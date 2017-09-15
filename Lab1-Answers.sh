# cheat sheet commands for lab #1
# life is more fun when you do it yourself...
# but sometimes you do get stuck and we understand  :)

# Virtual Machine Credentials
openstack keypair create --public-key ~/.ssh/id_rsa.pub default

# Networking Setup
openstack security group rule create --dst-port 80 --protocol tcp --ingress default
openstack security group rule create --dst-port 22 --protocol tcp --ingress default

# Network Ports
for port in port-admin1 port-ingress1 port-egress1 port-webclient port-webserver
do
    openstack port create --network internal "${port}"
done

# Save IP Address Assignments
WEBCLIENT_IP=$(openstack port show port-webclient -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo WEBCLIENT_IP=$WEBCLIENT_IP

WEBSERVER_IP=$(openstack port show port-webserver -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo WEBSERVER_IP=$WEBSERVER_IP

NETMON1_ADMIN_IP=$(openstack port show port-admin1 -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo NETMON1_ADMIN_IP=$NETMON1_ADMIN_IP




# Instances
openstack server create \
	--image NetMon \
	--flavor m1.small \
	--nic port-id=port-admin1 \
	--nic port-id=port-ingress1 \
	--nic port-id=port-egress1 \
	--key-name default \
	netmon1
        
 openstack server create \
	--image cirros \
	--flavor m1.tiny \
	--nic port-id=port-webclient \
	--key-name default \
	webclient
        
 openstack server create \
	--image cirros \
	--flavor m1.tiny \
        --nic port-id=port-webserver \
	--key-name default \
	webserver
        
        
 # Startup the Web Server
ssh cirros@${WEBSERVER_IP} \
	'while true; do echo -e "HTTP/1.0 200 OK\r\n\r\nWelcome to $(hostname)" | sudo nc -l -p 80 ; done&'
        
        
# Test Web Server
ssh cirros@${WEBCLIENT_IP} curl -s ${WEBSERVER_IP}

# IP Forwarding and Routing Setup
ssh -T centos@${NETMON1_ADMIN_IP} <<EOF
sudo ip route add $WEBCLIENT_IP dev eth1
sudo ip route add $WEBSERVER_IP dev eth2
sudo /sbin/sysctl -w net.ipv4.ip_forward=1
EOF


# Service Chaining
openstack sfc flow classifier create \
    --ethertype IPv4 \
    --source-ip-prefix ${WEBCLIENT_IP}/32 \
    --destination-ip-prefix ${WEBSERVER_IP}/32 \
    --protocol tcp \
    --destination-port 80:80 \
    --logical-source-port port-webclient \
    FC-WebServer-HTTP


openstack sfc port pair create --ingress=port-ingress1 --egress=port-egress1 Netmon1-PortPair
openstack sfc port pair group create --port-pair Netmon1-PortPair Netmon-PairGroup
openstack sfc port chain create --port-pair-group Netmon-PairGroup --flow-classifier FC-WebServer-HTTP PC1

