## Password Policy 
This playbook focuses on providing direction on how to effectively implement an adequate password policy in response to the inject which generally asks us to use Industry based standards to properly secure our systems with a secure password policy. This playbook will describe the general steps of implementing the password policy on both Linux and Windows systems as well as direct you to the inject response contained in the public-ccdc-resources for injects. 

**Please note that although these standards meet NIST and Microsoft industry standards, the inject may request different standards such as the implementation of an age/expiration for passwords**

For initial reference, here is a password policy that meets industry standards such as NIST 800-63B  (https://pages.nist.gov/800-63-3/sp800-63b.html). The bolded portions of this password policy are those which you must implement onto the Windows/Linux systems.

1. **User-generated passwords should be at least 8 characters long.**
2. **Passwords should contain a combination of uppercase letters, lowercase letters, numbers, and symbols.**
3. Users should be able to create passwords at least 64 characters in length.
4. **Passwords should NOT have an age expiration associated with the password.** 
5. Knowledge-based passwords or security questions, such as “What was the name of your first pet?” should not be used.
6. Passwords should not have hints.
7. Context-specific words, such as the name of the service for which the password will be used or the user’s specific username, should not be permitted.

Other considerations include
* Encourage use of passphrases over complexity requirements.
* Do not force regular password resets. (Only reset passwords if there is evidence of compromise.)
* Screen new passwords against lists of commonly used and compromised passwords. (To prevent dictionary or rainbow table attacks)
* Allow pasting of passwords. (For those using password managers)
* Enable the showing of passwords while typing.
* **Limit the number of attempts before lockout (3-5).**
* Implement 2-factor authentication.
* Salt and hash passwords.

## Implementing the Password Policy
### General Steps for Linux

| Step                          | Method of Execution                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\.   |  **Ubuntu / Debian / Mint / Raspberry Pi:** <br> **Rocky / Fedora / CentOS / Alpine / BSD(all):**
| 2\.    |

### General Steps for Windows
| Step                          | Method of Execution                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1\. Navigate to Active Directory    | The password policy will need to be implmented on the Active Directory / Domain Controller box only. The password policy cannot be updated in the local group policy for any AD bound device. 
| 2\. Open Group Policy on DC | Navigate to the Group Policy on the DC where the Password Policy is located. <br> Password policies are located in the **Group Policy Management Console (GPMC)** on the domain controller, specifically within the **Default Domain Policy** (or other GPOs linked to OUs/Domains) under **Computer Configuration > Policies > Windows Settings > Security Settings > Account Policies > Password Policy**.
| 3\. Update Password Policy | Change the Password Policy to include the following settings: <pre> Maximum password age: 90 days </pre> **^^^^^Please note that this one should generly be 'Not Defined' unless the inject specifies you must include it** <br> <br> <pre> Minimum password age: 1 days </pre> <pre> Minimum password length: 8 characters </pre> <pre> Password must meet complexity requirements: Enabled </pre>
| 4\. Take a screenshot | Take a focused screenshot of the Password Policy. 

**After implementing the Password Policy, use the inject report in public-ccdc-resources/Injects entitled secure_password_guidelines.txt/.docx.**
