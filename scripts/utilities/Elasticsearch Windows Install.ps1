#Requires -Version 7.4

<#
.SYNOPSIS
    Installs Elasticsearch on Windows systems.

.DESCRIPTION
    This script automates the installation of Elasticsearch on Windows, including JDK setup,
    cluster configuration, and service installation. It can be used to setup either a single VM
    or a cluster configuration when run from within an ARM template.

.PARAMETER ElasticSearchVersion
    Version of Elasticsearch to install (e.g., 1.7.3, 2.4.0).

.PARAMETER JdkDownloadLocation
    URL of the JDK installer. Defaults to Oracle JDK 8u65 if not specified.

.PARAMETER ElasticSearchBaseFolder
    Disk location of the base folder for Elasticsearch installation.

.PARAMETER DiscoveryEndpoints
    Formatted string of allowed subnet addresses for unicast internode communication.
    Format: 10.0.0.4-3 expands to [10.0.0.4,10.0.0.5,10.0.0.6].

.PARAMETER ElasticClusterName
    Name of the Elasticsearch cluster.

.PARAMETER StorageKey
    Azure storage key for cloud plugin configuration.

.PARAMETER MarvelEndpoints
    Marvel monitoring endpoints for cluster monitoring.

.PARAMETER po
    Azure storage account name for cloud plugin.

.PARAMETER r
    Azure storage key for cloud plugin.

.PARAMETER MarvelOnlyNode
    Configure VM as Marvel-only node.

.PARAMETER MasterOnlyNode
    Configure VM as master-only node.

.PARAMETER ClientOnlyNode
    Configure VM as client-only node.

.PARAMETER DataOnlyNode
    Configure VM as data-only node.

.PARAMETER m
    Install Marvel plugin.

.PARAMETER JmeterConfig
    Install and configure JMeter Server Agent.

.EXAMPLE
    .\Elasticsearch-Windows-Install.ps1 -ElasticSearchVersion "1.7.2" -ElasticClusterName "mycluster" -DiscoveryEndpoints "10.0.0.4-5" -MasterOnlyNode

.EXAMPLE
    .\Elasticsearch-Windows-Install.ps1 -ElasticSearchVersion "2.4.0" -ElasticClusterName "mycluster" -DiscoveryEndpoints "10.0.0.3-4" -DataOnlyNode

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ElasticSearchVersion,

    [ValidateNotNullOrEmpty()]
    [string]$JdkDownloadLocation,

    [ValidateNotNullOrEmpty()]
    [string]$ElasticSearchBaseFolder,

    [ValidateNotNullOrEmpty()]
    [string]$DiscoveryEndpoints,

    [ValidateNotNullOrEmpty()]
    [string]$ElasticClusterName,

    [ValidateNotNullOrEmpty()]
    [string]$StorageKey,

    [ValidateNotNullOrEmpty()]
    [string]$MarvelEndpoints,

    [ValidateNotNullOrEmpty()]
    [string]$po,

    [ValidateNotNullOrEmpty()]
    [string]$r,

    [switch]$MarvelOnlyNode,
    [switch]$MasterOnlyNode,
    [switch]$ClientOnlyNode,
    [switch]$DataOnlyNode,
    [switch]$m,
    [switch]$JmeterConfig
)

$ErrorActionPreference = "Stop"

Set-Variable -ErrorAction Stop regEnvPath -Option Constant -Value 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment'

function Log-Output {
    param([string]$Message)
    Write-Information $Message -ForegroundColor Cyan
}

function Log-Error {
    param([string]$Message)
    Write-Information $Message -ForegroundColor Red
}

Set-Alias -Name lmsg -Value Log-Output -Description "Displays an informational message in cyan color"
Set-Alias -Name lerr -Value Log-Error -Description "Displays an error message in red color"

