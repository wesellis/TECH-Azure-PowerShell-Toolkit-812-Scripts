#Requires -Version 7.0
#Requires -Module Az.Resources
<#
.SYNOPSIS
    Restore Azurermvm
.DESCRIPTION
    Restore Azurermvm operation
    Author: Wes Ellis (wes@wesellis.com)
#>
    Restore Azurermvm
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
   Restores Azure v2 ARM virtual machines from a backup VHD location.
   Does not work with VMs configured with managed disks because they allow snapshots.
    Requires AzureRM module version 4.2.1 or later.
   Copies VHD files from a backup location - from using the associated script Backup-AzureRMvm.ps1.  Since VHDs have a lease on them
   from being attached to a VM, the VM must first be deleted.  The VHD is copied over the original location and then the VM
   is recreated using the same configuration.
   VMs must be shutdown prior to running this script. It will halt if they are still running.
   .\Restore-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO'
   .\Restore-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO' -BackupContainer 'vhd-backups-9021' -VhdContainer 'MyVMs'
.PARAMETER -ResourceGroupName [string]
  Name of resource group being copied
.PARAMETER -BackupContainer [string]
  Name of container that holds the backup VHD blobs
.PARAMETER -VhdContainer [string]
  Name of container that will hold VHD blobs attached to VMs
.PARAMETER -Environment [string]
  Name of Environment e.g. AzureUSGovernment.  Defaults to AzureCloud
    Original Author:   https://github.com/JeffBow
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
    [string]$ResourceGroupName,
    [Parameter()]
    [string]$BackupContainer= 'vhd-backups',
    [Parameter()]
    [string]$VhdContainer= 'vhds',
    [Parameter()]
    [string]$Environment= "AzureCloud"
)
#region Functions
$ProgressPreference = 'SilentlyContinue'
$resourceGroupVMjsonPath = " $env:TEMP\$ResourceGroupName.resourceGroupVMs.json"
import-module AzureRM
if ((Get-Module -ErrorAction Stop AzureRM).Version -lt " 4.2.1" ) {
   Write-warning "Old version of Azure PowerShell module  $((Get-Module -ErrorAction Stop AzureRM).Version.ToString()) detected.  Minimum of 4.2.1 required. Run Update-Module AzureRM"
   BREAK
}
<###############################
 Get Storage Context function
function Get-StorageObject -ErrorAction Stop
{ [CmdletBinding()]
param($resourceGroupName, $srcURI)
    $split = $srcURI.Split('/')
    $strgDNS = $split[2]
    $splitDNS = $strgDNS.Split('.')
    $storageAccountName = $splitDNS[0]
    $StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $StorageAccountName).Value[0]
    $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    return $StorageContext
} # end of Get-StorageObject -ErrorAction Stop function
<###############################
  Copy blob function
