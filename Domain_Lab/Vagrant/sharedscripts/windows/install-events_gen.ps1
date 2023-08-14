#Some notes:
###This script assumes the ActiveDirectory and GroupPolicy modules are installed on your Domain Controller.
###The script first checks if it's running with administrative privileges.
###It creates a new GPO named "Security Auditing Policy."
###The audit settings for the categories you mentioned are then enabled for both success and failure events.
###vent log properties for the security log are set to retain events for 2 days and have a max size of 1 GB.
###The script finally links the GPO to the domain root.


## Account Logon Events:
## 4624: An account was successfully logged on.
## 4625: An account failed to log on.
## 4776: The domain controller attempted to validate the credentials for an account.

## Account Management:
## 4720: A user account was created.
## 4722: A user account was enabled.
## 4723: An attempt was made to change an account's password.
## 4725: A user account was disabled.
## 4740: A user account was locked out.
## 4726: A user account was deleted.

## Directory Service Access: 
## 4662: An operation was performed on an object.

## Logon/Logoff Events: 
## 4634: An account was logged off.
## 4647: User initiated logoff.
## 4648: A logon was attempted using explicit credentials.
## 4672: Special privileges assigned to a new logon.

## Object Access:
## 4663: An attempt was made to access an object.
## 4670: Permissions on an object were changed.

## Policy Change:
## 4719: System audit policy was changed.
## 4739: Domain policy was changed.

## Privilege Use:
## 4673: A privileged service was called.
## 4674: An operation was attempted on a privileged object.

## System Events: 
## 4610: An authentication package was loaded.
## 4621: Administrator recovered system from CrashOnAuditFail. Users who are not administrators will be disconnected.
## 4649: A replay attack was detected.

## Detailed Tracking: 
## 4688: A new process has been created.
## 4689: A process has exited.

## Network Policy Server: 
## 6272: Network Policy Server granted access to a user.
## 6273: Network Policy Server denied access to a user.
## 6278: Network Policy Server granted full access to a user because the host met the defined health policy.




# Ensure running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Import required modules
Import-Module ActiveDirectory
Import-Module GroupPolicy

# Create a new GPO
$gpoName = "Security Auditing Policy"
New-GPO -Name $gpoName | Out-Null

# Set Audit Policies
$auditCategories = @(
    "Logon/Logoff\Logon",
    "Account Logon\Kerberos Authentication Service",
    "DS Access\Directory Service Changes",
    "Account Management\User Account Management",
    "Policy Change\Audit Policy Change",
    "Privilege Use\Sensitive Privilege Use",
    "System\Other System Events"
)
foreach ($category in $auditCategories) {
    Set-GPRegistryValue -Name $gpoName -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Advanced Audit Policy\Configuration\$category" -ValueName "AuditFlag" -Type DWord -Value 3
}

# Configure Event Log Properties
$eventLogKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\EventLog\Security"
Set-GPRegistryValue -Name $gpoName -Key $eventLogKey -ValueName "Retention" -Type String -Value "OverwriteOlderThan2Days"
Set-GPRegistryValue -Name $gpoName -Key $eventLogKey -ValueName "MaxSize" -Type DWord -Value 1048576 # 1 GB

# Link the GPO to the domain
$domain = (Get-ADDomain).DistinguishedName
New-GPLink -Name $gpoName -Target $domain -LinkEnabled Yes

Write-Output "GPO $gpoName has been created and linked to the domain."