function Initialize-Disks {
    $disks = Get-Disk -ErrorAction Stop | Where-Object partitionstyle -eq 'raw' | Sort-Object number
    $label = 'datadisk-'
    $letters = 70..90 | ForEach-Object { ([char]$_) }
    $LetterIndex = 0

    if ($null -ne $disks) {
        $NumberedDisks = $disks.Number -join ','
        lmsg "Found attached VHDs with raw partition and numbers $NumberedDisks"
        try {
            foreach ($disk in $disks) {
                $DriveLetter = $letters[$LetterIndex].ToString()
                lmsg "Formatting disk...$DriveLetter"
                $disk | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -UseMaximumSize -DriveLetter $DriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$label$LetterIndex" -Confirm:$false -Force | Out-Null
                $LetterIndex++
            }
        }
        catch [System.Exception] {
            lerr $_.Exception.Message
            lerr $_.Exception.StackTrace
            Break
        }
    }
    return $LetterIndex
}

function Create-DataFolders {
    param(
        [int]$NumDrives,
        [ValidateNotNullOrEmpty()]
        [string]$folder
    )

    $letters = 70..90 | ForEach-Object { ([char]$_) }
    $PathSet = @(0) * $NumDrives
    for ($i = 0; $i -lt $NumDrives; $i++) {
        $PathSet[$i] = $letters[$i] + ':\' + $folder
        New-Item -Path $PathSet[$i] -ItemType Directory | Out-Null
    }
    $RetVal = $PathSet -join ','
    lmsg "Created data folders: $RetVal"
    return $RetVal
}

function Download-Jdk {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetDrive,
        [string]$DownloadLocation
    )

    try {
        $destination = "$TargetDrive`:\Downloads\Java\jdk-8u65-windows-x64.exe"
        $source = if ($DownloadLocation -eq '') { 'http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-windows-x64.exe' } else { $DownloadLocation }
        $folder = split-path $destination
        if (!(Test-Path $folder)) {
            New-Item -Path $folder -ItemType Directory | Out-Null
        }
        $client = New-Object -ErrorAction Stop System.Net.WebClient
        $cookie = "oraclelicense=accept-securebackup-cookie"
        lmsg "Downloading JDK from $source to $destination"
        $client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
        $client.downloadFile($source, $destination) | Out-Null
    }
    catch [System.Net.WebException], [System.Exception] {
        lerr $_.Exception.Message
        lerr $_.Exception.StackTrace
        Break
    }
    return $destination
}

function Install-Jdk {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceLoc,
        [Parameter(Mandatory)]
        [string]$TargetDrive
    )

    $InstallPath = "$TargetDrive`:\Program Files\Java\Jdk"
    $HomefolderPath = (Get-Location).Path
    $LogPath = "$HomefolderPath\java_install_log.txt"
    $PsLog = "$HomefolderPath\java_install_ps_log.txt"
    $PsErr = "$HomefolderPath\java_install_ps_err.txt"

    try {
        lmsg "Installing java on the box under $InstallPath..."
        $proc = Start-Process -FilePath $SourceLoc -ArgumentList "/s INSTALLDIR=`"$InstallPath`"/L `"$LogPath`"" -Wait -PassThru -RedirectStandardOutput $PsLog -RedirectStandardError $PsErr -NoNewWindow
        $proc.WaitForExit()
        lmsg "JDK installed under $InstallPath" "Log file location: $LogPath"
    }
    catch [System.Exception] {
        lerr $_.Exception.Message
        lerr $_.Exception.StackTrace
        Break
    }
    return $InstallPath
}

function Download-ElasticSearch {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ElasticVersion,
        [Parameter(Mandatory)]
        [string]$TargetDrive
    )

    try {
        $source = if ($ElasticVersion -match '2.') { "https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/zip/elasticsearch/$ElasticVersion/elasticsearch-$ElasticVersion.zip" } else { "https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-$ElasticVersion.zip" }
        $destination = "$TargetDrive`:\Downloads\ElasticSearch\Elastic-Search.zip"
        $folder = split-path $destination
        if (!(Test-Path $folder)) {
            New-Item -Path $folder -ItemType Directory | Out-Null
        }
        $client = New-Object -ErrorAction Stop System.Net.WebClient
        lmsg "Downloading Elasticsearch version $ElasticVersion from $source to $destination"
        $client.downloadFile($source, $destination) | Out-Null
    }
    catch [System.Net.WebException], [System.Exception] {
        lerr $_.Exception.Message
        lerr $_.Exception.StackTrace
        Break
    }
    return $destination
}

