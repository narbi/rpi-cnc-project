#!/bin/bash
# Description: This script will setup a DNS server on a Respberry pi
# Author: Christina Skouloudi
# Year: 2017

# Basics - Check connection, then update
if [[ "$(ping -c 1 8.8.8.8 | grep '100% packet loss' )" != "" ]]; then
    echo "Internet isn't present, please connect and try again"
    exit 1
sudo apt-get update -y

#static IP addr to work as DHCP server
echo -e "What is the static IP you would you like to give to this device?" 
read staticip

# Install bind9 for DNS server
sudo apt-get install bind9 bind9-docs dnsutils -y

# Install dnsmasq for DNS server and Access Point 
sudo apt-get install dnsmasq hostapd -y

# Checking the Status of the Server
if [[ "$(service bind9 status| grep 'ok')" != "" ] then
echo "bind service is running\n"

# Create the records
sudo echo 'search $domainname \n nameserver 127.0.0.1' >> /etc/resolv.conf

# Append the zone in the file 
sudo echo 'zone "$domainname"{type master;\n file "/etc/bind/$domianname";\n };' >> name.conf.local
cat $domainname.zone

rndc reload $domainname

echo "DNS Server setup completed."
