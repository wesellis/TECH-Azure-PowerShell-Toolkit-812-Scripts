<#
.SYNOPSIS
    Stop Azurev2Vm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Stop Azurev2Vm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Stops all Azure V2 (ARM) virtual machines by resource group.  
    
    
.DESCRIPTION
   Uses PowerShell workflow to stop all VMs in parallel. Includes a retry and wait cycle to display when VMs are stopped. PowerShell
   Workflow sessions require Azure authentication into each session so this script uses a splatting of parameters required for Connect-AzureRmAccount that
   can be passed to each session.  Recommend using the New-AzureServicePrincipal -ErrorAction Stop script to create the required service principal and associated ApplicationId
   and certificate thumbprint required to log into Azure with the -servicePrincipal flag


.EXAMPLE
   .\Stop-AzureV2vm.ps1 -ResourceGroupName 'CONTOSO' -CertificateThumbprint 'F3FB843E7D22594E16066F1A3A04CA29D5D6DA91' -ApplicationID 'd2d20159-4482-4987-9724-f367afb170e8' -TenantID '72f632bf-86f6-41af-77ab-2d7cd011db47' 

.EXAMPLE
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

.NOTES

    Original Author:  https://github.com/JeffBow
    
 ------------------------------------------------------------------------
               Copyright (C) 2016 Microsoft Corporation

 You have a royalty-free right to use, modify, reproduce and distribute
 this sample script (and/or any modified version) in any way
 you find useful, provided that you agree that Microsoft has no warranty,
 obligations or liability for any sample application or script files.
 ------------------------------------------------------------------------



[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,

    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WECertificateThumbprint,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEApplicationId,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETenantId,

    [Parameter(Mandatory=$false)]
    [string]$WEEnvironment= " AzureCloud"
     
)

$WEProgressPreference = 'SilentlyContinue'

import-module AzureRM 

if ((Get-Module -ErrorAction Stop AzureRM).Version -lt " 5.5.0" ) {
   Write-warning " Old version of Azure PowerShell module  $((Get-Module -ErrorAction Stop AzureRM).Version.ToString()) detected.  Minimum of 5.5.0 required. Run Update-Module AzureRM"
   BREAK
}

workflow Stop-Vms 
{ [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($WEVMS, $WEResourceGroupName, $loginParams, [switch]$WEForce)
     
	# Get all Azure VMs in the subscription that are not stopped and deallocated, and shut them down
    $login = Connect-AzureRmAccount @loginParams

    foreach -parallel ($vm in $WEVMs)
      {       
          $null = Connect-AzureRmAccount @loginParams
          
          $vmName = $vm.Name
          $count=0
          
          do
          {
            $status = ((Get-AzureRmVm -ResourceGroupName $resourceGroupName -Name $vmName -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
            Write-Output " $vmName current status is $status"
            if($status -ne 'VM deallocated')
            {
                if($count -gt 0)
                {
                    Write-Output " Failed to stop $WEVMName. Retrying in 60 seconds..."
                    sleep 60
                }

                if($force)
                {
                    $rtn = Stop-AzureRMVM -Name $WEVMName -ResourceGroupName $resourceGroupName -force -ea SilentlyContinue 
                }
                else 
                {
                    $rtn = Stop-AzureRMVM -Name $WEVMName -ResourceGroupName $resourceGroupName -ea SilentlyContinue 
                }
                    
                $count++
            }
                    
        }
        while($status -ne 'VM deallocated' -and $count -lt 5)
              
        if($status -eq 'VM deallocated')
        {
            Write-Output " $WEVMName stopped."
        }
        else
        {
            Write-Output " Shutdown for $WEVMName FAILED on attempt number $count of 5."
        }
           
      }
}  # end of workflow



$loginParams = @{
" CertificateThumbprint" = $WECertificateThumbprint
" ApplicationId" = $WEApplicationId
" TenantId" = $WETenantId
" ServicePrincipal" = $null
" EnvironmentName" = $WEEnvironment
}



try
{
    # Log into Azure
    Connect-AzureRmAccount @loginParams -ea Stop | out-null
}
catch 
{
    if (! $WECertificateThumbprint)
    {
        $WEErrorMessage = " Certificate $WECertificateThumbprint not found."
        throw $WEErrorMessage
    } 
    else
    {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }

    break     
}



$vms = Get-AzureRmVM -ResourceGroupName $WEResourceGroupName 

 #pre action confirmation
 write-output " Shutting down...$($vms.Name)"


 Stop-Vms -VMs $vms -ResourceGroupName $resourceGroupName -loginParams $loginParams -Force


 #post action confirmation

 do
 {
    cls
    Write-Information " Waiting for VMs in $resourceGroupName to stop..."
    $allStatus = @()  
    foreach ($vm in $WEVMs) 
    {
        $status = ((get-azurermvm -ResourceGroupName $resourceGroupName -Name $vm.Name -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
        " $($vm.Name) - $status"
       ;  $allStatus = $allStatus + $status
    }
    sleep 3
 }
 while($allStatus -ne 'VM deallocated')

 cls
 Write-Information " All VMs in $resourceGroupName are stopped..."
 foreach ($vm in $WEVMs)
 {       
  ;  $status = ((get-azurermvm -ResourceGroupName $resourceGroupName -Name $vm.Name -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
   " $($vm.Name) - $status"
 }






# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================