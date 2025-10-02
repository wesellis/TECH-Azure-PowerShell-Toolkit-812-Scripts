#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Attach Azvmdisk

.DESCRIPTION
    Attach Azvmdisk operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerName,

    [Parameter(Mandatory = $true)]
    [string]$VMName = 'Prod-PAS2',

    [Parameter(Mandatory = $true)]
    [string]$LocationName = 'CanadaCentral',

    [Parameter()]
    [string]$VMSize = 'Standard_D2s_v3',

    [Parameter()]
    [int]$AttachedDiskSizeinGiB = 500,

    [Parameter()]
    [int]$Lun = 0,

    [Parameter()]
    [string]$DiskSku = 'Standard_LRS'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$ResourceGroupName = -join ("$CustomerName" , "_$VMName" , "_RG" )
$GUID = [guid]::NewGuid()
$AttachedDiskName = -join ("$VMName" , "_AttachedDisk" , "_$Lun" , "_$GUID" )
$datetime = [System.DateTime]::Now.ToString("yyyy_MM_dd_HH_mm_ss")

[hashtable]$Tags = @{
    "Autoshutown"       = 'OFF'
    "Createdby"         = 'Abdullah Ollivierre'
    "CustomerName"      = "$CustomerName"
    "DateTimeCreated"   = "$datetime"
    "Environment"       = 'Production'
    "Application"       = 'Prescription Automation System'
    "Purpose"           = 'Prescription Automation System'
    "Uptime"            = '10 hours by 31 days'
    "Workload"          = 'Prescription Automation System'
    "VMGenenetation"    = 'Gen2'
    "RebootCaution"     = 'Schedule a maintenance window first before rebooting'
    "VMSize"            = "$VMSize"
    "Location"          = "$LocationName"
    "Requested By"      = 'svedula@quadratyx.com'
    "Approved By"       = "Hamza Musaphir"
    "Approved On"       = "Friday Jan 19 2021"
    "Ticket ID"         = "1516430"
    "CSP"               = "Canada Computing Inc."
    "Subscription Name" = "Microsoft Azure - FGC Production"
    "Subscription ID"   = "3532a85c-c00a-4465-9b09-388248166360"
    "Tenant ID"         = "e09d9473-1a06-4717-98c1-528067eab3a4"
}

$newAzDiskConfigSplat = @{
    Location = $LocationName
    DiskSizeGB = $AttachedDiskSizeinGiB
    SkuName = $DiskSku
    CreateOption = 'Empty'
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
$VirtualMachine = Get-AzVM -ErrorAction Stop @getAzVMSplat

$addAzVMDataDiskSplat = @{
    VM = $VirtualMachine
    Name = $AttachedDiskName
    Lun = $Lun
    Caching = 'ReadWrite'
    DiskSizeInGB = $AttachedDiskSizeinGiB
    CreateOption = 'Attach'
    ManagedDiskId = $DataDisk.Id
}
Add-AzVMDataDisk @addAzVMDataDiskSplat

$updateAzVMSplat = @{
    ResourceGroupName = $ResourceGroupName
    VM = $VirtualMachine
}
Update-AzVM @updateAzVMSplat