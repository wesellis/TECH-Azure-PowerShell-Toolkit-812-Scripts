#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.Resources, Az.DataFactory

<#
.SYNOPSIS
    Azure Data Factory Modern Pipeline Management Tool
.DESCRIPTION
    Advanced tool for creating, managing, and monitoring Azure Data Factory pipelines
    with modern data integration capabilities including real-time analytics and AI/ML integration.
.PARAMETER ResourceGroupName
    Target Resource Group for Data Factory
.PARAMETER DataFactoryName
    Name of the Azure Data Factory instance
.PARAMETER Location
    Azure region for the Data Factory
.PARAMETER Action
    Action to perform (Create, Deploy, Monitor, Trigger, Configure, Delete)
.PARAMETER PipelineName
    Name of the pipeline to manage
.PARAMETER PipelineDefinitionPath
    Path to pipeline JSON definition file
.PARAMETER TriggerName
    Name of the trigger
.PARAMETER TriggerType
    Type of trigger (Schedule, Tumbling, Event, Manual)
.PARAMETER DatasetName
    Name of the dataset
.PARAMETER LinkedServiceName
    Name of the linked service
.PARAMETER EnableMonitoring
    Enable comprehensive monitoring and alerting
.PARAMETER EnablePrivateEndpoints
    Create private endpoints for secure access
.PARAMETER GitConfiguration
    Git repository configuration for CI/CD
.PARAMETER Tags
    Tags to apply to resources
.EXAMPLE
    .\Azure-DataFactory-Modern-Pipeline-Tool.ps1 -ResourceGroupName "data-rg" -DataFactoryName "modern-adf" -Location "East US" -Action "Create" -EnableMonitoring
.EXAMPLE
    .\Azure-DataFactory-Modern-Pipeline-Tool.ps1 -ResourceGroupName "data-rg" -DataFactoryName "modern-adf" -Action "Deploy" -PipelineName "etl-pipeline" -PipelineDefinitionPath "C:\pipelines\etl.json"
.NOTES
    Author: Wesley Ellis
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
    [string]$TriggerName,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Schedule", "Tumbling", "Event", "Manual")]
    [string]$TriggerType = "Schedule",
    
    [Parameter(Mandatory = $false)]
    [string]$DatasetName,
    
    [Parameter(Mandatory = $false)]
    [string]$LinkedServiceName,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnablePrivateEndpoints,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$GitConfiguration = @{},
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Production"
        Application = "DataFactory"
        ManagedBy = "AutomationScript"
    }
)

# Import required modules
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.DataFactory -Force -ErrorAction Stop
    Import-Module Az.Storage -Force -ErrorAction Stop
    Write-Host "✅ Successfully imported required Azure modules" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to import required modules: $($_.Exception.Message)"
    exit 1
}

# Enhanced logging function
function Write-EnhancedLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow" 
        Error = "Red"
        Success = "Green"
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}

# Create Azure Data Factory instance
function New-DataFactoryInstance {
    try {
        Write-EnhancedLog "Creating Azure Data Factory instance: $DataFactoryName" "Info"
        
        # Check if Data Factory already exists
        $existingDataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -ErrorAction SilentlyContinue
        if ($existingDataFactory) {
            Write-EnhancedLog "Data Factory already exists: $DataFactoryName" "Warning"
            return $existingDataFactory
        }
        
        # Create Data Factory
        $dataFactory = Set-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -Location $Location -Tag $Tags
        Write-EnhancedLog "Successfully created Data Factory: $DataFactoryName" "Success"
        
        # Configure Git integration if provided
        if ($GitConfiguration.Keys.Count -gt 0) {
            Set-DataFactoryGitConfiguration
        }
        
        return $dataFactory
        
    } catch {
        Write-EnhancedLog "Failed to create Data Factory: $($_.Exception.Message)" "Error"
        throw
    }
}

