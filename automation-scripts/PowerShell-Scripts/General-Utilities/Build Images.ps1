<#
.SYNOPSIS
    We Enhanced Build Images

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

$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$WEProgressPreference = 'SilentlyContinue'


$imageBuildTimeoutInMinutes = ([int]$WEEnv:PIPELINE_TIMEOUT_IN_MINUTES) - 5

$imageBicepPath = Join-Path (Split-Path $WEPSScriptRoot -Parent) 'main.bicep'

$imageBuildProfileParam = 'imageBuildProfile={}'
if ($WEEnv:VM_SKU) {
    $imageBuildProfileParam = " imageBuildProfile={"" sku"" : "" $WEEnv:VM_SKU"" }"
}

$artifactSourceParam = '{}'
if ($WEEnv:ARTIFACTS_SOURCE_OBJ) {
    $artifactSourceParam = " artifactSource=$WEEnv:ARTIFACTS_SOURCE_OBJ"
}

Write-WELog " === Building images with deployment $WEEnv:DEPLOYMENT_NAME" " INFO"
$deploymentOutput = az deployment group create --template-file $imageBicepPath --name $WEEnv:DEPLOYMENT_NAME --subscription $WEEnv:SUBSCRIPTION_ID --resource-group $WEEnv:RESOURCE_GROUP `
    --parameters location=$WEEnv:RESOURCES_LOCATION builderIdentity=$WEEnv:BUILDER_IDENTITY imageIdentity=$WEEnv:IMAGE_IDENTITY galleryName=$WEEnv:GALLERY_NAME `
    ignoreBuildFailure=true imageBuildTimeoutInMinutes=$imageBuildTimeoutInMinutes $imageBuildProfileParam $artifactSourceParam


$deploymentOutput -Replace '\\n', [Environment]::NewLine

Write-WELog " === Getting deployment result" " INFO"
$deploymentResult = (az deployment group show --subscription $WEEnv:SUBSCRIPTION_ID --resource-group $WEEnv:RESOURCE_GROUP --name $WEEnv:DEPLOYMENT_NAME) | ConvertFrom-Json

$deploymentResultProps = $deploymentResult.PSobject.Properties | Where-Object { $_.Name -eq 'properties' } | Select-Object -ExpandProperty Value
$outputResources = $deploymentResultProps | Select-Object -ExpandProperty outputResources
# Pattern matching for validation
$imageTemplates = @($outputResources | Where-Object { $_ -match 'Microsoft.VirtualMachineImages' })

$failuresCount = 0
foreach ($imageTemplate in $imageTemplates) {
    Write-WELog " === Validating build result for image $($imageTemplate.id)" " INFO"
   ;  $templateInfo = (az image builder show --ids $imageTemplate.Id) | ConvertFrom-Json
    if ($templateInfo.lastRunStatus.runState -ne " Succeeded") {
        $failuresCount++
        Write-Warning " !!! [ERROR] Image build failed with status '$($templateInfo.lastRunStatus.runState)', message '$($templateInfo.lastRunStatus.message)'"
    }
}

if (($failuresCount -gt 0) -or ($imageTemplates.Count -eq 0)) {
    Write-Error " !!! [ERROR] $failuresCount image build(s) failed"
}
else {
    Write-WELog " === Success: $($imageTemplates.Count) image build(s) succeeded" " INFO"
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================