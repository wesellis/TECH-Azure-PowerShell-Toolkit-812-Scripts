#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Download Artifacts

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Download Artifacts

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$WEProgressPreference = 'SilentlyContinue'

[CmdletBinding()]
function WE-Get-ManagedIdentityAccessToken -ErrorAction Stop {
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = " Stop"
[CmdletBinding()]
param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $resource
    )

    $resourceEscaped = [uri]::EscapeDataString($resource)
    $requestUri = " http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$resourceEscaped"
    Write-WELog " Retrieving access token from $requestUri" " INFO"
    $response = Invoke-WebRequest -Uri $requestUri -Headers @{Metadata = " true" } -UseBasicParsing

    if ($response.Content -imatch " access_token" ) {
        $jsonContent = $response.Content | ConvertFrom-Json
        $accessToken = $jsonContent.access_token
    }
    else {
        throw " Failed to obtain access token from $requestUri, aborting"
    }

    return $accessToken
}

[CmdletBinding()]
function WE-Get-AzureDevOpsAccessToken -ErrorAction Stop {
    return (Get-ManagedIdentityAccessToken -ErrorAction Stop '499b84ac-1321-427f-aa17-267ca6975798')
}

$toolsRoot = " C:\.tools\Setup"
mkdir $toolsRoot -Force | Out-Null
$zip = " $toolsRoot\artifacts.zip"

if ($scriptsRepoUrl.StartsWith('https://github.com/')) {
    Write-WELog " === Downloading artifacts from branch $scriptsRepoBranch of repo $scriptsRepoUrl" " INFO"
    $requestUri = " $scriptsRepoUrl/archive/refs/heads/$scriptsRepoBranch.zip"
    Invoke-RestMethod -Uri $requestUri -Method Get -OutFile $zip

    $expandedArchiveRoot = " $toolsRoot\tmp"
    Write-WELog " -- Extracting to $expandedArchiveRoot" " INFO"
    mkdir $expandedArchiveRoot -Force | Out-Null
    Expand-Archive -Path $zip -DestinationPath $expandedArchiveRoot

    $expandedScriptsPath = [IO.Path]::GetFullPath($(Join-Path $((Get-ChildItem -ErrorAction Stop $expandedArchiveRoot)[0].FullName) $scriptsRepoPath))
    Write-WELog " -- Moving $expandedScriptsPath to $toolsRoot" " INFO"
    Move-Item -Path $expandedScriptsPath -Destination $toolsRoot

    Write-WELog " -- Deleting temp files" " INFO"
    Remove-Item -Path $expandedArchiveRoot -Recurse -Force

}
elseif ($scriptsRepoUrl.StartsWith('https://dev.azure.com/')) {
    Write-WELog " === Downloading artifacts from $scriptsRepoPath of branch $scriptsRepoBranch in repo $scriptsRepoUrl" " INFO"
   ;  $requestUri = " $scriptsRepoUrl/items?path=$scriptsRepoPath&`$format=zip&versionDescriptor.version=$scriptsRepoBranch&versionDescriptor.versionType=branch&api-version=5.0-preview.1"
   ;  $aadToken = Get-AzureDevOpsAccessToken -ErrorAction Stop
    Invoke-RestMethod -Uri $requestUri -Method Get -Headers @{" Authorization" = " Bearer $aadToken" } -OutFile $zip

    Write-WELog " -- Extracting to $toolsRoot" " INFO"
    Expand-Archive -Path $zip -DestinationPath $toolsRoot
    Remove-Item -Path $zip -Force
}
else {
    throw " Don't know how to download files from repo $scriptsRepoUrl"
}

Write-WELog " -- Content of $toolsRoot" " INFO"
Get-ChildItem -ErrorAction Stop $toolsRoot -Recurse

Write-WELog " === Completed downloading artifacts" " INFO"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
