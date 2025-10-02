#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Download Artifacts

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
    [string]$ProgressPreference = 'SilentlyContinue'
[OutputType([PSObject])]
 -ErrorAction Stop {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $resource
    )
    [string]$ResourceEscaped = [uri]::EscapeDataString($resource)
    [string]$RequestUri = " http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$ResourceEscaped"
    Write-Output "Retrieving access token from $RequestUri"
    [string]$response = Invoke-WebRequest -Uri $RequestUri -Headers @{Metadata = " true" } -UseBasicParsing
    if ($response.Content -imatch " access_token" ) {
    [string]$JsonContent = $response.Content | ConvertFrom-Json
    [string]$AccessToken = $JsonContent.access_token
    }
    else {
        throw "Failed to obtain access token from $RequestUri, aborting"
    }
    return $AccessToken
}
function Get-AzureDevOpsAccessToken -ErrorAction Stop {
    return (Get-ManagedIdentityAccessToken -ErrorAction Stop '499b84ac-1321-427f-aa17-267ca6975798')
}
    [string]$ToolsRoot = "C:\.tools\Setup"
mkdir $ToolsRoot -Force | Out-Null
    [string]$zip = " $ToolsRoot\artifacts.zip"
if ($ScriptsRepoUrl.StartsWith('https://github.com/')) {
    Write-Output " === Downloading artifacts from branch $ScriptsRepoBranch of repo $ScriptsRepoUrl"
    [string]$RequestUri = " $ScriptsRepoUrl/archive/refs/heads/$ScriptsRepoBranch.zip"
    Invoke-RestMethod -Uri $RequestUri -Method Get -OutFile $zip
    [string]$ExpandedArchiveRoot = " $ToolsRoot\tmp"
    Write-Output " -- Extracting to $ExpandedArchiveRoot"
    mkdir $ExpandedArchiveRoot -Force | Out-Null
    Expand-Archive -Path $zip -DestinationPath $ExpandedArchiveRoot
    [string]$ExpandedScriptsPath = [IO.Path]::GetFullPath($(Join-Path $((Get-ChildItem -ErrorAction Stop $ExpandedArchiveRoot)[0].FullName) $ScriptsRepoPath))
    Write-Output " -- Moving $ExpandedScriptsPath to $ToolsRoot"
    Move-Item -Path $ExpandedScriptsPath -Destination $ToolsRoot
    Write-Output " -- Deleting temp files"
    Remove-Item -Path $ExpandedArchiveRoot -Recurse -Force
}
elseif ($ScriptsRepoUrl.StartsWith('https://dev.azure.com/')) {
    Write-Output " === Downloading artifacts from $ScriptsRepoPath of branch $ScriptsRepoBranch in repo $ScriptsRepoUrl"
    [string]$RequestUri = " $ScriptsRepoUrl/items?path=$ScriptsRepoPath&`$format=zip&versionDescriptor.version=$ScriptsRepoBranch&versionDescriptor.versionType=branch&api-version=5.0-preview.1"
    [string]$AadToken = Get-AzureDevOpsAccessToken -ErrorAction Stop
    Invoke-RestMethod -Uri $RequestUri -Method Get -Headers @{"Authorization" = "Bearer $AadToken" } -OutFile $zip
    Write-Output " -- Extracting to $ToolsRoot"
    Expand-Archive -Path $zip -DestinationPath $ToolsRoot
    Remove-Item -Path $zip -Force
}
else {
    throw "Don't know how to download files from repo $ScriptsRepoUrl"
}
Write-Output " -- Content of $ToolsRoot"
Get-ChildItem -ErrorAction Stop $ToolsRoot -Recurse
Write-Output " === Completed downloading artifacts"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
