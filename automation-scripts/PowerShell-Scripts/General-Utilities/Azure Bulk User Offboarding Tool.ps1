<#
.SYNOPSIS
    Azure Bulk User Offboarding Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Bulk User Offboarding Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

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
    .\Azure-Bulk-User-Offboarding-Tool.ps1 -UserPrincipalName " user@company.com" -ForwardingAddress " manager@company.com" -RemoveFromAllGroups
.NOTES
    Author: Wesley Ellis
    Created: December 2024
    Updated: May 23, 2025
    Company: CompuCom Systems Inc.
    Email: [Email Address]
    
    Version: 2.0


[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEUserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEForwardingAddress,
    
    [Parameter(Mandatory=$false)]
    [switch]$WERemoveFromAllGroups
)


$WELogFile = " UserOffboarding_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
[CmdletBinding()]
function WE-Write-Log {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($WEMessage)
    $WETimestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    " $WETimestamp - $WEMessage" | Out-File -FilePath $WELogFile -Append
    Write-WELog " $WETimestamp - $WEMessage" " INFO"
}

try {
    Write-Log " Starting offboarding process for $WEUserPrincipalName"
    
    # Connect to Azure AD
    Connect-AzureAD
    
    # Get user object
    $WEUser = Get-AzureADUser -ObjectId $WEUserPrincipalName
    if (-not $WEUser) {
        throw " User $WEUserPrincipalName not found"
    }
    
    Write-Log " Found user: $($WEUser.DisplayName)"
    
    # Disable the account
    Set-AzureADUser -ObjectId $WEUser.ObjectId -AccountEnabled $false
    Write-Log " Account disabled"
    
    # Remove licenses
    $WEUserLicenses = Get-AzureADUserLicenseDetail -ObjectId $WEUser.ObjectId
    foreach ($WELicense in $WEUserLicenses) {
        $WELicenseToRemove = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
        $WELicenseToRemove.SkuId = $WELicense.SkuId
        
        $WELicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
        $WELicensesToAssign.RemoveLicenses = $WELicenseToRemove.SkuId
        
        Set-AzureADUserLicense -ObjectId $WEUser.ObjectId -AssignedLicenses $WELicensesToAssign
        Write-Log " Removed license: $($WELicense.SkuPartNumber)"
    }
    
    # Remove from groups if specified
    if ($WERemoveFromAllGroups) {
        $WEUserGroups = Get-AzureADUserMembership -ObjectId $WEUser.ObjectId
        foreach ($WEGroup in $WEUserGroups) {
            if ($WEGroup.ObjectType -eq " Group" ) {
                Remove-AzureADGroupMember -ObjectId $WEGroup.ObjectId -MemberId $WEUser.ObjectId
                Write-Log " Removed from group: $($WEGroup.DisplayName)"
            }
        }
    }
    
    # Set email forwarding if specified and connect to Exchange Online
    if ($WEForwardingAddress) {
        try {
            Connect-ExchangeOnline -ShowProgress $false
            Set-Mailbox -Identity $WEUserPrincipalName -ForwardingAddress $WEForwardingAddress
            Write-Log " Email forwarding set to: $WEForwardingAddress"
        } catch {
            Write-Log " Warning: Could not set email forwarding - $($_.Exception.Message)"
        }
    }
    
    # Reset password to random value
   ;  $WERandomPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object {[char]$_})
   ;  $WESecurePassword = ConvertTo-SecureString $WERandomPassword -AsPlainText -Force
    Set-AzureADUserPassword -ObjectId $WEUser.ObjectId -Password $WESecurePassword
    Write-Log " Password reset to random value"
    
    # Revoke all refresh tokens
    Revoke-AzureADUserAllRefreshToken -ObjectId $WEUser.ObjectId
    Write-Log " All refresh tokens revoked"
    
    Write-Log " Offboarding completed successfully for $WEUserPrincipalName"
    
} catch {
    Write-Log " ERROR: $($_.Exception.Message)"
    throw
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================