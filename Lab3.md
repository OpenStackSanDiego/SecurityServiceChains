
# Lab 3 - Malicious IoT Detection and Blocking

# Overview

A number of malicous IoT (Internet of Things) devices are running on your network! It's your job to analyze the traffic to determine how it is communicating and block the traffic.

Each IoT device is communicating with a "Command and Control" server at least every 60 seconds IP networking. Using TCPDump and/or Snort, determine what remote IP(s) the device is communicating and block that IP. Utilize a second NetMon to verify that the traffic is being blocked.

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

# Lab Steps

## Ports and Instances

Startup the following ports and images using Horizon or the OpenStack CLI.

| Instance Name | Image           | Flavor  | Ports                                        | 
| ------------- |:---------------:| -------:|---------------------------------------------:|
| iot1          | IoT-malicious   | m1.small | port-iot1                                    |
| iot2          | IoT-malicious   | m1.small | port-iot2                                    |
| netmon1       | NetMon          | m1.small| port-admin1, port-ingress1, port-egress1     |
| netmon2       | NetMon          | m1.small| port-admin2, port-ingress2, port-egress2     |

All ports should be on the internal network.

## Create a flow classifier to monitor all traffic
* Create a flow classifier that monitors all traffic
* Hint: removing "--destination-port" from a flow classifier will cover all ports
* Hint: 0.0.0.0/0 can be used as a wildcard IP address
* Utilize NetMon virtual machine(s) to monitor the traffic

## Create a chain to netmon1
* Chain traffic through the single netmon1 function

## Identify using tcpdump
* Hint: "sudo tcpdump -i eth1" will view all traffic from the chain
* Identify the malicious traffic ports and destinations

## Block the malicious traffic
* Update the flow classifier to only catch the malicious traffic by port
* Update the snort rules to block the traffic "/etc/snort/rules/snort-ips.rules"
* Disable IP forwarding on netmon1 before starting snort-ips
* Startup snort-ips and verify traffic is being dropped
* Run tcpdump on the egress port to validate traffic is being dropped

## Tear down the lab

* Delete the netmon and IoT virtual machines
* Delete the service chains (pair groups, port pairs, and flow classifier)
