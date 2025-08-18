<#
.SYNOPSIS
    We Enhanced Sample

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

cls
$WERGName = "RG-VS-Dev" ;
$WEVMName = "jdvs2015vm" ;
$WEVMUsername = "jmd" ;
$WEDeployLocation = "West Europe"; 
$WEChocoPackages = " linqpad;sysinternals;agentransack;beyondcompare;fiddler4;visualstudiocode;imageresizerapp;gimp";
$WEARMTemplate = " C:\@SourceControl\GitHub\ARMChocolatey\azuredeploy.json"




New-AzureRmResourceGroup -Name $WERGName -Location $WEDeployLocation -Force

; 
$sw = [system.diagnostics.stopwatch]::startNew()
New-AzureRmResourceGroupDeployment -ResourceGroupName $WERGName -TemplateFile $WEARMTemplate -deployLocation $WEDeployLocation -vmName $WEVMName -vmAdminUserName $WEVMUsername -vmIPPublicDnsName $WEVMName -chocoPackages $WEChocoPackages -Mode Complete -Force 
$sw | Format-List -Property *


Get-AzureRmRemoteDesktopFile -ResourceGroupName $WERGName -Name $WEVMName -Launch -Verbose -Debug



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================