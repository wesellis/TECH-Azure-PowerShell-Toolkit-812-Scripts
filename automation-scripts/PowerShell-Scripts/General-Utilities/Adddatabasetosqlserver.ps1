<#
.SYNOPSIS
    Adddatabasetosqlserver

.DESCRIPTION
    Azure automation
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
    [string]
    $userName,
	[string]
	$password
)
if ((Get-Command -ErrorAction Stop Install-PackageProvider -ErrorAction Ignore) -eq $null)
{
	# Load the latest SQL PowerShell Provider
	(Get-Module -ListAvailable "SQLPS | Sort-Object" -Property "Version)[0] | Import-Module;"
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
$params = @{
    QueryTimeout = "0"
    ServerInstance = "."
    Query = " restore filelistonly from disk='$($pwd)\AdventureWorks2016.bak'" ;"
    Password = $password
    UserName = $username
}
$fileList @params
$relocateFiles = @();
foreach ($nextBackupFile in $fileList)
{
    # Move the file to the default data directory of the default instance
    $nextBackupFileName = Split-Path -Path ($nextBackupFile.PhysicalName) -Leaf;
    $relocateFiles -ErrorAction "Stop Microsoft.SqlServer.Management.Smo.RelocateFile( $nextBackupFile.LogicalName, "$env:temp\$($nextBackupFileName)" );"
}
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
$credentials = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ($username, $securePassword)
$params = @{
    RelocateFile = $relocateFiles
    Database = "SampleDatabase"
    ServerInstance = "."
    Credential = $credentials;
    BackupFile = " $pwd\AdventureWorks2016.bak"
}
Restore-SqlDatabase @params
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

