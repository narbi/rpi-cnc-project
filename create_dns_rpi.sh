#!/bin/bash
# Description: This script will setup a DNS server on a Respberry pi
# Author: Christina Skouloudi
# Year: 2017
# https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/
# http://elinux.org/RPI-Wireless-Hotspot

# Basics - Check connection, then update
if [[ "$(ping -c 1 8.8.8.8 | grep '100% packet loss' )" != "" ]]; then
    echo "Internet isn't present, please connect and try again"
    exit 1
fi
# PACKAGES Update & Install dnsmasq for DNS server and Access Point 
#sudo apt-get update -y
sudo apt-get install dnsutils dnsmasq hostapd udhcpd -y

echo -e "Please connect via ethernet to continue and press y <y/N> " 
read prompt
if [[ $prompt =~ [yY](es)* ]] then
    #static IP addr to work as DHCP server and network and broadcast IPs
    echo -e "What is the static IP you would you like to give to this device? (eg. 192.168.66.100)" 
    read staticip
    networkip = echo $staticip | sed 's/\.[0-9]*$/.0/';
    routerip = echo $staticip | sed 's/\.[0-9]*$/.1/';
    broadcastip = echo $staticip | sed 's/\.[0-9]*$/.255/';
    
    echo -e "What is the SSID of the local network you will connect?" 
    read myssid
    
    echo -e "Give the pass of this Wifi you will connect:" 
    read wpapass
    
    echo -e "What is the min IP you would like the DHCP server to assign ? (eg. 192.168.66.100)" 
    read rangemin
    
    echo -e "What is the max IP you would like the DHCP server to assign ? (eg. 192.168.66.200)" 
    read rangemax
    
    # Configure udhcpd
    sudo echo -e "start $rangemin # This is the range of IPs that the hostspot will give to client devices.\nend $rangemax\ninterface wlan0 # The device uDHCP listens on.\nremaining yes\nopt dns 127.0.0.1 # The DNS servers client devices will use.\n opt subnet 255.255.255.0\nopt router $routerip # The Pi's IP address on wlan0.\nopt lease 864000 # 10 day DHCP lease time in seconds" >> /etc/udhcpd.conf 
    sed -i 's/DHCPD_ENABLED="no"/\#DHCPD_ENABLED="no"/g' /etc/default/udhcpd 
    
    echo -e "Configuring static IP and DHCP settings.."
    sudo echo 'denyinterfaces wlan0' >> /etc/dhcpcd.conf  
    sudo echo -e "allow-hotplug wlan0\niface wlan0 inet static\n\taddress $staticip\n\tnetmask 255.255.255.0\n\tnetwork $networkip\n\tbroadcast $broadcastip\n#wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf" >> /etc/network/interfaces
    sudo service dhcpcd restart
    sudo ifdown wlan0 
    sudo ifup wlan0
    
    echo -e "Setting up the hostapd configuration file.."
    echo -e "#WiFi Interface\ninterface=wlan0\n#Use the nl80211 driver with the brcmfmac driver\ndriver=nl80211\n#This is the name of the network\nssid=$myssid\n#Use the 2.4GHz band\nhw_mode=g\n#Use channel 6\nchannel=6\n#Enable 802.11n\nieee80211n=1\n#Enable WMM\nwmm_enabled=1\n# Enable 40MHz channels with 20ns guard interval\nht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]\n#Accept all MAC addresses\nmacaddr_acl=0\n#Use WPA authentication\nauth_algs=1\n#Require clients to know the network name\nignore_broadcast_ssid=0\n#Use WPA2\nwpa=2\n# Use a pre-shared key\nwpa_key_mgmt=WPA-PSK\n#The network passphrase\nwpa_passphrase=$wpapass\n#Use AES, instead of TKIP\nrsn_pairwise=CCMP \n" > /etc/hostapd/hostapd.conf

    #Check if it's working
    echo -e "Checking hostapd is working correctly.."
    sudo /usr/sbin/hostapd /etc/hostapd/hostapd.conf
    # find  #DAEMON_CONF="" and replace it with DAEMON_CONF="/etc/hostapd/hostapd.conf" in /etc/default/hostapd 
    sed -i 's/\#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd\.conf"/g' /etc/default/hostapd
    
    # Configure dnsmasq
    echo -e "Configuring dnsmasq.."
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig  
    echo -e "interface=wlan0\n#Use interface wlan0\nlisten-address= $staticip\n # Explicitly specify the address to listen on\nbind-interfaces\n# Bind to the interface to make sure we aren't sending things elsewhere\nserver=127.0.0.1\n# Forward DNS requests? \n domain-needed # Don't forward short names\nbogus-priv # Never forward addresses in the non-routed address spaces.\ndhcp-range=$rangemin,$rangemax,12h # Assign IP addresses within range with a 12 hour lease time\n" > /etc/dnsmasq.conf 
    
    # Set up IPv4 forwarding
    echo -e "Setting up IPv4.."
    sed -i 's/\#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  
    sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
    sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT  
    sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
    sudo echo -e "up iptables-restore < /etc/iptables.ipv4.nat" >> /etc/network/interfaces 

    # restart everything 
    sudo service hostapd start  
    sudo service dnsmasq start  
    sudo service udhcpd start
    
    sudo update-rc.d hostapd enable
    sudo update-rc.d udhcpd enable
    
else 
    exit 1
   
fi
