# --- ACCOUNT MANAGEMENT ---
    if not check_cmd("id doofenshmirtz"):
        score += 1; html_lines.append("<li style='color:green'>[+] Doofenshmirtz removed</li>")
    if not check_cmd("id norm"):
        score += 1; html_lines.append("<li style='color:green'>[+] Norm removed</li>")
    if check_cmd("grep -Eq '^PermitRootLogin no' /etc/ssh/sshd_config"):
        score += 1; html_lines.append("<li style='color:green'>[+] Root SSH login disabled</li>")
    if check_cmd("grep -Eq '^PermitEmptyPasswords no' /etc/ssh/sshd_config"):
        score += 1; html_lines.append("<li style='color:green'>[+] Empty SSH passwords disabled</li>")

    # --- LOCAL SECURITY POLICIES ---
    if check_cmd("grep -Eq '^minlen[[:space:]]*=[[:space:]]*[8-9]' /etc/security/pwquality.conf"):
        score += 1; html_lines.append("<li style='color:green'>[+] Password min length configured</li>")
    if check_cmd("grep -Eq '^PASS_MAX_DAYS[[:space:]]*[0-9]{2,3}' /etc/login.defs"):
        score += 1; html_lines.append("<li style='color:green'>[+] Password expiration enforced</li>")
    if check_cmd("stat -c %a /etc/shadow | grep -Eq '^[06]40$|^000$'"):
        score += 1; html_lines.append("<li style='color:green'>[+] Shadow file permissions secured</li>")

    # --- NETWORK & FIREWALL ---
    if check_cmd("ufw status | grep -q 'Status: active'"):
        score += 1; html_lines.append("<li style='color:green'>[+] UFW Firewall active</li>")
    if not check_cmd("ufw status | grep -q '4444'"):
        score += 1; html_lines.append("<li style='color:green'>[+] Malicious port 4444 closed</li>")
    if check_cmd("sysctl net.ipv4.ip_forward | grep -q '0'"):
        score += 1; html_lines.append("<li style='color:green'>[+] IP forwarding disabled</li>")

    # --- MALWARE & PERSISTENCE ---
    if not os.path.exists("/tmp/inator.elf"):
        score += 1; html_lines.append("<li style='color:green'>[+] Backdoor binary removed</li>")
    if not check_cmd("crontab -u root -l 2>/dev/null | grep -q 'inator'"):
        score += 1; html_lines.append("<li style='color:green'>[+] Malicious root cronjob removed</li>")
    if not os.path.exists("/etc/systemd/system/doof-backdoor.service"):
        score += 1; html_lines.append("<li style='color:green'>[+] Malicious service removed</li>")

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
