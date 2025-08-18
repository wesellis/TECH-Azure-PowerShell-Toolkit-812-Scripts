<#
.SYNOPSIS
    We Enhanced Restore Azurermvm

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


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
   Restores Azure v2 ARM virtual machines from a backup VHD location.
   Does not work with VMs configured with managed disks because they allow snapshots.
	
    Requires AzureRM module version 4.2.1 or later.
 
.DESCRIPTION
   Copies VHD files from a backup location - from using the associated script Backup-AzureRMvm.ps1.  Since VHDs have a lease on them 
   from being attached to a VM, the VM must first be deleted.  The VHD is copied over the original location and then the VM
   is recreated using the same configuration.

   VMs must be shutdown prior to running this script. It will halt if they are still running.



.EXAMPLE
   .\Restore-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO'

.EXAMPLE
   .\Restore-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO' -BackupContainer 'vhd-backups-9021' -VhdContainer 'MyVMs'



.PARAMETER -ResourceGroupName [string]
  Name of resource group being copied

.PARAMETER -BackupContainer [string]
  Name of container that holds the backup VHD blobs

.PARAMETER -VhdContainer [string]
  Name of container that will hold VHD blobs attached to VMs

.PARAMETER -Environment [string]
  Name of Environment e.g. AzureUSGovernment.  Defaults to AzureCloud


.NOTES

    Original Author:   https://github.com/JeffBow
    
 ------------------------------------------------------------------------
               Copyright (C) 2016 Microsoft Corporation

 You have a royalty-free right to use, modify, reproduce and distribute
 this sample script (and/or any modified version) in any way
 you find useful, provided that you agree that Microsoft has no warranty,
 obligations or liability for any sample application or script files.
 ------------------------------------------------------------------------


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,

    [Parameter(Mandatory=$false)]
    [string]$WEBackupContainer= 'vhd-backups',

    [Parameter(Mandatory=$false)]
    [string]$WEVhdContainer= 'vhds',

    [Parameter(Mandatory=$false)]
    [string]$WEEnvironment= " AzureCloud"

)
$WEProgressPreference = 'SilentlyContinue'
$resourceGroupVMjsonPath = " $env:TEMP\$WEResourceGroupName.resourceGroupVMs.json"

import-module AzureRM 

if ((Get-Module AzureRM).Version -lt " 4.2.1") {
   Write-warning " Old version of Azure PowerShell module  $((Get-Module AzureRM).Version.ToString()) detected.  Minimum of 4.2.1 required. Run Update-Module AzureRM"
   BREAK
}


<###############################
 Get Storage Context function

function WE-Get-StorageObject 
{ [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($resourceGroupName, $srcURI) 
    
    $split = $srcURI.Split('/')
    $strgDNS = $split[2]
    $splitDNS = $strgDNS.Split('.')
    $storageAccountName = $splitDNS[0]
    $WEStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $WEStorageAccountName).Value[0]
    $WEStorageContext = New-AzureStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey $WEStorageAccountKey
  
    
    return $WEStorageContext

} # end of Get-StorageObject function



<###############################
  Copy blob function

