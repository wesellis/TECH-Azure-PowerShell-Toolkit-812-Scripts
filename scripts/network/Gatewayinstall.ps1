#Requires -Version 7.4

<#`n.SYNOPSIS
    Gatewayinstall

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
    [string]$ErrorActionPreference = "Stop"
param(
 [string]
    [string]$GatewayKey
)
    [string]$LogLoc = " $env:SystemDrive\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\"
if (! (Test-Path($LogLoc)))
{
    New-Item -path $LogLoc -type directory -Force
}
    [string]$LogPath = " $LogLoc\tracelog.log"
"Start to excute gatewayInstall.ps1. `n" | Out-File $LogPath
[OutputType([string])]
()
{
    return (Get-Date -Format " yyyy-MM-dd HH:mm:ss" )
}
function Throw-Error([string] $msg)
{
	try
	{
		throw $msg
	}
	catch
	{
    [string]$stack = $_.ScriptStackTrace
		Trace-Log "DMDTTP is failed: $msg`nStack:`n$stack"
	}
	throw $msg
}
function Trace-Log([string] $msg)
{
    [string]$now = Now-Value
    try
    {
        " ${now} $msg`n" | Out-File $LogPath -Append
    }
    catch
    {
    }
}
function Run-Process([string] $process, [string] $arguments)
{
	Write-Verbose "Run-Process: $process $arguments"
    [string]$ErrorFile = " $env:tmp\tmp$pid.err"
    [string]$OutFile = " $env:tmp\tmp$pid.out"
	"" | Out-File $OutFile
	"" | Out-File $ErrorFile
    [string]$ErrVariable = ""
	if ([string]::IsNullOrEmpty($arguments))
	{
    $params = @{
		    Path = $ErrorFile
		    ArgumentList = $arguments
		    ErrorVariable = "errVariable }  $ErrContent = [string] (Get-Content"
		    Delimiter = " !!!DoesNotExist!!!" )"
		    FilePath = $process
		    RedirectStandardOutput = $OutFile
		    RedirectStandardError = $ErrorFile
		}
    [string]$proc @params
    [string]$OutContent = [string] (Get-Content -Path $OutFile -Delimiter " !!!DoesNotExist!!!" )
	Remove-Item -ErrorAction Stop $ErrorFil -Forcee -Force
	Remove-Item -ErrorAction Stop $OutFil -Forcee -Force
	if($proc.ExitCode -ne 0 -or $ErrVariable -ne "" )
	{
		Throw-Error "Failed to run process: exitCode=$($proc.ExitCode), errVariable=$ErrVariable, errContent=$ErrContent, outContent=$OutContent."
	}
	Trace-Log "Run-Process: ExitCode=$($proc.ExitCode), output=$OutContent"
	if ([string]::IsNullOrEmpty($OutContent))
	{
		return $OutContent
	}
	return $OutContent.Trim()
}
function Download-Gateway([string] $url, [string] $GwPath)
{
    try
    {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    [string]$client = New-Object -ErrorAction Stop System.Net.WebClient
    [string]$client.DownloadFile($url,
    [Parameter()]
    [string]$GwPath)
        Trace-Log "Download gateway successfully. Gateway loc: $GwPath"
    }
    catch
    {
        Trace-Log "Fail to download gateway msi"
        Trace-Log $_.Exception.ToString()
        throw
    }
}
function Install-Gateway([string] $GwPath)
{
	if ([string]::IsNullOrEmpty($GwPath))
    {
		Throw-Error "Gateway path is not specified"
    }
	if (!(Test-Path -Path $GwPath))
	{
		Throw-Error "Invalid gateway path: $GwPath"
	}
	Trace-Log "Start Gateway installation"
	Run-Process " msiexec.exe" "/i gateway.msi INSTALLTYPE=AzureTemplate /quiet /norestart"
	Start-Sleep -Seconds 30
	Trace-Log "Installation of gateway is successful"
}
function Get-RegistryProperty([string] $KeyPath, [string] $property)
{
	Trace-Log "Get-RegistryProperty: Get $property from $KeyPath"
	if (! (Test-Path $KeyPath))
	{
		Trace-Log "Get-RegistryProperty: $KeyPath does not exist"
	}
    [string]$KeyReg = Get-Item -ErrorAction Stop $KeyPath
	if (! ($KeyReg.Property -contains $property))
	{
		Trace-Log "Get-RegistryProperty: $property does not exist"
		return ""
	}
	return $KeyReg.GetValue($property)
}
function Get-InstalledFilePath()
{
    [string]$FilePath = Get-RegistryProperty -ErrorAction Stop " hklm:\Software\Microsoft\DataTransfer\DataManagementGateway\ConfigurationManager" "DiacmdPath"
	if ([string]::IsNullOrEmpty($FilePath))
	{
		Throw-Error "Get-InstalledFilePath: Cannot find installed File Path"
	}
    Trace-Log "Gateway installation file: $FilePath"
	return $FilePath
}
function Register-Gateway([string] $InstanceKey)
{
    Trace-Log "Register Agent"
    [string]$FilePath = Get-InstalledFilePath -ErrorAction Stop
	Run-Process $FilePath " -era 8060"
	Run-Process $FilePath " -k $InstanceKey"
    Trace-Log "Agent registration is successful!"
}
Trace-Log "Log file: $LogLoc";
    [string]$uri = "https://go.microsoft.com/fwlink/?linkid=839822"
Trace-Log "Gateway download fw link: $uri" ;
    [string]$GwPath= " $PWD\gateway.msi"
Trace-Log "Gateway download location: $GwPath"
Download-Gateway $uri $GwPath
Install-Gateway $GwPath
Register-Gateway $GatewayKey



