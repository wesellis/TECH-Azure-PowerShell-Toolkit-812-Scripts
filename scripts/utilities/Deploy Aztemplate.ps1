#Requires -Version 7.4
#Requires -Modules Az.Storage, Az.Resources, Az.Accounts

<#
.SYNOPSIS
    Deploy Azure Template

.DESCRIPTION
    Azure automation script for deploying ARM templates and Bicep files
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER ArtifactStagingDirectory
    Path to the staging directory containing template artifacts

.PARAMETER Location
    Azure region for deployment

.PARAMETER ResourceGroupName
    Name of the resource group for deployment

.PARAMETER UploadArtifacts
    Switch to upload artifacts to storage

.PARAMETER StorageAccountName
    Name of the storage account for artifacts

.PARAMETER StorageContainerName
    Name of the storage container for artifacts

.PARAMETER TemplateFile
    Path to the ARM template file

.PARAMETER TemplateParametersFile
    Path to the template parameters file

.PARAMETER DSCSourceFolder
    Path to DSC source folder

.PARAMETER BuildDscPackage
    Switch to build DSC packages

.PARAMETER ValidateOnly
    Switch to validate template only

.PARAMETER DebugOptions
    Debug options for deployment

.PARAMETER Mode
    Deployment mode (Incremental or Complete)

.PARAMETER DeploymentName
    Name for the deployment

.PARAMETER ManagementGroupId
    Management group ID for deployment

.PARAMETER Dev
    Switch for development environment

.PARAMETER Bicep
    Switch to indicate Bicep template

.PARAMETER WhatIf
    Switch for WhatIf deployment

.EXAMPLE
    .\Deploy-Aztemplate.ps1 -ArtifactStagingDirectory "C:\Templates" -Location "East US" -ResourceGroupName "MyRG"

.NOTES
    Supports both ARM templates and Bicep files
    Can deploy at various scopes: ResourceGroup, Subscription, ManagementGroup, Tenant
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ArtifactStagingDirectory,

    [Parameter(Mandatory = $true)]
    [Alias("ResourceGroupLocation")]
    [string]$Location,

    [string]$ResourceGroupName = (Split-Path $ArtifactStagingDirectory -Leaf),

    [switch]$UploadArtifacts,

    [string]$StorageAccountName,

    [string]$StorageContainerName = $ResourceGroupName.ToLowerInvariant() + '-stageartifacts',

    [string]$TemplateFile = $ArtifactStagingDirectory + '\mainTemplate.json',

    [string]$TemplateParametersFile = $ArtifactStagingDirectory + '\azuredeploy.parameters.json',

    [string]$DSCSourceFolder = $ArtifactStagingDirectory + '\DSC',

    [switch]$BuildDscPackage,

    [switch]$ValidateOnly,

    [string]$DebugOptions = "None",

    [string]$Mode = "Incremental",

    [string]$DeploymentName = ((Split-Path $TemplateFile -LeafBase) + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')),

    [string]$ManagementGroupId,

    [switch]$Dev,

    [switch]$Bicep,

    [switch]$WhatIf
)

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("AzQuickStarts-$UI$($host.name)".replace(" ", "_"), "1.0")
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}

Set-StrictMode -Version 3

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

