<#
.SYNOPSIS
    Azure Datafactory Modern Pipeline Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Datafactory Modern Pipeline Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

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
    .\Azure-DataFactory-Modern-Pipeline-Tool.ps1 -ResourceGroupName " data-rg" -DataFactoryName " modern-adf" -Location " East US" -Action " Create" -EnableMonitoring
.EXAMPLE
    .\Azure-DataFactory-Modern-Pipeline-Tool.ps1 -ResourceGroupName " data-rg" -DataFactoryName " modern-adf" -Action " Deploy" -PipelineName " etl-pipeline" -PipelineDefinitionPath " C:\pipelines\etl.json"
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Az.DataFactory module


[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDataFactoryName,
    
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet(" Create" , " Deploy" , " Monitor" , " Trigger" , " Configure" , " Delete" , " Export" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPipelineName,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPipelineDefinitionPath,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETriggerName,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet(" Schedule" , " Tumbling" , " Event" , " Manual" )]
    [string]$WETriggerType = " Schedule" ,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDatasetName,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELinkedServiceName,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableMonitoring,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnablePrivateEndpoints,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$WEGitConfiguration = @{},
    
    [Parameter(Mandatory = $false)]
    [hashtable]$WETags = @{
        Environment = " Production"
        Application = " DataFactory"
        ManagedBy = " AutomationScript"
    }
)


try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.DataFactory -Force -ErrorAction Stop
    Import-Module Az.Storage -Force -ErrorAction Stop
    Write-WELog " ✅ Successfully imported required Azure modules" " INFO" -ForegroundColor Green
} catch {
    Write-Error " ❌ Failed to import required modules: $($_.Exception.Message)"
    exit 1
}


function WE-Write-EnhancedLog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEMessage,
        [ValidateSet(" Info" , " Warning" , " Error" , " Success" )]
        [string]$WELevel = " Info"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = " White"
        Warning = " Yellow" 
        Error = " Red"
        Success = " Green"
    }
    
    Write-WELog " [$timestamp] $WEMessage" " INFO" -ForegroundColor $colors[$WELevel]
}


function WE-New-DataFactoryInstance {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try {
        if ($WEPSCmdlet.ShouldProcess($WEDataFactoryName, " Create Azure Data Factory instance" )) {
            Write-EnhancedLog " Creating Azure Data Factory instance: $WEDataFactoryName" " Info"
        
            # Check if Data Factory already exists
            $existingDataFactory = Get-AzDataFactoryV2 -ResourceGroupName $WEResourceGroupName -Name $WEDataFactoryName -ErrorAction SilentlyContinue
            if ($existingDataFactory) {
                Write-EnhancedLog " Data Factory already exists: $WEDataFactoryName" " Warning"
                return $existingDataFactory
            }
            
            # Create Data Factory
            $dataFactory = Set-AzDataFactoryV2 -ResourceGroupName $WEResourceGroupName -Name $WEDataFactoryName -Location $WELocation -Tag $WETags
            Write-EnhancedLog " Successfully created Data Factory: $WEDataFactoryName" " Success"
            
            # Configure Git integration if provided
            if ($WEGitConfiguration.Keys.Count -gt 0) {
                Set-DataFactoryGitConfiguration
            }
            
            return $dataFactory
        }
        
    } catch {
        Write-EnhancedLog " Failed to create Data Factory: $($_.Exception.Message)" " Error"
        throw
    }
}


function WE-Set-DataFactoryGitConfiguration {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try {
        if ($WEPSCmdlet.ShouldProcess($WEDataFactoryName, " Configure Git integration for Data Factory" )) {
            Write-EnhancedLog " Configuring Git integration for Data Factory..." " Info"
        
            if ($WEGitConfiguration.ContainsKey(" RepoUrl" ) -and $WEGitConfiguration.ContainsKey(" BranchName" )) {
                $gitConfig = @{
                    ResourceGroupName = $WEResourceGroupName
                    DataFactoryName = $WEDataFactoryName
                    RepositoryUrl = $WEGitConfiguration.RepoUrl
                    BranchName = $WEGitConfiguration.BranchName
                    RootFolder = $WEGitConfiguration.RootFolder ?? " /"
                    CollaborationBranch = $WEGitConfiguration.CollaborationBranch ?? " main"
                }
                
                Set-AzDataFactoryV2GitIntegration @gitConfig
                Write-EnhancedLog " Successfully configured Git integration" " Success"
            }
        }
        
    } catch {
        Write-EnhancedLog " Failed to configure Git integration: $($_.Exception.Message)" " Error"
    }
}


