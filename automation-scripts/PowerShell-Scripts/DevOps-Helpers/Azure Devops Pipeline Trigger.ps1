<#
.SYNOPSIS
    Azure Devops Pipeline Trigger

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Organization,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Project,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PipelineId,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PersonalAccessToken,
    [Parameter()]
    [string]$SourceBranch = "main"
)
Write-Host "Azure Script Started" -ForegroundColor Green
try {
    $base64Token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PersonalAccessToken"))
    $headers = @{ Authorization = "Basic $base64Token" }
    $uri = "https://dev.azure.com/$Organization/$Project/_apis/pipelines/$PipelineId/runs?api-version=6.0"
$body = @{
        stagesToSkip = @()
        resources = @{
            repositories = @{
                self = @{
                    refName = "refs/heads/$SourceBranch"
                }
            }
        }
    } | ConvertTo-Json -Depth 3
$response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType " application/json"
    Write-Host "Pipeline triggered successfully!" -ForegroundColor Green
    Write-Host "Run ID: $($response.id)" -ForegroundColor Cyan
    Write-Host "URL: $($response._links.web.href)" -ForegroundColor Yellow
} catch {

    throw
}

