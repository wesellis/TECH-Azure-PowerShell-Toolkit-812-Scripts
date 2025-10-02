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
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [hashtable]$Tags = @{}
)
Write-Output "Creating Resource Group: $ResourceGroupName"
if ($Tags.Count -gt 0) {
    $ResourcegroupSplat = @{
    Name = $ResourceGroupName
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
    Write-Output "Tags applied:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Output "  $($Tag.Key): $($Tag.Value)"
    }
} else {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}
Write-Output "Resource Group created successfully:"
Write-Output "Name: $($ResourceGroup.ResourceGroupName)"
Write-Output "Location: $($ResourceGroup.Location)"
Write-Output "Provisioning State: $($ResourceGroup.ProvisioningState)"
Write-Output "Resource ID: $($ResourceGroup.ResourceId)"



