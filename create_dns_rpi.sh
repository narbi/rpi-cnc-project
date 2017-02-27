#!/bin/bash
# Description: This script will setup a DNS server on a Respberry pi
# Author: Christina Skouloudi
# Year: 2017
# https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/

# Basics - Check connection, then update
if [[ "$(ping -c 1 8.8.8.8 | grep '100% packet loss' )" != "" ]]; then
    echo "Internet isn't present, please connect and try again"
    exit 1

# PACKAGES Update & Install dnsmasq for DNS server and Access Point 
sudo apt-get update -y
sudo apt-get install dnsutils dnsmasq hostapd -y

#
read -p "Please connect via ethernet to continue and press y <y/N> " prompt
if [[ $prompt =~ [yY](es)* ]] then
    #static IP addr to work as DHCP server and network and broadcast IPs
    echo -e "What is the static IP you would you like to give to this device? (eg. 192.168.66.100)" 
    read staticip
    networkip = echo $staticip | sed 's/\.[0-9]*$/.0/';
    broadcastip = echo $staticip | sed 's/\.[0-9]*$/.255/';
    
    echo -e "What is the SSID of the local network you will connect?" 
    read myssid
    
    echo -e "Give the pass of this Wifi you will connect:" 
    read wpapass
    
    echo -e "What is the min IP you would like the DHCP server to assign ? (eg. 192.168.66.100)" 
    read rangemin
    
    echo -e "What is the max IP you would like the DHCP server to assign ? (eg. 192.168.66.200)" 
    read rangemax
    
    # Create the records
    # sudo echo 'search $domainname \n nameserver 127.0.0.1' >> /etc/resolv.conf
    sudo echo 'denyinterfaces wlan0' >> /etc/dhcpcd.conf  
    sudo echo 'allow-hotplug wlan0 \n iface wlan0 inet static \n address $staticip \n netmask 255.255.255.0 \n network $networkip \n broadcast $broadcastip
    \n wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf' >> /etc/network/interfaces
    sudo service dhcpcd restart
    sudo ifdown wlan0 
    sudo ifup wlan0

    # content to hostapd.conf
    # sudo touch /etc/hostapd/hostapd.conf
    echo "\# WiFi Interface \n interface=wlan0 \n \# Use the nl80211 driver with the brcmfmac driver \n driver=nl80211 \n \# This is the name of the network \n ssid=$myssid \n \# Use the 2.4GHz band \n hw_mode=g \n \# Use channel 6 \n channel=6 \n \# Enable 802.11n \n ieee80211n=1 \n \# Enable WMM \n wmm_enabled=1 \n \# Enable 40MHz channels with 20ns guard interval \n  ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40] \n \# Accept all MAC addresses \n macaddr_acl=0 \n \# Use WPA authentication \n auth_algs=1 \n \# Require clients to know the network name \n ignore_broadcast_ssid=0 \n \# Use WPA2 \n wpa=2 \n \# Use a pre-shared key \n wpa_key_mgmt=WPA-PSK \n \# The network passphrase \n wpa_passphrase=$wpapass \n \# Use AES, instead of TKIP \n rsn_pairwise=CCMP \n" > /etc/hostapd/hostapd.conf

    #Check if it's working
    sudo /usr/sbin/hostapd /etc/hostapd/hostapd.conf
    # find  #DAEMON_CONF="" and replace it with DAEMON_CONF="/etc/hostapd/hostapd.conf" in /etc/default/hostapd 
    sed -i 's/\#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd\.conf"/g' /etc/default/hostapd
    
    # Configure dnsmasq
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig  
    echo "interface=wlan0 \n \# Use interface wlan0 \n listen-address= $staticip \n \# Explicitly specify the address to listen on \n bind-interfaces \# Bind to the interface to make sure we aren't sending things elsewhere \n server=127.0.0.1 \n \# Forward DNS requests? \n domain-needed \# Don't forward short names \n bogus-priv \# Never forward addresses in the non-routed address spaces.\n  dhcp-range=$rangemin,$rangemax,12h \# Assign IP addresses within range with a 12 hour lease time \n  " > /etc/dnsmasq.conf 
    
    # Set up IPv4 forwarding
    sed -i 's/\#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  
    sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
    sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT  

    # restart everything 
    sudo service hostapd start  
    sudo service dnsmasq start  
    
else 
    exit 1
   
fi
