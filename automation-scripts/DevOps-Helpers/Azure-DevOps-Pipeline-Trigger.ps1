# Azure DevOps Pipeline Trigger
# Trigger Azure DevOps build and release pipelines
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$true)]
    [string]$Organization,
    
    [Parameter(Mandatory=$true)]
    [string]$Project,
    
    [Parameter(Mandatory=$true)]
    [string]$PipelineId,
    
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory=$false)]
    [string]$SourceBranch = "main"
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure DevOps Pipeline Trigger" -Version "1.0" -Description "Trigger DevOps pipelines remotely"

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

    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType "application/json"
    
    Write-Host "✅ Pipeline triggered successfully!" -ForegroundColor Green
    Write-Host "Run ID: $($response.id)" -ForegroundColor Cyan
    Write-Host "URL: $($response._links.web.href)" -ForegroundColor Yellow

} catch {
    Write-Log "❌ Pipeline trigger failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
