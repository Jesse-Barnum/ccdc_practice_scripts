1. Unauthorized Account 1 (`doofenshmirtz`)
2. Unauthorized Account 2 (`norm`)
3. Root SSH Login Enabled (`PermitRootLogin`)
4. Empty SSH Passwords Enabled (`PermitEmptyPasswords`)
5. Weak Password Minimum Length (`minlen` in `pwquality.conf`)
6. Password Expiration Not Enforced (`PASS_MAX_DAYS`)
7. Insecure `/etc/shadow` Permissions
8. Firewall (UFW) Disabled
9. Malicious Port Open (4444)
10. IP Forwarding Enabled
11. Backdoor Binary Present (`/tmp/inator.elf`)
12. Unauthorized Root Cronjob (`inator`)
13. Unauthorized System Service (`doof-backdoor.service`)
14. Forensics Q1 Unanswered/Incorrect
15. Forensics Q2 Unanswered/Incorrect
16. Forensics Q3 Unanswered/Incorrect
17. FTP Anonymous Login Enabled
18. FTP Anonymous Uploads Enabled
19. FTP Anonymous Directory Creation Enabled
20. FTP TLS Not Enforced
21. FTP Root Login Allowed
22. Telnet Service Listening (Port 23)
23. Samba Guest Share Enabled
24. Samba Write Permissions Insecure (`read only = no`)
25. SSH X11Forwarding Enabled
26. SSH MaxAuthTries Insecure (Set to 20)
27. SSH HostbasedAuthentication Enabled
28. SSH IgnoreRhosts Not Enforced
29. SSH TCP Forwarding Enabled
30. SSH UserEnvironment Enabled
31. SSH ForceCommand Backdoor Present
32. Malicious Root SSH Key Present
33. Malicious User SSH Key Present
34. Nginx Directory Listing Enabled (`autoindex`)
35. Nginx Server Tokens Exposed
36. Nginx Worker Running as Root
37. Nginx Insecure HTTP Methods Enabled (`PUT DELETE`)
38. Web Root Permissions Insecure (`777`)
39. Web Shell Present (`owca_shell.php`)
40. Malicious Hidden Iframe in `index.html`
41. `/etc/passwd` Permissions Insecure (`666`)
42. Shadow File Backup Left on Disk (`/etc/shadow.bak`)
43. PATH Poisoning in `/etc/profile`
44. `/etc/sudoers` Permissions Insecure (`644`)
45. Unowned System File Present
46. SUID Bash Backdoor Hidden in `/var/tmp/`
47. `find` Binary SUID Bit Set
48. `cp` Binary SUID Bit Set
49. `NOPASSWD` Privilege Granted to User Buford
50. Malicious Sudoers Drop-in Present (`/etc/sudoers.d/doof_rules`)
51. Sudo Password Timeout Infinite (`timestamp_timeout=-1`)
52. Group Sudo Escalation Granted to All Users
53. Reverse Shell Payload in `/etc/profile`
54. Malicious Sudo Alias in `.bashrc`
55. Persistence Script in `/etc/rc.local`
56. Malicious Systemd Timer Present (`doof-beacon.timer`)
57. User Crontab Persistence (Isabella)
58. Payload in `.bash_logout`
59. `LD_PRELOAD` Poisoning File Present
60. DNS Hosts File Poisoned
61. ICMP Redirects Accepted in sysctl
62. Source Routing Enabled in sysctl
63. IPv6 Enabled/Unfiltered in sysctl
64. Rogue DNS Nameserver in `resolv.conf`
65. Bash History Symlinked to `/dev/null`
66. Unattended Upgrades Disabled in APT
67. 5-Minute Wall Broadcast Harassment Script Present
