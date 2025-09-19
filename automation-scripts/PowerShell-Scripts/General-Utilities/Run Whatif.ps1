#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Run Whatif

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

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
    Wes Ellis (wes@wesellis.com)

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

#region Functions

if (!$uploadResults) {

    Invoke-WebRequest -uri " $url" -OutFile " $ttkFolder/$filename" -Verbose
    Get-ChildItem -ErrorAction Stop " $ttkFolder/$filename"

    # Unzip Module
    Write-WELog " Expanding files..." " INFO"
    Expand-Archive -Path " $ttkFolder/$filename" -DestinationPath " $ttkFolder/modules" -Verbose -Force

    Write-WELog " Expanded files found:" " INFO"
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

   ;  $ctx = New-AzStorageContext -StorageAccountName " azurequickstartsservice" -StorageAccountKey $WEStorageAccountKey -Environment AzureCloud
   ;  $WERowKey = $WESampleName.Replace(" \" , " @" ).Replace(" /" , " @" )
    Write-WELog " RowKey: $WERowKey" " INFO"

    $params = @{
        Properties = "@{" CacheControl" = " no-cache" }"
        File = " $ttkFolder/modules/$txtFileName"
        Context = $ctx
        Blob = " $WERowKey@$txtFileName"
        Container = " whatif"
    }
    Set-AzStorageBlobContent @params

    $params = @{
        Properties = "@{" CacheControl" = " no-cache" }"
        File = " $ttkFolder/modules/$jsonFileName"
        Context = $ctx
        Blob = " $WERowKey@$jsonFileName"
        Container = " whatif"
    }
    Set-AzStorageBlobContent @params

}


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