function copy-azureBlob 
{  [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($srcUri, $srcContext, $destContext, $containerName)


    $split = $srcURI.Split('/')
    $blobName = $split[($split.count -1)]
    $blobSplit = $blobName.Split('.')
   ;  $extension = $blobSplit[($blobSplit.count -1)]
    if($($extension.tolower()) -eq 'status' ){Write-Output " Status file blob $blobname skipped";return}

    if(! $containerName){$containerName = $split[3]}

    # add full path back to blobname 
    if($split.count -gt 5) 
      { 
        $i = 4
        do
        {
            $path = $path + " /" + $split[$i]
            $i++
        }
        while($i -lt $split.length -1)

        $blobName= $path + '/' + $blobName
        $blobName = $blobName.Trim()
        $blobName = $blobName.Substring(1, $blobName.Length-1)
      }
    
    
   # create container if doesn't exist    
    if (!(Get-AzureStorageContainer -Context $destContext -Name $containerName -ea SilentlyContinue)) 
    { 
         try
         {
           ;  $newRtn = New-AzureStorageContainer -Context $destContext -Name $containerName -Permission Off -ea Stop 
            Write-Output " Container $($newRtn.name) was created." 
         }
         catch
         {
             $_ ; break
         }
    } 


   try 
   {
        $blobCopy = Start-AzureStorageBlobCopy `
            -srcUri $srcUri `
            -SrcContext $srcContext `
            -DestContainer $containerName `
            -DestBlob $blobName `
            -DestContext $destContext `
            -Force -ea Stop
         write-output " $srcUri is being copied to $containerName"
    
   }
   catch
   { 
      $_ ; write-warning " Failed to copy to $srcUri to $containerName"
   }
  

} # end of copy-azureBlob function




write-host " Enter credentials for your Azure Subscription..." -F Yellow
$login= Connect-AzureRmAccount -EnvironmentName $WEEnvironment
$loginID = $login.context.account.id
$sub = Get-AzureRmSubscription
$WESubscriptionId = $sub.Id


if($sub.count -gt 1) {
    $WESubscriptionId = (Get-AzureRmSubscription | select * | Out-GridView -title " Select Target Subscription" -OutputMode Single).Id
    Select-AzureRmSubscription -SubscriptionId $WESubscriptionId| Out-Null
    $sub = Get-AzureRmSubscription -SubscriptionId $WESubscriptionId
    $WESubscriptionId = $sub.Id
}

   


if(! $WESubscriptionId) 
{
   write-warning " The provided credentials failed to authenticate or are not associcated to a valid subscription. Exiting the script."
   break
}

write-verbose " Logged into $($sub.Name) with subscriptionID $WESubscriptionId as $loginID" -verbose


if(-not ($sourceResourceGroup = Get-AzureRmResourceGroup  -ResourceGroupName $resourceGroupName)) 
{
   write-warning " The provided resource group $resourceGroupName could not be found. Exiting the script."
   break
}



[string] $location = $sourceResourceGroup.location; 
$resourceGroupVMs = Get-AzureRMVM -ResourceGroupName $resourceGroupName


if(! $resourceGroupVMs){write-warning " No virtual machines found in resource group $resourceGroupName"; break}

$resourceGroupVMs | %{
   $status = ((get-azurermvm -ResourceGroupName $resourceGroupName -Name $_.name -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
   write-output " $($_.name) status is $status" 
   if($status -eq 'VM running'){write-warning " All virtual machines in this resource group are not stopped.  Please stop all VMs and try again"; break}
}


$resourceGroupVMs | ConvertTo-Json -depth 10 | Out-File $resourceGroupVMjsonPath


foreach($srcVM in $resourceGroupVMs)
{

    # get source VM attributes
    $WEVMName = $srcVM.Name
    $WEVMSize = $srcVM.HardwareProfile.VMSize
    $WEOSDiskName = $srcVM.StorageProfile.OsDisk.Name
    $WEOSType = $srcVM.storageprofile.osdisk.OsType
    $WEOSDiskCaching = $srcVM.StorageProfile.OsDisk.Caching
    $avSetRef = ($srcVM.AvailabilitySetReference.id).Split('/')
    $avSetName = $avSetRef[($avSetRef.count -1)]
    $WEAvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $WEResourceGroupName -Name $avSetName
    $WECreateOption = " Attach"

    # remove VM
    write-verbose " Restoring Virtual Machine $vmName" -verbose

    try
    { 
      Remove-AzureRmVM -Name $vmName -ResourceGroupName $resourceGroupName -Force -ea Stop | out-null
      write-output " Removed $vmName"
    }
    catch
    {
      $_
      Write-Warning " Failed to remove Virtual Machine $vmName" 
      break
    }


    # over-write existing disk from backup location

    # get storage account context from $srcVM.storageprofile.osdisk.vhd.uri
    $WEOSDiskUri = $null
    $WEOSDiskUri = $srcVM.storageprofile.osdisk.vhd.uri
    $WEOSsplit = $WEOSDiskUri.Split('/')
    $WEOSblobName = $WEOSsplit[($WEOSsplit.count -1)]
    $WEOScontainerName = $WEOSsplit[3]
    $WEOSstorageContext = Get-StorageObject -resourceGroupName $resourceGroupName -srcURI $WEOSDiskUri
    $backupURI = $WEOSDiskUri.Replace($vhdContainer, $backupContainer)
    
    copy-azureBlob -srcUri $backupURI -srcContext $WEOSstorageContext -destContext $WEOSstorageContext -containerName $vhdContainer
    
    # check on copy status
    do{
       $rtn = $null
       $rtn = Get-AzureStorageBlob -Context $WEOSstorageContext -container $WEOScontainerName -Blob $WEOSblobName | Get-AzureStorageBlobCopyState
       $rtn | select Source, Status, BytesCopied, TotalBytes | fl
       if($rtn.status  -ne 'Success'){
         write-verbose " Waiting for blob copy $WEOSblobName to complete" -verbose
         Sleep 10
       }  
    }
    while($rtn.status  -ne 'Success')

    # exit script if user breaks out of above loop   
    if($rtn.status  -ne 'Success'){EXIT} 



    # get the Network Interface Card we created previously based on the original source name
    $WENICRef = ($srcVM.NetworkInterfaceIDs).Split('/')
    $WENICName = $WENICRef[($WENICRef.count -1)]
    $WENIC = Get-AzureRmNetworkInterface -Name $WENICName -ResourceGroupName $WEResourceGroupName 

    
    

    # create VM Config
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

    # copy and readd data disk if they were present
    if($srcVM.storageProfile.datadisks)
    {
        foreach($disk in $srcVM.storageProfile.DataDisks) 
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
            $backupDiskURI = $dataDiskUri.Replace($vhdContainer, $backupContainer)
         
            copy-azureBlob -srcUri $backupDiskURI -srcContext $diskStorageContext -destContext $diskStorageContext -containerName $vhdContainer
       
            # check copy status
            do
            { 
              $drtn = $null
             ;  $drtn = Get-AzureStorageBlob -Context $diskStorageContext -container $diskContainerName -Blob $diskBlobName | Get-AzureStorageBlobCopyState
              $drtn| select Source, Status, BytesCopied, TotalBytes|fl
              if($rtn.status  -ne 'Success')
              {
               write-verbose " Waiting for blob copy $diskBlobName to complete" -verbose
               Sleep 10
              }
            }
            while($drtn.status  -ne 'Success')
            
            # exit script if user breaks out of above loop   
            if($rtn.status  -ne 'Success'){EXIT}
                
            Add-AzureRmVMDataDisk -VM $WEVirtualMachine -Name $dataDiskName -DiskSizeInGB $WEDiskSizeGB -Lun $dataDiskLUN -VhdUri $dataDiskUri -Caching $diskCaching -CreateOption $WECreateOption | out-null
        }
    }
     
    # create the VM from the config
    try
    {
        
        write-verbose " Recreating Virtual Machine $WEVMName in resource group $resourceGroupName at location $location" -verbose
       # $WEVirtualMachine
        New-AzureRmVM -ResourceGroupName $WEResourceGroupName -Location $location -VM $WEVirtualMachine -ea Stop -wa SilentlyContinue | out-null
        write-output " Successfully recreated Virtual Machine $WEVMName"
    }
    catch
    {
         $_
         write-warning " Failed to create Virtual Machine $WEVMName"
    }
}





        



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================