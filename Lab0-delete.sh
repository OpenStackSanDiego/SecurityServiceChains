screen -S webserver -X quit
screen -S webclient -X quit
screen -S tcpdump -X quit

openstack sfc port chain delete PC1
openstack sfc port pair group delete Netmon-PairGroup
openstack sfc port pair delete Netmon1-PortPair
openstack sfc flow classifier delete FC-WebServer-HTTP

# Instances
openstack server delete netmon1
openstack server delete webclient
openstack server delete webserver

openstack keypair delete lab0

# Network Ports
for port in port-admin1 port-ingress1 port-egress1 port-webclient port-webserver
do
    openstack port delete "${port}"
done

# Save IP Address Assignments
export WEBCLIENT_IP=
export WEBSERVER_IP=
export NETMON1_ADMIN_IP=
