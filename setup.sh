yum -y update
yum install -y https://www.rdoproject.org/repos/rdo-release.rpm
yum install -y openstack-packstack
yum -y update

yum -y update
time packstack                                  \
        --allinone                              \
        --os-cinder-install=n                   \
        --nagios-install=n                      \
        --os-ceilometer-install=n               \
        --os-neutron-ml2-type-drivers=flat,vxlan \
        --os-heat-install=y

yum -y update

# fix for https://bugs.launchpad.net/horizon/+bug/1671084 (heat topology tab not present in horizon)
sed -i 's/resources:index/resource:index/g' /usr/share/openstack-dashboard/openstack_dashboard/dashboards/project/stacks/tabs.py

## end of base OpenStack cloud install



## install and configure networing-sfc

yum install -y python-networking-sfc

NEUTRON_CONF=/etc/neutron/neutron.conf

# enable the service plugin (controller nodes)
sed -i '/^service_plugins=/ s/$/,networking_sfc.services.flowclassifier.plugin.FlowClassifierPlugin,networking_sfc.services.sfc.plugin.SfcPlugin/' /etc/neutron/neutron.conf

# specify drivers to use (controller nodes)
cat <<EOF>> $NEUTRON_CONF

# networking-sfc
[sfc]
drivers = ovs

[flowclassifier]

drivers = ovs
EOF

# enable extension (compute nodes)
ML2_CONF=/etc/neutron/plugins/ml2/ml2_conf.ini
cat <<EOF>>$ML2_CONF

# networking-sfc extension
[agent]
extensions = sfc
EOF

# database setup
neutron-db-manage --subproject networking-sfc upgrade head

## end of install and configure networking-sfc



## start of cloud customization

. ~/keystonerc_admin

# disconnect the demo router from the existing external public network
ROUTER_ID=`openstack router show router1 -c id -f value`
openstack router unset --external-gateway $ROUTER_ID

# delete the demo subnet from the public network
OLD_SUBNET_ID=`openstack subnet show public_subnet -f value -c id`
openstack subnet delete $OLD_SUBNET_ID

# add the new public subnet associated with the physical IP addresses assigned
IP=`hostname -I | cut -d' ' -f 1`
SUBNET=`ip -4 -o addr show dev bond0 | grep $IP | cut -d ' ' -f 7`
DNS_NAMESERVER=`grep -i nameserver /etc/resolv.conf | head -n1 | cut -d ' ' -f2`

openstack subnet create                         \
        --network public                        \
        --dns-nameserver $DNS_NAMESERVER        \
        --subnet-range $SUBNET                  \
        $SUBNET


# install some OS images
IMG_URL=https://download.fedoraproject.org/pub/alt/atomic/stable/Fedora-Atomic-25-20170626.0/CloudImages/x86_64/images/Fedora-Atomic-25-20170626.0.x86_64.qcow2
IMG_NAME=Fedora-Atomic-25
OS_DISTRO=fedora-atomic
wget -q -O - $IMG_URL | \
glance  --os-image-api-version 2 image-create --protected True --name $IMG_NAME \
        --visibility public --disk-format raw --container-format bare --property os_distro=$OS_DISTRO --progress
        
IMG_URL=https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
IMG_NAME=CentOS-7
OS_DISTRO=centos
wget -q -O - $IMG_URL | \
glance  --os-image-api-version 2 image-create --protected True --name $IMG_NAME \
        --visibility public --disk-format raw --container-format bare --property os_distro=$OS_DISTRO --progress  
	
IMG_URL=http://shell.openstacksandiego.us/Images/NetMon.img
IMG_NAME=NetMon
OS_DISTRO=centos
wget -q -O - $IMG_URL | \
glance  --os-image-api-version 2 image-create --protected True --name $IMG_NAME \
        --visibility public --disk-format raw --container-format bare --property os_distro=$OS_DISTRO --progress

# Cirros image with a basic web server running
IMG_URL=http://shell.openstacksandiego.us/Images/CirrosWeb.img
IMG_NAME=CirrosWeb
OS_DISTRO=cirros
wget -q -O - $IMG_URL | \
glance  --os-image-api-version 2 image-create --protected True --name $IMG_NAME \
        --visibility public --disk-format raw --container-format bare --property os_distro=$OS_DISTRO --progress

	

## end of cloud customization
	
	
	

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

## failsafe console login
# admin/openstack with sudo and ssh using root SSH key
adduser -p 42ZTHaRqaaYvI --group wheel admin
cp -R ~root/.ssh ~admin/
chown -R admin.admin ~admin/.ssh/


sync
sleep 1
reboot

  
