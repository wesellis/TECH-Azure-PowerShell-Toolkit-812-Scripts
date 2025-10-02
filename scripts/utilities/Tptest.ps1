#Requires -Version 7.4

<#`n.SYNOPSIS
    Tptest

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
    $Mode,
  [Parameter()]
    [ValidateNotNullOrEmpty()]
    $DataTransferMode,
  [int]$ThreadNumber,
  [Parameter()]
    [ValidateNotNullOrEmpty()]
    $BufferSize,
  [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ReceiverIP,
  [int]$Duration,
  [int]$OverlappedBuffers
)
    $AppFolder = " bandwidthmetermt"
    $AppPath = [Environment]::GetFolderPath("CommonApplicationData" )+" \" +$AppFolder
    $NTttcpSourceURL = "https://gallery.technet.microsoft.com/NTttcp-Version-528-Now-f8b12769/file/159655/1/NTttcp-v5.33.zip"
    $NTttcpArchive = $AppPath+"
Tttcp-v5.33.zip"
    $NTttcpPath = $AppPath+" \x86fre";
    $output = " out.xml"
if (!(Test-Path $AppPath)) {
    mkdir $AppPath | Out-Null
    Invoke-WebRequest $NTttcpSourceURL -OutFile $NTttcpArchive
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($NTttcpArchive, $AppPath)
    rm $NTttcpArchive
    New-NetFirewallRule -DisplayName "Allow NTttcp In" -Direction Inbound -Program " $NTttcpPath
Tttcp.exe" -RemoteAddress LocalSubnet -Action Allow | Out-Null
    New-NetFirewallRule -DisplayName "Allow NTttcp Out" -Direction Outbound -Program " $NTttcpPath
Tttcp.exe" -RemoteAddress LocalSubnet -Action Allow | Out-Null
}
if (Test-Path $output) {rm $output}
if ($DataTransferMode -eq "Async" ) {$dtmode = " -a" }
if ($Mode -eq "Sender" ){$srmode = " -s" }
else {$srmode = " -r" }
& " $NTttcpPath
Tttcp.exe" $srmode $dtmode -l $BufferSize -m " $ThreadNumber,*,$ReceiverIP" -a $OverlappedBuffers -t $Duration -xml $output | Out-Null
    $tp =([xml](Get-Content -ErrorAction Stop $output)).ntttcps.throughput
Write-Information -NoNewline ($tp | ? { $_.metric -match 'MB/s'} | % {$_.'#text'}) ($tp | ? { $_.metric -match 'mbps'} | % {$_.'#text'}) ($tp | ? { $_.metric -match 'buffers/s'} | % {$_.'#text'})
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