# Configure Git integration
function Set-DataFactoryGitConfiguration {
    try {
        Write-EnhancedLog "Configuring Git integration for Data Factory..." "Info"
        
        if ($GitConfiguration.ContainsKey("RepoUrl") -and $GitConfiguration.ContainsKey("BranchName")) {
            $gitConfig = @{
                ResourceGroupName = $ResourceGroupName
                DataFactoryName = $DataFactoryName
                RepositoryUrl = $GitConfiguration.RepoUrl
                BranchName = $GitConfiguration.BranchName
                RootFolder = $GitConfiguration.RootFolder ?? "/"
                CollaborationBranch = $GitConfiguration.CollaborationBranch ?? "main"
            }
            
            Set-AzDataFactoryV2GitIntegration @gitConfig
            Write-EnhancedLog "Successfully configured Git integration" "Success"
        }
        
    } catch {
        Write-EnhancedLog "Failed to configure Git integration: $($_.Exception.Message)" "Error"
    }
}

# Create modern data pipeline templates
function New-ModernDataPipelines {
    try {
        Write-EnhancedLog "Creating modern data pipeline templates..." "Info"
        
        # Create sample linked services
        New-SampleLinkedServices
        
        # Create sample datasets
        New-SampleDatasets
        
        # Create sample pipelines
        New-SamplePipelines
        
        Write-EnhancedLog "Successfully created modern data pipeline templates" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to create pipeline templates: $($_.Exception.Message)" "Error"
    }
}

# Create sample linked services
function New-SampleLinkedServices {
    try {
        # Azure SQL Database Linked Service
        $sqlLinkedService = @{
            type = "AzureSqlDatabase"
            typeProperties = @{
                connectionString = @{
                    type = "AzureKeyVaultSecret"
                    store = @{
                        referenceName = "KeyVaultLinkedService"
                        type = "LinkedServiceReference"
                    }
                    secretName = "SqlConnectionString"
                }
            }
        }
        
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "AzureSqlDatabaseLinkedService" -DefinitionObject $sqlLinkedService
        
        # Azure Blob Storage Linked Service
        $blobLinkedService = @{
            type = "AzureBlobStorage"
            typeProperties = @{
                serviceEndpoint = "https://modernstorageaccount.blob.core.windows.net/"
                accountKind = "StorageV2"
                authenticationType = "MSI"
            }
        }
        
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "AzureBlobStorageLinkedService" -DefinitionObject $blobLinkedService
        
        # Azure Synapse Analytics Linked Service
        $synapseLinkedService = @{
            type = "AzureSqlDW"
            typeProperties = @{
                connectionString = @{
                    type = "AzureKeyVaultSecret"
                    store = @{
                        referenceName = "KeyVaultLinkedService"
                        type = "LinkedServiceReference"
                    }
                    secretName = "SynapseConnectionString"
                }
            }
        }
        
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "AzureSynapseLinkedService" -DefinitionObject $synapseLinkedService
        
        # Key Vault Linked Service
        $keyVaultLinkedService = @{
            type = "AzureKeyVault"
            typeProperties = @{
                baseUrl = "https://modern-keyvault.vault.azure.net/"
            }
        }
        
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "KeyVaultLinkedService" -DefinitionObject $keyVaultLinkedService
        
        Write-EnhancedLog "Created sample linked services" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to create linked services: $($_.Exception.Message)" "Error"
    }
}

