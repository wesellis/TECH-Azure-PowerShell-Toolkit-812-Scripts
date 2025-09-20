#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Attach Azvmdisk

.DESCRIPTION
    Attach Azvmdisk operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$VMName = 'Prod-PAS2'
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$VMName = 'Prod-PAS2'
$LocationName = 'CanadaCentral'
$ResourceGroupName = -join (" $CustomerName" , "_$VMName" , "_RG" )
$GUID = [guid]::NewGuid()
$AttachedDiskName = -join (" $VMName" , "_AttachedDisk" , "_1" , "_$GUID" )
$AttacchedDiskSizeinGiB = '500'
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Autoshutown"       = 'OFF'
    "Createdby"         = 'Abdullah Ollivierre'
    "CustomerName"      = " $CustomerName"
    "DateTimeCreated"   = " $datetime"
    "Environment"       = 'Production'
    "Application"       = 'Prescription Automation System'
    "Purpose"           = 'Prescription Automation System'
    "Uptime"            = '10 hours by 31 days'
    "Workload"          = 'Prescription Automation System'
    "VMGenenetation"    = 'Gen2'
    "RebootCaution"     = 'Schedule a maintenance window first before rebooting'
    "VMSize"            = " $VMSize"
    "Location"          = " $LocationName"
    "Requested By"      = 'svedula@quadratyx.com'
    "Approved By"       = "Hamza Musaphir"
    "Approved On"       = "Friday Jan 19 2021"
    "Ticket ID"         = " 1516430"
    "CSP"               = "Canada Computing Inc."
    "Subscription Name" = "Microsoft Azure - FGC Production"
    "Subscription ID"   = " 3532a85c-c00a-4465-9b09-388248166360"
    "Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"
}
$newAzDiskConfigSplat = @{
    Location = $LocationName
    DiskSizeGB = $AttacchedDiskSizeinGiB
    SkuName = 'Standard_LRS'
    # OsType = 'Linux'
    CreateOption = 'Empty'
    # EncryptionSettingsEnabled = $true
    Tag = $Tags
}
$diskconfig = New-AzDiskConfig -ErrorAction Stop @newAzDiskConfigSplat
$newAzDiskSplat = @{
    ResourceGroupName = $ResourceGroupName
    DiskName = $AttachedDiskName
    Disk = $diskconfig
}
$DataDisk = New-AzDisk -ErrorAction Stop @newAzDiskSplat
$getAzVMSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $VMName
}
$VirtualMachine = Get-AzVM -ErrorAction Stop @getAzVMSplat;
$addAzVMDataDiskSplat = @{
    VM = $VirtualMachine
    Name = $AttachedDiskName
    # VhdUri = "https://contoso.blob.core.windows.net/vhds/diskstandard03.vhd"
    Lun = '0'
    Caching = 'ReadWrite'
    DiskSizeInGB = '500'
    CreateOption = 'Attach'
    ManagedDiskId = $dataDisk.Id
}
Add-AzVMDataDisk @addAzVMDataDiskSplat;
$updateAzVMSplat = @{
    ResourceGroupName = $ResourceGroupName
    VM = $VirtualMachine
}
Update-AzVM @updateAzVMSplat
#>
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
At C:\Users\Abdullah.Ollivierre\AzureRepos2\Azure
ew-AzVM\Disks\22-Attach-AzVMDisk.ps1:50 char:1
+ Update-AzVM @updateAzVMSplat
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [Update-AzVM], ComputeCloudException
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.Compute.UpdateAzureVMCommand