function WE-New-ModernDataPipeline {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try {
        if ($WEPSCmdlet.ShouldProcess($WEDataFactoryName, " Create modern data pipeline templates" )) {
            Write-EnhancedLog " Creating modern data pipeline templates..." " Info"
        
        # Create sample linked services
        New-SampleLinkedService
        
        # Create sample datasets
        New-SampleDataset
        
        # Create sample pipelines
        New-SamplePipeline
        
        Write-EnhancedLog " Successfully created modern data pipeline templates" " Success"
        }
        
    } catch {
        Write-EnhancedLog " Failed to create pipeline templates: $($_.Exception.Message)" " Error"
    }
}


function WE-New-SampleLinkedService {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if (-not $WEPSCmdlet.ShouldProcess($WEDataFactoryName, " Create sample linked services" )) {
        return
    }
    
    try {
        # Azure SQL Database Linked Service
        $sqlLinkedService = @{
            type = " AzureSqlDatabase"
            typeProperties = @{
                connectionString = @{
                    type = " AzureKeyVaultSecret"
                    store = @{
                        referenceName = " KeyVaultLinkedService"
                        type = " LinkedServiceReference"
                    }
                    secretName = " SqlConnectionString"
                }
            }
        }
        
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " AzureSqlDatabaseLinkedService" -DefinitionObject $sqlLinkedService
        
        # Azure Blob Storage Linked Service
        $blobLinkedService = @{
            type = " AzureBlobStorage"
            typeProperties = @{
                serviceEndpoint = " https://modernstorageaccount.blob.core.windows.net/"
                accountKind = " StorageV2"
                authenticationType = " MSI"
            }
        }
        
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " AzureBlobStorageLinkedService" -DefinitionObject $blobLinkedService
        
        # Azure Synapse Analytics Linked Service
        $synapseLinkedService = @{
            type = " AzureSqlDW"
            typeProperties = @{
                connectionString = @{
                    type = " AzureKeyVaultSecret"
                    store = @{
                        referenceName = " KeyVaultLinkedService"
                        type = " LinkedServiceReference"
                    }
                    secretName = " SynapseConnectionString"
                }
            }
        }
        
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " AzureSynapseLinkedService" -DefinitionObject $synapseLinkedService
        
        # Key Vault Linked Service
        $keyVaultLinkedService = @{
            type = " AzureKeyVault"
            typeProperties = @{
                baseUrl = " https://modern-keyvault.vault.azure.net/"
            }
        }
        
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " KeyVaultLinkedService" -DefinitionObject $keyVaultLinkedService
        
        Write-EnhancedLog " Created sample linked services" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to create linked services: $($_.Exception.Message)" " Error"
    }
}


function WE-New-SampleDataset {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if (-not $WEPSCmdlet.ShouldProcess($WEDataFactoryName, " Create sample datasets" )) {
        return
    }
    
    try {
        # Source SQL Dataset
        $sourceDataset = @{
            type = " AzureSqlTable"
            linkedServiceName = @{
                referenceName = " AzureSqlDatabaseLinkedService"
                type = " LinkedServiceReference"
            }
            typeProperties = @{
                schema = " dbo"
                table = " SourceTable"
            }
        }
        
        Set-AzDataFactoryV2Dataset -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " SourceSqlDataset" -DefinitionObject $sourceDataset
        
        # Blob Storage Dataset
        $blobDataset = @{
            type = " DelimitedText"
            linkedServiceName = @{
                referenceName = " AzureBlobStorageLinkedService"
                type = " LinkedServiceReference"
            }
            typeProperties = @{
                location = @{
                    type = " AzureBlobStorageLocation"
                    container = " data"
                    fileName = " output.csv"
                }
                columnDelimiter = " ,"
                escapeChar = '" '
                quoteChar = '" '
                firstRowAsHeader = $true
            }
        }
        
        Set-AzDataFactoryV2Dataset -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " BlobOutputDataset" -DefinitionObject $blobDataset
        
        # Synapse Dataset
        $synapseDataset = @{
            type = " AzureSqlDWTable"
            linkedServiceName = @{
                referenceName = " AzureSynapseLinkedService"
                type = " LinkedServiceReference"
            }
            typeProperties = @{
                schema = " dbo"
                table = " DimCustomer"
            }
        }
        
        Set-AzDataFactoryV2Dataset -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " SynapseDataset" -DefinitionObject $synapseDataset
        
        Write-EnhancedLog " Created sample datasets" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to create datasets: $($_.Exception.Message)" " Error"
    }
}


