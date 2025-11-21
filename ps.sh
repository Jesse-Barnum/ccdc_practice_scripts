#!/bin/bash
set -e

# Update package list
sudo apt-get update

# Install prerequisites
sudo apt-get install -y wget apt-transport-https software-properties-common

# Import Microsoft GPG key
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb

# Register Microsoft repository
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package list again
sudo apt-get update

# Install PowerShell
sudo apt-get install -y powershell

echo "✔ PowerShell installed successfully. Run it using: pwsh"
