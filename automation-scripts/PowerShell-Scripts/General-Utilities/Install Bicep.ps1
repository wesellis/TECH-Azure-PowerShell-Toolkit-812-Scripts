<#
.SYNOPSIS
    Install Bicep

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
Installs the bicep CLI
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $ttkFolder = $ENV:TTK_FOLDER,
    $bicepUri = $ENV:BICEP_URI
)
$installPath = " $ttkFolder\bicep"
$bicepFolder = New-Item -ItemType Directory -Path $installPath -Force;
$bicepPath = " $bicepFolder\bicep.exe"
Write-Host " $bicepPath"
(New-Object -ErrorAction Stop Net.WebClient).DownloadFile($bicepUri, $bicepPath)
if (!(Test-Path $bicepPath)) {
    Write-Error "Couldn't find downloaded file $bicepPath"
}
$p = $(Split-Path $bicepPath)
Write-Host " adding: $p"
Write-Host " ##vso[task.prependpath]$p" # this doesn't seem to work - see: https://github.com/microsoft/azure-pipelines-tasks/blob/master/docs/authoring/commands.md
$ENV:PATH = " $p;$($ENV:PATH)" # since the prependpath task isn't working explicitly set it here and will have to for each subsequent task since it doesn't carry across processes
Write-Host $ENV:PATH
$bicepPath = $(Get-command -ErrorAction Stop bicep.exe).source # rewrite the var to make sure we have the correct bicep.exe
Write-Host "Using bicep at: $bicepPath"
Write-Host " ##vso[task.setvariable variable=bicep.path]$bicepPath"
& bicep --version | Tee-Object -variable fullVersionString
$fullVersionString | select-string -Pattern " (?<version>[0-9]+\.[-0-9a-z.]+)" | ForEach-Object { $_.matches.groups[1].value } | Tee-Object -variable bicepVersion
Write-Host "Using bicep version: $bicepVersion"
Write-Host " ##vso[task.setvariable variable=bicep.version]$bicepVersion"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

