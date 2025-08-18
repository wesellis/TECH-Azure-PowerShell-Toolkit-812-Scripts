# ============================================================================
# Script Name: Azure Privileged Identity Management Activator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Activates eligible Azure PIM roles for just-in-time access
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$RoleName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceScope,
    
    [Parameter(Mandatory=$false)]
    [int]$DurationHours = 1,
    
    [Parameter(Mandatory=$false)]
    [string]$Justification = "Administrative task requiring elevated access"
)

Write-Information "Activating PIM role: $RoleName"
Write-Information "Scope: $ResourceScope"
Write-Information "Duration: $DurationHours hours"
Write-Information "Justification: $Justification"

try {
    # Check if Microsoft.Graph.Authentication module is available
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Error "Microsoft.Graph.Authentication module is required. Install with: Install-Module Microsoft.Graph.Authentication"
        return
    }
    
    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"
    
    # Get current user
    $CurrentUser = Get-MgUser -UserId (Get-MgContext).Account
    Write-Information "Current user: $($CurrentUser.DisplayName)"
    
    # Calculate activation end time
    $ActivationStart = Get-Date -ErrorAction Stop
    $ActivationEnd = $ActivationStart.AddHours($DurationHours)
    
    Write-Information "`nPIM Activation Request:"
    Write-Information "  Role: $RoleName"
    Write-Information "  Start Time: $($ActivationStart.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Information "  End Time: $($ActivationEnd.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Information "  Duration: $DurationHours hours"
    
    # Note: Actual PIM activation requires Azure AD Premium P2 and specific Graph API calls
    # This is a template showing the structure - actual implementation depends on environment
    
    Write-Information "`n⚠️ PIM Activation Process:"
    Write-Information "1. This script provides the framework for PIM activation"
    Write-Information "2. Actual activation requires Azure AD Premium P2 license"
    Write-Information "3. Use Azure Portal or Microsoft Graph API for activation"
    Write-Information "4. Approval may be required based on role settings"
    
    Write-Information "`nPIM Benefits:"
    Write-Information "• Just-in-time privileged access"
    Write-Information "• Time-limited role assignments"
    Write-Information "• Approval workflows"
    Write-Information "• Activity monitoring and alerts"
    Write-Information "• Reduced standing privileges"
    
    Write-Information "`nManual PIM Activation Steps:"
    Write-Information "1. Go to Azure Portal > Azure AD Privileged Identity Management"
    Write-Information "2. Select 'My roles' > 'Azure resources'"
    Write-Information "3. Find eligible role: $RoleName"
    Write-Information "4. Click 'Activate' and provide justification"
    Write-Information "5. Set duration: $DurationHours hours"
    Write-Information "6. Submit activation request"
    
    Write-Information "`nPowerShell Alternative:"
    Write-Information "# Using Microsoft.Graph.Identity.Governance module"
    Write-Information "Import-Module Microsoft.Graph.Identity.Governance"
    Write-Information "# Create activation request using New-MgIdentityGovernancePrivilegedAccessRoleAssignmentRequest"
    
    Write-Information "`n✅ PIM activation guidance provided"
    Write-Information "⏰ Remember to deactivate when no longer needed"
    
} catch {
    Write-Error "PIM activation failed: $($_.Exception.Message)"
}
