
#openstack keypair create --public-key ~/.ssh/id_rsa.pub default
#openstack security group rule create --dst-port 80 --protocol tcp --ingress default
#openstack security group rule create --dst-port 22 --protocol tcp --ingress default


for port in port-admin1 port-ingress1 port-egress1 port-admin2 port-ingress2 port-egress2 port-iot1 port-iot2
do
    openstack port create --network internal "${port}"
done


openstack server create \
        --image IoT-malicious \
        --flavor m1.small \
        --nic port-id=port-iot1 \
        --key-name default \
        iot1


openstack server create \
        --image IoT-malicious \
        --flavor m1.small \
        --nic port-id=port-iot2 \
        --key-name default \
        iot2



openstack server create \
        --image NetMon \
        --flavor m1.small \
        --nic port-id=port-admin1 \
        --nic port-id=port-ingress1 \
        --nic port-id=port-egress1 \
        --key-name default \
        netmon1

openstack server create \
        --image NetMon \
        --flavor m1.small \
        --nic port-id=port-admin2 \
        --nic port-id=port-ingress2 \
        --nic port-id=port-egress2 \
        --key-name default \
        netmon2


openstack sfc flow classifier create \
    --ethertype IPv4 \
    --source-ip-prefix 192.168.18.0/24 \
    --destination-ip-prefix 0.0.0.0/0 \
    --logical-source-port port-iot1 \
    --protocol tcp \
    FC-IOT-1
    
openstack sfc port pair create --ingress=port-ingress1 --egress=port-egress1 Netmon1-PortPair
openstack sfc port pair create --ingress=port-ingress1 --egress=port-egress1 Netmon1-PortPair
openstack sfc port pair group create --port-pair Netmon1-PortPair Netmon-PairGroup
openstack sfc port chain create --port-pair-group Netmon-PairGroup --flow-classifier FC-IOT-1 PC1
