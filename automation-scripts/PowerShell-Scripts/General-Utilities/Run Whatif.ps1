<#
.SYNOPSIS
    Run Whatif

.DESCRIPTION
    Azure automation
#>
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
    $url,
    $ttkFolder = $ENV:TTK_FOLDER,
    $sampleFolder = $ENV:SAMPLE_FOLDER,
    $sampleName = $ENV:SAMPLE_NAME,
    $paramFileName = $ENV:GEN_PARAMETERS_FILENAME,
    $resourceGroupName = $ENV:RESOURCEGROUP_NAME,
    $filename = "PSWhatIf.zip" ,
    $StorageAccountKey,
    $txtFileName = " results.txt" ,
    $jsonFileName = " results.json" ,
    [switch]$uploadResults
)
if (!$uploadResults) {
    Invoke-WebRequest -uri " $url" -OutFile " $ttkFolder/$filename" -Verbose
    Get-ChildItem -ErrorAction Stop " $ttkFolder/$filename"
    # Unzip Module
    Write-Host "Expanding files..."
    Expand-Archive -Path " $ttkFolder/$filename" -DestinationPath " $ttkFolder/modules" -Verbose -Force
    Write-Host "Expanded files found:"
    #Get-ChildItem -ErrorAction Stop " $ttkFolder/modules" -Recurse
    # Import Module
    Import-Module " $ttkFolder/modules/Az.Accounts/Az.Accounts.psd1" -Verbose -Scope Local
    Import-Module " $ttkFolder/modules/Az.Resources/Az.Resources.psd1" -Verbose -Scope Local
    # Run What-If to file
    $params = @{
        ResourceGroupName = $resourceGroupName
        TemplateParameterFile = " $sampleFolder\$paramFileName"
        TemplateFile = " $sampleFolder\azuredeploy.json"
        Name = "mainTemplate"
        ScopeType = "ResourceGroup"
    }
    $results @params
    # Upload files to storage container
    $results | Out-String | Set-Content -Path " $ttkFolder/modules/$txtFileName"
    $results | ConvertTo-Json | Set-Content -Path " $ttkFolder/modules/$jsonFileName"
}
else { # these need to be done in separate runs due to compatibility problems with the modules
$ctx = New-AzStorageContext -StorageAccountName " azurequickstartsservice" -StorageAccountKey $StorageAccountKey -Environment AzureCloud
$RowKey = $SampleName.Replace(" \" , "@" ).Replace(" /" , "@" )
    Write-Host "RowKey: $RowKey"
    $params = @{
        Properties = "@{"CacheControl" = " no-cache" }"
        File = " $ttkFolder/modules/$txtFileName"
        Context = $ctx
        Blob = " $RowKey@txtFileName"
        Container = " whatif"
    }
    Set-AzStorageBlobContent @params
    $params = @{
        Properties = "@{"CacheControl" = " no-cache" }"
        File = " $ttkFolder/modules/$jsonFileName"
        Context = $ctx
        Blob = " $RowKey@jsonFileName"
        Container = " whatif"
    }
    Set-AzStorageBlobContent @params
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

