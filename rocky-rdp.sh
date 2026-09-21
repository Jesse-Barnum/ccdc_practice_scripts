#!/bin/bash
# Lab setup: INTENTIONALLY INSECURE xrdp on Rocky Linux 9

# 1. Desktop environment + xrdp (EPEL required on Rocky)
sudo dnf install -y epel-release
sudo dnf groupinstall -y "Xfce"
sudo dnf install -y xrdp xorgxrdp

# 2. Enable (survives reboot) and start
sudo systemctl enable --now xrdp

# 3. Firewall: INTENTIONALLY wide open - students must restrict this
sudo firewall-cmd --permanent --add-port=3389/tcp
sudo firewall-cmd --reload

# 5. Downgrade to legacy RDP encryption: no TLS, no NLA
sudo sed -i -E 's/^[;#]?\s*security_layer\s*=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini
sudo sed -i -E 's/^[;#]?\s*ssl_protocols\s*=.*/ssl_protocols=TLSv1, TLSv1.1, TLSv1.2/' /etc/xrdp/xrdp.ini

# 6. sesman: allow root login + unlimited password guesses
sudo sed -i -E 's/^[;#]?\s*AllowRootLogin\s*=.*/AllowRootLogin=true/' /etc/xrdp/sesman.ini
sudo sed -i -E 's/^[;#]?\s*MaxLoginRetry\s*=.*/MaxLoginRetry=0/' /etc/xrdp/sesman.ini

sudo systemctl restart xrdp
echo "Done. xrdp listening on 3389 - intentionally insecure."