function Unzip-Archive {
    param(
        [string]$archive,
        [string]$destination
    )

    $shell = New-Object -com shell.application
    $zip = $shell.NameSpace($archive)
    if (!(Test-Path $destination)) {
        lmsg "Creating $destination folder"
        New-Item -Path $destination -ItemType Directory | Out-Null
    }
    $destination = $shell.NameSpace($destination)
    $destination.CopyHere($zip.Items())
}

function SetEnv-JavaHome {
    param([string]$JdkInstallLocation)

    $HomePath = $JdkInstallLocation
    lmsg "Setting JAVA_HOME in the registry to $HomePath..."
    Set-ItemProperty -Path $regEnvPath -Name JAVA_HOME -Value $HomePath | Out-Null
    lmsg 'Setting JAVA_HOME for the current session...'
    Set-Item -ErrorAction Stop Env:JAVA_HOME "$HomePath" | Out-Null
    if ([environment]::GetEnvironmentVariable("JAVA_HOME", "machine") -eq $null) {
        [environment]::setenvironmentvariable("JAVA_HOME", $HomePath, "machine") | Out-Null
    }
    lmsg 'Modifying path variable to point to java executable...'
    $CurrentPath = (Get-ItemProperty -Path $regEnvPath -Name PATH).Path
    $CurrentPath = $CurrentPath + ';' + "$HomePath\bin"
    Set-ItemProperty -Path $regEnvPath -Name PATH -Value $CurrentPath
    Set-Item -ErrorAction Stop Env:PATH "$CurrentPath"
}

function SetEnv-HeapSize {
    $HalfRamCnt = [math]::Round(((Get-CimInstance -ErrorAction Stop Win32_PhysicalMemory | Measure-Object Capacity -sum).sum / 1mb) / 2, 0)
    $HalfRamCnt = [math]::Min($HalfRamCnt, 31744)
    $HalfRam = $HalfRamCnt.ToString() + 'm'
    lmsg "Half of total RAM in system is $HalfRam mb."
    lmsg "Setting ES_HEAP_SIZE in the registry to $HalfRam..."
    Set-ItemProperty -Path $regEnvPath -Name ES_HEAP_SIZE -Value $HalfRam | Out-Null
    lmsg 'Setting ES_HEAP_SIZE for the current session...'
    Set-Item -ErrorAction Stop Env:ES_HEAP_SIZE $HalfRam | Out-Null
    if ([environment]::GetEnvironmentVariable("ES_HEAP_SIZE", "machine") -eq $null) {
        [environment]::setenvironmentvariable("ES_HEAP_SIZE", $HalfRam, "machine") | Out-Null
    }
}

function Install-ElasticSearch {
    param(
        [string]$DriveLetter,
        [string]$ElasticSearchZip,
        [string]$SubFolder = $ElasticSearchBaseFolder
    )

    $ElasticSearchPath = Join-Path "$DriveLetter`:" -ChildPath $SubFolder
    Unzip-Archive $ElasticSearchZip $ElasticSearchPath
    return $ElasticSearchPath
}

function Implode-Host2 {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$DiscoveryHost
    )

    $DiscoveryHost = $DiscoveryHost.Trim()
    $DashSplitArr = $DiscoveryHost.Split('-')
    $PrefixAddress = $DashSplitArr[0]
    $loop = $DashSplitArr[1]
    $IpRange = @(0) * $loop
    for ($i = 0; $i -lt $loop; $i++) {
        $format = "$PrefixAddress$i"
        $IpRange[$i] = '"' + $format + '"'
    }
    $addresses = $IpRange -join ','
    return $addresses
}

function ElasticSearch-InstallService {
    param([string]$ScriptPath)

    $ElasticService = (Get-Service -ErrorAction Stop | Where-Object { $_.Name -match "elasticsearch" }).Name
    if ($null -eq $ElasticService) {
        SetEnv-HeapSize
        lmsg 'Installing elasticsearch as a service...'
        cmd.exe /C "$ScriptPath install"
        if ($LASTEXITCODE) {
            throw "Command '$ScriptPath': exit code: $LASTEXITCODE"
        }
    }
}

