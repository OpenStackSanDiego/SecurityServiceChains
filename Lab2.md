
# Lab 2 - Chained Security Function

# Overview


# Goals

  * Monitor inbound web (HTTP) traffic from the client to web server
  * Block inbound web (HTTP) traffic from the client to the web server
  * Utilize service chains to monitor and block the packet flows in a single flow

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
## Service Network

Create a new network (service) if necessary (you may reuse the service network from an earlier lab). This will be used to host the service chaining ports on the virtual machines. The existing "internal" network will be used for production traffic to/from the virtual machines.

```bash
$ SERVICE_NETWORK_ID=`openstack network create service -c id -f value`
$ openstack subnet create --subnet-range 10.10.10.0/24 --dhcp --allocation-pool start=10.10.10.100,end=10.10.10.200 --network $SERVICE_NETWORK_ID service-subnet

```
## Service Network Ports

Create foud ports on the service network to be used for the monitoring. These will be the inbound and outbound traffic ports for the network monitoring virtual machine (netmon).
```bash
$ openstack port create --network service ingres-1
$ openstack port create --network service egress-1
$ openstack port create --network service ingres-2
$ openstack port create --network service egress-2
```
## Instances

Startup the following three images and assign floating IPs to all. This can all be done via Horizon.

| Instance Name | Image         | Flavor  | Network(s)      | Floating IP | Additional Ports            |
| ------------- |:-------------:| -------:|----------------:|------------:|-------------------------------------------------------:|
| WebClient     | CirrosWeb     | m1.tiny | internal        |  assign     | none                                                   |
| WebServer     | CirrosWeb     | m1.tiny | internal        |  assign     | none                                                   |
| NetMon1       | NetMon        | m1.small| internal,service|  assign     | ingress-1, egress-1                         | 
| NetMon2       | NetMon        | m1.small| internal,service|  assign     | ingress-2, egress-2                         | 

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

## Startup Network Traffic Monitoring on NetMon1

The first NetMon instance will be used to run tcpdump.

* Log into NetMon server via SSH using the assigned floating IP 
* Run a TCPDump to monitor for traffic to the client.

```bash
% sudo su -
# tcpdump -i eth1 not port 22
```

## Startup Snort on NetMon2

The second NetMon instance will be used to run Snort.

* Log into NetMon server via SSH using the assigned floating IP 
* Run a Snort to monitor for traffic to the client.

```bash
% sudo su -
# snort -i eth1 not port 22
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

* Create two port pairs once each for ingress-1/egress-1 (PP1) and ingress-2/egress-2 (PP2). See Lab 1 for syntax.

* Create the Port Pair Group (PPG2)
```bash
neutron port-pair-group-create \
  --port-pair PP1 --port-pair PP2 PPG1
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
* Verify that the tcpdump monitor on NetMon1 saw the traffic being pushed through the service chain
* Verify that snort on the NetMon2 saw the traffic as well.

## Block the traffic

* Update the snort command to block the web traffic
* Verify that the webclient can no longer access the web server

## Tear down the lab

* Delete the NetMon virtual machines
* Delete the service chains (pair groups, port pairs, and flow classifier)
* Delete the WebClient virtual machines
* The service network will be used for future labs so leave it running
