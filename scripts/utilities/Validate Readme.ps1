#Requires -Version 7.4

<#`n.SYNOPSIS
    Validate Readme

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $SampleName = $ENV:SAMPLE_NAME,
    [string] $StorageAccountName = $ENV:STORAGE_ACCOUNT_NAME,
    [string] $ReadMeFileName = "README.md" ,
    [string] $SupportedEnvironmentsJson = $ENV:SUPPORTED_ENVIRONMENTS,
    [switch] $BicepSupported = ($ENV:BICEP_SUPPORTED -eq " true" ),
    [switch] $Fix
)
Write-Output "StorageAccountName: $StorageAccountName"
Write-Output " bicepSupported: $BicepSupported"
$s = $SampleName.Replace(" \" , "/" )
    $SEncoded = $SampleName.Replace(" \" , "%2F" ).Replace("/" , "%2F" )
    $PublicLinkMarkDown = @(
    " https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true"
    " https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F$SEncoded%2Fazuredeploy.json"
)
    $GovLinkMarkDown = @(
    " https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true"
    " https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F$SEncoded%2Fazuredeploy.json"
)
    $ARMVizMarkDown = @(
    " https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true"
    " http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F$SEncoded%2Fazuredeploy.json"
)
    $BadgeLinks = @(
    " https://$StorageAccountName.blob.core.windows.net/badges/$s/PublicLastTestDate.svg" ,
    " https://$StorageAccountName.blob.core.windows.net/badges/$s/PublicDeployment.svg" ,
    " https://$StorageAccountName.blob.core.windows.net/badges/$s/FairfaxLastTestDate.svg" ,
    " https://$StorageAccountName.blob.core.windows.net/badges/$s/FairfaxDeployment.svg" ,
    " https://$StorageAccountName.blob.core.windows.net/badges/$s/BestPracticeResult.svg" ,
    " https://$StorageAccountName.blob.core.windows.net/badges/$s/CredScanResult.svg"
)
if ($BicepSupported) {
    $BadgeLinks = $BadgeLinks + " https://$StorageAccountName.blob.core.windows.net/badges/$s/BicepVersion.svg"
}
    $PublicLinks = @()
    $PublicButton = $null
    $GovLinks = @()
    $GovButton = $null
Write-Output "Supported Environments Found: $SupportedEnvironmentsJson"
    $SupportedEnvironments = ($SupportedEnvironmentsJson | ConvertFrom-JSON -AsHashTable)
if ($SupportedEnvironments.Contains("AzureCloud" )) {
    $PublicLinks = $PublicLinkMarkDown
    $PublicButton = " [![Deploy To Azure]($($PublicLinks[0]))]($($PublicLinks[1]))"
}
if ($SupportedEnvironments.Contains("AzureUSGovernment" )) {
    $GovLinks = $GovLinkMarkDown
    $GovButton = " [![Deploy To Azure US Gov]($($GovLinks[0]))]($($GovLinks[1]))"
}
    $ARMVizLinks = $ARMVizMarkDown
    $ARMVizButton = " [![Visualize]($($ARMVizLinks[0]))]($($ARMVizLinks[1]))"
    $links = $ARMVizLinks + $PublicLinks + $GovLinks
Write-Output "Testing file: $SampleFolder/$ReadMeFileName"
    $ReadmeFile = (Get-Item -ErrorAction Stop $SampleFolder).GetFiles($ReadMeFileName)
if ($ReadmeFile.Name -cne 'README.md') {
    Write-Error "Readme file must be named README.md (with that exact casing)."
}
    $ReadmePath = " $SampleFolder/$ReadMeFileName"
    $readme = Get-Content -ErrorAction Stop $ReadmePath -Raw
    $BadgesError = $false
function Note-FixableError([string] $error) {
    if ($Fix) {
        Write-Warning  $error
        Write-Warning "Fix will be attempted"
    }
    else {
    $HelpMessage = @"
`n**** SEE BELOW FOR EXPECTED MARKUP TO COPY AND PASTE INTO THE README ****
"Pass in -Fix flag to attempt fix"
" @
        Write-Error " $error`n$HelpMessage"
    }
    $script:badgesError = $true
}
if (-not ($readme.StartsWith(" #" )) -and
    -not ($readme.StartsWith(" ---" ))) {
    Write-Error "Readme must start with # header or YAML block '---', not: $($readme[0])"
}
foreach ($badge in $BadgeLinks) {
    if (-not ($readme -clike " *$badge*" )) {
        Note-FixableError "Readme is missing badge: $badge"
    }
}
foreach ($link in $links) {
    if (-not ($readme -clike " *$link*" )) {
        Note-FixableError "Readme must have a button with the link: $link"
    }
}
if (!$SupportedEnvironments.Contains("AzureUSGovernment" ) -and $readme -like " *$($GovLinkMarkDown[1])*" ) {
    Note-FixableError "Readme contains link to $($GovLinkMarkDown[1]) but sample is not supported in AzureUSGovernment"
}
if (!$SupportedEnvironments.Contains("AzureCloud" ) -and $readme -like " *$($PublicLinkMarkDown[1])*" ) {
    Note-FixableError "Readme contains link to $($PublicLinkMarkDown[1]) but sample is not supported in AzureCloud"
}
if ( $BadgesError ) {
    if ($BicepSupported) {
    $BicepBadge = " `n![Bicep Version]($($BadgeLinks[6]))`n"
    }
    $md = @"
![Azure Public Test Date]($($BadgeLinks[0]))
![Azure Public Test Result]($($BadgeLinks[1]))
![Azure US Gov Last Test Date]($($BadgeLinks[2]))
![Azure US Gov Last Test Result]($($BadgeLinks[3]))
![Best Practice Check]($($BadgeLinks[4]))
![Cred Scan Check]($($BadgeLinks[5]))
    $BicepBadge
    $PublicButton
    $GovButton
    $ARMVizButton
" @
    if ($Fix) {
       ; -ExpectedMarkdown $md -ReadmeContents $readme
    $backup = New-TemporaryFile -ErrorAction Stop
        mv $ReadmePath $backup
        Set-Content -ErrorAction Stop $ReadmePath $fixed
        Write-Warning " ***************************************************************************************"
        Write-Warning "Fixes have been made to $ReadmePath"
        Write-Warning "Previous file was written to $backup"
        Write-Warning " ***************************************************************************************"
        Write-Output " ##vso[task.setvariable variable=fixed.readme]TRUE"
    }
    else {
        Write-Output ""
        Write-Output " ***************************************************************************************"
        Write-Output "Copy and paste the following markdown to the README just under the top line's heading:"
        Write-Output " ***************************************************************************************"
        Write-Output $md
        Write-Output ""
        Write-Output " ***************************************************************************************"
        Write-Output "End of copy and paste for README"
        Write-Output " ***************************************************************************************"
        Write-Output ""
    }
}
Write-Output "Count: $($error.count)"
if ($error.count -eq 0) {
    Write-Output " ##vso[task.setvariable variable=result.readme]PASS"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
