<#
.SYNOPSIS
    We Enhanced Deploy Aztemplate

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

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string] [Parameter(Mandatory = $true)] $WEArtifactStagingDirectory,
    [string] [Parameter(Mandatory = $true)][alias("ResourceGroupLocation" )] $WELocation,
    [string] $WEResourceGroupName = (Split-Path $WEArtifactStagingDirectory -Leaf),
    [switch] $WEUploadArtifacts,
    [string] $WEStorageAccountName,
    [string] $WEStorageContainerName = $WEResourceGroupName.ToLowerInvariant() + '-stageartifacts',
    [string] $WETemplateFile = $WEArtifactStagingDirectory + '\mainTemplate.json',
    [string] $WETemplateParametersFile = $WEArtifactStagingDirectory + '.\azuredeploy.parameters.json',
    [string] $WEDSCSourceFolder = $WEArtifactStagingDirectory + '.\DSC',
    [switch] $WEBuildDscPackage,
    [switch] $WEValidateOnly,
    [string] $WEDebugOptions = "None" ,
    [string] $WEMode = "Incremental" ,
    [string] $WEDeploymentName = ((Split-Path $WETemplateFile -LeafBase) + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')),
    [string] $WEManagementGroupId,
    [switch] $WEDev,
    [switch] $bicep,
    [switch] $whatIf
)

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("AzQuickStarts-$WEUI$($host.name)" .replace(" " , "_" ), "1.0" )
}
catch { }

$WEErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function WE-Format-ValidationOutput {
    

function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
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


$isBicep = ($bicep -or $WETemplateFile.EndsWith('.bicep'))
if ($isBicep){
    $defaultTemplateFile = '\main.bicep'
} else {
    $defaultTemplateFile = '\azuredeploy.json'
}


if (!(Test-Path $WETemplateFile)) { 
    $WETemplateFile = $WEArtifactStagingDirectory + $defaultTemplateFile
}


if ($isBicep){
    bicep build $WETemplateFile
    # now point the deployment to the json file that was just build
    $WETemplateFile = $WETemplateFile.Replace('.bicep', '.json')
    $fromBicep = " (from bicep build)"
}else{
    $fromBicep = ""
}

Write-WELog " Using template file $($fromBicep):  $WETemplateFile" " INFO"


if ($WEDev) {
    $WETemplateParametersFile = $WETemplateParametersFile.Replace('azuredeploy.parameters.json', 'azuredeploy.parameters.dev.json')
    if (!(Test-Path $WETemplateParametersFile)) {
        $WETemplateParametersFile = $WETemplateParametersFile.Replace('azuredeploy.parameters.dev.json', 'azuredeploy.parameters.1.json')
    }
}

Write-WELog " Using parameter file: $WETemplateParametersFile" " INFO"

if (!$WEValidateOnly) {
    $WEOptionalParameters.Add('DeploymentDebugLogLevel', $WEDebugOptions)
    if ($whatIf) {
        $WEOptionalParameters.Add('WhatIf', $whatIf)
    }
}

$WETemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WEPSScriptRoot, $WETemplateFile))
$WETemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WEPSScriptRoot, $WETemplateParametersFile))

$WETemplateJSON = Get-Content $WETemplateFile -Raw | ConvertFrom-Json

$WETemplateSchema = $WETemplateJson | Select-Object -expand '$schema' -ErrorAction Ignore

switch -Wildcard ($WETemplateSchema) {
    '*tenantDeploymentTemplate.json*' {
        $deploymentScope = " Tenant"
    }
    '*managementGroupDeploymentTemplate.json*' {
        $deploymentScope = " ManagementGroup"
    }
    '*subscriptionDeploymentTemplate.json*' {
        $deploymentScope = " Subscription"
    }
    '*/deploymentTemplate.json*' {
        $deploymentScope = " ResourceGroup"
        $WEOptionalParameters.Add('Mode', $WEMode)
        if(!$WEValidateOnly -and !$WEWhatIf) {
            $WEOptionalParameters.Add('Force', $true)
        }
    }
}

Write-WELog " Running a $deploymentScope scoped deployment..." " INFO"

$WEArtifactsLocationName = '_artifactsLocation'
$WEArtifactsLocationSasTokenName = '_artifactsLocationSasToken'
$WEArtifactsLocationParameter = $WETemplateJson | Select-Object -expand 'parameters' -ErrorAction Ignore | Select-Object -Expand $WEArtifactsLocationName -ErrorAction Ignore
$WEArtifactsLocationSasTokenParameter = $WETemplateJson | Select-Object -expand 'parameters' -ErrorAction Ignore | Select-Object -Expand $WEArtifactsLocationSasTokenName -ErrorAction Ignore
$useAbsolutePathStaging = $($WEArtifactsLocationParameter -ne $null)


