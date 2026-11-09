#!/bin/bash

# 1. Create the locked-down engine directory
ENGINE_DIR="/opt/OWCA_Engine"
mkdir -p "$ENGINE_DIR"

# 2. Create the scoringadmin account (no login shell for security)
useradd -r -s /usr/sbin/nologin scoringadmin 2>/dev/null

# 3. Create the Forensics answer files
mkdir -p /home/ubuntu/Desktop/Forensics
echo "inator.elf" > /home/ubuntu/Desktop/Forensics/Q1.txt
echo "4444" > /home/ubuntu/Desktop/Forensics/Q2.txt
echo "192.168.1.100" > /home/ubuntu/Desktop/Forensics/Q3.txt

# 4. Generate the Python Scoring Engine (scoring_engine.py)
cat << 'EOF' > "$ENGINE_DIR/scoring_engine.py"
import subprocess
import os
import time
from datetime import datetime

# Adjusted to 12 to match the number of Linux checks
MAX_SCORE = 12 
REPORT_PATH = "/home/ubuntu/Desktop/ScoreReport.html"
FORENSICS_DIR = "/home/ubuntu/Desktop/Forensics"

def check_cmd(command):
    """Runs a shell command and returns True if successful (exit code 0)."""
    result = subprocess.run(command, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return result.returncode == 0

def read_file(filepath):
    """Reads a file and strips whitespace for forensics checks."""
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            return f.read().strip().lower()
    return ""

while True:
    score = 0
    html_lines = []

    # --- ACCOUNT MANAGEMENT ---
    if not check_cmd("id doofenshmirtz"):
        score += 1; html_lines.append("<li style='color:green'>[+] Doofenshmirtz removed</li>")
    if not check_cmd("id norm"):
        score += 1; html_lines.append("<li style='color:green'>[+] Norm removed</li>")
    if check_cmd("grep -q '^PermitRootLogin no' /etc/ssh/sshd_config"):
        score += 1; html_lines.append("<li style='color:green'>[+] Root SSH login disabled</li>")

    # --- NETWORK & FIREWALL ---
    if check_cmd("ufw status | grep -q 'Status: active'"):
        score += 1; html_lines.append("<li style='color:green'>[+] UFW Firewall active</li>")
    if not check_cmd("ufw status | grep -q '4444'"):
        score += 1; html_lines.append("<li style='color:green'>[+] Malicious port 4444 closed</li>")

    # --- MALWARE & PERSISTENCE ---
    if not os.path.exists("/tmp/inator.elf"):
        score += 1; html_lines.append("<li style='color:green'>[+] Backdoor binary removed</li>")
    if not check_cmd("crontab -u root -l 2>/dev/null | grep -q 'inator'"):
        score += 1; html_lines.append("<li style='color:green'>[+] Malicious root cronjob removed</li>")

    # --- SLAS (NGINX) ---
    if check_cmd("systemctl is-active --quiet nginx"):
        score += 1; html_lines.append("<li style='color:green'>[+] Nginx service running</li>")
    if check_cmd("ss -tulpn | grep -q ':80\\b'"):
        score += 1; html_lines.append("<li style='color:green'>[+] Server listening on Port 80</li>")

    # --- FORENSICS ---
    if "inator.elf" in read_file(f"{FORENSICS_DIR}/Q1.txt"):
        score += 1; html_lines.append("<li style='color:green'>[+] Forensics Q1 Correct</li>")
    if "4444" in read_file(f"{FORENSICS_DIR}/Q2.txt"):
        score += 1; html_lines.append("<li style='color:green'>[+] Forensics Q2 Correct</li>")
    if "192.168.1.100" in read_file(f"{FORENSICS_DIR}/Q3.txt"):
        score += 1; html_lines.append("<li style='color:green'>[+] Forensics Q3 Correct</li>")

    # --- GENERATE HTML REPORT ---
    current_time = datetime.now().strftime("%H:%M:%S")
    html_content = f"""<html>
<head>
    <title>O.W.C.A. Ubuntu Scoring</title>
    <style>body {{ font-family: Arial; background-color: #1e1e1e; color: #d4d4d4; padding: 20px; }}</style>
</head>
<body>
    <h2>O.W.C.A. Ubuntu Scoring</h2>
    <p>Score: {score} / {MAX_SCORE}</p>
    <p>Last Updated: {current_time}</p>
    <ul>
        {''.join(html_lines)}
    </ul>
</body>
</html>"""

    # Atomic write to prevent file locks/read errors when competitors view the HTML
    tmp_path = f"{REPORT_PATH}.tmp"
    with open(tmp_path, 'w') as f:
        f.write(html_content)
    os.rename(tmp_path, REPORT_PATH)

    time.sleep(30)
EOF

# 5. Lock down file permissions for the engine
chown -R scoringadmin:scoringadmin "$ENGINE_DIR"
chmod 700 "$ENGINE_DIR"
chmod 700 "$ENGINE_DIR/scoring_engine.py"

# Ensure the public desktop file is writable by the engine but readable by the competitor
touch /home/ubuntu/Desktop/ScoreReport.html
chmod 644 /home/ubuntu/Desktop/ScoreReport.html

# 6. Generate the Systemd Service File for Python
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
# Hide the service from standard process isolation
ProtectSystem=full

[Install]
WantedBy=multi-user.target
EOF

# 7. Enable and Start the Engine
chmod +x /opt/OWCA_Engine/scoring_engine.py
systemctl daemon-reload
systemctl enable owca-engine.service
systemctl start owca-engine.service

# 8. Cover Tracks (Clear history logs)
history -c
cat /dev/null > ~/.bash_history
rm -f /var/log/auth.log* 2>/dev/null

echo "Ubuntu Python Scoring Engine deployed, started, and history wiped."
