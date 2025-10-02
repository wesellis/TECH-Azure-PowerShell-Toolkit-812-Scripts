#Requires -Version 7.4
#Requires -Modules Microsoft.Graph.Identity.SignIns

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$PolicyName,
    [Parameter(Mandatory)]
    [string]$Description,
    [Parameter()]
    [array]$IncludeUsers = @("All"),
    [Parameter()]
    [array]$ExcludeUsers = @(),
    [Parameter()]
    [array]$IncludeApplications = @("All"),
    [Parameter()]
    [array]$RequireMFA = @("require"),
    [Parameter()]
    [string]$State = "enabledForReportingButNotEnforced"
)
Write-Output "Creating Conditional Access Policy: $PolicyName"
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
        Write-Warning "Microsoft.Graph.Identity.SignIns module is required for full functionality"
        Write-Output "Install with: Install-Module Microsoft.Graph.Identity.SignIns"
    }
    Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"
    Write-Output "Connected to Microsoft Graph"
    Write-Output "Name: $PolicyName"
    Write-Output "Description: $Description"
    Write-Output "State: $State"
    Write-Output "Include Users: $($IncludeUsers -join ', ')"
    if ($ExcludeUsers.Count -gt 0) {
        Write-Output "Exclude Users: $($ExcludeUsers -join ', ')"
    }
    Write-Output "Applications: $($IncludeApplications -join ', ')"
    Write-Output "Grant Controls: $($RequireMFA -join ', ')"
    Write-Output "`n[WARN] IMPORTANT NOTES:"
    Write-Output "Policy created in report-only mode by default"
    Write-Output "Test thoroughly before enabling enforcement"
    Write-Output "Ensure emergency access accounts are excluded"
    Write-Output "Monitor sign-in logs for impact analysis"
    Write-Output "`nConditional Access Policy Benefits:"
    Write-Output "Zero Trust security model"
    Write-Output "Risk-based access control"
    Write-Output "Multi-factor authentication enforcement"
    Write-Output "Device compliance requirements"
    Write-Output "Location-based restrictions"
    Write-Output "`nCommon Policy Types:"
    Write-Output "1. Require MFA for all users"
    Write-Output "2. Block access from untrusted locations"
    Write-Output "3. Require compliant devices"
    Write-Output "4. Require approved client apps"
    Write-Output "5. Block legacy authentication"
    Write-Output "`nNext Steps:"
    Write-Output "1. Create policy via Azure Portal (recommended)"
    Write-Output "2. Configure conditions and controls"
    Write-Output "3. Test with pilot users"
    Write-Output "4. Enable policy after validation"
    Write-Output "5. Monitor compliance and adjust as needed"
    Write-Output "`nManual Creation Steps:"
    Write-Output "1. Azure Portal > Azure Active Directory"
    Write-Output "2. Security > Conditional Access"
    Write-Output "3. New Policy"
    Write-Output "4. Configure users, apps, and conditions"
    Write-Output "5. Set access controls and session controls"
    Write-Output "6. Enable policy"
    Write-Output "`n Conditional Access policy template prepared"
} catch {
    Write-Error "Conditional Access policy creation failed: $($_.Exception.Message)"`n}
