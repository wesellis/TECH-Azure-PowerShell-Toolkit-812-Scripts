#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Accounts

<#
.SYNOPSIS
    Azure Bulk User Offboarding Tool

.DESCRIPTION
    Automated bulk user offboarding across all Azure services.
    This script disables user accounts, removes licenses, group memberships,
    and optionally forwards emails during user offboarding process

.PARAMETER UserPrincipalName
    UPN of the user to offboard

.PARAMETER ForwardingAddress
    Email address to forward user emails to

.PARAMETER RemoveFromAllGroups
    Remove user from all Azure AD groups

.EXAMPLE
    .\Azure-Bulk-User-Offboarding-Tool.ps1 -UserPrincipalName "user@company.com" -ForwardingAddress "manager@company.com" -RemoveFromAllGroups

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0
    Created: December 2024
    Updated: May 23, 2025
    Company: CompuCom Systems Inc.
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ForwardingAddress,

    [Parameter()]
    [switch]$RemoveFromAllGroups
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# Setup logging
$LogFile = "UserOffboarding_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - [$Level] $Message"

    $LogEntry | Out-File -FilePath $LogFile -Append

    $ColorMap = @{
        "INFO" = "White"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }

    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Starting offboarding process for $UserPrincipalName" -Level INFO

    # Connect to Azure AD
    Write-Log "Connecting to Azure AD..." -Level INFO
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Connect-AzAccount
    }

    # Import Azure AD module if needed
    if (-not (Get-Module -Name AzureAD -ListAvailable)) {
        Write-Log "Azure AD module not found. Installing..." -Level WARN
        Install-Module -Name AzureAD -Force -AllowClobber
        Import-Module AzureAD
    }

    # Connect to Azure AD
    Connect-AzureAD

    # Get the user
    Write-Log "Retrieving user information..." -Level INFO
    $User = Get-AzureADUser -ObjectId $UserPrincipalName -ErrorAction Stop

    if (-not $User) {
        throw "User $UserPrincipalName not found"
    }

    Write-Log "Found user: $($User.DisplayName) (ObjectId: $($User.ObjectId))" -Level SUCCESS

    # Disable the account
    Write-Log "Disabling user account..." -Level INFO
    Set-AzureADUser -ObjectId $User.ObjectId -AccountEnabled $false
    Write-Log "Account disabled successfully" -Level SUCCESS

    # Remove licenses
    Write-Log "Removing user licenses..." -Level INFO
    $UserLicenses = Get-AzureADUserLicenseDetail -ObjectId $User.ObjectId

    if ($UserLicenses) {
        foreach ($License in $UserLicenses) {
            try {
                $LicenseToRemove = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
                $LicenseToRemove.SkuId = $License.SkuId

                $LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
                $LicensesToAssign.RemoveLicenses = @($LicenseToRemove.SkuId)

                Set-AzureADUserLicense -ObjectId $User.ObjectId -AssignedLicenses $LicensesToAssign
                Write-Log "Removed license: $($License.SkuPartNumber)" -Level SUCCESS
            }
            catch {
                Write-Log "Failed to remove license $($License.SkuPartNumber): $($_.Exception.Message)" -Level WARN
            }
        }
    } else {
        Write-Log "No licenses found for user" -Level INFO
    }

    # Remove from groups if requested
    if ($RemoveFromAllGroups) {
        Write-Log "Removing user from all groups..." -Level INFO
        $UserGroups = Get-AzureADUserMembership -ObjectId $User.ObjectId -All $true

        foreach ($Group in $UserGroups) {
            if ($Group.ObjectType -eq "Group") {
                try {
                    Remove-AzureADGroupMember -ObjectId $Group.ObjectId -MemberId $User.ObjectId
                    Write-Log "Removed from group: $($Group.DisplayName)" -Level SUCCESS
                }
                catch {
                    Write-Log "Failed to remove from group $($Group.DisplayName): $($_.Exception.Message)" -Level WARN
                }
            }
        }
    }

    # Set email forwarding if requested
    if ($ForwardingAddress) {
        try {
            Write-Log "Setting up email forwarding..." -Level INFO

            # Check if Exchange Online Management module is available
            if (Get-Module -Name ExchangeOnlineManagement -ListAvailable) {
                Connect-ExchangeOnline -ShowProgress $false
                Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $ForwardingAddress -ForwardingSmtpAddress $ForwardingAddress
                Write-Log "Email forwarding set to: $ForwardingAddress" -Level SUCCESS
            } else {
                Write-Log "Exchange Online Management module not available. Email forwarding skipped." -Level WARN
            }
        }
        catch {
            Write-Log "Could not set email forwarding: $($_.Exception.Message)" -Level WARN
        }
    }

    # Reset password to random value
    Write-Log "Resetting user password..." -Level INFO
    $RandomPassword = -join ((48..57) + (65..90) + (97..122) + (33..38) | Get-Random -Count 20 | ForEach-Object {[char]$_})
    $SecurePassword = ConvertTo-SecureString -String $RandomPassword -AsPlainText -Force

    Set-AzureADUserPassword -ObjectId $User.ObjectId -Password $SecurePassword -ForceChangePasswordNextLogin $false
    Write-Log "Password reset to random value" -Level SUCCESS

    # Revoke all refresh tokens
    Write-Log "Revoking all refresh tokens..." -Level INFO
    Revoke-AzureADUserAllRefreshToken -ObjectId $User.ObjectId
    Write-Log "All refresh tokens revoked" -Level SUCCESS

    # Generate offboarding report
    Write-Log "`n=== Offboarding Summary ===" -Level INFO
    Write-Log "User: $($User.DisplayName)" -Level INFO
    Write-Log "UPN: $UserPrincipalName" -Level INFO
    Write-Log "Account Status: Disabled" -Level INFO
    Write-Log "Licenses Removed: $($UserLicenses.Count)" -Level INFO
    if ($RemoveFromAllGroups) {
        Write-Log "Groups Removed From: $($UserGroups.Count)" -Level INFO
    }
    if ($ForwardingAddress) {
        Write-Log "Email Forwarding: $ForwardingAddress" -Level INFO
    }
    Write-Log "Password: Reset" -Level INFO
    Write-Log "Tokens: Revoked" -Level INFO

    Write-Log "Offboarding completed successfully for $UserPrincipalName" -Level SUCCESS
    Write-Log "Log file saved to: $LogFile" -Level INFO
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" -Level ERROR
    throw
}