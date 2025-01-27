#!/bin/bash

# Set environment to avoid interactive prompts
export DEBIAN_FRONTEND="noninteractive"

# Define log file
LOG_FILE="/var/log/bootstrap_script.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting bootstrap script at $(date)"

# Ensure script exits on failure
set -e

# Update and upgrade system
echo "Updating and upgrading the system..."
apt update
apt-get upgrade -y
apt-get dist-upgrade -y

# Fix SSH permissions
echo "Fixing SSH permissions..."
chown root:root /root/.ssh/*
cp -rp /root/.ssh /home/gagan/
chown -R gagan:gagan /home/gagan/.ssh
chmod -R og-rxw /home/gagan/.ssh

# Add entry to /etc/hosts
echo "Adding harbor2.int.capoptix.com to /etc/hosts..."
if ! grep -q '192.168.4.64 harbor2.int.capoptix.com' /etc/hosts; then
  echo '192.168.4.64 harbor2.int.capoptix.com' >> /etc/hosts
fi

# Install required packages
echo "Installing required packages..."
apt-get install -y \
  ansible \
  git \
  open-vm-tools \
  curl \
  apt-transport-https \
  gpg \
  openssl \
  net-tools \
  unzip

# Git operations in /root/bootstrap-server
echo "Cloning bootstrap-server repository..."
cd /root/
rm -rf bootstrap-server
git clone git@gitlab.int.capoptix.com:p9/devops/bootstrap-server.git
cd bootstrap-server
git checkout packer
git pull
exit 1

# Retrieve IP and last octet
echo "Fetching IP address and last octet..."
IP='$(hostname -I | awk '{print $1}')'

if [[ -z "$IP" ]]; then
  echo "Error: Could not fetch IP address. Exiting..."
  exit 1
fi

echo "Fetched IP Address: $IP"

IP_LAST_OCTET=$(echo "$IP" | awk -F. '{if (NF==4) print $4; else print "INVALID"}')

if [[ "$IP_LAST_OCTET" == "INVALID" ]]; then
  echo "Error: Invalid IP format detected. Exiting..."
  exit 1
fi

echo "Extracted Last Octet: $IP_LAST_OCTET"

# Update or create hostInfo.yml file
FILE_PATH="/root/bootstrap-server/hostInfo.yml"
if [ -f "$FILE_PATH" ]; then
  echo "Removing existing file at $FILE_PATH..."
  rm -f "$FILE_PATH"
fi

echo "Creating new hostInfo.yml file..."
cat <<EOF > "$FILE_PATH"
[all:vars]
ansible_user=root

[servers]
$IP domain='app${IP_LAST_OCTET}dev.int.capoptix.com' domain_files='app${IP_LAST_OCTET}dev-files.int.capoptix.com' env='custom'
EOF

echo "File created at $FILE_PATH:"
cat "$FILE_PATH"

# Clean up package cache
echo "Cleaning up package cache..."
apt-get clean -y
apt-get autoclean -y
apt-get autoremove -y

echo "Bootstrap script completed successfully at $(date)"