function ElasticSearch-StartService {
    $ElasticService = (Get-Service -ErrorAction Stop | Where-Object { $_.Name -match 'elasticsearch' }).Name
    if ($null -ne $ElasticService) {
        lmsg 'Starting elasticsearch service...'
        Start-Service -Name $ElasticService | Out-Null
        $svc = Get-Service -ErrorAction Stop | Where-Object { $_.Name -Match 'elasticsearch' }
        if ($null -ne $svc) {
            $svc.WaitForStatus('Running', '00:00:10')
        }
        lmsg 'Setting the elasticsearch service startup to automatic...'
        Set-Service -ErrorAction Stop $ElasticService -StartupType Automatic | Out-Null
    }
}

function ElasticSearch-VerifyInstall {
    $EsRequest = [System.Net.WebRequest]::Create("http://localhost:9200")
    $EsRequest.Method = "GET"
    $EsResponse = $EsRequest.GetResponse()
    $reader = New-Object -ErrorAction Stop System.IO.StreamReader($EsResponse.GetResponseStream())
    lmsg 'Elasticsearch service response status: ' $EsResponse.StatusCode
    lmsg 'Elasticsearch service response full text: ' $reader.ReadToEnd()
}

function Jmeter-Download {
    param([string]$drive)

    try {
        $destination = "$drive`:\Downloads\Jmeter\Jmeter_server_agent.zip"
        $source = 'http://jmeter-plugins.org/downloads/file/ServerAgent-2.2.1.zip'
        $folder = split-path $destination
        if (!(Test-Path $folder)) {
            New-Item -Path $folder -ItemType Directory | Out-Null
        }
        $client = New-Object -ErrorAction Stop System.Net.WebClient
        lmsg "Downloading Jmeter SA from $source to $destination"
        $client.downloadFile($source, $destination) | Out-Null
    }
    catch [System.Net.WebException], [System.Exception] {
        lerr $_.Exception.Message
        lerr $_.Exception.StackTrace
        Break
    }
    return $destination
}

function Jmeter-Unzip {
    param(
        [string]$source,
        [string]$drive
    )

    $shell = New-Object -com shell.application
    $zip = $shell.NameSpace($source)
    $loc = "$drive`:\jmeter_sa"
    if (!(Test-Path $loc)) {
        lmsg "Creating $loc folder"
        New-Item -Path $loc -ItemType Directory | Out-Null
    }
    $LocShell = $shell.NameSpace($loc)
    $LocShell.CopyHere($zip.Items())
    return $loc
}

function Jmeter-ConfigFirewall {
    for ($i = 4440; $i -le 4444; $i++) {
        lmsg 'Adding firewall rule - Allow Jmeter Inbound Port ' $i
        New-NetFirewallRule -Name "Jmeter_ServerAgent_IN_$i" -DisplayName "Allow Jmeter Inbound Port $i" -Protocol tcp -LocalPort $i -Action Allow -Enabled True -Direction Inbound | Out-Null
        lmsg 'Adding firewall rule - Allow Jmeter Outbound Port ' $i
        New-NetFirewallRule -Name "Jmeter_ServerAgent_OUT_$i" -DisplayName "Allow Jmeter Outbound Port $i" -Protocol tcp -LocalPort $i -Action Allow -Enabled True -Direction Outbound | Out-Null
    }
}

