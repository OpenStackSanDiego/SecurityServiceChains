
# Lab 1 - Single Security Function

# Overview

In this first exercise we'll be adding a rule to move traffic through a virtual machine configured with the network monitoring tool TCPDump. This exercise walks through the basics of setting up your first service chain and service functions. The service functions will be setup in three different modes (IP forwarded, bridged, and snort IDS inline).

# Goals

  * Monitor inbound web (HTTP) traffic from a web client to web server
  * Setup a service chain to monitor the packet flows
  * Setup a service function in each of IP forwarded, bridged, and inline configurations

# Prereq

  * Use the credentials and lab information provided on the lab handout
  * Your OS (SSH) and Horizon login will be in the form of userN with N being a one or two digit number
  * The userN login will be used for the physical OpenStack controller and Horizon login

# Lab Steps

## Log into Horizon and OpenStack Controller

  * Log into the OpenStack dashboard via a web brower using the credentials provided
  * Log into the controller via SSH using the credentials provided
    
## Virtual Machine Credentials

* Import the SSH keypair into OpenStack for use in accessing the deployed VMs
```bash
openstack keypair create --public-key ~/.ssh/id_rsa.pub default
```

## Networking Setup
  * Setup network security groups to allow SSH and HTTP to deployed virtual machines
```bash
openstack security group rule create --dst-port 80 --protocol tcp --ingress default
openstack security group rule create --dst-port 22 --protocol tcp --ingress default
```

# Lab Steps
## Network Ports

Create three ports for the network monitoring service function. One port will be for administrative purposes (port-admin1) to manage the virtual machine via an SSH session. The other two ports (port-ingress1 and port-egress1) will be the ingress and egress of network traffic in and out of the service function. Create one port each for the web client and web server virtual machines. All of these ports will be on the internal network.

* Create the ports to be used by the VMs and service chains
```bash
for port in port-admin1 port-ingress1 port-egress1 port-webclient port-webserver
do
    openstack port create --network internal "${port}"
done
```

## Save IP Address Assignments

For simplicity sake, save the IP addresses assigned to each port to a shell variable to be used later in the lab.

* Save the assigned IP addresses to shell variables
```bash
WEBCLIENT_IP=$(openstack port show port-webclient -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo WEBCLIENT_IP=$WEBCLIENT_IP

WEBSERVER_IP=$(openstack port show port-webserver -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo WEBSERVER_IP=$WEBSERVER_IP

NETMON1_ADMIN_IP=$(openstack port show port-admin1 -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo NETMON1_ADMIN_IP=$NETMON1_ADMIN_IP
```

## Instances

Startup the following three images and assign floating IPs to all. This can all be done via Horizon or the OpenStack CLI.

| Instance Name | Image         | Flavor  | Ports                                        | 
| ------------- |:-------------:| -------:|---------------------------------------------:|
| WebClient     | cirros        | m1.tiny | port-webclient                               |
| WebServer     | cirros        | m1.tiny | port-webserver                               |
| NetMon1       | NetMon        | m1.small| port-admin1, port-ingress1, port-egress1     |


* Startup the NetMon VM
```bash
openstack server create \
	--image NetMon \
	--flavor m1.small \
	--nic port-id=port-admin1 \
	--nic port-id=port-ingress1 \
	--nic port-id=port-egress1 \
	--key-name default \
	NetMon1
```

* Startup the Web Client VM
```bash
openstack server create \
	--image cirros \
	--flavor m1.tiny \
	--nic port-id=port-webclient \
	--key-name default \
	webclient
```

* Startup the Web Server VM
```bash
openstack server create \
	--image cirros \
	--flavor m1.tiny \
        --nic port-id=port-webserver \
	--key-name default \
	webserver
```

## Startup the Web Server

We'll startup a small web server that simply responds back with a hostname string. This is simply to simulate a web server and to give us some traffic to monitor

* Startup a web server process
```bash
ssh cirros@${WEBSERVER_IP} \
	'while true; do echo -e "HTTP/1.0 200 OK\r\n\r\nWelcome to $(hostname)" | sudo nc -l -p 80 ; done&'
```

## Test Web Server

From the WebClient, we'll hit the WebServer, using curl, to verify functionality of the webserver.

* Run a curl from the WebClient to the WebServer
```bash
ssh cirros@${WEBCLIENT_IP} curl -s ${WEBSERVER_IP}
```

* Verify that the web server responds

## Service Chaining

* Log into the physical OpenStack controller via SSH (IP address provided on the lab handout). The OpenStack credentials (keystonerc) will be loaded automatically when you login.

* Create the Flow Classifier for HTTP (tcp port 80) traffic from the WebClient to the WebServer.
```bash
openstack sfc flow classifier create \
    --ethertype IPv4 \
    --source-ip-prefix ${WEBCLIENT_IP}/32 \
    --destination-ip-prefix ${WEBSERVER_IP}/32 \
    --protocol tcp \
    --destination-port 80:80 \
    --logical-source-port port-webclient \
    FC-WebServer-HTTP
```

