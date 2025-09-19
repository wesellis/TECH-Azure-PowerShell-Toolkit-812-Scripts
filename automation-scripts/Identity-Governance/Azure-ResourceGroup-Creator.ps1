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
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Tags = @{}
)

#region Functions

Write-Information "Creating Resource Group: $ResourceGroupName"

if ($Tags.Count -gt 0) {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
    Write-Information "Tags applied:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Information "  $($Tag.Key): $($Tag.Value)"
    }
} else {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}

Write-Information " Resource Group created successfully:"
Write-Information "  Name: $($ResourceGroup.ResourceGroupName)"
Write-Information "  Location: $($ResourceGroup.Location)"
Write-Information "  Provisioning State: $($ResourceGroup.ProvisioningState)"
Write-Information "  Resource ID: $($ResourceGroup.ResourceId)"


#endregion
