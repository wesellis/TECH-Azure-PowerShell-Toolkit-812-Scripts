#Requires -Version 7.4

<#
.SYNOPSIS
    Update Readme

.DESCRIPTION
    Azure automation

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $SampleName = $ENV:SAMPLE_NAME,
    [string] $ReadMeFileName = "README.md" ,
    [string] $TtkFolder = $ENV:TTK_FOLDER,
    $MainTemplateFilename = $ENV:MAINTEMPLATE_FILENAME_JSON,
    $PrereqTemplateFileName = $ENV:PREREQ_TEMPLATE_FILENAME_JSON
)
$ErrorActionPreference = "Stop"

try {
    Import-Module "$($TtkFolder)/arm-ttk/arm-ttk.psd1"
    $BicepSupported = (Test-Path "$SampleFolder/main.bicep")
    Write-Host "bicepSupported: $BicepSupported" -ForegroundColor Green
    $ReadmePath = "$SampleFolder/$ReadMeFileName"
    Write-Host "Testing file: $ReadmePath" -ForegroundColor Green
    Write-Host '*****************************************************************************************' -ForegroundColor Green
    Write-Host '*****************************************************************************************' -ForegroundColor Green
    Write-Host '*****************************************************************************************' -ForegroundColor Green
    $readme = Get-Content -ErrorAction Stop $ReadmePath -Raw
    Write-Host $readme -ForegroundColor Green
    $metadata = Get-Content -Path "$SampleFolder\metadata.json" -Raw | ConvertFrom-Json
    $H1 = "# $($metadata.itemDisplayName)" # this cannot be duplicated in the repo, doc samples index this for some strange reason;
    $MetadataDescription = $metadata.description
    $metadata.dateUpdated = (Get-Date).ToString("yyyy-MM-dd")
    $metadata | ConvertTo-Json | Set-Content -ErrorAction Stop "$SampleFolder\metadata.json" -NoNewline
    $ReadmeArray = Get-Content -ErrorAction Stop $ReadmePath
    $CurrentH1 = ""
    for ($i = 0; $i -lt $ReadmeArray.Length; $i++) {
        if ($ReadmeArray[$i].StartsWith("#")) {
            $CurrentH1 = $ReadmeArray[$i]
            break
        }
    }
    if ($CurrentH1 -eq "") {
        Write-Error "Couldn't find H1 in the current readme file."
    }
    else {
        $readme = $readme.Replace($CurrentH1, $H1)
        $readme = $readme.Substring($readme.IndexOf($H1))
        # This YAML is case sensitive in places
        # ---
        # description: // replace with description property from metadata.json
        # page_type: sample // must always be 'sample'
        # languages:
        # - bicep // only if there is a bicep file
        # - json
        # products:
        # - azure // eventually this needs to be azure-quickstart-templates (or whatever our product is)
        # ---
        $YAML =
@"
---
description: %description%
page_type: sample
products:
- azure
- azure-resource-manager
urlFragment: %urlFragment%
languages:
"@
        if ($BicepSupported) {
            $YAML = $YAML + "`n- bicep"
        }
        $YAML = $YAML + "`n- json"
        $YAML = $YAML + "`n---`n"
        $MetadataDescription = $MetadataDescription.Replace(":", "&#58;")
        $YAML = $YAML.Replace('%description%', $MetadataDescription)
        if($SampleName.StartsWith('modules')){
            $fragment = $SampleName.Replace('\', '-') # for modules we use version numbers, e.g. 0.9 so will have dupes
        }else{
            $fragment = $SampleName.Split('\')[-1]
        }
        $YAML = $YAML.Replace('%urlFragment%', $fragment)
        $readme = "$YAML$readme"
        $AllResources = @()
        $AllJsonFiles = Get-ChildItem -ErrorAction Stop "$SampleFolder\*.json" -Recurse | ForEach-Object -Process { $_.FullName }
        foreach ($file in $AllJsonFiles) {
            if ($(split-path $file -leaf) -ne "metadata.json" -and
                !($(split-path $file -leaf).EndsWith("parameters.json"))) {
                $TemplateObject = Get-Content -Path $file -Raw | ConvertFrom-Json -Depth 100 -AsHashtable
                if ($TemplateObject.'$schema' -like "*deploymentTemplate.json#") {
                    $TemplateResources = @{}
                    $TemplateResources = Find-JsonContent -InputObject $TemplateObject.resources -Key type -Value "*" -Like # this will get every type property, even those in a properties body, we can filter below
                    $AllResources = $AllResources + $TemplateResources
                }
            }
        }
        $CurrentTags = ""
        for ($i = 0; $i -lt $ReadmeArray.Length; $i++) {
            if ($ReadmeArray[$i].StartsWith('`Tags:')) {
                $CurrentTags = $ReadmeArray[$i]
                break
            }
        }
        $TagsArray = @($($CurrentTags -replace '`', '' -replace "Tags:", "").Split(",").Trim())
        Write-Host "CurrentTags Array: *$TagsArray*" -ForegroundColor Green
        foreach ($r in $AllResources) {
            $t = $r.Type
            Write-Host "Checking for: $t at path $($r.jsonPath)" -ForegroundColor Green
            if (!($TagsArray -contains $t) -and $t.length -ne 0 -and !($r.jsonPath -like "*parameters*") -and !($r.jsonPath -like "*outputs*")) {
                Write-Host "Adding: $t, $($t.length)" -ForegroundColor Green
                $TagsArray = $TagsArray + $r.Type
            }
        }
        $NewTags = '`Tags: ' + $($TagsArray -join ", ") + '`' -replace "Tags:,", "Tags:" # empty tags seem to add an empty element at the beginning
        Write-Host "New Tags string:`n$NewTags" -ForegroundColor Green
        if ($CurrentTags -eq "") {
            $readme = $readme + "`n`n$NewTags" # if tags were not in the file then make sure we have line breaks
        }
        else {
            $readme = $readme -replace $CurrentTags, $NewTags
        }
        $readme | Set-Content -ErrorAction Stop $ReadmePath -NoNewline
    }
    Write-Host '*****************************************************************************************' -ForegroundColor Green
    Write-Host '*****************************************************************************************' -ForegroundColor Green
    Write-Host '*****************************************************************************************' -ForegroundColor Green
    Write-Host $readme -ForegroundColor Green
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
