#Requires -Version 7.4

<#`n.SYNOPSIS
    Testbandwidth

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
  [Parameter()]
    [ValidateNotNullOrEmpty()]
    $TestIPPort,
  [int]$TestNumber,
  $PacketSize
)
    $AppPath = [Environment]::GetFolderPath("CommonApplicationData" )+" \bandwidthmeter"
    $PsToolsSourceURL = "https://download.sysinternals.com/files/PSTools.zip"
    $PsToolsArchive = $AppPath+" \PSTools.zip"
if (!(Test-Path $AppPath)){
    mkdir $AppPath | Out-Null
    Invoke-WebRequest $PsToolsSourceURL -OutFile $PsToolsArchive
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($PsToolsArchive, $AppPath)
    Remove-Item -ErrorAction Stop $PsToolsArchiv -Forcee -Force
}
Set-Location -ErrorAction Stop $AppPath;
    $bw = .\psping.exe -b -q -accepteula -l $PacketSize -n $TestNumber $TestIPPort | Select-String "Minimum = (.*)" | % { $_.Matches.Value };
    $latency = .\psping.exe -q -accepteula -l $PacketSize -n $TestNumber $TestIPPort | Select-String "Minimum = (.*)" | % { $_.Matches.Value }
"Bandwidth: $bw. Latency: $latency"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