if ($WEUploadArtifacts -Or $useAbsolutePathStaging -or $WEArtifactsLocationSasTokenParameter) {
    # Convert relative paths to absolute paths if needed
    $WEArtifactStagingDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WEPSScriptRoot, $WEArtifactStagingDirectory))
    $WEDSCSourceFolder = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($WEPSScriptRoot, $WEDSCSourceFolder))

    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
    if (Test-Path $WETemplateParametersFile) {
        $WEJsonParameters = Get-Content $WETemplateParametersFile -Raw | ConvertFrom-Json
        if (($WEJsonParameters | Get-Member -Type NoteProperty 'parameters') -ne $null) {
            $WEJsonParameters = $WEJsonParameters.parameters
        }
    }
    else {
        $WEJsonParameters = @{ }
    }
    
    # if using _artifacts* parameters, add them to the optional params and get the value from the param file (if any)
    if ($useAbsolutePathStaging) {
        $WEOptionalParameters[$WEArtifactsLocationName] = $WEJsonParameters | Select-Object -Expand $WEArtifactsLocationName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
        $WEOptionalParameters[$WEArtifactsLocationSasTokenName] = $WEJsonParameters | Select-Object -Expand $WEArtifactsLocationSasTokenName -ErrorAction Ignore | Select-Object -Expand 'value' -ErrorAction Ignore
    }

    # Create DSC configuration archive
    if ((Test-Path $WEDSCSourceFolder) -and ($WEBuildDscPackage)) {
        $WEDSCSourceFilePaths = @(Get-ChildItem $WEDSCSourceFolder -File -Filter '*.ps1' | ForEach-Object -Process { $_.FullName })
        foreach ($WEDSCSourceFilePath in $WEDSCSourceFilePaths) {
            $WEDSCArchiveFilePath = $WEDSCSourceFilePath.Substring(0, $WEDSCSourceFilePath.Length - 4) + '.zip'
            Publish-AzVMDscConfiguration $WEDSCSourceFilePath -OutputArchivePath $WEDSCArchiveFilePath -Force -Verbose
        }
    }

    # Create a storage account name if none was provided
    if ($WEStorageAccountName -eq '') {
        $WEStorageAccountName = 'stage' + ((Get-AzContext).Subscription.Id).Replace('-', '').substring(0, 19)
    }

    $WEStorageAccount = (Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $WEStorageAccountName })

    # Create the storage account if it doesn't already exist
    if ($WEStorageAccount -eq $null) {
        $WEStorageResourceGroupName = 'ARM_Deploy_Staging'
        if ((Get-AzResourceGroup -Name $WEStorageResourceGroupName -Verbose -ErrorAction SilentlyContinue) -eq $null) {
            New-AzResourceGroup -Name $WEStorageResourceGroupName -Location $WELocation -Verbose -Force -ErrorAction Stop
        }
        $WEStorageAccount = New-AzStorageAccount -StorageAccountName $WEStorageAccountName -Type 'Standard_LRS' -ResourceGroupName $WEStorageResourceGroupName -Location " $WELocation"
    }

    if ($WEStorageContainerName.length -gt 63) {
        $WEStorageContainerName = $WEStorageContainerName.Substring(0, 63)
    }
    $WEArtifactStagingLocation = $WEStorageAccount.Context.BlobEndPoint + $WEStorageContainerName + " /"   

    # Generate the value for artifacts location if it is not provided in the parameter file
    if ($useAbsolutePathStaging -and $WEOptionalParameters[$WEArtifactsLocationName] -eq $null) {
        #if the defaultValue for _artifactsLocation is using the template location, use the defaultValue, otherwise set it to the staging location
        $defaultValue = $WEArtifactsLocationParameter | Select-Object -Expand 'defaultValue' -ErrorAction Ignore
        if ($defaultValue -like '*deployment().properties.templateLink.uri*') {
            $WEOptionalParameters.Remove($WEArtifactsLocationName) # just use the defaultValue if it's using the template language function
        }
        else {
            $WEOptionalParameters[$WEArtifactsLocationName] = $WEArtifactStagingLocation   
        }
    } 

    # Copy files from the local storage staging location to the storage account container
    New-AzStorageContainer -Name $WEStorageContainerName -Context $WEStorageAccount.Context -ErrorAction SilentlyContinue *>&1

    $WEArtifactFilePaths = Get-ChildItem $WEArtifactStagingDirectory -Recurse -File | ForEach-Object -Process { $_.FullName }
    foreach ($WESourcePath in $WEArtifactFilePaths) {
        
        if ($WESourcePath -like " $WEDSCSourceFolder*" -and $WESourcePath -like " *.zip" -or !($WESourcePath -like " $WEDSCSourceFolder*")) {
            #When using DSC, just copy the DSC archive, not all the modules and source files
            $blobName = ($WESourcePath -ireplace [regex]::Escape($WEArtifactStagingDirectory), "" ).TrimStart("/" ).TrimStart("\" )
            Set-AzStorageBlobContent -File $WESourcePath -Blob $blobName -Container $WEStorageContainerName -Context $WEStorageAccount.Context -Force
        }
    }

    # Generate a 4 hour SAS token for the artifacts location if one was not provided in the parameters file
    # first check to see if we need a sasToken (if it was not already provided in the param file or we're using relativePath)
    if ($useAbsolutePathStaging -or $WEOptionalParameters[$WEArtifactsLocationSasTokenName] -eq $null) {
        $sasToken = (New-AzStorageContainerSASToken -Container $WEStorageContainerName -Context $WEStorageAccount.Context -Permission r -ExpiryTime (Get-Date).AddHours(4))
    }

    # now set the parameter value for the QueryString or _artifactsLocationSasToken as appropriate
    if($WEOptionalParameters[$WEArtifactsLocationSasTokenName] -eq $null -and $useAbsolutePathStaging){
        $WEOptionalParameters[$WEArtifactsLocationSasTokenName] = ConvertTo-SecureString $sasToken -AsPlainText -Force
        $WETemplateArgs.Add('TemplateUri', $WEArtifactStagingLocation + (Get-ChildItem $WETemplateFile).Name + $sasToken)
    }elseif (!$useAbsolutePathStaging) {
        $WEOptionalParameters['QueryString'] = $sasToken.TrimStart("?" ) # remove leading ? as it is not part of the QueryString
        $WETemplateArgs.Add('TemplateUri', $WEArtifactStagingLocation + (Get-ChildItem $WETemplateFile).Name)
    }
}
else {

    $WETemplateArgs.Add('TemplateFile', $WETemplateFile)

}

