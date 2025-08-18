<#
.SYNOPSIS
    Deploy Azureresourcegroup

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
    We Enhanced Deploy Azureresourcegroup

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿#Requires -Version 3.0


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string] [Parameter(Mandatory = $true)] $WEArtifactStagingDirectory,
    [string] [Parameter(Mandatory = $true)][alias(" ResourceGroupLocation" )] $WELocation,
    [string] $WEResourceGroupName = (Split-Path $WEArtifactStagingDirectory -Leaf),
    [switch] $WEUploadArtifacts,
    [string] $WEStorageAccountName,
    [string] $WEStorageContainerName = $WEResourceGroupName.ToLowerInvariant() + '-stageartifacts',
    [string] $WETemplateFile = $WEArtifactStagingDirectory + '\mainTemplate.json',
    [string] $WETemplateParametersFile = $WEArtifactStagingDirectory + '.\azuredeploy.parameters.json',
    [string] $WEDSCSourceFolder = $WEArtifactStagingDirectory + '.\DSC',
    [switch] $WEBuildDscPackage,
    [switch] $WEValidateOnly,
    [string] $WEDebugOptions = " None" ,
    [string] $WEDeploymentName = ([IO.Path]::GetFileNameWithoutExtension($WETemplateFile) + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')),
    [switch] $WEDev
)

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent(" AzureQuickStarts-$WEUI$($host.name)" .replace(" " , " _" ), " 1.0" )
} 
catch { }

$WEErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function WE-Format-ValidationOutput {
    

function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

param ($WEValidationOutput, [int] $WEDepth = 0)
    Set-StrictMode -Off
    return @($WEValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $WEDepth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($WEDepth + 1)) })
}

$WEOptionalParameters = New-Object -TypeName Hashtable
$WETemplateArgs = New-Object -TypeName Hashtable
$WEArtifactStagingDirectory = ($WEArtifactStagingDirectory.TrimEnd('/')).TrimEnd('\')


if (!(Test-Path $WETemplateFile)) { 
    $WETemplateFile = $WEArtifactStagingDirectory + '\azuredeploy.json'
}

Write-WELog " Using template file:  $WETemplateFile" " INFO"


if ($WEDev) {
    $WETemplateParametersFile = $WETemplateParametersFile.Replace('azuredeploy.parameters.json', 'azuredeploy.parameters.dev.json')
    if (!(Test-Path $WETemplateParametersFile)) {
        $WETemplateParametersFile = $WETemplateParametersFile.Replace('azuredeploy.parameters.dev.json', 'azuredeploy.parameters.1.json')
    }
}

Write-WELog " Using parameter file: $WETemplateParametersFile" " INFO"

if (!$WEValidateOnly) {
    $WEOptionalParameters.Add('DeploymentDebugLogLevel', $WEDebugOptions)
}

$WETemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WEPSScriptRoot, $WETemplateFile))
$WETemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WEPSScriptRoot, $WETemplateParametersFile))

$WETemplateJSON = Get-Content $WETemplateFile -Raw | ConvertFrom-Json

$WETemplateSchema = $WETemplateJson | Select-Object -expand '$schema' -ErrorAction Ignore

if ($WETemplateSchema -like '*subscriptionDeploymentTemplate.json*') {
    $deploymentScope = " Subscription"
}
else {
    $deploymentScope = " ResourceGroup"
}

Write-WELog " Running a $deploymentScope scoped deployment..." " INFO"

$WEArtifactsLocationParameter = $WETemplateJson | Select-Object -expand 'parameters' -ErrorAction Ignore | Select-Object -Expand '_artifactsLocation' -ErrorAction Ignore


