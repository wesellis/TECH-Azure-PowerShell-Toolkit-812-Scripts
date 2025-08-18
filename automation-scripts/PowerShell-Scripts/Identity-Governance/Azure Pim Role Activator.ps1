<#
.SYNOPSIS
    We Enhanced Azure Pim Role Activator

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERoleName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceScope,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDurationHours = 1,
    
    [Parameter(Mandatory=$false)]
    [string]$WEJustification = " Administrative task requiring elevated access"
)

Write-WELog " Activating PIM role: $WERoleName" " INFO"
Write-WELog " Scope: $WEResourceScope" " INFO"
Write-WELog " Duration: $WEDurationHours hours" " INFO"
Write-WELog " Justification: $WEJustification" " INFO"

try {
    # Check if Microsoft.Graph.Authentication module is available
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Error " Microsoft.Graph.Authentication module is required. Install with: Install-Module Microsoft.Graph.Authentication"
        return
    }
    
    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes " RoleManagement.ReadWrite.Directory"
    
    # Get current user
    $WECurrentUser = Get-MgUser -UserId (Get-MgContext).Account
    Write-WELog " Current user: $($WECurrentUser.DisplayName)" " INFO"
    
    # Calculate activation end time
    $WEActivationStart = Get-Date
   ;  $WEActivationEnd = $WEActivationStart.AddHours($WEDurationHours)
    
    Write-WELog " `nPIM Activation Request:" " INFO"
    Write-WELog "  Role: $WERoleName" " INFO"
    Write-WELog "  Start Time: $($WEActivationStart.ToString('yyyy-MM-dd HH:mm:ss'))" " INFO"
    Write-WELog "  End Time: $($WEActivationEnd.ToString('yyyy-MM-dd HH:mm:ss'))" " INFO"
    Write-WELog "  Duration: $WEDurationHours hours" " INFO"
    
    # Note: Actual PIM activation requires Azure AD Premium P2 and specific Graph API calls
    # This is a template showing the structure - actual implementation depends on environment
    
    Write-WELog " `n⚠️ PIM Activation Process:" " INFO"
    Write-WELog " 1. This script provides the framework for PIM activation" " INFO"
    Write-WELog " 2. Actual activation requires Azure AD Premium P2 license" " INFO"
    Write-WELog " 3. Use Azure Portal or Microsoft Graph API for activation" " INFO"
    Write-WELog " 4. Approval may be required based on role settings" " INFO"
    
    Write-WELog " `nPIM Benefits:" " INFO"
    Write-WELog " • Just-in-time privileged access" " INFO"
    Write-WELog " • Time-limited role assignments" " INFO"
    Write-WELog " • Approval workflows" " INFO"
    Write-WELog " • Activity monitoring and alerts" " INFO"
    Write-WELog " • Reduced standing privileges" " INFO"
    
    Write-WELog " `nManual PIM Activation Steps:" " INFO"
    Write-WELog " 1. Go to Azure Portal > Azure AD Privileged Identity Management" " INFO"
    Write-WELog " 2. Select 'My roles' > 'Azure resources'" " INFO"
    Write-WELog " 3. Find eligible role: $WERoleName" " INFO"
    Write-WELog " 4. Click 'Activate' and provide justification" " INFO"
    Write-WELog " 5. Set duration: $WEDurationHours hours" " INFO"
    Write-WELog " 6. Submit activation request" " INFO"
    
    Write-WELog " `nPowerShell Alternative:" " INFO"
    Write-WELog " # Using Microsoft.Graph.Identity.Governance module" " INFO"
    Write-WELog " Import-Module Microsoft.Graph.Identity.Governance" " INFO"
    Write-WELog " # Create activation request using New-MgIdentityGovernancePrivilegedAccessRoleAssignmentRequest" " INFO"
    
    Write-WELog " `n✅ PIM activation guidance provided" " INFO"
    Write-WELog " ⏰ Remember to deactivate when no longer needed" " INFO"
    
} catch {
    Write-Error " PIM activation failed: $($_.Exception.Message)"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================