function Format-ValidationOutput {
    [CmdletBinding()]
    param($ValidationOutput, [int]$Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $null -ne $_ } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

$OptionalParameters = New-Object -TypeName Hashtable
$TemplateArgs = New-Object -TypeName Hashtable
$ArtifactStagingDirectory = ($ArtifactStagingDirectory.TrimEnd('/')).TrimEnd('\')
$IsBicep = ($Bicep -or $TemplateFile.EndsWith('.bicep'))

if ($IsBicep) {
    $DefaultTemplateFile = '\main.bicep'
} else {
    $DefaultTemplateFile = '\azuredeploy.json'
}

if (!(Test-Path $TemplateFile)) {
    $TemplateFile = $ArtifactStagingDirectory + $DefaultTemplateFile
}

if ($IsBicep) {
    bicep build $TemplateFile
    $TemplateFile = $TemplateFile.Replace('.bicep', '.json')
    $FromBicep = "(from bicep build)"
} else {
    $FromBicep = ""
}

Write-Output "Using template file $($FromBicep): $TemplateFile"

if ($Dev) {
    $TemplateParametersFile = $TemplateParametersFile.Replace('azuredeploy.parameters.json', 'azuredeploy.parameters.dev.json')
    if (!(Test-Path $TemplateParametersFile)) {
        $TemplateParametersFile = $TemplateParametersFile.Replace('azuredeploy.parameters.dev.json', 'azuredeploy.parameters.1.json')
    }
}

Write-Output "Using parameter file: $TemplateParametersFile"

if (!$ValidateOnly) {
    $OptionalParameters.Add('DeploymentDebugLogLevel', $DebugOptions)
    if ($WhatIf) {
        $OptionalParameters.Add('WhatIf', $WhatIf)
    }
}

$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
$TemplateJSON = Get-Content -ErrorAction Stop $TemplateFile -Raw | ConvertFrom-Json
$TemplateSchema = $TemplateJson | Select-Object -expand '$schema' -ErrorAction Ignore

switch -Wildcard ($TemplateSchema) {
    '*tenantDeploymentTemplate.json*' {
        $DeploymentScope = "Tenant"
    }
    '*managementGroupDeploymentTemplate.json*' {
        $DeploymentScope = "ManagementGroup"
    }
    '*subscriptionDeploymentTemplate.json*' {
        $DeploymentScope = "Subscription"
    }
    '*/deploymentTemplate.json*' {
        $DeploymentScope = "ResourceGroup"
        $OptionalParameters.Add('Mode', $Mode)
        if (!$ValidateOnly -and !$WhatIf) {
            $OptionalParameters.Add('Force', $true)
        }
    }
}

Write-Output "Running a $DeploymentScope scoped deployment..."

$ArtifactsLocationName = '_artifactsLocation'
$ArtifactsLocationSasTokenName = '_artifactsLocationSasToken'
$ArtifactsLocationParameter = $TemplateJson | Select-Object -expand 'parameters' -ErrorAction Ignore | Select-Object -Expand $ArtifactsLocationName -ErrorAction Ignore
$ArtifactsLocationSasTokenParameter = $TemplateJson | Select-Object -expand 'parameters' -ErrorAction Ignore | Select-Object -Expand $ArtifactsLocationSasTokenName -ErrorAction Ignore
$UseAbsolutePathStaging = $($null -ne $ArtifactsLocationParameter)

if ($UploadArtifacts -Or $UseAbsolutePathStaging -or $ArtifactsLocationSasTokenParameter) {
    $ArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory))
    $DSCSourceFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $DSCSourceFolder))

    if (Test-Path $TemplateParametersFile) {
        $JsonParameters = Get-Content -ErrorAction Stop $TemplateParametersFile -Raw | ConvertFrom-Json
        if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
            $JsonParameters = $JsonParameters.parameters
        }
    }
    else {
        $JsonParameters = @{ }
    }

    if ($UseAbsolutePathStaging) {
        $OptionalParameters[$ArtifactsLocationName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
        $OptionalParameters[$ArtifactsLocationSasTokenName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationSasTokenName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    }

    if ((Test-Path $DSCSourceFolder) -and ($BuildDscPackage)) {
        $DSCSourceFilePaths = @(Get-ChildItem -ErrorAction Stop $DSCSourceFolder -File -Filter '*.ps1' | ForEach-Object -Process { $_.FullName })
        foreach ($DSCSourceFilePath in $DSCSourceFilePaths) {
            $DSCArchiveFilePath = $DSCSourceFilePath.Substring(0, $DSCSourceFilePath.Length - 4) + '.zip'
            Publish-AzVMDscConfiguration $DSCSourceFilePath -OutputArchivePath $DSCArchiveFilePath -Force -Verbose
        }
    }

    if ($StorageAccountName -eq '') {
        $StorageAccountName = 'stage' + ((Get-AzContext).Subscription.Id).Replace('-', '').substring(0, 19)
    }

    $StorageAccount = (Get-AzStorageAccount -ErrorAction Stop | Where-Object { $_.StorageAccountName -eq $StorageAccountName })

    if ($null -eq $StorageAccount) {
        $StorageResourceGroupName = 'ARM_Deploy_Staging'
        if ((Get-AzResourceGroup -Name $StorageResourceGroupName -Verbose -ErrorAction SilentlyContinue) -eq $null) {
            $ResourcegroupSplat = @{
                Name = $StorageResourceGroupName
                Location = $Location
                ErrorAction = 'Stop'
            }
            New-AzResourceGroup @resourcegroupSplat
        }

        $StorageaccountSplat = @{
            StorageAccountName = $StorageAccountName
            SkuName = 'Standard_LRS'
            ResourceGroupName = $StorageResourceGroupName
            Location = $Location
        }
        New-AzStorageAccount @storageaccountSplat
    }

    if ($StorageContainerName.length -gt 63) {
        $StorageContainerName = $StorageContainerName.Substring(0, 63)
    }

    $ArtifactStagingLocation = $StorageAccount.Context.BlobEndPoint + $StorageContainerName + "/"

    if ($UseAbsolutePathStaging -and $OptionalParameters[$ArtifactsLocationName] -eq $null) {
        $DefaultValue = $ArtifactsLocationParameter | Select-Object -Expand 'defaultValue' -ErrorAction Ignore
        if ($DefaultValue -like '*deployment().properties.templateLink.uri*') {
            $OptionalParameters.Remove($ArtifactsLocationName)
        }
        else {
            $OptionalParameters[$ArtifactsLocationName] = $ArtifactStagingLocation
        }
    }

    New-AzStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context -ErrorAction SilentlyContinue *>&1

    $ArtifactFilePaths = Get-ChildItem -ErrorAction Stop $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process { $_.FullName }
    foreach ($SourcePath in $ArtifactFilePaths) {
        if ($SourcePath -like "$DSCSourceFolder*" -and $SourcePath -like "*.zip" -or !($SourcePath -like "$DSCSourceFolder*")) {
            $BlobName = ($SourcePath -ireplace [regex]::Escape($ArtifactStagingDirectory), "").TrimStart("/").TrimStart("\")
            Set-AzStorageBlobContent -File $SourcePath -Blob $BlobName -Container $StorageContainerName -Context $StorageAccount.Context -Force
        }
    }

    if ($UseAbsolutePathStaging -or $OptionalParameters[$ArtifactsLocationSasTokenName] -eq $null) {
        $SasToken = (New-AzStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddHours(4))
    }

    if ($OptionalParameters[$ArtifactsLocationSasTokenName] -eq $null -and $UseAbsolutePathStaging) {
        $OptionalParameters[$ArtifactsLocationSasTokenName] = Read-Host -Prompt "Enter secure value" -AsSecureString
        $TemplateArgs.Add('TemplateUri', $ArtifactStagingLocation + (Get-ChildItem -ErrorAction Stop $TemplateFile).Name + $SasToken)
    }
    elseif (!$UseAbsolutePathStaging) {
        $OptionalParameters['QueryString'] = $SasToken.TrimStart("?")
        $TemplateArgs.Add('TemplateUri', $ArtifactStagingLocation + (Get-ChildItem -ErrorAction Stop $TemplateFile).Name)
    }
}
else {
    $TemplateArgs.Add('TemplateFile', $TemplateFile)
}

if (Test-Path $TemplateParametersFile) {
    $TemplateArgs.Add('TemplateParameterFile', $TemplateParametersFile)
}

Write-Information ($TemplateArgs | Out-String)
Write-Information ($OptionalParameters | Out-String)

if ($DeploymentScope -eq "ResourceGroup") {
    if ((Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -ErrorAction SilentlyContinue) -eq $null) {
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -Force -ErrorAction Stop
    }
}

if ($ValidateOnly) {
    switch ($DeploymentScope) {
        "ResourceGroup" {
            $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName @TemplateArgs @OptionalParameters)
        }
        "Subscription" {
            $ErrorMessages = Format-ValidationOutput (Test-AzDeployment -Location $Location @TemplateArgs @OptionalParameters)
        }
        "ManagementGroup" {
            $ErrorMessages = Format-ValidationOutput (Test-AzManagementGroupDeployment -Location $Location @TemplateArgs @OptionalParameters)
        }
        "Tenant" {
            $ErrorMessages = Format-ValidationOutput (Test-AzTenantDeployment -Location $Location @TemplateArgs @OptionalParameters)
        }
    }
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {
    $ErrorActionPreference = 'Stop'
    switch ($DeploymentScope) {
        "ResourceGroup" {
            $params = @{
                ResourceGroupName = $ResourceGroupName
                Name = $DeploymentName
                ErrorVariable = "ErrorMessages"
            }
            New-AzResourceGroupDeployment @params @TemplateArgs @OptionalParameters
        }
        "Subscription" {
            $params = @{
                Location = $Location
                Name = $DeploymentName
                ErrorVariable = "ErrorMessages"
            }
            New-AzDeployment @params @TemplateArgs @OptionalParameters
        }
        "ManagementGroup" {
            $params = @{
                Location = $Location
                ManagementGroupId = $ManagementGroupId
                Name = $DeploymentName
                ErrorVariable = "ErrorMessages"
            }
            New-AzManagementGroupDeployment @params @TemplateArgs @OptionalParameters
        }
        "Tenant" {
            $params = @{
                Location = $Location
                Name = $DeploymentName
                ErrorVariable = "ErrorMessages"
            }
            New-AzTenantDeployment @params @TemplateArgs @OptionalParameters
        }
    }

    if ($ErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', '', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message })
        Write-Error "Deployment failed."
    }
}