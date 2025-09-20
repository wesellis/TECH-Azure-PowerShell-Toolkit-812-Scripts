<#
.SYNOPSIS
    Update Templatehash

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string]$StorageAccountResourceGroupName = " azure-quickstarts-template-hash" ,
    [string]$StorageAccountName = " azurequickstartshash" ,
    [string]$TableName = "QuickStartsTemplateHash" ,
    [string]$RepoRoot = $ENV:BUILD_REPOSITORY_LOCALPATH,
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER, # this is the path to the sample
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$bearerToken,
    [Parameter(mandatory = $true)]$StorageAccountKey
)
If(!$RepoRoot.EndsWith(" \" )){
    $RepoRoot = " $RepoRoot\"
}
if ($bearerToken -eq "" ) {
    Write-Host "Getting token..."
    Import-Module Az.Accounts
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $azContext = Get-AzContext -ErrorAction Stop
    $profileClient = New-Object -ErrorAction Stop Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
    $bearerToken = ($profileClient.AcquireAccessToken($azContext.Tenant.TenantId)).AccessToken
}
$uri = "https://management.azure.com/providers/Microsoft.Resources/calculateTemplateHash?api-version=2019-10-01"
$Headers = @{
    'Authorization' = "Bearer $bearerToken"
    'Content-Type'  = 'application/json'
}
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey " $StorageAccountKey" -Environment AzureCloud
$ctx | Out-String
Get-AzStorageTable -Name $tableName -Context $ctx -Verbose
$cloudTable = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable
if ($ENV:BUILD_REASON -eq "Schedule" -or $ENV:BUILD_REASON -eq "Manual" ) { # calculate hash for everything in the repo on the scheduled build
    $ArtifactFilePaths = Get-ChildItem -Path $RepoRoot .\metadata.json -Recurse -File | ForEach-Object -Process { $_.FullName }
} else { # calculate hash only for the sample that was submitted
    $ArtifactFilePaths = Get-ChildItem -Path $SampleFolder .\metadata.json -Recurse -File | ForEach-Object -Process { $_.FullName }
}
foreach ($SourcePath in $ArtifactFilePaths) {
    if ($SourcePath -like " *\test\*" ) {
        Write-Host "Skipping... $SourcePath"
        continue
    }
    #Write-Output "RepoRoot: $RepoRoot"
    $metadataPath = ($SourcePath | Split-Path)
    #Write-Output "MetadataPath: $metadataPath"
    $sampleName = $metadataPath -ireplace [regex]::Escape($RepoRoot), ""
    #Write-output "SampleName: $sampleName"
    $partitionKey = $sampleName.Replace(" /" , "@" ).Replace(" \" , "@" )
    #Write-Output "PartitionKey: $partitionKey"
    # Find each template file in the sample (prereqs, nested, etc.)
    $JsonFilePaths = Get-ChildItem -Path $metadataPath .\*.json -Recurse -File | ForEach-Object -Process { $_.FullName }
    foreach ($file in $JsonFilePaths) {
        if ($file -like " *\test\*" ) {
            Write-Host "Skipping..."
            continue
        }
        #Write-output $file
        $json = Get-Content -Path $file -Raw
        # Check the schema to see if this is a template, then get the hash and update the table
        if ($json -like " *deploymentTemplate.json#*" ) {
            # Get TemplateHash
            Write-Host "Requesting Hash for file: $file"
            try{ #fail the build for now so we can find issues
            $params = @{
                Method = "POST"
                verbose = "}catch{ Write-Host $response Write-Error "Failed to get hash for: $file" }  ;  $templateHash = $response.templateHash"
                Uri = $uri
                Headers = $Headers
                Body = $json
            }
            $response @params
            # Find row in table if it exists, if it doesn't exist, add a new row with the new hash
            Write-Output "Fetching row for: *$templateHash*"
$r = Get-AzTableRow -table $cloudTable -ColumnName "RowKey" -Value " $templateHash" -Operator Equal -verbose
            if ($null -eq $r) {
                # Add this as a new hash
                Write-Output " $templateHash not found in table"
                $params = @{
                    table = $cloudTable
                    rowKey = $templateHash
                    property = "@{ " version"  = " $templateHash-$(Get-Date"
                    partitionKey = $partitionKey
                    ireplace = "[regex]::Escape(" $RepoRoot$sampleName\" ), '')" } } } }"
                    Format = "yyyy-MM-dd')" ; " file" = " $($file"
                }
                Add-AzTableRow @params
}

