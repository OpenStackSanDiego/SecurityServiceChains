# cheat sheet commands for lab #1
# life is more fun when you do it yourself...
# but sometimes you do get stuck and we understand  :)

openstack security group rule create --dst-port 80 --protocol tcp --ingress default
openstack security group rule create --dst-port 22 --protocol tcp --ingress default

INTERNAL_NETWORK_ID=`openstack network show internal -c id -f value`

openstack server create --image CirrosWeb --flavor m1.tiny --nic net-id=$INTERNAL_NETWORK_ID WebServer -c id -f value
FLOATING_IP=`openstack floating ip create public -c floating_ip_address -f value`
openstack server add floating ip WebServer $FLOATING_IP

openstack server create --image CirrosWeb --flavor m1.tiny --nic net-id=$INTERNAL_NETWORK_ID WebClient -c id -f value
FLOATING_IP=`openstack floating ip create public -c floating_ip_address -f value`
openstack server add floating ip WebClient $FLOATING_IP

INGRESS_PORT_ID=`openstack port create --network internal ingress-01 -c id -f value`
EGRESS_PORT_ID=`openstack port create --network internal egress-01 -c id -f value`

NETMON_ID=`openstack server create --image NetMon --flavor m1.small \
        --nic   net-id=$INTERNAL_NETWORK_ID \
        --nic   port-id=$INGRESS_PORT_ID \
        --nic   port-id=$EGRESS_PORT_ID \
        NetMon -c id -f value`
FLOATING_IP=`openstack floating ip create public -c floating_ip_address -f value`
openstack server add floating ip NetMon $FLOATING_IP


WEBCLIENT_ID=`openstack port list --server WebClient -c ID -f value`
neutron flow-classifier-create   --description "HTTP traffic from WebClient" \
                                 --logical-source-port $WEBCLIENT_ID \
                                 --ethertype IPv4 \
                                 --protocol tcp \
                                 --destination-port 80:80 WebClientFC
neutron port-pair-create --description "NetMon" \
                         --ingress ingress-01 \
                         --egress egress-01 PP1
neutron port-pair-group-create --port-pair PP1 PPG1
neutron port-chain-create --port-pair-group PPG1 --flow-classifier WebClientFC PC1