if ($WEUploadArtifacts -Or $WEArtifactsLocationParameter -ne $null) {
    # Convert relative paths to absolute paths if needed
    $WEArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WEPSScriptRoot, $WEArtifactStagingDirectory))
    $WEDSCSourceFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WEPSScriptRoot, $WEDSCSourceFolder))

    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
    $WEJsonParameters = Get-Content $WETemplateParametersFile -Raw | ConvertFrom-Json
    if (($WEJsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
        $WEJsonParameters = $WEJsonParameters.parameters
    }
    $WEArtifactsLocationName = '_artifactsLocation'
    $WEArtifactsLocationSasTokenName = '_artifactsLocationSasToken'
    $WEOptionalParameters[$WEArtifactsLocationName] = $WEJsonParameters | Select-Object -Expand $WEArtifactsLocationName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    $WEOptionalParameters[$WEArtifactsLocationSasTokenName] = $WEJsonParameters | Select-Object -Expand $WEArtifactsLocationSasTokenName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore

    # Create DSC configuration archive
    if ((Test-Path $WEDSCSourceFolder) -and ($WEBuildDscPackage)) {
        $WEDSCSourceFilePaths = @(Get-ChildItem $WEDSCSourceFolder -File -Filter '*.ps1' | ForEach-Object -Process { $_.FullName })
        foreach ($WEDSCSourceFilePath in $WEDSCSourceFilePaths) {
            $WEDSCArchiveFilePath = $WEDSCSourceFilePath.Substring(0, $WEDSCSourceFilePath.Length - 4) + '.zip'
            Publish-AzureRmVMDscConfiguration $WEDSCSourceFilePath -OutputArchivePath $WEDSCArchiveFilePath -Force -Verbose
        }
    }

    # Create a storage account name if none was provided
    if ($WEStorageAccountName -eq '') {
        $WEStorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.Id).Replace('-', '').substring(0, 19)
    }

    $WEStorageAccount = (Get-AzureRmStorageAccount | Where-Object { $_.StorageAccountName -eq $WEStorageAccountName })

    # Create the storage account if it doesn't already exist
    if ($WEStorageAccount -eq $null) {
        $WEStorageResourceGroupName = 'ARM_Deploy_Staging'
        New-AzureRmResourceGroup -Location " $WELocation" -Name $WEStorageResourceGroupName -Force
        $WEStorageAccount = New-AzureRmStorageAccount -StorageAccountName $WEStorageAccountName -Type 'Standard_LRS' -ResourceGroupName $WEStorageResourceGroupName -Location " $WELocation"
    }

    $WEArtifactStagingLocation = $WEStorageAccount.Context.BlobEndPoint + $WEStorageContainerName + " /"   

    # Generate the value for artifacts location if it is not provided in the parameter file
    if ($WEOptionalParameters[$WEArtifactsLocationName] -eq $null) {
        #if the defaultValue for _artifactsLocation is using the template location, use the defaultValue, otherwise set it to the staging location
        $defaultValue = $WEArtifactsLocationParameter | Select-Object -Expand 'defaultValue' -ErrorAction Ignore
        if ($defaultValue -like '*deployment().properties.templateLink.uri*') {
            $WEOptionalParameters.Remove($WEArtifactsLocationName)
        }
        else {
            $WEOptionalParameters[$WEArtifactsLocationName] = $WEArtifactStagingLocation   
        }
    } 

    # Copy files from the local storage staging location to the storage account container
    New-AzureStorageContainer -Name $WEStorageContainerName -Context $WEStorageAccount.Context -ErrorAction SilentlyContinue *>&1

    $WEArtifactFilePaths = Get-ChildItem $WEArtifactStagingDirectory -Recurse -File | ForEach-Object -Process { $_.FullName }
    foreach ($WESourcePath in $WEArtifactFilePaths) {
        
        if ($WESourcePath -like " $WEDSCSourceFolder*" -and $WESourcePath -like " *.zip" -or !($WESourcePath -like " $WEDSCSourceFolder*" )) {
            #When using DSC, just copy the DSC archive, not all the modules and source files
            $blobName = ($WESourcePath -ireplace [regex]::Escape($WEArtifactStagingDirectory), "" ).TrimStart(" /" ).TrimStart(" \" )
            Set-AzureStorageBlobContent -File $WESourcePath -Blob $blobName -Container $WEStorageContainerName -Context $WEStorageAccount.Context -Force
        }
    }
    # Generate a 4 hour SAS token for the artifacts location if one was not provided in the parameters file
    if ($WEOptionalParameters[$WEArtifactsLocationSasTokenName] -eq $null) {
        $WEOptionalParameters[$WEArtifactsLocationSasTokenName] = (New-AzureStorageContainerSASToken -Container $WEStorageContainerName -Context $WEStorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddHours(4))
    }

    $WETemplateArgs.Add('TemplateUri', $WEArtifactStagingLocation + (Get-ChildItem $WETemplateFile).Name + $WEOptionalParameters[$WEArtifactsLocationSasTokenName])

    $WEOptionalParameters[$WEArtifactsLocationSasTokenName] = ConvertTo-SecureString $WEOptionalParameters[$WEArtifactsLocationSasTokenName] -AsPlainText -Force

}
else {

    $WETemplateArgs.Add('TemplateFile', $WETemplateFile)

}

$WETemplateArgs.Add('TemplateParameterFile', $WETemplateParametersFile)


if ($deploymentScope -eq " ResourceGroup" ) {
    if ((Get-AzureRmResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -ErrorAction SilentlyContinue) -eq $null) {
        New-AzureRmResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -Force -ErrorAction Stop
    }
}
if ($WEValidateOnly) {
    if ($deploymentScope -eq " Subscription" ) {
        #subscription scoped deployment
       ;  $WEErrorMessages = Format-ValidationOutput (Test-AzureRmDeployment -Location $WELocation @TemplateArgs @OptionalParameters)
    }
    else {
        #resourceGroup deployment 
       ;  $WEErrorMessages = Format-ValidationOutput (Test-AzureRmResourceGroupDeployment -ResourceGroupName $WEResourceGroupName @TemplateArgs @OptionalParameters)
    }
    if ($WEErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($WEErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {
    if ($deploymentScope -eq " Subscription" ) {
        #subscription scoped deployment
        New-AzureRmDeployment -Name $WEDeploymentName `
            -Location $WELocation `
            @TemplateArgs `
            @OptionalParameters `
            -Verbose `
            -ErrorVariable ErrorMessages
    }
    else {
        New-AzureRmResourceGroupDeployment -Name $WEDeploymentName `
            -ResourceGroupName $WEResourceGroupName `
            @TemplateArgs `
            @OptionalParameters `
            -Force -Verbose `
            -ErrorVariable ErrorMessages
    }
    if ($WEErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', @(@($WEErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd(" `r`n" ) })
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================