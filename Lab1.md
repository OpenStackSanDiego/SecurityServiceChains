
# Lab 1 - Single Security Function

# Overview


# Goals

  * Monitor inbound web (HTTP) traffic from the client to web
  * Utilize service chains to monitor the packet flows

# Prereq

## Log into Horizon and OpenStack Controller
  * User the credentials and lab information provided on the lab handout

## Networking Setup
  * Setup network security groups to allow SSH and HTTP to the project from your laptop external network
```bash
openstack security group rule create --dst-port 80 --protocol tcp --ingress default
openstack security group rule create --dst-port 22 --protocol tcp --ingress default
```
  
## Virtual machine images login info
  * admin/openstack for the CirrosWeb image
  * admin/openstack for the NetMon image

# Service Network

Create a new network (service). This will be used to host the service chaining ports on the virtual machines. The existing "internal" network will be used for production traffic to/from the virtual machines.

```bash
$ SERVICE_NETWORK_ID=`openstack network create service -c id -f value`
$ openstack subnet create --subnet-range 10.10.10.0/24 --dhcp --allocation-pool start=10.10.10.100,end=10.10.10.200 --network $SERVICE_NETWORK_ID service-subnet

```

# Service Network Ports

Create two ports on the service network to be used for the monitoring. These will be the inbound and outbound traffic ports for the network monitoring virtual machine (netmon).
```bash
$ openstack port create --network service service-port-1
$ openstack port create --network service service-port-2
```


# Instances

Startup the following three images and assign floating IPs to all. This can all be done via Horizon.

| Instance Name | Image         | Flavor  | Network(s)      | Floating IP | Additional Ports            |
| ------------- |:-------------:| -------:|----------------:|------------:|-------------------------------------------------------:|
| WebClient     | CirrosWeb     | m1.tiny | internal        |  assign     | none                                                   |
| WebServer     | CirrosWeb     | m1.tiny | internal        |  assign     | none                                                   |
| NetMon        | NetMon        | m1.small| internal,service|  assign     | service-port-1, service-port-2                         | 

Ensure floating IPs are assigned to all instances. Associate the NetMon floating IP to the internal network port.


## Startup the Web Server
* Log into CirrosWebServer via SSH using the assigned floating IP
* su to root to gain superuser privileges
```bash
$ sudo su -
```
* Startup the web server via the command "hostname-webserver.sh"
```bash
# ./hostname-webserver.sh
```

## Initial web-server Test

We'll startup a small web server that simply responds back with a hostname string. This is simply to simulate a web server and to give us some traffic to monitor.

* Log into CirrosClient via SSH using the assigned floating IP
* Verify that the client can connect to the web server on the CirrosWebServer private IP
```bash
$ curl 192.168.2.XXX
```
* Verify that the hostname of the web server is returned as the response from the remote Web Server

## Network Traffic Monitoring

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
openstack port list --server WebClient
```

* Create the Flow Classifier
```bash
neutron flow-classifier-create \
  --description "HTTP traffic from WebClient" \
  --logical-source-port f9d265a7-90e2-41e1-8cf6-0d142e153d0b \
  --ethertype IPv4 \
  --protocol tcp \
  --destination-port 80:80 WebClientOutboundFlowClassifier
```

* Create the Port Pair
```bash
neutron port-pair-create \
  --description "NetMon" \
  --ingress p1 \
  --egress p2 PP1
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
  --flow-classifier WebClientOutboundFlowClassifier PC1
```