# Create sample datasets
function New-SampleDatasets {
    try {
        # Source SQL Dataset
        $sourceDataset = @{
            type = "AzureSqlTable"
            linkedServiceName = @{
                referenceName = "AzureSqlDatabaseLinkedService"
                type = "LinkedServiceReference"
            }
            typeProperties = @{
                schema = "dbo"
                table = "SourceTable"
            }
        }
        
        Set-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "SourceSqlDataset" -DefinitionObject $sourceDataset
        
        # Blob Storage Dataset
        $blobDataset = @{
            type = "DelimitedText"
            linkedServiceName = @{
                referenceName = "AzureBlobStorageLinkedService"
                type = "LinkedServiceReference"
            }
            typeProperties = @{
                location = @{
                    type = "AzureBlobStorageLocation"
                    container = "data"
                    fileName = "output.csv"
                }
                columnDelimiter = ","
                escapeChar = '"'
                quoteChar = '"'
                firstRowAsHeader = $true
            }
        }
        
        Set-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "BlobOutputDataset" -DefinitionObject $blobDataset
        
        # Synapse Dataset
        $synapseDataset = @{
            type = "AzureSqlDWTable"
            linkedServiceName = @{
                referenceName = "AzureSynapseLinkedService"
                type = "LinkedServiceReference"
            }
            typeProperties = @{
                schema = "dbo"
                table = "DimCustomer"
            }
        }
        
        Set-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "SynapseDataset" -DefinitionObject $synapseDataset
        
        Write-EnhancedLog "Created sample datasets" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to create datasets: $($_.Exception.Message)" "Error"
    }
}

# Create sample pipelines
function New-SamplePipelines {
    try {
        # Modern ETL Pipeline
        $etlPipeline = @{
            activities = @(
                @{
                    name = "CopyFromSqlToBlob"
                    type = "Copy"
                    inputs = @(
                        @{
                            referenceName = "SourceSqlDataset"
                            type = "DatasetReference"
                        }
                    )
                    outputs = @(
                        @{
                            referenceName = "BlobOutputDataset"
                            type = "DatasetReference"
                        }
                    )
                    typeProperties = @{
                        source = @{
                            type = "AzureSqlSource"
                            sqlReaderQuery = "SELECT * FROM dbo.SourceTable WHERE LastModified >= '@{formatDateTime(pipeline().parameters.StartDate, 'yyyy-MM-dd')}'"
                        }
                        sink = @{
                            type = "DelimitedTextSink"
                            storeSettings = @{
                                type = "AzureBlobStorageWriteSettings"
                            }
                            formatSettings = @{
                                type = "DelimitedTextWriteSettings"
                                quoteAllText = $true
                                fileExtension = ".csv"
                            }
                        }
                        enableStaging = $false
                        parallelCopies = 4
                        cloudDataMovementUnits = 32
                    }
                },
                @{
                    name = "DataTransformation"
                    type = "DatabricksNotebook"
                    dependsOn = @(
                        @{
                            activity = "CopyFromSqlToBlob"
                            dependencyConditions = @("Succeeded")
                        }
                    )
                    typeProperties = @{
                        notebookPath = "/Shared/data-transformation"
                        baseParameters = @{
                            inputPath = "@activity('CopyFromSqlToBlob').output.effectiveIntegrationRuntime"
                            outputPath = "dbfs:/mnt/processed/data"
                        }
                    }
                    linkedServiceName = @{
                        referenceName = "DatabricksLinkedService"
                        type = "LinkedServiceReference"
                    }
                },
                @{
                    name = "LoadToSynapse"
                    type = "Copy"
                    dependsOn = @(
                        @{
                            activity = "DataTransformation"
                            dependencyConditions = @("Succeeded")
                        }
                    )
                    inputs = @(
                        @{
                            referenceName = "BlobOutputDataset"
                            type = "DatasetReference"
                        }
                    )
                    outputs = @(
                        @{
                            referenceName = "SynapseDataset"
                            type = "DatasetReference"
                        }
                    )
                    typeProperties = @{
                        source = @{
                            type = "DelimitedTextSource"
                        }
                        sink = @{
                            type = "SqlDWSink"
                            preCopyScript = "TRUNCATE TABLE dbo.DimCustomer"
                            allowPolyBase = $true
                            polyBaseSettings = @{
                                rejectValue = 0
                                rejectType = "value"
                                useTypeDefault = $true
                            }
                        }
                        enableStaging = $true
                        stagingSettings = @{
                            linkedServiceName = @{
                                referenceName = "AzureBlobStorageLinkedService"
                                type = "LinkedServiceReference"
                            }
                            path = "staging"
                        }
                    }
                }
            )
            parameters = @{
                StartDate = @{
                    type = "String"
                    defaultValue = "@formatDateTime(addDays(utcnow(), -1), 'yyyy-MM-dd')"
                }
            }
        }
        
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "ModernETLPipeline" -DefinitionObject $etlPipeline
        
        # Real-time Streaming Pipeline
        $streamingPipeline = @{
            activities = @(
                @{
                    name = "ProcessEventHubData"
                    type = "ExecuteDataFlow"
                    typeProperties = @{
                        dataflow = @{
                            referenceName = "EventStreamDataFlow"
                            type = "DataFlowReference"
                        }
                        compute = @{
                            coreCount = 8
                            computeType = "General"
                        }
                        integrationRuntime = @{
                            referenceName = "DataFlowIntegrationRuntime"
                            type = "IntegrationRuntimeReference"
                        }
                    }
                }
            )
        }
        
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "RealTimeStreamingPipeline" -DefinitionObject $streamingPipeline
        
        Write-EnhancedLog "Created sample pipelines" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to create pipelines: $($_.Exception.Message)" "Error"
    }
}

