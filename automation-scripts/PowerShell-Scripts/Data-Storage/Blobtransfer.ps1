<#
.SYNOPSIS
    Blobtransfer

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
    We Enhanced Blobtransfer

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS
	Copies a blob from one storage accout to another
.DESCRIPTION
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
    or lawsuits, including attorneys� fees, that arise or result from the use or distribution of the Sample Code.
    Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained
    within the Premier Customer Services Description.


[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
	[Parameter(Mandatory=$true)]
	[string]$WESourceImage ,

	[Parameter(Mandatory=$true)]
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESourceSAKey,

	[Parameter(Mandatory=$true)]
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDestinationURI,

	[Parameter(Mandatory=$true)]
	[string]$WEDestinationSAKey

)


[CmdletBinding()]
function getBlobName
{
	param(
		[Parameter(Mandatory=$true)]
		[string]$url
	)

; 	$startIndex = 0

	for ($i=0;$i -lt 4;$i++)
	{
		[int]$startIndex = $url.IndexOf(" /" ,$startIndex)
	    $startIndex++  
	}

	return $url.Substring($startIndex)
}

[CmdletBinding()]
function getPathUpToContainerLevelfromUrl
{
	param(
		[Parameter(Mandatory=$true)]
		[string]$url
	)

; 	$startIndex = 0

	for ($i=0;$i -lt 4;$i++)
	{
		[int]$startIndex = $url.IndexOf(" /" ,$startIndex)
	    $startIndex++  
	}

	return $url.Substring(0,$startIndex-1)
}

