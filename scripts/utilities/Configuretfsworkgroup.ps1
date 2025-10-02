#Requires -Version 7.4

<#
.SYNOPSIS
    Configure TFS Workgroup

.DESCRIPTION
    Azure automation script for Team Foundation Server workgroup configuration

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$TfsDownloadUrl = 'https://go.microsoft.com/fwlink/?LinkId=857132'
$InstallDirectory = "${env:ProgramFiles}\Microsoft Team Foundation Server 15.0"
$InstallKey = 'HKLM:\SOFTWARE\Microsoft\DevDiv\tfs\Servicing\15.0\serverCore'

function Ensure-TfsInstalled {
    $TfsInstalled = $false

    if (Test-Path $InstallKey) {
        $key = Get-Item -ErrorAction Stop $InstallKey
        $value = $key.GetValue("Install", $null)
        if (($null -ne $value) -and $value -eq 1) {
            $TfsInstalled = $true
        }
    }

    if (-not $TfsInstalled) {
        Write-Verbose "Installing TFS using ISO"
        $parent = [System.IO.Path]::GetTempPath()
        [string]$name = [System.Guid]::NewGuid()
        [string]$FullPath = Join-Path $parent $name

        try {
            New-Item -ItemType Directory -Path $FullPath | Out-Null

            Write-Verbose "Downloading TFS installer..."
            Invoke-WebRequest -UseBasicParsing -Uri $TfsDownloadUrl -OutFile "$FullPath\tfsserver2017.3.1_enu.iso"

            Write-Verbose "Mounting ISO..."
            $MountResult = Mount-DiskImage "$FullPath\tfsserver2017.3.1_enu.iso" -PassThru
            $DriveLetter = ($MountResult | Get-Volume).DriveLetter

            Write-Verbose "Running TFS installer..."
            $process = Start-Process -FilePath "${DriveLetter}:\TfsServer2017.3.1.exe" -ArgumentList '/quiet' -PassThru -Wait
            $process.WaitForExit()

            Start-Sleep -Seconds 90

            Write-Verbose "Dismounting ISO..."
            Dismount-DiskImage "$FullPath\tfsserver2017.3.1_enu.iso"
        }
        finally {
            if (Test-Path $FullPath) {
                Remove-Item -Path $FullPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    else {
        Write-Verbose "TFS is already installed"
    }
}

function Configure-TfsWorkgroup {
    param(
        [string]$SqlInstance = ".\SQLEXPRESS",
        [string]$WebSiteVDir = "DefaultCollection",
        [string]$CollectionName = "DefaultCollection",
        [string]$SiteBindings = "http:*:8080:"
    )

    $ConfigPath = "${InstallDirectory}\Tools"
    $TfsConfigExe = Join-Path $ConfigPath "TfsConfig.exe"

    if (-not (Test-Path $TfsConfigExe)) {
        throw "TFS configuration tool not found at: $TfsConfigExe"
    }

    Write-Verbose "Configuring TFS Workgroup..."

    $arguments = @(
        "unattend"
        "/configure"
        "/type:Standard"
        "/inputs:SqlInstance=$SqlInstance"
        "/inputs:WebSiteVDir=$WebSiteVDir"
        "/inputs:CollectionName=$CollectionName"
        "/inputs:SiteBindings=$SiteBindings"
        "/inputs:UseNTLM=True"
    )

    $process = Start-Process -FilePath $TfsConfigExe -ArgumentList $arguments -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "TFS configuration failed with exit code: $($process.ExitCode)"
    }

    Write-Verbose "TFS Workgroup configuration completed successfully"
}

function Set-TfsUrlAcl {
    param(
        [string]$Port = "8080"
    )

    Write-Verbose "Setting URL ACL for port $Port..."

    $urlAcl = "http://+:${Port}/"
    $user = "NT AUTHORITY\NETWORK SERVICE"

    try {
        $result = netsh http add urlacl url=$urlAcl user=$user
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "URL ACL may already exist or failed to set: $result"
        }
        else {
            Write-Verbose "URL ACL set successfully for $urlAcl"
        }
    }
    catch {
        Write-Warning "Failed to set URL ACL: $_"
    }
}

try {
    Write-Verbose "Starting TFS Workgroup configuration..."

    # Ensure TFS is installed
    Ensure-TfsInstalled

    # Set URL ACL for TFS
    Set-TfsUrlAcl

    # Configure TFS in workgroup mode
    Configure-TfsWorkgroup

    Write-Verbose "TFS Workgroup setup completed successfully"
}
catch {
    Write-Error "TFS configuration failed: $($_.Exception.Message)"
    throw
}