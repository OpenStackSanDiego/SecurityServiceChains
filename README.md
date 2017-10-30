# ServiceChains

## Overview

This workshop will teach you how to use network rule chains to push traffic through security functions. This allows security functions, such as network monitors, IDS/IPS, web filters and web proxies, to be placed inline with the network traffic without having to route traffic through layer 3 IPs.

To learn a little more about this workshop, how it came about, why it makes sense to run layer 2 service chains and how the lab is configured, please read:

* [About this Workshop] (../blob/master/AboutThisWorkshop.md)

## Cloud Assignments

Each workshop attendee is provided an OpenStack cloud preconfigured with the required networking plugins to support service chains. When you arrive at the workshop, you'll be assigned a lab (IP address) and a password.

As part of this workshop, each attendee will be assigned a physical server running their own private OpenStack cloud. This physical server can be access via SSH and the Horizon GUI. Each physical server has 32 GB of RAM and 6 floating IP addresses. This allows six virtual machines to run comfortably in the cloud. The floating IP addresses allow remote network access to the virtual machines.

## Workshop Exercises

This workshop consists of a number of exercises going from the basics through more advanced configurations. Once you've completed the steps below to familiarize your self and configure the lab, please proceed to the exercises.

* Lab 0 https://github.com/OpenStackSanDiego/SecurityServiceChains/blob/master/Lab0.md
* Lab 1 https://github.com/OpenStackSanDiego/SecurityServiceChains/blob/master/Lab1.md
* Lab 2 https://github.com/OpenStackSanDiego/SecurityServiceChains/blob/master/Lab2.md
* Lab 3 https://github.com/OpenStackSanDiego/SecurityServiceChains/blob/master/Lab3.md

# Answers

If you get stuck, the "answers" to the lab are available as a list of command lines.

* Lab 1 Answers https://github.com/OpenStackSanDiego/SecurityServiceChains/blob/master/Lab1-Answers.sh


