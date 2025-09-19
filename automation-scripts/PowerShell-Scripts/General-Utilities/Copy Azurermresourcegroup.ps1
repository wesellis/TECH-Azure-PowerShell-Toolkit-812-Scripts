#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Copy Azurermresourcegroup

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
    We Enhanced Copy Azurermresourcegroup

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
    Copies Azure V2 (ARM) resources from one Azure Subscription to another.  
    Unlike the Move-AzureRMresource cmdlet, this script allows you to move between subscriptions in different Tenants and 
    different Azure Environments. Requires AzureRM module version 6.7 or later.
    
.DESCRIPTION
   Copies configurations of a resource group in one subscription and provisions them in the target subscription.
   This is intended mostly for Azure V2 virtual machines and will include copying virtual disks, virtual
   network, load balancers, Public IPs and other associated storage accounts and blob files.

   The VHD copies can take several hours depending on how many and the sizes so the script can be executed in two parts.  
   It will break with the copy status that can be refreshed - or you can exit at that point and use the -resume switch to 
   continue with the VM provisioning after the file copies are complete.

  Due to uniqueness requirements DNS names of source and targets, the following renaming occurs during reprovisioning within the same environment
  ** Storage accounts will be renamed by appending an 8 character GUID to the original storage account name
  ** DNS Labels on Public IPs will be renamed by appending 'new' to the DNS name



.EXAMPLE
   .\Copy-AzureRMresourceGroup.ps1 -ResourceGroupName 'CONTOSO'

Using the script without explicitly specifying OptionalSourceEnvironment or OptionalTargetEnvrionment will result in prompts for these.  
Press <Enter> to accept the default environment of AzureCloud.

.EXAMPLE
   .\Copy-AzureRMresourceGroup.ps1 -ResourceGroupName 'CONTOSO'  -Resume

Resumes the script after waitig for the blob copy to complete.  Press <Enter> to accept the default source and target environments of AzureCloud.

.EXAMPLE
   .\Copy-AzureRMresourceGroup.ps1 -ResourceGroupName 'CONTOSO' -OptionalNewLocation 'westus'

Specify -newLocation if the target resource group needs to be in a different region than the source
Press <Enter> to accept the default environment of AzureCloud.


.EXAMPLE
   .\Copy-AzureRMresourceGroup.ps1 -ResourceGroupName 'CONTOSO' -OptionalTargetEnvironment 'AzureGermanCloud' 

Copies Resource Group CONTOSO from Azure Cloud to Azure German Cloud.  Press <Enter> at prompt for OptionalSourceEnvironment


.EXAMPLE
   .\Copy-AzureRMresourceGroup.ps1 -ResourceGroupName 'CONTOSO' -OptionalSourceEnvironment 'AzureUSGovernment'  -OptionalTargetEnvironment 'AzureUSGovernment' 

Copies Resource Group CONTOSO from Azure Government to Azure Government



.PARAMETER -ResourceGroupName [string]
  Name of resource group being copied

.PARAMETER -OptionalSourceEnvironment [string]
  Name of the source Environment. e.g. AzureUSGovernment, AzureGermanCloud or AzureChinaCloud. Defaults to AzureCloud.

.PARAMETER -OptionalTargetEnvironment [string]
  Name of the target Environment. e.g. AzureUSGovernment, AzureGermanCloud or AzureChinaCloud. Defaults to AzureCloud.

.PARAMETER -OptionalNewLocation [string]
  Name of the Azure location for new resource group if different than the source.

