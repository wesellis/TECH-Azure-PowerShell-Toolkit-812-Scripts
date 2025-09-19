#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Update Templatehash

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
    We Enhanced Update Templatehash

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string]$WEStorageAccountResourceGroupName = " azure-quickstarts-template-hash" ,
    [string]$WEStorageAccountName = " azurequickstartshash" ,
    [string]$WETableName = " QuickStartsTemplateHash" ,
    [string]$WERepoRoot = $WEENV:BUILD_REPOSITORY_LOCALPATH,
    [string] $WESampleFolder = $WEENV:SAMPLE_FOLDER, # this is the path to the sample
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$bearerToken,
    [Parameter(mandatory = $true)]$WEStorageAccountKey
)

#region Functions

If(!$WERepoRoot.EndsWith(" \" )){
    $WERepoRoot = " $WERepoRoot\"
}


if ($bearerToken -eq "" ) {
    Write-WELog " Getting token..." " INFO"
    Import-Module Az.Accounts
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $azContext = Get-AzContext -ErrorAction Stop
    $profileClient = New-Object -ErrorAction Stop Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
    $bearerToken = ($profileClient.AcquireAccessToken($azContext.Tenant.TenantId)).AccessToken
}
$uri = " https://management.azure.com/providers/Microsoft.Resources/calculateTemplateHash?api-version=2019-10-01"
$WEHeaders = @{
    'Authorization' = " Bearer $bearerToken"
    'Content-Type'  = 'application/json'
}



$ctx = New-AzStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey " $WEStorageAccountKey" -Environment AzureCloud
$ctx | Out-String
Get-AzStorageTable -Name $tableName -Context $ctx -Verbose
$cloudTable = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable


if ($WEENV:BUILD_REASON -eq " Schedule" -or $WEENV:BUILD_REASON -eq " Manual" ) { # calculate hash for everything in the repo on the scheduled build
    
    $WEArtifactFilePaths = Get-ChildItem -Path $WERepoRoot .\metadata.json -Recurse -File | ForEach-Object -Process { $_.FullName }

} else { # calculate hash only for the sample that was submitted

    $WEArtifactFilePaths = Get-ChildItem -Path $WESampleFolder .\metadata.json -Recurse -File | ForEach-Object -Process { $_.FullName }

}

foreach ($WESourcePath in $WEArtifactFilePaths) {

    if ($WESourcePath -like " *\test\*" ) {
        Write-Information " Skipping... $WESourcePath"
        continue
    }

    #Write-Output " RepoRoot: $WERepoRoot"
    $metadataPath = ($WESourcePath | Split-Path)
    #Write-Output " MetadataPath: $metadataPath"
    $sampleName = $metadataPath -ireplace [regex]::Escape($WERepoRoot), ""
    #Write-output " SampleName: $sampleName"
    $partitionKey = $sampleName.Replace(" /" , " @" ).Replace(" \" , " @" )
    #Write-Output " PartitionKey: $partitionKey"
    
    # Find each template file in the sample (prereqs, nested, etc.)
    $WEJsonFilePaths = Get-ChildItem -Path $metadataPath .\*.json -Recurse -File | ForEach-Object -Process { $_.FullName }
    foreach ($file in $WEJsonFilePaths) {
        if ($file -like " *\test\*" ) {
            Write-Information " Skipping..."
            continue
        }

        #Write-output $file
        $json = Get-Content -Path $file -Raw

        # Check the schema to see if this is a template, then get the hash and update the table
        if ($json -like " *deploymentTemplate.json#*" ) {
    
            # Get TemplateHash
            Write-WELog " Requesting Hash for file: $file" " INFO"
            try{ #fail the build for now so we can find issues
            $params = @{
                Method = " POST"
                verbose = "}catch{ Write-Information $response Write-Error " Failed to get hash for: $file" }  ;  $templateHash = $response.templateHash"
                Uri = $uri
                Headers = $WEHeaders
                Body = $json
            }
            $response @params

            # Find row in table if it exists, if it doesn't exist, add a new row with the new hash
            Write-Output " Fetching row for: *$templateHash*"

           ;  $r = Get-AzTableRow -table $cloudTable -ColumnName " RowKey" -Value " $templateHash" -Operator Equal -verbose 
            if ($null -eq $r) {
                # Add this as a new hash
                Write-Output " $templateHash not found in table"

                $params = @{
                    table = $cloudTable
                    rowKey = $templateHash
                    property = "@{ " version"  = " $templateHash-$(Get-Date"
                    partitionKey = $partitionKey
                    ireplace = "[regex]::Escape(" $WERepoRoot$sampleName\" ), '')" } } } }"
                    Format = "yyyy-MM-dd')" ; " file" = " $($file"
                }
                Add-AzTableRow @params
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
