<#
.SYNOPSIS
    We Enhanced Configuretfsbasic

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
)

$WEErrorActionPreference = 'Stop'


$WETfsDownloadUrl = 'https://go.microsoft.com/fwlink/?LinkId=857132'
$WEInstallDirectory = 'C:\Program Files\Microsoft Team Foundation Server 15.0'
$WEInstallKey = 'HKLM:\SOFTWARE\Microsoft\DevDiv\tfs\Servicing\15.0\serverCore'


function WE-Ensure-TfsInstalled()
{
    # Check if TFS is already installed.
    $tfsInstalled = $false

    if(Test-Path $WEInstallKey)
    {
        $key = Get-Item $WEInstallKey
        $value = $key.GetValue("Install" , $null)

        if(($value -ne $null) -and $value -eq 1)
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

            Invoke-WebRequest -UseBasicParsing -Uri $WETfsDownloadUrl -OutFile $fullPath\tfsserver2017.3.1_enu.iso

            $mountResult = Mount-DiskImage $fullPath\tfsserver2017.3.1_enu.iso -PassThru
            $driveLetter = ($mountResult | Get-Volume).DriveLetter
            
            $process = Start-Process -FilePath $driveLetter" :\TfsServer2017.3.1.exe" -ArgumentList '/quiet' -PassThru -Wait
            $process.WaitForExit()
            Start-Sleep -Seconds 90
        }
        finally 
        {
            Dismount-DiskImage -ImagePath $fullPath\tfsserver2017.3.1_enu.iso
            Remove-Item $fullPath\tfsserver2017.3.1_enu.iso -Force -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    else
    {
        Write-Verbose " TFS is already installed"
    }
}


function WE-Configure-TfsBasic()
{
    # Run tfsconfig to do the unattend install
    $path = Join-Path $WEInstallDirectory '\Tools\tfsconfig.exe'
   ;  $tfsConfigArgs = 'unattend /configure /type:Basic /inputs:" InstallSqlExpress=True"'

    Write-Verbose " Running tfsconfig..."

    Invoke-Expression " & '$path' $tfsConfigArgs"

    if($WELASTEXITCODE)
    {
        throw " tfsconfig.exe failed with exit code $WELASTEXITCODE . Check the TFS logs for more information"
    }
}

Ensure-TfsInstalled
Configure-TfsBasic


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
