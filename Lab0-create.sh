# Virtual Machine Credentials
openstack keypair create --public-key ~/.ssh/id_rsa.pub lab0

# Network Ports
for port in port-admin1 port-ingress1 port-egress1 port-webclient port-webserver
do
    openstack port create --network internal "${port}"
done


# Instances
openstack server create \
	--image NetMon \
	--flavor m1.small \
	--nic port-id=port-admin1 \
	--nic port-id=port-ingress1 \
	--nic port-id=port-egress1 \
	--key-name lab0 \
	netmon1
        
openstack server create \
	--image cirros \
	--flavor m1.tiny \
	--nic port-id=port-webclient \
	--key-name lab0 \
	webclient
        
openstack server create \
	--image cirros \
	--flavor m1.tiny \
        --nic port-id=port-webserver \
	--key-name lab0 \
	webserver

# Save IP Address Assignments
export WEBCLIENT_IP=$(openstack port show port-webclient -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo export WEBCLIENT_IP=$WEBCLIENT_IP

export WEBSERVER_IP=$(openstack port show port-webserver -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo export WEBSERVER_IP=$WEBSERVER_IP

export NETMON1_ADMIN_IP=$(openstack port show port-admin1 -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo export NETMON1_ADMIN_IP=$NETMON1_ADMIN_IP

# Startup the Web Server
screen -d -m -S webserver \
  ssh  -oStrictHostKeyChecking=no cirros@${WEBSERVER_IP} \
	'while true; do echo -e "HTTP/1.0 200 OK\r\n\r\nWelcome to $(hostname)" | sudo nc -l -p 80 ; done&'
        
# Test Web Server
screen -d -m -S webclient \
  ssh  -oStrictHostKeyChecking=no cirros@${WEBCLIENT_IP} \
  "while true; do curl ${WEBSERVER_IP} ; sleep 10 ; done"

# IP Forwarding and Routing Setup
ssh -oStrictHostKeyChecking=no -T centos@${NETMON1_ADMIN_IP} <<EOF
sudo ip route add ${WEBCLIENT_IP} dev eth1
sudo ip route add ${WEBSERVER_IP} dev eth2
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

screen -d -m -S tcpdump \
  ssh -oStrictHostKeyChecking=no centos@${NETMON1_ADMIN_IP} \
  "sudo tcpdump -i eth1 port 80"

