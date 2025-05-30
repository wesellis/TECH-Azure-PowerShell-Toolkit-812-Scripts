# ============================================================================
# Script Name: Azure Bulk User Offboarding Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Comprehensive automated bulk user offboarding across all Azure services
# ============================================================================

#Requires -Modules Az.Accounts, Az.Resources, AzureAD

<#
.SYNOPSIS
    Automated bulk user offboarding across all Azure services
.DESCRIPTION
    Comprehensive script to disable user accounts, remove licenses, group memberships,
    and optionally forward emails during user offboarding process
.PARAMETER UserPrincipalName
    UPN of the user to offboard
.PARAMETER ForwardingAddress
    Email address to forward user emails to
.PARAMETER RemoveFromAllGroups
    Remove user from all Azure AD groups
.EXAMPLE
    .\Azure-Bulk-User-Offboarding-Tool.ps1 -UserPrincipalName "user@company.com" -ForwardingAddress "manager@company.com" -RemoveFromAllGroups
.NOTES
    Author: Wesley Ellis
    Created: December 2024
    Updated: May 23, 2025
    Company: CompuCom Systems Inc.
    Email: wes@wesellis.com
    Website: wesellis.com
    Version: 2.0
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [string]$ForwardingAddress,
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveFromAllGroups
)

# Initialize logging
$LogFile = "UserOffboarding_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
function Write-Log {
    param($Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append
    Write-Host "$Timestamp - $Message"
}

try {
    Write-Log "Starting offboarding process for $UserPrincipalName"
    
    # Connect to Azure AD
    Connect-AzureAD
    
    # Get user object
    $User = Get-AzureADUser -ObjectId $UserPrincipalName
    if (-not $User) {
        throw "User $UserPrincipalName not found"
    }
    
    Write-Log "Found user: $($User.DisplayName)"
    
    # Disable the account
    Set-AzureADUser -ObjectId $User.ObjectId -AccountEnabled $false
    Write-Log "Account disabled"
    
    # Remove licenses
    $UserLicenses = Get-AzureADUserLicenseDetail -ObjectId $User.ObjectId
    foreach ($License in $UserLicenses) {
        $LicenseToRemove = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
        $LicenseToRemove.SkuId = $License.SkuId
        
        $LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
        $LicensesToAssign.RemoveLicenses = $LicenseToRemove.SkuId
        
        Set-AzureADUserLicense -ObjectId $User.ObjectId -AssignedLicenses $LicensesToAssign
        Write-Log "Removed license: $($License.SkuPartNumber)"
    }
    
    # Remove from groups if specified
    if ($RemoveFromAllGroups) {
        $UserGroups = Get-AzureADUserMembership -ObjectId $User.ObjectId
        foreach ($Group in $UserGroups) {
            if ($Group.ObjectType -eq "Group") {
                Remove-AzureADGroupMember -ObjectId $Group.ObjectId -MemberId $User.ObjectId
                Write-Log "Removed from group: $($Group.DisplayName)"
            }
        }
    }
    
    # Set email forwarding if specified and connect to Exchange Online
    if ($ForwardingAddress) {
        try {
            Connect-ExchangeOnline -ShowProgress $false
            Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $ForwardingAddress
            Write-Log "Email forwarding set to: $ForwardingAddress"
        } catch {
            Write-Log "Warning: Could not set email forwarding - $($_.Exception.Message)"
        }
    }
    
    # Reset password to random value
    $RandomPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object {[char]$_})
    $SecurePassword = ConvertTo-SecureString $RandomPassword -AsPlainText -Force
    Set-AzureADUserPassword -ObjectId $User.ObjectId -Password $SecurePassword
    Write-Log "Password reset to random value"
    
    # Revoke all refresh tokens
    Revoke-AzureADUserAllRefreshToken -ObjectId $User.ObjectId
    Write-Log "All refresh tokens revoked"
    
    Write-Log "Offboarding completed successfully for $UserPrincipalName"
    
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
