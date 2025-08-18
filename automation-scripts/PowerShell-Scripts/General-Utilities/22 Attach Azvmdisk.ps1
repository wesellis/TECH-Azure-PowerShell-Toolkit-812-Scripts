<#
.SYNOPSIS
    22 Attach Azvmdisk

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
    We Enhanced 22 Attach Azvmdisk

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEVMName = 'Prod-PAS2'



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$WEVMName = 'Prod-PAS2'
$WELocationName = 'CanadaCentral'
$WEResourceGroupName = -join (" $WECustomerName" , " _$WEVMName" , " _RG" )
$WEGUID = [guid]::NewGuid()
$WEAttachedDiskName = -join (" $WEVMName" , " _AttachedDisk" , " _1" , " _$WEGUID" )
$WEAttacchedDiskSizeinGiB = '500'


$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Autoshutown"       = 'OFF'
    " Createdby"         = 'Abdullah Ollivierre'
    " CustomerName"      = " $WECustomerName"
    " DateTimeCreated"   = " $datetime"
    " Environment"       = 'Production'
    " Application"       = 'Prescription Automation System'  
    " Purpose"           = 'Prescription Automation System'
    " Uptime"            = '10 hours by 31 days'
    " Workload"          = 'Prescription Automation System'
    " VMGenenetation"    = 'Gen2'
    " RebootCaution"     = 'Schedule a maintenance window first before rebooting'
    " VMSize"            = " $WEVMSize"
    " Location"          = " $WELocationName"
    " Requested By"      = 'svedula@quadratyx.com'
    " Approved By"       = " Hamza Musaphir"
    " Approved On"       = " Friday Jan 19 2021"
    " Ticket ID"         = " 1516430"
    " CSP"               = " Canada Computing Inc."
    " Subscription Name" = " Microsoft Azure - FGC Production"
    " Subscription ID"   = " 3532a85c-c00a-4465-9b09-388248166360"
    " Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"
}

$newAzDiskConfigSplat = @{
    Location = $WELocationName
    DiskSizeGB = $WEAttacchedDiskSizeinGiB
    SkuName = 'Standard_LRS'
    # OsType = 'Linux'
    CreateOption = 'Empty'
    # EncryptionSettingsEnabled = $true
    Tag = $WETags
}

$diskconfig = New-AzDiskConfig -ErrorAction Stop @newAzDiskConfigSplat

$newAzDiskSplat = @{
    ResourceGroupName = $WEResourceGroupName
    DiskName = $WEAttachedDiskName
    Disk = $diskconfig
}
$WEDataDisk = New-AzDisk -ErrorAction Stop @newAzDiskSplat


$getAzVMSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Name = $WEVMName
}
$WEVirtualMachine = Get-AzVM -ErrorAction Stop @getAzVMSplat; 
$addAzVMDataDiskSplat = @{
    VM = $WEVirtualMachine
    Name = $WEAttachedDiskName
    # VhdUri = " https://contoso.blob.core.windows.net/vhds/diskstandard03.vhd"
    Lun = '0'
    Caching = 'ReadWrite'
    DiskSizeInGB = '500'
    CreateOption = 'Attach'
    ManagedDiskId = $dataDisk.Id
}

Add-AzVMDataDisk @addAzVMDataDiskSplat; 
$updateAzVMSplat = @{
    ResourceGroupName = $WEResourceGroupName
    VM = $WEVirtualMachine
}

Update-AzVM @updateAzVMSplat



<#

was getting error

Update-AzVM : Disk Prod-Cassandra1_AttachedDisk_1_c7e193df-8466-472c-9b5a-1e84b293445d already exists in resource group FGCHEALTH_PROD-CASSANDRA1_RG. 
Only CreateOption.Attach is supported.
ErrorCode: ConflictingUserInput
ErrorMessage: Disk Prod-Cassandra1_AttachedDisk_1_c7e193df-8466-472c-9b5a-1e84b293445d already exists in resource group FGCHEALTH_PROD-CASSANDRA1_RG.     
Only CreateOption.Attach is supported.
ErrorTarget: /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCHealth_Prod-Cassandra1_RG/providers/Microsoft.Compute/disks/Prod-Cassa 
ndra1_AttachedDisk_1_c7e193df-8466-472c-9b5a-1e84b293445d
StatusCode: 409
ReasonPhrase: Conflict
OperationID : d2ee44e2-3e14-4aaa-ba9f-6015488a1a7d
At C:\Users\Abdullah.Ollivierre\AzureRepos2\Azure\New-AzVM\Disks\22-Attach-AzVMDisk.ps1:50 char:1
+ Update-AzVM @updateAzVMSplat
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [Update-AzVM], ComputeCloudException
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.Compute.UpdateAzureVMCommand




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================