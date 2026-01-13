## Admin Account Inventory
This playbook focuses on providing direction on how to effectively identify all administrative user accounts. This inject typically requires an inventory to be taken on all network devices to list administrator accounts and document which accounts do not need administrative priveleges and as such need to be removed. 

## Taking an Inventory of Admin Accounts
### General Steps for Linux

| OS                          | Method of Execution                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ubuntu / Debian / Mint / Raspberry Pi   | 1\. <pre>> getent group sudo \| cut -d: -f4</pre> <br> 2\. <pre>> cat /etc/passwd </pre> Any usernames with UID 0 have root level priveleges. 
| Rocky / Fedora / CentOS / Alpine / BSD(all)   |1\. <pre>> getent group wheel</pre> <br> 2\. <pre>> lid -g wheel </pre> 
     

### General Steps for Windows 
**Use Powershell** 
| Type of Device                          | Method of Execution                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Local Device (Non-AD) | 1\. <pre>> net localgroup Administrators </pre> <br> 2\. <pre>>  (Get-LocalGroupMember "Administrators").Name </pre> 
| Domain/Active Directory   |1\. <pre>> Get-ADGroupMember -Identity "Domain Admins" -Recursive </pre> 


### Documenting Accounts
Generally screenshots are not necessary in this inject, but you will certainly need to create a table to document the Administrator accounts found on each device.
Here is an example table that could be utilized: 

| Hostname                          | Operating System | Administrator Accounts on Device   | Removed Adminsitrator Accounts                                                                                                                                                                                                                                             |
| ------------------------------------ | --------------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| Minty | Windows 2022 | Administrator, ccdcuser1, alice | |
| Sweet | Ubuntu 22.04 | Administrator, ccdcuser1, Bob | |
| Spicy | CentOS 8 | Administrator, ccdcuser1 | Hackerman | 

**Please note that it is important to indicate which accounts weren't supposed to be there and have hence been removed. You can do so by adding another column to the tabel entitled 'Removed Admin Accounts' or highlight them in red text or bold them to indicate that those accounts have been removed**

## Removing Administrator Accounts
### General Steps for Linux

| OS                          | Method of Execution                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ubuntu / Debian / Mint / Raspberry Pi   | 1\. <pre>> sudo deluser 'username' sudo </pre> <br> 2\. <pre>> sudo userdel -r 'username' </pre>
| Rocky / Fedora / CentOS / Alpine / BSD(all)   |1\. <pre>> sudo gpasswd -d 'username' wheel </pre> <br> 2\. <pre>> sudo userdel -r 'username' </pre>
     

### General Steps for Windows 
**Use Powershell** 
| Type of Device                          | Method of Execution                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Local Device (Non-AD) | 1\. <pre>> Remove-LocalGroupMember -Group "Administrators" -Member "username" </pre>
| Domain/Active Directory   |1\. <pre>> Remove-LocalGroupMember -Group "Administrators" -Member "username" </pre>

