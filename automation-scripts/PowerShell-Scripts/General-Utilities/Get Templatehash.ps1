#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Get Templatehash

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
    We Enhanced Get Templatehash

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string][Parameter(Mandatory = $true)] $templateFilePath,
    [string][Parameter(Mandatory = $false)] $bearerToken,
    # If this is set, the hash obtained will *not* be the official template hash that Azure would compute.
    [switch][Parameter(Mandatory = $false)] $removeGeneratorMetadata
)

#region Functions

Import-Module " $WEPSScriptRoot/Local.psm1" -Force


if ($bearerToken -eq "" ) {
    Write-WELog " Getting token..." " INFO"
    Import-Module Az.Accounts
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $azContext = Get-AzContext -ErrorAction Stop
    $profileClient = New-Object -ErrorAction Stop Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
    $bearerToken = ($profileClient.AcquireAccessToken($azContext.Tenant.TenantId)).AccessToken
    if (!$bearerToken) {
        Write-Error " Could not retrieve token"
    }
}
$uri = " https://management.azure.com/providers/Microsoft.Resources/calculateTemplateHash?api-version=2019-10-01"
$WEHeaders = @{
    'Authorization' = " Bearer $bearerToken"
    'Content-Type'  = 'application/json'
}


$raw = Get-Content -Path $templateFilePath -Raw -ErrorAction Stop
if ($WERemoveGeneratorMetadata) {
    $withoutGeneratorMetadata = Remove-GeneratorMetadata -ErrorAction Stop $raw
}
else {
    $withoutGeneratorMetadata = $raw
}

if ($null -eq $withoutGeneratorMetadata -or $withoutGeneratorMetadata -eq "" ) {
    Write-Error " JSON is empty"
}


Write-WELog " Requesting Hash for file: $templateFilePath" " INFO"
try {
    #fail the build for now so we can find issues
   $params = @{
       Method = " POST"
       Uri = $uri
       Headers = $WEHeaders
       Body = $withoutGeneratorMetadata ;  $templateHash = $response.templateHash
   }
   ; @params
}
catch {
    Write-Warning $WEError[0]
    Write-Warning ($response ? $response : " (no response)" )
    Write-Error " Failed to get hash for: $templateFilePath"
}

Write-WELog " Template hash: $templateHash" " INFO"
if (!$templateHash -or !($templateHash -gt 0)) {
    Write-Error " Failed to get hash for: $templateFilePath"
}

Return $templateHash


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
