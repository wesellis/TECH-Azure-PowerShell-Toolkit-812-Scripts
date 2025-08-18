<#
.SYNOPSIS
    Run Whatif

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
    We Enhanced Run Whatif

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $url,
    $ttkFolder = $WEENV:TTK_FOLDER,
    $sampleFolder = $WEENV:SAMPLE_FOLDER,
    $sampleName = $WEENV:SAMPLE_NAME,
    $paramFileName = $WEENV:GEN_PARAMETERS_FILENAME,
    $resourceGroupName = $WEENV:RESOURCEGROUP_NAME,
    $filename = " PSWhatIf.zip" ,
    $WEStorageAccountKey, 
    $txtFileName = " results.txt" ,
    $jsonFileName = " results.json" ,
    [switch]$uploadResults
)

if (!$uploadResults) {

    Invoke-WebRequest -uri " $url" -OutFile " $ttkFolder/$filename" -Verbose
    Get-ChildItem " $ttkFolder/$filename"

    # Unzip Module
    Write-WELog " Expanding files..." " INFO"
    Expand-Archive -Path " $ttkFolder/$filename" -DestinationPath " $ttkFolder/modules" -Verbose -Force

    Write-WELog " Expanded files found:" " INFO"
    #Get-ChildItem " $ttkFolder/modules" -Recurse

    # Import Module
    Import-Module " $ttkFolder/modules/Az.Accounts/Az.Accounts.psd1" -Verbose -Scope Local
    Import-Module " $ttkFolder/modules/Az.Resources/Az.Resources.psd1" -Verbose -Scope Local

    # Run What-If to file
    $results = New-AzDeploymentWhatIf -ScopeType ResourceGroup `
        -Name mainTemplate `
        -TemplateFile " $sampleFolder\azuredeploy.json" `
        -TemplateParameterFile " $sampleFolder\$paramFileName" `
        -ResourceGroupName $resourceGroupName `
        -Verbose

    # Upload files to storage container

    $results | Out-String | Set-Content -Path " $ttkFolder/modules/$txtFileName"
    $results | ConvertTo-Json | Set-Content -Path " $ttkFolder/modules/$jsonFileName"
}
else { # these need to be done in separate runs due to compatibility problems with the modules

   ;  $ctx = New-AzStorageContext -StorageAccountName " azurequickstartsservice" -StorageAccountKey $WEStorageAccountKey -Environment AzureCloud
   ;  $WERowKey = $WESampleName.Replace(" \" , " @" ).Replace(" /" , " @" )
    Write-WELog " RowKey: $WERowKey" " INFO"

    Set-AzStorageBlobContent -Container " whatif" `
        -File " $ttkFolder/modules/$txtFileName" `
        -Blob " $WERowKey@$txtFileName" `
        -Context $ctx -Force -Verbose `
        -Properties @{" CacheControl" = " no-cache" }

    Set-AzStorageBlobContent -Container " whatif" `
        -File " $ttkFolder/modules/$jsonFileName" `
        -Blob " $WERowKey@$jsonFileName" `
        -Context $ctx -Force -Verbose `
        -Properties @{" CacheControl" = " no-cache" }

}


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
