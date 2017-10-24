
## setup physical networking
IFCFG_BOND0=/etc/sysconfig/network-scripts/ifcfg-bond0
IFCFG_BR_EX=/etc/sysconfig/network-scripts/ifcfg-br-ex

# setup a new network config with the IP address from bond0
cp $IFCFG_BOND0 $IFCFG_BR_EX
sed -i 's/^DEVICE=bond0/DEVICE=br-ex/' $IFCFG_BR_EX
sed -i 's/^NAME=bond0/NAME=br-ex/' $IFCFG_BR_EX

# remove the IP address from bond0 by commenting it out
sed -i '/^IPADDR=/ s/^#*/#/' $IFCFG_BOND0

# change the default gateway device from bond0 to br-ex
sed -i 's/^GATEWAYDEV=.*/GATEWAYDEV=br-ex/' /etc/sysconfig/network

# add the physical port to the bridge
ovs-vsctl add-port br-ex bond0

## end of physical networking

sync
sleep 1
reboot
