#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Module Az.Resources
    Write Testresults
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
<#`n.SYNOPSIS
    PowerShell script
.DESCRIPTION
    PowerShell operation


    Author: Wes Ellis (wes@wesellis.com)
This script is used to update the table where the test results for each sample are stored.
Typical scenario is that results will be passed in for only one cloud Public or Fairfax - so the
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    $SampleFolder = $ENV:SAMPLE_FOLDER,
    $SampleName = $ENV:SAMPLE_NAME,
    $StorageAccountName = $ENV:STORAGE_ACCOUNT_NAME,
    $TableName = "QuickStartsMetadataService" ,
    $TableNamePRs = "QuickStartsMetadataServicePRs" ,
    $BadgesContainerName = " badges" ,
    $PRsContainerName = " prs" ,
    $RegressionsTableName = "Regressions" ,
    [Parameter(mandatory = $true)][Parameter()]
    [ValidateNotNullOrEmpty()]
    $StorageAccountKey,
    $BestPracticeResult = " $ENV:RESULT_BEST_PRACTICE" ,
    $CredScanResult = " $ENV:RESULT_CREDSCAN" ,
    $BuildReason = " $ENV:BUILD_REASON" ,
    $AgentJobStatus = " $ENV:AGENT_JOBSTATUS" ,
    $ValidationType = " $ENV:VALIDATION_TYPE" ,
    $SupportedEnvironmentsJson = " $ENV:SUPPORTED_ENVIRONMENTS" , # the minified json array from metadata.json
    $ResultDeploymentParameter = " $ENV:RESULT_DEPLOYMENT_PARAMETER" , #also cloud specific
    $FairfaxDeployment = "" ,
    $FairfaxLastTestDate = (Get-Date -Format " yyyy-MM-dd" ).ToString(),
    $PublicDeployment = "" ,
    $PublicLastTestDate = (Get-Date -Format " yyyy-MM-dd" ).ToString(),
    $BicepVersion = $ENV:BICEP_VERSION,
    $TemplateAnalyzerResult = " $ENV:TEMPLATE_ANALYZER_RESULT" ,
    $TemplateAnalyzerOutputFilePath = " $ENV:TEMPLATE_ANALYZER_OUTPUT_FILEPATH" ,
    $TemplateAnalyzerLogsContainerName = " $ENV:TEMPLATE_ANALYZER_LOGS_CONTAINER_NAME"
)
[OutputType([bool])]
(
    [object] $OldRow,
    [object] $NewRow,
    [string] $PropertyName
) {
    $OldValue = $OldRow.$PropertyName
    $NewValue = $NewRow.$PropertyName
    Write-Output "Comparison results for ${propertyName}: '$OldValue' -> '$NewValue'"
    if (![string]::IsNullOrWhiteSpace($NewValue)) {
    $OldResultPassed = $OldValue -eq "PASS"
    $NewResultPassed = $NewValue -eq "PASS"
        if ($OldResultPassed -and !$NewResultPassed) {
            Write-Warning "REGRESSION: $PropertyName changed from '$OldValue' to '$NewValue'"
            return $true
        }
    }
    return $false
}
function Convert-EntityToHashtable([PSCustomObject] $entity) {
    $hashtable = New-Object -Type Hashtable
    $entity | Get-Member -MemberType NoteProperty | ForEach-Object {
    $name = $_.Name
        if ($name -ne "PartitionKey" -and $name -ne "RowKey" -and $name -ne "Etag" -and $name -ne "TableTimestamp" ) {
    $hashtable[$name] = $entity.$Name
        }
    }
    return $hashtable
}
Write-Output "Storage account name: $StorageAccountName"
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -Environment AzureCloud
    $IsPullRequest = $false
