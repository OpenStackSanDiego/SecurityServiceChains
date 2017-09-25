yum -y update
yum install -y http://www.rdoproject.org/repos/rdo-release.rpm
if [ "$?" -ne 0 ]; then
  sleep 10
  yum install -y http://www.rdoproject.org/repos/rdo-release.rpm
  if [ "$?" -ne 0 ]; then
    sleep 10
    yum install -y http://www.rdoproject.org/repos/rdo-release.rpm
  else
    echo "unable to update RDO RPM"
    exit
  fi
fi

yum install -y openstack-packstack
yum -y update

exit

time packstack                                  \
        --allinone                              \
        --os-cinder-install=n                   \
        --os-ceilometer-install=n               \
        --os-neutron-ml2-type-drivers=flat,vxlan \
        --os-heat-install=y

yum -y update
echo "*** End of base OpenStack cloud install"


# easy modification of .ini configuration files
yum install -y crudini


# install the port security extension so that port security can be turned on/off per network/por
# service chaining requires port security turned off
crudini --set --list /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security


## install and configure networing-sfc
yum install -y python-networking-sfc

# enable the service plugin (controller nodes)
crudini --set --list /etc/neutron/neutron.conf DEFAULT service_plugins networking_sfc.services.flowclassifier.plugin.FlowClassifierPlugin
crudini --set --list /etc/neutron/neutron.conf DEFAULT service_plugins networking_sfc.services.sfc.plugin.SfcPlugin

# specify drivers to use (controller nodes)
crudini --set --list /etc/neutron/neutron.conf sfc drivers ovs
crudini --set --list /etc/neutron/neutron.conf flowclassifier drivers ovs

# enable extension (compute nodes)
crudini --set --list /etc/neutron/plugins/ml2/openvswitch_agent.ini agent extensions sfc

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

IMG_URL=https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
IMG_NAME=CentOS-7
OS_DISTRO=centos
wget -q -O - $IMG_URL | \
glance  --os-image-api-version 2 image-create --protected True --name $IMG_NAME \
        --visibility public --disk-format raw --container-format bare --property os_distro=$OS_DISTRO --progress
	
IMG_URL=http://shell.openstacksandiego.us/Images/IoT-malicious.img
IMG_NAME=IoT-malicious
OS_DISTRO=centos
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

# setup the admin OpenStack credentials for the admin account
cp ~root/keystonerc_admin ~admin/
chown admin.admin ~admin/keystonerc_admin

# have the keystone credentials read upon login of the admin user
cat >> ~admin/.bashrc << EOF

# OpenStack
. ~/keystonerc_admin
EOF


sync
sleep 1
reboot

  