# Deploy pipeline from definition file
function Deploy-PipelineFromFile {
    param(
        [string]$PipelineName,
        [string]$DefinitionPath
    )
    
    try {
        Write-EnhancedLog "Deploying pipeline '$PipelineName' from: $DefinitionPath" "Info"
        
        if (-not (Test-Path $DefinitionPath)) {
            throw "Pipeline definition file not found: $DefinitionPath"
        }
        
        $pipelineDefinition = Get-Content $DefinitionPath -Raw | ConvertFrom-Json
        
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $PipelineName -DefinitionObject $pipelineDefinition
        
        Write-EnhancedLog "Successfully deployed pipeline: $PipelineName" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to deploy pipeline: $($_.Exception.Message)" "Error"
        throw
    }
}

# Create and configure triggers
function New-DataFactoryTriggers {
    try {
        Write-EnhancedLog "Creating Data Factory triggers..." "Info"
        
        # Schedule Trigger
        $scheduleTrigger = @{
            type = "ScheduleTrigger"
            typeProperties = @{
                recurrence = @{
                    frequency = "Day"
                    interval = 1
                    startTime = (Get-Date).AddDays(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
                    timeZone = "UTC"
                    schedule = @{
                        hours = @(2)
                        minutes = @(0)
                    }
                }
            }
            pipelines = @(
                @{
                    pipelineReference = @{
                        referenceName = "ModernETLPipeline"
                        type = "PipelineReference"
                    }
                    parameters = @{
                        StartDate = "@formatDateTime(addDays(utcnow(), -1), 'yyyy-MM-dd')"
                    }
                }
            )
        }
        
        Set-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "DailyETLTrigger" -DefinitionObject $scheduleTrigger
        
        # Event-based Trigger
        $eventTrigger = @{
            type = "BlobEventsTrigger"
            typeProperties = @{
                blobPathBeginsWith = "/data/input/"
                blobPathEndsWith = ".csv"
                ignoreEmptyBlobs = $true
                scope = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/modernstorageaccount"
                events = @("Microsoft.Storage.BlobCreated")
            }
            pipelines = @(
                @{
                    pipelineReference = @{
                        referenceName = "RealTimeStreamingPipeline"
                        type = "PipelineReference"
                    }
                }
            )
        }
        
        Set-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "BlobEventTrigger" -DefinitionObject $eventTrigger
        
        Write-EnhancedLog "Successfully created triggers" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to create triggers: $($_.Exception.Message)" "Error"
    }
}

# Monitor Data Factory pipelines
function Get-DataFactoryMonitoring {
    try {
        Write-EnhancedLog "Monitoring Data Factory pipelines..." "Info"
        
        # Get pipeline runs from last 24 hours
        $startTime = (Get-Date).AddDays(-1)
        $endTime = Get-Date
        
        $pipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -LastUpdatedAfter $startTime -LastUpdatedBefore $endTime
        
        Write-EnhancedLog "Pipeline Runs in Last 24 Hours:" "Info"
        foreach ($run in $pipelineRuns) {
            $status = switch ($run.Status) {
                "Succeeded" { "Success" }
                "Failed" { "Error" }
                "InProgress" { "Info" }
                default { "Warning" }
            }
            
            Write-EnhancedLog "  Pipeline: $($run.PipelineName)" "Info"
            Write-EnhancedLog "  Run ID: $($run.RunId)" "Info"
            Write-EnhancedLog "  Status: $($run.Status)" $status
            Write-EnhancedLog "  Start Time: $($run.RunStart)" "Info"
            Write-EnhancedLog "  Duration: $($run.DurationInMs / 1000) seconds" "Info"
            Write-EnhancedLog "  ---" "Info"
        }
        
        # Get trigger runs
        $triggerRuns = Get-AzDataFactoryV2TriggerRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -LastUpdatedAfter $startTime -LastUpdatedBefore $endTime
        
        Write-EnhancedLog "Trigger Runs in Last 24 Hours:" "Info"
        foreach ($run in $triggerRuns) {
            Write-EnhancedLog "  Trigger: $($run.TriggerName)" "Info"
            Write-EnhancedLog "  Status: $($run.Status)" "Info"
            Write-EnhancedLog "  Trigger Time: $($run.TriggerRunTimestamp)" "Info"
            Write-EnhancedLog "  ---" "Info"
        }
        
        # Get activity runs for failed pipeline runs
        $failedRuns = $pipelineRuns | Where-Object { $_.Status -eq "Failed" }
        foreach ($failedRun in $failedRuns) {
            Write-EnhancedLog "Activity details for failed pipeline run: $($failedRun.RunId)" "Error"
            $activityRuns = Get-AzDataFactoryV2ActivityRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $failedRun.RunId -RunStartedAfter $startTime -RunStartedBefore $endTime
            
            foreach ($activity in $activityRuns) {
                if ($activity.Status -eq "Failed") {
                    Write-EnhancedLog "  Failed Activity: $($activity.ActivityName)" "Error"
                    Write-EnhancedLog "  Error: $($activity.Error.Message)" "Error"
                }
            }
        }
        
    } catch {
        Write-EnhancedLog "Failed to monitor Data Factory: $($_.Exception.Message)" "Error"
    }
}

# Configure monitoring and alerting
function Set-DataFactoryMonitoring {
    try {
        Write-EnhancedLog "Configuring Data Factory monitoring..." "Info"
        
        # Create Log Analytics workspace
        $workspaceName = "law-$ResourceGroupName-adf"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location
            Write-EnhancedLog "Created Log Analytics workspace: $workspaceName" "Success"
        }
        
        # Configure diagnostic settings
        $dataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName
        
        $diagnosticSettings = @{
            logs = @(
                @{
                    category = "PipelineRuns"
                    enabled = $true
                    retentionPolicy = @{
                        enabled = $true
                        days = 90
                    }
                },
                @{
                    category = "TriggerRuns"
                    enabled = $true
                    retentionPolicy = @{
                        enabled = $true
                        days = 90
                    }
                },
                @{
                    category = "ActivityRuns"
                    enabled = $true
                    retentionPolicy = @{
                        enabled = $true
                        days = 90
                    }
                }
            )
            metrics = @(
                @{
                    category = "AllMetrics"
                    enabled = $true
                    retentionPolicy = @{
                        enabled = $true
                        days = 90
                    }
                }
            )
        }
        
        Set-AzDiagnosticSetting -ResourceId $dataFactory.DataFactoryId -WorkspaceId $workspace.ResourceId -Log $diagnosticSettings.logs -Metric $diagnosticSettings.metrics -Name "$DataFactoryName-diagnostics"
        
        Write-EnhancedLog "Successfully configured monitoring" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to configure monitoring: $($_.Exception.Message)" "Error"
    }
}

