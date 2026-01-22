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

| OS                          | Method of Execution                                                                                                                                                                                                                                                |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ubuntu / Debian / Mint / Raspberry Pi   | 1\. <pre>> getent group sudo \| cut -d: -f4</pre> <br> 2\. <pre>> cat /etc/passwd </pre> Any usernames with UID 0 have root level priveleges. 
| Rocky / Fedora / CentOS / Alpine / BSD(all)   |1\. <pre>> getent group wheel</pre> <br> 2\. <pre>> lid -g wheel </pre> 

### General Steps for Linux
