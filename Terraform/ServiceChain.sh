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