if ($BuildReason -eq "PullRequest" ) {
    $IsPullRequest = $true
    $t = $TableNamePRs
}
else {
    $t = $TableName
}
Write-Output "Writing to table $t"
if (($BicepVersion -ne "" ) -and !($BicepVersion -match " ^[0-9]+\.[-0-9a-z.]+$" )) {
    Write-Error "Unexpected bicep version format: $BicepVersion.  This may be caused by a previous error in the pipeline"
}
    $CloudTable = (Get-AzStorageTable -Name $t -Context $ctx).CloudTable
    $PathToMetadata = " $SampleFolder\metadata.json"
Write-Output "PathToMetadata: $PathToMetadata"
    $RowKey = $SampleName.Replace(" \" , "@" ).Replace("/" , "@" )
Write-Output "RowKey: $RowKey"
    $Metadata = Get-Content -ErrorAction Stop $PathToMetadata -Raw | ConvertFrom-Json
    $PartitionKey = $Metadata.Type
$r = Get-AzTableRow -table $CloudTable -PartitionKey $PartitionKey -RowKey $RowKey
    $ComparisonCloudTable = (Get-AzStorageTable -Name $TableName -Context $ctx).CloudTable
    $ComparisonResults = Get-AzTableRow -table $ComparisonCloudTable -PartitionKey $PartitionKey -RowKey $RowKey
Write-Output "Comparison table for previous results: $TableName"
Write-Output "Comparison table current results: $ComparisonResults"
if ($IsPullRequest) {
    $t1 = (Get-AzStorageTable -Name $TableName -Context $ctx).CloudTable
    $t2 = (Get-AzStorageTable -Name $TableNamePRs -Context $ctx).CloudTable
    $ItemDisplayName = $Metadata.itemDisplayName
    $r1 = Get-AzTableRow -Table $t1 -ColumnName itemDisplayName -Value $ItemDisplayName -Operator Equal
    $r2 = Get-AzTableRow -Table $t2 -ColumnName itemDisplayName -Value $ItemDisplayName -Operator Equal
    if ($r1.Count -gt 0) {
    $SameRow = ($r1.PartitionKey -eq $PartitionKey -and $r1.RowKey -eq $RowKey)
        if ($r1.count -ge 2 -or !$SameRow) {
            Write-Output "Duplicate sample name found in $TableName for: $ItemDisplayName"
            Write-Output " ##vso[task.setvariable variable=duplicate.metadata]$true"
            foreach ($_ in $r1) {
                Write-Output "RowKey: $($_.RowKey)"
            }
        }
    }
    if ($r2.Count -gt 0) {
    $SameRow = ($r2.PartitionKey -eq $PartitionKey -and $r2.RowKey -eq $RowKey)
        if ($r2.count -ge 2 -or !$SameRow) {
            Write-Output "Duplicate sample name found in $TableNamePRs for: $ItemDisplayName"
            Write-Output " ##vso[task.setvariable variable=duplicate.metadata]$true"
            foreach ($_ in $r2) {
                Write-Output "RowKey: $($_.RowKey)"
            }
        }
    }
}
if ($null -ne $r -and $AgentJobStatus -eq "Canceled" -and $BuildReason -ne "PullRequest" ) {
    if ($null -eq $r.status) {
        Add-Member -InputObject $r -NotePropertyName " status" -NotePropertyValue "Live"
    }
    else {
    $r.status = "Live"
    }
    Write-Output "Build Canceled, setting status back to Live"
    $r | Update-AzTableRow -table $CloudTable
    exit
}
    $BestPracticeResult = $BestPracticeResult -ireplace [regex]::Escape(" true" ), "PASS"
    $BestPracticeResult = $BestPracticeResult -ireplace [regex]::Escape(" false" ), "FAIL"
    $CredScanResult = $CredScanResult -ireplace [regex]::Escape(" true" ), "PASS"
    $CredScanResult = $CredScanResult -ireplace [regex]::Escape(" false" ), "FAIL"
    $FairfaxDeployment = $FairfaxDeployment -ireplace [regex]::Escape(" true" ), "PASS"
    $FairfaxDeployment = $FairfaxDeployment -ireplace [regex]::Escape(" false" ), "FAIL"
    $PublicDeployment = $PublicDeployment -ireplace [regex]::Escape(" true" ), "PASS"
    $PublicDeployment = $PublicDeployment -ireplace [regex]::Escape(" false" ), "FAIL"
    $TemplateAnalyzerResult = $TemplateAnalyzerResult -ireplace [regex]::Escape(" true" ), "PASS"
    $TemplateAnalyzerResult = $TemplateAnalyzerResult -ireplace [regex]::Escape(" false" ), "FAIL"
Write-Output "Supported Environments Found: $SupportedEnvironmentsJson"
    $SupportedEnvironments = ($SupportedEnvironmentsJson | ConvertFrom-JSON -AsHashTable)
if ($ValidationType -eq "Manual" ) {
    if ($SupportedEnvironments.Contains("AzureUSGovernment" )) {
    $FairfaxDeployment = "Manual Test"
    }
    if ($SupportedEnvironments.Contains("AzureCloud" )) {
    $PublicDeployment = "Manual Test"
    }
}
if ($null -eq $r) {
    Write-Output "No record found, adding a new one..."
    $results = New-Object -TypeName hashtable
    Write-Output "BP Result: $BestPracticeResult"
    if (![string]::IsNullOrWhiteSpace($BestPracticeResult)) {
        Write-Output "Adding BP results to hashtable..."
    $results.Add("BestPracticeResult" , $BestPracticeResult)
    }
    Write-Output "Adding Bicep version to hashtable..."
    $results.Add("BicepVersion" , $BicepVersion)
    Write-Output "CredScan Result: $CredScanResult"
    if (![string]::IsNullOrWhiteSpace($CredScanResult)) {
    $results.Add("CredScanResult" , $CredScanResult)
    }
    Write-Output "TemplateAnalyzer result: $TemplateAnalyzerResult"
    if (![string]::IsNullOrWhiteSpace($TemplateAnalyzerResult)) {
    $results.Add("TemplateAnalyzerResult" , $TemplateAnalyzerResult)
    }
    Write-Output "FF Result"
    if (![string]::IsNullOrWhiteSpace($FairfaxDeployment)) {
    $results.Add("FairfaxDeployment" , $FairfaxDeployment)
    $results.Add("FairfaxLastTestDate" , $FairfaxLastTestDate)
    }
    Write-Output "Mac Result"
    if (![string]::IsNullOrWhiteSpace($PublicDeployment)) {
    $results.Add("PublicDeployment" , $PublicDeployment)
    $results.Add("PublicLastTestDate" , $PublicLastTestDate)
    }
    Write-Output "New Record: adding metadata"
    $results.Add(" itemDisplayName" , $Metadata.itemDisplayName)
    $results.Add(" description" , $Metadata.description)
    $results.Add(" summary" , $Metadata.summary)
    $results.Add(" githubUsername" , $Metadata.githubUsername)
    $results.Add(" dateUpdated" , $Metadata.dateUpdated)
    if ($BuildReason -eq "PullRequest" ) {
    $results.Add(" status" , $BuildReason)
    $results.Add($($ResultDeploymentParameter + "BuildNumber" ), $ENV:BUILD_BUILDNUMBER)
    $results.Add(" pr" , $ENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER)
    }
    Write-Output "New Record: Dump results variable"
    $results | Format-List *
    $NewResults = $results.PSObject.copy()
    Write-Output "New Record: Add-AzTableRow"
    $params = @{
        table = $CloudTable
        property = $results
        partitionKey = $PartitionKey
        rowKey = $RowKey
    }
    Add-AzTableRow @params
}
else {
    Write-Output "Updating the existing record from:"
    $r | Format-List *
    if (![string]::IsNullOrWhiteSpace($BestPracticeResult)) {
        if ($null -eq $r.BestPracticeResult) {
            Add-Member -InputObject $r -NotePropertyName 'BestPracticeResult' -NotePropertyValue $BestPracticeResult
        }
        else {
    $r.BestPracticeResult = $BestPracticeResult
        }
    }
    if (![string]::IsNullOrWhiteSpace($TemplateAnalyzerResult)) {
        if ($null -eq $r.TemplateAnalyzerResult) {
            Add-Member -InputObject $r -NotePropertyName 'TemplateAnalyzerResult' -NotePropertyValue $TemplateAnalyzerResult
        }
        else {
    $r.TemplateAnalyzerResult = $TemplateAnalyzerResult
        }
    }
    if (![string]::IsNullOrWhiteSpace($BicepVersion)) {
        if ($null -eq $r.BicepVersion) {
            Add-Member -InputObject $r -NotePropertyName 'BicepVersion' -NotePropertyValue $BicepVersion
        }
        else {
    $r.BicepVersion = $BicepVersion
        }
    }
    if (![string]::IsNullOrWhiteSpace($CredScanResult)) {
        if ($null -eq $r.CredScanResult) {
            Add-Member -InputObject $r -NotePropertyName "CredScanResult" -NotePropertyValue $CredScanResult
        }
        else {
    $r.CredScanResult = $CredScanResult
        }
    }
    if (![string]::IsNullOrWhiteSpace($FairfaxDeployment)) {
        if ($null -eq $r.FairfaxDeployment) {
            Add-Member -InputObject $r -NotePropertyName "FairfaxDeployment" -NotePropertyValue $FairfaxDeployment
            Add-Member -InputObject $r -NotePropertyName "FairfaxLastTestDate" -NotePropertyValue $FairfaxLastTestDate -Force
        }
        else {
    $r.FairfaxDeployment = $FairfaxDeployment
    $r.FairfaxLastTestDate = $FairfaxLastTestDate
        }
    }
    if (![string]::IsNullOrWhiteSpace($PublicDeployment)) {
        if ($null -eq $r.PublicDeployment) {
            Add-Member -InputObject $r -NotePropertyName "PublicDeployment" -NotePropertyValue $PublicDeployment
            Add-Member -InputObject $r -NotePropertyName "PublicLastTestDate" -NotePropertyValue $PublicLastTestDate -Force
        }
        else {
    $r.PublicDeployment = $PublicDeployment
    $r.PublicLastTestDate = $PublicLastTestDate
        }
    }
    if ($BuildReason -eq "PullRequest" ) {
        if ($null -eq $r.status) {
            Add-Member -InputObject $r -NotePropertyName " status" -NotePropertyValue $BuildReason
        }
        else {
    $r.status = $BuildReason
        }
        if ($null -eq $r.pr) {
            Add-Member -InputObject $r -NotePropertyName " pr" -NotePropertyValue $ENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER
        }
        if ($null -eq $r.($ResultDeploymentParameter + "BuildNumber" )) {
            Add-Member -InputObject $r -NotePropertyName ($ResultDeploymentParameter + "BuildNumber" ) -NotePropertyValue $ENV:BUILD_BUILDNUMBER
        }
        else {
    $r.($ResultDeploymentParameter + "BuildNumber" ) = $ENV:BUILD_BUILDNUMBER
        }
        if ($null -eq $r.pr) {
            Add-Member -InputObject $r -NotePropertyName " pr" -NotePropertyValue $ENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER
        }
        else {
    $r.pr = $ENV:SYSTEM_PULLREQUEST_PULLREQUESTNUMBER
        }
    }
    else {
        if ($null -eq $r.status) {
            Add-Member -InputObject $r -NotePropertyName " status" -NotePropertyValue "Live"
        }
        else {
    $r.status = "Live"
        }
    }
    if ($null -eq $r.itemDisplayName) {
        Add-Member -InputObject $r -NotePropertyName " itemDisplayName" -NotePropertyValue $Metadata.itemDisplayName
    }
    else {
    $r.itemDisplayName = $Metadata.itemDisplayName
    }
    if ($null -eq $r.description) {
        Add-Member -InputObject $r -NotePropertyName " description" -NotePropertyValue $Metadata.description
    }
    else {
    $r.description = $Metadata.description
    }
    if ($null -eq $r.summary) {
        Add-Member -InputObject $r -NotePropertyName " summary" -NotePropertyValue $Metadata.summary
    }
    else {
    $r.summary = $Metadata.summary
    }
    if ($null -eq $r.githubUsername) {
        Add-Member -InputObject $r -NotePropertyName " githubUsername" -NotePropertyValue $Metadata.githubUsername
    }
    else {
    $r.githubUsername = $Metadata.githubUsername
    }
    if ($null -eq $r.dateUpdated) {
        Add-Member -InputObject $r -NotePropertyName " dateUpdated" -NotePropertyValue $Metadata.dateUpdated
    }
    else {
    $r.dateUpdated = $Metadata.dateUpdated
    }
    Write-Output "Updating to new results:"
    $r | Format-List *
    $r | Update-AzTableRow -table $CloudTable
    $NewResults = $r.PSObject.copy()
}
    $BPRegressed = Get-Regression -ErrorAction Stop $ComparisonResults $NewResults "BestPracticeResult"
    $FairfaxRegressed = Get-Regression -ErrorAction Stop $ComparisonResults $NewResults "FairfaxDeployment"
    $PublicRegressed = Get-Regression -ErrorAction Stop $ComparisonResults $NewResults "PublicDeployment"
    $TemplateAnalyzerRegressed = Get-Regression -ErrorAction Stop $ComparisonResults $NewResults "TemplateAnalyzerResult"
    $AnyRegressed = $BPRegressed -or $FairfaxRegressed -or $PublicRegresse
if (!$IsPullRequest) {
    Write-Output "Writing regression info to table '$RegressionsTableName'"
    $RegressionsTable = (Get-AzStorageTable -Name $RegressionsTableName -Context $ctx).CloudTable
    $RegressionsKey = Get-Date -Format " o"
    $RegressionsRow = $NewResults.PSObject.copy()
    $RegressionsRow | Add-Member "Sample" $RowKey
    $RegressionsRow | Add-Member "AnyRegressed" $AnyRegressed
    $RegressionsRow | Add-Member "BPRegressed" $BPRegressed
    $RegressionsRow | Add-Member "FairfaxRegressed" $FairfaxRegressed
    $RegressionsRow | Add-Member "PublicRegressed" $PublicRegressed
    $RegressionsRow | Add-Member "TemplateAnalyzerRegressed" $TemplateAnalyzerRegressed
    $RegressionsRow | Add-Member "BuildNumber" $ENV:BUILD_BUILDNUMBER
    $RegressionsRow | Add-Member "BuildId" $ENV:BUILD_BUILDID
    $RegressionsRow | Add-Member "Build" " https://dev.azure.com/azurequickstarts/azure-quickstart-templates/_build/results?buildId=$($ENV:BUILD_BUILDID)"
    $params = @{
        table = $RegressionsTable
        property = "(Convert-EntityToHashtable $RegressionsRow)"
        partitionKey = $PartitionKey
        rowKey = $RegressionsKey
    }
    Add-AzTableRow @params
}
Now write the badges to storage for the README.md files
$r = Get-AzTableRow -table $CloudTable -PartitionKey $PartitionKey -RowKey $RowKey
    $Badges = @{ }
    $na = "Not%20Tested"
if ($null -ne $r.PublicLastTestDate) {
    $PublicLastTestDate = $r.PublicLastTestDate.Replace(" -" , "." )
    $PublicLastTestDateColor = " black"
}
else {
    $PublicLastTestDate = $na
    $PublicLastTestDateColor = " inactive"
}
if ($null -ne $r.FairfaxLastTestDate) {
    $FairfaxLastTestDate = $r.FairfaxLastTestDate.Replace(" -" , "." )
    $FairfaxLastTestDateColor = " black"
}
else {
    $FairfaxLastTestDate = $na
    $FairfaxLastTestDateColor = " inactive"
}
if ($null -ne $r.FairfaxDeployment) {
    $FairfaxDeployment = ($r.FairfaxDeployment).ToString().ToLower().Replace(" true" , "PASS" ).Replace(" false" , "FAIL" )
}
switch ($FairfaxDeployment) {
    "PASS" { $FairfaxDeploymentColor = " brightgreen" }
    "FAIL" { $FairfaxDeploymentColor = " red" }
    "Not Supported" { $FairfaxDeploymentColor = " yellow" }
    "Manual Test" { $FairfaxDeploymentColor = " blue" }
    default {
    $FairfaxDeployment = $na
    $FairfaxDeploymentColor = " inactive"
    }
}
if ($null -ne $r.PublicDeployment) {
    $PublicDeployment = ($r.PublicDeployment).ToString().ToLower().Replace(" true" , "PASS" ).Replace(" false" , "FAIL" )
}
switch ($PublicDeployment) {
    "PASS" { $PublicDeploymentColor = " brightgreen" }
    "FAIL" { $PublicDeploymentColor = " red" }
    "Not Supported" { $PublicDeploymentColor = " yellow" }
    "Manual Test" { $PublicDeploymentColor = " blue" }
    default {
    $PublicDeployment = $na
    $PublicDeploymentColor = " inactive"
    }
}
if ($null -ne $r.BestPracticeResult) {
    $BestPracticeResult = ($r.BestPracticeResult).ToString().ToLower().Replace(" true" , "PASS" ).Replace(" false" , "FAIL" )
}
switch ($BestPracticeResult) {
    "PASS" { $BestPracticeResultColor = " brightgreen" }
    "FAIL" { $BestPracticeResultColor = " red" }
    default {
    $BestPracticeResult = $na
    $BestPracticeResultColor = " inactive"
    }
}
if ($null -ne $r.CredScanResult) {
    $CredScanResult = ($r.CredScanResult).ToString().ToLower().Replace(" true" , "PASS" ).Replace(" false" , "FAIL" )
}
switch ($CredScanResult) {
    "PASS" { $CredScanResultColor = " brightgreen" }
    "FAIL" { $CredScanResultColor = " red" }
    default {
    $CredScanResult = $na
    $CredScanResultColor = " inactive"
    }
}
switch ($TemplateAnalyzerResult) {
    "PASS" { $TemplateAnalyzerResultColor = " brightgreen" }
    "FAIL" { $TemplateAnalyzerResultColor = " red" }
    default {
    $TemplateAnalyzerResult = $na
    $TemplateAnalyzerResultColor = " inactive"
    }
}
    $BicepVersionColor = " brightgreen" ;
if ($BicepVersion -eq "" ) { $BicepVersion = " n/a" } # make sure the badge value is not empty
    $badges = @(
    @{
        " url"      = "https://img.shields.io/badge/Azure%20Public%20Test%20Date-$PublicLastTestDate-/?color=$PublicLastTestDateColor" ;
        " filename" = "PublicLastTestDate.svg" ;
    },
    @{
        " url"      = "https://img.shields.io/badge/Azure%20Public%20Test%20Result-$PublicDeployment-/?color=$PublicDeploymentColor" ;
        " filename" = "PublicDeployment.svg"
    },
    @{
        " url"      = "https://img.shields.io/badge/Azure%20US%20Gov%20Test%20Date-$FairfaxLastTestDate-/?color=$FairfaxLastTestDateColor" ;
        " filename" = "FairfaxLastTestDate.svg"
    },
    @{
        " url"      = "https://img.shields.io/badge/Azure%20US%20Gov%20Test%20Result-$FairfaxDeployment-/?color=$FairfaxDeploymentColor" ;
        " filename" = "FairfaxDeployment.svg"
    },
    @{
        " url"      = "https://img.shields.io/badge/Best%20Practice%20Check-$BestPracticeResult-/?color=$BestPracticeResultColor" ;
        " filename" = "BestPracticeResult.svg"
    },
    @{
        " url"      = "https://img.shields.io/badge/CredScan%20Check-$CredScanResult-/?color=$CredScanResultColor" ;
        " filename" = "CredScanResult.svg"
    },
    @{
        " url"      = "https://img.shields.io/badge/Bicep%20Version-$BicepVersion-/?color=$BicepVersionColor" ;
        " filename" = "BicepVersion.svg"
    },
    @{
        " url"      = "https://img.shields.io/badge/Template%20Analyzer%20Check-$TemplateAnalyzerResult-/?color=$TemplateAnalyzerResultColor" ;
        " filename" = "TemplateAnalyzerResult.svg"
    }
)
Write-Output "Uploading Badges..."
    $TempFolder = [System.IO.Path]::GetTempPath();
foreach ($badge in $badges) {
    $BadgeTempPath = Join-Path $TempFolder $badge.filename
    (Invoke-WebRequest -Uri $($badge.url)).Content | Set-Content -Path $BadgeTempPath -Force
if this is just a PR, we don't want to overwrite the live badges until it's merged
        just create the badges in the " pr" folder and they will be copied over by a CI build when merged
        scheduled builds should be put into the " live" container (i.e. badges)
    if ($BuildReason -eq "PullRequest" ) {
    $ContainerName = $PRsContainerName
    }
    else {
    $ContainerName = $BadgesContainerName
    }
    $BadgePath = $RowKey.Replace(" @" , "/" )
    $BlobName = " $BadgePath/$($badge.filename)"
    Write-Output "Uploading badge to storage account '$($StorageAccountName)', container '$($ContainerName)', name '$($BlobName)':"
    $badge | Format-List | Write-Output
    $params = @{
        Properties = "@{"ContentType" = " image/svg+xml" ; "CacheControl" = " no-cache" }"
        File = $BadgeTempPath
        Context = $ctx
        Blob = $BlobName
        Container = $ContainerName
    }
    Set-AzStorageBlobContent @params
}
    $TemplateAnalyzerLogFileName = " $($ENV:BUILD_BUILDNUMBER)_$RowKey.txt"
Write-Output "Uploading TemplateAnalyzer log file: $TemplateAnalyzerLogFileName"
try {
    $params = @{
        Properties = "@{ "ContentType" = " text/plain" }"
        File = $TemplateAnalyzerOutputFilePath
        Context = $ctx
        Blob = $TemplateAnalyzerLogFileName
        Container = $TemplateAnalyzerLogsContainerName
    }
    Set-AzStorageBlobContent @params
}
catch {
    Write-Output " ===================================================="
    Write-Output "Failed to upload $TemplateAnalyzerOutputFilePath   "
    Write-Output " ===================================================="
}
Debugging only
    $HTML = " <HTML>"
foreach ($badge in $badges) {
    $HTML = $HTML + " <IMG SRC=`" $($badge.url)`"/>&nbsp;"
}
    $HTML = $HTML + " </HTML>"
    $HTML | Set-Content -path " test.html"
Snippet that will be placed in the README.md files
<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/PublicLastTestDate.svg"/>&nbsp;
<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/PublicDeployment.svg"/>&nbsp;
<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/FairfaxLastTestDate.svg"/>&nbsp;
<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/FairfaxDeployment.svg"/>&nbsp;
<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/BestPracticeResult.svg"/>&nbsp;
<IMG SRC=" https://azurequickstartsservice.blob.core.windows.net/badges/100-blank-template/CredScanResult.svg"/>&nbsp;



