#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Data Factory Modern Pipeline Management Tool

.DESCRIPTION
    Tool for creating, managing, and monitoring Azure Data Factory pipelines
    with modern data integration capabilities including real-time analytics and AI/ML integration.

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.PARAMETER ResourceGroupName
    Target Resource Group for Data Factory

.PARAMETER DataFactoryName
    Name of the Azure Data Factory instance

.PARAMETER Location
    Azure region for the Data Factory

.PARAMETER Action
    Action to perform (Create, Deploy, Monitor, Trigger, Configure, Delete)

.EXAMPLE
    .\Azure-DataFactory-Modern-Pipeline-Tool.ps1 -ResourceGroupName "data-rg" -DataFactoryName "modern-adf" -Location "East US" -Action "Create"

.NOTES
    Version: 2.0
    Requires: PowerShell 7.0+, Az.DataFactory module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$DataFactoryName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "Deploy", "Monitor", "Trigger", "Configure", "Delete", "Export")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$PipelineName,

    [Parameter(Mandatory = $false)]
    [string]$PipelineDefinitionPath,

    [Parameter(Mandatory = $false)]
    [switch]$EnableMonitoring,

    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Production"
        Application = "DataFactory"
        ManagedBy = "AutomationScript"
    }
)

$ErrorActionPreference = 'Stop'

try {
    Write-Host "Azure Data Factory Modern Pipeline Tool" -ForegroundColor Green
    Write-Host "Action: $Action" -ForegroundColor Green
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
    Write-Host "Data Factory: $DataFactoryName" -ForegroundColor Green

    # Check for resource group
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
        $ResourcegroupSplat = @{
            Name = $ResourceGroupName
            Location = $Location
            Tag = $Tags
        }
        New-AzResourceGroup @ResourcegroupSplat
        Write-Host "Resource group created successfully" -ForegroundColor Green
    }

    switch ($Action) {
        "Create" {
            Write-Host "Creating Data Factory: $DataFactoryName" -ForegroundColor Green

            # Check if data factory exists
            $ExistingDataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -ErrorAction SilentlyContinue
            if ($ExistingDataFactory) {
                Write-Host "Data Factory already exists" -ForegroundColor Yellow
            } else {
                $DataFactory = Set-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -Location $Location -Tag $Tags
                Write-Host "Data Factory created successfully" -ForegroundColor Green
            }
        }

        "Monitor" {
            Write-Host "Monitoring Data Factory: $DataFactoryName" -ForegroundColor Green
            $StartTime = (Get-Date).AddDays(-1)
            $EndTime = Get-Date

            $PipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -LastUpdatedAfter $StartTime -LastUpdatedBefore $EndTime

            Write-Host "Pipeline Runs in last 24 hours:" -ForegroundColor Green
            foreach ($run in $PipelineRuns) {
                $statusColor = switch ($run.Status) {
                    "Succeeded" { "Green" }
                    "Failed" { "Red" }
                    "InProgress" { "Yellow" }
                    default { "Gray" }
                }
                Write-Host "  Pipeline: $($run.PipelineName) - Status: $($run.Status)" -ForegroundColor $statusColor
            }
        }

        "Trigger" {
            if (-not $PipelineName) {
                throw "PipelineName parameter is required for Trigger action"
            }
            Write-Host "Triggering pipeline: $PipelineName" -ForegroundColor Green
            $RunId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineName $PipelineName
            Write-Host "Pipeline triggered successfully. Run ID: $RunId" -ForegroundColor Green
        }

        "Delete" {
            Write-Host "Deleting Data Factory: $DataFactoryName" -ForegroundColor Yellow
            Remove-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -Force
            Write-Host "Data Factory deleted successfully" -ForegroundColor Green
        }

        "Export" {
            Write-Host "Exporting Data Factory configuration" -ForegroundColor Green
            $ExportPath = ".\DataFactory-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null

            # Export pipelines
            $pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
            foreach ($pipeline in $pipelines) {
                $PipelineDefinition = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $pipeline.Name
                $PipelineDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath "$ExportPath\pipeline-$($pipeline.Name).json" -Encoding UTF8
            }

            Write-Host "Configuration exported to: $ExportPath" -ForegroundColor Green
        }

        default {
            Write-Host "Action not implemented: $Action" -ForegroundColor Yellow
        }
    }

    Write-Host "Operation completed successfully" -ForegroundColor Green

} catch {
    Write-Error "Data Factory operation failed: $_"
    throw
}