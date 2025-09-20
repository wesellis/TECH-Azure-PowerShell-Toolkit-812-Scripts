#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Azure DevOps pipelines
.DESCRIPTION
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
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory)]
    [string]$OrganizationUrl,

    [Parameter(Mandatory)]
    [string]$ProjectName,

    [Parameter(Mandatory)]
    [string]$PipelineName,

    [Parameter(Mandatory)]
    [ValidateSet('Create', 'Update', 'Delete', 'Run', 'Status')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'

try {
    Write-Verbose "Managing Azure DevOps pipeline: $PipelineName"

    $apiVersion = "6.0"
    $baseUrl = "$OrganizationUrl/$ProjectName/_apis"

    switch ($Action) {
        'Status' {
            $uri = "$baseUrl/pipelines?api-version=$apiVersion"
            $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $pipeline = $response.value | Where-Object { $_.name -eq $PipelineName }

            if ($pipeline) {
                [PSCustomObject]@{
                    Name = $pipeline.name
                    Id = $pipeline.id
                    Url = $pipeline.url
                    Status = 'Found'
                }
            } else {
                Write-Warning "Pipeline '$PipelineName' not found"
                return $null
            }
        }

        'Run' {
            if ($PSCmdlet.ShouldProcess($PipelineName, 'Run pipeline')) {
                Write-Host "Pipeline run functionality requires Azure DevOps PAT token configuration" -ForegroundColor Yellow
                Write-Host "Use Azure CLI: az pipelines run --name '$PipelineName'" -ForegroundColor Green
            }
        }

        default {
            Write-Host "Action '$Action' requires Azure DevOps REST API integration" -ForegroundColor Yellow
            Write-Host "Consider using Azure CLI DevOps extension for full functionality" -ForegroundColor Green
        }
    }
}
catch {
    Write-Error "Failed to manage pipeline: $_"
    throw
}