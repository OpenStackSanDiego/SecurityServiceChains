
# Lab 1 - Single Security Function

# Overview


# Goals

  * Monitor inbound web (HTTP) traffic from the client to web
  * Utilize service chains to monitor the packet flows

# Prereq

## Networking Setup
  * Setup network security groups to allow SSH and HTTP to the project from your laptop external network
  * Setup the external and internal networking
  
## Image login info
  * admin/openstack for the CirrosWeb image
  * admin/openstack for the NetMon image
  * admin/openstack for the physical server

## Add a security service network

Execute the script to create a service network. This network will be used to inspect the network traffic.

* Source service-net.sh to setup the security service network
```bash
# source service-net.sh
```

## Add a security management network

Execute the script to create a management network. This network will be used to connect to the network monitoring instances.

* Source mgmt-net.sh to setup the security management network
```bash
# source mgmt-net.sh
```

# Instances

Startup the following three images and assign floating IPs to all. 

| Instance Name | Image         | Flavor  | Network(s)      | Floating IP | Interfaces          | Notes                            |
| ------------- |:-------------:| -------:|----------------:|------------:|--------------------:|---------------------------------:|
| Client        | CirrosWeb     | m1.tiny | internal        |  assign     | eth0                | reuse from previous exercise     |
| WebServer     | CirrosWeb     | m1.tiny | internal        |  assign     | eth0                |                                  |
| NetMon        | NetMon        | m1.small| mgmt,service    |  assign     | eth0, eth1          | eth0 to mgmt and eth1 to service | 

Ensure floating IPs are assigned to all instances. Associate the NetMon floating IP to the mgmt network (eth0).


## Startup the Web Server
* Log into CirrosWebServer via SSH using the assigned floating IP
* su to root to gain superuser privileges
```bash
$ sudo su -
```
* Startup the web server via the command "hostname-webserver.sh"
```bash
# ./hostname-webserver.sh &
```

## Initial web-server Test

We'll startup a small web server that simply responds back with a hostname string. This is simply to simulate a web server and to give us some traffic to monitor.

* Log into CirrosClient via SSH using the assigned floating IP
* Verify that the client can connect to the web server on the CirrosWebServer private IP
```bash
$ curl 192.168.2.XXX
```
* Verify that the hostname of the web server is returned as the response from the remote Web Server

## Deallocate the floating IP from web-server

To conserve floating IPs, we'll deallocate the floating IP address from the web server so it can be used for a NetMon instance in a later exercise.

* Deallocate the floating IP from web-server via Horizon

## Network Traffic Monitoring

Next we'll introduce a virtual machine with some network monitoring tools installed (tcpdump and snort)

* Log into NetMon server via SSH using the assigned floating IP 
* Run a TCPDump to monitor for traffic to the client.

```bash
% sudo su -
# tcpdump -i eth1 not port 22
```



## Service Chaining


* Log into the physical OpenStack controller via SSH (labXXX.openstacksandiego.us)
* Load the OpenStack credentials
```bash
% sudo su -
# source keystonerc_admin
```

* Retrieve the UUID of both the web-server and NetMon instance's network ports. This can be retrieved via Horizon or neutron-cli. Also note the web-server MAC address for service chaining configuration.
* Via Horizon Network->Networks->internal->Ports and select the port ID corresponding to the web server and NetMon IP addresses for the web-server-port-UUID & MAC address, and the NetMon-port-UUID.
```bash
% neutron port-list
% neutron port-show <web-server-port-UUID>
```

* Via the `XXX` configure L2-insertion of the NetMon instance for protecting the web-server
```bash
# XXX
```

* Return to NetMon and restart the tcpdump commands to monitor traffic
* Return to Client and rerun the curl commands to generate some network traffic
* Validate that the NetworkMonitor _does_ see the traffic

However, traffic will not traverse between the client and web servers. Network traffic arrives on NetMon but not forward on until a decision is made by some security software tool or the interfaces are bridged to allow traffic to pass. This allows the NetMon virtual machine to block malicious traffic. Next we'll see how to bridge traffic through the interfaces.

