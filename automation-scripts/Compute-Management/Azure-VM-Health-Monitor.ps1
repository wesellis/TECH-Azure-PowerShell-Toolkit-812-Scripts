<#
.SYNOPSIS
    Check VM health

.DESCRIPTION
    Check VM health
#>
param (
    [string]$ResourceGroupName,
    [string]$VmName
)
# Get VM status and details
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Status
Write-Host "VM Name: $($VM.Name)"
Write-Host "Resource Group: $($VM.ResourceGroupName)"
Write-Host "Location: $($VM.Location)"
Write-Host "Power State: $($VM.PowerState)"
Write-Host "Provisioning State: $($VM.ProvisioningState)"
# Display status information
foreach ($Status in $VM.Statuses) {
    Write-Host "Status: $($Status.Code) - $($Status.DisplayStatus)"
}