function Elasticsearch-OpenPorts {
    lmsg 'Adding firewall rule - Allow Elasticsearch Inbound Port 9200'
    New-NetFirewallRule -Name 'ElasticSearch_In_Lb' -DisplayName 'Allow Elasticsearch Inbound Port 9200' -Protocol tcp -LocalPort 9200 -Action Allow -Enabled True -Direction Inbound | Out-Null
    lmsg 'Adding firewall rule - Allow Elasticsearch Outbound Port 9200 for Marvel'
    New-NetFirewallRule -Name 'ElasticSearch_Out_Lb' -DisplayName 'Allow Elasticsearch Outbound Port 9200 for Marvel' -Protocol tcp -LocalPort 9200 -Action Allow -Enabled True -Direction Outbound | Out-Null
    lmsg 'Adding firewall rule - Allow Elasticsearch Inter Node Communication Inbound Port 9300'
    New-NetFirewallRule -Name 'ElasticSearch_In_Unicast' -DisplayName 'Allow Elasticsearch Inter Node Communication Inbound Port 9300' -Protocol tcp -LocalPort 9300 -Action Allow -Enabled True -Direction Inbound | Out-Null
    lmsg 'Adding firewall rule - Allow Elasticsearch Inter Node Communication Outbound Port 9300'
    New-NetFirewallRule -Name 'ElasticSearch_Out_Unicast' -DisplayName 'Allow Elasticsearch Inter Node Communication Outbound Port 9300' -Protocol tcp -LocalPort 9300 -Action Allow -Enabled True -Direction Outbound | Out-Null
}

function Jmeter-Run {
    param([string]$UnzipLoc)

    $TargetPath = Join-Path -Path $UnzipLoc -ChildPath 'startAgent.bat'
    lmsg 'Starting jmeter server agent at ' $TargetPath
    Start-Process -FilePath $TargetPath -WindowStyle Minimized | Out-Null
}

function Install-WorkFlow {
    Startup-Output
    $dc = Initialize-Disks
    if ($dc -gt 0) {
        $FolderPathSetting = (Create-DataFolders $dc 'elasticsearch\data')
    }
    $FirstDrive = (Get-Location).Drive.Name
    $JdkSource = Download-Jdk $FirstDrive
    $JdkInstallLocation = Install-Jdk $JdkSource $FirstDrive
    $ElasticSearchZip = Download-ElasticSearch $ElasticSearchVersion $FirstDrive
    if ($ElasticSearchBaseFolder.Length -eq 0) { $ElasticSearchBaseFolder = 'elasticSearch' }
    $ElasticSearchInstallLocation = Install-ElasticSearch $FirstDrive $ElasticSearchZip
    SetEnv-JavaHome $JdkInstallLocation
    if ($ElasticClusterName.Length -eq 0) { $ElasticClusterName = 'elasticsearch_cluster' }
    if ($DiscoveryEndpoints.Length -ne 0) { $IpAddresses = Implode-Host2 $DiscoveryEndpoints }
    $ElasticSearchBinParent = (Get-ChildItem -path $ElasticSearchInstallLocation -filter "bin" -Recurse).Parent.FullName
    $ElasticSearchBin = Join-Path $ElasticSearchBinParent -ChildPath "bin"
    $ElasticSearchConfFile = Join-Path $ElasticSearchBinParent -ChildPath "config\elasticsearch.yml"
    lmsg "Configure cluster name to $ElasticClusterName"
    $TextToAppend = "`n#### Settings automatically added by deployment script`ncluster.name: $ElasticClusterName"
    $hostname = (Get-CimInstance -Class Win32_ComputerSystem -Property Name).Name
    $TextToAppend = $TextToAppend + "`nnode.name: $hostname"
    if ($null -ne $FolderPathSetting) {
        $TextToAppend = $TextToAppend + "`npath.data: $FolderPathSetting"
    }
    if ($MasterOnlyNode) {
        lmsg 'Configure node as master only'
        $TextToAppend = $TextToAppend + "`nnode.master: true`nnode.data: false"
    }
    elseif ($DataOnlyNode) {
        lmsg 'Configure node as data only'
        $TextToAppend = $TextToAppend + "`nnode.master: false`nnode.data: true"
    }
    elseif ($ClientOnlyNode) {
        lmsg 'Configure node as client only'
        $TextToAppend = $TextToAppend + "`nnode.master: false`nnode.data: false"
    }
    else {
        lmsg 'Configure node as master and data'
        $TextToAppend = $TextToAppend + "`nnode.master: true`nnode.data: true"
    }
    $TextToAppend = $TextToAppend + "`ndiscovery.zen.minimum_master_nodes: 2"
    $TextToAppend = $TextToAppend + "`ndiscovery.zen.ping.multicast.enabled: false"
    if ($null -ne $IpAddresses) {
        $TextToAppend = $TextToAppend + "`ndiscovery.zen.ping.unicast.hosts: [$IpAddresses]"
    }
    if ($ElasticSearchVersion -match '2.') {
        $TextToAppend = $TextToAppend + "`nnetwork.host: _non_loopback_"
    }
    if ($po.Length -ne 0 -and $r.Length -ne 0) {
        if ($ElasticSearchVersion -match '2.') {
            cmd.exe /C "$ElasticSearchBin\plugin.bat install cloud-azure"
            $TextToAppend = $TextToAppend + "`ncloud.azure.storage.default.account: $po"
            $TextToAppend = $TextToAppend + "`ncloud.azure.storage.default.key: $r"
        }
        else {
            cmd.exe /C "$ElasticSearchBin\plugin.bat -i elasticsearch/elasticsearch-cloud-azure/2.8.2"
            $TextToAppend = $TextToAppend + "`ncloud.azure.storage.account: $po"
            $TextToAppend = $TextToAppend + "`ncloud.azure.storage.key: $r"
        }
    }
    if ($MarvelEndpoints.Length -ne 0) {
        $MarvelIPAddresses = Implode-Host2 $MarvelEndpoints
        if ($ElasticSearchVersion -match '2.') {
            $TextToAppend = $TextToAppend + "`nmarvel.agent.exporters:`n  id1:`n    type: http`n    host: [$MarvelIPAddresses]"
        }
        else {
            $TextToAppend = $TextToAppend + "`nmarvel.agent.exporter.hosts: [$MarvelIPAddresses]"
        }
    }
    if ($MarvelOnlyNode -and ($ElasticSearchVersion -match '1.')) {
        $TextToAppend = $TextToAppend + "`nmarvel.agent.enabled: false"
    }
    Add-Content $ElasticSearchConfFile $TextToAppend
    Elasticsearch-OpenPorts
    $ScriptPath = Join-Path $ElasticSearchBin -ChildPath "service.bat"
    ElasticSearch-InstallService $ScriptPath
    if ($m) {
        if ($ElasticSearchVersion -match '2.') {
            cmd.exe /C "$ElasticSearchBin\plugin.bat install license"
            cmd.exe /C "$ElasticSearchBin\plugin.bat install marvel-agent"
        }
        else {
            cmd.exe /C "$ElasticSearchBin\plugin.bat -i elasticsearch/marvel/1.3.1"
        }
    }
    if ($JmeterConfig) {
        $JmZip = Jmeter-Download $FirstDrive
        $UnzipLocation = Jmeter-Unzip $JmZip $FirstDrive
        Jmeter-ConfigFirewall
        Jmeter-Run $UnzipLocation
    }
    ElasticSearch-StartService
}

