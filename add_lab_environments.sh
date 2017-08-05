for i in 01 02 03;
do

PROJECT=project$i
USER=user$i

echo $PROJECT $USER

PROJECT_ID=`openstack project create $PROJECT -f value -c id`

openstack user create --password "openstack" $USER

openstack role create $USER

openstack role add --project $PROJECT --user $USER $USER

NETWORK_ID=`openstack network create internal --project $PROJECT_ID -f value -c id`

DNS_NAMESERVER=`grep -i nameserver /etc/resolv.conf | cut -d ' ' -f2 | head -1`
INTERNAL_SUBNET=192.168.10.0/24

SUBNET_ID=`openstack subnet create              \
        --network $NETWORK_ID                   \
        --dns-nameserver $DNS_NAMESERVER        \
        --subnet-range $INTERNAL_SUBNET         \
        --project $PROJECT_ID                   \
        $INTERNAL_SUBNET -f value -c id`


ROUTER_ID=`openstack router create --project $PROJECT_ID router -f value -c id`
openstack router add subnet $ROUTER_ID $SUBNET_ID

PUBLIC_NETWORK_ID=`openstack network show public -f value -c id`
openstack router set --external-gateway $PUBLIC_NETWORK_ID $ROUTER_ID

done
