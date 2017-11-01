
# Lab 2 - Chained Security Function

# Overview

In this exercise we'll be building a more complex service chain sending traffic through two service functions chained together in a redundant configuration. This will include two tcpdump instances (in a redundant pair) and two Snort instances (in a redundant pair). This involves setting up the service chain and the virtual security functions. 


# Goals

  * Build two virtual security function (tcpdump/snort) in redundant virtual machines
  * Group together multiple port pairs for redundancy
  * Chain traffic through multiple port pair groups
  * Setup a service chain incorporating both virtual security functions
  * Monitor inbound web (HTTP) traffic from the client to web server
  * Block inbound web (HTTP) traffic from the client to the web server

# Prereq

## Log into Horizon and OpenStack Controller
  * User the credentials and lab information provided on the lab handout
  * Your OS (SSH) and Horizon login will be in the form of userNN with NN being a two digit number (including leading zero)
  * The userN login will be used for the physical OpenStack controller and Horizon login

## Networking Setup

There's no need to run this command if the security groups are already setup from lab 1. Rerunning the commands will result in a warning if the security groups are already in place but won't cause any harm.

  * Setup network security groups to allow SSH and HTTP to the project from your laptop external network
```bash
openstack security group rule create --dst-port 80 --protocol tcp --ingress default
openstack security group rule create --dst-port 22 --protocol tcp --ingress default
```

# Lab Steps
## Network Monitoring Ports

Create eight ports to be used for the monitoring. These will be the inbound and outbound traffic ports for the network monitoring virtual machines. Create ports for the web client and web server virtual machines. See Lab #1 for the CLI syntax. Hint: openstack port create --network internal port-name....


| Port              | Network       | Purpose                             |
| ------------------|:--------------|:------------------------------------|
| port-ingress{1-4}     | internal      | service function traffic ingress  |
| port-egress{1-4}      | internal      | service function traffic egress   |
| port-admin{1-4}       | internal      | service function management       |
| port-webclient    | internal      | traffic source                      |
| port-webserver    | internal      | traffic consumer                    |




## Instances

Startup the following four images. This can be done via Horizon or the OpenStack CLI. See Lab #1 for the CLI syntax.

| Instance Name | Image         | Flavor  | Ports                                        | 
| ------------- |:-------------:| -------:|---------------------------------------------:|
| webclient     | cirros        | m1.tiny | port-webclient                               |
| webserver     | cirros        | m1.tiny | port-webserver                               |
| netmon{1-4}      | NetMon        | m1.small| port-admin{1-4}, port-ingress{1-4}, port-egress{1-4}     |


## Save IP Address Assignments

For simplicity sake, save the IP addresses assigned to each port to a shell variable to be used later in the lab. See the previous lab for examples.

## Startup the Web Server

We'll startup a small web server that simply responds back with a hostname string. This is simply to simulate a web server and to give us some traffic to monitor. See lab #1 for the CLI syntax.

## IP Forwarding and Routing Setup

* Setup routes to/from webclient and webserver across all the netmon instances.

See Lab #1 for the CLI syntax. Be sure to turn on IP Forwarding and setup the routes on all netmon instances.

## Service Chaining

Create a new service chain that sends HTTP traffic from the web client to the web server through all the netmon instances.

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

Netmon{1,2} will run tcpdump in a set of two redundant instances.
Netmon{3,4} will run Snort (IDS) in a set of two redunant instances.

* Create the Port Pairs (4 in total)
* Create the Port Pair Groups (2 in total)
* Create the Port Chain (1)

## Enable Monitoring/IDS Functions

See Lab #1 for the commands to startup TCPDump or Snort.

Startup TCPDump on netmon{1,2} and Snort IDS (not IPS) on netmon{3,4} Only run one function on each monitor.

* Monitor traffic through the netmon1 service function with TCPDump or Snort IDS
* Monitor traffic through the netmon2 service function with TCPDump or Snort IDS

## Generate traffic through Service Chain

From the WebClient, we'll hit the WebServer, using curl, to generate traffic through the chain and the service function.

* Run a curl from the WebClient to the WebServer

* Verify that the the remote web server responds

* Verify that the netmon1 and netmon2 service functions saw the traffic via TCPDump or Snort

## Tear down the lab

* Delete the webclient, webserver, and netmon virtual machines
* Delete the service chain components
* Delete the network ports
