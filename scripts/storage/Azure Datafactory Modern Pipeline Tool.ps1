#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Data Factory Modern Pipeline Management Tool

.DESCRIPTION
    Tool for creating, managing, and monitoring Azure Data Factory pipelines


    Author: Wes Ellis (wes@wesellis.com)
    [string]$ErrorActionPreference = 'Stop'

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
    Enable  monitoring and alerting
.PARAMETER EnablePrivateEndpoints
    Create private endpoints for secure access
.PARAMETER GitConfiguration
    Git repository configuration for CI/CD
.PARAMETER Tags
    Tags to apply to resources
    .\Azure-DataFactory-Modern-Pipeline-Tool.ps1 -ResourceGroupName " data-rg" -DataFactoryName " modern-adf" -Location "East US" -Action "Create" -EnableMonitoring
    .\Azure-DataFactory-Modern-Pipeline-Tool.ps1 -ResourceGroupName " data-rg" -DataFactoryName " modern-adf" -Action "Deploy" -PipelineName " etl-pipeline" -PipelineDefinitionPath "C:\pipelines\etl.json"
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Az.DataFactory module
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DataFactoryName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "Deploy", "Monitor", "Trigger", "Configure", "Delete", "Export")]
    [string]$Action,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$PipelineName,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$PipelineDefinitionPath,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$TriggerName,
    [Parameter(Mandatory = $false)]
    [ValidateSet("Schedule", "Tumbling", "Event", "Manual")]
    [string]$TriggerType = "Schedule",
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$DatasetName,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
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
try {
                    Write-Output "Successfully imported required Azure modules" # Color: $2
} catch {
    Write-Error "  Failed to import required modules: $($_.Exception.Message)"
    throw
}
[OutputType([bool])]
 "Log entry"ndatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("Info" , "Warning" , "Error" , "Success" )]
        [string]$Level = "Info"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow"
        Error = "Red"
        Success = "Green"
    }
    Write-Output " [$timestamp] $Message" -ForegroundColor $colors[$Level]
}
function New-DataFactoryInstance -ErrorAction Stop {
    param()
    try {
        if ($PSCmdlet.ShouldProcess($DataFactoryName, "Create Azure Data Factory instance" )) {
            Write-Verbose "Log entry"ng Azure Data Factory instance: $DataFactoryName" "Info"
    [string]$ExistingDataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -ErrorAction SilentlyContinue
            if ($ExistingDataFactory) {
                Write-Verbose "Log entry"Name" "Warning"
                return $ExistingDataFactory
            }
    [string]$DataFactory = Set-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -Location $Location -Tag $Tags
            Write-Verbose "Log entry"Name" "Success"
            if ($GitConfiguration.Keys.Count -gt 0) {
                Set-DataFactoryGitConfiguration -ErrorAction Stop
            }
            return $DataFactory
        }
    } catch {
        Write-Verbose "Log entry"n.Message)" "Error"
        throw
    }
}
function Set-DataFactoryGitConfiguration -ErrorAction Stop {
    param()
    try {
        if ($PSCmdlet.ShouldProcess($DataFactoryName, "Configure Git integration for Data Factory" )) {
            Write-Verbose "Log entry"nfiguring Git integration for Data Factory..." "Info"
            if ($GitConfiguration.ContainsKey("RepoUrl" ) -and $GitConfiguration.ContainsKey("BranchName" )) {
    $GitConfig = @{
                    ResourceGroupName = $ResourceGroupName
                    DataFactoryName = $DataFactoryName
                    RepositoryUrl = $GitConfiguration.RepoUrl
                    BranchName = $GitConfiguration.BranchName
                    RootFolder = $GitConfiguration.RootFolder ?? "/"
                    CollaborationBranch = $GitConfiguration.CollaborationBranch ?? " main"
                }
                Set-AzDataFactoryV2GitIntegration -ErrorAction Stop @gitConfig
                Write-Verbose "Log entry"nfigured Git integration" "Success"
            }
        }
    } catch {
        Write-Verbose "Log entry"nfigure Git integration: $($_.Exception.Message)" "Error"
    }
}
function New-ModernDataPipeline -ErrorAction Stop {
    param()
    try {
        if ($PSCmdlet.ShouldProcess($DataFactoryName, "Create modern data pipeline templates" )) {
            Write-Verbose "Log entry"ng modern data pipeline templates..." "Info"
        New-SampleLinkedService -ErrorAction Stop
        New-SampleDataset -ErrorAction Stop
        New-SamplePipeline -ErrorAction Stop
        Write-Verbose "Log entry"n data pipeline templates" "Success"
        }
    } catch {
        Write-Verbose "Log entry"ne templates: $($_.Exception.Message)" "Error"
    }
}
function New-SampleLinkedService -ErrorAction Stop {
    param()
    if (-not $PSCmdlet.ShouldProcess($DataFactoryName, "Create sample linked services" )) {
        return
    }
    try {
    $SqlLinkedService = @{
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
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "AzureSqlDatabaseLinkedService" -DefinitionObject $SqlLinkedService
    $BlobLinkedService = @{
            type = "AzureBlobStorage"
            typeProperties = @{
                serviceEndpoint = "https://modernstorageaccount.blob.core.windows.net/"
                accountKind = "StorageV2"
                authenticationType = "MSI"
            }
        }
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "AzureBlobStorageLinkedService" -DefinitionObject $BlobLinkedService
    $SynapseLinkedService = @{
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
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "AzureSynapseLinkedService" -DefinitionObject $SynapseLinkedService
    $KeyVaultLinkedService = @{
            type = "AzureKeyVault"
            typeProperties = @{
                baseUrl = "https://modern-keyvault.vault.azure.net/"
            }
        }
        Set-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "KeyVaultLinkedService" -DefinitionObject $KeyVaultLinkedService
        Write-Verbose "Log entry"nked services" "Success"
    } catch {
        Write-Verbose "Log entry"nked services: $($_.Exception.Message)" "Error"
    }
}
function New-SampleDataset -ErrorAction Stop {
    param()
    if (-not $PSCmdlet.ShouldProcess($DataFactoryName, "Create sample datasets" )) {
        return
    }
    try {
    $SourceDataset = @{
            type = "AzureSqlTable"
            linkedServiceName = @{
                referenceName = "AzureSqlDatabaseLinkedService"
                type = "LinkedServiceReference"
            }
            typeProperties = @{
                schema = " dbo"
                table = "SourceTable"
            }
        }
        Set-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "SourceSqlDataset" -DefinitionObject $SourceDataset
    $BlobDataset = @{
            type = "DelimitedText"
            linkedServiceName = @{
                referenceName = "AzureBlobStorageLinkedService"
                type = "LinkedServiceReference"
            }
            typeProperties = @{
                location = @{
                    type = "AzureBlobStorageLocation"
                    container = " data"
                    fileName = " output.csv"
                }
                columnDelimiter = " ,"
                escapeChar = '" '
                quoteChar = '" '
                firstRowAsHeader = $true
            }
        }
        Set-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "BlobOutputDataset" -DefinitionObject $BlobDataset
    $SynapseDataset = @{
            type = "AzureSqlDWTable"
            linkedServiceName = @{
                referenceName = "AzureSynapseLinkedService"
                type = "LinkedServiceReference"
            }
            typeProperties = @{
                schema = " dbo"
                table = "DimCustomer"
            }
        }
        Set-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "SynapseDataset" -DefinitionObject $SynapseDataset
        Write-Verbose "Log entry"nhancedLog "Failed to create datasets: $($_.Exception.Message)" "Error"
    }
}
function New-SamplePipeline -ErrorAction Stop {
    param()
    if (-not $PSCmdlet.ShouldProcess($DataFactoryName, "Create sample pipelines" )) {
        return
    }
    try {
    $EtlPipeline = @{
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
                                fileExtension = " .csv"
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
                            dependencyConditions = @("Succeeded" )
                        }
                    )
                    typeProperties = @{
                        notebookPath = "/Shared/data-transformation"
                        baseParameters = @{
                            inputPath = " @activity('CopyFromSqlToBlob').output.effectiveIntegrationRuntime"
                            outputPath = " dbfs:/mnt/processed/data"
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
                            dependencyConditions = @("Succeeded" )
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
                                rejectType = " value"
                                useTypeDefault = $true
                            }
                        }
                        enableStaging = $true
                        stagingSettings = @{
                            linkedServiceName = @{
                                referenceName = "AzureBlobStorageLinkedService"
                                type = "LinkedServiceReference"
                            }
                            path = " staging"
                        }
                    }
                }
            )
            parameters = @{
                StartDate = @{
                    type = "String"
                    defaultValue = " @formatDateTime(addDays(utcnow(), -1), 'yyyy-MM-dd')"
                }
            }
        }
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "ModernETLPipeline" -DefinitionObject $EtlPipeline
    $StreamingPipeline = @{
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
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "RealTimeStreamingPipeline" -DefinitionObject $StreamingPipeline
        Write-Verbose "Log entry"nes" "Success"
    } catch {
        Write-Verbose "Log entry"nes: $($_.Exception.Message)" "Error"
    }
}
function Deploy-PipelineFromFile {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PipelineName,
        [string]$DefinitionPath
    )
    try {
        Write-Verbose "Log entry"ng pipeline '$PipelineName' from: $DefinitionPath" "Info"
        if (-not (Test-Path $DefinitionPath)) {
            throw "Pipeline definition file not found: $DefinitionPath"
        }
    [string]$PipelineDefinition = Get-Content -ErrorAction Stop $DefinitionPath -Raw | ConvertFrom-Json
        Set-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $PipelineName -DefinitionObject $PipelineDefinition
        Write-Verbose "Log entry"ne: $PipelineName" "Success"
    } catch {
        Write-Verbose "Log entry"ne: $($_.Exception.Message)" "Error"
        throw
    }
}
function New-DataFactoryTrigger -ErrorAction Stop {
    param()
    if (-not $PSCmdlet.ShouldProcess($DataFactoryName, "Create Data Factory triggers" )) {
        return
    }
    try {
        Write-Verbose "Log entry"ng Data Factory triggers..." "Info"
    $ScheduleTrigger = @{
            type = "ScheduleTrigger"
            typeProperties = @{
                recurrence = @{
                    frequency = "Day"
                    interval = 1
                    startTime = (Get-Date).AddDays(1).ToString(" yyyy-MM-ddTHH:mm:ssZ" )
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
                        StartDate = " @formatDateTime(addDays(utcnow(), -1), 'yyyy-MM-dd')"
                    }
                }
            )
        }
        Set-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "DailyETLTrigger" -DefinitionObject $ScheduleTrigger
    $EventTrigger = @{
            type = "BlobEventsTrigger"
            typeProperties = @{
                blobPathBeginsWith = "/data/input/"
                blobPathEndsWith = " .csv"
                ignoreEmptyBlobs = $true
                scope = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/modernstorageaccount"
                events = @("Microsoft.Storage.BlobCreated" )
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
        Set-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name "BlobEventTrigger" -DefinitionObject $EventTrigger
        Write-Verbose "Log entry"nhancedLog "Failed to create triggers: $($_.Exception.Message)" "Error"
    }
}
function Get-DataFactoryMonitoring -ErrorAction Stop {
    try {
        Write-Verbose "Log entry"nitoring Data Factory pipelines..." "Info"
    [string]$StartTime = (Get-Date).AddDays(-1)
    [string]$EndTime = Get-Date -ErrorAction Stop
    [string]$PipelineRuns = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -LastUpdatedAfter $StartTime -LastUpdatedBefore $EndTime
        Write-Verbose "Log entry"ne Runs in Last 24 Hours:" "Info"
        foreach ($run in $PipelineRuns) {
    [string]$status = switch ($run.Status) {
                "Succeeded" { "Success" }
                "Failed" { "Error" }
                "InProgress" { "Info" }
                default { "Warning" }
            }
            Write-Verbose "Log entry"ne: $($run.PipelineName)" "Info"
            Write-Verbose "Log entry"n ID: $($run.RunId)" "Info"
            Write-Verbose "Log entry"n.Status)" $status
            Write-Verbose "Log entry"n.RunStart)" "Info"
            Write-Verbose "Log entry"n: $($run.DurationInMs / 1000) seconds" "Info"
            Write-Verbose "Log entry"nfo"
        }
    [string]$TriggerRuns = Get-AzDataFactoryV2TriggerRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -LastUpdatedAfter $StartTime -LastUpdatedBefore $EndTime
        Write-Verbose "Log entry"ns in Last 24 Hours:" "Info"
        foreach ($run in $TriggerRuns) {
            Write-Verbose "Log entry"n.TriggerName)" "Info"
            Write-Verbose "Log entry"n.Status)" "Info"
            Write-Verbose "Log entry"n.TriggerRunTimestamp)" "Info"
            Write-Verbose "Log entry"nfo"
        }
    [string]$FailedRuns = $PipelineRuns | Where-Object { $_.Status -eq "Failed" }
        foreach ($FailedRun in $FailedRuns) {
            Write-Verbose "Log entry"ne run: $($FailedRun.RunId)" "Error"
    [string]$ActivityRuns = Get-AzDataFactoryV2ActivityRun -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineRunId $FailedRun.RunId -RunStartedAfter $StartTime -RunStartedBefore $EndTime
            foreach ($activity in $ActivityRuns) {
                if ($activity.Status -eq "Failed" ) {
                    Write-Verbose "Log entry"Name)" "Error"
                    Write-Verbose "Log entry"nhancedLog "Failed to monitor Data Factory: $($_.Exception.Message)" "Error"
    }
}
function Set-DataFactoryMonitoring -ErrorAction Stop {
    param()
    if (-not $PSCmdlet.ShouldProcess($DataFactoryName, "Configure Data Factory monitoring" )) {
        return
    }
    try {
        Write-Verbose "Log entry"nfiguring Data Factory monitoring..." "Info"
    [string]$WorkspaceName = " law-$ResourceGroupName-adf"
    [string]$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
        if (-not $workspace) {
    [string]$workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Location $Location
            Write-Verbose "Log entry"nalytics workspace: $WorkspaceName" "Success"
        }
    [string]$DataFactory = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName
    $DiagnosticSettings = @{
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
        Set-AzDiagnosticSetting -ResourceId $DataFactory.DataFactoryId -WorkspaceId $workspace.ResourceId -Log $DiagnosticSettings.logs -Metric $DiagnosticSettings.metrics -Name " $DataFactoryName-diagnostics"
        Write-Verbose "Log entry"nfigured monitoring" "Success"
    } catch {
        Write-Verbose "Log entry"nfigure monitoring: $($_.Exception.Message)" "Error"
    }
}
function Export-DataFactoryConfiguration {
    try {
        Write-Verbose "Log entry"ng Data Factory configuration..." "Info"
    [string]$ExportPath = " .\DataFactory-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null
    [string]$pipelines = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
        foreach ($pipeline in $pipelines) {
    [string]$PipelineDefinition = Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $pipeline.Name
    [string]$PipelineDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath " $ExportPath\pipeline-$($pipeline.Name).json" -Encoding UTF8
        }
    [string]$datasets = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
        foreach ($dataset in $datasets) {
    [string]$DatasetDefinition = Get-AzDataFactoryV2Dataset -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $dataset.Name
    [string]$DatasetDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath " $ExportPath\dataset-$($dataset.Name).json" -Encoding UTF8
        }
    [string]$LinkedServices = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
        foreach ($LinkedService in $LinkedServices) {
    [string]$LinkedServiceDefinition = Get-AzDataFactoryV2LinkedService -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $LinkedService.Name
    [string]$LinkedServiceDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath " $ExportPath\linkedservice-$($LinkedService.Name).json" -Encoding UTF8
        }
    [string]$triggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
        foreach ($trigger in $triggers) {
    [string]$TriggerDefinition = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $trigger.Name
    [string]$TriggerDefinition | ConvertTo-Json -Depth 20 | Out-File -FilePath " $ExportPath\trigger-$($trigger.Name).json" -Encoding UTF8
        }
        Write-Verbose "Log entry"nfiguration to: $ExportPath" "Success"
    } catch {
        Write-Verbose "Log entry"nfiguration: $($_.Exception.Message)" "Error"
    }
}
try {
    Write-Verbose "Log entry"ng Azure Data Factory Modern Pipeline Tool" "Info"
    Write-Verbose "Log entry"n: $Action" "Info"
    Write-Verbose "Log entry"Name: $DataFactoryName" "Info"
    Write-Verbose "Log entry"Name" "Info"
    [string]$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Verbose "Log entry"ng resource group: $ResourceGroupName" "Info"
    $ResourcegroupSplat = @{
    Name = $ResourceGroupName
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
        Write-Verbose "Log entry"n) {
        "Create" {
    [string]$DataFactory = New-DataFactoryInstance -ErrorAction Stop
            New-ModernDataPipeline
            New-DataFactoryTrigger -ErrorAction Stop
            if ($EnableMonitoring) {
                Set-DataFactoryMonitoring -ErrorAction Stop
            }
        }
        "Deploy" {
            if (-not $PipelineName) {
                throw "PipelineName parameter is required for Deploy action"
            }
            if ($PipelineDefinitionPath) {
                Deploy-PipelineFromFile -PipelineName $PipelineName -DefinitionPath $PipelineDefinitionPath
            } else {
                New-ModernDataPipeline -ErrorAction Stop
            }
        }
        "Monitor" {
            Get-DataFactoryMonitoring -ErrorAction Stop
        }
        "Trigger" {
            if (-not $PipelineName) {
                throw "PipelineName parameter is required for Trigger action"
            }
            Write-Verbose "Log entry"ng pipeline: $PipelineName" "Info"
    [string]$RunId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineName $PipelineName
            Write-Verbose "Log entry"ne triggered successfully. Run ID: $RunId" "Success"
        }
        "Configure" {
            New-DataFactoryTrigger -ErrorAction Stop
            if ($EnableMonitoring) {
                Set-DataFactoryMonitoring -ErrorAction Stop
            }
        }
        "Export" {
            Export-DataFactoryConfiguration
        }
        "Delete" {
            Write-Verbose "Log entry"ng Data Factory: $DataFactoryName" "Warning"
            Remove-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName -Force
            Write-Verbose "Log entry"nhancedLog "Azure Data Factory Modern Pipeline Tool completed successfully" "Success"
} catch {
    Write-Verbose "Log entry"n failed: $($_.Exception.Message)" "Error"
    throw`n}
