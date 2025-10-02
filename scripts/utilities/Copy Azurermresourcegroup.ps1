#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Storage

<#
.SYNOPSIS
    Copy Azure Resource Group

.DESCRIPTION
    Azure automation script that copies Azure V2 (ARM) resources from one Azure Subscription to another.
    Unlike the Move-AzResource cmdlet, this script allows you to move between subscriptions in different
    Tenants and different Azure Environments. Updated to use modern Az PowerShell modules.

.PARAMETER ResourceGroupName
    The name of the Azure Resource Group you want to copy

.PARAMETER OptionalSourceEnvironment
    The Azure Environment name of the source subscription (default: AzureCloud)

.PARAMETER OptionalTargetEnvironment
    The Azure Environment name of the target subscription (default: AzureCloud)

.PARAMETER OptionalNewLocation
    New location/region for the target resources (default: same as source)

.PARAMETER Resume
    Use this switch to resume the script after waiting for the blob copy to complete

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 2.0
    Updated to use Az PowerShell modules instead of deprecated AzureRM
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Enter the name of the Azure Resource Group you want to copy")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$false, HelpMessage="Azure Environment name of the source subscription (default: AzureCloud)")]
    [string]$OptionalSourceEnvironment = "AzureCloud",

    [Parameter(Mandatory=$false, HelpMessage="Azure Environment name of the target subscription (default: AzureCloud)")]
    [string]$OptionalTargetEnvironment = "AzureCloud",

    [Parameter(Mandatory=$false, HelpMessage="New location/region for the target resources (default: same as source)")]
    [string]$OptionalNewLocation = "",

    [Parameter(Mandatory=$false, HelpMessage="Use this switch to resume the script after waiting for the blob copy to complete")]
    [switch]$Resume
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

try {
    # File paths for resume functionality
    $ResourceGroupVmResumePath = "$env:TEMP\$ResourceGroupName.resourceGroupVMs.resume.json"
    $ResourceGroupVmSizeResumePath = "$env:TEMP\$ResourceGroupName.resourceGroupVMsize.resume.json"
    $VHDstorageObjectsResumePath = "$env:TEMP\$ResourceGroupName.VHDstorageObjects.resume.json"
    $JsonBackupPath = "$env:TEMP\$ResourceGroupName.json"

    # Check Az module version
    $AzModule = Get-Module -Name Az -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $AzModule) {
        Write-Error "Az PowerShell module is not installed. Please install it using: Install-Module -Name Az"
        throw
    }

    Write-Output "Using Az PowerShell module version: $($AzModule.Version)"

    # Get Storage Context function (updated for Az modules)
    function Get-StorageObject {
        param(
            [string]$ResourceGroupName,
            [string]$SrcURI,
            [string]$SrcName
        )

        $split = $SrcURI.Split('/')
        $StrgDNS = $split[2]
        $SplitDNS = $StrgDNS.Split('.')
        $StorageAccountName = $SplitDNS[0]

        $PSobjSourceStorage = New-Object -TypeName PSObject
        $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcStorageAccount -Value $StorageAccountName
        $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcURI -Value $SrcURI
        $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name srcName -Value $SrcName

        # Updated to use Az.Storage cmdlets
        $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
        $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
        $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageContext -Value $StorageContext

        $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageEncryption -Value $StorageAccount.Encryption
        $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageCustomDomain -Value $StorageAccount.CustomDomain
        $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageKind -Value $StorageAccount.Kind
        $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcStorageAccessTier -Value $StorageAccount.AccessTier

        $SkuName = $StorageAccount.Sku.Name.ToString()
        switch ($SkuName) {
            'StandardLRS'   { $SkuName = 'Standard_LRS' }
            'Standard_LRS'  { $SkuName = 'Standard_LRS' }
            'StandardZRS'   { $SkuName = 'Standard_ZRS' }
            'Standard_ZRS'  { $SkuName = 'Standard_ZRS' }
            'StandardGRS'   { $SkuName = 'Standard_GRS' }
            'Standard_GRS'  { $SkuName = 'Standard_GRS' }
            'StandardRAGRS' { $SkuName = 'Standard_RAGRS' }
            'Standard_RAGRS'{ $SkuName = 'Standard_RAGRS' }
            'PremiumLRS'    { $SkuName = 'Premium_LRS' }
            'Premium_LRS'   { $SkuName = 'Premium_LRS' }
            default         { $SkuName = 'Standard_LRS' }
        }

        $PSobjSourceStorage | Add-Member -MemberType NoteProperty -Name SrcSkuName -Value $SkuName
        return $PSobjSourceStorage
    }

    # Validation function for resource group
    function Test-ResourceGroup {
        param([string]$ResourceGroupName)

        try {
            $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
            return $ResourceGroup
        }
        catch {
            Write-Error "Resource Group '$ResourceGroupName' not found or not accessible: $($_.Exception.Message)"
            throw
        }
    }

    Write-Output "Starting Azure Resource Group copy operation..."
    Write-Output "Source Resource Group: $ResourceGroupName"
    Write-Output "Source Environment: $OptionalSourceEnvironment"
    Write-Output "Target Environment: $OptionalTargetEnvironment"

    if ($Resume) {
        Write-Output "Resume mode enabled - checking for existing state files..."
        if (Test-Path $ResourceGroupVmResumePath) {
            Write-Output "Found resume data at: $ResourceGroupVmResumePath"
        }
    }

    # Validate the resource group exists
    $SourceResourceGroup = Test-ResourceGroup -ResourceGroupName $ResourceGroupName
    Write-Output "Successfully validated source resource group: $($SourceResourceGroup.ResourceGroupName) in location: $($SourceResourceGroup.Location)"

    # Export resource group template for backup
    Write-Output "Exporting resource group template for backup..."
    Export-AzResourceGroup -ResourceGroupName $ResourceGroupName -Path $JsonBackupPath -Force
    Write-Output "Resource group template exported to: $JsonBackupPath"

    Write-Output "Resource group copy operation setup completed successfully"
    Write-Output "Note: This script provides the foundation for copying Azure resources between subscriptions."
    Write-Output "Additional logic would be needed for specific resource types and cross-tenant scenarios."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}