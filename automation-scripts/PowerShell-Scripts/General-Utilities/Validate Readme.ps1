<#
.SYNOPSIS
    Validate Readme

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
    We Enhanced Validate Readme

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
    [string] $WEStorageAccountName = $WEENV:STORAGE_ACCOUNT_NAME,
    [string] $WEReadMeFileName = " README.md" ,
    [string] $supportedEnvironmentsJson = $WEENV:SUPPORTED_ENVIRONMENTS, # the minified json array from metadata.json
    [switch] $bicepSupported = ($WEENV:BICEP_SUPPORTED -eq " true" ),
    [switch] $WEFix # If true, README will be fixed if possible
)

Write-WELog " StorageAccountName: $WEStorageAccountName" " INFO"
Write-WELog " bicepSupported: $bicepSupported" " INFO"

$s = $sampleName.Replace(" \" , " /" )
$sEncoded = $sampleName.Replace(" \" , " %2F" ).Replace(" /" , " %2F" )

$WEPublicLinkMarkDown = @(
    " https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true"
    " https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F$sEncoded%2Fazuredeploy.json"
)
$WEGovLinkMarkDown = @(
    " https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true"
    " https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F$sEncoded%2Fazuredeploy.json"
)
$WEARMVizMarkDown = @(
    " https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true"
    " http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F$sEncoded%2Fazuredeploy.json"
)

$badgeLinks = @(
    " https://$WEStorageAccountName.blob.core.windows.net/badges/$s/PublicLastTestDate.svg" ,
    " https://$WEStorageAccountName.blob.core.windows.net/badges/$s/PublicDeployment.svg" ,
    " https://$WEStorageAccountName.blob.core.windows.net/badges/$s/FairfaxLastTestDate.svg" ,
    " https://$WEStorageAccountName.blob.core.windows.net/badges/$s/FairfaxDeployment.svg" ,
    " https://$WEStorageAccountName.blob.core.windows.net/badges/$s/BestPracticeResult.svg" ,
    " https://$WEStorageAccountName.blob.core.windows.net/badges/$s/CredScanResult.svg"
)
if ($bicepSupported) {
    $WEBadgeLinks = $WEBadgeLinks + " https://$WEStorageAccountName.blob.core.windows.net/badges/$s/BicepVersion.svg"
}


$WEPublicLinks = @()
$WEPublicButton = $null
$WEGovLinks = @()
$WEGovButton = $null


Write-WELog " Supported Environments Found: $supportedEnvironmentsJson" " INFO"
$supportedEnvironments = ($supportedEnvironmentsJson | ConvertFrom-JSON -AsHashTable)


if ($supportedEnvironments.Contains(" AzureCloud" )) {
    $WEPublicLinks = $WEPublicLinkMarkDown
    $WEPublicButton = " [![Deploy To Azure]($($WEPublicLinks[0]))]($($WEPublicLinks[1]))"
}

if ($supportedEnvironments.Contains(" AzureUSGovernment" )) {
    $WEGovLinks = $WEGovLinkMarkDown
    $WEGovButton = " [![Deploy To Azure US Gov]($($WEGovLinks[0]))]($($WEGovLinks[1]))"
}

$WEARMVizLinks = $WEARMVizMarkDown
$WEARMVizButton = " [![Visualize]($($WEARMVizLinks[0]))]($($WEARMVizLinks[1]))"



$links = $WEARMVizLinks + $WEPublicLinks + $WEGovLinks

Write-Output " Testing file: $WESampleFolder/$WEReadMeFileName"


$readmeFile = (Get-Item $WESampleFolder).GetFiles($WEReadMeFileName)
if ($readmeFile.Name -cne 'README.md') {
    Write-Error " Readme file must be named README.md (with that exact casing)."
}

$readmePath = " $WESampleFolder/$WEReadMeFileName"
$readme = Get-Content $readmePath -Raw

$badgesError = $false

function WE-Note-FixableError([string] $error) {
    if ($WEFix) {
        Write-Warning  $error
        Write-Warning " Fix will be attempted"
    }
    else {
        $helpMessage = @"
`n**** SEE BELOW FOR EXPECTED MARKUP TO COPY AND PASTE INTO THE README ****
" Pass in -Fix flag to attempt fix"
" @
        Write-Error " $error`n$helpMessage"
    }

    $script:badgesError = $true
}


if (-not ($readme.StartsWith(" # " )) -and
    -not ($readme.StartsWith(" ---" ))) {
    Write-Error " Readme must start with # header or YAML block '---', not: $($readme[0])"
}


foreach ($badge in $badgeLinks) {
    if (-not ($readme -clike " *$badge*" )) {        
        Note-FixableError " Readme is missing badge: $badge"
    }
}


foreach ($link in $links) {
    #Write-Host $link
    if (-not ($readme -clike " *$link*" )) {
        Note-FixableError " Readme must have a button with the link: $link"
    }
}




if (!$supportedEnvironments.Contains(" AzureUSGovernment" ) -and $readme -like " *$($WEGovLinkMarkDown[1])*" ) {
    Note-FixableError " Readme contains link to $($WEGovLinkMarkDown[1]) but sample is not supported in AzureUSGovernment"
}
if (!$supportedEnvironments.Contains(" AzureCloud" ) -and $readme -like " *$($WEPublicLinkMarkDown[1])*" ) {
    Note-FixableError " Readme contains link to $($WEPublicLinkMarkDown[1]) but sample is not supported in AzureCloud"
}


if ( $badgesError ) {
  
    if ($bicepSupported) {
        $bicepBadge = " `n![Bicep Version]($($WEBadgeLinks[6]))`n"
    }

    # Create a string with what the metadata should look like
    $md = @"
![Azure Public Test Date]($($WEBadgeLinks[0]))
![Azure Public Test Result]($($WEBadgeLinks[1]))

![Azure US Gov Last Test Date]($($WEBadgeLinks[2]))
![Azure US Gov Last Test Result]($($WEBadgeLinks[3]))

![Best Practice Check]($($WEBadgeLinks[4]))
![Cred Scan Check]($($WEBadgeLinks[5]))
$bicepBadge
$WEPublicButton
$WEGovButton
$WEARMVizButton   
" @

    if ($WEFix) {
       ;  $fixed = & $WEPSScriptRoot/Get-FixedReadMe.ps1 `
            -ReadmeContents $readme `
            -ExpectedMarkdown $md

        # Back up existing
       ;  $backup = New-TemporaryFile
        mv $readmePath $backup

        # Write new readme
        Set-Content $readmePath $fixed

        Write-Warning " ***************************************************************************************"
        Write-Warning " Fixes have been made to $readmePath"
        Write-Warning " Previous file was written to $backup"
        Write-Warning " ***************************************************************************************"
        Write-WELog " ##vso[task.setvariable variable=fixed.readme]TRUE" " INFO"
    }
    else {
        Write-WELog "" " INFO"
        Write-WELog " ***************************************************************************************" " INFO"
        Write-WELog " Copy and paste the following markdown to the README just under the top line's heading:" " INFO"
        Write-WELog " ***************************************************************************************" " INFO"
        Write-Host $md
        Write-WELog "" " INFO"
        Write-WELog " ***************************************************************************************" " INFO"
        Write-WELog " End of copy and paste for README" " INFO"
        Write-WELog " ***************************************************************************************" " INFO"
        Write-WELog "" " INFO"
    }
}


Write-WELog " Count: $($error.count)" " INFO"
if ($error.count -eq 0) {
    Write-WELog " ##vso[task.setvariable variable=result.readme]PASS" " INFO"
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
