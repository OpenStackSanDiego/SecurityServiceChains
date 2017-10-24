source keystonerc_admin

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
