#Requires -Version 7.4

<#`n.SYNOPSIS
    Blobtransfer

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
	Copies a blob from one storage accout to another
	Copies a blob from one storage accout to another
.PARAMETER SourceImage
	SourceImage - Contains one or more full path URLs to source VHDs, if more than one must be provided, make them comma separated
				E.g.
				https://pmcsa06.blob.core.windows.net/system/Microsoft.Compute/Images/myimage01.vhd
				https://pmcsa06.blob.core.windows.net/system/Microsoft.Compute/Images/myimage01.vhd,https://pmcsa06.blob.core.windows.net/system/Microsoft.Compute/Images/myimage02.vhd
.PARAMETER SourceSAKey
	SourceSAKey - Source storage account Key
.PARAMETER DestinationURI
	DestinationURI - URI up to container level where blob(s) will be copied
.PARAMETER DestinationSAKey
	DestinationSAKey - Destination storage account Key
.NOTE
    AzCopy must always be updated to the latest version otherwise it mail fail executing it, Visual Studio solution must use the latest version.
.DISCLAIMER
	This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
    We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object
    code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software
    product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the
    Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims
    or lawsuits, including attorneys�� fees, that arise or result from the use or distribution of the Sample Code.
    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained
    within the Premier Customer Services Description.
[CmdletBinding()]
    [string]$ErrorActionPreference = "Stop"
