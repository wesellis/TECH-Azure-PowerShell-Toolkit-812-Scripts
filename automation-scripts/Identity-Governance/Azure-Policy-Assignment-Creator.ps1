# ============================================================================
# Script Name: Azure Policy Assignment Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Policy assignments for governance and compliance
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$PolicyDefinitionId,
    
    [Parameter(Mandatory=$true)]
    [string]$AssignmentName,
    
    [Parameter(Mandatory=$true)]
    [string]$Scope,
    
    [Parameter(Mandatory=$false)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Parameters = @{},
    
    [Parameter(Mandatory=$false)]
    [string]$EnforcementMode = "Default"
)

Write-Host "Creating Policy Assignment: $AssignmentName"

# Prepare assignment parameters
$AssignmentParams = @{
    Name = $AssignmentName
    PolicyDefinition = Get-AzPolicyDefinition -Id $PolicyDefinitionId
    Scope = $Scope
    EnforcementMode = $EnforcementMode
}

if ($Description) {
    $AssignmentParams.Description = $Description
}

if ($Parameters.Count -gt 0) {
    $AssignmentParams.PolicyParameterObject = $Parameters
}

# Create policy assignment
$Assignment = New-AzPolicyAssignment @AssignmentParams

Write-Host "✅ Policy Assignment created successfully:"
Write-Host "  Name: $($Assignment.Name)"
Write-Host "  Policy: $($Assignment.Properties.PolicyDefinitionId.Split('/')[-1])"
Write-Host "  Scope: $Scope"
Write-Host "  Enforcement Mode: $($Assignment.Properties.EnforcementMode)"

if ($Description) {
    Write-Host "  Description: $Description"
}

if ($Parameters.Count -gt 0) {
    Write-Host "`nPolicy Parameters:"
    foreach ($Param in $Parameters.GetEnumerator()) {
        Write-Host "  $($Param.Key): $($Param.Value)"
    }
}

Write-Host "`nPolicy Assignment Benefits:"
Write-Host "• Automated compliance enforcement"
Write-Host "• Consistent governance across resources"
Write-Host "• Audit and reporting capabilities"
Write-Host "• Cost and security optimization"

Write-Host "`nCommon Policy Types:"
Write-Host "• Resource tagging requirements"
Write-Host "• Location restrictions"
Write-Host "• SKU limitations"
Write-Host "• Security configurations"
Write-Host "• Naming conventions"

Write-Host "`nNext Steps:"
Write-Host "1. Monitor compliance status"
Write-Host "2. Review policy effects"
Write-Host "3. Adjust parameters if needed"
Write-Host "4. Create exemptions if required"