function WE-New-SamplePipeline {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if (-not $WEPSCmdlet.ShouldProcess($WEDataFactoryName, " Create sample pipelines" )) {
        return
    }
    
    try {
        # Modern ETL Pipeline
        $etlPipeline = @{
            activities = @(
                @{
                    name = " CopyFromSqlToBlob"
                    type = " Copy"
                    inputs = @(
                        @{
                            referenceName = " SourceSqlDataset"
                            type = " DatasetReference"
                        }
                    )
                    outputs = @(
                        @{
                            referenceName = " BlobOutputDataset"
                            type = " DatasetReference"
                        }
                    )
                    typeProperties = @{
                        source = @{
                            type = " AzureSqlSource"
                            sqlReaderQuery = " SELECT * FROM dbo.SourceTable WHERE LastModified >= '@{formatDateTime(pipeline().parameters.StartDate, 'yyyy-MM-dd')}'"
                        }
                        sink = @{
                            type = " DelimitedTextSink"
                            storeSettings = @{
                                type = " AzureBlobStorageWriteSettings"
                            }
                            formatSettings = @{
                                type = " DelimitedTextWriteSettings"
                                quoteAllText = $true
                                fileExtension = " .csv"
                            }
                        }
                        enableStaging = $false
                        parallelCopies = 4
                        cloudDataMovementUnits = 32
                    }
                },
                @{
                    name = " DataTransformation"
                    type = " DatabricksNotebook"
                    dependsOn = @(
                        @{
                            activity = " CopyFromSqlToBlob"
                            dependencyConditions = @(" Succeeded" )
                        }
                    )
                    typeProperties = @{
                        notebookPath = " /Shared/data-transformation"
                        baseParameters = @{
                            inputPath = " @activity('CopyFromSqlToBlob').output.effectiveIntegrationRuntime"
                            outputPath = " dbfs:/mnt/processed/data"
                        }
                    }
                    linkedServiceName = @{
                        referenceName = " DatabricksLinkedService"
                        type = " LinkedServiceReference"
                    }
                },
                @{
                    name = " LoadToSynapse"
                    type = " Copy"
                    dependsOn = @(
                        @{
                            activity = " DataTransformation"
                            dependencyConditions = @(" Succeeded" )
                        }
                    )
                    inputs = @(
                        @{
                            referenceName = " BlobOutputDataset"
                            type = " DatasetReference"
                        }
                    )
                    outputs = @(
                        @{
                            referenceName = " SynapseDataset"
                            type = " DatasetReference"
                        }
                    )
                    typeProperties = @{
                        source = @{
                            type = " DelimitedTextSource"
                        }
                        sink = @{
                            type = " SqlDWSink"
                            preCopyScript = " TRUNCATE TABLE dbo.DimCustomer"
                            allowPolyBase = $true
                            polyBaseSettings = @{
                                rejectValue = 0
                                rejectType = " value"
                                useTypeDefault = $true
                            }
                        }
                        enableStaging = $true
                        stagingSettings = @{
                            linkedServiceName = @{
                                referenceName = " AzureBlobStorageLinkedService"
                                type = " LinkedServiceReference"
                            }
                            path = " staging"
                        }
                    }
                }
            )
            parameters = @{
                StartDate = @{
                    type = " String"
                    defaultValue = " @formatDateTime(addDays(utcnow(), -1), 'yyyy-MM-dd')"
                }
            }
        }
        
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " ModernETLPipeline" -DefinitionObject $etlPipeline
        
        # Real-time Streaming Pipeline
        $streamingPipeline = @{
            activities = @(
                @{
                    name = " ProcessEventHubData"
                    type = " ExecuteDataFlow"
                    typeProperties = @{
                        dataflow = @{
                            referenceName = " EventStreamDataFlow"
                            type = " DataFlowReference"
                        }
                        compute = @{
                            coreCount = 8
                            computeType = " General"
                        }
                        integrationRuntime = @{
                            referenceName = " DataFlowIntegrationRuntime"
                            type = " IntegrationRuntimeReference"
                        }
                    }
                }
            )
        }
        
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " RealTimeStreamingPipeline" -DefinitionObject $streamingPipeline
        
        Write-EnhancedLog " Created sample pipelines" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to create pipelines: $($_.Exception.Message)" " Error"
    }
}