if (Test-Path $WETemplateParametersFile) {
    $WETemplateArgs.Add('TemplateParameterFile', $WETemplateParametersFile)
}
Write-Host ($WETemplateArgs | Out-String)
Write-Host ($WEOptionalParameters | Out-String)


if ($deploymentScope -eq "ResourceGroup" ) {
    if ((Get-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -ErrorAction SilentlyContinue) -eq $null) {
        New-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -Force -ErrorAction Stop
    }
}

if ($WEValidateOnly) {
    
    switch ($deploymentScope) {
        "resourceGroup" {
            $WEErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $WEResourceGroupName @TemplateArgs @OptionalParameters)
        }
        " Subscription" {
            $WEErrorMessages = Format-ValidationOutput (Test-AzDeployment -Location $WELocation @TemplateArgs @OptionalParameters)
        }
        " managementGroup" {           
            $WEErrorMessages = Format-ValidationOutput (Test-AzManagementGroupDeployment -Location $WELocation @TemplateArgs @OptionalParameters)
        }
        " tenant" {
            $WEErrorMessages = Format-ValidationOutput (Test-AzTenantDeployment -Location $WELocation @TemplateArgs @OptionalParameters)
        }
    }

    if ($WEErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($WEErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}

else {

    $WEErrorActionPreference = 'Continue' # Switch to Continue" so multiple errors can be formatted and output
    
    switch ($deploymentScope) {
        " resourceGroup" {
            New-AzResourceGroupDeployment -Name $WEDeploymentName `
                -ResourceGroupName $WEResourceGroupName `
                @TemplateArgs `
                @OptionalParameters `
                -Verbose `
                -ErrorVariable ErrorMessages
        }
        " Subscription" {
            New-AzDeployment -Name $WEDeploymentName `
                -Location $WELocation `
                @TemplateArgs `
                @OptionalParameters `
                -Verbose `
                -ErrorVariable ErrorMessages
        }
        " managementGroup" {           
            New-AzManagementGroupDeployment -Name $WEDeploymentName `
                -ManagementGroupId $managementGroupId `
                -Location $WELocation `
                @TemplateArgs `
                @OptionalParameters `
                -Verbose `
                -ErrorVariable ErrorMessages
        }
        " tenant" {
            New-AzTenantDeployment -Name $WEDeploymentName `
                -Location $WELocation `
                @TemplateArgs `
                @OptionalParameters `
                -Verbose `
                -ErrorVariable ErrorMessages
        }
    }
    
   ;  $WEErrorActionPreference = 'Stop' 
    if ($WEErrorMessages) {
        Write-Output '', 'Template deployment returned the following errors:', '', @(@($WEErrorMessages) | ForEach-Object { $_.Exception.Message })
        Write-Error " Deployment failed."
    }

}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================