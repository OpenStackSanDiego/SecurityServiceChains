source keystonerc_admin

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
