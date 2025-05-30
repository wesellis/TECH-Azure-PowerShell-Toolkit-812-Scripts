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

Write-Host "Activating PIM role: $RoleName"
Write-Host "Scope: $ResourceScope"
Write-Host "Duration: $DurationHours hours"
Write-Host "Justification: $Justification"

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
    Write-Host "Current user: $($CurrentUser.DisplayName)"
    
    # Calculate activation end time
    $ActivationStart = Get-Date
    $ActivationEnd = $ActivationStart.AddHours($DurationHours)
    
    Write-Host "`nPIM Activation Request:"
    Write-Host "  Role: $RoleName"
    Write-Host "  Start Time: $($ActivationStart.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "  End Time: $($ActivationEnd.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "  Duration: $DurationHours hours"
    
    # Note: Actual PIM activation requires Azure AD Premium P2 and specific Graph API calls
    # This is a template showing the structure - actual implementation depends on environment
    
    Write-Host "`n⚠️ PIM Activation Process:"
    Write-Host "1. This script provides the framework for PIM activation"
    Write-Host "2. Actual activation requires Azure AD Premium P2 license"
    Write-Host "3. Use Azure Portal or Microsoft Graph API for activation"
    Write-Host "4. Approval may be required based on role settings"
    
    Write-Host "`nPIM Benefits:"
    Write-Host "• Just-in-time privileged access"
    Write-Host "• Time-limited role assignments"
    Write-Host "• Approval workflows"
    Write-Host "• Activity monitoring and alerts"
    Write-Host "• Reduced standing privileges"
    
    Write-Host "`nManual PIM Activation Steps:"
    Write-Host "1. Go to Azure Portal > Azure AD Privileged Identity Management"
    Write-Host "2. Select 'My roles' > 'Azure resources'"
    Write-Host "3. Find eligible role: $RoleName"
    Write-Host "4. Click 'Activate' and provide justification"
    Write-Host "5. Set duration: $DurationHours hours"
    Write-Host "6. Submit activation request"
    
    Write-Host "`nPowerShell Alternative:"
    Write-Host "# Using Microsoft.Graph.Identity.Governance module"
    Write-Host "Import-Module Microsoft.Graph.Identity.Governance"
    Write-Host "# Create activation request using New-MgIdentityGovernancePrivilegedAccessRoleAssignmentRequest"
    
    Write-Host "`n✅ PIM activation guidance provided"
    Write-Host "⏰ Remember to deactivate when no longer needed"
    
} catch {
    Write-Error "PIM activation failed: $($_.Exception.Message)"
}
