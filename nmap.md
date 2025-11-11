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
| 1\. Install nmap     | <pre>>sudo apt install nmap</pre>                                                                                                                                |
| 2\. Use Nmap    | <pre>> nmap 'ip address or subnet'</pre> <br>  You can also add various flags to output different information.<br> <br> * The '-sV' flag also displays the version of the service that is open. <br> * The '-Pn' flag skips the process where it pings the host to see if it is up. This is important if you are getting errors saying the host is not up. <br> * The '-v' flag will allow it to display information of hosts while it still scans other hosts. This is helpful when scanning an entire subnet. <br>
| 3\. Use the 'nmap.txt' template to fill in host information                                                                                                                                                                                                                |
| 4. Take a screenshot to show evidence of the completed scans |                                                                                                                                                                                                                                                    |




