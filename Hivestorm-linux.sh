#!/bin/bash

echo "Starting O.W.C.A. Ubuntu Injection & Setup..."

# ==========================================
# 0. PREREQUISITES & USERS
# ==========================================
apt-get update -y
apt-get install -y nginx ufw libpam-pwquality attr python3

# Ensure Nginx is running and listening on port 80
systemctl enable nginx
systemctl start nginx

# Create the locked-down engine directory & user
ENGINE_DIR="/opt/OWCA_Engine"
mkdir -p "$ENGINE_DIR"
useradd -r -s /usr/sbin/nologin scoringadmin 2>/dev/null

# ==========================================
# 1. INJECT VULNERABILITIES
# ==========================================
echo "Injecting vulnerabilities..."

# Account Management
useradd -m doofenshmirtz 2>/dev/null
useradd -m norm 2>/dev/null
sed -i 's/^.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^.*PermitEmptyPasswords.*/PermitEmptyPasswords yes/' /etc/ssh/sshd_config

# Local Security Policies
sed -i 's/^.*minlen.*/minlen = 0/' /etc/security/pwquality.conf 2>/dev/null || echo "minlen = 0" >> /etc/security/pwquality.conf
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   99999/' /etc/login.defs
chmod 777 /etc/shadow

# Network & Firewall
ufw --force disable
ufw allow 4444/tcp
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Malware & Persistence
echo "#!/bin/bash" > /tmp/inator.elf
echo "echo 'Curse you Perry the Platypus!'" >> /tmp/inator.elf
chmod +x /tmp/inator.elf

(crontab -u root -l 2>/dev/null; echo "* * * * * /tmp/inator.elf") | crontab -u root -

cat << 'EOF' > /etc/systemd/system/doof-backdoor.service
[Unit]
Description=Doofenshmirtz Reverse Shell
[Service]
ExecStart=/tmp/inator.elf
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl enable doof-backdoor.service
systemctl start doof-backdoor.service

# ==========================================
# 2. FORENSICS SETUP
# ==========================================
DESKTOP_DIR="/home/ubuntu/Desktop" # Change 'ubuntu' if your default user is different
mkdir -p "$DESKTOP_DIR/Forensics"
chown -R ubuntu:ubuntu "$DESKTOP_DIR" 2>/dev/null

# Create empty answer templates for the competitors
echo "[Answer Here]" > "$DESKTOP_DIR/Forensics/Q1.txt"
echo "[Answer Here]" > "$DESKTOP_DIR/Forensics/Q2.txt"
echo "[Answer Here]" > "$DESKTOP_DIR/Forensics/Q3.txt"

# Create the "ADS" equivalent file using Linux Extended Attributes
touch "$DESKTOP_DIR/Forensics/owcaregulations.txt"
echo "Standard O.W.C.A. Field Regulations..." > "$DESKTOP_DIR/Forensics/owcaregulations.txt"
setfattr -n user.hiddenADS -v "192.168.1.100" "$DESKTOP_DIR/Forensics/owcaregulations.txt"

# ==========================================
# 3. WRITE THE SUBTRACTIVE SCORING ENGINE
# ==========================================
cat << 'EOF' > "$ENGINE_DIR/scoring_engine.py"
import subprocess
import os
import time
from datetime import datetime

MAX_SCORE = 18 
REPORT_PATH = "/home/ubuntu/Desktop/ScoreReport.html"
FORENSICS_DIR = "/home/ubuntu/Desktop/Forensics"

