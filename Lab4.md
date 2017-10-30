
# Lab 4 - WAF NFV

# Overview

Web Application Firewalls, WAFs, provider layer 7 monitoring and blocking of web traffic. A web proxy, such as nginx, can be configured to run as a WAF. In this lab, nginx will be installed and configured as a virtual security function as part of a service chain. 

# Goals

  * Virtualize nginx for use in a SFC
  * Create a SFC that uses the new VM

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

Create enough ports to have two virtual security functions (tcpdump/snort and nginx) as well as a webclient and a webserver. Refer back to lab 2 for details on this setup as needed.

Utilizing the NetMon baseline, install and configure nginx as an additional function. 

All ports should be on the internal network.

## Create the virtual security function

Within the virtual instance, install and configure nginx to handle traffic delivered via the service chain.

* Disable SELinux

```bash
sed -i /etc/selinux/config -r -e 's/^SELINUX=.*/SELINUX=disabled/g'
yum -y install epel-release
reboot
```

* Install nginx

```bash
yum -y install nginx
```

* Configure nginx

```bash
vi /etc/nginx/nginx.conf
```

* Startup nginx

```bash
service nginx start
```

* Setup the routing through the virtual machine
```bash
sudo ip route add ${WEBCLIENT_IP} dev eth1
sudo ip route add ${WEBSERVER_IP} dev eth2
```

* Setup iptables rules to rewrite inbound traffic to web server

* Setup iptables rules to rewrite outbound traffic from web server

## Create a flow classifier and service chain

Refer back to the earlier labs for the syntax on creating port pairs/groups/chains and flow classifiers.

* Create a flow classifier that monitors from the web client to the web server
* Chain traffic through all the virtualized security functions

## Generate traffic
* From the web client, generate web traffic to the web server

## Monitor Traffic
* Validate that traffic through the nginx server is being monitored and logged.

```bash
tail -f /var/log/nginx/proxy_access.log
```

## Tear down the lab

* Delete all the virtual instances
* Delete the service chains (pair groups, port pairs, and flow classifier)
