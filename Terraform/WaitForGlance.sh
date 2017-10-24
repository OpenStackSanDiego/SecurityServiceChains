. ~/keystonerc_admin

until openstack image list 
do
echo "waiting for OpenStack Glance to come online";
sleep 2;
done