* Create the Port Pair, Port Pair Group, and Port Chain
```bash
openstack sfc port pair create --ingress=port-ingress1 --egress=port-egress1 Netmon1-PortPair
openstack sfc port pair group create --port-pair Netmon1-PortPair Netmon-PairGroup
openstack sfc port chain create --port-pair-group Netmon-PairGroup --flow-classifier FC-WebServer-HTTP PC1
```

## Network Traffic Monitoring - IP Forwarding

* Startup a new SSH session to the controller
* SSH into NetMon server via the admin interface

```bash
TODO - setup routing
ssh centos@${NETMON1_ADMIN_IP}
```

* Enabled Kernel IPForwarding on Netmon1
```bash
sudo echo 1 > /proc/sys/net/ipv4/ip_forward
```

* Monitor Traffic through the Netmon1 service function
```bash
sudo tcpdump -i eth1 port 80
```

The next time traffic goes through the service chain, it will run through the Netmon service function and be monitored by the tcpdump process.

## Service Chaining via Kernel IP Forwarding

From the WebClient, we'll hit the WebServer, using curl, to generate traffic through the chain and the service function.

* Run a curl from the WebClient to the WebServer
```bash
ssh cirros@${WEBCLIENT_IP} curl@{$WEBSERVER_IP}
```

* Verify that the the remove web server responds

* Verify that the Netmon1 service function saw the traffic via tcpdump

In this scenarion, traffic traversed through the service function via the service chain. Within the Netmon1 service function, the traffic was routed from eth1 to eth2 by the kernel (via ipforwarding).


## Network Traffic Monitoring - IP Forwarding

The current service chain brings traffic to the netmon instance but it doesn't travel through the vm. Bridging the ingress and egress ports allows traffic to flow through the vm and onto the web server. The bridge can then be used by tcpdump to monitor traffic as it flows through the vm.

* Disable Kernel IPForwarding on Netmon1
```bash
sudo echo 0 > /proc/sys/net/ipv4/ip_forward
```

* Setup the Bridge on Netmon1
```bash
brctl addbr br0
brctl stp br0 on
ifconfig eth1 0.0.0.0 down
ifconfig eth2 0.0.0.0 down
brctl addif br0 eth1
brctl addif br0 eth2
ifconfig eth1 up
ifconfig eth2 up
ifconfig br0 up
```

* Monitor Traffic through the Netmon1 service function
```bash
sudo tcpdump -i br0 port 80
```

The next time traffic goes through the service chain, it will run through the Netmon service function and be monitored by the tcpdump process.

## Service Chaining via Bridged Service Function

From the WebClient, we'll hit the WebServer, using curl, to generate traffic through the chain and the service function.

* Run a curl from the WebClient to the WebServer
```bash
ssh cirros@${WEBCLIENT_IP} curl@{$WEBSERVER_IP}
```

* Verify that the the remove web server responds

* Verify that the Netmon1 service function saw the traffic via tcpdump

In this scenarion, traffic traversed through the service function via the service chain. Within the Netmon1 service function, the traffic was bridged from eth1 to eth2.


## Tear down the Bridge

Remove the bridge so that an inline Snort instance can be setup.

* Stop the tcpdump on Netmon1 with ctrl-c

* Disable bridge on Netmon1
```bash
sudo brctl delif br0 eth1
sudo brctl delif br0 eth2
sudo ifconfig br0 down
sudo brctl delbr br0
```

## Network Traffic Monitoring - Snort IDS Inline

The current service chain brings traffic to the netmon instance but it doesn't travel through the vm. Bridging the ingress and egress ports allows traffic to flow through the vm and onto the web server. The bridge can then be used by tcpdump to monitor traffic as it flows through the vm.
Next we'll be using Snort as an inline bridge to monitor and pass traffic.

* Disable Kernel IPForwarding on Netmon1
```bash
sudo echo 0 > /proc/sys/net/ipv4/ip_forward
```

* Startup Snort inline on netmon1
```bash
sudo snort -A console -Q -c snort.conf -Q -i eth1:eth2 -N
```

## Service Chaining via Snort Inline Function

From the WebClient, we'll hit the WebServer, using curl, to generate traffic through the chain and the service function.

* Run a curl from the WebClient to the WebServer
```bash
ssh cirros@${WEBCLIENT_IP} curl@{$WEBSERVER_IP}
```

* Verify that the the remove web server responds

* Verify that the Netmon1 service function saw the traffic via snort

In this scenarion, traffic traversed through the service function via the service chain. Within the Netmon1 service function, the traffic was passed through the snort process which utilized eth1 and eth2 as the ingress and egress interfaces.

## Tear down the lab

* Delete the NetMon1 virtual machine
```bash
openstack server delete NetMon1
```

* Delete the service chains from the controller
```bash
openstack sfc port chain delete FC-WebServer-HTTP PC1
openstack sfc port pair group delete Netmon-PairGroup
openstack sfc port pair delete Netmon1-PortPair
openstack sfc flow classifier delete FC-WebServer-HTTP
```

* The WebServer and WebClient will be used for future labs so leave them running
* The ports can be saved for future labs so leave them runnings


