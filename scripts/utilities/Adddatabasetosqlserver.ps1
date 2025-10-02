#Requires -Version 7.4
#Requires -Modules SqlServer

<#
.SYNOPSIS
    Add database to SQL Server

.DESCRIPTION
    Add/restore database to SQL Server automation script

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserName,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [Parameter(Mandatory = $true)]
    [string]$ServerInstance = ".",

    [Parameter(Mandatory = $true)]
    [string]$BackupFilePath,

    [Parameter(Mandatory = $true)]
    [string]$DatabaseName,

    [Parameter()]
    [string]$RelocateDirectory = $env:temp
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    # Import SQL Server module
    if (Get-Module -ListAvailable SqlServer) {
        Import-Module -Name SqlServer
    }
    else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        Install-Module -Name SqlServer -Force -AllowClobber | Out-Null
        Import-Module -Name SqlServer
    }

    # Create credentials
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential($UserName, $securePassword)

    # Get file list from backup
    $fileListParams = @{
        QueryTimeout = 0
        ServerInstance = $ServerInstance
        Query = "RESTORE FILELISTONLY FROM DISK='$BackupFilePath'"
        Credential = $credentials
    }

    $fileList = Invoke-Sqlcmd @fileListParams

    # Create relocate files array
    $relocateFiles = @()
    foreach ($backupFile in $fileList) {
        $fileName = Split-Path -Path $backupFile.PhysicalName -Leaf
        $relocateFiles += New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($backupFile.LogicalName, "$RelocateDirectory\$fileName")
    }

    # Restore database
    $restoreParams = @{
        RelocateFile = $relocateFiles
        Database = $DatabaseName
        ServerInstance = $ServerInstance
        Credential = $credentials
        BackupFile = $BackupFilePath
        ReplaceDatabase = $true
    }

    Restore-SqlDatabase @restoreParams
    Write-Output "Database '$DatabaseName' restored successfully from '$BackupFilePath'"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}