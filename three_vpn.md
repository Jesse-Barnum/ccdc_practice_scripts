This is a playbook in response to the common inject request to research 3 VPN options that a company should be considered and can easily be implemented to allow external secure access into the company’s internal network. Most of these injects ask the option to be compatible with for implementation with ansible. This playbook will walk you through the 3 best VPN options and the general response to provide for this inject. 

For this playbook and in the competition, we will be choosing between 3 VPNs that are easy to implement, meet the comapny needs, and that sometimes need to be implemented using ansible. 
The 3 VPN options chosen that meet these requirements are Tailscale, WireGuard, and ZeroTeir. 

## Comparing and Contrasting the 3 VPNs ##

| VPN Option | Tailscale | WireGuard | ZeroTeir |
| :--- | :--- | :--- | :--- |
| **Benefits** | Strong security support and has lots of support and documentation. <br> Easy integration of users and devices. | High Performance, no third-party servers. Our organization owns the entire stack. <br> Highly Scalable. | Supports integration of Layer 2 netwroking devices and advanced routing. |
| **Cons** | Reliance on third-party servers (if their servers are down, we lose secure connection to internal devices) | Highly technical maintainence and management required. <br> Difficult to scale | Difficult set-up, high cost |
| **Authentication** | Uses existing providers (Google, Microsoft, GitHub, or Company emails | Key-based (a manual exchange of private and public keys is necessary between every device in the organization) | Network ID authorization (devices join via a Network ID and must be approved by a centralized network controller |
| **OS Support** | Windows, Mac, Linux, iOS, Android, etc. | Universal (works on all operating systems) | Windows, Mac, Linux, iOS, Android, Netowrk devices |
| **Ansible Compatibility** | Easy integration with Ansible, installation automation can be done easily with 'tailscale up' and an authorization key. | Difficult. Integration with ansible requires heavy logic to generate, fetch, and distrubte keys among all devices. | Fair integration, but requires techincal expertise to automate the interaction with the ZT API for device joining and approved connection. |

##
This inject often requires donwloading each VPN on at least one device to test compatability with the network and test overall usability. The next section of the playbook will focus on implementing each VPN into the network on either a Windows or a Linux device. 

## Testing Tailscale
### Windows
| Steps                          | Tasks                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Install Tailscale     | Navigate to https://tailscale.com/download and select 'Download Tailscale for Windows'.|
| 2\. Run the Installer from Downloads | From downloads, select and run the tailscale-setup-1.92.5.exe while following the prompts to installation including agreeing to terms and installing. |
| 3\. Log into Tailscale | Log into tailscale using your own account which we can obfuscate from screenshots after. 
| 4\. Select "Connect" | After logging in, a screen should appear that will allow you to connect the device you are currrntly on to a private Tailscale VPN. Select the blue "Connect" button. 
| 5\. Ensure Connection | You should be brought to a page with a large black heading entitled "Machines". You should see the Machine you are currently on listed under connected machines. <br> To ensure connection, looking for the Tailscale logo in your system tray. Right click on the system tray and look for 'Connected' under 'Tailscale' at the top of the pop-up. If it says 'Not Connected', select the word 'Tailscale' to connect to the VPN.

### Linux 
| Steps                          | Tasks                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Install Tailscale     | Install Tailscale using this command: <pre>> curl -fsSL https://tailscale.com/install.sh \| sh </pre>.|
| 2\. Log into Tailscale | Run the following command to initialize Tailscale: <pre>> sudo tailscale up </pre> <br> After a few minutes, your CLI should provide you with an authentication link. Follow that link and Log in to Tailscale using your own account (google). After logging in, your CLI will say 'Success' |
| 3\. Ensure connectivity | Run this command to display the devices that are currently connected to your tailscale account. It should list your IP address and the name of your device. If your device is not connected, connection did not work properly. <pre>> sudo tailscale status <pre>



## Testing Wireguard


## Testing ZeroTeir

