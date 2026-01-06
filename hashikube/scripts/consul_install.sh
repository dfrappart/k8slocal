#!/bin/sh

# Add current node in  /etc/hosts
echo "127.0.1.1 $(hostname)" >> /etc/hosts
echo "192.168.56.33 $(hostname)" >> /etc/hosts
echo "192.168.56.32 vault1" >> /etc/hosts
echo "192.168.56.31 hashikube1" >> /etc/hosts

# Get current IP adress
export currentip=$(/sbin/ip -o -4 addr list enp0s8 | awk '{print $4}' | cut -d/ -f1)

# Add Hashicorp repository

wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install consul & prereq

sudo apt update
sudo apt install consul net-tools apt-transport-https gnupg curl wget bat -y
