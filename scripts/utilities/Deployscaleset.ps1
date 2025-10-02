#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Storage, Az.Compute, Az.Network

<#
.SYNOPSIS
    Deploy Scale Set

.DESCRIPTION
    Azure automation script for deploying Virtual Machine Scale Sets with custom images
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER Location
    Azure region for deployment

.PARAMETER ResourceGroupName
    Name of the resource group

.PARAMETER CustomImageStorageAccountName
    Source storage account name for custom image

.PARAMETER CustomImageContainer
    Source container name for custom image

.PARAMETER CustomImageBlobName
    Source blob name for custom image

.PARAMETER NewStorageAccountName
    Name for the new storage account

.PARAMETER NewStorageAccountType
    Type of the new storage account

.PARAMETER NewImageContainer
    New container name for image

.PARAMETER NewImageBlobName
    New blob name for image

.PARAMETER RepoUri
    Repository URI for templates

.PARAMETER StorageAccountTemplate
    Storage account template path

.PARAMETER ScaleSetName
    Name for the scale set

.PARAMETER ScaleSetInstanceCount
    Number of instances in scale set

.PARAMETER ScaleSetVMSize
    VM size for scale set instances

.PARAMETER ScaleSetDNSPrefix
    DNS prefix for scale set

.PARAMETER ScaleSetVMCredentials
    Credentials for scale set VMs

.PARAMETER ScaleSetTemplate
    Scale set template path

.EXAMPLE
    .\Deployscaleset.ps1 -Location "East US" -ResourceGroupName "MyRG" -NewStorageAccountName "mystorageaccount" -NewStorageAccountType "Standard_LRS" -ScaleSetName "MyScaleSet" -ScaleSetVMSize "Standard_B2s" -ScaleSetDNSPrefix "myscaleset"

.NOTES
    Deploys VM Scale Sets with custom images
    Uses modern Az PowerShell modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [string]$CustomImageStorageAccountName = 'sdaviesarmne',

    [string]$CustomImageContainer = 'images',

    [string]$CustomImageBlobName = 'IISBase-osDisk.vhd',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$NewStorageAccountName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$NewStorageAccountType,

    [string]$NewImageContainer = 'images',

    [string]$NewImageBlobName = 'IISBase-osDisk.vhd',

    [string]$RepoUri = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.compute/vmss-windows-customimage/',

    [string]$StorageAccountTemplate = 'templates/storageaccount.json',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ScaleSetName,

    [int]$ScaleSetInstanceCount = 2,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ScaleSetVMSize,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ScaleSetDNSPrefix,

    [PSCredential]$ScaleSetVMCredentials = (Get-Credential -Message 'Enter Credentials for new scale set VMs'),

    [string]$ScaleSetTemplate = 'azuredeploy.json'
)

$ErrorActionPreference = "Stop"

try {
    # Create resource group
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup) {
        Write-Output "Creating resource group: $ResourceGroupName"
        New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $Location -Force
    }

    # Validate storage account name
    $NewStorageAccountName = $NewStorageAccountName.ToLowerInvariant()
    $existingAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $NewStorageAccountName -ErrorAction SilentlyContinue
    if (-not $existingAccount) {
        $nameAvailability = Get-AzStorageAccountNameAvailability -Name $NewStorageAccountName
        if (-not $nameAvailability.NameAvailable) {
            throw "Storage Account Name in use: $($nameAvailability.Reason)"
        }
    }

    # Validate DNS prefix
    $ScaleSetDNSPrefix = $ScaleSetDNSPrefix.ToLowerInvariant()
    $existingPublicIPs = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    $dnsInUse = $existingPublicIPs | Where-Object {
        $_.Location -eq $Location -and $_.DnsSettings.DomainNameLabel -eq $ScaleSetDNSPrefix
    }

    if (-not $dnsInUse) {
        # Check DNS availability (Note: Test-AzDnsAvailability is deprecated, using alternative approach)
        try {
            $dnsCheck = Resolve-DnsName "$ScaleSetDNSPrefix.$Location.cloudapp.azure.com" -ErrorAction SilentlyContinue
            if ($dnsCheck) {
                throw "Scale Set DNS Name in use"
            }
        }
        catch {
            # DNS name is available if resolution fails
        }
    }

    # Deploy storage account
    Write-Output "Deploying storage account: $NewStorageAccountName"
    $storageParameters = @{
        "location" = $Location
        "newStorageAccountName" = $NewStorageAccountName
        "storageAccountType" = $NewStorageAccountType
    }
    $TemplateUri = "$RepoUri$StorageAccountTemplate"
    New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateUri -TemplateParameterObject $storageParameters -Name 'createstorageaccount'

    # Get storage account key
    $storageAccount = Get-AzStorageAccount -Name $NewStorageAccountName -ResourceGroupName $ResourceGroupName
    $destKey = (Get-AzStorageAccountKey -Name $NewStorageAccountName -ResourceGroupName $ResourceGroupName)[0].Value

    # Create storage contexts
    $destContext = New-AzStorageContext -StorageAccountName $NewStorageAccountName -StorageAccountKey $destKey
    $srcContext = New-AzStorageContext -StorageAccountName $CustomImageStorageAccountName -Anonymous

    # Create destination container if it doesn't exist
    $destContainer = Get-AzStorageContainer -Context $destContext -Name $NewImageContainer -ErrorAction SilentlyContinue
    if ($null -eq $destContainer) {
        Write-Output "Creating storage container: $NewImageContainer"
        New-AzStorageContainer -Context $destContext -Name $NewImageContainer -Permission Off
    }

    # Copy blob from source to destination
    Write-Output "Copying custom image blob..."
    $copyBlob = Get-AzStorageBlob -Container $CustomImageContainer -Context $srcContext -Blob $CustomImageBlobName |
        Start-AzStorageBlobCopy -DestContext $destContext -DestContainer $NewImageContainer -DestBlob $NewImageBlobName

    # Wait for copy to complete
    do {
        Start-Sleep -Seconds 10
        $copyStatus = $copyBlob | Get-AzStorageBlobCopyState
        Write-Output "Copy status: $($copyStatus.Status)"
    } while ($copyStatus.Status -eq "Pending")

    if ($copyStatus.Status -ne "Success") {
        throw "Blob copy failed with status: $($copyStatus.Status)"
    }

    # Get source image VHD URI
    $sourceImageBlob = Get-AzStorageBlob -Container $NewImageContainer -Context $destContext -Blob $NewImageBlobName
    $SourceImageVhdUri = $sourceImageBlob.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri

    # Deploy scale set
    Write-Output "Deploying scale set: $ScaleSetName"
    $scaleSetParameters = @{
        "vmSSName" = $ScaleSetName
        "instanceCount" = $ScaleSetInstanceCount
        "vmSize" = $ScaleSetVMSize
        "dnsNamePrefix" = $ScaleSetDNSPrefix
        "adminUsername" = $ScaleSetVMCredentials.UserName
        "adminPassword" = $ScaleSetVMCredentials.GetNetworkCredential().Password
        "location" = $Location
        "sourceImageVhdUri" = $SourceImageVhdUri
    }
    $TemplateUri = "$RepoUri$ScaleSetTemplate"
    New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateUri -TemplateParameterObject $scaleSetParameters -Name 'createscaleset'

    Write-Output "Scale set deployment completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}