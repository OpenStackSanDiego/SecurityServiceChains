. ~/keystonerc_admin

until openstack image list > /dev/null
do
echo "waiting for OpenStack Glance to come online";
sleep 2;
done

