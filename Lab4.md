
# Lab 4 - WAF NFV

# Overview

Web Application Firewalls, WAFs, provide layer 7 monitoring and can manage web traffic. A web proxy, such as Apache with [Mod Security](https://www.modsecurity.org/), can be configured as a WAF. In this lab, a WAF will be installed and configured as a virtual security function as part of a service chain.

# Goals

  * Deploy a mod security based virtual machine
  * Configure that virtual machine to properly route packets through the WAF
  * Configure a service chain to use the WAF
  * Validate that the WAF is inline of the chain and can either alert or block malicious web traffic

# Prereq

## Log into Horizon and OpenStack Controller
  * User the credentials and lab information provided on the lab handout
  * Your OS (SSH) and Horizon login will be in the form of userNN with NN being a two digit number (including leading zero)
  * The userNN login will be used for the physical OpenStack controller and Horizon login
  * Virtual machine logins will generic login account details below

## Networking Setup
  * Setup network security groups to allow SSH and HTTP to the project from your laptop/controller to the virtual networks
```bash
openstack security group rule create --dst-port 80 --protocol tcp --ingress default
openstack security group rule create --dst-port 22 --protocol tcp --ingress default
```

# Lab Steps

## Ports and Instances

Startup the following ports and images using Horizon or the OpenStack CLI.

| Port              | Network       | Purpose                             |
| ------------------|:--------------|:------------------------------------|
| port-ingress1     | internal      | service function traffic ingress    |
| port-egress1      | internal      | service function traffic egress     |
| port-admin1       | internal      | service function management         |
| port-webclient    | internal      | traffic source                      |
| port-webserver    | internal      | traffic consumer                    |

## Instances

Startup the following instances. This can be done via Horizon or the OpenStack CLI. See Lab #1 for the CLI syntax.

| Instance Name | Image         | Flavor  | Ports                                        |
| ------------- |:-------------:| -------:|---------------------------------------------:|
| webclient     | cirros        | m1.tiny | port-webclient                               |
| webserver     | cirros        | m1.tiny | port-webserver                               |
| modsec1       | ModSec        | m1.small| port-admin1, port-ingress1, port-egress1     |

## Save IP Address Assignments

For simplicity sake, save the IP addresses assigned to each port to a shell variable to be used later in the lab.

```bash
WEBCLIENT_IP=$(openstack port show port-webclient -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
export WEBCLIENT_IP=$WEBCLIENT_IP

WEBSERVER_IP=$(openstack port show port-webserver -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
export WEBSERVER_IP=$WEBSERVER_IP

MODSEC1_ADMIN_IP=$(openstack port show port-admin1 -f value -c fixed_ips | \
	grep "ip_address='[0-9]*\." | cut -d"'" -f2)
export MODSEC1_ADMIN_IP=$MODSEC1_ADMIN_IP
```

## Configure Apache's proxy.conf

ssh into the modsec1 instance and edit `/etc/httpd/conf.d/proxy.conf` changing the `WEBSERVER_IP` to be the IP address of the webserver that was created. Also uncomment the `ProxyPass` and `ProxyPassReverse` lines as well. This will allow Apache to proxy to the backend webserver.

Make sure to reload Apache/httpd once the file has been edited and configured properly.

```bash
$ systemctl reload httpd
```

## IP Forwarding and Routing Setup

* On the ModSec instance, setup routes to/from webclient and webserver

See Lab #1 for the CLI syntax. Be sure to turn on IP Forwarding and setup the routes on all netmon instances.

* Setup IPTables to forward traffic destined for the `WEBSERVER_IP` to the `MODSEC1_ADMIN_IP` so that the traffic will go through mod security.

```bash
ssh fedora@{$MODSEC1_ADMIN_IP} \
'sudo iptables -t nat -A PREROUTING -p tcp -d {$WEBSERVER_IP} --dport 80 -j NETMAP --to ${MODSEC1_ADMIN_IP}'
```

## Service Chaining

Create a new service chain that sends HTTP traffic from the web client to the web server through the modsec instance.

## Generate traffic through Service Chain

First, login to the modsec1 instance and run:

```
modsec1$ sudo tail -f modsec_audit.log
```

Fake a directory traversal attack.

```bash
ssh fedora@${WEBCLIENT_IP} curl -s ${WEBSERVER_IP}/?abc=../../
```

The attack should be logged by mod security in the audit log.

## Tear down the lab

* Delete all the virtual instances
* Delete the service chains (pair groups, port pairs, and flow classifier)
