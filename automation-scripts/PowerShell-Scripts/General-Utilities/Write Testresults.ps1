<#
.SYNOPSIS
    Write Testresults

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
    We Enhanced Write Testresults

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿<#

This script is used to update the table where the test results for each sample are stored.
Typical scenario is that results will be passed in for only one cloud Public or Fairfax - so the 



[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string]$WESampleFolder = $WEENV:SAMPLE_FOLDER, # this is the full absolute path to the sample
    [string]$WESampleName = $WEENV:SAMPLE_NAME, # the name of the sample or folder path from the root of the repo (i.e. relative path) e.g. " sample-type/sample-name"
    [string]$WEStorageAccountName = $WEENV:STORAGE_ACCOUNT_NAME,
    [string]$WETableName = " QuickStartsMetadataService" ,
    [string]$WETableNamePRs = " QuickStartsMetadataServicePRs" ,
    [string]$WEBadgesContainerName = " badges" ,
    [string]$WEPRsContainerName = " prs" ,
    [string]$WERegressionsTableName = " Regressions" ,
    [Parameter(mandatory = $true)][Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEStorageAccountKey, 
    [string]$WEBestPracticeResult = " $WEENV:RESULT_BEST_PRACTICE" ,
    [string]$WECredScanResult = " $WEENV:RESULT_CREDSCAN" ,
    [string]$WEBuildReason = " $WEENV:BUILD_REASON" ,
    [string]$WEAgentJobStatus = " $WEENV:AGENT_JOBSTATUS" ,
    [string]$WEValidationType = " $WEENV:VALIDATION_TYPE" ,
    [string]$supportedEnvironmentsJson = " $WEENV:SUPPORTED_ENVIRONMENTS" , # the minified json array from metadata.json
    [string]$WEResultDeploymentParameter = " $WEENV:RESULT_DEPLOYMENT_PARAMETER" , #also cloud specific
    [string]$WEFairfaxDeployment = "" ,
    [string]$WEFairfaxLastTestDate = (Get-Date -Format " yyyy-MM-dd" ).ToString(),
    [string]$WEPublicDeployment = "" ,
    [string]$WEPublicLastTestDate = (Get-Date -Format " yyyy-MM-dd" ).ToString(),
    [string]$WEBicepVersion = $WEENV:BICEP_VERSION, # empty if bicep not supported by the sample
    [string]$WETemplateAnalyzerResult = " $WEENV:TEMPLATE_ANALYZER_RESULT" ,
    [string]$WETemplateAnalyzerOutputFilePath = " $WEENV:TEMPLATE_ANALYZER_OUTPUT_FILEPATH" ,
    [string]$WETemplateAnalyzerLogsContainerName = " $WEENV:TEMPLATE_ANALYZER_LOGS_CONTAINER_NAME"
)

function WE-Get-Regression(
    [object] $oldRow,
    [object] $newRow,
    [string] $propertyName
) {
    $oldValue = $oldRow.$propertyName
    $newValue = $newRow.$propertyName

    Write-WELog " Comparison results for ${propertyName}: '$oldValue' -> '$newValue'" " INFO"

    if (![string]::IsNullOrWhiteSpace($newValue)) { 
        $oldResultPassed = $oldValue -eq " PASS"
        $newResultPassed = $newValue -eq " PASS"

        if ($oldResultPassed -and !$newResultPassed) {
            Write-Warning " REGRESSION: $propertyName changed from '$oldValue' to '$newValue'"
            return $true
        }
    }

    return $false
}

function WE-Convert-EntityToHashtable([PSCustomObject] $entity) {
    $hashtable = New-Object -Type Hashtable
    $entity | Get-Member -MemberType NoteProperty | ForEach-Object {
        $name = $_.Name
        if ($name -ne " PartitionKey" -and $name -ne " RowKey" -and $name -ne " Etag" -and $name -ne " TableTimestamp" ) {
            $hashtable[$name] = $entity.$WEName
        }
    }
        
    return $hashtable
}


Write-WELog " Storage account name: $WEStorageAccountName" " INFO"
$ctx = New-AzStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey $WEStorageAccountKey -Environment AzureCloud

$isPullRequest = $false
if ($WEBuildReason -eq " PullRequest" ) {
    $isPullRequest = $true
    $t = $WETableNamePRs
}
else {
    $t = $WETableName
}
Write-WELog " Writing to table $t" " INFO"

