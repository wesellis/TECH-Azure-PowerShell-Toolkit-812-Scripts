#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Release Ttk

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string]$StorageAccountResourceGroupName = " azure-quickstarts-service-storage" ,
    [string]$StorageAccountName = " azurequickstartsservice" ,
    [string]$containerName = " ttk" ,
    [string]$folderName = " latest" ,
    [string]$ttkFileName = " arm-template-toolkit.zip" ,
    [switch]$Staging,
    [switch]$Publish
)
if ($Staging) {
    # Publish to staging folder instead of default (" latest" ) folder
    $folderName = 'staging'
}
$releaseFiles = " ..\..\arm-ttk\arm-ttk" , ".\ci-scripts" , "..\Deploy-AzTemplate.ps1"
Compress-Archive -DestinationPath $ttkFileName -Path $releaseFiles -Force
Copy-Item " ..\..\arm-ttk\arm-ttk" -Destination " .\template-tests" -Recurse
$releaseFiles = $releaseFiles + " .\template-tests"
$releaseFiles = $releaseFiles -ne " ..\..\arm-ttk/arm-ttk"
Compress-Archive -DestinationPath "AzTemplateToolkit.zip" -Path $releaseFiles -Force
Remove-Item -ErrorAction Stop " -Force .\template-tests" -Recurse -Force
$Target = "Target: storage account $StorageAccountName, container $containerName, folder $folderName"
if ($Publish) {
    Write-Host "Publishing to $Target"
$ctx = (Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountResourceGroupName).Context
    $params = @{
        Properties = "@{"ContentType" = " application/x-zip-compressed" ; "CacheControl" = " no-cache" } Write-Host "Published"
        File = $ttkFileName
        Context = $ctx
        Blob = " $folderName/$ttkFileName"
        Container = $containerName
    }
    Set-AzStorageBlobContent @params
}
else {
    Write-Host "If -Publish flag had been set, this would have published to $Target"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

