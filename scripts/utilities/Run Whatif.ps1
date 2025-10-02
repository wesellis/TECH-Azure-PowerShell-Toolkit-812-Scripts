#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Run Whatif

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
    [Parameter()]
    $url,
    [Parameter()]
    $TtkFolder = $ENV:TTK_FOLDER,
    [Parameter()]
    $SampleFolder = $ENV:SAMPLE_FOLDER,
    [Parameter()]
    $SampleName = $ENV:SAMPLE_NAME,
    [Parameter()]
    $ParamFileName = $ENV:GEN_PARAMETERS_FILENAME,
    [Parameter()]
    $ResourceGroupName = $ENV:RESOURCEGROUP_NAME,
    [Parameter()]
    $filename = "PSWhatIf.zip" ,
    [Parameter()]
    $StorageAccountKey,
    [Parameter()]
    $TxtFileName = " results.txt" ,
    [Parameter()]
    $JsonFileName = " results.json" ,
    [switch]$UploadResults
)
if (!$UploadResults) {
    Invoke-WebRequest -uri " $url" -OutFile " $TtkFolder/$filename" -Verbose
    Get-ChildItem -ErrorAction Stop " $TtkFolder/$filename"
    Write-Output "Expanding files..."
    Expand-Archive -Path " $TtkFolder/$filename" -DestinationPath " $TtkFolder/modules" -Verbose -Force
    Write-Output "Expanded files found:"
    Import-Module " $TtkFolder/modules/Az.Accounts/Az.Accounts.psd1" -Verbose -Scope Local
    Import-Module " $TtkFolder/modules/Az.Resources/Az.Resources.psd1" -Verbose -Scope Local
    $params = @{
        ResourceGroupName = $ResourceGroupName
        TemplateParameterFile = " $SampleFolder\$ParamFileName"
        TemplateFile = " $SampleFolder\azuredeploy.json"
        Name = "mainTemplate"
        ScopeType = "ResourceGroup"
    }
    $results @params
    $results | Out-String | Set-Content -Path " $TtkFolder/modules/$TxtFileName"
    $results | ConvertTo-Json | Set-Content -Path " $TtkFolder/modules/$JsonFileName"
}
else {
    $ctx = New-AzStorageContext -StorageAccountName " azurequickstartsservice" -StorageAccountKey $StorageAccountKey -Environment AzureCloud
    $RowKey = $SampleName.Replace(" \" , "@" ).Replace("/" , "@" )
    Write-Output "RowKey: $RowKey"
    $params = @{
        Properties = "@{"CacheControl" = " no-cache" }"
        File = " $TtkFolder/modules/$TxtFileName"
        Context = $ctx
        Blob = " $RowKey@txtFileName"
        Container = " whatif"
    }
    Set-AzStorageBlobContent @params
    $params = @{
        Properties = "@{"CacheControl" = " no-cache" }"
        File = " $TtkFolder/modules/$JsonFileName"
        Context = $ctx
        Blob = " $RowKey@jsonFileName"
        Container = " whatif"
    }
    Set-AzStorageBlobContent @params
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
