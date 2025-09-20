#Requires -Version 7.0

<#`n.SYNOPSIS
    Configuretfsworkgroup

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
)
$TfsDownloadUrl = 'https://go.microsoft.com/fwlink/?LinkId=857132'
$InstallDirectory = '${env:ProgramFiles}\Microsoft Team Foundation Server 15.0'
$InstallKey = 'HKLM:\SOFTWARE\Microsoft\DevDiv\tfs\Servicing\15.0\serverCore'
function Ensure-TfsInstalled()
{
    # Check if TFS is already installed.
    $tfsInstalled = $false
    if(Test-Path $InstallKey)
    {
        $key = Get-Item -ErrorAction Stop $InstallKey
        $value = $key.GetValue("Install" , $null)
        if(($null -ne $value) -and $value -eq 1)
        {
            $tfsInstalled = $true
        }
    }
    if(-not $tfsInstalled)
    {
        Write-Verbose "Installing TFS using ISO"
        # Download TFS and mount it
        $parent = [System.IO.Path]::GetTempPath()
        [string] $name = [System.Guid]::NewGuid()
        [string] $fullPath = Join-Path $parent $name
        try
        {
            New-Item -ItemType Directory -Path $fullPath
            Invoke-WebRequest -UseBasicParsing -Uri $TfsDownloadUrl -OutFile $fullPath\tfsserver2017.3.1_enu.iso
            $mountResult = Mount-DiskImage $fullPath\tfsserver2017.3.1_enu.iso -PassThru
            $driveLetter = ($mountResult | Get-Volume).DriveLetter
            $process = Start-Process -FilePath $driveLetter" :\TfsServer2017.3.1.exe" -ArgumentList '/quiet' -PassThru -Wait
            $process.WaitForExit()
            Start-Sleep -Seconds 90
        }
        finally
        {
            Dismount-DiskImage -ImagePath $fullPath\tfsserver2017.3.1_enu.iso
            Remove-Item -ErrorAction Stop $fullPath\tfsserver2017.3.1_enu.is -Forceo -Force -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    else
    {
        Write-Verbose "TFS is already installed"
    }
}
function Configure-TfsWorkgroup()
{
    # Run tfsconfig to do the unattend install
$path = Join-Path $InstallDirectory '\Tools\tfsconfig.exe'
$tfsConfigArgs = 'unattend /configure /type:Basic /inputs:"InstallSqlExpress=True" '
    Write-Verbose "Running tfsconfig..."
    Invoke-Expression " & '$path' $tfsConfigArgs"
    if($LASTEXITCODE)
    {
        throw "tfsconfig.exe failed with exit code $LASTEXITCODE . Check the TFS logs for more information"
    }
}
Ensure-TfsInstalled
Configure-TfsWorkgroup
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
