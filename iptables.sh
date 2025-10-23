#!/bin/bash

sudo iptables -F
sudo iptables -X

sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT  # SSH
sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT  # HTTP
sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT # HTTPS
sudo iptables -A OUTPUT -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT #DNS
sudo iptables -A OUTPUT -p tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT #dns
sudo iptables -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT  # HTTP
sudo iptables -A OUTPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT #HTTPS
sudo iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

sudo iptables -A INPUT -j LOG_AND_DROP

sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP # Also good practice
sudo iptables -P OUTPUT DROP

echo "Firewall rules applied:"
sudo iptables -L -n -v --line-numbers

echo "Installing persistence package..."
sudo apt-get install -y iptables-persistent
echo "Saving rules..."
sudo netfilter-persistent save

echo "Firewall setup complete and saved."