function WE-Deploy-PipelineFromFile {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPipelineName,
        [string]$WEDefinitionPath
    )
    
    try {
        Write-EnhancedLog " Deploying pipeline '$WEPipelineName' from: $WEDefinitionPath" " Info"
        
        if (-not (Test-Path $WEDefinitionPath)) {
            throw " Pipeline definition file not found: $WEDefinitionPath"
        }
        
        $pipelineDefinition = Get-Content $WEDefinitionPath -Raw | ConvertFrom-Json
        
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name $WEPipelineName -DefinitionObject $pipelineDefinition
        
        Write-EnhancedLog " Successfully deployed pipeline: $WEPipelineName" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to deploy pipeline: $($_.Exception.Message)" " Error"
        throw
    }
}


function WE-New-DataFactoryTrigger {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if (-not $WEPSCmdlet.ShouldProcess($WEDataFactoryName, " Create Data Factory triggers" )) {
        return
    }
    
    try {
        Write-EnhancedLog " Creating Data Factory triggers..." " Info"
        
        # Schedule Trigger
        $scheduleTrigger = @{
            type = " ScheduleTrigger"
            typeProperties = @{
                recurrence = @{
                    frequency = " Day"
                    interval = 1
                    startTime = (Get-Date).AddDays(1).ToString(" yyyy-MM-ddTHH:mm:ssZ" )
                    timeZone = " UTC"
                    schedule = @{
                        hours = @(2)
                        minutes = @(0)
                    }
                }
            }
            pipelines = @(
                @{
                    pipelineReference = @{
                        referenceName = " ModernETLPipeline"
                        type = " PipelineReference"
                    }
                    parameters = @{
                        StartDate = " @formatDateTime(addDays(utcnow(), -1), 'yyyy-MM-dd')"
                    }
                }
            )
        }
        
        Set-AzDataFactoryV2Trigger -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " DailyETLTrigger" -DefinitionObject $scheduleTrigger
        
        # Event-based Trigger
        $eventTrigger = @{
            type = " BlobEventsTrigger"
            typeProperties = @{
                blobPathBeginsWith = " /data/input/"
                blobPathEndsWith = " .csv"
                ignoreEmptyBlobs = $true
                scope = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$WEResourceGroupName/providers/Microsoft.Storage/storageAccounts/modernstorageaccount"
                events = @(" Microsoft.Storage.BlobCreated" )
            }
            pipelines = @(
                @{
                    pipelineReference = @{
                        referenceName = " RealTimeStreamingPipeline"
                        type = " PipelineReference"
                    }
                }
            )
        }
        
        Set-AzDataFactoryV2Trigger -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name " BlobEventTrigger" -DefinitionObject $eventTrigger
        
        Write-EnhancedLog " Successfully created triggers" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to create triggers: $($_.Exception.Message)" " Error"
    }
}


