#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Deploy Azureresourcegroup

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#Requires -Version 3.0
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string] [Parameter(Mandatory = $true)] $ArtifactStagingDirectory,
    [string] [Parameter(Mandatory = $true)][alias("ResourceGroupLocation" )] $Location,
    [string] $ResourceGroupName = (Split-Path $ArtifactStagingDirectory -Leaf),
    [switch] $UploadArtifacts,
    [string] $StorageAccountName,
    [string] $StorageContainerName = $ResourceGroupName.ToLowerInvariant() + '-stageartifacts',
    [string] $TemplateFile = $ArtifactStagingDirectory + '\mainTemplate.json',
    [string] $TemplateParametersFile = $ArtifactStagingDirectory + '.\azuredeploy.parameters.json',
    [string] $DSCSourceFolder = $ArtifactStagingDirectory + '.\DSC',
    [switch] $BuildDscPackage,
    [switch] $ValidateOnly,
    [string] $DebugOptions = "None" ,
    [string] $DeploymentName = ([IO.Path]::GetFileNameWithoutExtension($TemplateFile) + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')),
    [switch] $Dev
)
try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("AzureQuickStarts-$UI$($host.name)" .replace(" " , "_" ), "1.0" )
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
Set-StrictMode -Version 3
[OutputType([PSObject])]
 {
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $null -ne $_ } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}
$OptionalParameters = New-Object -TypeName Hashtable
$TemplateArgs = New-Object -TypeName Hashtable
$ArtifactStagingDirectory = ($ArtifactStagingDirectory.TrimEnd('/')).TrimEnd('\')
if (!(Test-Path $TemplateFile)) {
    $TemplateFile = $ArtifactStagingDirectory + '\azuredeploy.json'
}
Write-Host "Using template file:  $TemplateFile"
if ($Dev) {
    $TemplateParametersFile = $TemplateParametersFile.Replace('azuredeploy.parameters.json', 'azuredeploy.parameters.dev.json')
    if (!(Test-Path $TemplateParametersFile)) {
        $TemplateParametersFile = $TemplateParametersFile.Replace('azuredeploy.parameters.dev.json', 'azuredeploy.parameters.1.json')
    }
}
Write-Host "Using parameter file: $TemplateParametersFile"
if (!$ValidateOnly) {
    $OptionalParameters.Add('DeploymentDebugLogLevel', $DebugOptions)
}
$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))
$TemplateJSON = Get-Content -ErrorAction Stop $TemplateFile -Raw | ConvertFrom-Json
$TemplateSchema = $TemplateJson | Select-Object -expand '$schema' -ErrorAction Ignore
if ($TemplateSchema -like '*subscriptionDeploymentTemplate.json*') {
    $deploymentScope = "Subscription"
}
else {
    $deploymentScope = "ResourceGroup"
}
Write-Host "Running a $deploymentScope scoped deployment..."
$ArtifactsLocationParameter = $TemplateJson | Select-Object -expand 'parameters' -ErrorAction Ignore | Select-Object -Expand '_artifactsLocation' -ErrorAction Ignore
if ($UploadArtifacts -Or $null -ne $ArtifactsLocationParameter) {
    # Convert relative paths to absolute paths if needed
    $ArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory))
    $DSCSourceFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $DSCSourceFolder))
    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
    $JsonParameters = Get-Content -ErrorAction Stop $TemplateParametersFile -Raw | ConvertFrom-Json
    if (($JsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
        $JsonParameters = $JsonParameters.parameters
    }
    $ArtifactsLocationName = '_artifactsLocation'
    $ArtifactsLocationSasTokenName = '_artifactsLocationSasToken'
    $OptionalParameters[$ArtifactsLocationName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    $OptionalParameters[$ArtifactsLocationSasTokenName] = $JsonParameters | Select-Object -Expand $ArtifactsLocationSasTokenName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    # Create DSC configuration archive
    if ((Test-Path $DSCSourceFolder) -and ($BuildDscPackage)) {
        $DSCSourceFilePaths = @(Get-ChildItem -ErrorAction Stop $DSCSourceFolder -File -Filter '*.ps1' | ForEach-Object -Process { $_.FullName })
        foreach ($DSCSourceFilePath in $DSCSourceFilePaths) {
            $DSCArchiveFilePath = $DSCSourceFilePath.Substring(0, $DSCSourceFilePath.Length - 4) + '.zip'
            Publish-AzureRmVMDscConfiguration $DSCSourceFilePath -OutputArchivePath $DSCArchiveFilePath -Force -Verbose
        }
    }
    # Create a storage account name if none was provided
    if ($StorageAccountName -eq '') {
        $StorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.Id).Replace('-', '').substring(0, 19)
    }
    $StorageAccount = (Get-AzureRmStorageAccount -ErrorAction Stop | Where-Object { $_.StorageAccountName -eq $StorageAccountName })
    # Create the storage account if it doesn't already exist
    if ($null -eq $StorageAccount) {
        $StorageResourceGroupName = 'ARM_Deploy_Staging'
        New-AzureRmResourceGroup -Location " $Location" -Name $StorageResourceGroupName -Force
        $StorageAccount = New-AzureRmStorageAccount -StorageAccountName $StorageAccountName -Type 'Standard_LRS' -ResourceGroupName $StorageResourceGroupName -Location " $Location"
    }
    $ArtifactStagingLocation = $StorageAccount.Context.BlobEndPoint + $StorageContainerName + " /"
    # Generate the value for artifacts location if it is not provided in the parameter file
    if ($OptionalParameters[$ArtifactsLocationName] -eq $null) {
        #if the defaultValue for _artifactsLocation is using the template location, use the defaultValue, otherwise set it to the staging location
        $defaultValue = $ArtifactsLocationParameter | Select-Object -Expand 'defaultValue' -ErrorAction Ignore
        if ($defaultValue -like '*deployment().properties.templateLink.uri*') {
            $OptionalParameters.Remove($ArtifactsLocationName)
        }
        else {
            $OptionalParameters[$ArtifactsLocationName] = $ArtifactStagingLocation
        }
    }
    # Copy files from the local storage staging location to the storage account container
    New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccount.Context -ErrorAction SilentlyContinue *>&1
    $ArtifactFilePaths = Get-ChildItem -ErrorAction Stop $ArtifactStagingDirectory -Recurse -File | ForEach-Object -Process { $_.FullName }
    foreach ($SourcePath in $ArtifactFilePaths) {
        if ($SourcePath -like " $DSCSourceFolder*" -and $SourcePath -like " *.zip" -or !($SourcePath -like " $DSCSourceFolder*" )) {
            #When using DSC, just copy the DSC archive, not all the modules and source files
            $blobName = ($SourcePath -ireplace [regex]::Escape($ArtifactStagingDirectory), "" ).TrimStart(" /" ).TrimStart(" \" )
            Set-AzureStorageBlobContent -File $SourcePath -Blob $blobName -Container $StorageContainerName -Context $StorageAccount.Context -Force
        }
    }
    # Generate a 4 hour SAS token for the artifacts location if one was not provided in the parameters file
    if ($OptionalParameters[$ArtifactsLocationSasTokenName] -eq $null) {
        $OptionalParameters[$ArtifactsLocationSasTokenName] = (New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddHours(4))
    }
    $TemplateArgs.Add('TemplateUri', $ArtifactStagingLocation + (Get-ChildItem -ErrorAction Stop $TemplateFile).Name + $OptionalParameters[$ArtifactsLocationSasTokenName])
    $OptionalParameters[$ArtifactsLocationSasTokenName] = Read-Host -Prompt "Enter secure value" -AsSecureString
}
else {
    $TemplateArgs.Add('TemplateFile', $TemplateFile)
}
$TemplateArgs.Add('TemplateParameterFile', $TemplateParametersFile)
if ($deploymentScope -eq "ResourceGroup" ) {
    if ((Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -ErrorAction SilentlyContinue) -eq $null) {
        New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -Force -ErrorAction Stop
    }
}
if ($ValidateOnly) {
    if ($deploymentScope -eq "Subscription" ) {
        #subscription scoped deployment
$ErrorMessages = Format-ValidationOutput (Test-AzureRmDeployment -Location $Location @TemplateArgs @OptionalParameters)
    }
    else {
        #resourceGroup deployment
$ErrorMessages = Format-ValidationOutput (Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName @TemplateArgs @OptionalParameters)
    }
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {
    if ($deploymentScope -eq "Subscription" ) {
        #subscription scoped deployment
        $params = @{
            ResourceGroupName = $ResourceGroupName @TemplateArgs @OptionalParameters
            ErrorVariable = "ErrorMessages } else { New-AzureRmResourceGroupDeployment"
            Name = $DeploymentName
            Location = $Location @TemplateArgs @OptionalParameters
        }
        New-AzureRmDeployment @params
}


