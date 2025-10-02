#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Release Ttk

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    $StorageAccountResourceGroupName = " azure-quickstarts-service-storage" ,
    $StorageAccountName = " azurequickstartsservice" ,
    $ContainerName = " ttk" ,
    $FolderName = " latest" ,
    $TtkFileName = " arm-template-toolkit.zip" ,
    [switch]$Staging,
    [switch]$Publish
)
if ($Staging) {
    $FolderName = 'staging'
}
    $ReleaseFiles = " ..\..\arm-ttk\arm-ttk" , ".\ci-scripts" , "..\Deploy-AzTemplate.ps1"
Compress-Archive -DestinationPath $TtkFileName -Path $ReleaseFiles -Force
Copy-Item " ..\..\arm-ttk\arm-ttk" -Destination " .\template-tests" -Recurse
    $ReleaseFiles = $ReleaseFiles + " .\template-tests"
    $ReleaseFiles = $ReleaseFiles -ne " ..\..\arm-ttk/arm-ttk"
Compress-Archive -DestinationPath "AzTemplateToolkit.zip" -Path $ReleaseFiles -Force
Remove-Item -ErrorAction Stop " -Force .\template-tests" -Recurse -Force
    $Target = "Target: storage account $StorageAccountName, container $ContainerName, folder $FolderName"
if ($Publish) {
    Write-Output "Publishing to $Target"
    $ctx = (Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountResourceGroupName).Context
    $params = @{
        Properties = "@{"ContentType" = " application/x-zip-compressed" ; "CacheControl" = " no-cache" } Write-Output "Published"
        File = $TtkFileName
        Context = $ctx
        Blob = " $FolderName/$TtkFileName"
        Container = $ContainerName
    }
    Set-AzStorageBlobContent @params
}
else {
    Write-Output "If -Publish flag had been set, this would have published to $Target"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
