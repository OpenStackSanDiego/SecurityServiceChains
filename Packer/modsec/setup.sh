#!/bin/bash

set -e

# We are using Fedora 27 b/c it has a new enough mod_security to work with the
# CRS rules which require at least 2.8.
dnf install mod_security git wget unzip iptables tcpdump -y

# Configure eth1 and eth2 to just be up so that they can be used without having
# to manually do ip link set ethx up
for i in eth1 eth2; do
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$i
BOOTPROTO=none
DEVICE=$i
ONBOOT=yes
TYPE=Ethernet
USERCTL=no
EOF
done

cd /etc/httpd/modsecurity.d

# Remove existing directories
rm -rf /etc/httpd/modsecurity.d/*

# Download CRS rules and install them
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs .
cp crs-setup.conf.example crs-setup.conf
mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

# Bring in a proxy.conf that is almost setup to use, and setup mod_security.conf
# so that it will pull in the right rules and also not drop connections by
# default, instead just log
mv /tmp/proxy.conf /etc/httpd/conf.d/proxy.conf
mv /tmp/mod_security.conf /etc/httpd/conf.d/mod_security.conf

# Ensure http can use network
/usr/sbin/setsebool -P httpd_can_network_connect 1

# Ensure httpd will startup at boot time
systemctl enable httpd
