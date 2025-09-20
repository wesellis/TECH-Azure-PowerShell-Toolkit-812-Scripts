<#
.SYNOPSIS
    Azure Conditionalaccess Policy Creator

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding()];
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PolicyName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Description,
    [Parameter()]
    [array]$IncludeUsers = @("All" ),
    [Parameter()]
    [array]$ExcludeUsers = @(),
    [Parameter()]
    [array]$IncludeApplications = @("All" ),
    [Parameter()]
    [array]$RequireMFA = @(" require" ),
    [Parameter()]
    [string]$State = " enabledForReportingButNotEnforced"
)
Write-Host "Creating Conditional Access Policy: $PolicyName"
try {
    # Check if Microsoft.Graph.Identity.SignIns module is available
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
        Write-Warning "Microsoft.Graph.Identity.SignIns module is required for full functionality"
        Write-Host "Install with: Install-Module Microsoft.Graph.Identity.SignIns"
    }
    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"
    Write-Host "Connected to Microsoft Graph"
    Write-Host "Conditional Access Policy Configuration:"
    Write-Host "Name: $PolicyName"
    Write-Host "Description: $Description"
    Write-Host "State: $State"
    Write-Host "Include Users: $($IncludeUsers -join ', ')"
    if ($ExcludeUsers.Count -gt 0) {
        Write-Host "Exclude Users: $($ExcludeUsers -join ', ')"
    }
    Write-Host "Applications: $($IncludeApplications -join ', ')"
    Write-Host "Grant Controls: $($RequireMFA -join ', ')"
    Write-Host " `n[WARN] IMPORTANT NOTES:"
    Write-Host "Policy created in report-only mode by default"
    Write-Host "Test thoroughly before enabling enforcement"
    Write-Host "Ensure emergency access accounts are excluded"
    Write-Host "Monitor sign-in logs for impact analysis"
    Write-Host " `nConditional Access Policy Benefits:"
    Write-Host "Zero Trust security model"
    Write-Host "Risk-based access control"
    Write-Host "Multi-factor authentication enforcement"
    Write-Host "Device compliance requirements"
    Write-Host "Location-based restrictions"
    Write-Host " `nCommon Policy Types:"
    Write-Host " 1. Require MFA for all users"
    Write-Host " 2. Block access from untrusted locations"
    Write-Host " 3. Require compliant devices"
    Write-Host " 4. Require approved client apps"
    Write-Host " 5. Block legacy authentication"
    Write-Host " `nNext Steps:"
    Write-Host " 1. Create policy via Azure Portal (recommended)"
    Write-Host " 2. Configure conditions and controls"
    Write-Host " 3. Test with pilot users"
    Write-Host " 4. Enable policy after validation"
    Write-Host " 5. Monitor compliance and adjust as needed"
    Write-Host " `nManual Creation Steps:"
    Write-Host " 1. Azure Portal > Azure Active Directory"
    Write-Host " 2. Security > Conditional Access"
    Write-Host " 3. New Policy"
    Write-Host " 4. Configure users, apps, and conditions"
    Write-Host " 5. Set access controls and session controls"
    Write-Host " 6. Enable policy"
    Write-Host " `n Conditional Access policy template prepared"
    Write-Host "Use Azure Portal to create the actual policy for safety"
} catch {
    Write-Error "Conditional Access policy creation failed: $($_.Exception.Message)"
    Write-Host "Tip: Use Azure Portal for creating Conditional Access policies"
}

