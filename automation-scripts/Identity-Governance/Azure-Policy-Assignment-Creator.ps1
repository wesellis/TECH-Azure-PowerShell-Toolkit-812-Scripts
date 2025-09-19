#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
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

#region Functions

Write-Information "Creating Policy Assignment: $AssignmentName"

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
$Assignment = New-AzPolicyAssignment -ErrorAction Stop @AssignmentParams

Write-Information " Policy Assignment created successfully:"
Write-Information "  Name: $($Assignment.Name)"
Write-Information "  Policy: $($Assignment.Properties.PolicyDefinitionId.Split('/')[-1])"
Write-Information "  Scope: $Scope"
Write-Information "  Enforcement Mode: $($Assignment.Properties.EnforcementMode)"

if ($Description) {
    Write-Information "  Description: $Description"
}

if ($Parameters.Count -gt 0) {
    Write-Information "`nPolicy Parameters:"
    foreach ($Param in $Parameters.GetEnumerator()) {
        Write-Information "  $($Param.Key): $($Param.Value)"
    }
}

Write-Information "`nPolicy Assignment Benefits:"
Write-Information "• Automated compliance enforcement"
Write-Information "• Consistent governance across resources"
Write-Information "• Audit and reporting capabilities"
Write-Information "• Cost and security optimization"

Write-Information "`nCommon Policy Types:"
Write-Information "• Resource tagging requirements"
Write-Information "• Location restrictions"
Write-Information "• SKU limitations"
Write-Information "• Security configurations"
Write-Information "• Naming conventions"

Write-Information "`nNext Steps:"
Write-Information "1. Monitor compliance status"
Write-Information "2. Review policy effects"
Write-Information "3. Adjust parameters if needed"
Write-Information "4. Create exemptions if required"


#endregion
