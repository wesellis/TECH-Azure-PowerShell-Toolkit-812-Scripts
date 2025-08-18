<#
.SYNOPSIS
    We Enhanced Release Ttk

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

[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    [string]$WEStorageAccountResourceGroupName = "azure-quickstarts-service-storage" ,
    [string]$WEStorageAccountName = "azurequickstartsservice" ,
    [string]$containerName = "ttk" ,
    [string]$folderName = "latest" ,
    [string]$ttkFileName = "arm-template-toolkit.zip" ,
    [switch]$WEStaging,
    [switch]$WEPublish
)

if ($WEStaging) {
    # Publish to staging folder instead of default ("latest" ) folder
    $folderName = 'staging'
}



$releaseFiles = "..\..\arm-ttk\arm-ttk" , ".\ci-scripts" , "..\Deploy-AzTemplate.ps1"

Compress-Archive -DestinationPath $ttkFileName -Path $releaseFiles -Force


Copy-Item " ..\..\arm-ttk\arm-ttk" -Destination " .\template-tests" -Recurse
$releaseFiles = $releaseFiles + " .\template-tests"
$releaseFiles = $releaseFiles -ne " ..\..\arm-ttk/arm-ttk"
Compress-Archive -DestinationPath " AzTemplateToolkit.zip" -Path $releaseFiles -Force
Remove-Item " -Force .\template-tests" -Recurse -Force


$WETarget = " Target: storage account $WEStorageAccountName, container $containerName, folder $folderName"

if ($WEPublish) {
    Write-WELog " Publishing to $WETarget" " INFO"
   ;  $ctx = (Get-AzStorageAccount -Name $WEStorageAccountName -ResourceGroupName $WEStorageAccountResourceGroupName).Context
    Set-AzStorageBlobContent -Container $containerName `
        -File $ttkFileName `
        -Blob " $folderName/$ttkFileName" `
        -Context $ctx `
        -Force -Verbose `
        -Properties @{" ContentType" = " application/x-zip-compressed"; " CacheControl" = " no-cache" }
    Write-WELog " Published" " INFO"
}
else {
    Write-WELog " If -Publish flag had been set, this would have published to $WETarget" " INFO"
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
