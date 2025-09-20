#Requires -Version 7.0

<#`n.SYNOPSIS
    Disable user account and cleanup

.DESCRIPTION
Disable user, reset password, revoke sessions
.PARAMETER UserPrincipalName
User to disable
.PARAMETER Manager
Forward email to this address
.EXAMPLE
.\Disable-User.ps1 -UserPrincipalName john@company.com
.EXAMPLE
.\Disable-User.ps1 -UserPrincipalName john@company.com -Manager jane@company.com
#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$UserPrincipalName,
    [string]$Manager
)
Connect-MgGraph -Scopes "User.ReadWrite.All"
$user = Get-MgUser -UserId $UserPrincipalName
Write-Host "Disabling $($user.DisplayName)" -ForegroundColor Yellow
# Disable account
Update-MgUser -UserId $user.Id -AccountEnabled:$false
Write-Host "Account disabled"
# Reset password
$newPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | % {[char]$_})
Update-MgUser -UserId $user.Id -PasswordProfile @{Password=$newPassword; ForceChangePasswordNextSignIn=$true}
Write-Host "Password reset"
# Revoke sessions
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$($user.Id)/revokeSignInSessions"
Write-Host "Sessions revoked"
# Set forwarding if specified
if ($Manager) {
    try {
        Import-Module ExchangeOnlineManagement
        Connect-ExchangeOnline -ShowProgress:$false
        Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $Manager
        Write-Host "Email forwarding set to $Manager"
    } catch {
        Write-Warning "Could not set email forwarding: $_"
    }
}
Write-Host "User $UserPrincipalName disabled" -ForegroundColor Green


