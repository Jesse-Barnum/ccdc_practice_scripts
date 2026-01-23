## Implement Central Logging
This playbook focuses on providing direction on how to effectively respond to this common inject which requires us to implement central logging. Luckily, most of the work has already been completed if the splunk forwarding portion of the initial hardening scripts was run properly. This playbook outlines the best way to respond including mention of what screenshots to include. 

## Overall Steps for Completion
| Step                          | Task |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Identify Pre-Connected Devices   | Naviagte to the device which is hosting Splunk and login it the GUI. Identify which network devices are already connected by viewing the Splunk dashboard (Homedash) to see events by hosts. If necessary, you may also run this SPL query: <pre> metadata type=hosts </pre> <br> If all devices are properly connected, you may skip the remaining steps and being the Inject Response. 
| 2\. Ensure Firewall Rules are configured Properly   | Create firewall rules on each Network Router to allow cross network ingress/egress traffic on ports 8000 and 9997. The firewall on each host device should be configured properly by the initial hardening script.  
| 3\. Manually forward logs to Splunk | If a given network device is not accurately forwarding logs to Splunk, you will need to manually run the splunk forwarding script on each necessary device. <br> **Linux:** <br> Use these commands to get the script and run it properly: <pre> wget https://tinyurl.com/byunccdc/splunk/splunk.sh <br> chmod +x splunk.sh <br> ./splunk.sh </pre>  <br> **Windows:** <br> Use these commands to get the script and run it properly: <pre> iwr https://tinyurl.com/byunccdc/splunk/splunk.ps1 -o splunk.ps1 <br> ./splunk.ps1 </pre>


## Sample Inject Response




### Screenshots
You will need to provide screenshots of the following items:
1. Screenshot of the Firewall Configuration on Network Routers showing incoming and outgoing traffic allowed on ports 8000 and 9997.
2. Provide separate screenshot of configuring forwarding on an example Linux server and Windows server. **In order to do so, you will have to manually run the splunk forwarding script on both devices, see step 3 above**
4. Provide a screenshot of the test-message records from each server in the central repository. You can do so by searching <pre> index** this is a test </pre> in the search bar. This should display the test messages acquired from each host.











