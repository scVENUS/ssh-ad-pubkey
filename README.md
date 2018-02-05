# ssh-ad-pubkey
Manage SSH public keys stored in ActiveDirectory

## Motivation
With Windows 10 Build 1709 and Windows Server 2016 the  OpenSSH client and server is available as an optional feature. OpenSSH for Windows is still in Beta. You can use it from command line or with PowerShell instead of WinRM. The idea was to make a tool like ssh-ldap-pubkey based on PowerShell. It should run on Windows PowerShell 2-5.1 and PowerShell Core 6.x. Unfortunately the .Net 3.5 assemblies for Active Directory Access are only available for Windows and not Linux or Mac. 

## Problem
At the time of writing the code it wasn't clear to me that the option AuthorizedKeysCommand is out of project scope because Windows don't support a fork. This is why you can't use a wrapper for OpenSSH server under Windows who fetch the SSH Public Key of the user!

## For what?
Good question. Currently we must wait because it makes no sense to administrate SSH Public Keys for Linux and Mac under Windows. 😉

## Install
However, if you are still interest then take a look to the file ssh-ad-pubkey.pdf in the directory doc.
   
There are the following steps to do:

1. Extend the Active Directrory schema
1. Optional: Delegate the rights to change the SSH Public Key to the users for self serving.
1. Execute the PowerShell script ssh-ad-pubkey to manage the SSH Public Key in Active Directory

### Prerequisites
For Installation of the schema extention must be member of Schema Admins. You need Domain Admin or equivalent rights for the optional delegation task. The same is true to add, remove or change the SSH Public Key for other users.

**_Note_** </Br>
To use Powershell with the ssh protocol you have th add a PowerShell subsystem entry into  `sshd_config` file. </Br>
https://docs.microsoft.com/en-us/powershell/scripting/core-powershell/ssh-remoting-in-powershell-core?view=powershell-5.1
 

### Testing
Start Windows PowerShell or PowerShell Core. First check whether the schema is correct
```
PS C:\scripts> .\ssh-ad-pubkey.ps1 -check
Customized AD Schema is OK!
```
Add your public SSH Key to Active Dricetory, which was created before with the command `ssh-keygen –t ed25519`    
```
PS C:\scripts> .\ssh-ad-pubkey.ps1 -add -filepath C:\Users\`<xxx>`\.ssh\id_ed25519.pub 
```
List your key(s) in Active Directory
```
PS C:\scripts> .\ssh-ad-pubkey.ps1 -list
<xxx> has 1 SSH Public Key(s) in AD:
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/W0JyvJut/Tlro2JR8aOsonHEAOTNSU1PVjTUz60i9 <xxx>@domain@host 
```

## Links
https://github.com/jirutka/ssh-ldap-pubkey

https://github.com/PowerShell/Win32-OpenSSH

https://www.balabit.com/documents/scb-latest-guides/en/scb-guide-admin/html/proc-scenario-usermapping.html

http://www.theendofthetunnel.org/2015/11/21/authorized_keys-in-active-directory/

https://blog.laslabs.com/2016/08/storing-ssh-keys-in-active-directory/

https://blog.laslabs.com/2017/04/managing-ssh-keys-stored-in-active-directory/

https://github.com/PowerShell/PowerShell

https://github.com/markekraus/PSCoreWindowsCompat

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments
* [Jirutka](https://github.com/jirutka) for inspiration 