function WE-Get-DataFactoryMonitoring {
    try {
        Write-EnhancedLog " Monitoring Data Factory pipelines..." " Info"
        
        # Get pipeline runs from last 24 hours
        $startTime = (Get-Date).AddDays(-1)
        $endTime = Get-Date
        
        $pipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -LastUpdatedAfter $startTime -LastUpdatedBefore $endTime
        
        Write-EnhancedLog " Pipeline Runs in Last 24 Hours:" " Info"
        foreach ($run in $pipelineRuns) {
            $status = switch ($run.Status) {
                " Succeeded" { " Success" }
                " Failed" { " Error" }
                " InProgress" { " Info" }
                default { " Warning" }
            }
            
            Write-EnhancedLog "  Pipeline: $($run.PipelineName)" " Info"
            Write-EnhancedLog "  Run ID: $($run.RunId)" " Info"
            Write-EnhancedLog "  Status: $($run.Status)" $status
            Write-EnhancedLog "  Start Time: $($run.RunStart)" " Info"
            Write-EnhancedLog "  Duration: $($run.DurationInMs / 1000) seconds" " Info"
            Write-EnhancedLog "  ---" " Info"
        }
        
        # Get trigger runs
        $triggerRuns = Get-AzDataFactoryV2TriggerRun -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -LastUpdatedAfter $startTime -LastUpdatedBefore $endTime
        
        Write-EnhancedLog " Trigger Runs in Last 24 Hours:" " Info"
        foreach ($run in $triggerRuns) {
            Write-EnhancedLog "  Trigger: $($run.TriggerName)" " Info"
            Write-EnhancedLog "  Status: $($run.Status)" " Info"
            Write-EnhancedLog "  Trigger Time: $($run.TriggerRunTimestamp)" " Info"
            Write-EnhancedLog "  ---" " Info"
        }
        
        # Get activity runs for failed pipeline runs
        $failedRuns = $pipelineRuns | Where-Object { $_.Status -eq " Failed" }
        foreach ($failedRun in $failedRuns) {
            Write-EnhancedLog " Activity details for failed pipeline run: $($failedRun.RunId)" " Error"
            $activityRuns = Get-AzDataFactoryV2ActivityRun -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -PipelineRunId $failedRun.RunId -RunStartedAfter $startTime -RunStartedBefore $endTime
            
            foreach ($activity in $activityRuns) {
                if ($activity.Status -eq " Failed" ) {
                    Write-EnhancedLog "  Failed Activity: $($activity.ActivityName)" " Error"
                    Write-EnhancedLog "  Error: $($activity.Error.Message)" " Error"
                }
            }
        }
        
    } catch {
        Write-EnhancedLog " Failed to monitor Data Factory: $($_.Exception.Message)" " Error"
    }
}


function WE-Set-DataFactoryMonitoring {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if (-not $WEPSCmdlet.ShouldProcess($WEDataFactoryName, " Configure Data Factory monitoring" )) {
        return
    }
    
    try {
        Write-EnhancedLog " Configuring Data Factory monitoring..." " Info"
        
        # Create Log Analytics workspace
        $workspaceName = " law-$WEResourceGroupName-adf"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -Location $WELocation
            Write-EnhancedLog " Created Log Analytics workspace: $workspaceName" " Success"
        }
        
        # Configure diagnostic settings
        $dataFactory = Get-AzDataFactoryV2 -ResourceGroupName $WEResourceGroupName -Name $WEDataFactoryName
        
        $diagnosticSettings = @{
            logs = @(
                @{
                    category = " PipelineRuns"
                    enabled = $true
                    retentionPolicy = @{
                        enabled = $true
                        days = 90
                    }
                },
                @{
                    category = " TriggerRuns"
                    enabled = $true
                    retentionPolicy = @{
                        enabled = $true
                        days = 90
                    }
                },
                @{
                    category = " ActivityRuns"
                    enabled = $true
                    retentionPolicy = @{
                        enabled = $true
                        days = 90
                    }
                }
            )
            metrics = @(
                @{
                    category = " AllMetrics"
                    enabled = $true
                    retentionPolicy = @{
                        enabled = $true
                        days = 90
                    }
                }
            )
        }
        
        Set-AzDiagnosticSetting -ResourceId $dataFactory.DataFactoryId -WorkspaceId $workspace.ResourceId -Log $diagnosticSettings.logs -Metric $diagnosticSettings.metrics -Name " $WEDataFactoryName-diagnostics"
        
        Write-EnhancedLog " Successfully configured monitoring" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to configure monitoring: $($_.Exception.Message)" " Error"
    }
}


