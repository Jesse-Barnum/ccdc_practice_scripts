## Firewall Policy
This playbook outlines how to properly complete the 'Firewall Policy' inject which requests a summary of all current firewall policies and the policies in place that make our network's security robust. 

## Listing Current Firewall Rules
The primary goals of this inject is to have us provide evidence that we have a secure firewall policy, specifically take screenshots of the firewall policies on each individual device. 

**You can list the firewall rules on each device by:**
### Linux
<pre> sudo iptables -L </pre>
*Take a screenshot*

### Windows
1. Search 'Windows Defender Firewall' in the Windows search bar.
2. Select 'Inbound Rules' or 'Outbound Rules' to view the current firewall policies. 

You may also run this command in Powershell:
<pre> Get-NetFirewallRule -Enabled True </pre>

*Take a Screenshot*

## Firewall Logs
This inject may ask you to show logs of proper packet flow through the firewall including dropped/blocked packets. 
### Linux
<pre> sudo tail -f /var/log/kern.log | grep "iptables" </pre>
or
<pre> sudo tail -f /var/log/messages | grep "iptables"</pre>

*Take a Screenshot*

### Windows
1. Enable logging dropped packets: <pre> netsh advfirewall set allprofiles logging droppedconnections enable </pre>
2. View Logs: **Open Event Viewer -> Applications and Services Logs -> Microsoft -> Windows -> Windows Firewall with Advanced Security -> Firewall**

*Take a Screenshot*

## Sample Inject Response

**Summary:** The following document outlines the firewall rules on each server and the logs that
indicate traffic running through the firewall. The logs are used to identify malicious traffic and identify
if any safe traffic is being dropped.

**Windows Servers**

Firewall rules from 'Windows Device Hostname':

Firewall Logs from 'Windows Device Hostname':

**Linux Servers**

Firewall rules from 'Linux Device Hostname':

Firewall logs from 'Linux Device Hostname':


If you have any questions or concerns, please do not hesitate to contact us.

Best Regards,

Team 01
