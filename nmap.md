## Nmap
This is a playbook describing how to Port Scan and identify running services on associated ports using the Network Mapping Tool, 'nmap'. 

### General Steps for Linux and Windows 
| Description                          | Tasks                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Install nmap     | <pre>>sudo apt install nmap</pre>                                                                                                                                
| 2\. Use Nmap    | <pre>> nmap 'ip address or subnet'</pre> <br>  You can also add various flags to output different information.<br> <br> * The '-sV' flag also displays the version of the service that is open. <br> * The '-Pn' flag skips the process where it pings the host to see if it is up. This is important if you are getting errors saying the host is not up. <br> * The '-v' flag will allow it to display information of hosts while it still scans other hosts. This is helpful when scanning an entire subnet. <br> * the '-p' flag allows you to specify ports to be scanned. 
| 3\. Use the 'nmap.txt' template to fill in host information                                                                                                                                                                                                                |
| 4. Take a screenshot to show evidence of the completed scans                                                                                                                                                                                                                                                     

### Other Options for Nmap
| Description                          | Nmap command                                                                                                                                                                                                                                              |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  Limited UDP scan for limited ports   | <pre>> nmap -sU -T4 —top-ports 10 'target IPs'</pre>                                                                                                                                
|  Nmap a set of hosts from a text file (i.e. hosts.txt)  |  <pre>> nmap -iL 'file containing host names' </pre>   
|  Do a stealth TCP map of the network  |  <pre>> nmap -sT 'target IPs' </pre>                                                                                                                                                                                                               |