# Export Data Factory configuration
function Export-DataFactoryConfiguration {
    try {
        Write-EnhancedLog "Exporting Data Factory configuration..." "Info"
        
        $exportPath = ".\DataFactory-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        New-Item -ItemType Directory -Path $exportPath -Force | Out-Null
        
        # Export pipelines
        $pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
        foreach ($pipeline in $pipelines) {
            $pipelineDefinition = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $pipeline.Name
            $pipelineDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath "$exportPath\pipeline-$($pipeline.Name).json" -Encoding UTF8
        }
        
        # Export datasets
        $datasets = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
        foreach ($dataset in $datasets) {
            $datasetDefinition = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $dataset.Name
            $datasetDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath "$exportPath\dataset-$($dataset.Name).json" -Encoding UTF8
        }
        
        # Export linked services
        $linkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
        foreach ($linkedService in $linkedServices) {
            $linkedServiceDefinition = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $linkedService.Name
            $linkedServiceDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath "$exportPath\linkedservice-$($linkedService.Name).json" -Encoding UTF8
        }
        
        # Export triggers
        $triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
        foreach ($trigger in $triggers) {
            $triggerDefinition = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $trigger.Name
            $triggerDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath "$exportPath\trigger-$($trigger.Name).json" -Encoding UTF8
        }
        
        Write-EnhancedLog "Successfully exported Data Factory configuration to: $exportPath" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to export Data Factory configuration: $($_.Exception.Message)" "Error"
    }
}