function WE-Export-DataFactoryConfiguration {
    try {
        Write-EnhancedLog " Exporting Data Factory configuration..." " Info"
        
        $exportPath = " .\DataFactory-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        New-Item -ItemType Directory -Path $exportPath -Force | Out-Null
        
        # Export pipelines
        $pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName
        foreach ($pipeline in $pipelines) {
            $pipelineDefinition = Get-AzDataFactoryV2Pipeline -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name $pipeline.Name
            $pipelineDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath " $exportPath\pipeline-$($pipeline.Name).json" -Encoding UTF8
        }
        
        # Export datasets
        $datasets = Get-AzDataFactoryV2Dataset -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName
        foreach ($dataset in $datasets) {
            $datasetDefinition = Get-AzDataFactoryV2Dataset -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name $dataset.Name
            $datasetDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath " $exportPath\dataset-$($dataset.Name).json" -Encoding UTF8
        }
        
        # Export linked services
        $linkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName
        foreach ($linkedService in $linkedServices) {
            $linkedServiceDefinition = Get-AzDataFactoryV2LinkedService -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name $linkedService.Name
            $linkedServiceDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath " $exportPath\linkedservice-$($linkedService.Name).json" -Encoding UTF8
        }
        
        # Export triggers
        $triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName
        foreach ($trigger in $triggers) {
            $triggerDefinition = Get-AzDataFactoryV2Trigger -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -Name $trigger.Name
            $triggerDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath " $exportPath\trigger-$($trigger.Name).json" -Encoding UTF8
        }
        
        Write-EnhancedLog " Successfully exported Data Factory configuration to: $exportPath" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to export Data Factory configuration: $($_.Exception.Message)" " Error"
    }
}


try {
    Write-EnhancedLog " Starting Azure Data Factory Modern Pipeline Tool" " Info"
    Write-EnhancedLog " Action: $WEAction" " Info"
    Write-EnhancedLog " Data Factory Name: $WEDataFactoryName" " Info"
    Write-EnhancedLog " Resource Group: $WEResourceGroupName" " Info"
    
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-EnhancedLog " Creating resource group: $WEResourceGroupName" " Info"
        $rg = New-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Tag $WETags
        Write-EnhancedLog " Successfully created resource group" " Success"
    }
    
    switch ($WEAction) {
        " Create" {
           ;  $dataFactory = New-DataFactoryInstance
            New-ModernDataPipeline
            New-DataFactoryTrigger
            
            if ($WEEnableMonitoring) {
                Set-DataFactoryMonitoring
            }
        }
        
        " Deploy" {
            if (-not $WEPipelineName) {
                throw " PipelineName parameter is required for Deploy action"
            }
            
            if ($WEPipelineDefinitionPath) {
                Deploy-PipelineFromFile -PipelineName $WEPipelineName -DefinitionPath $WEPipelineDefinitionPath
            } else {
                New-ModernDataPipeline
            }
        }
        
        " Monitor" {
            Get-DataFactoryMonitoring
        }
        
        " Trigger" {
            if (-not $WEPipelineName) {
                throw " PipelineName parameter is required for Trigger action"
            }
            
            Write-EnhancedLog " Triggering pipeline: $WEPipelineName" " Info"
           ;  $runId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $WEResourceGroupName -DataFactoryName $WEDataFactoryName -PipelineName $WEPipelineName
            Write-EnhancedLog " Pipeline triggered successfully. Run ID: $runId" " Success"
        }
        
        " Configure" {
            New-DataFactoryTrigger
            if ($WEEnableMonitoring) {
                Set-DataFactoryMonitoring
            }
        }
        
        " Export" {
            Export-DataFactoryConfiguration
        }
        
        " Delete" {
            Write-EnhancedLog " Deleting Data Factory: $WEDataFactoryName" " Warning"
            Remove-AzDataFactoryV2 -ResourceGroupName $WEResourceGroupName -Name $WEDataFactoryName -Force
            Write-EnhancedLog " Successfully deleted Data Factory" " Success"
        }
    }
    
    Write-EnhancedLog " Azure Data Factory Modern Pipeline Tool completed successfully" " Success"
    
} catch {
    Write-EnhancedLog " Tool execution failed: $($_.Exception.Message)" " Error"
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================