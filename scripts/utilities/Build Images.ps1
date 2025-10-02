#Requires -Version 7.4

<#`n.SYNOPSIS
    Build Images

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ImageBuildTimeoutInMinutes = ([int]$Env:PIPELINE_TIMEOUT_IN_MINUTES) - 5
$ImageBicepPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'main.bicep'
$ImageBuildProfileParam = 'imageBuildProfile={}'
if ($Env:VM_SKU) {
    $ImageBuildProfileParam = " imageBuildProfile={"" sku"" : "" $Env:VM_SKU"" }"
}
$ArtifactSourceParam = '{}'
if ($Env:ARTIFACTS_SOURCE_OBJ) {
    $ArtifactSourceParam = " artifactSource=$Env:ARTIFACTS_SOURCE_OBJ"
}
Write-Output " === Building images with deployment $Env:DEPLOYMENT_NAME"
$params = @{
    file = $ImageBicepPath
    parameters = "location=$Env:RESOURCES_LOCATION builderIdentity=$Env:BUILDER_IDENTITY imageIdentity=$Env:IMAGE_IDENTITY galleryName=$Env:GALLERY_NAME ignoreBuildFailure=true imageBuildTimeoutInMinutes=$ImageBuildTimeoutInMinutes $ImageBuildProfileParam $ArtifactSourceParam"
    group = $Env:RESOURCE_GROUP
    name = $Env:DEPLOYMENT_NAME
    subscription = $Env:SUBSCRIPTION_ID
}
$DeploymentOutput @params
$DeploymentOutput -Replace '\
', [Environment]::NewLine
Write-Output " === Getting deployment result"
$DeploymentResult = (az deployment group show --subscription $Env:SUBSCRIPTION_ID --resource-group $Env:RESOURCE_GROUP --name $Env:DEPLOYMENT_NAME) | ConvertFrom-Json
$DeploymentResultProps = $DeploymentResult.PSobject.Properties | Where-Object { $_.Name -eq 'properties' } | Select-Object -ExpandProperty Value
$OutputResources = $DeploymentResultProps | Select-Object -ExpandProperty outputResources
$ImageTemplates = @($OutputResources | Where-Object { $_ -match 'Microsoft.VirtualMachineImages' })
$FailuresCount = 0
foreach ($ImageTemplate in $ImageTemplates) {
    Write-Output " === Validating build result for image $($ImageTemplate.id)"
$TemplateInfo = (az image builder show --ids $ImageTemplate.Id) | ConvertFrom-Json
    if ($TemplateInfo.lastRunStatus.runState -ne "Succeeded" ) {
        $FailuresCount++
        Write-Warning " !!! [ERROR] Image build failed with status '$($TemplateInfo.lastRunStatus.runState)', message '$($TemplateInfo.lastRunStatus.message)'"
    }
}
if (($FailuresCount -gt 0) -or ($ImageTemplates.Count -eq 0)) {
    Write-Error " !!! [ERROR] $FailuresCount image build(s) failed"
}
else {
    Write-Output " === Success: $($ImageTemplates.Count) image build(s) succeeded"`n}
