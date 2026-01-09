This is a playbook in response to the common inject request to research 3 VPN options that a company should be considered and can easily be implemented to allow external secure access into the company’s internal network. Most of these injects ask the option to be compatible with for implementation with ansible. This playbook will walk you through the 3 best VPN options and the general response to provide for this inject. 

For this playbook and in the competition, we will be choosing between 3 VPNs that are easy to implement, meet the comapny needs, and that sometimes need to be implemented using ansible. 
The 3 VPN options chosen that meet these requirements are Tailscale, WireGuard, and ZeroTier. 

## Comparing and Contrasting the 3 VPNs ##

| VPN Option | Tailscale | WireGuard | ZeroTeir |
| :--- | :--- | :--- | :--- |
| **Benefits** | Strong security support and has lots of support and documentation. <br> Easy integration of users and devices. | High Performance, no third-party servers. Our organization owns the entire stack. <br> Highly Scalable. | Supports integration of Layer 2 netwroking devices and advanced routing. |
| **Cons** | Reliance on third-party servers (if their servers are down, we lose secure connection to internal devices) | Highly technical maintainence and management required. <br> Difficult to scale | Difficult set-up, high cost |
| **Authentication** | Uses existing providers (Google, Microsoft, GitHub, or Company emails | Key-based (a manual exchange of private and public keys is necessary between every device in the organization) | Network ID authorization (devices join via a Network ID and must be approved by a centralized network controller |
| **OS Support** | Windows, Mac, Linux, iOS, Android, etc. | Universal (works on all operating systems) | Windows, Mac, Linux, iOS, Android, Netowrk devices |
| **Ansible Compatibility** | Easy integration with Ansible, installation automation can be done easily with 'tailscale up' and an authorization key. | Difficult. Integration with ansible requires heavy logic to generate, fetch, and distrubte keys among all devices. | Fair integration, but requires techincal expertise to automate the interaction with the ZT API for device joining and approved connection. |

##
This inject often requires donwloading each VPN on at least one device to test compatability with the network and test overall usability. The next section of the playbook will focus on implementing each VPN into the network on either a Windows or a Linux device. **Please note that you may only need to implement the VPN on one device instead of multiple to ensure that it is possible to implement on the network**. These instructions show how to implement each VPN on Windows and Linux devices - choose whichever is the best fit for the device you are one. 

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
|0\. For devices with no GUI, follow this step | Run the following command to connect your device to the Tailscale network: <pre>> curl -fsSL https://tailscale.com/install.sh \| sh && sudo tailscale up --auth-key=tskey-auth-kAXeUh226621CNTRL-oLEJUQuPAcTuwEe8QsX9cTYQDBXpjJXP. </pre> The authkey can be changed manually by generating a new key on tailscale.com after you log in. 
| 1\. Install Tailscale     | Install Tailscale using this command: <pre>> curl -fsSL https://tailscale.com/install.sh \| sh </pre>.|
| 2\. Log into Tailscale | Run the following command to initialize Tailscale: <pre>> sudo tailscale up </pre> <br> After a few minutes, your CLI should provide you with an authentication link. Follow that link and Log in to Tailscale using your own account (google). After logging in, your CLI will say 'Success' |
| 3\. Ensure connectivity | Run this command to display the devices that are currently connected to your tailscale account. It should list your IP address and the name of your device. If your device is not connected, connection did not work properly. <pre>> sudo tailscale status <pre>

It is suggested that you install tailscale on two devices in the network and check the network connectivty status between the two when you are on the network versus not on the network. 

## Testing Wireguard
### Windows
| Steps                          | Tasks                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Install Tailscale     | Navigate to https://wireguard.com/install/ and select 'Download Windows installer'.|
| 2\. Run the Installer from Downloads | From downloads, select and run the wirguard-installer.exe while following the prompts to installation including agreeing to terms and installing. |
| 3\. Add Tunnel |  Select the carrot icon next to the words 'Add Tunnel' on the wireguard application and select 'Add Empty Tunnel' <br> Wireguard will create a set of private and public keys for you. <br> Give the tunnel a name such as "WireGuard-Server" DO NOT HIT THE 'SAVE' Button yet! |
| 4\. Save Server Public Key | Save a copy of the server's public key by copy and pasting it into a notes file or other file. DO NOT HIT THE 'SAVE' Button yet!
| 5\. Adding further configuration  | Add 'ListenPort = 51820' and 'Address = 10.0.0.1/24' underneath the PrivateKey and hit Save. 
| 6\. Create client configuration file | Once again, select 'Add Empty Tunnel' and name it 'Client Configuration File'. <br> Copy and save the client's public key in the same file as the server's public key. <br> add the following settings to the Client Configuration File: <pre> Address = 10.0.0.2/24 <br> DNS = 8.8.8.8, 8.8.4.4 <br> [Peer] <br> PublicKey = Server Public Key <br> AllowedIPs = 0.0.0.0/0 <br> Endpoint = Server Public IP:51820 </pre> Replace the 'Server Public Key' with your previously saved public key. <br> Replace 'Server Public IP with the public IP address of your server device. Hit Save.
| 7\. Add the client as a Peer in Server Config File | Select your Server Config file unfer 'Tunnels' (the one called WireGuard-Server) and select Edit in the bottom right corner. <br> Add the following to the Config file: <pre> [Peer] <br> PublicKey = 'THE SAVED PUBLIC KEY FOR THE CLIENT' <br> AllowedIPs = 10.0.0.2/32 </pre> Make sure you add in the saved client public key! <br> Hit Save.
| 8\. Export Config files | Export the COnfiguration Files for the Server and Client using the Zip Icon at the bottom of the screen. Extract the Client config file and trafer it to another client device. 
| 9\. Activate the VPN connection | Select the Activate Button on the main WireGuard screen. 
|10\. Allow WireGuard on Firewall | Add Firewall rules on the host devces and external router firewall to allow internal and external acces on port 51820. 
| 11\. Install WireGuard on Client | Install Wireguard on another Windows or Linux device. This should be the device that you transfered the client Config file to. <br> upload the Client Config tunnel into the wireguard app using the "Import Tunnel from File" under the "Add Tunnel" carrot. <br> Select the toggle Icon and turn on Client 1. <br> You should now see a connected peer on your server device.  

### Linux
| Steps                          | Tasks                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Install Tailscale     | Run the following command based on operating system: <pre> Ubuntu/Debian: sudo apt install wireguard </pre> <br> <pre> Fedora: sudo dnf install wireguard-tools </pre> <br> <pre> Alpine: apk add -U wireguard-tools </pre> <br> For all other Linux distrubtions, visit wireguard.com/install to see the correct CLI command to use.|
| 2\. Generate Keys | YOU MUST BE IN A ROOT TERMINAL TO DO THIS. RUN this command to get a root terminal <pre> sudo -i </pre> Navigate to the wrieguard system files. <pre>> cd /etc/wireguard/ </pre> <br> Run the following command to generate the system keys <pre>> wg genkey \| tee privatekey \| wg pubkey > publickey </pre> <br> Display the private and public key to your terminal <pre>> cat publickey <br>> cat privatekey </pre>|
| 3\. Configure Wireguard | Create and edit a file called 'wg0.conf'. Inside of the conf file, enter this: <pre> \[Interface\] <br> Address = 10.0.0.1/24 <br> ListenPort = 51820 <br> PrivateKey = ENTER-THE-PRIVATEKEY-THAT-WAS-JUST-CREATED </pre> |
|4\. Start wg0 | Run the following commands: <pre> wg-quick up wg0 <br> wg-quick down wg0 <br> systemctl start wg-quick@wg0 <br> systemctl enable wg-qucik@wg0 <br> systemctl status wg-quick@wg0 <br> wg show </pre> |

## Testing ZeroTier
### Windows
| Steps                          | Tasks                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Create an account on zerotier.com | Go to ZeroTier.com on an external device and select 'Login' and then Login with google or create a username and password. Create  a new network and name it something fun! Find the Network ID - you will need it for a later step. |
| 2\. Install ZeroTier    | Navigate to https://zerotier.com/download and select 'MSI Installer'.|
| 3\. Run the Installer from Downloads | From downloads, select and run the tailscale-setup-1.92.5.e'ZeroTeir One.msi' while following the prompts to installation including agreeing to terms and installing. |
|4\. Connect your device to ZeroTeir | Open ZeroTier and it should appear as an icon on the system tray. Select the ZeroTeir icon from the system tray and click 'Join New Network'. Paste in the Network ID from the ZeroTier website. <br> If the device does not appear as a 'member device' on the ZeroTier website, then click 'Add Member Device' on the website and type in the device's  ID located next to the words 'My Address' when you click ZeroTier from the system tray on the device you are attempting to connect. |

### Linux
| Steps                          | Tasks                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Create an account on zerotier.com | Go to ZeroTier.com on an external device and select 'Login' and then Login with google or create a username and password. Create  a new network and name it something fun! Find the Network ID - you will need it for a later step. |
| 2\. Install ZeroTier     | Install ZeroTier using this command: <pre>. curl -s https://install.zerotier.com \| sudo bash </pre> Notice that it should say "Success! You are ZeroTier Address ...|
|3\. Connect your device to ZeroTeir | Run the following command to join your device to he ZeroTier network: <pre>> sudo zerotier-cli join NETWORK-ID </pre> MAKE SURE TO REPLACE THE NETWORK-ID with the ID found on the ZeroTier website. Refresh the website to see the device joined. <br> If the device did not join correctly, you can add the device manually on the website. On the ZeroTier website, select 'Add Member Device". Under "device ID', copy the device's address ID that was listed in the terminal with "You are ZeroTier address ...". Select 'Add Member Device" after inputting in the device address to connect the device to your network. 

## Installing Tailscale using Ansible
This is the Ansible Playbook that can be used to install Tailscale using Ansible:
<pre> - name: Install Tailscale
  hosts: myhosts
  become: true
  tasks:
    - name: Download Tailscale GPG Key
      ansible.builtin.uri:
        dest: /usr/share/keyrings/tailscale-archive-keyring.gpg
        url: https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg 

    - name: Add Tailscale repository
      ansible.builtin.uri:
        dest: /etc/apt/sources.list.d/tailscale.list
        url: https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list

    - name: Install Tailscale
      ansible.builtin.apt:
        name: tailscale
        update_cache: true
        state: present 
    - name: Ensure tailscaled is enabled and started
      ansible.builtin.systemd:
        name: tailscaled
        state: started
        enabled: true

    - name: Check Tailscale status
      ansible.builtin.command: tailscale status
      register: tailscale_status
      changed_when: false
      failed_when: false
- name: Authenticate to Tailscale
      ansible.builtin.command: 
        cmd: tailscale up --authkey=tskey-auth-kAXeUh226621CNTRL-oLEJUQuPAcTuwEe8QsX9cTYQDBXpjJXP
      when: "'Logged out' in tailscale_status.stdout or 'No Tailscale' in tailscale_status.stdout"
      changed_when: true

</pre>
        
##

## A user's guide to Tailscale
Most of these injects require a guide to be made to show employees how to install tailscale on their device in order to access the network. The following section includes all the information that we need to include in the guide to help user properly connect to Tailscale and access devices on the Network. Below is an example guide which can be used in the inject. **Remember to include plenty of screenshots for this user guide**. 


### User Guide Outline
1. Navigate to https://tailscale.com/download and installing Tailscale for Windows or Linux, depending on host device.  
2. If on windows, select the downloaded file and allow the executable to run (tailscale-setup-1.90.6.exe). If on Linux, follow these commands: <pre>  curl -fsSL https://tailscale.com/install.sh \| sh && sudo tailscale up </pre> 
 
3. If on windows, allow the app to make changes to the device and agree to the license terms and conditions.  
 
 
4. After successful installation, navigate to https://login.tailscale.com/ and log in using your company email address. If you are on a linux device, a similar link will appear in your Command Line Interface Terminal shortly after running the initial command found in step 2. 
 
5. Select the big blue ‘Connect' button that asks you to connect to your device. 
You should now be able to see a screen that displays all connected devices.   
 
6. Your device will now be connected to Tailscale. Your connection status can be seen by clicking the Tailscale Logo in your System tray on windows or by running 'tailscale status' in the CLI.   
 
7. FOR WINDOWS USERS: Select the word “Tailscale” at the top of the pop-up which allows you to easily disconnect and connect to the VPN. FOR LINUX USERS: You can disconnect to the tailscale VPN by running 'sudo tailscale down' and reconnect using 'sudo tailscale up'. 
 
Now that you are connected to the VPN, you can access all internal devices and networks. 

