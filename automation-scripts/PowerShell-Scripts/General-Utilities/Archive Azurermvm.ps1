#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Archive Azurermvm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Archive Azurermvm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Archives or Rehydrates Azure V2 (ARM) Virtual Machines from specified resource group to save VM core allotment  
    Requires AzureRM module version 4.2.1 or later
    
.DESCRIPTION
   Removes VMs from a subscription leaving the VHDs, NICs and other assets along with a JSON configuration file that can 
   be used later to recreate the environment using the -Rehydrate switch

.EXAMPLE
   .\Archive-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO'

Archives all VMs in the CONTOSO resource group.

.EXAMPLE
   .\Archive-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO' -Rehydrate 

Rehydrates the VMs using the saved configuration and remaining resource group components (VNet, NIC, NSG, AvSet etc...


.PARAMETER -ResourceGroupName [string]
  Name of resource group being copied

.PARAMETER -Rehydrate[switch]
  Rebuilds VMs from configuration file

.PARAMETER -OptionalEnvironment [string]
  Name of the Environment. e.g. AzureUSGovernment, AzureGermanCloud or AzureChinaCloud. Defaults to AzureCloud.


.NOTES

  The script attempts to restore VM extensions but some extensions may need to be reinstalled manually. 

    Original Author:   https://github.com/JeffBow
    
 ------------------------------------------------------------------------
               Copyright (C) 2017 Microsoft Corporation

 You have a royalty-free right to use, modify, reproduce and distribute
 this sample script (and/or any modified version) in any way
 you find useful, provided that you agree that Microsoft has no warranty,
 obligations or liability for any sample application or script files.
 ------------------------------------------------------------------------


[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(mandatory=$WETrue,
      HelpMessage=" Enter the name of the Azure Resource Group you want to target and Press <Enter> e.g. CONTOSO" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,

    [Parameter(mandatory=$WEFalse,
      HelpMessage=" Use this switch to rebuild the script after waiting for the blob copy to complete" )]
    [switch]$WERehydrate,

    [Parameter(mandatory=$WETrue,
      HelpMessage=" Press <Enter> to default to AzureCloud or enter the Azure Environment name of the subscription. e.g. AzureUSGovernment" )]
    [AllowEmptyString()]
    [string]$WEOptionalEnvironment

)  

#region Functions

$WEProgressPreference = 'SilentlyContinue'

import-module AzureRM 

if ((Get-Module -ErrorAction Stop AzureRM).Version -lt " 4.2.1" ) {
   Write-warning " Old version of Azure PowerShell module  $((Get-Module -ErrorAction Stop AzureRM).Version.ToString()) detected.  Minimum of 4.2.1 required. Run Update-Module AzureRM"
   BREAK
}


<###############################
 Get Storage Context function

[CmdletBinding()]
function WE-Get-StorageObject -ErrorAction Stop 
{ [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($resourceGroupName, $srcURI) 
    
    $split = $srcURI.Split('/')
    $strgDNS = $split[2]
    $splitDNS = $strgDNS.Split('.')
    $storageAccountName = $splitDNS[0]
    $WEStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $WEStorageAccountName).Value[0]
    $WEStorageContext = New-AzureStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey $WEStorageAccountKey
    
    return $WEStorageContext

} # end of Get-StorageObject -ErrorAction Stop function



<###############################
 New-VM -ErrorAction Stop function
 param $vmobj takes Microsoft.Azure.Commands.Compute.Models.PSVirtualMachineList object 
 or custom PS object that was hydrated from a JSON export of the VM configuration

[CmdletBinding()]
function WE-New-VM -ErrorAction Stop
{ [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($vmObj) 

    $created = $false

    # get source VM attributes
    $WEVMName = $vmObj.Name
    $location = $vmObj.location
    $WEVMSize = $vmObj.HardwareProfile.VMSize
    $WEOSDiskName = $vmObj.StorageProfile.OsDisk.Name
    $WEOSType = $vmObj.storageprofile.osdisk.OsType
    $WEOSDiskCaching = $vmObj.StorageProfile.OsDisk.Caching
    $WECreateOption = " Attach"


    if($vmObj.AvailabilitySetReference)
    {
        $avSetRef = ($vmObj.AvailabilitySetReference.id).Split('/')
        $avSetName = $avSetRef[($avSetRef.count -1)]
        $WEAvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $WEResourceGroupName -Name $avSetName
    }

    # get storage account context from $vmObj.storageprofile.osdisk.vhd.uri
    $WEOSDiskUri = $null
    $WEOSDiskUri = $vmObj.storageprofile.osdisk.vhd.uri
    $WEOSsplit = $WEOSDiskUri.Split('/')
    $WEOSblobName = $WEOSsplit[($WEOSsplit.count -1)]
    $WEOScontainerName = $WEOSsplit[3]
    $WEOSstorageContext = Get-StorageObject -resourceGroupName $resourceGroupName -srcURI $WEOSDiskUri

    # get the Network Interface Card we created previously based on the original source name
    $WENICRef = ($vmObj.NetworkInterfaceIDs).Split('/')
    $WENICName = $WENICRef[($WENICRef.count -1)]
    $WENIC = Get-AzureRmNetworkInterface -Name $WENICName -ResourceGroupName $WEResourceGroupName 

    #create VM config
    if($WEAvailabilitySet)
    {
        $WEVirtualMachine = New-AzureRmVMConfig -VMName $WEVMName -VMSize $WEVMSize  -AvailabilitySetID $WEAvailabilitySet.Id  -wa SilentlyContinue
    }
    else
    {
        $WEVirtualMachine = New-AzureRmVMConfig -VMName $WEVMName -VMSize $WEVMSize -wa SilentlyContinue
    }
    
    # Set OS Disk based on OS type
    if($WEOStype -eq 'Windows' -or $WEOStype -eq '0'){
        $WEVirtualMachine = Set-AzureRmVMOSDisk -VM $WEVirtualMachine -Name $WEOSDiskName -VhdUri $WEOSDiskUri -Caching $WEOSDiskCaching -CreateOption $createOption -Windows
    }
    else
    {
        $WEVirtualMachine = Set-AzureRmVMOSDisk -VM $WEVirtualMachine -Name $WEOSDiskName -VhdUri $WEOSDiskUri -Caching $WEOSDiskCaching -CreateOption $createOption -Linux
    }

    # add NIC
    $WEVirtualMachine = Add-AzureRmVMNetworkInterface -VM $WEVirtualMachine -Id $WENIC.Id

    # readd data disk if they were present
    if($vmObj.storageProfile.datadisks)
    {
        foreach($disk in $vmObj.storageProfile.DataDisks) 
        {
            $dataDiskName = $null
            $dataDiskUri = $null
            $diskBlobName = $null
            $dataDiskName = $disk.Name
            $dataDiskLUN = $disk.Lun
            $diskCaching = $disk.Caching
            $WEDiskSizeGB = $disk.DiskSizeGB
            $dataDiskUri = $disk.vhd.uri
            $split = $dataDiskUri.Split('/')
            $diskBlobName = $split[($split.count -1)]
            $diskContainerName = $split[3]
            
            $diskStorageContext = Get-StorageObject -resourceGroupName $resourceGroupName -srcURI $dataDiskUri
                
            Add-AzureRmVMDataDisk -VM $WEVirtualMachine -Name $dataDiskName -DiskSizeInGB $WEDiskSizeGB -Lun $dataDiskLUN -VhdUri $dataDiskUri -Caching $diskCaching -CreateOption $WECreateOption | out-null
        }
    }
    
    # create the VM from the config
    try
    {
        
        write-verbose " Rehydrating Virtual Machine $WEVMName in resource group $resourceGroupName at location $location" -verbose
        New-AzureRmVM -ResourceGroupName $WEResourceGroupName -Location $location -VM $WEVirtualMachine -ea Stop -wa SilentlyContinue | out-null
        $created = $true
        Write-Information " Successfully rehydrated Virtual Machine $WEVMName" 
    }
    catch
    {
        $_
        write-warning " Failed to create Virtual Machine $WEVMName"
        $created = $false
    }
    
    if($created)
    {
        try 
        {
            $newVM = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $WEVMName

            if($vmObj.DiagnosticsProfile.BootDiagnostics.Enabled -eq 'True')
            {   
                write-verbose " Adding Boot Diagnostics to virtual machine $WEVMName" -Verbose
                $storageURI = $vmObj.DiagnosticsProfile.BootDiagnostics.StorageUri
                $WEStgSplit = $storageUri.Split('/')
                $WEDiagStorageAccountName = $WEStgSplit[2].Split('.')[0]
                $newVM | Set-AzureRmVMBootDiagnostics -Enable -ResourceGroupName $WEResourceGroupName -StorageAccountName $WEDiagStorageAccountName | Out-Null
            }
            else
            { 
                write-verbose " Disabling Boot Diagnostics on virtual machine $WEVMName" -Verbose
                $newVM | Set-AzureRmVMBootDiagnostics -Disable | Out-Null
            }

            $newVM | Update-AzureRMVm -ResourceGroupName $resourceGroupName | Out-Null
        }
        catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}

    }
    
    return $created


} # end of New-VM -ErrorAction Stop function




if($WEOptionalEnvironment -and (Get-AzureRMEnvironment -Name $WEOptionalEnvironment) -eq $null)
{
   write-warning " The specified -OptionalSourceEnvironment could not be found. Select one of these valid environments."
   $WEOptionalEnvironment = (Get-AzureRMEnvironment -ErrorAction Stop | Select-Object Name, ManagementPortalUrl | Out-GridView -title " Select a valid Azure environment for your source subscription" -OutputMode Single).Name
}


Write-Information " Enter credentials for the Azure Subscription..." -f Yellow
if($WEOptionalEnvironment)
{
   $login= Connect-AzureRmAccount -EnvironmentName $WEOptionalEnvironment
}
else
{
   $login= Connect-AzureRmAccount
}

$loginID = $login.context.account.id
$sub = Get-AzureRmSubscription -ErrorAction Stop
$WESubscriptionId = $sub.Id


if($sub.count -gt 1) 
{
    $WESubscriptionId = (Get-AzureRmSubscription -ErrorAction Stop | Select-Object * | Out-GridView -title " Select Target Subscription" -OutputMode Single).Id
    Select-AzureRmSubscription -SubscriptionId $WESubscriptionId | Out-Null
    $sub = Get-AzureRmSubscription -SubscriptionId $WESubscriptionId
}

   


if(! $WESubscriptionId) 
{
   write-warning " The provided credentials failed to authenticate or are not associcated to a valid subscription. Exiting the script."
   break
}

$WESubscriptionName = $sub.Name

Write-Information " Logged into $WESubscriptionName with subscriptionID $WESubscriptionId as $loginID" -f Green


if(-not ($sourceResourceGroup = Get-AzureRmResourceGroup -ErrorAction Stop  -ResourceGroupName $resourceGroupName)) 
{
   write-warning " The provided resource group $resourceGroupName could not be found. Exiting the script."
   break
}

if(-not ($sourceResourceGroup = Get-AzureRmResourceGroup -ErrorAction Stop  -ResourceGroupName $resourceGroupName)) 
{
   write-warning " The provided resource group $resourceGroupName could not be found. Exiting the script."
   break
}

if($WERehydrate)
{
   # search all storage accounts and containers for rehydrate files
    foreach($WEStorageAccount in (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName))
    { 
        $WEStorageAccountName = $WEStorageAccount.StorageAccountName
        write-verbose " Searching for rehydrate files in storage account $WEStorageAccountName)..." -verbose        
        $WEStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $WEStorageAccountName).Value[0]
        $WEStorageContext = New-AzureStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey $WEStorageAccountKey

        foreach($WEStorageContainer in (Get-AzureStorageContainer -Context $WEStorageContext) )
        { 
            $WEStorageContainerName = $WEStorageContainer.Name
            write-verbose " Searching for rehydrate files in container $WEStorageContainerName)..." -verbose
            $rehydrateBlobs = Get-AzureStorageBlob -Container $WEStorageContainerName -Context $WEStorageContext | Where-Object{$_.name -like " *.rehydrate.json" }
            foreach($rehydrateBlob in $rehydrateBlobs)
            {
                write-verbose " Retreiving rehydrate file $($rehydrateBlob.name)..." -verbose
                try 
                {
                    $WETempRehydratefile = Get-AzureStorageBlobContent -CloudBlob $WERehydrateBlob.iCloudBlob -Context $WEStorageContext -Destination $env:temp -Force -ea Stop
                    $WETempRehydratefileName = $WETempRehydratefile.Name
                    $fileContent = get-content -ErrorAction Stop " $env:temp\$WETempRehydratefileName" -ea Stop
                    $fileContent | Where-Object{$_ -ne ''} | out-file " $env:temp\$WETempRehydratefileName"
                    $rehydrateVM = (get-content -ErrorAction Stop " $env:temp\$WETempRehydratefileName" -ea Stop) -Join " `n" | ConvertFrom-Json -ea Stop
                }
                catch
                {
                    write-warning " Virtual machine object data could not be restored from rehydrate file $($rehydrateBlob.Name) "
                }
               

                if($rehydrateVM)
                {
                    $created = New-VM -vmObj $rehydrateVM

                    if($created)
                    {
      
                        try
                        {
                            write-verbose " Searching for Diagnostics config file in container $WEStorageContainerName..." -verbose
                            $rehydrateDiagBlob = Get-AzureStorageBlob -Container $WEStorageContainerName -Context $WEStorageContext -ea Stop | Where-Object{$_.name -like " *$($rehydrateVM.Name).rehydratediag.xml" }  
                            if($rehydrateDiagBlob)
                            {
                                write-verbose " Retreiving Diagnostics config file $($rehydrateDiagBlob.name)..." -verbose
                                $WETempDiagRehydratefile = Get-AzureStorageBlobContent -CloudBlob $WERehydrateDiagBlob.iCloudBlob -Context $WEStorageContext -Destination $env:temp -Force -ea Stop
                                $WETempDiagRehydratefileName = $WETempDiagRehydratefile.Name
                                $WEDiagfileContent = get-content -ErrorAction Stop " $env:temp\$WETempDiagRehydratefileName" -ea Stop
                                $WEDiagfileContent | Where-Object{$_ -ne ''} | out-file " $env:temp\$WETempDiagRehydratefileName"
                                $rehydrateVMDiag = (get-content -ErrorAction Stop " $env:temp\$WETempDiagRehydratefileName" -ea Stop) -Join " `n" | ConvertFrom-Json
                                $wadCfg = $rehydrateVMDiag.wadCfg
                                $wadStorageAccount = $rehydrateVMDiag.StorageAccount
                                $wadStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $wadStorageAccount -ea Stop).Value[0]
                                write-verbose " Applying VM Diagnostic settings to virtual machine $($rehydrateVM.Name)..." -verbose
                                Set-AzureRmVMDiagnosticsExtension -ResourceGroupName $WEResourceGroupName -VMName $($rehydrateVM.Name) -DiagnosticsConfigurationPath " $env:temp\$WETempDiagRehydratefileName" -StorageAccountName $wadStorageAccount -StorageAccountKey $wadStorageAccountKey | out-null
                            }
                            else 
                            {
                                write-verbose " No Diagnostics config file found for $($rehydrateVM.Name)..." -verbose
                            }
                        }
                        catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
                    }
                }
 
           }
        }

    }
} # end of if rehydrate
else 
{
    
    # get configuration details for all VMs
    [string];  $location = $sourceResourceGroup.location
   ;  $resourceGroupVMs = Get-AzureRMVM -ResourceGroupName $resourceGroupName


    if(! $resourceGroupVMs){write-warning " No virtual machines found in resource group $resourceGroupName" ; break}

    $resourceGroupVMs | %{
    $status = ((get-azurermvm -ResourceGroupName $resourceGroupName -Name $_.name -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
    write-output " $($_.name) status is $status" 
    if($status -eq 'VM running')
        {write-warning " All virtual machines in this resource group are not stopped.  Please stop all VMs and try again" ; break}
    }

    
     
    # remove each VM - leaving VHD for archive and possible rehydration
    foreach($srcVM in $resourceGroupVMs)
    {
        # get source VM OS disk attributes to determine storage account and container to copy config file
        $vmName = $srcVM.Name
        $WEOSDiskUri = $null
        $WEOSDiskUri = $srcVM.storageprofile.osdisk.vhd.uri
        $WEOSsplit = $WEOSDiskUri.Split('/')
        $WEOScontainerName = $WEOSsplit[3]
        $WEStorageContext = Get-StorageObject -resourceGroupName $resourceGroupName -srcURI $WEOSDiskUri

        $diagSettings = (Get-AzureRmVMDiagnosticsExtension -ResourceGroupName $WEResourceGroupName -VMName $vmName).PublicSettings
        if($diagSettings)
        {
            $WERehydrateDiagFile = (" $WEResourceGroupName.$vmName.rehydrateDiag.xml" ).ToLower()
            $tempDiagFilePath = " $env:TEMP\$WERehydrateDiagFile"
            $diagSettings | Out-File -FilePath $tempDiagFilePath -Force
            # expand file size to 20KB for Page blob write if we experience Premium_LRS storage
            $file = [System.IO.File]::OpenWrite($tempDiagFilePath)
            $file.SetLength(40960)
            $file.Close()

            # copy to cloud container as Page blog  
            $copyDiagResult = Set-AzureStorageBlobContent -File $tempDiagFilePath -Blob $WERehydrateDiagFile -Context $WEStorageContext -Container $WEOScontainerName -BlobType Page -Force 
        }

        #save off VM config to temp drive before copying it back to cloud storage
        $WERehydrateFile = (" $WEResourceGroupName.$vmName.rehydrate.json" ).ToLower()
        $tempFilePath = " $env:TEMP\$WERehydrateFile"
        $srcVM | ConvertTo-Json -depth 10 | Out-File -FilePath $tempFilePath -Force

        # expand file size to 20KB for Page blob write if we experience Premium_LRS storage
       ;  $file = [System.IO.File]::OpenWrite($tempFilePath)
        $file.SetLength(20480)
        $file.Close()
        
        # copy to cloud container as Page blog  
       ;  $copyResult = Set-AzureStorageBlobContent -File $tempFilePath -Blob $WERehydrateFile -Context $WEStorageContext -Container $WEOScontainerName -BlobType Page -Force 
        
        if($copyResult)
        {
            # remove VM
            write-verbose " Archiving Virtual Machine $vmName..." -verbose
            try
            { 
                Remove-AzureRmVM -Name $vmName -ResourceGroupName $resourceGroupName -Force -ea Stop | out-null
                write-output " Archived $vmName"
            }
            catch
            {
                $_
                Write-Warning " Failed to remove Virtual Machine $vmName" 
            }
        }

     }
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
