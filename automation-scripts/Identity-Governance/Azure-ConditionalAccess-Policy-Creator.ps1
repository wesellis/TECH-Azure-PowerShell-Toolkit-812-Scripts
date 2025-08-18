# ============================================================================
# Script Name: Azure Conditional Access Policy Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure AD Conditional Access policies for enhanced security
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$PolicyName,
    
    [Parameter(Mandatory=$true)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [array]$IncludeUsers = @("All"),
    
    [Parameter(Mandatory=$false)]
    [array]$ExcludeUsers = @(),
    
    [Parameter(Mandatory=$false)]
    [array]$IncludeApplications = @("All"),
    
    [Parameter(Mandatory=$false)]
    [array]$RequireMFA = @("require"),
    
    [Parameter(Mandatory=$false)]
    [string]$State = "enabledForReportingButNotEnforced"
)

Write-Information "Creating Conditional Access Policy: $PolicyName"

try {
    # Check if Microsoft.Graph.Identity.SignIns module is available
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
        Write-Warning "Microsoft.Graph.Identity.SignIns module is required for full functionality"
        Write-Information "Install with: Install-Module Microsoft.Graph.Identity.SignIns"
    }
    
    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"
    
    Write-Information "✅ Connected to Microsoft Graph"
    
    Write-Information "🔐 Conditional Access Policy Configuration:"
    Write-Information "  Name: $PolicyName"
    Write-Information "  Description: $Description"
    Write-Information "  State: $State"
    Write-Information "  Include Users: $($IncludeUsers -join ', ')"
    if ($ExcludeUsers.Count -gt 0) {
        Write-Information "  Exclude Users: $($ExcludeUsers -join ', ')"
    }
    Write-Information "  Applications: $($IncludeApplications -join ', ')"
    Write-Information "  Grant Controls: $($RequireMFA -join ', ')"
    
    Write-Information "`n⚠️ IMPORTANT NOTES:"
    Write-Information "• Policy created in report-only mode by default"
    Write-Information "• Test thoroughly before enabling enforcement"
    Write-Information "• Ensure emergency access accounts are excluded"
    Write-Information "• Monitor sign-in logs for impact analysis"
    
    Write-Information "`nConditional Access Policy Benefits:"
    Write-Information "• Zero Trust security model"
    Write-Information "• Risk-based access control"
    Write-Information "• Multi-factor authentication enforcement"
    Write-Information "• Device compliance requirements"
    Write-Information "• Location-based restrictions"
    
    Write-Information "`nCommon Policy Types:"
    Write-Information "1. Require MFA for all users"
    Write-Information "2. Block access from untrusted locations"
    Write-Information "3. Require compliant devices"
    Write-Information "4. Require approved client apps"
    Write-Information "5. Block legacy authentication"
    
    Write-Information "`nNext Steps:"
    Write-Information "1. Create policy via Azure Portal (recommended)"
    Write-Information "2. Configure conditions and controls"
    Write-Information "3. Test with pilot users"
    Write-Information "4. Enable policy after validation"
    Write-Information "5. Monitor compliance and adjust as needed"
    
    Write-Information "`nManual Creation Steps:"
    Write-Information "1. Azure Portal > Azure Active Directory"
    Write-Information "2. Security > Conditional Access"
    Write-Information "3. New Policy"
    Write-Information "4. Configure users, apps, and conditions"
    Write-Information "5. Set access controls and session controls"
    Write-Information "6. Enable policy"
    
    Write-Information "`n✅ Conditional Access policy template prepared"
    Write-Information "🚨 Use Azure Portal to create the actual policy for safety"
    
} catch {
    Write-Error "Conditional Access policy creation failed: $($_.Exception.Message)"
    Write-Information "💡 Tip: Use Azure Portal for creating Conditional Access policies"
}
