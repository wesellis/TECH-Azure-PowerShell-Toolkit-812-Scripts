<#
.SYNOPSIS
    Refresh Quickstartstable

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
    We Enhanced Refresh Quickstartstable

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    $WEBuildSourcesDirectory = " $WEENV:BUILD_SOURCESDIRECTORY" , # absolute path to the clone
    [string]$WEStorageAccountName = $WEENV:STORAGE_ACCOUNT_NAME,
    $WETableName = " QuickStartsMetadataService" ,
    [Parameter(mandatory = $true)]$WEStorageAccountKey
)
<#

Get all metadata files in the repo
Get all the badges (if found) for the status
Update the table's LIVE or null records to reflect badge status and metadata contents
Remove old row and create new table row (i.e. update if exists)




while($WEBuildSourcesDirectory.EndsWith(" /" )){
    $WEBuildSourcesDirectory = $WEBuildSourcesDirectory.TrimEnd(" /" )
}
while($WEBuildSourcesDirectory.EndsWith(" \" )){
   ;  $WEBuildSourcesDirectory = $WEBuildSourcesDirectory.TrimEnd(" \" )
}
; 
$badges = @{
    PublicLastTestDate  = " https://$WEStorageAccountName.blob.core.windows.net/badges/%sample.folder%/PublicLastTestDate.svg" ;
    PublicDeployment    = " https://$WEStorageAccountName.blob.core.windows.net/badges/%sample.folder%/PublicDeployment.svg" ;
    FairfaxLastTestDate = " https://$WEStorageAccountName.blob.core.windows.net/badges/%sample.folder%/FairfaxLastTestDate.svg" ;
    FairfaxDeployment   = " https://$WEStorageAccountName.blob.core.windows.net/badges/%sample.folder%/FairfaxDeployment.svg" ;
    BestPracticeResult  = " https://$WEStorageAccountName.blob.core.windows.net/badges/%sample.folder%/BestPracticeResult.svg" ;
    CredScanResult      = " https://$WEStorageAccountName.blob.core.windows.net/badges/%sample.folder%/CredScanResult.svg" ;
    BicepVersion        = " https://$WEStorageAccountName.blob.core.windows.net/badges/%sample.folder%/BicepVersion.svg"
}


$WEArtifactFilePaths = Get-ChildItem -ErrorAction Stop $WEBuildSourcesDirectory\metadata.json -Recurse -File | ForEach-Object -Process { $_.FullName }

if ($WEArtifactFilePaths.Count -eq 0) {
    Write-Error " No metadata.json files found in $WEBuildSourcesDirectory"
    throw
}


$ctx = New-AzStorageContext -StorageAccountName $WEStorageAccountName -StorageAccountKey $WEStorageAccountKey -Environment AzureCloud
$cloudTable = (Get-AzStorageTable -Name $tableName -Context $ctx).CloudTable


$t = Get-AzTableRow -table $cloudTable



Write-WELog " Checking table to see if this is a new sample (does the row exist?)" " INFO"
foreach ($WESourcePath in $WEArtifactFilePaths) {
    
    if ($WESourcePath -like " *\test\*" ) {
        Write-Information " Skipping..."
        continue
    }

    Write-WELog " Reading: $WESourcePath" " INFO"
    $WEMetadataJson = Get-Content -ErrorAction Stop $WESourcePath -Raw | ConvertFrom-Json

    # Get the sample's path off of the root, replace any path chars with " @" since the rowkey for table storage does not allow / or \ (among other things)
    $WERowKey = (Split-Path $WESourcePath -Parent).Replace(" $(Resolve-Path $WEBuildSourcesDirectory)\" , "" ).Replace(" \" , " @" ).Replace(" /" , " @" )

    Write-WELog " RowKey from path: $WERowKey" " INFO"

    $r = Get-AzTableRow -table $cloudTable -ColumnName " RowKey" -Value $WERowKey -Operator Equal

    $p = @{ }

    Write-WELog " Status: $($r.status)" " INFO"

    # if the row isn't found in the table, it could be a new sample, add it with the data found in metadata.json
    Write-WELog " Updating: $WERowkey" " INFO"
        
    $p.Add(" itemDisplayName" , $WEMetadataJson.itemDisplayName)
    $p.Add(" description" , $WEMetadataJson.description)
    $p.Add(" summary" , $WEMetadataJson.summary)
    $p.Add(" githubUsername" , $WEMetadataJson.githubUsername)
    $p.Add(" dateUpdated" , $WEMetadataJson.dateUpdated)

    $p.Add(" status" , " Live" ) # if it's in master, it's live
    # $p.Add($($WEResultDeploymentParameter + " BuildNumber" ), " 0)

    #update the row if it's live or no status
    #if ($r.status -eq " Live" -or $r.status -eq $null) {

        #add status from badges

        $badges.GetEnumerator() | ForEach-Object {
            $uri = $($_.Value).replace(" %sample.folder%" , $WERowKey.Replace(" @" , " /" ))
            #Write-Information $uri
            $svg = $null
            try { $svg = (Invoke-WebRequest -Uri $uri -ErrorAction SilentlyContinue) } catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
            if ($svg) {
                $xml = $svg.content.replace('xmlns=" http://www.w3.org/2000/svg" ', '')
                #Write-Information $xml
                $t = Select-XML -Content $xml -XPath " //text"
                #$t | Out-string                
                #$v = $($t[$t.length - 1])
                #Write-WELog " $($_.Key) = $v" " INFO"
            
                $v = $($t[$t.length - 1]).ToString()

                # set the value in the table based on the value in the badge
                switch ($v) {
                    " PASS" {
                        $v = " PASS"
                    }
                    " FAIL" {
                        $v = " FAIL"
                    }
                    " Not Supported" {
                        $v = " Not Supported"
                    }
                    " Not Tested" {
                        $v = " Not Tested"
                    }
                    " Bicep Version" {
                        $v = " n/a" # this is a temp hack as bicep badges were created with no value
                    }
                    default {
                        # must be a date or bicep version, fix that below
                        #$v = $v.Replace(" ." , " -" )
                    }
                }
                if ($_.Key -like " *Date" ) { 
                    #;  $v = $WEMetadataJson.dateUpdated
                   ;  $v = $v.Replace(" ." , " -" )
                }
                if ($null -ne $v) {
                    $p.Add($_.Key, $v)
                }
                Write-WELog " $($_.Key) = $v" " INFO"
            }
        }
    #}

    #$p | out-string
    #Read-Host " Cont?"
    
    # if we didn't get the date from the badge, then add it from metadata.json
    if ([string]::IsNullOrWhiteSpace($p.FairfaxLastTestDate)) { 
        $p.Add(" FairfaxLastTestDate" , $WEMetadataJson.dateUpdated) 
    }
    if ([string]::IsNullOrWhiteSpace($p.PublicLastTestDate)) { 
        $p.Add(" PublicLastTestDate" , $WEMetadataJson.dateUpdated) 
    }

    # preserve the build number if possible
    if ([string]::IsNullOrWhiteSpace($r.FairfaxDeploymentBuildNumber)) { 
        $p.Add(" FairfaxDeploymentBuildNumber" , " 0" ) 
    }
    else {
        $p.Add(" FairfaxDeploymentBuildNumber" , $r.FairfaxDeploymentBuildNumber) 
    }
    if ([string]::IsNullOrWhiteSpace($r.PublicDeploymentBuildNumber)) { 
        $p.Add(" PublicDeploymentBuildNumber" , " 0" ) 
    }
    else {
        $p.Add(" PublicDeploymentBuildNumber" , $r.PublicDeploymentBuildNumber) 
    }

    Write-WELog " Removing... $($r.RowKey)" " INFO"
    $r | Remove-AzTableRow -Table $cloudTable
    Write-WELog " Adding... $WERowKey" " INFO"
    Add-AzTableRow -table $cloudTable `
        -partitionKey $WEMetadataJson.type `
        -rowKey $WERowKey `
        -property $p

} #foreach




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================