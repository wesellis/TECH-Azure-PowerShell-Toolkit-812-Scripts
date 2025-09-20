#Requires -Version 7.0

<#`n.SYNOPSIS
    Triggers Azure DevOps build and release pipelines programmatically

.DESCRIPTION
    This script connects to Azure DevOps REST API to trigger pipeline runs.
    Supports triggering builds on specific branches with authentication via PAT.
.PARAMETER Organization
    Azure DevOps organization name
.PARAMETER Project
    Azure DevOps project name
.PARAMETER PipelineId
    Numeric ID of the pipeline to trigger
.PARAMETER PersonalAccessToken
    Personal Access Token for Azure DevOps authentication
.PARAMETER SourceBranch
    Branch name to trigger the pipeline against. Defaults to 'main'
    .\Azure-DevOps-Pipeline-Trigger.ps1 -Organization "contoso" -Project "MyProject" -PipelineId "123" -PersonalAccessToken "abc123"
    .\Azure-DevOps-Pipeline-Trigger.ps1 -Organization "contoso" -Project "MyProject" -PipelineId "123" -PersonalAccessToken "abc123" -SourceBranch "develop"
    Author: Wes Ellis (wes@wesellis.com)Prerequisites:
    - Valid Azure DevOps Personal Access Token with build permissions
    - Network access to dev.azure.com
.LINK
    https://docs.microsoft.com/en-us/rest/api/azure/devops/pipelines/runs/run-pipeline
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, HelpMessage="Azure DevOps organization name")]
    [ValidateNotNullOrEmpty()]
    [string]$Organization,
    [Parameter(Mandatory, HelpMessage="Azure DevOps project name")]
    [ValidateNotNullOrEmpty()]
    [string]$Project,
    [Parameter(Mandatory, HelpMessage="Pipeline ID to trigger")]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$PipelineId,
    [Parameter(Mandatory, HelpMessage="Personal Access Token for authentication")]
    [ValidateNotNullOrEmpty()]
    [string]$PersonalAccessToken,
    [Parameter(HelpMessage="Source branch to build from")]
    [ValidateNotNullOrEmpty()]
    [string]$SourceBranch = "main"
)
#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Script variables
$script:ApiVersion = '6.0'
$script:BaseUri = "https://dev.azure.com"
#endregion
[OutputType([bool])]
 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}
function Test-PipelineAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Organization,
        [Parameter(Mandatory)]
        [string]$Project,
        [Parameter(Mandatory)]
        [int]$PipelineId,
        [Parameter(Mandatory)]
        [hashtable]$Headers
    )
    try {
        $testUri = "$script:BaseUri/$Organization/$Project/_apis/pipelines/$PipelineId?api-version=$script:ApiVersion"
        $pipeline = Invoke-RestMethod -Uri $testUri -Headers $Headers -Method Get
        Write-Log "Pipeline validation successful: $($pipeline.name)" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Pipeline validation failed: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}
function Start-PipelineRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Organization,
        [Parameter(Mandatory)]
        [string]$Project,
        [Parameter(Mandatory)]
        [int]$PipelineId,
        [Parameter(Mandatory)]
        [string]$Branch,
        [Parameter(Mandatory)]
        [hashtable]$Headers
    )
    try {
        $runUri = "$script:BaseUri/$Organization/$Project/_apis/pipelines/$PipelineId/runs?api-version=$script:ApiVersion"
        $requestBody = @{
            stagesToSkip = @()
            resources = @{
                repositories = @{
                    self = @{
                        refName = "refs/heads/$Branch"
                    }
                }
            }
        } | ConvertTo-Json -Depth 3
        Write-Log "Triggering pipeline run on branch: $Branch" -Level INFO
        $response = Invoke-RestMethod -Uri $runUri -Method Post -Headers $Headers -Body $requestBody -ContentType "application/json"
        return $response
    }
    catch {
        Write-Log "Pipeline trigger failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}
#endregion
#region Main-Execution
try {
    Write-Host "Azure DevOps Pipeline Trigger" -ForegroundColor White
    Write-Host "==============================" -ForegroundColor White
    Write-Host "Organization: $Organization" -ForegroundColor Gray
    Write-Host "Project: $Project" -ForegroundColor Gray
    Write-Host "Pipeline ID: $PipelineId" -ForegroundColor Gray
    Write-Host "Source Branch: $SourceBranch" -ForegroundColor Gray
    Write-Host ""
    # Create authentication headers
    Write-Log "Setting up authentication" -Level INFO
    $base64Token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PersonalAccessToken"))
    $headers = @{
        Authorization = "Basic $base64Token"
        'Content-Type' = 'application/json'
    }
    # Validate pipeline access
    Write-Log "Validating pipeline access" -Level INFO
    if (-not (Test-PipelineAccess -Organization $Organization -Project $Project -PipelineId $PipelineId -Headers $headers)) {
        throw "Pipeline validation failed. Check permissions and pipeline ID."
    }
    # Trigger the pipeline
    Write-Log "Initiating pipeline run" -Level INFO
    $response = Start-PipelineRun -Organization $Organization -Project $Project -PipelineId $PipelineId -Branch $SourceBranch -Headers $headers
    # Display results
    Write-Host ""
    Write-Host "Pipeline Trigger Results" -ForegroundColor Green
    Write-Host "========================" -ForegroundColor Green
    Write-Host "Run ID: $($response.id)" -ForegroundColor White
    Write-Host "State: $($response.state)" -ForegroundColor White
    Write-Host "Created: $($response.createdDate)" -ForegroundColor White
    if ($response._links.web.href) {
        Write-Host "URL: $($response._links.web.href)" -ForegroundColor Cyan
    }
    Write-Log "Pipeline triggered successfully with Run ID: $($response.id)" -Level SUCCESS
    # Return the response for pipeline usage
    return $response
} catch {
    Write-Log "Pipeline trigger operation failed: $($_.Exception.Message)" -Level ERROR
    Write-Host ""
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "- Verify Personal Access Token has 'Build (read and execute)' permissions" -ForegroundColor Gray
    Write-Host "- Check organization and project names are correct" -ForegroundColor Gray
    Write-Host "- Ensure pipeline ID exists and is accessible" -ForegroundColor Gray
    Write-Host "- Validate source branch exists in the repository" -ForegroundColor Gray
    Write-Host ""
    throw
} finally {
    Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
}

