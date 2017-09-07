
# Lab 1 - Single Security Function

# Overview

In this first exercise we'll be adding a rule to move traffic through a virtual machine configured with the network monitoring tool TCPDump. This exercise walks through the basics of setting up your first set of chain rules.

# Goals

  * Monitor inbound web (HTTP) traffic from a web client to web server
  * Setup a service chain to monitor the packet flows
  * Setup a service function in each of routing, bridged, and inline configurations

# Prereq

  * Use the credentials and lab information provided on the lab handout
  * Your OS (SSH) and Horizon login will be in the form of userNN with NN being a one or two digit number
  * The userNN login will be used for the physical OpenStack controller and Horizon login

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

Create three ports for the network monitoring service function. One port will be for administrative purposes (port-admin1) to manage the virtual machine via an SSH session. The other two ports (port-ingress1 and port-egress1) will be the ingress and egress of network traffic in and out of the service function.

Create one port each for the web client and web server virtual machines.

All of these ports will be on the internal network.

```bash
for port in port-admin1 port-ingress1 port-egress1 port-webclient port-webserver
do
    openstack port create --network internal "${port}"
done
```

## Instances

Startup the following three images and assign floating IPs to all. This can all be done via Horizon.

| Instance Name | Image         | Flavor  | Ports                                        | 
| ------------- |:-------------:| -------:|---------------------------------------------:|
| WebClient     | cirros        | m1.tiny | port-webclient                               |
| WebServer     | cirros        | m1.tiny | port-webserver                               |
| NetMon        | NetMon        | m1.small| port-admin1, port-ingress1, port-egress1     |


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
WEBSERVER_IP=$(openstack port show port-webserver -f value -c fixed_ips | grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo WEBSERVER_IP=$WEBSERVER_IP

ssh cirros@${WEBSERVER_IP} 'while true; do echo -e "HTTP/1.0 200 OK\r\n\r\nWelcome to $(hostname)" | sudo nc -l -p 80 ; done&'
```

* Validate that the web server process is running
```bash
curl $WEBSERVER_IP
```

## Initial web-server Test

From the WebClient, we'll hit the WebServer to verify functionality of the webserver.

* Log into WebClient via SSH
```
WEBCLIENT_IP=$(openstack port show port-client -f value -c fixed_ips | grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo WEBCLIENT_IP=$WEBCLIENT_IP
ssh cirros@${WEBCLIENT_IP}
```

* Verify that the client can connect to the web server using curl

* Verify that the hostname of the web server is returned as the response from the remote Web Server

## Startup Network Traffic Monitoring

Next we'll introduce a virtual machine with some network monitoring tools installed (tcpdump and snort)

* Log into NetMon server via SSH using the assigned floating IP 
* Run a TCPDump to monitor for traffic to the client.

```bash
% sudo su -
# tcpdump -i eth1 not port 22
```

## Service Chaining

* Log into the physical OpenStack controller via SSH (IP address provided on the lab handout). The OpenStack credentials (keystonerc) will be loaded automatically when you login.

* Record the assigned port (ID) for the WebClient. We'll need this to create the service chain.
```bash
WEBCLIENT_ID=`openstack port list --server WebClient -c ID -f value`
echo $WEBCLIENT_ID
```

* Create the Flow Classifier
```bash
neutron flow-classifier-create \
  --description "HTTP traffic from WebClient" \
  --logical-source-port $WEBCLIENT_ID \
  --ethertype IPv4 \
  --protocol tcp \
  --destination-port 80:80 FC1
```

* Create the Port Pair
```bash
neutron port-pair-create \
  --description "NetMon" \
  --ingress ingress-1 \
  --egress egress-1 PP1
```

* Create the Port Pair Group
```bash
neutron port-pair-group-create \
  --port-pair PP1 PPG1
```

* Create the Port Chain
```bash
neutron port-chain-create \
  --port-pair-group PPG1 \
  --flow-classifier FC1 PC1
```

## Verify service chain functionality

* Log into WebClient via SSH using the assigned floating IP
* Generate traffic from the WebClient to the WebServer
```bash
$ curl 192.168.2.XXX
```
* Verify that the tcpdump monitor on NetMon saw the traffic being pushed through the service chain


## Bridge Traffic with tcpdump

The current service chain brings traffic to the netmon instance but it doesn't travel through the vm. Bridging the ingress and egress ports allows traffic to flow through the vm and onto the web server. The bridge can then be used by tcpdump to monitor traffic as it flows through the vm.

* Setup the Bridge on netmon
```bash
yum install bridge-utils
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

* Startup tcpdump on netmon using the bridge
```bash
tcpdump -i br0 port 80
```

* Generate traffic from the WebClient to the WebServer
```bash
$ curl 192.168.2.XXX
```
* Verify that the tcpdump monitor on NetMon saw the traffic being pushed through the service chain
* Verify that the curl command received a response back from the web server

## Tear down the Bridge

Remove the bridge so that an inline Snort bridge can be setup.

```bash
brctl delif br0 eth1
brctl delif br0 eth2
ifconfig br0 down
brctl delbr br0
```

## Inline Bridge with Snort
Next we'll be using Snort as an inline bridge to monitor and pass traffic.

* Startup Snort inline on netmon
```bash
snort -A console -Q -c snort.conf -Q -i eth1:eth2 -N
```

* Generate traffic from the WebClient to the WebServer
```bash
$ curl 192.168.2.XXX
```
* Verify that the Snort on NetMon saw the traffic
* Verify that the curl command received a response back from the web server

## Tear down the lab

* Delete the NetMon virtual machine
* Delete the service chains from the controller
```bash
neutron port-chain-delete PC1
neutron port-pair-group-delete PPG1
neutron port-pair-delete PP1
neutron flow-classifier-delete FC1
```

* The WebServer and WebClient will be used for future labs so leave them running


