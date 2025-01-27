#!/bin/bash

# Script to automatically set a static IP address on the primary network interface

# Define your static IP configuration
STATIC_IP="192.168.4.202"
NETMASK="255.255.255.0"
GATEWAY="192.168.4.1"
DNS1="8.8.8.8"
DNS2="8.8.4.4"

# Automatically get the primary network interface
INTERFACE=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")

# Create or replace the network configuration file
cat <<EOF | sudo tee /etc/network/interfaces.d/$INTERFACE
# The primary network interface
auto $INTERFACE
iface $INTERFACE inet static
    address $STATIC_IP
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS1 $DNS2
EOF

# Restart networking service
#sudo systemctl restart networking.service

echo "Static IP configuration applied to $INTERFACE"
