
# Lab 1 - Single Security Function

# Overview

In this first exercise we'll be adding a rule to move traffic through a virtual machine configured with the network monitoring tool TCPDump. This exercise walks through the basics of setting up your first set of chain rules.

# Goals

  * Monitor inbound web (HTTP) traffic from the client to web
  * Utilize service chains to monitor the packet flows

# Prereq

## Log into Horizon and OpenStack Controller
  * User the credentials and lab information provided on the lab handout
  * Your OS (SSH) and Horizon login will be in the form of userNN with NN being a two digit number (including leading zero)
  * The userNN login will be used for the physical OpenStack controller and Horizon login
  * Virtual machine logins will generic login account details below

## Networking Setup
  * Setup network security groups to allow SSH and HTTP to the project from your laptop external network
```bash
openstack security group rule create --dst-port 80 --protocol tcp --ingress default
openstack security group rule create --dst-port 22 --protocol tcp --ingress default
```
## Virtual machine images login info
  * admin/openstack for the CirrosWeb image (WebServer and WebClient instances)
  * admin/openstack for the NetMon image

# Lab Steps
## Netmon Network Ports

Create two ports on the internal network to be used for the monitoring. These will be the inbound and outbound traffic ports for the network monitoring virtual machine (netmon).
```bash
$ openstack port create --network internal ingres-1
$ openstack port create --network internal egress-1
```
## Instances

Startup the following three images and assign floating IPs to all. This can all be done via Horizon.

| Instance Name | Image         | Flavor  | Network(s)      | Floating IP | Additional Ports            |
| ------------- |:-------------:| -------:|----------------:|------------:|-------------------------------------------------------:|
| WebClient     | CirrosWeb     | m1.tiny | internal        |  assign     | none                                                   |
| WebServer     | CirrosWeb     | m1.tiny | internal        |  assign     | none                                                   |
| NetMon        | NetMon        | m1.small| internal        |  assign     | ingress-1, egress-1, management                         | 

Ensure floating IPs are assigned to all instances. Associate the NetMon floating IP to the internal network port.
## Startup the Web Server

We'll startup a small web server that simply responds back with a hostname string. This is simply to simulate a web server and to give us some traffic to monitor
* Log into WebServer via SSH using the assigned floating IP
* su to root to gain superuser privileges
```bash
$ sudo su -
```
* Startup the web server via the command "hostname-webserver.sh"
```bash
# ./hostname-webserver.sh
```

## Initial web-server Test

From the WebClient, we'll hit the WebServer to verify functionality of the webserver.

* Log into WebClient via SSH using the assigned floating IP
* Verify that the client can connect to the web server on the WebServer private IP
```bash
$ curl 192.168.2.XXX
```
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
  --destination-port 80:80 WebClientFC
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
  --flow-classifier WebClientFC PC1
```

## Verify service chain functionality

* Log into WebClient via SSH using the assigned floating IP
* Generate traffic from the WebClient to the WebServer
```bash
$ curl 192.168.2.XXX
```
* Verify that the tcpdump monitor on NetMon saw the traffic being pushed through the service chain

## Tear down the lab

* Delete the NetMon virtual machine
* Delete the service chains (pair groups, port pairs, and flow classifier)
* The WebServer and WebClient will be used for future labs so leave them running


