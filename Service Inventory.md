## Unnecessary Service Inventory
This inject generally asks you to take an audit of running services on each device and identify which services do not need to be running. These services may include common scored services tha aren't important on a given device such as SSH or FTP, or software such as Steam that shouldn't be running on a company device. 

## General Steps For Completion
Remember to take screenshots throughout the process as designated in the inject instructions. For examples, the inject instructions may request you provide proof that unnecessary services have been removed/disabled. 
|   Step                        | Method of Execution per OS                                                                                                                                                                                                                                               |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Audit Currently Running Services  | **Linux:** <pre>> systemctl list-units --type=service </pre> <br> You can also run this command to see all software on your device if asked by the inject: <pre>> systemctl list-units --type=service</pre> or <pre>> ps aux </pre> <br> <br> **Windows:** <pre>> Get-Service </pre> or <pre>> Get-Service \| Where-Object Status -eq 'Running' </pre>
| 2\. Identify Unnecessary Services   | When this inject is given, it is often because there are many services pre-enabled that should not be enabled on a specified device. Services that may allow access to your device that are not scored are also considered unnecessary; this can include SSH, FTP, SMB, etc. Unecessary services may also include unknown software that is not essential for your services or the device's operations or other pre-downloaded software that competitior architects put on the devices (i.e. steam, discord).  
| 3\. Remove Unnecessary Services | **Linux:** <pre>> sudo systemctl disable --now 'service_name' </pre> or <pre>> sudo systemctl stop 'service_name' </pre> <br> <br> **Windows:** <pre>> Stop-Service -Name "ServiceName" </pre> and then <pre>> Remove-Service -Name "ServiceName" </pre>
| 4\. Fill out Inject Report | Fill out an inject report that contains necessary information requested in the inject instructions. This often includes a table of hosts with the services identified that were necessary as well as unnecessary services. You may use the provided example table below or another created table to support answering the inject. 

### Documenting Service Inventory example
| Hostname                          | Operating System | Unnecessary Software/Services   |                                                                                                                                                                                                          
| ------------------------------------ | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Minty | Windows 2022 | Steam, SSH, FTP | 
| Sweet | Ubuntu 22.04 | SSH, RDP, Xeyes | 
| Spicy | CentOS 8 | FTP, SMTP, Telnet | 
