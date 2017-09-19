
# Lab 2 - Chained Security Function

# Overview

In this exercise we'll be building a more complex service chain sending traffic through two service functions chained together. This includes setting up the service chain and the virtual security functions. 


# Goals

  * Build two virtual security function in virtual machines
  * Setup a service chain incorporating both virtual security functions
  * Monitor inbound web (HTTP) traffic from the client to web server
  * Block inbound web (HTTP) traffic from the client to the web server

# Prereq

## Log into Horizon and OpenStack Controller
  * User the credentials and lab information provided on the lab handout
  * Your OS (SSH) and Horizon login will be in the form of userNN with NN being a two digit number (including leading zero)
  * The userNN login will be used for the physical OpenStack controller and Horizon login
  * Virtual machine logins will generic login account details below

## Networking Setup

There's no need to run this command if the security groups are already setup from lab 1. Rerunning the commands will result in a warning if the security groups are already in place but won't cause any harm.

  * Setup network security groups to allow SSH and HTTP to the project from your laptop external network
```bash
openstack security group rule create --dst-port 80 --protocol tcp --ingress default
openstack security group rule create --dst-port 22 --protocol tcp --ingress default
```

# Lab Steps
## Network Monitoring Ports

Create six ports to be used for the monitoring. These will be the inbound and outbound traffic ports for the network monitoring virtual machines. Create ports for the web client and web server virtual machines. See Lab #1 for the CLI syntax. Hint: openstack port create --network internal port-name....

| Port              | Network       | Purpose                             |
| ------------------|:--------------|:------------------------------------|
| port-ingress1     | internal      | service function 1 traffic ingress  |
| port-egress1      | internal      | service function 1 traffic egress   |
| port-admin1       | internal      | service function 1 management       |
| port-ingress2     | internal      | service function 2 traffic ingress  |
| port-egress2      | internal      | service function 2 traffic egress   |
| port-admin2       | internal      | service function 2 management       |
| port-webclient    | internal      | traffic source                      |
| port-webserver    | internal      | traffic consumer                    |




## Instances

Startup the following five images. This can be done via Horizon or the OpenStack CLI. See Lab #1 for the CLI syntax.

| Instance Name | Image         | Flavor  | Ports                                        | 
| ------------- |:-------------:| -------:|---------------------------------------------:|
| webclient     | cirros        | m1.tiny | port-webclient                               |
| webserver     | cirros        | m1.tiny | port-webserver                               |
| netmon1       | NetMon        | m1.small| port-admin1, port-ingress1, port-egress1     |
| netmon2       | NetMon        | m1.small| port-admin2, port-ingress2, port-egress2     |

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


NETMON2_ADMIN_IP=$(openstack port show port-admin2 -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
echo NETMON2_ADMIN_IP=$NETMON2_ADMIN_IP
```

## Startup the Web Server

We'll startup a small web server that simply responds back with a hostname string. This is simply to simulate a web server and to give us some traffic to monitor. See lab #1 for the CLI syntax.

## IP Forwarding and Routing Setup

* Setup routes to/from webclient and webserver on netmon1 and netmon2

See Lab #1 for the CLI syntax. Be sure to turn on IP Forwarding and setup the routes on both virtual machines netmon1 and netmon2.

## Service Chaining

Create a new service chain that sends HTTP traffic from the web client to the web server through both netmon1 and netmon2.

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
openstack sfc port pair create --ingress=port-ingress2 --egress=port-egress2 Netmon2-PortPair
openstack sfc port pair group create --port-pair Netmon1-PortPair Netmon1-PairGroup
openstack sfc port pair group create --port-pair Netmon2-PortPair Netmon2-PairGroup
openstack sfc port chain create --port-pair-group Netmon1-PairGroup --port-pair-group Netmon2-PairGroup --flow-classifier FC-WebServer-HTTP PC1
```

## Enable Monitoring/IDS Functions

See Lab #1 for the commands to startup TCPDump or Snort.  Startup either TCPDump or Snort IDS (not IPS) on each of netmon1 and netmon2. Only run one function on each monitor.

* Monitor traffic through the netmon1 service function with TCPDump or Snort IDS
* Monitor traffic through the netmon2 service function with TCPDump or Snort IDS

## Generate traffic through Service Chain

From the WebClient, we'll hit the WebServer, using curl, to generate traffic through the chain and the service function.

* Run a curl from the WebClient to the WebServer

* Verify that the the remote web server responds

* Verify that the netmon1 and netmon2 service functions saw the traffic via TCPDump or Snort

## Tear down the lab

* Delete the webclient, webserver, netmon1 and netmon2 virtual machines
* Delete the service chain components
* Delete the network ports