# Main execution
try {
    Write-EnhancedLog "Starting Azure Data Factory Modern Pipeline Tool" "Info"
    Write-EnhancedLog "Action: $Action" "Info"
    Write-EnhancedLog "Data Factory Name: $DataFactoryName" "Info"
    Write-EnhancedLog "Resource Group: $ResourceGroupName" "Info"
    
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-EnhancedLog "Creating resource group: $ResourceGroupName" "Info"
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
        Write-EnhancedLog "Successfully created resource group" "Success"
    }
    
    switch ($Action) {
        "Create" {
            $dataFactory = New-DataFactoryInstance
            New-ModernDataPipelines
            New-DataFactoryTriggers
            
            if ($EnableMonitoring) {
                Set-DataFactoryMonitoring
            }
        }
        
        "Deploy" {
            if (-not $PipelineName) {
                throw "PipelineName parameter is required for Deploy action"
            }
            
            if ($PipelineDefinitionPath) {
                Deploy-PipelineFromFile -PipelineName $PipelineName -DefinitionPath $PipelineDefinitionPath
            } else {
                New-ModernDataPipelines
            }
        }
        
        "Monitor" {
            Get-DataFactoryMonitoring
        }
        
        "Trigger" {
            if (-not $PipelineName) {
                throw "PipelineName parameter is required for Trigger action"
            }
            
            Write-EnhancedLog "Triggering pipeline: $PipelineName" "Info"
            $runId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineName $PipelineName
            Write-EnhancedLog "Pipeline triggered successfully. Run ID: $runId" "Success"
        }
        
        "Configure" {
            New-DataFactoryTriggers
            if ($EnableMonitoring) {
                Set-DataFactoryMonitoring
            }
        }
        
        "Export" {
            Export-DataFactoryConfiguration
        }
        
        "Delete" {
            Write-EnhancedLog "Deleting Data Factory: $DataFactoryName" "Warning"
            Remove-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -Force
            Write-EnhancedLog "Successfully deleted Data Factory" "Success"
        }
    }
    
    Write-EnhancedLog "Azure Data Factory Modern Pipeline Tool completed successfully" "Success"
    
} catch {
    Write-EnhancedLog "Tool execution failed: $($_.Exception.Message)" "Error"
    exit 1
}