if (($WEBicepVersion -ne "" ) -and !($WEBicepVersion -match " ^[0-9]+\.[-0-9a-z.]+$" )) {
    Write-Error " Unexpected bicep version format: $WEBicepVersion.  This may be caused by a previous error in the pipeline"
}

$cloudTable = (Get-AzStorageTable -Name $t -Context $ctx).CloudTable


$WEPathToMetadata = " $WESampleFolder\metadata.json"
Write-WELog " PathToMetadata: $WEPathToMetadata" " INFO"

$WERowKey = $WESampleName.Replace(" \" , " @" ).Replace(" /" , " @" )
Write-WELog " RowKey: $WERowKey" " INFO"

$WEMetadata = Get-Content -ErrorAction Stop $WEPathToMetadata -Raw | ConvertFrom-Json
$WEPartitionKey = $WEMetadata.Type # if the type changes we'll have an orphaned row, this is removed in Get-OldestSampleFolder.ps1


$r = Get-AzTableRow -table $cloudTable -PartitionKey $WEPartitionKey -RowKey $WERowKey


$comparisonCloudTable = (Get-AzStorageTable -Name $WETableName -Context $ctx).CloudTable
$comparisonResults = Get-AzTableRow -table $comparisonCloudTable -PartitionKey $WEPartitionKey -RowKey $WERowKey
Write-WELog " Comparison table for previous results: $WETableName" " INFO"
Write-WELog " Comparison table current results: $comparisonResults" " INFO"

if ($isPullRequest) {
    # Check for a duplicate itemDisplayName in metadata
    # we need to check both tables - merged and PRs in case a dupe is in a PR
    $t1 = (Get-AzStorageTable -Name $WETableName -Context $ctx).CloudTable
    $t2 = (Get-AzStorageTable -Name $WETableNamePRs -Context $ctx).CloudTable
    $itemDisplayName = $WEMetadata.itemDisplayName
    $r1 = Get-AzTableRow -Table $t1 -ColumnName itemDisplayName -Value $itemDisplayName -Operator Equal
    $r2 = Get-AzTableRow -Table $t2 -ColumnName itemDisplayName -Value $itemDisplayName -Operator Equal
    if ($r1.Count -gt 0) {
        # make sure rowkey and partition key don't match - or there's more than one row returned flag it
        $sameRow = ($r1.PartitionKey -eq $WEPartitionKey -and $r1.RowKey -eq $WERowKey)
        if ($r1.count -ge 2 -or !$sameRow) {
            Write-WELog " Duplicate sample name found in $WETableName for: $itemDisplayName" " INFO"
            Write-WELog " ##vso[task.setvariable variable=duplicate.metadata]$true" " INFO"
            foreach ($_ in $r1) {
                Write-WELog " RowKey: $($_.RowKey)" " INFO"
            }
        }
    }
    if ($r2.Count -gt 0) {
        $sameRow = ($r2.PartitionKey -eq $WEPartitionKey -and $r2.RowKey -eq $WERowKey)
        if ($r2.count -ge 2 -or !$sameRow) {
            Write-WELog " Duplicate sample name found in $WETableNamePRs for: $itemDisplayName" " INFO"
            Write-WELog " ##vso[task.setvariable variable=duplicate.metadata]$true" " INFO"
            foreach ($_ in $r2) {
                Write-WELog " RowKey: $($_.RowKey)" " INFO"
            }
        }
    }
}


if ($null -ne $r -and $WEAgentJobStatus -eq " Canceled" -and $WEBuildReason -ne " PullRequest" ) {
    if ($null -eq $r.status) {
        Add-Member -InputObject $r -NotePropertyName " status" -NotePropertyValue " Live"
    }
    else {
        $r.status = " Live"
    }
    Write-WELog " Build Canceled, setting status back to Live" " INFO"
    $r | Update-AzTableRow -table $cloudTable
    exit
}

$WEBestPracticeResult = $WEBestPracticeResult -ireplace [regex]::Escape(" true" ), " PASS"
$WEBestPracticeResult = $WEBestPracticeResult -ireplace [regex]::Escape(" false" ), " FAIL"
$WECredScanResult = $WECredScanResult -ireplace [regex]::Escape(" true" ), " PASS"
$WECredScanResult = $WECredScanResult -ireplace [regex]::Escape(" false" ), " FAIL"
$WEFairfaxDeployment = $WEFairfaxDeployment -ireplace [regex]::Escape(" true" ), " PASS"
$WEFairfaxDeployment = $WEFairfaxDeployment -ireplace [regex]::Escape(" false" ), " FAIL"
$WEPublicDeployment = $WEPublicDeployment -ireplace [regex]::Escape(" true" ), " PASS"
$WEPublicDeployment = $WEPublicDeployment -ireplace [regex]::Escape(" false" ), " FAIL"
$WETemplateAnalyzerResult = $WETemplateAnalyzerResult -ireplace [regex]::Escape(" true" ), " PASS"
$WETemplateAnalyzerResult = $WETemplateAnalyzerResult -ireplace [regex]::Escape(" false" ), " FAIL"

Write-WELog " Supported Environments Found: $supportedEnvironmentsJson" " INFO"
$supportedEnvironments = ($supportedEnvironmentsJson | ConvertFrom-JSON -AsHashTable)


if ($WEValidationType -eq " Manual" ) {
    if ($supportedEnvironments.Contains(" AzureUSGovernment" )) {
        $WEFairfaxDeployment = " Manual Test" 
    }
    if ($supportedEnvironments.Contains(" AzureCloud" )) {
        $WEPublicDeployment = " Manual Test"
    }
}


if ($null -eq $r) {

    Write-WELog " No record found, adding a new one..." " INFO"
    $results = New-Object -TypeName hashtable
    Write-WELog " BP Result: $WEBestPracticeResult" " INFO"
    if (![string]::IsNullOrWhiteSpace($WEBestPracticeResult)) {
        Write-WELog " Adding BP results to hashtable..." " INFO"
        $results.Add(" BestPracticeResult" , $WEBestPracticeResult)
    }
    Write-WELog " Adding Bicep version to hashtable..." " INFO"
    $results.Add(" BicepVersion" , $WEBicepVersion)
    Write-WELog " CredScan Result: $WECredScanResult" " INFO"
    if (![string]::IsNullOrWhiteSpace($WECredScanResult)) {
        $results.Add(" CredScanResult" , $WECredScanResult)
    }
    Write-WELog " TemplateAnalyzer result: $WETemplateAnalyzerResult" " INFO"
    if (![string]::IsNullOrWhiteSpace($WETemplateAnalyzerResult)) {
        $results.Add(" TemplateAnalyzerResult" , $WETemplateAnalyzerResult)
    }
    # set the values for Fairfax only if a result was passed
    Write-WELog " FF Result" " INFO"
    if (![string]::IsNullOrWhiteSpace($WEFairfaxDeployment)) { 
        $results.Add(" FairfaxDeployment" , $WEFairfaxDeployment) 
        $results.Add(" FairfaxLastTestDate" , $WEFairfaxLastTestDate) 
    }
    # set the values for MAC only if a result was passed
    Write-WELog " Mac Result" " INFO"
    if (![string]::IsNullOrWhiteSpace($WEPublicDeployment)) {
        $results.Add(" PublicDeployment" , $WEPublicDeployment) 
        $results.Add(" PublicLastTestDate" , $WEPublicLastTestDate) 
    }
    # add metadata columns
    Write-WELog " New Record: adding metadata" " INFO"
    $results.Add(" itemDisplayName" , $WEMetadata.itemDisplayName)
    $results.Add(" description" , $WEMetadata.description)
    $results.Add(" summary" , $WEMetadata.summary)
    $results.Add(" githubUsername" , $WEMetadata.githubUsername)
    $results.Add(" dateUpdated" , $WEMetadata.dateUpdated)

    if ($WEBuildReason -eq " PullRequest" ) {
        $results.Add(" status" , $WEBuildReason)
        $results.Add($($WEResultDeploymentParameter + " BuildNumber" ), $WEENV:BUILD_BUILDNUMBER)
        $results.Add(" pr" , $WEENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER)
    }

    Write-WELog " New Record: Dump results variable" " INFO"

    $results | Format-List *
    $newResults = $results.PSObject.copy()
    Write-WELog " New Record: Add-AzTableRow" " INFO"

    Add-AzTableRow -table $cloudTable `
        -partitionKey $WEPartitionKey `
        -rowKey $WERowKey `
        -property $results `
        -Verbose
}
else {
    # Update the existing row - need to check to make sure the columns exist
    Write-WELog " Updating the existing record from:" " INFO"
    $r | Format-List *

    if (![string]::IsNullOrWhiteSpace($WEBestPracticeResult)) {
        if ($null -eq $r.BestPracticeResult) {
            Add-Member -InputObject $r -NotePropertyName 'BestPracticeResult' -NotePropertyValue $WEBestPracticeResult
        }
        else {
            $r.BestPracticeResult = $WEBestPracticeResult
        }
    }
    if (![string]::IsNullOrWhiteSpace($WETemplateAnalyzerResult)) {
        if ($null -eq $r.TemplateAnalyzerResult) {
            Add-Member -InputObject $r -NotePropertyName 'TemplateAnalyzerResult' -NotePropertyValue $WETemplateAnalyzerResult
        }
        else {
            $r.TemplateAnalyzerResult = $WETemplateAnalyzerResult
        }
    }
    if (![string]::IsNullOrWhiteSpace($WEBicepVersion)) {
        if ($null -eq $r.BicepVersion) {
            Add-Member -InputObject $r -NotePropertyName 'BicepVersion' -NotePropertyValue $WEBicepVersion
        }
        else {
            $r.BicepVersion = $WEBicepVersion
        }
    }
    if (![string]::IsNullOrWhiteSpace($WECredScanResult)) {
        if ($null -eq $r.CredScanResult) {
            Add-Member -InputObject $r -NotePropertyName " CredScanResult" -NotePropertyValue $WECredScanResult
        }
        else {
            $r.CredScanResult = $WECredScanResult 
        }
    }
    # set the values for FF only if a result was passed
    if (![string]::IsNullOrWhiteSpace($WEFairfaxDeployment)) { 
        if ($null -eq $r.FairfaxDeployment) {
            Add-Member -InputObject $r -NotePropertyName " FairfaxDeployment" -NotePropertyValue $WEFairfaxDeployment
            Add-Member -InputObject $r -NotePropertyName " FairfaxLastTestDate" -NotePropertyValue $WEFairfaxLastTestDate -Force
        }
        else {
            $r.FairfaxDeployment = $WEFairfaxDeployment
            $r.FairfaxLastTestDate = $WEFairfaxLastTestDate 
        }
    }
    # set the values for MAC only if a result was passed
    if (![string]::IsNullOrWhiteSpace($WEPublicDeployment)) {
        if ($null -eq $r.PublicDeployment) {
            Add-Member -InputObject $r -NotePropertyName " PublicDeployment" -NotePropertyValue $WEPublicDeployment
            Add-Member -InputObject $r -NotePropertyName " PublicLastTestDate" -NotePropertyValue $WEPublicLastTestDate -Force
        }
        else {
            $r.PublicDeployment = $WEPublicDeployment 
            $r.PublicLastTestDate = $WEPublicLastTestDate 
        }
    }

    if ($WEBuildReason -eq " PullRequest" ) {
        if ($null -eq $r.status) {
            Add-Member -InputObject $r -NotePropertyName " status" -NotePropertyValue $WEBuildReason            
        }
        else {
            $r.status = $WEBuildReason
        }
        # set the pr number only if the column isn't present (should be true only for older prs before this column was added)
        if ($null -eq $r.pr) {
            Add-Member -InputObject $r -NotePropertyName " pr" -NotePropertyValue $WEENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER            
        }
        
        # if it's a PR, set the build number, since it's not set before this outside of a scheduled build
        if ($null -eq $r.($WEResultDeploymentParameter + " BuildNumber" )) {
            Add-Member -InputObject $r -NotePropertyName ($WEResultDeploymentParameter + " BuildNumber" ) -NotePropertyValue $WEENV:BUILD_BUILDNUMBER           
        }
        else {
            $r.($WEResultDeploymentParameter + " BuildNumber" ) = $WEENV:BUILD_BUILDNUMBER
        }
        if ($null -eq $r.pr) {
            Add-Member -InputObject $r -NotePropertyName " pr" -NotePropertyValue $WEENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER
        }
        else {
            $r.pr = $WEENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER
        }   
    
    }
    else {
        # if this isn't a PR, then it's a scheduled build so set the status back to " live" as the test is complete
        if ($null -eq $r.status) {
            Add-Member -InputObject $r -NotePropertyName " status" -NotePropertyValue " Live"
        }
        else {
            $r.status = " Live"
        }
    }

    # update metadata columns
    if ($null -eq $r.itemDisplayName) { 
        Add-Member -InputObject $r -NotePropertyName " itemDisplayName" -NotePropertyValue $WEMetadata.itemDisplayName
    }
    else {
        $r.itemDisplayName = $WEMetadata.itemDisplayName
    }

    if ($null -eq $r.description) {
        Add-Member -InputObject $r -NotePropertyName " description" -NotePropertyValue $WEMetadata.description
    }
    else {
        $r.description = $WEMetadata.description
    }

    if ($null -eq $r.summary) {
        Add-Member -InputObject $r -NotePropertyName " summary" -NotePropertyValue $WEMetadata.summary
    }
    else {
        $r.summary = $WEMetadata.summary
    }

    if ($null -eq $r.githubUsername) {
        Add-Member -InputObject $r -NotePropertyName " githubUsername" -NotePropertyValue $WEMetadata.githubUsername
    }
    else {
        $r.githubUsername = $WEMetadata.githubUsername
    }   
    
    if ($null -eq $r.dateUpdated) {
        Add-Member -InputObject $r -NotePropertyName " dateUpdated" -NotePropertyValue $WEMetadata.dateUpdated
    }
    else {
        $r.dateUpdated = $WEMetadata.dateUpdated
    }

    Write-WELog " Updating to new results:" " INFO"
    $r | Format-List *
    $r | Update-AzTableRow -table $cloudTable

    $newResults = $r.PSObject.copy()
}


$WEBPRegressed = Get-Regression -ErrorAction Stop $comparisonResults $newResults " BestPracticeResult"
$WEFairfaxRegressed = Get-Regression -ErrorAction Stop $comparisonResults $newResults " FairfaxDeployment"
$WEPublicRegressed = Get-Regression -ErrorAction Stop $comparisonResults $newResults " PublicDeployment"
$WETemplateAnalyzerRegressed = Get-Regression -ErrorAction Stop $comparisonResults $newResults " TemplateAnalyzerResult"

$WEAnyRegressed = $WEBPRegressed -or $WEFairfaxRegressed -or $WEPublicRegresse

if (!$isPullRequest) {
    Write-WELog " Writing regression info to table '$WERegressionsTableName'" " INFO"
    $regressionsTable = (Get-AzStorageTable -Name $WERegressionsTableName -Context $ctx).CloudTable
    $regressionsKey = Get-Date -Format " o"
    $regressionsRow = $newResults.PSObject.copy()
    $regressionsRow | Add-Member " Sample" $WERowKey
    $regressionsRow | Add-Member " AnyRegressed" $WEAnyRegressed
    $regressionsRow | Add-Member " BPRegressed" $WEBPRegressed
    $regressionsRow | Add-Member " FairfaxRegressed" $WEFairfaxRegressed
    $regressionsRow | Add-Member " PublicRegressed" $WEPublicRegressed
    $regressionsRow | Add-Member " TemplateAnalyzerRegressed" $WETemplateAnalyzerRegressed
    $regressionsRow | Add-Member " BuildNumber" $WEENV:BUILD_BUILDNUMBER
    $regressionsRow | Add-Member " BuildId" $WEENV:BUILD_BUILDID
    $regressionsRow | Add-Member " Build" " https://dev.azure.com/azurequickstarts/azure-quickstart-templates/_build/results?buildId=$($WEENV:BUILD_BUILDID)"
    Add-AzTableRow -table $regressionsTable `
        -partitionKey $WEPartitionKey `
        -rowKey $regressionsKey `
        -property (Convert-EntityToHashtable $regressionsRow) `
        -Verbose
}

<#

Now write the badges to storage for the README.md files



$r = Get-AzTableRow -table $cloudTable -PartitionKey $WEPartitionKey -RowKey $WERowKey

$WEBadges = @{ }

$na = " Not%20Tested"


if ($null -ne $r.PublicLastTestDate) {
    $WEPublicLastTestDate = $r.PublicLastTestDate.Replace(" -" , " ." )
    $WEPublicLastTestDateColor = " black"
}
else {
    $WEPublicLastTestDate = $na
    $WEPublicLastTestDateColor = " inactive"
}

if ($null -ne $r.FairfaxLastTestDate) {
    $WEFairfaxLastTestDate = $r.FairfaxLastTestDate.Replace(" -" , " ." )
    $WEFairfaxLastTestDateColor = " black"
}
else {
    $WEFairfaxLastTestDate = $na
    $WEFairfaxLastTestDateColor = " inactive"
}

if ($null -ne $r.FairfaxDeployment) {
    # TODO can be removed when table is updated to string
    $WEFairfaxDeployment = ($r.FairfaxDeployment).ToString().ToLower().Replace(" true" , " PASS" ).Replace(" false" , " FAIL" )
}
switch ($WEFairfaxDeployment) {
    " PASS" { $WEFairfaxDeploymentColor = " brightgreen" }
    " FAIL" { $WEFairfaxDeploymentColor = " red" }
    " Not Supported" { $WEFairfaxDeploymentColor = " yellow" }
    " Manual Test" { $WEFairfaxDeploymentColor = " blue" }
    default {
        $WEFairfaxDeployment = $na
        $WEFairfaxDeploymentColor = " inactive"    
    }
}

if ($null -ne $r.PublicDeployment) {
    # TODO can be removed when table is updated to string
    $WEPublicDeployment = ($r.PublicDeployment).ToString().ToLower().Replace(" true" , " PASS" ).Replace(" false" , " FAIL" )
}
switch ($WEPublicDeployment) {
    " PASS" { $WEPublicDeploymentColor = " brightgreen" }
    " FAIL" { $WEPublicDeploymentColor = " red" }
    " Not Supported" { $WEPublicDeploymentColor = " yellow" }
    " Manual Test" { $WEPublicDeploymentColor = " blue" }
    default {
        $WEPublicDeployment = $na
        $WEPublicDeploymentColor = " inactive"    
    }
}

if ($null -ne $r.BestPracticeResult) {
    # TODO can be removed when table is updated to string
    $WEBestPracticeResult = ($r.BestPracticeResult).ToString().ToLower().Replace(" true" , " PASS" ).Replace(" false" , " FAIL" )
}
switch ($WEBestPracticeResult) {
    " PASS" { $WEBestPracticeResultColor = " brightgreen" }
    " FAIL" { $WEBestPracticeResultColor = " red" }
    default {
        $WEBestPracticeResult = $na
        $WEBestPracticeResultColor = " inactive"    
    }
}

if ($null -ne $r.CredScanResult) {
    # TODO can be removed when table is updated to string
    $WECredScanResult = ($r.CredScanResult).ToString().ToLower().Replace(" true" , " PASS" ).Replace(" false" , " FAIL" )
}
switch ($WECredScanResult) {
    " PASS" { $WECredScanResultColor = " brightgreen" }
    " FAIL" { $WECredScanResultColor = " red" }
    default {
        $WECredScanResult = $na
        $WECredScanResultColor = " inactive"    
    }
}

switch ($WETemplateAnalyzerResult) {
    " PASS" { $WETemplateAnalyzerResultColor = " brightgreen" }
    " FAIL" { $WETemplateAnalyzerResultColor = " red" }
    default {
        $WETemplateAnalyzerResult = $na
       ;  $WETemplateAnalyzerResultColor = " inactive"    
    }
}
; 
$WEBicepVersionColor = " brightgreen" ;
if ($WEBicepVersion -eq "" ) { $WEBicepVersion = " n/a" } # make sure the badge value is not empty
; 
$badges = @(
    @{
        " url"      = " https://img.shields.io/badge/Azure%20Public%20Test%20Date-$WEPublicLastTestDate-/?color=$WEPublicLastTestDateColor" ;
        " filename" = " PublicLastTestDate.svg" ;
    },
    @{
        " url"      = " https://img.shields.io/badge/Azure%20Public%20Test%20Result-$WEPublicDeployment-/?color=$WEPublicDeploymentColor" ;
        " filename" = " PublicDeployment.svg"

    },
    @{ 
        " url"      = " https://img.shields.io/badge/Azure%20US%20Gov%20Test%20Date-$WEFairfaxLastTestDate-/?color=$WEFairfaxLastTestDateColor" ;
        " filename" = " FairfaxLastTestDate.svg"
    },
    @{
        " url"      = " https://img.shields.io/badge/Azure%20US%20Gov%20Test%20Result-$WEFairfaxDeployment-/?color=$WEFairfaxDeploymentColor" ;
        " filename" = " FairfaxDeployment.svg"
    },
    @{
        " url"      = " https://img.shields.io/badge/Best%20Practice%20Check-$WEBestPracticeResult-/?color=$WEBestPracticeResultColor" ;
        " filename" = " BestPracticeResult.svg"
    },
    @{
        " url"      = " https://img.shields.io/badge/CredScan%20Check-$WECredScanResult-/?color=$WECredScanResultColor" ;
        " filename" = " CredScanResult.svg"
    },
    @{
        " url"      = " https://img.shields.io/badge/Bicep%20Version-$WEBicepVersion-/?color=$WEBicepVersionColor" ;
        " filename" = " BicepVersion.svg"
    },
    @{
        " url"      = " https://img.shields.io/badge/Template%20Analyzer%20Check-$WETemplateAnalyzerResult-/?color=$WETemplateAnalyzerResultColor" ;
        " filename" = " TemplateAnalyzerResult.svg"
    }
)

Write-WELog " Uploading Badges..." " INFO"
$tempFolder = [System.IO.Path]::GetTempPath();
foreach ($badge in $badges) {
    $badgeTempPath = Join-Path $tempFolder $badge.filename
    (Invoke-WebRequest -Uri $($badge.url)).Content | Set-Content -Path $badgeTempPath -Force
    <#
        if this is just a PR, we don't want to overwrite the live badges until it's merged
        just create the badges in the " pr" folder and they will be copied over by a CI build when merged
        scheduled builds should be put into the " live" container (i.e. badges)
    #>
    if ($WEBuildReason -eq " PullRequest" ) {
        $containerName = $WEPRsContainerName
    }
    else {
        $containerName = $WEBadgesContainerName
    }

   ;  $badgePath = $WERowKey.Replace(" @" , " /" )

   ;  $blobName = " $badgePath/$($badge.filename)"
    Write-Output " Uploading badge to storage account '$($WEStorageAccountName)', container '$($containerName)', name '$($blobName)':"
    $badge | Format-List | Write-Output
    Set-AzStorageBlobContent -Container $containerName `
        -File $badgeTempPath `
        -Blob $blobName `
        -Context $ctx `
        -Properties @{" ContentType" = " image/svg+xml" ; " CacheControl" = " no-cache" } `
        -Force -Verbose
}


$templateAnalyzerLogFileName = " $($WEENV:BUILD_BUILDNUMBER)_$WERowKey.txt"
Write-WELog " Uploading TemplateAnalyzer log file: $templateAnalyzerLogFileName" " INFO"
try {
    Set-AzStorageBlobContent -Container $WETemplateAnalyzerLogsContainerName `
        -File $WETemplateAnalyzerOutputFilePath `
        -Blob $templateAnalyzerLogFileName `
        -Context $ctx `
        -Properties @{ " ContentType" = " text/plain" } `
        -Force -Verbose
}
catch {
    Write-WELog " ====================================================" " INFO"
    Write-WELog " Failed to upload $WETemplateAnalyzerOutputFilePath   " " INFO"
    Write-WELog " ====================================================" " INFO"
}

<#Debugging only
; 
$WEHTML = " <HTML>"
foreach ($badge in $badges) {
   ;  $WEHTML = $WEHTML + " <IMG SRC=`" $($badge.url)`" />&nbsp;"
}
$WEHTML = $WEHTML + " </HTML>"
$WEHTML | Set-Content -path " test.html"

<#

Snippet that will be placed in the README.md files

<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/PublicLastTestDate.svg" />&nbsp;
<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/PublicDeployment.svg" />&nbsp;

<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/FairfaxLastTestDate.svg" />&nbsp;
<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/FairfaxDeployment.svg" />&nbsp;

<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/BestPracticeResult.svg" />&nbsp;
<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/CredScanResult.svg" />&nbsp;



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================