[CmdletBinding()]
function getBlobCompletionStatus
{
	param(
		[Parameter(Mandatory=$true)]
		[string]$WEAzCopyLogFile
	)

; 	$resultObject = New-Object -TypeName PSObject -Property `
		@{ " TotalFilesTransfered" =0;
			" TransferSuccessfully" =0;
			" TransferSkipped" =0;
			" TransferFailed" =0;
			" UserCancelled" =$false;
			" Success" =$false;
			" SummaryFound" =$false;
			" ErrorMessage" =[string]::Empty;
			" ElapsedTime" =[string]::Empty }


	# Parsing log file for errors
	$azCopyOutput = Get-Content -ErrorAction Stop $WEAzCopyLogFile
			
	for ($i=$azCopyOutput.Count-1 ;$i -ge 0; $i--)
	{
		$line = $azCopyOutput[$i]
		if ($line.Contains(" Transfer failed" ))
		{
			$resultObject.TransferFailed = $line.Split(" :" )[1].Trim()
		}
		elseif ($line.Contains(" Transfer skipped" ))
		{
			$resultObject.TransferSkipped = $line.Split(" :" )[1].Trim()
		}
		elseif ($line.Contains(" Transfer successfully" ))
		{
			$resultObject.TransferSuccessfully = $line.Split(" :" )[1].Trim()
		}
		elseif ($line.Contains(" Total files transferred" ))
		{
			$resultObject.TotalFilesTransfered = $line.Split(" :" )[1].Trim()
		}
		elseif ($line.Contains(" Transfer summary" ))
		{
			$resultObject.SummaryFound = $true
		}
		elseif ($line.Contains(" User canceled this process" ) -or $line.Contains(" A task was canceled" ))
		{
			$resultObject.UserCancelled = $true
		}
		elseif ($line.Contains(" Elapsed time" ))
		{
			$resultObject.ElapsedTime = $line.Substring($line.IndexOf(" :" )).Trim()
		}
	}
		
	if (!$resultObject.SummaryFound)
	{
		$resultObject.Success  = $false
		$resultObject.ErrorMessage = " Blob copy $blobName failed. AzCopy Summary information could not be located"
		return $resultObject
	}

	if (!$resultObject.UserCancelled -and $resultObject.TransferFailed -eq 0 -and $resultObject.TotalFilesTransfered -eq 1)
	{
		$resultObject.Success  = $true
	}

	return $resultObject
}



try
{
	$sourceImageList = $WESourceImage.Split(" ," ,[StringSplitOptions]::RemoveEmptyEntries)

	$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($WEMyInvocation.MyCommand.Definition)
	$currentScriptFolder = [System.IO.Path]::GetDirectoryName($WEMyInvocation.MyCommand.Definition)
	" Current folder $currentScriptFolder" | Out-File " c:\$scriptName.txt"

	# Downloading and installing AzCopt
	$url = " http://aka.ms/downloadazcopy" 
	$localPath = Join-Path $currentScriptFolder " MicrosoftAzureStorageTools.msi" 

	" Downloading AzCopy from $url" | Out-File " c:\$scriptName.txt" -Append

	if(!(Split-Path -parent $localPath) -or !(Test-Path -pathType Container (Split-Path -parent $localPath)))
	{ 
		$localPath = Join-Path $pwd (Split-Path -leaf $localPath) 
	} 
      
	" Saving file at [$localPath]" | Out-File " c:\$scriptName.txt" -Append
	$client = new-object -ErrorAction Stop System.Net.WebClient 
	$client.DownloadFile($url, $localPath) 

	" Installing AzCopy" | Out-File " c:\$scriptName.txt" -Append

	$azCopyInstallLogFileName = " $currentScriptFolder\azCopyInstallLog.txt"

	Invoke-Command -ScriptBlock { & cmd /c " msiexec.exe /i $localPath /log $azCopyInstallLogFileName" /qn}

	$installLog = Get-Content -ErrorAction Stop $azCopyInstallLogFileName
	# Pattern matching for validation
# Pattern matching for validation
$installFolder = ($installLog | ? {$_ -match " AZURESTORAGETOOLSFOLDER" }).Split(" =" )[1].Trim()

	$azCopyTool = Join-Path $installFolder " AzCopy\Azcopy.exe"


	" Azcopy Path => $WEAzCopyTool" | Out-File " c:\$scriptName.txt" -Append
	" Source images URLs =>" | Out-File " c:\$scriptName.txt" -Append 
	foreach ($url in $sourceImageList)
	{
		"    $url" | Out-File " c:\$scriptName.txt" -Append 
	}

	" SourceSAKey => $WESourceSAKey" | Out-File " c:\$scriptName.txt" -Append
	" DestinationURI => $WEDestinationURI" | Out-File " c:\$scriptName.txt" -Append
	" DestinationSAKey => $WEDestinationSAKey" | Out-File " c:\$scriptName.txt" -Append

	# Copying blobs

	foreach ($url in $sourceImageList)
	{
		" Copying blob $url" | Out-File " c:\$scriptName.txt" -Append
	
		$WESourceURIContainer = getPathUpToContainerLevelfromUrl -url $url
		"   SourceURIContainer = $WESourceURIContainer" | Out-File " c:\$scriptName.txt" -Append

		$blobName = getBlobName -url $url
		"   BlobName = $blobName" | Out-File " c:\$scriptName.txt" -Append

	; 	$azCopyLogFile = " $WEPSScriptRoot\azcopylog-$blobName.txt"
		"   azCopyLogFile = $azCopyLogFile" | Out-File " c:\$scriptName.txt" -Append

		"   Running AzCopy Tool..." | Out-File " c:\$scriptName.txt" -Append

		& $WEAzCopyTool " /Source:$WESourceURIContainer" , " /S" , " /Dest:$WEDestinationURI" , " /DestKey:$WEDestinationSAKey" , " /Pattern:$blobName" , " /Y" , " /V:$azCopyLogFile" , " /NC:20"

		"   Checking blob copy status..." | Out-File " c:\$scriptName.txt" -Append
		# Checking blob copy status
	; 	$result = getBlobCompletionStatus -AzCopyLogFile $azCopyLogFile
		if ($result.Success)
		{
			" Blob $url successfuly transfered to $WEDestinationURI" | Out-File " c:\$scriptName.txt" -Append
			"   Elapsed time $($result.ElapsedTime)" | Out-File " c:\$scriptName.txt" -Append
		}
		else
		{
			throw " Blob $url copy failed to $WEDestinationURI, please analyze logs and retry operation."
		}
	}

	" Blob copy operation completed with success." | Out-File " c:\$scriptName.txt" -Append
}
catch
{
	" An error ocurred: $_" | Out-File " c:\$scriptName.txt" -Append
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================