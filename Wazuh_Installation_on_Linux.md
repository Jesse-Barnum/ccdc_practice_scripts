These instructions detail the fulfillment for the Wazuh installation inject, detailing the steps for installation and configuration. This playbook describes how to install and configure the Wazuh Dashboard on a linux box and the wazuh agents on Windows and Linux devices. 

Ideally, the wazuh dashboard should be fully installed and functional before the wazuh agents are configured on each of the devices. 
## Wazuh Dashboard Installation

| Step | Description |
| --- | --- |
| **1** | Choose a Linux device with more than 4GB RAM available. The installation will fail otherwise. Check the free memory using `free -h`.  |
| **2** | Get and run the Dashboard installation script: `wget https://tinyurl.com/byunccdc/injects/wazuh_dashboard.sh` and `chmod +x wazuh_dahsboard.sh` and `sudo ./wazuh_dashboard.sh` |
| **3** | After the Installation finishes (**IT MAY TAKE 5-10 minutes**), take note of the credentials that appear after the script is run. The wazuh username will be "Admin" and the password will be displayed in the results of the successful installation.  |
| **4** | Add firewall rules for the Wazuh Dashboard to function properly. `sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT`, `sudo iptables -A INPUT -p tcp --dport 1514 -j ACCEPT`, and  `sudo iptables -A INPUT -p tcp --dport 1515 -j ACCEPT`. Then run `sudo iptables-save`. |
| **5** | Log into the Wazuh Dashboard on another device at https://'dashboard host IP address' to verify proper connectivity and functionality. If you need the admin credentials, run `sudo sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt` and find the password associated with 'admin'.|





## Wazuh Agent Installation - LINUX


## Wazuh Agent Installation - WINDOWS

