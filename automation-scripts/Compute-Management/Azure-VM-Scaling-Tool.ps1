# ============================================================================
# Script Name: Azure Virtual Machine Scaling Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates scaling of Azure Virtual Machine sizes and configurations
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VmName,
    [string]$NewVmSize
)

# Get current VM
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

# Update VM size
$VM.HardwareProfile.VmSize = $NewVmSize

# Apply the changes
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM

Write-Host "VM $VmName has been scaled to size: $NewVmSize"