param(
	[Parameter(Mandatory)]
	[string]$SourceImage ,
	[Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SourceSAKey,
	[Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationURI,
	[Parameter(Mandatory)]
	[string]$DestinationSAKey
)
function getBlobName
{
	param(
		[Parameter(Mandatory)]
		[string]$url
	)
    [string]$StartIndex = 0
	for ($i=0;$i -lt 4;$i++)
	{
		[int]$StartIndex = $url.IndexOf("/" ,$StartIndex)
    [string]$StartIndex++
	}
	return $url.Substring($StartIndex)
}
function getPathUpToContainerLevelfromUrl
{
	param(
		[Parameter(Mandatory)]
		[string]$url
	)
    [string]$StartIndex = 0
	for ($i=0;$i -lt 4;$i++)
	{
		[int]$StartIndex = $url.IndexOf("/" ,$StartIndex)
    [string]$StartIndex++
	}
	return $url.Substring(0,$StartIndex-1)
}
function getBlobCompletionStatus
{
	param(
		[Parameter(Mandatory)]
		[string]$AzCopyLogFile
	)
; -TypeName "PSObject" -Property "@{ "TotalFilesTransfered" =0; "TransferSuccessfully" =0; "TransferSkipped" =0; "TransferFailed" =0; "UserCancelled" =$false; "Success" =$false; "SummaryFound" =$false; "ErrorMessage" =[string]::Empty; "ElapsedTime" =[string]::Empty }"
    [string]$AzCopyOutput = Get-Content -ErrorAction Stop $AzCopyLogFile
	for ($i=$AzCopyOutput.Count-1 ;$i -ge 0; $i--)
	{
    [string]$line = $AzCopyOutput[$i]
		if ($line.Contains("Transfer failed" ))
		{
    [string]$ResultObject.TransferFailed = $line.Split(" :" )[1].Trim()
		}
		elseif ($line.Contains("Transfer skipped" ))
		{
    [string]$ResultObject.TransferSkipped = $line.Split(" :" )[1].Trim()
		}
		elseif ($line.Contains("Transfer successfully" ))
		{
    [string]$ResultObject.TransferSuccessfully = $line.Split(" :" )[1].Trim()
		}
		elseif ($line.Contains("Total files transferred" ))
		{
    [string]$ResultObject.TotalFilesTransfered = $line.Split(" :" )[1].Trim()
		}
		elseif ($line.Contains("Transfer summary" ))
		{
    [string]$ResultObject.SummaryFound = $true
		}
		elseif ($line.Contains("User canceled this process" ) -or $line.Contains("A task was canceled" ))
		{
    [string]$ResultObject.UserCancelled = $true
		}
		elseif ($line.Contains("Elapsed time" ))
		{
    [string]$ResultObject.ElapsedTime = $line.Substring($line.IndexOf(" :" )).Trim()
		}
	}
	if (!$ResultObject.SummaryFound)
	{
    [string]$ResultObject.Success  = $false
    [string]$ResultObject.ErrorMessage = "Blob copy $BlobName failed. AzCopy Summary information could not be located"
		return $ResultObject
	}
	if (!$ResultObject.UserCancelled -and $ResultObject.TransferFailed -eq 0 -and $ResultObject.TotalFilesTransfered -eq 1)
	{
    [string]$ResultObject.Success  = $true
	}
	return $ResultObject
}
try
{
    [string]$SourceImageList = $SourceImage.Split(" ," ,[StringSplitOptions]::RemoveEmptyEntries)
    [string]$ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Definition)
    [string]$CurrentScriptFolder = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
	"Current folder $CurrentScriptFolder" | Out-File " c:\$ScriptName.txt"
    [string]$url = " http://aka.ms/downloadazcopy"
    [string]$LocalPath = Join-Path $CurrentScriptFolder "MicrosoftAzureStorageTools.msi"
	"Downloading AzCopy from $url" | Out-File " c:\$ScriptName.txt" -Append
	if(!(Split-Path -parent $LocalPath) -or !(Test-Path -pathType Container (Split-Path -parent $LocalPath)))
	{
    [string]$LocalPath = Join-Path $pwd (Split-Path -leaf $LocalPath)
	}
	"Saving file at [$LocalPath]" | Out-File " c:\$ScriptName.txt" -Append
    [string]$client = new-object -ErrorAction Stop System.Net.WebClient
    [string]$client.DownloadFile($url, $LocalPath)
	"Installing AzCopy" | Out-File " c:\$ScriptName.txt" -Append
    [string]$AzCopyInstallLogFileName = " $CurrentScriptFolder\azCopyInstallLog.txt"
	Invoke-Command -ScriptBlock { & cmd /c " msiexec.exe /i $LocalPath /log $AzCopyInstallLogFileName"/qn}
    [string]$InstallLog = Get-Content -ErrorAction Stop $AzCopyInstallLogFileName
    [string]$InstallFolder = ($InstallLog | ? {$_ -match "AZURESTORAGETOOLSFOLDER" }).Split(" =" )[1].Trim()
    [string]$AzCopyTool = Join-Path $InstallFolder "AzCopy\Azcopy.exe"
	"Azcopy Path => $AzCopyTool" | Out-File " c:\$ScriptName.txt" -Append
	"Source images URLs =>" | Out-File " c:\$ScriptName.txt" -Append
	foreach ($url in $SourceImageList)
	{
		"    $url" | Out-File " c:\$ScriptName.txt" -Append
	}
	"SourceSAKey => $SourceSAKey" | Out-File " c:\$ScriptName.txt" -Append
	"DestinationURI => $DestinationURI" | Out-File " c:\$ScriptName.txt" -Append
	"DestinationSAKey => $DestinationSAKey" | Out-File " c:\$ScriptName.txt" -Append
	foreach ($url in $SourceImageList)
	{
		"Copying blob $url" | Out-File " c:\$ScriptName.txt" -Append
    [string]$SourceURIContainer = getPathUpToContainerLevelfromUrl -url $url
		"   SourceURIContainer = $SourceURIContainer" | Out-File " c:\$ScriptName.txt" -Append
    [string]$BlobName = getBlobName -url $url
		"   BlobName = $BlobName" | Out-File " c:\$ScriptName.txt" -Append
    [string]$AzCopyLogFile = " $PSScriptRoot\azcopylog-$BlobName.txt"
		"   azCopyLogFile = $AzCopyLogFile" | Out-File " c:\$ScriptName.txt" -Append
		"   Running AzCopy Tool..." | Out-File " c:\$ScriptName.txt" -Append
		& $AzCopyTool "/Source:$SourceURIContainer" , "/S" , "/Dest:$DestinationURI" , "/DestKey:$DestinationSAKey" , "/Pattern:$BlobName" , "/Y" , "/V:$AzCopyLogFile" , "/NC:20"
		"   Checking blob copy status..." | Out-File " c:\$ScriptName.txt" -Append
    [string]$result = getBlobCompletionStatus -AzCopyLogFile $AzCopyLogFile
		if ($result.Success)
		{
			"Blob $url successfuly transfered to $DestinationURI" | Out-File " c:\$ScriptName.txt" -Append
			"   Elapsed time $($result.ElapsedTime)" | Out-File " c:\$ScriptName.txt" -Append
		}
		else
		{
			throw "Blob $url copy failed to $DestinationURI, please analyze logs and retry operation."
		}
	}
	"Blob copy operation completed with success." | Out-File " c:\$ScriptName.txt" -Append
}
catch
{
	"An error ocurred: $_" | Out-File " c:\$ScriptName.txt" -Append`n}
