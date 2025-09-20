<#
.SYNOPSIS
    Sample

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
cls
$RGName = "RG-VS-Dev" ;
$VMName = " jdvs2015vm" ;
$VMUsername = " jmd" ;
$DeployLocation = "West Europe";
$ChocoPackages = " linqpad;sysinternals;agentransack;beyondcompare;fiddler4;visualstudiocode;imageresizerapp;gimp" ;
$ARMTemplate = "C:\@SourceControl\GitHub\ARMChocolatey\azuredeploy.json"
New-AzureRmResourceGroup -Name $RGName -Location $DeployLocation -Force
$sw = [system.diagnostics.stopwatch]::startNew()
New-AzureRmResourceGroupDeployment -ResourceGroupName $RGName -TemplateFile $ARMTemplate -deployLocation $DeployLocation -vmName $VMName -vmAdminUserName $VMUsername -vmIPPublicDnsName $VMName -chocoPackages $ChocoPackages -Mode Complete -Force
$sw | Format-List -Property *
Get-AzureRmRemoteDesktopFile -ResourceGroupName $RGName -Name $VMName -Launch -Verbose -Debug\n