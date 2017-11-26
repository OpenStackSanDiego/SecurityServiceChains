# cheat sheet for lab4

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
export WEBCLIENT_IP=$WEBCLIENT_IP

WEBSERVER_IP=$(openstack port show port-webserver -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
export WEBSERVER_IP=$WEBSERVER_IP

MODSEC1_ADMIN_IP=$(openstack port show port-admin1 -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
export MODSEC1_ADMIN_IP=$MODSEC1_ADMIN_IP

# Instances
openstack server create \
	--image ModSec \
	--flavor m1.small \
	--nic port-id=port-admin1 \
	--nic port-id=port-ingress1 \
	--nic port-id=port-egress1 \
	--key-name default \
	modsec1

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
# NOTE(curtis): Should the image have eth1 and eth2 already up?
# NOTE(curtis): ip forwarding not needed (tested)
ssh -T fedora@${MODSEC1_ADMIN_IP} <<EOF
sudo ip link set eth1 up
sudo ip link set eth2 up
sudo ip route add $WEBCLIENT_IP dev eth1
sudo ip route add $WEBSERVER_IP dev eth2
sudo iptables -t nat -A PREROUTING -p tcp -d ${WEBSERVER_IP} --dport 80 -j NETMAP --to ${MODSEC1_ADMIN_IP}
sudo sed -i "s|#ProxyPass / http://WEBSERVER_IP/|ProxyPass / http://${WEBSERVER_IP}/|" /etc/httpd/conf.d/proxy.conf
sudo sed -i "s|#ProxyPassReverse / http://WEBSERVER_IP/|ProxyPassReverse / http://${WEBSERVER_IP}/|" /etc/httpd/conf.d/proxy.conf
sudo systemctl restart httpd
EOF

# Service Chaining
openstack sfc flow classifier create \
    --ethertype IPv4 \
    --source-ip-prefix ${WEBCLIENT_IP}/32 \
    --destination-ip-prefix ${WEBSERVER_IP}/32 \
    --protocol tcp \
    --destination-port 80:80 \
    --logical-source-port port-webclient \
    FC-WAF-HTTP

openstack sfc port pair create --ingress=port-ingress1 --egress=port-egress1 ModSec1-PortPair
openstack sfc port pair group create --port-pair ModSec1-PortPair ModSec1-PairGroup
openstack sfc port chain create --port-pair-group ModSec1-PairGroup --flow-classifier FC-WAF-HTTP PC1

# To delete
# openstack sfc port chain delete PC1
# openstack sfc port pair group delete ModSec1-PairGroup
# openstack sfc port pair delete ModSec1-PortPair

# Test mod security
ssh cirros@${WEBCLIENT_IP} curl -s ${WEBSERVER_IP}/?abc=../../
