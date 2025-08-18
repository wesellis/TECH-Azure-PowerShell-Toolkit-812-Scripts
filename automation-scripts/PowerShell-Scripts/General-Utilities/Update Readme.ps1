<#
.SYNOPSIS
    Update Readme

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
    We Enhanced Update Readme

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
    [string] $WESampleFolder = $WEENV:SAMPLE_FOLDER, # this is the path to the sample
    [string] $WESampleName = $WEENV:SAMPLE_NAME, # the name of the sample or folder path from the root of the repo e.g. " sample-type/sample-name"
    [string] $WEReadMeFileName = " README.md" ,
    [string] $ttkFolder = $WEENV:TTK_FOLDER,
    [string]$mainTemplateFilename = $WEENV:MAINTEMPLATE_FILENAME_JSON,
    [string]$prereqTemplateFileName = $WEENV:PREREQ_TEMPLATE_FILENAME_JSON
)


Import-Module " $($ttkFolder)/arm-ttk/arm-ttk.psd1"


$bicepSupported = (Test-Path " $WESampleFolder/main.bicep" )
Write-WELog " bicepSupported: $bicepSupported" " INFO"

$readmePath = " $WESampleFolder/$WEReadMeFileName"
Write-Output " Testing file: $readmePath"

Write-Output '*****************************************************************************************'
Write-Output '*****************************************************************************************'
Write-Output '*****************************************************************************************'


$readme = Get-Content $readmePath -Raw
Write-Output $readme


$metadata = Get-Content -Path " $WESampleFolder\metadata.json" -Raw | ConvertFrom-Json 
$WEH1 = " # $($metadata.itemDisplayName)" # this cannot be duplicated in the repo, doc samples index this for some strange reason; 
$metadataDescription = $metadata.description # note this will be truncated to 150 chars but the summary is usually the same as the itemDisplayName


$metadata.dateUpdated = (Get-Date).ToString(" yyyy-MM-dd" )
$metadata | ConvertTo-Json | Set-Content " $WESampleFolder\metadata.json" -NoNewline



[string[]]$readmeArray = Get-Content $readmePath
; 
$currentH1 = ""
for ($i = 0; $i -lt $readmeArray.Length; $i++) {
    if ($readmeArray[$i].StartsWith(" # " )) {
        # Get the current H1
        $currentH1 = $readmeArray[$i]
        break
    }
}

if ($currentH1 -eq "" ) {
    # we didn't find a header in the readme - throw and don't try to write the file
    Write-Error " Couldn't find H1 in the current readme file."
}
else {
    # we found H1 and can update the readme
    # replace # H1 with our new $WEH1
    $readme = $readme.Replace($currentH1, $WEH1)

    # remove everything before H1 so we can insert clean YAML (i.e. remove he previous YAML or any junk user submitted)
    $readme = $readme.Substring($readme.IndexOf($WEH1))

    <#
    This YAML is case sensitive in places
    ---
    description: // replace with description property from metadata.json
    page_type: sample // must always be 'sample'
    languages:
    - bicep // only if there is a bicep file
    - json
    products:
    - azure // eventually this needs to be azure-quickstart-templates (or whatever our product is)
    ---
    #>

    $WEYAML = 
@"
---
description: %description%
page_type: sample
products:
- azure
- azure-resource-manager
urlFragment: %urlFragment%
languages:
" @

    # add bicep to the list of languages as appropriate - it needs to be first in the list since doc samples only shows one at the moment
    if ($bicepSupported) {
        $WEYAML = $WEYAML + " `n- bicep"
    }

    # add JSON unconditionally, after bicep
    $WEYAML = $WEYAML + " `n- json"

    # close the YAML block
   ;  $WEYAML = $WEYAML + " `n---`n"

    # update the description
    # replace disallowed chars
   ;  $metadataDescription = $metadataDescription.Replace(" :" , " &#58;" )

    # set an urlFragment to the path to minimize dupes - we use the last segment of the path, which may not be unique, but it's a friendlier url
    $WEYAML = $WEYAML.Replace('%description%', $metadataDescription)
    if($WESampleName.StartsWith('modules')){
        $fragment = $WESampleName.Replace('\', '-') # for modules we use version numbers, e.g. 0.9 so will have dupes
    }else{
        $fragment = $WESampleName.Split('\')[-1]
    }
    $WEYAML = $WEYAML.Replace('%urlFragment%', $fragment)

    # prepend the YAML
    $readme = " $WEYAML$readme"

    # add tags
    $allResources = @()

    $allJsonFiles = Get-ChildItem " $sampleFolder\*.json" -Recurse | ForEach-Object -Process { $_.FullName }
    foreach ($file in $allJsonFiles) {
        if ($(split-path $file -leaf) -ne " metadata.json" -and
            !($(split-path $file -leaf).EndsWith(" parameters.json" ))) {
            $templateObject = Get-Content -Path $file -Raw | ConvertFrom-Json -Depth 100 -AsHashtable
            if ($templateObject.'$schema' -like " *deploymentTemplate.json#" ) {
                $templateResources = @{}
                $templateResources = Find-JsonContent -InputObject $templateObject.resources -Key type -Value " *" -Like # this will get every type property, even those in a properties body, we can filter below
               ;  $allResources = $allResources + $templateResources
            }
        }
    }

    # Find Current Tags
   ;  $currentTags = ""
    for ($i = 0; $i -lt $readmeArray.Length; $i++) {
        if ($readmeArray[$i].StartsWith('`Tags:')) {
            # Get the current Tags
            $currentTags = $readmeArray[$i]
            break
        }
    }

    $tagsArray = @($($currentTags -replace '`', '' -replace " Tags:" , "" ).Split(" ," ).Trim())

    Write-WELog " CurrentTags Array: *$tagsArray*" " INFO"
    foreach ($r in $allResources) {
        $t = $r.Type
        Write-WELog " Checking for: $t at path $($r.jsonPath)" " INFO"
        if (!($tagsArray -contains $t) -and $t.length -ne 0 -and !($r.jsonPath -like " *parameters*" ) -and !($r.jsonPath -like " *outputs*" )) {
            Write-WELog " Adding: $t, $($t.length)" " INFO"
            $tagsArray = $tagsArray + $r.Type
        }
    }
    
    $newTags = '`Tags: ' + $($tagsArray -join " , " ) + '`' -replace " Tags:," , " Tags:" # empty tags seem to add an empty element at the beginning

    Write-WELog " New Tags string:`n$newTags" " INFO"

    # replace the current Tags in the file if any
    if ($currentTags -eq "" ) {
        # Add to the end of the file
        $readme =;  $readme = $readme + " $newTags" # if tags were not in the file then make sure we have line breaks
    }
    else {
        #replace
       ;  $readme = $readme -replace $currentTags, $newTags
    }
        
    #Write-Output $readme
    $readme | Set-Content $readmePath -NoNewline

}


Write-Output '*****************************************************************************************'
Write-Output '*****************************************************************************************'
Write-Output '*****************************************************************************************'
Write-Output $readme



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
