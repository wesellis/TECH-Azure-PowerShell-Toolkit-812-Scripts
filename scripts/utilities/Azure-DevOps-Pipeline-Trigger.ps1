#Requires -Version 7.4

<#
.SYNOPSIS
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

.EXAMPLE
    .\Azure-DevOps-Pipeline-Trigger.ps1 -Organization "contoso" -Project "MyProject" -PipelineId 123 -PersonalAccessToken "abc123"

.EXAMPLE
    .\Azure-DevOps-Pipeline-Trigger.ps1 -Organization "contoso" -Project "MyProject" -PipelineId 123 -PersonalAccessToken "abc123" -SourceBranch "develop"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Prerequisites:
    - Valid Azure DevOps Personal Access Token with build permissions
    - Network access to dev.azure.com

.LINK
    https://docs.microsoft.com/en-us/rest/api/azure/devops/pipelines/runs/run-pipeline
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure DevOps organization name")]
    [ValidateNotNullOrEmpty()]
    [string]$Organization,

    [Parameter(Mandatory = $true, HelpMessage = "Azure DevOps project name")]
    [ValidateNotNullOrEmpty()]
    [string]$Project,

    [Parameter(Mandatory = $true, HelpMessage = "Pipeline ID to trigger")]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$PipelineId,

    [Parameter(Mandatory = $true, HelpMessage = "Personal Access Token for authentication")]
    [ValidateNotNullOrEmpty()]
    [string]$PersonalAccessToken,

    [Parameter(HelpMessage = "Source branch to build from")]
    [ValidateNotNullOrEmpty()]
    [string]$SourceBranch = "main"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# Script variables
$script:ApiVersion = '6.0'
$script:BaseUri = "https://dev.azure.com"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $colorMap = @{
        'INFO'    = 'Cyan'
        'WARNING' = 'Yellow'
        'ERROR'   = 'Red'
        'SUCCESS' = 'Green'
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

function Test-PipelineAccess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$Project,

        [Parameter(Mandatory = $true)]
        [int]$PipelineId,

        [Parameter(Mandatory = $true)]
        [hashtable]$Headers
    )

    try {
        $TestUri = "$script:BaseUri/$Organization/$Project/_apis/pipelines/$PipelineId`?api-version=$script:ApiVersion"
        Write-Verbose "Testing pipeline access: $TestUri"

        $pipeline = Invoke-RestMethod -Uri $TestUri -Headers $Headers -Method Get

        Write-Log "Pipeline validation successful: $($pipeline.name)" -Level SUCCESS
        Write-Verbose "Pipeline folder: $($pipeline.folder)"
        return $true
    }
    catch {
        Write-Log "Pipeline validation failed: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Start-PipelineRun {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$Project,

        [Parameter(Mandatory = $true)]
        [int]$PipelineId,

        [Parameter(Mandatory = $true)]
        [string]$Branch,

        [Parameter(Mandatory = $true)]
        [hashtable]$Headers
    )

    try {
        $RunUri = "$script:BaseUri/$Organization/$Project/_apis/pipelines/$PipelineId/runs?api-version=$script:ApiVersion"
        Write-Verbose "Pipeline run URI: $RunUri"

        # Build request body
        $RequestBody = @{
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
        Write-Verbose "Request body: $RequestBody"

        $response = Invoke-RestMethod -Uri $RunUri -Method Post -Headers $Headers -Body $RequestBody -ContentType "application/json"

        return $response
    }
    catch {
        Write-Log "Pipeline trigger failed: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

try {
    Write-Host "Azure DevOps Pipeline Trigger" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor DarkGray
    Write-Host "Organization: $Organization"
    Write-Host "Project: $Project"
    Write-Host "Pipeline ID: $PipelineId"
    Write-Host "Source Branch: $SourceBranch"
    Write-Host ""

    # Setup authentication
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

    # Trigger pipeline
    Write-Log "Initiating pipeline run" -Level INFO
    $response = Start-PipelineRun -Organization $Organization -Project $Project -PipelineId $PipelineId -Branch $SourceBranch -Headers $headers

    # Display results
    Write-Host ""
    Write-Host "Pipeline Trigger Results" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor DarkGray
    Write-Host "Run ID: $($response.id)"
    Write-Host "State: $($response.state)"
    Write-Host "Created: $($response.createdDate)"

    if ($response._links.web.href) {
        Write-Host "URL: $($response._links.web.href)"
    }

    if ($response.pipeline) {
        Write-Host "Pipeline Name: $($response.pipeline.name)"
        Write-Host "Pipeline Version: $($response.pipeline.version)"
    }

    Write-Log "Pipeline triggered successfully with Run ID: $($response.id)" -Level SUCCESS

    # Return the response for potential pipeline chaining
    return $response
}
catch {
    Write-Log "Pipeline trigger operation failed: $($_.Exception.Message)" -Level ERROR
    Write-Host ""
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "- Verify Personal Access Token has 'Build (read and execute)' permissions"
    Write-Host "- Check organization and project names are correct"
    Write-Host "- Ensure pipeline ID exists and is accessible"
    Write-Host "- Validate source branch exists in the repository"
    Write-Host "- Check network connectivity to dev.azure.com"
    Write-Host ""

    # Provide more detailed error information
    if ($_.Exception.Response) {
        try {
            $errorDetails = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorDetails)
            $errorText = $reader.ReadToEnd()
            Write-Host "API Error Details:" -ForegroundColor Red
            Write-Host $errorText
        }
        catch {
            Write-Verbose "Could not parse error details"
        }
    }

    throw
}
finally {
    Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
}