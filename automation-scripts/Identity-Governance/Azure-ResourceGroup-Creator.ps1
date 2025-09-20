<#
.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [hashtable]$Tags = @{}
)
Write-Host "Creating Resource Group: $ResourceGroupName"
if ($Tags.Count -gt 0) {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
    Write-Host "Tags applied:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Host "  $($Tag.Key): $($Tag.Value)"
    }
} else {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}
Write-Host "Resource Group created successfully:"
Write-Host "Name: $($ResourceGroup.ResourceGroupName)"
Write-Host "Location: $($ResourceGroup.Location)"
Write-Host "Provisioning State: $($ResourceGroup.ProvisioningState)"
Write-Host "Resource ID: $($ResourceGroup.ResourceId)"

