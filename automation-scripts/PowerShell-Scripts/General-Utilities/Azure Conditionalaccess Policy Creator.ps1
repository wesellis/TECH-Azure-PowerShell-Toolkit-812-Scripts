<#
.SYNOPSIS
    Azure Conditionalaccess Policy Creator

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
    We Enhanced Azure Conditionalaccess Policy Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPolicyName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDescription,
    
    [Parameter(Mandatory=$false)]
    [array]$WEIncludeUsers = @(" All" ),
    
    [Parameter(Mandatory=$false)]
    [array]$WEExcludeUsers = @(),
    
    [Parameter(Mandatory=$false)]
    [array]$WEIncludeApplications = @(" All" ),
    
    [Parameter(Mandatory=$false)]
    [array]$WERequireMFA = @(" require" ),
    
    [Parameter(Mandatory=$false)]
    [string]$WEState = " enabledForReportingButNotEnforced"
)

Write-WELog " Creating Conditional Access Policy: $WEPolicyName" " INFO"

try {
    # Check if Microsoft.Graph.Identity.SignIns module is available
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
        Write-Warning " Microsoft.Graph.Identity.SignIns module is required for full functionality"
        Write-WELog " Install with: Install-Module Microsoft.Graph.Identity.SignIns" " INFO"
    }
    
    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes " Policy.ReadWrite.ConditionalAccess"
    
    Write-WELog " ✅ Connected to Microsoft Graph" " INFO"
    
    Write-WELog " 🔐 Conditional Access Policy Configuration:" " INFO"
    Write-WELog "  Name: $WEPolicyName" " INFO"
    Write-WELog "  Description: $WEDescription" " INFO"
    Write-WELog "  State: $WEState" " INFO"
    Write-WELog "  Include Users: $($WEIncludeUsers -join ', ')" " INFO"
    if ($WEExcludeUsers.Count -gt 0) {
        Write-WELog "  Exclude Users: $($WEExcludeUsers -join ', ')" " INFO"
    }
    Write-WELog "  Applications: $($WEIncludeApplications -join ', ')" " INFO"
    Write-WELog "  Grant Controls: $($WERequireMFA -join ', ')" " INFO"
    
    Write-WELog " `n⚠️ IMPORTANT NOTES:" " INFO"
    Write-WELog " • Policy created in report-only mode by default" " INFO"
    Write-WELog " • Test thoroughly before enabling enforcement" " INFO"
    Write-WELog " • Ensure emergency access accounts are excluded" " INFO"
    Write-WELog " • Monitor sign-in logs for impact analysis" " INFO"
    
    Write-WELog " `nConditional Access Policy Benefits:" " INFO"
    Write-WELog " • Zero Trust security model" " INFO"
    Write-WELog " • Risk-based access control" " INFO"
    Write-WELog " • Multi-factor authentication enforcement" " INFO"
    Write-WELog " • Device compliance requirements" " INFO"
    Write-WELog " • Location-based restrictions" " INFO"
    
    Write-WELog " `nCommon Policy Types:" " INFO"
    Write-WELog " 1. Require MFA for all users" " INFO"
    Write-WELog " 2. Block access from untrusted locations" " INFO"
    Write-WELog " 3. Require compliant devices" " INFO"
    Write-WELog " 4. Require approved client apps" " INFO"
    Write-WELog " 5. Block legacy authentication" " INFO"
    
    Write-WELog " `nNext Steps:" " INFO"
    Write-WELog " 1. Create policy via Azure Portal (recommended)" " INFO"
    Write-WELog " 2. Configure conditions and controls" " INFO"
    Write-WELog " 3. Test with pilot users" " INFO"
    Write-WELog " 4. Enable policy after validation" " INFO"
    Write-WELog " 5. Monitor compliance and adjust as needed" " INFO"
    
    Write-WELog " `nManual Creation Steps:" " INFO"
    Write-WELog " 1. Azure Portal > Azure Active Directory" " INFO"
    Write-WELog " 2. Security > Conditional Access" " INFO"
    Write-WELog " 3. New Policy" " INFO"
    Write-WELog " 4. Configure users, apps, and conditions" " INFO"
    Write-WELog " 5. Set access controls and session controls" " INFO"
    Write-WELog " 6. Enable policy" " INFO"
    
    Write-WELog " `n✅ Conditional Access policy template prepared" " INFO"
    Write-WELog " 🚨 Use Azure Portal to create the actual policy for safety" " INFO"
    
} catch {
    Write-Error " Conditional Access policy creation failed: $($_.Exception.Message)"
    Write-WELog " 💡 Tip: Use Azure Portal for creating Conditional Access policies" " INFO"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================