function Startup-Output {
    lmsg 'Install workflow starting with following params:'
    lmsg "Elasticsearch version: $ElasticSearchVersion"
    if ($ElasticClusterName.Length -ne 0) { lmsg "Elasticsearch cluster name: $ElasticClusterName" }
    if ($JdkDownloadLocation.Length -ne 0) { lmsg "Jdk download location: $JdkDownloadLocation" }
    if ($ElasticSearchBaseFolder.Length -ne 0) { lmsg "Elasticsearch base folder: $ElasticSearchBaseFolder" }
    if ($DiscoveryEndpoints.Length -ne 0) { lmsg "Discovery endpoints: $DiscoveryEndpoints" }
    if ($MarvelEndpoints.Length -ne 0) { lmsg "Marvel endpoints: $MarvelEndpoints" }
    if ($po.Length -ne 0 -and $r.Length -ne 0) { lmsg "Installing cloud-azure plugin" }
    if ($MasterOnlyNode) { lmsg 'Node installation mode: Master' }
    if ($ClientOnlyNode) { lmsg 'Node installation mode: Client' }
    if ($DataOnlyNode) { lmsg 'Node installation mode: Data' }
    if ($MarvelOnlyNode) { lmsg 'Node installation mode: Marvel' }
}

try {
    Install-WorkFlow
    Write-Output "Elasticsearch installation completed successfully"
}
catch {
    Write-Error "Elasticsearch installation failed: $($_.Exception.Message)"
    throw
}