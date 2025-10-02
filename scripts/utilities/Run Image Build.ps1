#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Run Image Build

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
$ImageTemplateName = ${env:imageTemplateName}
function Log([string] $message, [switch] $AsError) {
    $FormattedTime = Get-Date -Format " yyyy/MM/dd HH:mm:ss.ff"
    $FormattedMessage = " [$FormattedTime $ImageTemplateName] $message"
    if ($AsError) {
        Write-Error $FormattedMessage
    }
    else {
        Write-Output $FormattedMessage
    }
}
RunWithRetries { Connect-AzAccount -Identity | Out-Null }
RunWithRetries { Install-Module -Name Az.ImageBuilder -AllowPrerelease -Force -Verbose }
$PreBuildPauseSeconds = 30
Log " === Pausing for $PreBuildPauseSeconds seconds for the template and prerequisites to complete initialization"
Start-Sleep -Seconds $PreBuildPauseSeconds
Log " === Starting the image build"
RunWithRetries {
    $info = $null
    try {
        $info = Get-AzImageBuilderTemplate -ImageTemplateName $ImageTemplateName -ResourceGroupName ${env:resourceGroupName
} catch {
        Log " $_`n=== The template might still be initializing - wait a bit more before starting the build"
        Start-Sleep -Seconds 60
    }
    if ($info -and $info.LastRunStatusRunState) {
        Log " === Already started"
    }
    else {
        Invoke-AzResourceAction -ResourceName " $ImageTemplateName" -ResourceGroupName " ${env:resourceGroupName}" -ResourceType "Microsoft.VirtualMachineImages/imageTemplates" -ApiVersion " 2020-02-14" -Action Run -Force
    }
}
Log " === Waiting for the image build to complete"
$script:status = 'UNKNOWN'
while ($global:status -ne 'Succeeded' -and $global:status -ne 'Failed' -and $global:status -ne 'Canceled') {
    Start-Sleep -Seconds 15
    RunWithRetries {
        $script:info = Get-AzImageBuilderTemplate -ImageTemplateName $ImageTemplateName -ResourceGroupName ${env:resourceGroupName}
        $script:status = $info.LastRunStatusRunState
    }
}
$BuildStatusShort = " status '$global:status', message '$($global:info.LastRunStatusMessage)'"
Log " === Image build completed with $BuildStatusShort"
$IgnoreBuildFailure = [bool]::Parse(" ${env:ignoreBuildFailure}" )
if ( (!$IgnoreBuildFailure) -and ($global:status -ne 'Succeeded')) {
    Start-Sleep -Seconds 15
    Log -asError " !!! [ERROR] Image build failed with $BuildStatusShort"
}
$PrintCustomizationLogLastLines = [int]::Parse(" ${env:printCustomizationLogLastLines}" )
if ($PrintCustomizationLogLastLines -ne 0) {
    $StagingResourceGroupName = ${env:stagingResourceGroupName}
    $LogsFile = 'customization.log'
    Log " === Looking for storage account in staging RG '$StagingResourceGroupName'"
    $StagingStorageAccountName = (Get-AzResource -ResourceGroupName $StagingResourceGroupName -ResourceType "Microsoft.Storage/storageAccounts" )[0].Name
    $StagingStorageAccountKey = $(Get-AzStorageAccountKey -StorageAccountName $StagingStorageAccountName -ResourceGroupName $StagingResourceGroupName)[0].value
$ctx = New-AzStorageContext -StorageAccountName $StagingStorageAccountName -StorageAccountKey $StagingStorageAccountKey
$LogsBlob = Get-AzStorageBlob -Context $ctx -Container packerlogs | Where-Object { $_.Name -like " */$LogsFile" }
    if ($LogsBlob) {
        Log " === Downloading $LogsFile from storage account '$StagingStorageAccountName'"
        Get-AzStorageBlobContent -Context $ctx -CloudBlob $LogsBlob.ICloudBlob -Destination $LogsFile -Force | Format-List
        if ($PrintCustomizationLogLastLines -gt 0) {
            Log " === Last $PrintCustomizationLogLastLines lines of $LogsFile :`n"
            Log " $(Get-Content -ErrorAction Stop $LogsFile -Tail $PrintCustomizationLogLastLines | Out-String)"
        }
        else {
            Log " === Content of $LogsFile :`n"
            Log " $(Get-Content -ErrorAction Stop $LogsFile | Out-String)"
        }
    }
    else {
        Log "Could not find customization.log in storage account: $StagingStorageAccountName"
    }
}
Log " === DONE"
Start-Sleep -Seconds 15



