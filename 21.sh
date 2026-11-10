#!/bin/bash
# ==========================================
# INJECT_UBUNTU_21.sh
# Run as root (sudo ./inject_ubuntu_21.sh)
# ==========================================

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

echo "[*] Installing required packages (auditd, vim, netcat-traditional, ufw)..."
apt-get update -qq
apt-get install -y auditd vim netcat-traditional ufw -qq > /dev/null

echo "[*] Injecting 21 Ubuntu Configuration Vulnerabilities..."

# 1. SSH Logging Disabled (LogLevel QUIET)
# 16. SSH GatewayPorts Enabled
sed -i '/^LogLevel/d' /etc/ssh/sshd_config
sed -i '/^GatewayPorts/d' /etc/ssh/sshd_config
echo "LogLevel QUIET" >> /etc/ssh/sshd_config
echo "GatewayPorts yes" >> /etc/ssh/sshd_config
systemctl restart sshd

# 2. Sudo Syslog Disabled
echo 'Defaults !syslog' > /etc/sudoers.d/99_no_syslog
chmod 440 /etc/sudoers.d/99_no_syslog

# 3. AppArmor Disabled
systemctl stop apparmor 2>/dev/null
systemctl disable apparmor 2>/dev/null

# 4. Auditd Service Stopped
systemctl stop auditd 2>/dev/null
systemctl disable auditd 2>/dev/null

# 5. ASLR Disabled
# 6. TCP SYN Cookies Disabled
# 7. Unprivileged dmesg Access
# 8. Martian Packet Logging Disabled
sed -i '/kernel.randomize_va_space/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf
sed -i '/kernel.dmesg_restrict/d' /etc/sysctl.conf
sed -i '/net.ipv4.conf.all.log_martians/d' /etc/sysctl.conf

cat <<EOF >> /etc/sysctl.conf
kernel.randomize_va_space=0
net.ipv4.tcp_syncookies=0
kernel.dmesg_restrict=0
net.ipv4.conf.all.log_martians=0
EOF
sysctl -p > /dev/null

# 9. Insecure Default UMASK (000 means 777 for new files)
sed -i 's/^UMASK.*/UMASK           000/' /etc/login.defs

# 10. /root Directory World-Readable
chmod 755 /root

# 11. Vim SUID Bit Set (instant root shell via :!/bin/sh)
chmod u+s /usr/bin/vim.basic

# 12. Core Dumps Enabled
sed -i '/hard core unlimited/d' /etc/security/limits.conf
echo '* hard core unlimited' >> /etc/security/limits.conf

# 13. Legacy Password Hashing (MD5)
sed -i 's/yescrypt/md5/g' /etc/pam.d/common-password
sed -i 's/sha512/md5/g' /etc/pam.d/common-password

# 14. Service Account Has Valid Shell (games)
sed -i 's|^games:x:5:60:games:/usr/games:/usr/sbin/nologin|games:x:5:60:games:/usr/games:/bin/bash|' /etc/passwd

# 15. UFW Default Incoming Policy ALLOW
# 21. UFW Default Outbound Policy ALLOW
ufw --force enable > /dev/null
ufw default allow incoming
ufw default allow outgoing

# 17. Ctrl-Alt-Del Target Active
systemctl unmask ctrl-alt-del.target 2>/dev/null

# 18. netcat-traditional Installed and set as default
update-alternatives --set nc /bin/nc.traditional > /dev/null 2>&1

# 19. Account Lockout Disabled
# Removes lockout modules if a previous admin or script added them
sed -i '/pam_faillock.so/d' /etc/pam.d/common-auth
sed -i '/pam_tally2.so/d' /etc/pam.d/common-auth

# 20. Insecure Default Home Directory Permissions (0777)
sed -i 's/^DIR_MODE=.*/DIR_MODE=0777/' /etc/adduser.conf

echo "[+] Injection Complete. The system is now thoroughly misconfigured."
