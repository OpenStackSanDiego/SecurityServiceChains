
# Lab 3 - Malicious IoT Detection and Blocking

# Overview

A number of malicous IoT (Internet of Things) devices are running on your network! It's your job to analyze the traffic to determine how it is communicating and block the traffic.

Each IoT device is communicating with a "Command and Control" server at least every 60 seconds using either TDP or UDP. Using TCPDump and/or Snort, determine what remote IP(s) the device is communicating and block that IP. Utilize a second NetMon to verify that the traffic is being blocked.

No login credentials are provided for the IoT box. You should consider it a black box where you can only examine traffic in/out of the virtual machine.

# Goals

  * Detect outbound message by the rogue IoT device
  * Block and log the malicious messages
  * Utilize service chains to manipulate the packet flows

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
  * No access to the "IoT-Malicious" image is provided

# Lab Steps
## Network Monitoring Ports

Create four ports on the service network to be used for the monitoring. These will be the inbound and outbound traffic ports for the network monitoring virtual machine (netmon).
```bash
$ openstack port create --network service ingres-1
$ openstack port create --network service egress-1
$ openstack port create --network service ingres-2
$ openstack port create --network service egress-2
```
## Instances

Startup the following three images and assign floating IPs to all. This can all be done via Horizon.

| Instance Name | Image         | Flavor  | Network(s)      | Floating IP | Additional Ports            |
| ------------- |:-------------:| -------:|----------------:|------------:|----------------------------:|
| IoT-1         | IoT-malicious | m1.small | internal       | none        |                             |
| IoT-2         | IoT-malicious | m1.small | internal       | none        |                             |
| NetMon1       | NetMon        | m1.small | internal       |  assign     | ingress-1, egress-1         | 
| NetMon2       | NetMon        | m1.small | internal       |  assign     | ingress-2, egress-2         | 

Ensure floating IPs are assigned to the NetMon instances.

## Monitor for malicious traffic

* Utilize NetMon virtual machine(s) to monitor the traffic
* Utilize tcpdump and/or snort to monitor the traffic
* "whois" will help translate remote IP addresses to services
* Create a service chain to monitor traffic from the IoT devices
* Traffic can be monitored from the individual IoT device ports or via the gateway port

## Block the malicious traffic

* Update the NetMon virtual machine(s) to block the traffic
* Build a snort command to block the traffic from the malicious IoT devices
* Update/Replace the service chain as needed
* Verify that the traffic is no longer being sent over the Internet

## Tear down the lab

* Delete the NetMon virtual machines
* Delete the service chains (pair groups, port pairs, and flow classifier)
* Delete the IoT-malicious virtual machines
