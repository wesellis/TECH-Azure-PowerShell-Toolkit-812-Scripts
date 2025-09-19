#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Install Bicep

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
    We Enhanced Install Bicep

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

Installs the bicep CLI



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $ttkFolder = $WEENV:TTK_FOLDER,
    $bicepUri = $WEENV:BICEP_URI
)

#region Functions




$installPath = " $ttkFolder\bicep"
$bicepFolder = New-Item -ItemType Directory -Path $installPath -Force; 
$bicepPath = " $bicepFolder\bicep.exe"
Write-WELog " $bicepPath" " INFO"
(New-Object -ErrorAction Stop Net.WebClient).DownloadFile($bicepUri, $bicepPath)
if (!(Test-Path $bicepPath)) {
    Write-Error " Couldn't find downloaded file $bicepPath"
}


; 
$p = $(Split-Path $bicepPath)
Write-WELog " adding: $p" " INFO"
Write-WELog " ##vso[task.prependpath]$p" " INFO" # this doesn't seem to work - see: https://github.com/microsoft/azure-pipelines-tasks/blob/master/docs/authoring/commands.md

$WEENV:PATH = " $p;$($WEENV:PATH)" # since the prependpath task isn't working explicitly set it here and will have to for each subsequent task since it doesn't carry across processes

Write-Information $WEENV:PATH
$bicepPath = $(Get-command -ErrorAction Stop bicep.exe).source # rewrite the var to make sure we have the correct bicep.exe

Write-WELog " Using bicep at: $bicepPath" " INFO"
Write-WELog " ##vso[task.setvariable variable=bicep.path]$bicepPath" " INFO"


& bicep --version | Tee-Object -variable fullVersionString
$fullVersionString | select-string -Pattern " (?<version>[0-9]+\.[-0-9a-z.]+)" | ForEach-Object { $_.matches.groups[1].value } | Tee-Object -variable bicepVersion

Write-WELog " Using bicep version: $bicepVersion" " INFO"
Write-WELog " ##vso[task.setvariable variable=bicep.version]$bicepVersion" " INFO"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
