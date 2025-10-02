#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Stop Azurev2Vm

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Stops all Azure V2 (ARM) virtual machines by resource group.
   Uses PowerShell workflow to stop all VMs in parallel. Includes a retry and wait cycle to display when VMs are stopped. PowerShell
   Workflow sessions require Azure authentication into each session so this script uses a splatting of parameters required for Connect-AzureRmAccount that
   can be passed to each session.  Recommend using the New-AzureServicePrincipal -ErrorAction Stop script to create the required service principal and associated ApplicationId
   and certificate thumbprint required to log into Azure with the -servicePrincipal flag
   .\Stop-AzureV2vm.ps1 -ResourceGroupName 'CONTOSO' -CertificateThumbprint 'F3FB843E7D22594E16066F1A3A04CA29D5D6DA91' -ApplicationID 'd2d20159-4482-4987-9724-f367afb170e8' -TenantID '72f632bf-86f6-41af-77ab-2d7cd011db47'
   .\Stop-AzureV2vm.ps1 -ResourceGroupName 'CONTOSO'-CertificateThumbprint 'F3FB843E7D22594E16066F1A3A04CA29D5D6DA91' -ApplicationID 'd2d20159-4482-4987-9724-f367afb170e8' -TenantID '72f632bf-86f6-41af-77ab-2d7cd011db47'
.PARAMETER -ResourceGroupName [string]
  Name of resource group being copied
.PARAMETER -CertificateThumbprint [string]
  Thumbprint of the x509 certificate that is used for authentication
.PARAMETER -ApplicationId [string]
  Aplication ID of the registered Azure Active Directory Service Principal
.PARAMETER -TenantId [string]
  Tenant ID of the registered Azure Active Directory Service Principal
.PARAMETER -Environment [string]
  Name of Environment e.g. AzureUSGovernment.  Defaults to AzureCloud
    Original Author:  https://github.com/JeffBow
 ------------------------------------------------------------------------
               Copyright (C) 2016 Microsoft Corporation
 You have a royalty-free right to use, modify, reproduce and distribute
 this sample script (and/or any modified version) in any way
 you find useful, provided that you agree that Microsoft has no warranty,
 obligations or liability for any sample application or script files.
 ------------------------------------------------------------------------
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $CertificateThumbprint,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ApplicationId,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $TenantId,
    [Parameter(ValueFromPipeline)]`n    $Environment= "AzureCloud"
)
    $ProgressPreference = 'SilentlyContinue'
if ((Get-Module -ErrorAction Stop AzureRM).Version -lt " 5.5.0" ) {
   Write-warning "Old version of Azure PowerShell module  $((Get-Module -ErrorAction Stop AzureRM).Version.ToString()) detected.  Minimum of 5.5.0 required. Run Update-Module AzureRM"
   BREAK
}
workflow Stop-Vms
{ param($VMS, $ResourceGroupName, $LoginParams, [switch]$Force)
    $login = Connect-AzureRmAccount @loginParams
    foreach -parallel ($vm in $VMs)
      {
    $null = Connect-AzureRmAccount @loginParams
    $VmName = $vm.Name
    $count=0
          do
          {
    $status = ((Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VmName -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
            Write-Output " $VmName current status is $status"
            if($status -ne 'VM deallocated')
            {
                if($count -gt 0)
                {
                    Write-Output "Failed to stop $VMName. Retrying in 60 seconds..."
                    sleep 60
                }
                if($force)
                {
    $rtn = Stop-AzureRMVM -Name $VMName -ResourceGroupName $ResourceGroupName -force -ea SilentlyContinue
                }
                else
                {
    $rtn = Stop-AzureRMVM -Name $VMName -ResourceGroupName $ResourceGroupName -ea SilentlyContinue
                }
    $count++
            }
        }
        while($status -ne 'VM deallocated' -and $count -lt 5)
        if($status -eq 'VM deallocated')
        {
            Write-Output " $VMName stopped."
        }
        else
        {
            Write-Output "Shutdown for $VMName FAILED on attempt number $count of 5."
        }
      }
}
    $LoginParams = @{
"CertificateThumbprint" = $CertificateThumbprint
"ApplicationId" = $ApplicationId
"TenantId" = $TenantId
"ServicePrincipal" = $null
"EnvironmentName" = $Environment
}
try
{
    Connect-AzureRmAccount @loginParams -ea Stop | out-null
}
catch
{
    if (! $CertificateThumbprint)
    {
    $ErrorMessage = "Certificate $CertificateThumbprint not found."
        throw $ErrorMessage
    }
    else
    {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
    break
}
    $vms = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
 write-output "Shutting down...$($vms.Name)"
 Stop-Vms -VMs $vms -ResourceGroupName $ResourceGroupName -loginParams $LoginParams -Force
 do
 {
    cls
    Write-Output "Waiting for VMs in $ResourceGroupName to stop..."
    $AllStatus = @()
    foreach ($vm in $VMs)
    {
    $status = ((get-azurermvm -ResourceGroupName $ResourceGroupName -Name $vm.Name -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
        " $($vm.Name) - $status"
    $AllStatus = $AllStatus + $status
    }
    sleep 3
 }
 while($AllStatus -ne 'VM deallocated')
 cls
 Write-Output "All VMs in $ResourceGroupName are stopped..."
 foreach ($vm in $VMs)
 {
    $status = ((get-azurermvm -ResourceGroupName $ResourceGroupName -Name $vm.Name -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
   " $($vm.Name) - $status"`n}