def check_cmd(command):
    result = subprocess.run(command, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return result.returncode == 0

def read_file(filepath):
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            return f.read().strip().lower()
    return ""

while True:
    score = MAX_SCORE
    html_lines = []

    # --- ACCOUNT MANAGEMENT ---
    if check_cmd("id doofenshmirtz"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Unauthorized user 'doofenshmirtz' present</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Doofenshmirtz removed</li>")

    if check_cmd("id norm"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Unauthorized user 'norm' present</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Norm removed</li>")

    if not check_cmd("grep -Eq '^PermitRootLogin no' /etc/ssh/sshd_config"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Root SSH login is permitted</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Root SSH login disabled</li>")

    if not check_cmd("grep -Eq '^PermitEmptyPasswords no' /etc/ssh/sshd_config"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Empty SSH passwords permitted</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Empty SSH passwords disabled</li>")


    # --- LOCAL SECURITY POLICIES ---
    if not check_cmd("grep -Eq '^minlen[[:space:]]*=[[:space:]]*[8-9]' /etc/security/pwquality.conf"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Password minimum length insecure</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Password min length configured</li>")

    if not check_cmd("grep -Eq '^PASS_MAX_DAYS[[:space:]]*[0-9]{1,3}$' /etc/login.defs") or check_cmd("grep -Eq '^PASS_MAX_DAYS[[:space:]]*99999' /etc/login.defs"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Password expiration insecure</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Password expiration enforced</li>")

    if not check_cmd("stat -c %a /etc/shadow | grep -Eq '^[06]40$|^000$'"):
        score -= 1; html_lines.append("<li style='color:red'>[-] /etc/shadow permissions insecure</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Shadow file permissions secured</li>")


    # --- NETWORK & FIREWALL ---
    if not check_cmd("ufw status | grep -q 'Status: active'"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Firewall is disabled</li>")
    else:
        html_lines.append("<li style='color:green'>[+] UFW Firewall active</li>")

    if check_cmd("ufw status | grep -q '4444'"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Unauthorized port 4444 is open</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Malicious port 4444 closed</li>")

    if not check_cmd("sysctl net.ipv4.ip_forward | grep -q '0'"):
        score -= 1; html_lines.append("<li style='color:red'>[-] IP forwarding is enabled</li>")
    else:
        html_lines.append("<li style='color:green'>[+] IP forwarding disabled</li>")


    # --- MALWARE & PERSISTENCE ---
    if os.path.exists("/tmp/inator.elf"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Malicious executable present in /tmp</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Backdoor binary removed</li>")

    if check_cmd("crontab -u root -l 2>/dev/null | grep -q 'inator'"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Unauthorized cronjob present</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Malicious root cronjob removed</li>")

    if os.path.exists("/etc/systemd/system/doof-backdoor.service"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Unauthorized systemd service present</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Malicious service removed</li>")


    # --- SLAS (NGINX) ---
    if not check_cmd("systemctl is-active --quiet nginx"):
        score -= 1; html_lines.append("<li style='color:red'>[-] SLA FAILURE: Nginx service is stopped</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Nginx service running</li>")

    if not check_cmd("ss -tulpn | grep -q ':80\\b'"):
        score -= 1; html_lines.append("<li style='color:red'>[-] SLA FAILURE: Port 80 is not listening</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Server listening on Port 80</li>")


    # --- FORENSICS ---
    if "inator.elf" not in read_file(f"{FORENSICS_DIR}/Q1.txt"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Forensics Q1 Incorrect</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Forensics Q1 Correct</li>")

    if "4444" not in read_file(f"{FORENSICS_DIR}/Q2.txt"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Forensics Q2 Incorrect</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Forensics Q2 Correct</li>")

    if "192.168.1.100" not in read_file(f"{FORENSICS_DIR}/Q3.txt"):
        score -= 1; html_lines.append("<li style='color:red'>[-] Forensics Q3 Incorrect</li>")
    else:
        html_lines.append("<li style='color:green'>[+] Forensics Q3 Correct</li>")

    # --- GENERATE HTML REPORT ---
    current_time = datetime.now().strftime("%H:%M:%S")
    html_content = f"""<html>
<head>
    <title>O.W.C.A. Ubuntu Scoring</title>
    <style>body {{ font-family: Arial; background-color: #1e1e1e; color: #d4d4d4; padding: 20px; font-size: 18px; }}</style>
</head>
<body>
    <h2>O.W.C.A. Ubuntu Scoring</h2>
    <p><strong>Score: {score} / {MAX_SCORE}</strong></p>
    <p>Last Updated: {current_time}</p>
    <ul>
        {''.join(html_lines)}
    </ul>
</body>
</html>"""

    tmp_path = f"{REPORT_PATH}.tmp"
    with open(tmp_path, 'w') as f:
        f.write(html_content)
    os.rename(tmp_path, REPORT_PATH)

    time.sleep(30)
EOF

# ==========================================
# 4. SECURE ENGINE & REGISTER SERVICE
# ==========================================
chown -R scoringadmin:scoringadmin "$ENGINE_DIR"
chmod 700 "$ENGINE_DIR"
chmod 700 "$ENGINE_DIR/scoring_engine.py"
touch /home/ubuntu/Desktop/ScoreReport.html
chmod 644 /home/ubuntu/Desktop/ScoreReport.html

cat << 'EOF' > /etc/systemd/system/owca-engine.service
[Unit]
Description=O.W.C.A. Python Scoring Engine
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/OWCA_Engine/scoring_engine.py
User=root
Restart=always
RestartSec=5
ProtectSystem=full

[Install]
WantedBy=multi-user.target
EOF

chmod +x /opt/OWCA_Engine/scoring_engine.py
systemctl daemon-reload
systemctl enable owca-engine.service
systemctl start owca-engine.service

# ==========================================
# 5. COVER TRACKS
# ==========================================
history -c
cat /dev/null > ~/.bash_history
rm -f /var/log/auth.log* 2>/dev/null

echo "Done! The box is infected, SLAs are running, and the subtractive scoring engine is live."
