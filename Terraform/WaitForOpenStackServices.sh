. ~/keystonerc_admin

until openstack token issue;
do
echo "waiting for OpenStack Keystone to come online";
sleep 2;
done

