#Requires -Version 7.4

<#`n.SYNOPSIS
    Disable user account and cleanup

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
Disable user, reset password, revoke sessions
.PARAMETER UserPrincipalName
User to disable
.PARAMETER Manager
Forward email to this address
.EXAMPLE
.\Disable-User.ps1 -UserPrincipalName john@company.com
.EXAMPLE
.\Disable-User.ps1 -UserPrincipalName john@company.com -Manager jane@company.com
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$UserPrincipalName,
    [string]$Manager
)
Connect-MgGraph -Scopes "User.ReadWrite.All"
$user = Get-MgUser -UserId $UserPrincipalName
Write-Output "Disabling $($user.DisplayName)" # Color: $2
Update-MgUser -UserId $user.Id -AccountEnabled:$false
Write-Output "Account disabled"
$NewPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | % {[char]$_})
Update-MgUser -UserId $user.Id -PasswordProfile @{Password=$NewPassword; ForceChangePasswordNextSignIn=$true}
Write-Output "Password reset"
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$($user.Id)/revokeSignInSessions"
Write-Output "Sessions revoked"
if ($Manager) {
    try {
        Import-Module ExchangeOnlineManagement
        Connect-ExchangeOnline -ShowProgress:$false
        Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $Manager
        Write-Output "Email forwarding set to $Manager"
    } catch {
        Write-Warning "Could not set email forwarding: $_"
    }
}
Write-Output "User $UserPrincipalName disabled" # Color: $2



