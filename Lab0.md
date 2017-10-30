
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

Spin up all the virtual machines (web client, web server, and security function VMs), setup the L2 ports, and setup the chains.

```bash
bash Lab0-create.sh
```

List the screens that have been started up as part of the lab.

```bash
screen -ls
```

## Verify Functionality

As part of the setup, the web client hits the web server, through the chain, every 10 seconds. This can be verified on the following screen.

* Verify that the web client is hitting the webserver

```bash
screen -r webclient
ctrl-A ctrl-D
```

* Verify that the NetMon instance is seeing data via tcpdump

As part of the setup, a virtualized security function (tcpdump) is monitoring the traffic as the chain sends it through. This can be verified on the following screen.

```bash
screen -r tcpdump
ctrl-A ctrl-D
```

## Verify Setup

Take a look at the virtual machines and layer 2 & 3 networking to visualize the setup.

* Via the OpenStack dashboard examine the following pages:
* Project->Compute->Instances
* Project->Network->Network Topology->{Graph,Topology}
* Project->Network->Networks->Internal->Ports

## Verify Service Function Chain components

Examine the flow classifier to see what traffic is sent through the chain.

* Examine the Flow Classifier
```bash
openstack sfc flow classifier list
```

* Examine the Port Chains, Groups and Pair

Examine the port pairs/groups/chains to see how the traffic is chained.

```bash
openstack sfc port chain list
openstack sfc port pair group list
openstack sfc port pair list
```

## Tear down the Lab

Tear down the lab so the environment is ready for the next lab.

```bash
bash Lab0-delete.sh
```




