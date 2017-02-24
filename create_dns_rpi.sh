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
echo -e "What is the static IP you would you like to give to this device? (eg. 192.168.66.100)" 
read staticip

# networkip = awk  '$staticip {gsub(".[0-9]*",".0",$4)}';
# broadcastip = awk  '$staticip {gsub(".[0-9]*",".255",$4)}';

# Install dnsmasq for DNS server and Access Point 
sudo apt-get install dnsutils dnsmasq hostapd -y

# Create the records
sudo echo 'search $domainname \n nameserver 127.0.0.1' >> /etc/resolv.conf
sudo echo 'denyinterfaces wlan0' >> /etc/dhcpcd.conf  
sudo echo 'allow-hotplug wlan0 \n iface wlan0 inet static \n address $staticip \n netmask 255.255.255.0 \n network $networkip \n broadcast $broadcastip
\n wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf' >> /etc/network/interfaces
sudo service dhcpcd restart
sudo ifdown wlan0 
sudo ifup wlan0

# sed * 15 times (settings below)
# sed -i 's/ugly/beautiful/g' /etc/hostapd/hostapd.conf

# content to hostapd.conf
# This is the name of the WiFi interface we configured above
interface=wlan0

# Use the nl80211 driver with the brcmfmac driver
driver=nl80211

# This is the name of the network
ssid=Pi3-AP

# Use the 2.4GHz band
hw_mode=g

# Use channel 6
channel=6

# Enable 802.11n
ieee80211n=1

# Enable WMM
wmm_enabled=1

# Enable 40MHz channels with 20ns guard interval
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]

# Accept all MAC addresses
macaddr_acl=0

# Use WPA authentication
auth_algs=1

# Require clients to know the network name
ignore_broadcast_ssid=0

# Use WPA2
wpa=2

# Use a pre-shared key
wpa_key_mgmt=WPA-PSK

# The network passphrase
wpa_passphrase=raspberry

# Use AES, instead of TKIP
rsn_pairwise=CCMP

# >> /etc/hostapd/hostapd.conf

#Check if it's working
sudo /usr/sbin/hostapd /etc/hostapd/hostapd.conf

#sudo nano /etc/default/hostapd and find the line #DAEMON_CONF="" and replace it with DAEMON_CONF="/etc/hostapd/hostapd.conf"

