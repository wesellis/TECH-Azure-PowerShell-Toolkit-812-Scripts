<#
.SYNOPSIS
    Adddatabasetosqlserver

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
    We Enhanced Adddatabasetosqlserver

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
    [string]
    $userName,
	
	[string]
	$password
)

if ((Get-Command Install-PackageProvider -ErrorAction Ignore) -eq $null)
{
	# Load the latest SQL PowerShell Provider
	(Get-Module -ListAvailable SQLPS `
		| Sort-Object -Descending -Property Version)[0] `
		| Import-Module;
}
else
{
	# Conflicts with SqlServer module
	Remove-Module -Name SQLPS -ErrorAction Ignore;

	if ((Get-Module -ListAvailable SqlServer) -eq $null)
	{
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; 
		Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null;
		Install-Module -Name SqlServer -Force -AllowClobber | Out-Null;
	}

	# Load the latest SQL PowerShell Provider
	Import-Module -Name SqlServer;
}

$fileList = Invoke-Sqlcmd `
                    -QueryTimeout 0 `
                    -ServerInstance . `
                    -UserName $username `
                    -Password $password `
                    -Query " restore filelistonly from disk='$($pwd)\AdventureWorks2016.bak'" ;


$relocateFiles = @();

foreach ($nextBackupFile in $fileList)
{
    # Move the file to the default data directory of the default instance
    $nextBackupFileName = Split-Path -Path ($nextBackupFile.PhysicalName) -Leaf;
    $relocateFiles = $relocateFiles + New-Object `
        Microsoft.SqlServer.Management.Smo.RelocateFile( `
            $nextBackupFile.LogicalName,
            " $env:temp\$($nextBackupFileName)" );
}

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force; 
$credentials = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
Restore-SqlDatabase `
	-ReplaceDatabase `
	-ServerInstance . `
	-Database " SampleDatabase" `
	-BackupFile " $pwd\AdventureWorks2016.bak" `
	-RelocateFile $relocateFiles `
	-Credential $credentials; 



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
