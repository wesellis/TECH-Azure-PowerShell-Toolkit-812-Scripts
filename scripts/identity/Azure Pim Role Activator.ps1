#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Pim Role Activator

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Log {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"
    }
    [string]$LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$RoleName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
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
    [string]$CurrentUser = Get-MgUser -UserId (Get-MgContext).Account
    Write-Output "Current user: $($CurrentUser.DisplayName)"
    [string]$ActivationStart = Get-Date -ErrorAction Stop
    [string]$ActivationEnd = $ActivationStart.AddHours($DurationHours)
    Write-Output " `nPIM Activation Request:"
    Write-Output "Role: $RoleName"
    Write-Output "Start Time: $($ActivationStart.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Output "End Time: $($ActivationEnd.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Output "Duration: $DurationHours hours"
    Write-Output " `n[WARN] PIM Activation Process:"
    Write-Output " 1. This script provides the framework for PIM activation"
    Write-Output " 2. Actual activation requires Azure AD Premium P2 license"
    Write-Output " 3. Use Azure Portal or Microsoft Graph API for activation"
    Write-Output " 4. Approval may be required based on role settings"
    Write-Output " `nPIM Benefits:"
    Write-Output "Just-in-time privileged access"
    Write-Output "Time-limited role assignments"
    Write-Output "Approval workflows"
    Write-Output "Activity monitoring and alerts"
    Write-Output "Reduced standing privileges"
    Write-Output " `nManual PIM Activation Steps:"
    Write-Output " 1. Go to Azure Portal > Azure AD Privileged Identity Management"
    Write-Output " 2. Select 'My roles' > 'Azure resources'"
    Write-Output " 3. Find eligible role: $RoleName"
    Write-Output " 4. Click 'Activate' and provide justification"
    Write-Output " 5. Set duration: $DurationHours hours"
    Write-Output " 6. Submit activation request"
    Write-Output " `nPowerShell Alternative:"
    Write-Output " # Using Microsoft.Graph.Identity.Governance module"
    Write-Output "Import-Module Microsoft.Graph.Identity.Governance"
    Write-Output "     Write-Host " `n PIM activation guidance provided"
    Write-Output "Remember to deactivate when no longer needed"
} catch {
    Write-Error "PIM activation failed: $($_.Exception.Message)"`n}
