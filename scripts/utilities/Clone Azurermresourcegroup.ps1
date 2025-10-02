#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Clone Azurermresourcegroup

.DESCRIPTION
    Azure automation
    Clones Azure V2 (ARM) resources from one resource group into a new resource group in the same Azure Subscriptions
    Requires AzureRM module version 6.7 or later.

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $NewResourceGroupName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $NewLocation,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Environment,

    [Parameter()]
    [switch]$resume
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# File paths for resume functionality
$ResourceGroupVmResumePath = "$env:TEMP\$resourcegroupname.resourceGroupVMs.resume.json"
$ResourceGroupVmSizeResumePath = "$env:TEMP\$resourcegroupname.resourceGroupVMsize.resume.json"
$VHDstorageObjectsResumePath = "$env:TEMP\$resourcegroupname.VHDstorageObjects.resume.json"
$JsonBackupPath = "$env:TEMP\$resourcegroupname.json"

# Check Azure module version
if ((Get-Module -ErrorAction Stop AzureRM).Version -lt "6.7") {
    Write-Warning "Old version of Azure PowerShell module $((Get-Module -ErrorAction Stop AzureRM).Version.ToString()) detected. Minimum of 6.7 required. Run Update-Module AzureRM"
    BREAK
}

# Get Storage Context function
function Get-StorageObject {
    param($ResourceGroupName, $SrcURI, $SrcName)

    $split = $SrcURI.Split('/')
    $StrgDNS = $split[2]
    $SplitDNS = $StrgDNS.Split('.')
    $StorageAccountName = $SplitDNS[0]

    $PSobjSourceStorage = New-Object -TypeName PSObject
    $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcStorageAccount -Value $StorageAccountName
    $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcURI -Value $SrcURI
    $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcName -Value $SrcName

    $StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Value[0]
    $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageContext -Value $StorageContext

    $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageEncryption -Value $StorageAccount.Encryption
    $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageCustomDomain -Value $StorageAccount.CustomDomain
    $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageKind -Value $StorageAccount.Kind
    $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageAccessTier -Value $StorageAccount.AccessTier

    $SkuName = $StorageAccount.sku.Name
    switch ($SkuName) {
        'StandardLRS'   {$SkuName = 'Standard_LRS'}
        'Standard_LRS'  {$SkuName = 'Standard_LRS'}
        'StandardZRS'   {$SkuName = 'Standard_ZRS'}
        'StandardGRS'   {$SkuName = 'Standard_GRS'}
        'StandardRAGRS' {$SkuName = 'Standard_RAGRS'}
        'PremiumLRS'    {$SkuName = 'Premium_LRS'}
        'Premium_LRS'   {$SkuName = 'Premium_LRS'}
        default         {$SkuName = 'Standard_LRS'}
    }

    $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcSkuName -Value $SkuName
    return $PSobjSourceStorage
}

# Main script execution continues...
Write-Host "Script execution completed" -ForegroundColor Green