function copy-azureBlob
{  [CmdletBinding()]
param($srcUri, $srcContext, $destContext, $containerName)
    $split = $srcURI.Split('/')
    $blobName = $split[($split.count -1)]
$blobSplit = $blobName.Split('.')
$extension = $blobSplit[($blobSplit.count -1)]
    if($($extension.tolower()) -eq 'status' ){Write-Output "Status file blob $blobname skipped" ;return}
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
$newRtn = New-AzureStorageContainer -Context $destContext -Name $containerName -Permission Off -ea Stop
            Write-Output "Container $($newRtn.name) was created."
         }
         catch
         {
             $_ ; break
         }
    }
   try
   {
        $params = @{
            DestBlob = $blobName
            srcUri = $srcUri
            DestContext = $destContext
            SrcContext = $srcContext
            DestContainer = $containerName
            ea = "Stop write-output " $srcUri is being copied to $containerName"  } catch { $_ ; write-warning "Failed to copy to $srcUri to $containerName" }"
        }
        $blobCopy @params
} # end of copy-azureBlob function
Write-Host "Enter credentials for your Azure Subscription..." -F Yellow
$login= Connect-AzureRmAccount -EnvironmentName $Environment
$loginID = $login.context.account.id
$sub = Get-AzureRmSubscription -ErrorAction Stop
$SubscriptionId = $sub.Id
if($sub.count -gt 1) {
    $SubscriptionId = (Get-AzureRmSubscription -ErrorAction Stop | select * | Out-GridView -title "Select Target Subscription" -OutputMode Single).Id
    Select-AzureRmSubscription -SubscriptionId $SubscriptionId| Out-Null
    $sub = Get-AzureRmSubscription -SubscriptionId $SubscriptionId
    $SubscriptionId = $sub.Id
}
if(! $SubscriptionId)
{
   write-warning "The provided credentials failed to authenticate or are not associcated to a valid subscription. Exiting the script."
   break
}
write-verbose "Logged into $($sub.Name) with subscriptionID $SubscriptionId as $loginID" -verbose
if(-not ($sourceResourceGroup = Get-AzureRmResourceGroup -ErrorAction Stop  -ResourceGroupName $resourceGroupName))
{
   write-warning "The provided resource group $resourceGroupName could not be found. Exiting the script."
   break
}
[string];  $location = $sourceResourceGroup.location;
$resourceGroupVMs = Get-AzureRMVM -ResourceGroupName $resourceGroupName
if(! $resourceGroupVMs){write-warning "No virtual machines found in resource group $resourceGroupName" ; break}
$resourceGroupVMs | %{
   $status = ((get-azurermvm -ResourceGroupName $resourceGroupName -Name $_.name -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
   write-output " $($_.name) status is $status"
   if($status -eq 'VM running'){write-warning "All virtual machines in this resource group are not stopped.  Please stop all VMs and try again" ; break}
}
$resourceGroupVMs | ConvertTo-Json -depth 10 | Out-File $resourceGroupVMjsonPath
foreach($srcVM in $resourceGroupVMs)
{
    # get source VM attributes
    $VMName = $srcVM.Name
    $VMSize = $srcVM.HardwareProfile.VMSize
    $OSDiskName = $srcVM.StorageProfile.OsDisk.Name
    $OSType = $srcVM.storageprofile.osdisk.OsType
    $OSDiskCaching = $srcVM.StorageProfile.OsDisk.Caching
    $avSetRef = ($srcVM.AvailabilitySetReference.id).Split('/')
    $avSetName = $avSetRef[($avSetRef.count -1)]
    $AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $avSetName
    $CreateOption = "Attach"
    # remove VM
    write-verbose "Restoring Virtual Machine $vmName" -verbose
    try
    {
      Remove-AzureRmVM -Name $vmName -ResourceGroupName $resourceGroupName -Force -ea Stop | out-null
      write-output "Removed $vmName"
    }
    catch
    {
      $_
      Write-Warning "Failed to remove Virtual Machine $vmName"
      break
    }
    # over-write existing disk from backup location
    # get storage account context from $srcVM.storageprofile.osdisk.vhd.uri
    $OSDiskUri = $null
    $OSDiskUri = $srcVM.storageprofile.osdisk.vhd.uri
    $OSsplit = $OSDiskUri.Split('/')
    $OSblobName = $OSsplit[($OSsplit.count -1)]
    $OScontainerName = $OSsplit[3]
    $OSstorageContext = Get-StorageObject -resourceGroupName $resourceGroupName -srcURI $OSDiskUri
    $backupURI = $OSDiskUri.Replace($vhdContainer, $backupContainer)
    copy-azureBlob -srcUri $backupURI -srcContext $OSstorageContext -destContext $OSstorageContext -containerName $vhdContainer
    # check on copy status
    do{
       $rtn = $null
       $rtn = Get-AzureStorageBlob -Context $OSstorageContext -container $OScontainerName -Blob $OSblobName | Get-AzureStorageBlobCopyState -ErrorAction Stop
       $rtn | select Source, Status, BytesCopied, TotalBytes | fl
       if($rtn.status  -ne 'Success'){
         write-verbose "Waiting for blob copy $OSblobName to complete" -verbose
         Sleep 10
       }
    }
    while($rtn.status  -ne 'Success')
    # exit script if user breaks out of above loop
    if($rtn.status  -ne 'Success'){EXIT}
    # get the Network Interface Card we created previously based on the original source name
    $NICRef = ($srcVM.NetworkInterfaceIDs).Split('/')
    $NICName = $NICRef[($NICRef.count -1)]
    $NIC = Get-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName
    # create VM Config
    if($AvailabilitySet)
    {
        $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize  -AvailabilitySetID $AvailabilitySet.Id  -wa SilentlyContinue
    }
    else
    {
        $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -wa SilentlyContinue
    }
    # Set OS Disk based on OS type
    if($OStype -eq 'Windows' -or $OStype -eq '0'){
       $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -Caching $OSDiskCaching -CreateOption $createOption -Windows
    }
    else
    {
       $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -Caching $OSDiskCaching -CreateOption $createOption -Linux
    }
    # add NIC
    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
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
            $DiskSizeGB = $disk.DiskSizeGB
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
$drtn = Get-AzureStorageBlob -Context $diskStorageContext -container $diskContainerName -Blob $diskBlobName | Get-AzureStorageBlobCopyState -ErrorAction Stop
              $drtn| select Source, Status, BytesCopied, TotalBytes|fl
              if($rtn.status  -ne 'Success')
              {
               write-verbose "Waiting for blob copy $diskBlobName to complete" -verbose
               Sleep 10
              }
            }
            while($drtn.status  -ne 'Success')
            # exit script if user breaks out of above loop
            if($rtn.status  -ne 'Success'){EXIT}
            Add-AzureRmVMDataDisk -VM $VirtualMachine -Name $dataDiskName -DiskSizeInGB $DiskSizeGB -Lun $dataDiskLUN -VhdUri $dataDiskUri -Caching $diskCaching -CreateOption $CreateOption | out-null
        }
    }
    # create the VM from the config
    try
    {
        write-verbose "Recreating Virtual Machine $VMName in resource group $resourceGroupName at location $location" -verbose
       # $VirtualMachine
        New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $location -VM $VirtualMachine -ea Stop -wa SilentlyContinue | out-null
        write-output "Successfully recreated Virtual Machine $VMName"
    }
    catch
    {
         $_
         write-warning "Failed to create Virtual Machine $VMName"
    }
}\n