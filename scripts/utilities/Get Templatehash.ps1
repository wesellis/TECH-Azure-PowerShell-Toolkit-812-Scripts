#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Get Template Hash

.DESCRIPTION
    Azure automation script to calculate template hash using Azure Resource Manager API

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER TemplateFilePath
    Path to the template file

.PARAMETER BearerToken
    Bearer token for authentication (optional)

.PARAMETER RemoveGeneratorMetadata
    Switch to remove generator metadata

.EXAMPLE
    .\Get_Templatehash.ps1 -TemplateFilePath "C:\templates\template.json"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TemplateFilePath,

    [Parameter(Mandatory = $false)]
    [string]$BearerToken,

    [Parameter(Mandatory = $false)]
    [switch]$RemoveGeneratorMetadata
)

$ErrorActionPreference = "Stop"

try {
    if ($BearerToken -eq "") {
        Write-Output "Getting token..."
        Import-Module Az.Accounts
        $AzProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
        $AzContext = Get-AzContext -ErrorAction Stop
        $ProfileClient = New-Object -ErrorAction Stop Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($AzProfile)
        $BearerToken = ($ProfileClient.AcquireAccessToken($AzContext.Tenant.TenantId)).AccessToken
        if (!$BearerToken) {
            Write-Error "Could not retrieve token"
        }
    }

    $uri = "https://management.azure.com/providers/Microsoft.Resources/calculateTemplateHash?api-version=2019-10-01"
    $Headers = @{
        'Authorization' = "Bearer $BearerToken"
        'Content-Type'  = 'application/json'
    }

    $raw = Get-Content -Path $TemplateFilePath -Raw -ErrorAction Stop
    if ($RemoveGeneratorMetadata) {
        $WithoutGeneratorMetadata = Remove-GeneratorMetadata -ErrorAction Stop $raw
    }
    else {
        $WithoutGeneratorMetadata = $raw
    }

    if ($null -eq $WithoutGeneratorMetadata -or $WithoutGeneratorMetadata -eq "") {
        Write-Error "JSON is empty"
    }

    Write-Output "Requesting Hash for file: $TemplateFilePath"

    $params = @{
        Method = "POST"
        Uri = $uri
        Headers = $Headers
        Body = $WithoutGeneratorMetadata
    }

    $response = Invoke-RestMethod @params
    $TemplateHash = $response.templateHash

    Write-Output "Template hash: $TemplateHash"
    if (!$TemplateHash -or !($TemplateHash -gt 0)) {
        Write-Error "Failed to get hash for: $TemplateFilePath"
    }

    Return $TemplateHash
} catch {
    Write-Warning $Error[0].Exception.Message
    Write-Warning ($response ? $response : "(no response)")
    Write-Error "Failed to get hash for: $TemplateFilePath"
}
