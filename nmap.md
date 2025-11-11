## Nmap
This is a playbook describing how to Port Scan and identify running services on associated ports. 

### Windows
To add a logon banner using Group Policy:
1. Navigate to Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies
2. Select Security Options
3. Select the Interactive Logon: Message text for users attempting to logon policy

### Linux
| Description                          | Tasks                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Install nmap     | sudo apt install nmap                                                                                                                                |
| 2\. Use Nmap    | nmap <ip address or subnet>   You can also add various flags to output different information. The '-sV' flag also displays the version of the service that is open. 
| 3\. Restart the SSH Service          | <pre>> sudo systemctl restart ssh</pre>                                                                                                                                                                                                              |
| 4. Test to verify and get screenshot | SSH into the machine and screenshot the login banner                                                                                                                                                                                                                                                     |
Alternative: <pre>> sudo vim /etc/motd</pre>
<pre>> sudo systemctl restart sshd</pre>

___


***WARNING: UNAUTHORIZED ACCESS TO THIS NETWORK DEVICE IS PROHIBITED***
You must have explicit, authorized permission to access or configure this device. Unauthorized attempts to access and misuse of this system may result in prosecution. All activities performed on this device are logged and monitored.

___

***WARNING:*** This computer system is the property of Team ##. This computer system, including all related equipment, networks, and network devices are only for authorized users. All activity on this network is being monitored and logged for lawful purposes including to ensure use is authorized.

Data collected including logs will be used to investigate and prosecute unauthorized or improper access. By continuing to use this system you indicate your awareness of and consent to these terms and conditions of use.

___

All employees shall take reasonable steps to prevent unauthorized access to the System,
including without limitation by protecting its passwords and other log-in information. 

Employees will notify their administrators immediately of any known or suspected use of the system or breach of its security and shall use best efforts to stop said breach.

Using company services to access, or to attempt to access without authority, the accounts of others, or to penetrate, or to attempt to penetrate, security measures or third party’s software or hardware, whether or not the intrusion results in disruption of service or the corruption or loss of data is a violation of the terms of use. 

___

Note: Reference the Acceptable Use Policy Template from SANS Institute

