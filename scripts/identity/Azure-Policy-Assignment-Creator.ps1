#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$PolicyDefinitionId,
    [Parameter(Mandatory)]
    [string]$AssignmentName,
    [Parameter(Mandatory)]
    [string]$Scope,
    [Parameter()]
    [string]$Description,
    [Parameter()]
    [hashtable]$Parameters = @{},
    [Parameter()]
    [string]$EnforcementMode = "Default"
)
Write-Output "Creating Policy Assignment: $AssignmentName"
if ($Description) {
    $AssignmentParams.Description = $Description
}
if ($Parameters.Count -gt 0) {
    $AssignmentParams.PolicyParameterObject = $Parameters
}
$Assignment = New-AzPolicyAssignment -ErrorAction Stop @AssignmentParams
Write-Output "Policy Assignment created successfully:"
Write-Output "Name: $($Assignment.Name)"
Write-Output "Policy: $($Assignment.Properties.PolicyDefinitionId.Split('/')[-1])"
Write-Output "Scope: $Scope"
Write-Output "Enforcement Mode: $($Assignment.Properties.EnforcementMode)"
if ($Description) {
    Write-Output "Description: $Description"
}
if ($Parameters.Count -gt 0) {
    Write-Output "`nPolicy Parameters:"
    foreach ($Param in $Parameters.GetEnumerator()) {
        Write-Output "  $($Param.Key): $($Param.Value)"
    }
}
Write-Output "`nPolicy Assignment Benefits:"
Write-Output "Automated compliance enforcement"
Write-Output "Consistent governance across resources"
Write-Output "Audit and reporting capabilities"
Write-Output "Cost and security optimization"
Write-Output "`nCommon Policy Types:"
Write-Output "Resource tagging requirements"
Write-Output "Location restrictions"
Write-Output "SKU limitations"
Write-Output "Security configurations"
Write-Output "Naming conventions"
Write-Output "`nNext Steps:"
Write-Output "1. Monitor compliance status"
Write-Output "2. Review policy effects"
Write-Output "3. Adjust parameters if needed"
Write-Output "4. Create exemptions if required"



