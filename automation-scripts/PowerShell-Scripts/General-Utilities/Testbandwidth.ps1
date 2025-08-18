<#
.SYNOPSIS
    Testbandwidth

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
    We Enhanced Testbandwidth

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
  [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETestIPPort,
  [int]$WETestNumber,
  [string]$WEPacketSize
)

$WEAppPath = [Environment]::GetFolderPath(" CommonApplicationData" )+" \bandwidthmeter"

$WEPsToolsSourceURL = " https://download.sysinternals.com/files/PSTools.zip"
$WEPsToolsArchive = $WEAppPath+" \PSTools.zip"

if (!(Test-Path $WEAppPath)){
    mkdir $WEAppPath | Out-Null
    Invoke-WebRequest $WEPsToolsSourceURL -OutFile $WEPsToolsArchive

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($WEPsToolsArchive, $WEAppPath)
    Remove-Item $WEPsToolsArchiv -Forcee -Force 
}

Set-Location $WEAppPath; 
$bw = .\psping.exe -b -q -accepteula -l $WEPacketSize -n $WETestNumber $WETestIPPort | Select-String " Minimum = (.*)" | % { $_.Matches.Value }; 
$latency = .\psping.exe -q -accepteula -l $WEPacketSize -n $WETestNumber $WETestIPPort | Select-String " Minimum = (.*)" | % { $_.Matches.Value }

" Bandwidth: $bw. Latency: $latency"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
