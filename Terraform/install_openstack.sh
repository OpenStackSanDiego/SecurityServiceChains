
yum -y update
yum install -y https://www.rdoproject.org/repos/rdo-release.rpm
yum install -y openstack-packstack
yum -y update

time packstack --allinone --os-cinder-install=n --nagios-install=n --os-ceilometer-install=n --os-neutron-ml2-type-drivers=flat,vxlan --os-heat-install=y

. /root/keystonerc_admin

IMAGE_SERVER=shell.openstacksandiego.us

for IMAGE in CentOS7:CentOS-7-x86_64-GenericCloud.qcow2 Ubuntu14_04:xenial-server-cloudimg-amd64-disk1.img CirrosWeb:CirrosWeb.img pfSense:pfSense-small.img NetMon:NetMon.img IoT:IoT.img
do
  IMG_FILE=`echo $IMAGE | cut -d':' -f1`
  IMG_NAME=`echo $IMAGE | cut -d':' -f2`
  echo $IMG_FILE
  echo $IMG_NAME
  
  wget -q -O - http://$IMAGE_SERVER/Images/$IMG_FILE | \
  glance --os-image-api-version 2 image-create --protected True --name $IMG_NAME --visibility public --disk-format raw --container-format bare
done




