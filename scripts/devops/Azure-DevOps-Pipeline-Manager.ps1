#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Azure DevOps pipelines
.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Create, update, and manage Azure DevOps build and release pipelines
.PARAMETER OrganizationUrl
    Azure DevOps organization URL
.PARAMETER ProjectName
    Project name
.PARAMETER PipelineName
    Pipeline name
.PARAMETER Action
    Action to perform (Create, Update, Delete, Run)
.EXAMPLE
    ./Azure-DevOps-Pipeline-Manager.ps1 -OrganizationUrl "https://dev.azure.com/contoso" -ProjectName "MyProject" -PipelineName "Build-Pipeline" -Action "Run"
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^https?://.+')]
    [ValidateNotNullOrEmpty()]
    [string]$OrganizationUrl,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PipelineName,

    [Parameter(Mandatory)]
    [ValidateSet('Create', 'Update', 'Delete', 'Run', 'Status')]
    [string]$Action
)
    [string]$ErrorActionPreference = 'Stop'

try {
    Write-Verbose "Managing Azure DevOps pipeline: $PipelineName"
    [string]$ApiVersion = "6.0"
    [string]$BaseUrl = "$OrganizationUrl/$ProjectName/_apis"

    switch ($Action) {
        'Status' {
    [string]$uri = "$BaseUrl/pipelines?api-version=$ApiVersion"
    [string]$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    [string]$pipeline = $response.value | Where-Object { $_.name -eq $PipelineName }

            if ($pipeline) {
                [PSCustomObject]@{
                    Name = $pipeline.name
                    Id = $pipeline.id
                    Url = $pipeline.url
                    Status = 'Found'
                }
            } else {
                Write-Warning "Pipeline '$PipelineName' not found"
                exit 0
            }
        }

        'Run' {
            if ($PSCmdlet.ShouldProcess($PipelineName, 'Run pipeline')) {
                Write-Information "Pipeline run functionality requires Azure DevOps PAT token configuration" -InformationAction Continue
                Write-Information "Use Azure CLI: az pipelines run --name '$PipelineName'" -InformationAction Continue
            }
        }

        default {
            Write-Information "Action '$Action' requires Azure DevOps REST API integration" -InformationAction Continue
            Write-Information "Consider using Azure CLI DevOps extension for full functionality" -InformationAction Continue
        }
    }
}
catch {
    Write-Error "Failed to manage pipeline: $_"
    throw
        exit 1
    exit 1`n}
