#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Update Templatehash

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules

[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    $StorageAccountResourceGroupName = " azure-quickstarts-template-hash" ,
    $StorageAccountName = " azurequickstartshash" ,
    $TableName = "QuickStartsTemplateHash" ,
    $RepoRoot = $ENV:BUILD_REPOSITORY_LOCALPATH,
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $BearerToken,
    [Parameter(mandatory = $true)]$StorageAccountKey
)
If(!$RepoRoot.EndsWith(" \" )){
    $RepoRoot = " $RepoRoot\"
}
if ($BearerToken -eq "" ) {
    Write-Output "Getting token..."
    Import-Module Az.Accounts
    $AzProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $AzContext = Get-AzContext -ErrorAction Stop
    $ProfileClient = New-Object -ErrorAction Stop Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($AzProfile)
    $BearerToken = ($ProfileClient.AcquireAccessToken($AzContext.Tenant.TenantId)).AccessToken
}
    $uri = "https://management.azure.com/providers/Microsoft.Resources/calculateTemplateHash?api-version=2019-10-01"
    $Headers = @{
    'Authorization' = "Bearer $BearerToken"
    'Content-Type'  = 'application/json'
}
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey " $StorageAccountKey" -Environment AzureCloud
    $ctx | Out-String
Get-AzStorageTable -Name $TableName -Context $ctx -Verbose
    $CloudTable = (Get-AzStorageTable -Name $TableName -Context $ctx).CloudTable
if ($ENV:BUILD_REASON -eq "Schedule" -or $ENV:BUILD_REASON -eq "Manual" ) { # calculate hash for everything in the repo on the scheduled build
    $ArtifactFilePaths = Get-ChildItem -Path $RepoRoot .\metadata.json -Recurse -File | ForEach-Object -Process { $_.FullName }
} else {
    $ArtifactFilePaths = Get-ChildItem -Path $SampleFolder .\metadata.json -Recurse -File | ForEach-Object -Process { $_.FullName }
}
foreach ($SourcePath in $ArtifactFilePaths) {
    if ($SourcePath -like " *\test\*" ) {
        Write-Output "Skipping... $SourcePath"
        continue
    }
    $MetadataPath = ($SourcePath | Split-Path)
    $SampleName = $MetadataPath -ireplace [regex]::Escape($RepoRoot), ""
    $PartitionKey = $SampleName.Replace("/" , "@" ).Replace(" \" , "@" )
    $JsonFilePaths = Get-ChildItem -Path $MetadataPath .\*.json -Recurse -File | ForEach-Object -Process { $_.FullName }
    foreach ($file in $JsonFilePaths) {
        if ($file -like " *\test\*" ) {
            Write-Output "Skipping..."
            continue
        }
    $json = Get-Content -Path $file -Raw
        if ($json -like " *deploymentTemplate.json#*" ) {
            Write-Output "Requesting Hash for file: $file"
            try{
    $params = @{
                Method = "POST"
                verbose = "}catch{ Write-Output $response Write-Error "Failed to get hash for: $file" }  ;  $TemplateHash = $response.templateHash"
                Uri = $uri
                Headers = $Headers
                Body = $json
            }
    $response @params
            Write-Output "Fetching row for: *$TemplateHash*"
$r = Get-AzTableRow -table $CloudTable -ColumnName "RowKey" -Value " $TemplateHash" -Operator Equal -verbose
            if ($null -eq $r) {
                Write-Output " $TemplateHash not found in table"
    $params = @{
                    table = $CloudTable
                    rowKey = $TemplateHash
                    property = "@{ " version"  = " $TemplateHash-$(Get-Date"
                    partitionKey = $PartitionKey
                    ireplace = "[regex]::Escape(" $RepoRoot$SampleName\" ), '')" } } } }"
                    Format = "yyyy-MM-dd')" ; " file" = " $($file"
                }
                Add-AzTableRow @params`n}
