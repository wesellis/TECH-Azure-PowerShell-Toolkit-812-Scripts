<#
.SYNOPSIS
    We Enhanced Tptest

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

[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
  [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEMode,
  [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDataTransferMode,
  [int]$WEThreadNumber,
  [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEBufferSize,
  [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEReceiverIP,
  [int]$WEDuration,
  [int]$WEOverlappedBuffers
)

$WEAppFolder = "bandwidthmetermt"
$WEAppPath = [Environment]::GetFolderPath(" CommonApplicationData")+" \"+$WEAppFolder

$WENTttcpSourceURL = " https://gallery.technet.microsoft.com/NTttcp-Version-528-Now-f8b12769/file/159655/1/NTttcp-v5.33.zip"
$WENTttcpArchive = $WEAppPath+" \NTttcp-v5.33.zip"
$WENTttcpPath = $WEAppPath+" \x86fre"
$output = " out.xml"

if (!(Test-Path $WEAppPath)) {
    mkdir $WEAppPath | Out-Null
    Invoke-WebRequest $WENTttcpSourceURL -OutFile $WENTttcpArchive

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($WENTttcpArchive, $WEAppPath)
    rm $WENTttcpArchive 

    New-NetFirewallRule -DisplayName " Allow NTttcp In" -Direction Inbound -Program " $WENTttcpPath\NTttcp.exe" -RemoteAddress LocalSubnet -Action Allow | Out-Null
    New-NetFirewallRule -DisplayName " Allow NTttcp Out" -Direction Outbound -Program " $WENTttcpPath\NTttcp.exe" -RemoteAddress LocalSubnet -Action Allow | Out-Null
}

if (Test-Path $output) {rm $output}

if ($WEDataTransferMode -eq " Async") {$dtmode = " -a"}

if ($WEMode -eq " Sender"){$srmode = " -s"}
else {$srmode = " -r"}

& " $WENTttcpPath\NTttcp.exe" $srmode $dtmode -l $WEBufferSize -m " $WEThreadNumber,*,$WEReceiverIP" -a $WEOverlappedBuffers -t $WEDuration -xml $output | Out-Null
; 
$tp =([xml](Get-Content $output)).ntttcps.throughput
Write-Host -NoNewline ($tp | ? { $_.metric -match 'MB/s'} | % {$_.'#text'}) ($tp | ? { $_.metric -match 'mbps'} | % {$_.'#text'}) ($tp | ? { $_.metric -match 'buffers/s'} | % {$_.'#text'})


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
