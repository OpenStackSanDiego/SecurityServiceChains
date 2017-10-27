
# Lab 0 - Prebuild Lab

# Overview

This demo lab automatically sets up a full environment with all security functions and service chains preconfigured. The intent is to showcase the end functionality before running the other labs where everything is setup by hand.

In this demo, a chain is setup to monitor traffic between a web client and a web server. The web client is setup to hit (curl) the web server every 10 seconds. The chain directs the traffic through the NetMon instance which is running TCPDump to monitor the traffic.

# Goals

  * Understand the final end setup of a security service chain
  * Use this knowledge to setup a chain from scratch in the lab exercises

# Prereq

  * Use the credentials and lab information provided on the lab handout
  * Your OS (SSH) and Horizon login will be in the form of userN with N being a one or two digit number
  * The userN login will be used for the physical OpenStack controller and Horizon login
  * SSH client (i.e. PuTTY or Secure Shell plugin for Chrome)

# Lab Steps

## Log into Horizon and OpenStack Controller

  * Log into the OpenStack dashboard via a web brower using the credentials provided
  * Log into the controller via SSH using the credentials provided
    
## Setup the Lab

```bash
bash Lab0-create.sh
```

## Verify Functionality

* Verify that the web client is hitting the webserver

```bash
screen -r webclient
ctrl-A ctrl-D
```

* Verify that the NetMon instance is seeing data via tcpdump
```bash
screen -r tcpdump
ctrl-A ctrl-D
```

## Verify Setup

* Via the OpenStack dashboard examine the following pages:
* Project->Compute->Instances
* Project->Network->Network Topology->{Graph,Topology}
* Project->Network->Networks->Internal->Ports

## Verify Service Function Chain components

* Examine the Flow Classifier
```bash
openstack sfc flow classifier list
```

* Examine the Port Chains, Groups and Pair
```bash
openstack sfc port chain list
openstack sfc port pair group list
openstack sfc port pair list
```

## Tear down the Lab

```bash
bash Lab0-delete.sh
```




