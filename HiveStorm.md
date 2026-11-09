

### 👤 Account Management (4 Points)

1. **Unauthorized User Removed:** `Dr. Doofenshmirtz` deleted from the system.
2. **Unauthorized User Removed:** `Norm` deleted from the system.
3. **Default Admin Disabled:** Built-in `Administrator` account disabled (as requested by Major Monogram).
4. **Guest Disabled:** Built-in `Guest` account disabled.

### 🛡️ Local Security Policies (4 Points)

5. **Password Complexity:** Enabled in Local Security Policy.
6. **Password Length:** Minimum password length set to 8 or more characters.
7. **Account Lockout:** Lockout threshold enabled (e.g., 5 invalid attempts).
8. **Clear-Text Passwords:** WDigest authentication disabled in the registry (preventing credential dumping).

### 🌐 Network & Firewall (3 Points)

9. **Firewall Enabled:** Windows Defender Firewall turned on for Domain, Private, and Public profiles.
10. **Malicious Port Closed:** Unauthorized inbound firewall rule (e.g., Doofenshmirtz's reverse shell port) removed.
11. **RDP Disabled:** Remote Desktop Services disabled (since IIS is the only required SLA).

### 🦠 Malware & Persistence Removal (4 Points)

12. **Malicious Task:** Doofenshmirtz's unauthorized scheduled task/backdoor removed from Task Scheduler.
13. **Malicious File:** Backdoor executable (e.g., `nc.exe` or `inator.exe`) deleted from the file system.
14. **Registry Run Key:** Unauthorized startup program removed from `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`.
15. **Antivirus Active:** Windows Defender Real-Time Protection enabled.

### 📝 Forensics & Critical SLAs (5 Points)

16. **Remove LoveHandel_song:** World Wide Web Publishing Service (`W3SVC`) is actively running.
18. **Forensics Q1:** Correct answer saved in `C:\Users\Public\Desktop\Forensics\Q1.txt`.  **Correct Answer: Doofensmirtz**
19. **Forensics Q2:** Correct answer saved in `C:\Users\Public\Desktop\Forensics\Q2.txt`.  **Correct Answer: inator.exe**
20. **Forensics Q3:** Correct answer saved in `C:\Users\Public\Desktop\Forensics\Q3.txt`.  **Correct Answer: 203.0.113.85**
