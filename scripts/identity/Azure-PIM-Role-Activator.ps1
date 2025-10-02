#Requires -Version 7.4
#Requires -Modules Microsoft.Graph.Authentication

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$RoleName,
    [Parameter(Mandatory)]
    [string]$ResourceScope,
    [Parameter()]
    [int]$DurationHours = 1,
    [Parameter()]
    [string]$Justification = "Administrative task requiring elevated access"
)
Write-Output "Activating PIM role: $RoleName"
Write-Output "Scope: $ResourceScope"
Write-Output "Duration: $DurationHours hours"
Write-Output "Justification: $Justification"
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Error "Microsoft.Graph.Authentication module is required. Install with: Install-Module Microsoft.Graph.Authentication"
        return
    }
    Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"
    $CurrentUser = Get-MgUser -UserId (Get-MgContext).Account
    Write-Output "Current user: $($CurrentUser.DisplayName)"
    $ActivationStart = Get-Date -ErrorAction Stop
    $ActivationEnd = $ActivationStart.AddHours($DurationHours)
    Write-Output "`nPIM Activation Request:"
    Write-Output "Role: $RoleName"
    Write-Output "Start Time: $($ActivationStart.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Output "End Time: $($ActivationEnd.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Output "Duration: $DurationHours hours"
    Write-Output "`n[WARN] PIM Activation Process:"
    Write-Output "1. This script provides the framework for PIM activation"
    Write-Output "2. Actual activation requires Azure AD Premium P2 license"
    Write-Output "3. Use Azure Portal or Microsoft Graph API for activation"
    Write-Output "4. Approval may be required based on role settings"
    Write-Output "`nPIM Benefits:"
    Write-Output "Just-in-time privileged access"
    Write-Output "Time-limited role assignments"
    Write-Output "Approval workflows"
    Write-Output "Activity monitoring and alerts"
    Write-Output "Reduced standing privileges"
    Write-Output "`nManual PIM Activation Steps:"
    Write-Output "1. Go to Azure Portal > Azure AD Privileged Identity Management"
    Write-Output "2. Select 'My roles' > 'Azure resources'"
    Write-Output "3. Find eligible role: $RoleName"
    Write-Output "4. Click 'Activate' and provide justification"
    Write-Output "5. Set duration: $DurationHours hours"
    Write-Output "6. Submit activation request"
    Write-Output "`nPowerShell Alternative:"
    Write-Output "# Using Microsoft.Graph.Identity.Governance module"
    Write-Output "Import-Module Microsoft.Graph.Identity.Governance"
    Write-Output "    Write-Host "`n PIM activation guidance provided"
    Write-Output "Remember to deactivate when no longer needed"
} catch {
    Write-Error "PIM activation failed: $($_.Exception.Message)"`n}