.PARAMETER -Resume [switch]
  Resumes after the file copy


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
$ErrorActionPreference = " Stop"
param(
    [Parameter(mandatory=$WETrue,
      HelpMessage=" Enter the name of the Azure Resource Group you want to copy and Press <Enter> e.g. CONTOSO" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,

    [Parameter(mandatory=$WETrue,
      HelpMessage=" Press <Enter> to default to AzureCloud or enter the Azure Environment name of the source subscription. e.g. AzureUSGovernment" )]
    [AllowEmptyString()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOptionalSourceEnvironment,
    
    [Parameter(mandatory=$WETrue,
      HelpMessage=" Press <Enter> to default to AzureCloud or enter the Azure Environment name of the target subscription. e.g. AzureGermanCloud" )]
    [AllowEmptyString()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOptionalTargetEnvironment,

   [Parameter(mandatory=$WETrue,
    HelpMessage=" Press <Enter> to create the new resource in the same region as the source or enter a new location/region for the target." )]
    [AllowEmptyString()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOptionalNewLocation,

    [Parameter(mandatory=$WEFalse,
      HelpMessage=" Use this switch to resume the script after waiting for the blob copy to complete" )]
    [switch]$WEResume



)  

#region Functions

$resourceGroupVmResumePath = " $env:TEMP\$resourcegroupname.resourceGroupVMs.resume.json"
$resourceGroupVmSizeResumePath = " $env:TEMP\$resourcegroupname.resourceGroupVMsize.resume.json"
$WEVHDstorageObjectsResumePath = " $env:TEMP\$resourcegroupname.VHDstorageObjects.resume.json"
$jsonBackupPath = " $env:TEMP\$resourcegroupname.json"
$WEProgressPreference = 'SilentlyContinue'

import-module AzureRM 

if ((Get-Module -ErrorAction Stop AzureRM).Version -lt " 6.7.0" ) {
   Write-warning " Old version of Azure PowerShell module  $((Get-Module -ErrorAction Stop AzureRM).Version.ToString()) detected.  Minimum of 6.7 required. Run Update-Module AzureRM"
   BREAK
}


<###############################
 Get Storage Context function

[CmdletBinding()]
function WE-Get-StorageObject -ErrorAction Stop 
{ [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($resourceGroupName, $srcURI, $srcName) 
    
    $split = $srcURI.Split('/')
    $strgDNS = $split[2]
    $splitDNS = $strgDNS.Split('.')
    $storageAccountName = $splitDNS[0]
    # add uri and storage account name to custom PSobject
    $WEPSobjSourceStorage = New-Object -TypeName PSObject
    $WEPSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcStorageAccount -Value $storageAccountName  
    $WEPSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcURI -Value $srcURI
    $WEPSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcName -Value $srcName
    # retrieve storage account key and storage context
    $WEStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $WEStorageAccountName).Value[0]
    $WEStorageContext = New-AzureStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey $WEStorageAccountKey
    # add storage context to psObject
    $WEPSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageContext -Value $WEStorageContext 
    # get storage account and add other attributes to psCustom object
    $storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
    $WEPSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageEncryption -Value $storageAccount.Encryption
    $WEPSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageCustomDomain -Value $storageAccount.CustomDomain
    $WEPSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageKind -Value $storageAccount.Kind
    $WEPSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageAccessTier -Value $storageAccount.AccessTier
    # get storage account sku and convert to string that is required for creation
    $skuName = $storageAccount.sku.Name.ToString()
 
    switch ($skuName) 
        { 
            'StandardLRS'   {$skuName = 'Standard_LRS'} 
            'Standard_LRS'   {$skuName = 'Standard_LRS'} 
            'StandardZRS'   {$skuName = 'Standard_ZRS'} 
            'StandardGRS'   {$skuName = 'Standard_GRS'} 
            'StandardRAGRS'{$skuName = 'Standard_RAGRS'} 
            'PremiumLRS'   {$skuName = 'Premium_LRS'} 
            'Premium_LRS'   {$skuName = 'Premium_LRS'} 
            default {$skuName = 'Standard_LRS'}
        }
     
     $WEPSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcSkuName -Value $skuName
    
    return $WEPSobjSourceStorage

} # end of Get-StorageObject -ErrorAction Stop function

<###############################
  get available resources function

[CmdletBinding()]
function get-availableResources -ErrorAction Stop
{ [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($resourceType, $location)

    $resource = Get-AzureRmVMUsage -Location $location | Where-Object{$_.Name.value -eq $resourceType}
    [int32]$availabe = $resource.limit - $resource.currentvalue
    return $availabe 

}
<###############################
  get blob copy status

[CmdletBinding()]
function WE-Get-BlobCopyStatus -ErrorAction Stop
{ [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($context, $containerName, $blobName)
    
    if($blobName)
    {
        write-verbose " Checking VHD blob copy for $blobName" -verbose
        $blob = Get-AzureStorageBlob -Context $context -container $containerName -Blob $blobName
    }
    else
    {
        write-verbose " Checking VHD blob copy for container $containerName" -verbose 
        $blob = Get-AzureStorageBlob -Context $context -container $containerName 
    }

    do
    {
        $rtn = $blob | Get-AzureStorageBlobCopyState -ErrorAction Stop
        $rtn | Select-Object Source, Status, BytesCopied, TotalBytes | Format-List
        if($rtn.status  -ne 'Success')
        {
            write-warning " VHD blob copy is not complete"
            $rh = read-host " Press <Enter> to refresh or type EXIT and press <Enter> to quit copy status updates and resume later"
            if(($rh.ToLower()) -eq 'exit')
            {
                write-output " Run script with -resume switch to continue creating VMs after file copy has completed."
                BREAK
            }
        }
    }
    while($rtn.status  -ne 'Success')

    # exit script if user breaks out of above loop   
    if($rtn.status  -ne 'Success'){EXIT}

}

<###############################
  Copy blob function

[CmdletBinding()]
function copy-azureBlob 
{  [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($srcUri, $srcContext, $destContext, $containerName)


    $split = $srcURI.Split('/')
    $blobName = $split[($split.count -1)]
   ;  $blobSplit = $blobName.Split('.')
   ;  $extension = $blobSplit[($blobSplit.count -1)]
    if($($extension.tolower()) -eq 'status' ){Write-Output " Status file blob $blobname skipped" ;return}

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
       ;  $blobName = $blobName.Substring(1, $blobName.Length-1)
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
        $params = @{
            DestBlob = $blobName
            srcUri = $srcUri
            DestContext = $destContext
            SrcContext = $srcContext
            DestContainer = $containerName
            ea = "Stop"
        }
        $blobCopy @params

         write-output " $srcUri is being copied to $containerName"
    
   }
   catch
   { 
      $_ ; write-warning " Failed to copy to $srcUri to $containerName"
   }
  

} # end of copy-azureBlob function


if(! $resume){

<###############################

 Read resource group from old Sub




if($WEOptionalSourceEnvironment -and (Get-AzureRMEnvironment -Name $WEOptionalSourceEnvironment) -eq $null)
{
   write-warning " The specified -OptionalSourceEnvironment could not be found. Specify one of these valid environments."
   $WEOptionalSourceEnvironment = (Get-AzureRMEnvironment -ErrorAction Stop | Select-Object Name, ManagementPortalUrl | Out-GridView -title " Select a valid Azure environment for your source subscription" -OutputMode Single).Name
}


Write-Information " Enter credentials for the 'source' Azure Subscription..." -f Yellow
if($WEOptionalSourceEnvironment)
{
   $login= Connect-AzureRmAccount -EnvironmentName $WEOptionalSourceEnvironment
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



$WERGexport = Export-AzureRmResourceGroup -ResourceGroupName $resourceGroupName -Path $jsonBackupPath -IncludeParameterDefaultValue -Force -wa SilentlyContinue




[string] $location = $sourceResourceGroup.location
$resourceGroupStorageAccounts = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName
$resourceGroupManagedDisks = Get-AzureRmDisk -ResourceGroupName $resourceGroupName
$resourceGroupVirtualNetworks = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName
$resourceGroupNICs = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName
$resourceGroupNSGs = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroupName
$resourceGroupAvSets = Get-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName 
$resourceGroupVMs = Get-AzureRMVM -ResourceGroupName $resourceGroupName
$resourceGroupPIPs = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName
$resourceGroupNICs = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName; 
$resourceGroupLBs = Get-AzureRmLoadBalancer -ResourceGroupName $resourceGroupName
if(! $resourceGroupVMs){write-warning " No virtual machines found in resource group $resourceGroupName" }




Write-Information " The following items will be copied:" -f DarkGreen
Write-Information " Storage Accounts:" -f DarkGreen
$resourceGroupStorageAccounts.StorageAccountName
Write-Information " Managed Disks:" -f DarkGreen
$resourceGroupManagedDisks.Name
Write-Information " Virtual Machines:" -f DarkGreen
$resourceGroupVMs.name
Write-Information " Operating system disks:" -f DarkGreen
$resourceGroupVMs.storageProfile.osdisk.name
Write-Information " Data disks:" -f DarkGreen
$resourceGroupVMs.datadisknames

Write-Information " Current status of VMs:" -f DarkGreen
$resourceGroupVMs | %{
  ;  $status = ((get-azurermvm -ResourceGroupName $resourceGroupName -Name $_.name -status).Statuses|Where-Object{$_.Code -like 'PowerState*'}).DisplayStatus
   write-output " $($_.name) status is $status" 
   if($status -eq 'VM running'){write-warning " All virtual machines in this resource group are not stopped.  Please stop all VMs and try again" ; break}
}

Write-Information " Virtual networks:" -f DarkGreen
$resourceGroupVirtualNetworks.name
Write-Information " Network Security Groups:" -f DarkGreen
$resourceGroupNSGs.name
Write-Information " Load Balancers:" -f DarkGreen
$resourceGroupLBs.name
Write-Information " Public IPs:" -f DarkGreen
$resourceGroupPIPs.name




[array]$sourceVHDstorageObjects = $()
[array]$sourceMDstorageObjects = $()
write-verbose " Retrieving storage context for each source blob" -Verbose

foreach($vm in $resourceGroupVMs) 
{
    # get storage account name from VM.URI
    if($vm.storageprofile.osdisk.vhd)
    {
        $vmURI = $vm.storageprofile.osdisk.vhd.uri
        $obj = $null
        $obj = Get-StorageObject -resourceGroupName $resourceGroupName -srcURI $vmURI
        [array]$sourceVHDstorageObjects = $sourceVHDstorageObjects + $obj 
    }
    
    if($vm.storageProfile.datadisks)
    {
       foreach($disk in $vm.storageProfile.datadisks) 
       {
            if($disk.vhd)
            {
                $diskURI = $disk.vhd.uri
                $obj = $null
                $obj = Get-StorageObject -resourceGroupName $resourceGroupName -srcURI $diskURI
                [array]$sourceVHDstorageObjects = $sourceVHDstorageObjects + $obj
            }
       }
    }
}

    # start copy of all Managed Disks       
    write-verbose " Retrieving SAS access token for each managed disk" -Verbose

    foreach($md in $resourceGroupManagedDisks)
    { 

        #Get the SAS URL of the VHD blob and do a copy process to the temp storage account
        $WEAccessURI = $md | Grant-AzureRmDiskAccess -Access 'Read' -DurationInSecond 10800
        $WEAccessSAS = $WEAccessURI.AccessSAS

        $WEPSobjMDstorage = New-Object -TypeName PSObject
        $WEPSobjMDstorage | Add-Member -MemberType NoteProperty -Name Name -Value $md.Name
        $WEPSobjMDstorage | Add-Member -MemberType NoteProperty -Name AccessSAS -Value $WEAccessSAS
        $WEPSobjMDstorage | Add-Member -MemberType NoteProperty -Name SkuName -Value $md.sku.Name.ToString()
        $WEPSobjMDstorage | Add-Member -MemberType NoteProperty -Name Id -Value $md.id  
        $WEPSobjMDstorage | Add-Member -MemberType NoteProperty -Name OsType -Value $md.OsType
        $WEPSobjMDstorage | Add-Member -MemberType NoteProperty -Name DiskSizeGB -Value $md.DiskSizeGB
        $WEPSobjMDstorage | Add-Member -MemberType NoteProperty -Name EncryptionSettings -Value $md.EncryptionSettings

        [array]$sourceMDstorageObjects = $sourceMDstorageObjects + $WEPSobjMDstorage
    }


[array]$sourceStorageObjects = $()

foreach($sourceStorageAccount in $resourceGroupStorageAccounts)
{ 
  $sourceStorageAccountName = $sourceStorageAccount.StorageAccountName
  $sourceStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $sourceStorageAccountName).Value[0]
  $sourceStorageContext = New-AzureStorageContext -StorageAccountName $sourceStorageAccountName -StorageAccountKey $sourceStorageAccountKey 
  $sourceStorageContainers = Get-AzureStorageContainer -Context $sourceStorageContext
  foreach($container in $sourceStorageContainers)
  {
    $blobs = Get-AzureStorageBlob -Container $container.name -Context $sourceStorageContext

    foreach($blob in $blobs) 
    {
      # get storage account details from uri
      $WEURI = $blob.ICloudBlob.uri.Absoluteuri
      # only add to sourceStorageObjects if it isn't in sourceVHDstorageObjects - must do replace to adapt to absoluteURI
      if($sourceVHDstorageObjects.srcURI -notcontains ($WEURI.replace('https','http')) -and $sourceVHDstorageObjects.srcURI -notcontains $WEURI)
      {
        $obj = $null
        $obj = Get-StorageObject -resourceGroupName $resourceGroupName -srcURI $WEURI
        [array]$sourceStorageObjects = $sourceStorageObjects + $obj 
      }
    }
  }
}

Write-Information " Additional storage blobs:" -f DarkGreen
$sourceStorageObjects.srcURI


} # end of if not resume



<#############################################################


 Recreate resource group in new Sub





$login = $null
$sub = $null
$WESourceSubscriptionID = $subscriptionID
$subscriptionID = $null


if($WEOptionalTargetEnvironment -and (Get-AzureRMEnvironment -Name $WEOptionalTargetEnvironment) -eq $null)
{
   write-warning " The specified -OptionalTargetEnvironment could not be found. Select one of these valid environments."
   $WEOptionalTargetEnvironment = (Get-AzureRMEnvironment -ErrorAction Stop | Select-Object Name, ManagementPortalUrl | Out-GridView -title " Select a valid Azure environment for your target subscription" -OutputMode Single).Name
}

Write-Information " Disconnecting from the 'source' Azure Subscription..." -f Yellow
Disconnect-AzureRmAccount -Username $loginID | Out-Null


Write-Information " Enter credentials for the 'target' Azure Subscription..." -f Yellow
if($WEOptionalTargetEnvironment)
{
   $login= Connect-AzureRmAccount -EnvironmentName $WEOptionalTargetEnvironment
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
    Select-AzureRmSubscription -SubscriptionId $WESubscriptionId| Out-Null
    $sub = Get-AzureRmSubscription -SubscriptionId $WESubscriptionId
}

   


if(! $WESubscriptionId) 
{
   write-warning " The provided credentials failed to authenticate or are not associcated to a valid subscription. Exiting the script."
   break
}

if($WESubscriptionId -eq $WESourceSubscriptionID) 
{
   write-warning " Failed to authenticate to a different subscription. Exiting the script."
   break
}

$WESubscriptionName = $sub.Name

Write-Information " Logged into $WESubscriptionName with subscriptionID $WESubscriptionId as $loginID" -f Green


if(! $resume)
{
    [bool]$isSameEnv = $true
    if($WEOptionalTargetEnvironment -ne $WEOptionalSourceEnvironment)
    {
        [bool]$isSameEnv = $false
    }

    <###############################
     Verify Location
    ################################>
    $srcLocation = $location

    if($WEOptionalNewLocation)
    {
        $location = $WEOptionalNewLocation
    }

    Write-Output " Verifying specified location: $location ..."
    # Prompt for location if provided location doesn't exist in current environment.
    $location = (Get-AzureRMlocation -ErrorAction Stop | Where-Object { $_.Providers -eq 'Microsoft.Compute' -and ( $_.DisplayName -like $location -or $_.location -like $location)}).location
    if(! $location) 
    {
        write-warning " $WEOptionalNewLocation is an invalid Azure Resource Group location for this environment.  Please select a valid location and click OK"
        $location = (Get-AzureRMlocation -ErrorAction Stop | Where-Object { $_.Providers -eq 'Microsoft.Compute'} | Select-Object DisplayName, Providers, Location | Out-GridView -Title " Select Azure Resource Group Location" -OutputMode Single).location
    }


    <###############################
     Verify Available Resources 
    ################################>

    foreach ($vmSize in ($resourceGroupVMs.hardwareprofile.vmsize))
    {
        $cores = $null
        $cores = (Get-AzureRmVMSize -Location $location | Where-Object{$_.Name -eq $vmSize}).NumberOfCores
        $totalCoresNeeded = $cores + $totalCoresNeeded
    }

    
    $WETotalAvailabeVMs = Get-availableResources -ResourceType 'virtualMachines' -Location $location
    if($resourceGroupVMs.count -gt $WETotalAvailabeVMs)
    {
        Write-Warning " Insufficent available VMs in location $location. Script halted."
        break
    }

    $WETotalAvailabeCores = Get-availableResources -ResourceType 'cores' -Location $location
    if($totalCoresNeeded -gt $WETotalAvailabeCores)
    {
        Write-Warning " Insufficent available cores in location $location. Script halted."
        break
    }
    

    $WETotalAvailabeAVs = Get-availableResources -ResourceType 'availabilitySets' -Location $location
    if($resourceGroupAvSets.count -gt $WETotalAvailabeAVs)
    {
        Write-Warning " Insufficent Availability Sets in location $location. Script halted."
        break
    }
    


    <###############################

    Create new Resource Group - using same name as source

    ################################>

    do 
    {
        $WERGexists = $null
        try
        {
            $WERGexists = Get-AzureRmResourceGroup -Name $WEResourceGroupName -ea stop
        }
        catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
        
        if($WERGexists) 
        {
            write-warning " $WEResourceGroupName already exists." 
            $WEResourceGroupName = read-host   'Enter a different Resource Group Name'
        }  
    }
    while($WERGexists)


    try
    {
        write-verbose " Creating new resource group $resourceGroupName in $location" -Verbose
        $WENewResourceGroup  = New-AzureRmResourceGroup -Name $WEResourceGroupName -Location $location -ea Stop -wa SilentlyContinue
        write-output " The new resource group $resourceGroupName was created in subscription $WESubscriptionName"
    }
    catch
    {
        $_
        write-warning " Failed to create the new resource group $resourceGroupName  Exiting the script."
        break
    }



  <###############################

   Create new destination storage accounts
   and copy blobs
 
   ################################>


    # initialize array to store new destination storage account names relative to srcURI
    [array]$WEVHDstorageObjects = @()

    # get all the unique source storage accounts from custom psobject
    $srcStorageAccountNames = $sourceStorageObjects | Select-Object -Property srcStorageAccount -Unique
    
    $WEVHDsrcStorageAccounts = $sourceVHDstorageObjects| Select-Object -Property srcStorageAccount -Unique
    
    # add the VHD storage accounts to $sourceStorageObjects if they're not there already
    foreach($WEVHDsrcStorageAccountObj in $WEVHDsrcStorageAccounts)
    {
        $WEVHDsrcStorageAccountName = $WEVHDsrcStorageAccountObj.srcStorageAccount
        
        if($srcStorageAccountNames.srcStorageAccount -notcontains $WEVHDsrcStorageAccountName )
        {
            [array]$sourceStorageObjects = $sourceStorageObjects + $sourceVHDstorageObjects|Where-Object{$_.srcStorageAccount -eq $WEVHDsrcStorageAccountName}
        }
    }

    $srcStorageAccounts = $sourceStorageObjects | Select-Object -Property srcStorageAccount -Unique

    # process each source storage account - creating new destination storage account from old account name
    foreach($srcStorageAccountObj in $srcStorageAccounts)
    {
        $srcStorageAccount = $srcStorageAccountObj.srcStorageAccount 
        if($isSameEnv)
        {
            # create unique storage account name from old account name and guid
            if($srcStorageAccount.Length -gt 16)
            {
                $first16 = $srcStorageAccount.Substring(0,16)
            }
            else
            {
                $first16 = $srcStorageAccount
            }

            [string] $guid = (New-Guid).Guid
            [string] $WEDeststorageAccountName = " $($first16.ToLower())" +($guid.Substring(0,8))
        }
        else
        {
            $WEDeststorageAccountName = $srcStorageAccount
        }

        # select sku and other attributes
        $skuName = ($sourceStorageObjects | Where-Object{$_.srcStorageAccount -eq $srcStorageAccount} | Select-Object -Property srcSkuName -Unique).srcSkuName
        $WEEncryption = ($sourceStorageObjects | Where-Object{$_.srcStorageAccount -eq $srcStorageAccount} | Select-Object -Property SrcStorageEncryption -Unique).SrcStorageEncryption
        $WECustomDomain = ($sourceStorageObjects | Where-Object{$_.srcStorageAccount -eq $srcStorageAccount} | Select-Object -Property SrcStorageCustomDomain -Unique).SrcStorageCustomDomain
        $kind = ($sourceStorageObjects | Where-Object{$_.srcStorageAccount -eq $srcStorageAccount} | Select-Object -Property SrcStorageKind -Unique).SrcStorageKind
        $WEAccessTier = ($sourceStorageObjects | Where-Object{$_.srcStorageAccount -eq $srcStorageAccount} | Select-Object -Property SrcStorageAccessTier -Unique).SrcStorageAccessTier
        
        $storageParams = @{
        " ResourceGroupName" = $resourceGroupName 
        " Name" = $WEDeststorageAccountName 
        " location" = $location
        " SkuName" = $skuName
        }

        # add AccessTier if kind is BlobStorage.
        if($kind -ne 'Storage') 
        {
            $storageParams.Add(" Kind" , $kind)
            $storageParams.Add(" AccessTier" , $accessTier)
        }

        # add CustomDomainName if present.
        if($WECustomDomain) 
        {
            $storageParams.Add(" CustomDomainName" , $WECustomDomain)
        }

        # add CustomDomainName if present.
        if($WEEncryption) 
        {
            if($WEEncryption.Services.Blob){$encryptionBlob  = 'Blob'}
            if($WEEncryption.Services.File){$encryptionFile  = 'File'}
            if($encryptionBlob){$WEEncryptionType = $encryptionBlob}
            if($encryptionFile){$WEEncryptionType = $encryptionFile}
            if($encryptionBlob -and $encryptionFile){$WEEncryptionType = " $encryptionBlob,$encryptionFile" }
           # remarked for newer modules, prior to 6.7, this was required
           
           #  $storageParams.Add(" EnableEncryptionService" , $WEEncryptionType)
        }
        

        # Create new storage account
        do 
        {
            try
            {
                # create new storage account
                write-verbose " Creating storage account $WEDeststorageAccountName in resource group $resourceGroupName at location $location" -verbose
                $newStorageAccount = New-AzureRmStorageAccount -ErrorAction Stop @storageParams -ea Stop -wa SilentlyContinue 
                write-output " The storage account $WEDeststorageAccountName was created"
            }
            catch
            {
                $_
                write-warning " Failed to create storage account. Storage account name $WEDeststorageAccountName may already exists."
                $WEDeststorageAccountName = read-host   'Enter a different Destination Storage Account Name'
            }
        }
        while(! $newStorageAccount)


        try 
        {
            # get key and storage context of newly created storage account
            $WEDestStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $WEDestStorageAccountName -ea Stop).Value[0] 
            $WEDestStorageContext = New-AzureStorageContext -StorageAccountName $WEDestStorageAccountName -StorageAccountKey $WEDestStorageAccountKey -ea Stop -wa SilentlyContinue
        }
        catch 
        {
            write-warning " Could not retrieve storage account key or storage context for $WEDestStorageAccountName . Exiting the script."
            break
        }



        # start blob copy for VHDs attached to VMs        
        foreach($obj in $sourceVHDstorageObjects | Where-Object{$_.srcStorageAccount -eq $srcStorageAccount})
        { 
            $srcURI = $obj.srcURI

            copy-azureBlob -srcUri $srcURI -srcContext $obj.SrcStorageContext -destContext $WEDestStorageContext
            #copy-azureBlob -srcUri $srcURI -srcContext $obj.SrcStorageContext -destContext $WEDestStorageContext -containerName 'vhd-backup'
            
            # add srcURI and destination storage account name to custom PSobject
            $WEPSobjVHDstorage = New-Object -TypeName PSObject
            $WEPSobjVHDstorage | Add-Member -MemberType NoteProperty -Name destStorageContext -Value $WEDestStorageContext  
            $WEPSobjVHDstorage | Add-Member -MemberType NoteProperty -Name srcURI -Value $srcURI 

            [array]$WEVHDstorageObjects = $WEVHDstorageObjects + $WEPSobjVHDstorage
        }
    
        
        # start copy for remaining blobs           
        if($srcStorageAccountNames)
        {
            foreach($obj in $sourceStorageObjects | Where-Object{$_.srcStorageAccount -eq $srcStorageAccount})
            {
                copy-azureBlob -srcUri $obj.srcURI -srcContext $obj.SrcStorageContext -destContext $WEDestStorageContext 
            }
        }


    } # end of foreach srcStorageAccounts

    # create temporary blob storage account to stage managed disks that will be copied 
    if($resourceGroupManagedDisks)
    {
        $cleanResourceGroupName = $resourceGroupName -replace " [^a-z0-9]" , ""

        if($resourceGroupName.Length -gt 16)
        {
            $first16 = $cleanResourceGroupName.Substring(0,16)
        }
        else
        {
            $first16 = $cleanResourceGroupName 
        }

           
        [string] $guid = (New-Guid).Guid
        [string] $tempStorageAccountName = " $($first16.ToLower())" +($guid.Substring(0,8))

        $storageParams = @{
        " ResourceGroupName" = $resourceGroupName 
        " Name" = $tempstorageAccountName 
        " location" = $location
        " SkuName" = 'Standard_LRS'
        }
            
        # Create new storage account
        do 
        {
            try
            {
                # create new storage account
                write-verbose " Creating temmporary storage account $tempstorageAccountName in resource group $resourceGroupName at location $location" -verbose
                $newStorageAccount = New-AzureRmStorageAccount -ErrorAction Stop @storageParams -ea Stop -wa SilentlyContinue 
                write-output " The storage account $tempstorageAccountName was created"
            }
            catch
            {
                $_
                write-warning " Failed to create temporary storage account. Storage account name $WEDeststorageAccountName may already exists."
                $tempstorageAccountName = read-host   'Enter a different Temporary Storage Account Name. This is used to stage managed disks.'
            }
        }
        while(! $newStorageAccount)


        try 
        {
            # get key and storage context of newly created storage account
            $tempStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $tempStorageAccountName -ea Stop).Value[0] 
            $tempStorageContext = New-AzureStorageContext -StorageAccountName $tempStorageAccountName -StorageAccountKey $tempStorageAccountKey -ea Stop -wa SilentlyContinue
            $tempContainer = New-AzureStorageContainer -Name 'vhdblobs' -Context $tempStorageContext -Permission Blob  -ea Stop -wa SilentlyContinue
        }
        catch 
        {
            write-warning " Could not retrieve storage account key or storage context for $tempStorageAccountName . Exiting the script."
            break
        }

    }

    # start copy of all Managed Disks       
    foreach($md in $sourceMDstorageObjects)
    { 
        $srcMDname = $md.Name
        $srcSkuName = $md.SkuName
        $WEAccessSAS = $md.AccessSAS
        # $srcMDid = $md.id
        # $srcOStype = $md.OsType

        $rtn = Start-AzureStorageBlobCopy -AbsoluteUri $WEAccessSAS -DestBlob $srcMDname -DestContainer $tempContainer.Name -destContext $tempStorageContext
        $WEPSobjVHDstorage = New-Object -TypeName PSObject
        $WEPSobjVHDstorage | Add-Member -MemberType NoteProperty -Name srcName -Value $srcMDname 
        $WEPSobjVHDstorage | Add-Member -MemberType NoteProperty -Name destStorageContext -Value $tempStorageContext 
        $WEPSobjVHDstorage | Add-Member -MemberType NoteProperty -Name srcURI -Value $rtn.ICloudBlob.Uri.AbsoluteUri
        $WEPSobjVHDstorage | Add-Member -MemberType NoteProperty -Name srcSkuName -Value $srcSkuName

        [array]$WEVHDstorageObjects = $WEVHDstorageObjects + $WEPSobjVHDstorage
    }
    
    <###############################

    Create new network resources.  
    Vnets, NICs, Loadbalancers, PIPs

    ################################>
        
    
    # create new Network Security Groups
    foreach($srcNSG in $resourceGroupNSGs)
    {
        $nsgName = $srcNSG.name
        [array]$nsgRules = @()
       
        foreach($nsgRule in $srcNSG.SecurityRules)
        {
           
            $nsgRuleParams = @{
                " Name" = $nsgRule.Name  
                " Access" = $nsgRule.Access
                " Protocol" = $nsgRule.Protocol 
                " Direction" = $nsgRule.Direction 
                " Priority" = $nsgRule.Priority 
                " SourceAddressPrefix" = $nsgRule.SourceAddressPrefix 
                " SourcePortRange" =  $nsgRule.SourcePortRange 
                " DestinationAddressPrefix" = $nsgRule.DestinationAddressPrefix 
                " DestinationPortRange" = $nsgRule.DestinationPortRange
            }

            if($nsgRule.Description)
            {
                $nsgRuleParams.Add(" Description" , $nsgRule.Description)
            }

           $nsgRules = $nsgRules + New-AzureRmNetworkSecurityRuleConfig -ErrorAction Stop @nsgRuleParams
        }
    

        try
        {
            write-verbose " Creating Network Security Group $nsgName in resource group $resourceGroupName at location $location" -verbose
           $WENSG = New-AzureRmNetworkSecurityGroup -Name $nsgName -SecurityRules $nsgRules  -ResourceGroupName $WEResourceGroupName -Location $location  -ea Stop -wa SilentlyContinue
            Write-Output " Network Security Group $nsgName was created"
        }
        catch
        {
            $_
            write-warning " Failed to create Network Security Group $nsgName"
        }


    }

    # create new Virtual Network(s)
    foreach($srcNetwork in $resourceGroupVirtualNetworks)
    {
        $destVNname = $srcNetwork.Name
        $destAddressPrefix = $srcNetwork.AddressSpace.AddressPrefixes
        $destDNSserver = $srcNetwork.DhcpOptions.DnsServers
        $destSubnets = $srcNetwork.Subnets
        try
        {
            write-verbose " Creating virtual network $destVNname in resource group $resourceGroupName at location $location" -verbose
            $newVirtualNetwork = New-AzureRmVirtualNetwork -Name $destVNname -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $destAddressPrefix -DnsServer $destDNSserver -Subnet $destSubnets -Force -ea Stop -wa SilentlyContinue
            Write-Output " Virtual Network $destVNname was created"
        }
        catch
        {
            $_
            write-warning " Failed to create virtual network $destVNname"
        }

                       
        foreach($destSub in $destSubnets) 
        {         
            if($destSub.Subnets.NetworkSecurityGroup)
            {   
                try
                {
                    $WENSGsplit = $destSub.Subnets.NetworkSecurityGroup.id.split('/')
                    $srcNSGname = $WENSGsplit[$WENSGsplit.Length -1]
                    $WENSG = Get-AzureRmNetworkSecurityGroup -Name $srcNSGname -ResourceGroupName $WEResourceGroupName -ea Stop
                    $subnet = $newVirtualNetwork | Get-AzureRmVirtualNetworkSubnetConfig -ErrorAction Stop  -Name $destSub.Name -ea Stop -wa SilentlyContinue
                    Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $newVirtualNetwork -Name $destSub.Name -AddressPrefix $subnet.AddressPrefix -NetworkSecurityGroup $WENSG | Set-AzureRmVirtualNetwork -ea Stop | out-null
                }
                catch
                {
                    $_
                    write-warning " Failed to add Network Security Group $srcNSGname to $($destSub.Name)"
                }
            }
          
        }

    }

    
    # create new Availability sets
    foreach($srcAVset in $resourceGroupAvSets)
    {
        $WEAVname = $srcAVset.name
        
        $avParams = @{
            " Name" = $WEAVname 
            " ResourceGroupName" = $resourceGroupName  
            " Location" = $location
            " sku" = $srcAVset.Sku
            " PlatformFaultDomainCount" = $srcAVset.PlatformFaultDomainCount
            " PlatformUpdateDomainCount" = $srcAVset.PlatformUpdateDomainCount
            " ea" = 'Stop'
            " wa" = 'SilentlyContinue'
        }
        
 
        try
        {
            write-verbose " Creating availability set $WEAVname in resource group $resourceGroupName at location $location" -verbose
            $WENewAvailabilitySet = New-AzureRmAvailabilitySet -ErrorAction Stop @avParams 
            Write-Output " Availability Set $WEAVname was created"
        }
        catch
        {
            $_
            write-warning " Failed to create availability set $WEAVname"
        } 
    
    }


    # create new PIPs
    foreach($srcPIP in $resourceGroupPIPs)
    {
        $pipName = $srcPIP.name
        $pipDomainNameLabel = $srcPIP.dnssettings.domainNameLabel

        $pipParams = @{
                " Name" = $pipName 
                " ResourceGroupName" = $resourceGroupName  
                " Location" = $location
                " AllocationMethod" = $srcPIP.PublicIpAllocationMethod
                " ea" = 'Stop'
                " wa" = 'SilentlyContinue'
        }
                
        # append 'new' to name so it is unique from existing
        if($pipDomainNameLabel)
        {
          $WENewPipDomainNameLabel = $pipDomainNameLabel + 'new'
          $pipParams.Add(" DomainNameLabel" , $WENewPipDomainNameLabel)
        }
        

        try
        {
            write-verbose " Creating public IP $pipName in resource group $resourceGroupName at location $location" -verbose
            $WEPIP = New-AzureRmPublicIpAddress -ErrorAction Stop @pipParams
            Write-Output " Public IP $pipName was created with DomainName Label $WENewPipDomainNameLabel"
        }
        catch
        {
            $_
            write-warning " Failed to create Public IP $pipName"
        }
    }




    # create new Load Balancer
    foreach($srcLB in $resourceGroupLBs)
    {
        $WELBName = $srcLB.name
        $WELBFrontendIpConfigurations = $srcLB.FrontendIpConfigurations
        $WELBInboundNatRules = $srcLB.InboundNatRules
        $WELBBackendAddressPool = $srcLB.BackendAddressPools
        $WELBProbe = $srcLB.Probes
        $WELoadBalancingRule = $srcLB.LoadBalancingRules
        $WELBInboundNatPool = $srcLB.InboundNatPools
        $subnet = $null
        $vnet = $null

        # add IP Configs
        [array]$newLBipConfigs = @()

        foreach($WELBipConfig in $WELBFrontendIpConfigurations) 
        {
            $newLBipConfig = $null
              
            $WELBipConfigName =  $WELBipConfig.name
            $lbConfigParams = @{" Name" = $WELBipConfigName} 

            # get new vnet and subnet from old vnet and subnet names
            if($WELBipConfig.Subnet) 
            {
                $subsplit = $WELBipConfig.Subnet.id.split('/')
                $subnetName = $subsplit[$subsplit.Length -1]
                $vnetName = $subsplit[$subsplit.Length -3]
                $subnet = $null
                $vnet = $null
                try
                {
                  $vnet = Get-AzureRmVirtualNetwork -name $vnetName -ResourceGroupName $resourceGroupName -ea Stop -wa SilentlyContinue
                  $subnet = $vnet | Get-AzureRmVirtualNetworkSubnetConfig -ErrorAction Stop  -Name $subnetName -ea Stop -wa SilentlyContinue
                }
                catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}

                $lbConfigParams.Add(" SubnetId" , $subnet.id)
            }

            # add PublicIpAddress if present.
            if($WELBipConfig.PublicIpAddress) 
            {
                $lbPubIPSplit = $WELBipConfig.PublicIpAddress.id.split('/')
                $lbPubIPName = $lbPubIPSplit[$lbPubIPSplit.Length -1]
            
                try
                {
                  $lbPubIP = Get-AzureRmPublicIpAddress -Name $lbPubIPName -ResourceGroupName $resourceGroupName -ea Stop -wa SilentlyContinue
                }
                catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
                
                if($lbPubIP)
                {
                  $lbConfigParams.Add(" PublicIpAddress" , $lbPubIP) 
                }
            }
            
            if($WELBipConfig.PrivateIpAddress) 
            {
              $lbConfigParams.Add(" PrivateIpAddress" , $WELBipConfig.PrivateIpAddress)  
            }   


            #create  new FrontendIPConfig
            try
              {
                write-verbose " Adding IP config $WELBipConfigName to load balancer $lbName" -verbose
                $newLBipConfig = New-AzureRmLoadBalancerFrontendIpConfig -ErrorAction Stop @lbConfigParams -ea Stop -wa SilentlyContinue 
                Write-Output " IP config $WELBipConfigName for $lbName was added"
              }
              catch
              {
                $_
                write-warning " Failed to add IP config $WELBipConfigName to load balancer $lbName"
              } 
                    
             # add other attributes
            if($WELBipConfig.PrivateIpAllocationMethod) 
            {
              $newLBipConfig.PrivateIpAllocationMethod = $WELBipConfig.PrivateIpAllocationMethod 
            }

             # add InboundNATruleConfigs
            if($newLBipConfig -and $WELBipConfig.InboundNatRules)
            {
                foreach($WEInboundNatRuleID in $WELBipConfig.InboundNatRules.ID) 
                {
                    $newNatRuleConfig = $null
                    $WEInboundNatRule = $WELBInboundNatRules | Where-Object{$_.ID -eq $WEInboundNatRuleID}
                    
                    $inboundNatRuleParams = @{
                        " Name" = $WEInboundNatRule.name
                        " FrontendIpConfiguration" = $newLBipConfig
                        " Protocol" = $WEInboundNatRule.Protocol
                        " FrontendPort" = $WEInboundNatRule.FrontEndPort
                        " BackendPort" = $WEInboundNatRule.BackendPort
                    }

                    if($WEInboundNatRule.EnableFloatingIP)
                    {
                        $inboundNatRuleParams.Add(" EnableFloatingIP" , $null)
                    }
                    
                    $newNatRuleConfig = New-AzureRmLoadBalancerInboundNatRuleConfig -ErrorAction Stop @inboundNatRuleParams  
                        
                    if($newNatRuleConfig)
                    {
                    [array]$newNatRuleConfigs = $newNatRuleConfigs + $newNatRuleConfig
                    }
               }
            }

            if($newLBipConfig)
            {
     
              [array]$newLBipConfigs = $newLBipConfigs + $newLBipConfig 
            }


        }

        $WELBparams = @{
        " Name" = $WELBName 
        " ResourceGroupName" = $resourceGroupName
        " Location" = $location 
        }

        if($newLBipConfigs)
        {
         $WELBparams.Add(" FrontendIpConfiguration" , $newLBipConfigs)
        }

        if($newNatRuleConfigs)
        {
         $WELBparams.Add(" InboundNatRule" , $newNatRuleConfigs)
        }
         
        try
        {
            write-verbose " Creating load balancer $WELBName in resource group $resourceGroupName at location $location" -verbose
            $WENewLB = New-AzureRmLoadBalancer -ErrorAction Stop @LBparams -ea Stop -wa SilentlyContinue
            Write-Output " Load balancer $WELBName was created"
        }
        catch
        {
            $_
            write-warning " Failed to create load balancer $WELBName"
        } 

               
            
        if($WELBBackendAddressPool -and $WENewLB) 
        {
            $WENewLB | Add-AzureRmLoadBalancerBackendAddressPoolConfig -Name $WELBBackendAddressPool.Name -ea Stop -wa SilentlyContinue | out-null
        }
        
        if($WELBProbe -and $WENewLB) 
        {
            # TODO:        
            #   $WENewLB | Add-AzureRmLoadBalancerProbeConfig -Name $WELBProbe.Name  -RequestPath -Protocol -Port -IntervalInSeconds -ProbeCount | out-null
        }
        
            
        if($WELoadBalancingRule -and $WENewLB) 
        {
            # TODO:
            #$WENewLB | Add-AzureRmLoadBalancerRuleConfig -Name $WELoadBalancingRule.Name -ea Stop -wa SilentlyContinue | out-null
        }

        if($WELBInboundNatPool -and $WENewLB) 
        {
            # TODO:
            # $WENewLB |Add-AzureRmLoadBalancerInboundNatPoolConfig -Name $WELBInboundNatPool.Name  -ea Stop -wa SilentlyContinue | out-null
        }  
            
        if($WENewLB) 
        {    
            try
            {
                $WENewLB | Set-AzureRmLoadBalancer -ea Stop -wa SilentlyContinue | out-null
            }
            catch
            {
                $_
                write-warning " Failed to update load balancer $WELBName"
                $WENewLB
            }
        }
        
    } # end of foreach loadbalancer



    # create new NICs
    foreach($srcNIC in $resourceGroupNICs)
    {
        $WENicName = $srcNIC.name
        $oldIPconfigs = $srcNIC.IpConfigurations
        $WENicDNS = $srcNIC.DnsSettings.AppliedDnsServers

        # add IP Configs
        [array]$WENewIpConfigs = @()

        foreach($ipConfig in $oldIPconfigs) 
        {

            $ipConfigName =  $ipConfig.name

            # get new vnet and subnet from old vnet and subnet names
            if($ipconfig.Subnet)
            {
                $subsplit = $ipconfig.Subnet.id.split('/')
                $subnetName = $subsplit[$subsplit.Length -1]
                $vnetName = $subsplit[$subsplit.Length -3]
                $subnet = $null
                $vnet = $null
                try
                {
                    $vnet = Get-AzureRmVirtualNetwork -name $vnetName -ResourceGroupName $resourceGroupName -ea Stop -wa SilentlyContinue
                    $subnet = $vnet | Get-AzureRmVirtualNetworkSubnetConfig -ErrorAction Stop  -Name $subnetName -ea Stop -wa SilentlyContinue
               
                }
                catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
            }

            $ipConfigParams = @{
            " Name" = $ipConfigName
            " PrivateIpAddressVersion" = $ipConfig.PrivateIpAddressVersion
            " PrivateIpAddress" = $ipConfig.PrivateIpAddress
            }

            # add subnet if present.
            if($subnet) 
            {
                $ipConfigParams.Add( " Subnet" , $subnet)
            }
            
            # add public IP if present.
            if($ipConfig.PublicIpAddress) 
            {
                $ipipsplit = $ipConfig.PublicIpAddress.id.split('/')
                $ipipName = $ipipsplit[$ipipsplit.Length -1]
                $WEPublicIP = Get-AzureRmPublicIpAddress -Name $ipipName -ResourceGroupName $WEResourceGroupName
                $ipConfigParams.Add(" PublicIpAddress" , $WEPublicIP)
            }

            # add LoadBalancerBackendAddressPools if present.
            if($ipConfig.LoadBalancerBackendAddressPools) 
            {
                $lbbesplit = $ipconfig.LoadBalancerBackendAddressPools.id.split('/')
                $lbbeName = $lbbesplit[$lbbesplit.Length -1]
                $lbName = $lbbesplit[$lbbesplit.Length -3]
                try
                {
                $lb = Get-AzureRmLoadBalancer -name $lbName -ResourceGroupName $resourceGroupName -ea Stop -wa SilentlyContinue
                    $lbbe = $lb | Get-AzureRmLoadBalancerBackendAddressPoolConfig -Name $lbbeName -ea Stop -wa SilentlyContinue
                }
                catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
                
                if($lbbe){ $ipConfigParams.Add(" LoadBalancerBackendAddressPool" , $lbbe) }
            }
            
            # add LoadBalancerInboundNatRules if present.
            if($ipConfig.LoadBalancerInboundNatRules) 
            {
                $lbINRsplit = $ipconfig.LoadBalancerInboundNatRules.id.split('/')
                $lbINRName = $lbINRsplit[$lbINRsplit.Length -1]
                $lbName = $lbINRsplit[$lbINRsplit.Length -3]
                try
                {
                    $lb = Get-AzureRmLoadBalancer -name $lbName -ResourceGroupName $resourceGroupName -ea Stop -wa SilentlyContinue
                    $lbINR = $lb | Get-AzureRmLoadBalancerInboundNatRuleConfig -Name $lbINRName -ea Stop -wa SilentlyContinue
                }
                catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
            
                if($lbINR){$ipConfigParams.Add(" LoadBalancerInboundNatRule" , $lbINR)}
            }
            
            # add ApplicationGatewayBackendAddressPools if present.
            # TODO:  need to very this can be added as is
            if($ipConfig.ApplicationGatewayBackendAddressPools) 
            {
                $ipConfigParams.Add(" ApplicationGatewayBackendAddressPool" , $ipConfig.ApplicationGatewayBackendAddressPools)
            }



            try
            {
                write-verbose " Adding IP config $ipConfigName to network interface $WENicName" -verbose
                $WENewIpConfig = New-AzureRmNetworkInterfaceIpConfig -ErrorAction Stop @ipConfigParams -ea Stop -wa SilentlyContinue 
                [array]$WENewIpConfigs = $WENewIpConfigs + $WENewIpConfig                
                Write-Output " IP config $ipConfigName for $WENicName was added"
            }
            catch
            {
                $_
                write-warning " Failed to add IP config $ipConfigName to network interface $WENicName"
            } 

        }

        if(! $WENewIpConfigs)
        {
            $WENewIpConfigs = New-AzureRmNetworkInterfaceIpConfig -Name 'empty'
        }
        
        $WENICparams = @{
        " Name" = $WENicName
        " ResourceGroupName" = $resourceGroupName
        " Location" = $location
        " IpConfiguration" = $WENewIpConfigs
        }
        
        # add DNS if present.
        if($WENicDNS) 
        {
            $WENICparams.Add(" DnsServer" , $WENicDNS)
        }


        # add NetworkSecurityGroup if present.
        if($srcNIC.NetworkSecurityGroup) 
        {
            $WENSGsplit = $srcNIC.NetworkSecurityGroup.id.split('/')
            $srcNSGname = $WENSGsplit[$WENSGsplit.Length -1]
            
            try
            { 
                $newNSG = Get-AzureRmNetworkSecurityGroup -Name $srcNSGname -ResourceGroupName $WEResourceGroupName
                $WENICparams.Add(" NetworkSecurityGroup" , $newNSG)
            }
            catch
            {
                write-warning " Failed to add Network Security Group $srcNSGname to network interface $WENicName"
            }
        }

        # add EnableIPForwarding if present.
        # TODO:  need to verify this switch can be splatted with explicit value of $true
        if($srcNIC.EnableIPForwarding) 
        {
            $WENICparams.Add(" EnableIPForwarding" , $true)
        }

        
        try
        {
            write-verbose " Creating network interface $WENicName in resource group $resourceGroupName at location $location" -verbose
            $WENewNIC = New-AzureRmNetworkInterface -ErrorAction Stop @NICparams -ea Stop -wa SilentlyContinue
            Write-Output " Network interface $WENicName was created"
        }
        catch
        {
            $_
            write-warning " Failed to create network interface $WENicName"
        } 

    } # end of foreach nic


    # for some reason vmSizes do not convert to json with the rest of the vm data so this step is required
    [array]$sourceVmSizeObjects = $()

    foreach($vm in $resourceGroupVMs)
    { 

        $WEPSobjVmSize = New-Object -TypeName PSObject
        $WEPSobjVmSize | Add-Member -MemberType NoteProperty -Name VmName -Value $vm.Name
        $WEPSobjVmSize  | Add-Member -MemberType NoteProperty -Name VmSize -Value $vm.HardwareProfile.VmSize.ToString()

        [array]$sourceVMSizeObjects = $sourceVMSizeObjects + $WEPSobjVmSize
    }

    $sourceVMSizeObjects | ConvertTo-Json -depth 10 | Out-File $resourceGroupVMSizeresumePath
    $resourceGroupVMs | ConvertTo-Json -depth 10 | Out-File $resourceGroupVMresumePath
    $WEVHDstorageObjects | ConvertTo-Json | Out-File $WEVHDstorageObjectsResumePath

    # monitor file copy - do not proceed with VM creation until it is complete.  Allows for user to break out and use -resume switch 
    # only applies when VHD blobs are present
    if($WEVHDstorageObjects)
    {
        $WEVHDstorageObjects | ConvertTo-Json | Out-File $WEVHDstorageObjectsResumePath

        $WEVHDstorageObjects | Select-Object -Property destStorageContext -Unique | %{
    
            $containers = Get-AzureStorageContainer -Context $_.destStorageContext 
            
            foreach($container in $containers)
            {
                # monitor disk copy
                Get-BlobCopyStatus -Context $_.destStorageContext -containerName $container.name
            }
        }

    }
} 
else # if not resume
{

    # check for valid source resource group
    if(-not ($targetResourceGroup = Get-AzureRmResourceGroup -ErrorAction Stop  -ResourceGroupName $resourceGroupName)) 
    {
       write-warning " The provided resource group $resourceGroupName could not be found. Exiting the script."
       break
    }
    
    [string] $location = $targetResourceGroup.location

    
    try
    {
        $resourceGroupVMs = (get-content -ErrorAction Stop $resourceGroupVMresumePath -ea Stop) -Join " `n" | ConvertFrom-Json 
        $resourceGroupVMSizes = (get-content -ErrorAction Stop $resourceGroupVMSizeresumePath -ea Stop) -Join " `n" | ConvertFrom-Json 
    } 
    catch
    {
        $_
        write-warning " Failed to load resume file $resourceGroupVMresumePath  Cannot resume. Exiting script."
    }

    try 
    {
        $WEVHDstorageObjects = (get-content -ErrorAction Stop $WEVHDstorageObjectsResumePath -ea Stop) -Join " `n" | ConvertFrom-Json 
    }
    catch
    {
        $_
        write-warning " Failed to load resume file $WEVHDstorageObjectsResumePath  Cannot resume. Exiting script."
    }
}


if($resourceGroupVMs.storageprofile.osdisk.manageddisk -and $location -ne $srcLocation)
{
 
    foreach($mdObj in $WEVHDstorageObjects|Where-Object{$_.srcSkuName -ne 'NULL'})
    {
        # refresh the storage context object if -resume
        if($resume)
        {
            $tempStorageContext =  $mdObj.destStorageContext 
            $tempStorageAccountName = $tempStorageContext.StorageAccountName
            $WEStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $tempStorageAccountName).Value[0]
            $tempStorageContext = New-AzureStorageContext -StorageAccountName $tempStorageAccountName -StorageAccountKey $WEStorageAccountKey
        }
        
        $mdTempContainerName = (Get-AzureStorageContainer -Context $tempStorageContext).Name
        $srcMDuri = $mdObj.srcURI
        $srcMDname = $mdObj.srcName
        $srcSkuName = $mdObj.srcSkuName

        Get-BlobCopyStatus -Context $tempStorageContext -containerName $mdTempContainerName -BlobName $srcMDname
        
        write-verbose " Creating new managed disk $srcMDname in $location" -Verbose
        try
        {
            $mdiskconfig = New-AzureRmDiskConfig -SkuName $srcSkuName -Location $location  -CreateOption Import -SourceUri $srcMDuri 
            $newMDdisk = New-AzureRmDisk -ResourceGroupName $resourceGroupName -Disk $mdiskconfig -DiskName $srcMDname 
            write-output " The managed disk $srcMDname was created."
        }
        catch
        {
            $_
            write-warning " Failed to create new managed disk $srcMDname"
        }
        
    }

    #cleanup
    write-verbose " All managed disks have been created. Removing temporary storage account $tempStorageAccountName" -Verbose
    Remove-AzureRmStorageAccount -ResourceGroupName $WEResourceGroupName -Name $tempStorageAccountName -Force | out-null
    Write-output " The storage account $tempStorageAccountName was removed" 
  
}

<###############################

 Create new Virtual Machines.  





foreach($srcVM in $resourceGroupVMs)
{
    # get source VM attributes
    $WEVMName = $srcVM.Name
    $WEOSDiskName = $srcVM.StorageProfile.OsDisk.Name
    $WEOSType = $srcVM.storageprofile.osdisk.OsType
    $WEOSDiskCaching = $srcVM.StorageProfile.OsDisk.Caching
    $WECreateOption = " Attach"
    if($resume)
    {  
        $WEVMSize = ($resourceGroupVMSizes | Where-Object {$_.VMname -eq $WEVMName}).VmSize
    }
    else 
    {
        $WEVMSize = $srcVM.HardwareProfile.VMSize
    }

    if($srcVM.AvailabilitySetReference)
    {
        $avSetRef = ($srcVM.AvailabilitySetReference.id).Split('/')
        $avSetName = $avSetRef[($avSetRef.count -1)]
        $WEAvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $WEResourceGroupName -Name $avSetName
    }

    Write-Output " Verifying specified VM Size of $vmSize for location $location ..."
    # Prompt for to select new if doesn't exist in current environment.
    $savedVMSize = $vmSize 
    if($vmSize  -and (Get-AzureRmVMSize -Location $WELocation).name -notcontains $vmSize) 
    {
      write-warning " $savedVMSize is an invalid Azure Virtual Machine Size for this location in this environment.  Please select a valid VM Size and click OK"
      $vmSize = (Get-AzureRmVMSize -Location $WELocation | Select-Object Name, NumberOfCores, MemoryInMB, MaxDataDiskCount | Out-GridView -Title " Select Azure VM Size" -OutputMode Single).Name
    }
   
   
    # get blob and container names from source URI for blobs
    if($srcVM.storageprofile.osdisk.vhd)
    {
        # get blob and container names from source URI
        $WEOSsrcURI = $srcVM.storageprofile.osdisk.vhd.uri
        $WEOSsplit = $WEOSsrcURI.Split('/')
        # TODO: assumes one level of container.  need to adjust to allow for something like container/myfolder/vhdfolder
        $WEOSblobName = $WEOSsplit[($WEOSsplit.count -1)]
        $WEOScontainerName = $WEOSsplit[3]
        # get the new destination storage account name from our custom object array
        $WEOSstorageContext = ($WEVHDstorageObjects| Where-Object{$_.srcURI -eq $WEOSsrcURI} | Select-Object -Property destStorageContext -Unique).destStorageContext
        # refresh the storage context object if -resume
        if($resume)
        {
        $osStorageAccountName = $WEOSstorageContext.StorageAccountName
        $WEStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $osStorageAccountName).Value[0]
        $WEOSstorageContext = New-AzureStorageContext -StorageAccountName $osStorageAccountName -StorageAccountKey $WEStorageAccountKey
        }
        
        # set the OSdisk URI
        $WEOSDiskUri = " $($WEOSstorageContext.BlobEndPoint)$WEOScontainerName/$WEOSblobName"
    
        # verify disk copy
        Get-BlobCopyStatus -Context $WEOsStorageContext -containerName $WEOScontainerName -BlobName $WEOsBlobName 
    }

    # get the Network Interface Card we created previously based on the original source name
    $newNICs = @()
    foreach($nicID in $srcVM.NetworkProfile.NetworkInterfaces.id)
    {
        $WENICRef = $nicID.Split('/')
        $WENICName = $WENICRef[($WENICRef.count -1)]
        $newNICs = $newNICs + Get-AzureRmNetworkInterface -Name $WENICName -ResourceGroupName $WEResourceGroupName 
    }
    
    
    # create VM Config
    if($WEAvailabilitySet)
    {
        $WEVirtualMachine = New-AzureRmVMConfig -VMName $WEVMName -VMSize $WEVMSize  -AvailabilitySetID $WEAvailabilitySet.Id  -wa SilentlyContinue
    }
    else
    {
        $WEVirtualMachine = New-AzureRmVMConfig -VMName $WEVMName -VMSize $WEVMSize -wa SilentlyContinue 
    }
    
    if($srcVM.storageprofile.osdisk.vhd)
    {
       # Set OS Disk based on OS type
        if($WEOStype -eq 'Windows' -or $WEOStype -eq '0')
        {
            $WEVirtualMachine = Set-AzureRmVMOSDisk -VM $WEVirtualMachine -Name $WEOSDiskName -VhdUri $WEOSDiskUri -Caching $WEOSDiskCaching -CreateOption $createOption -Windows
        }
        else
        {
            $WEVirtualMachine = Set-AzureRmVMOSDisk -VM $WEVirtualMachine -Name $WEOSDiskName -VhdUri $WEOSDiskUri -Caching $WEOSDiskCaching -CreateOption $createOption -Linux
        }
    }
    elseif($srcVM.storageprofile.osdisk.manageddisk)
    {
        $osMDisk = Get-AzureRmDisk -DiskName $WEOSDiskName -ResourceGroupName $resourceGroupName
        $osDiskId = $osMDisk.id
        $osDiskSkuName= $osMDisk.Sku.Name

        if($WEOStype -eq 'Windows' -or $WEOStype -eq '0')
        {
            $WEVirtualMachine = Set-AzureRmVMOSDisk -VM $WEVirtualMachine -Name $WEOSDiskName -ManagedDiskId $osDiskId -StorageAccountType $osDiskSkuName -Caching $WEOSDiskCaching -CreateOption $createOption -Windows
        }
        else
        {
            $WEVirtualMachine = Set-AzureRmVMOSDisk -VM $WEVirtualMachine -Name $WEOSDiskName -ManagedDiskId $osDiskId -StorageAccountType $osDiskSkuName -Caching $WEOSDiskCaching -CreateOption $createOption -Linux
        }
    }

      # add NICs
    foreach($WENIC in $newNICs)
    {
        $WEVirtualMachine = Add-AzureRmVMNetworkInterface -VM $WEVirtualMachine -Id $WENIC.Id
    }


    # add data disk if they were present
    if($srcVM.storageProfile.datadisks)
    {
        foreach($disk in $srcVM.storageProfile.DataDisks) 
        {
            $dataDiskName = $null
            $srcURI = $null
            $blobName = $null
            $dataDiskName = $disk.Name
            $dataDiskLUN = $disk.Lun
            $diskCaching = $disk.Caching
            $WEDiskSizeGB = $disk.DiskSizeGB
            
            if($disk.vhd)
            { 
                $srcDiskURI = $disk.vhd.uri
                $split = $srcDiskURI.Split('/')
                # TODO: assumes one level of container.  need to adjust to allow for something like container/myfolder/vhdfolder
                $diskBlobName = $split[($split.count -1)]
                $diskContainerName = $split[3]
                # get the new destination storage account name from our custom object array
                $diskStorageContext = ($WEVHDstorageObjects| Where-Object{$_.srcURI -eq $srcDiskURI} | Select-Object -Property destStorageContext -Unique).destStorageContext
                # refresh the storage context object if -resume
                if($resume)
                {
                    $diskStorageAccountName = $diskStorageContext.StorageAccountName
                    $WEStorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $diskStorageAccountName).Value[0]
                    $diskStorageContext = New-AzureStorageContext -StorageAccountName $diskStorageAccountName -StorageAccountKey $WEStorageAccountKey
                }

                $dataDiskUri = " $($diskStorageContext.BlobEndPoint)$diskContainerName/$diskBlobName"
            
                # Verify copy status
                Get-BlobCopyStatus -Context $diskStorageContext -containerName $diskContainerName -BlobName $diskBlobName
             
            }
                
            # determine if managed disk are used and use apppropiate attach method 
	        if($disk.vhd)
            {
                Add-AzureRmVMDataDisk -VM $WEVirtualMachine -Name $dataDiskName -DiskSizeInGB $WEDiskSizeGB -Lun $dataDiskLUN -VhdUri $dataDiskUri -Caching $diskCaching -CreateOption $WECreateOption | out-null
            }
            elseif($disk.manageddisk)
            {
                $mdDataDisk = Get-AzureRmDisk -ResourceGroupName $resourceGroupName -DiskName $dataDiskName
                 # Write-Information ('Disk Provisioning State -> [ ' + ($mdDataDisk.ProvisioningState) + ' ]')
                ;  $dataDiskId = $mdDataDisk.id
                ;  $dataDiskSku = $mdDataDisk.sku.Name

                Add-AzureRmVMDataDisk -VM $WEVirtualMachine -Name $dataDiskName -Lun $dataDiskLUN -ManagedDiskId $dataDiskId -StorageAccountType $dataDiskSku -Caching $diskCaching -CreateOption $WECreateOption | out-null
            }        
        }
    }
     
    # create the VM from the config
    try
    {
        
        write-verbose " Creating Virtual Machine $WEVMName in resource group $resourceGroupName at location $location" -verbose
       # $WEVirtualMachine
        New-AzureRmVM -ResourceGroupName $WEResourceGroupName -Location $location -VM $WEVirtualMachine -ea Stop -wa SilentlyContinue | out-null
        write-output " Successfully created Virtual Machine $WEVMName"
    }
    catch
    {
         $_
         write-warning " Failed to create Virtual Machine $WEVMName"
    }
}





# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
