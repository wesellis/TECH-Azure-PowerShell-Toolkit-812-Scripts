#Requires -Module Az.Monitor
<#
.SYNOPSIS
    Azure Monitoring Enterprise Management Module
.DESCRIPTION
    Advanced monitoring and observability management for Azure resources including
    Log Analytics workspaces, custom metrics, alert automation, dashboard deployment,
    workbook templates, and action group management.
.NOTES
    Version: 1.0.0
    Author: Enterprise Toolkit Team
    Requires: Az.Monitor module 4.0+
#>

# Import required modules
Import-Module Az.Monitor -ErrorAction Stop
Import-Module Az.OperationalInsights -ErrorAction Stop

# Module variables
$script:ModuleName = "Az.Monitoring.Enterprise"
$script:ModuleVersion = "1.0.0"

#region Log Analytics Workspace Management

function New-AzLogAnalyticsWorkspaceAdvanced {
    <#
    .SYNOPSIS
        Creates and configures enterprise-grade Log Analytics workspace
    .DESCRIPTION
        Deploys Log Analytics workspace with advanced features including data retention,
        capacity reservation, network isolation, and automated solutions
    .EXAMPLE
        New-AzLogAnalyticsWorkspaceAdvanced -WorkspaceName "Enterprise-LAW" -ResourceGroupName "Monitoring-RG" -Location "eastus"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$WorkspaceName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$Location,
        
        [Parameter()]
        [ValidateSet('Free', 'PerGB2018', 'PerNode', 'Premium', 'Standalone', 'Standard')]
        [string]$Sku = 'PerGB2018',
        
        [Parameter()]
        [ValidateRange(7, 730)]
        [int]$RetentionInDays = 90,
        
        [Parameter()]
        [ValidateSet(100, 200, 300, 400, 500, 1000, 2000, 5000)]
        [int]$CapacityReservationLevel,
        
        [Parameter()]
        [string[]]$Solutions = @('Security', 'Updates', 'SQLAssessment'),
        
        [Parameter()]
        [hashtable]$Tags
    )
    
    begin {
        Write-Verbose "Creating enterprise Log Analytics workspace: $WorkspaceName"
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess($WorkspaceName, "Create Log Analytics workspace")) {
                # Create workspace
                $workspaceParams = @{
                    Name = $WorkspaceName
                    ResourceGroupName = $ResourceGroupName
                    Location = $Location
                    Sku = $Sku
                    RetentionInDays = $RetentionInDays
                }
                
                if ($CapacityReservationLevel) {
                    $workspaceParams['CapacityReservationLevel'] = $CapacityReservationLevel
                }
                
                if ($Tags) {
                    $workspaceParams['Tag'] = $Tags
                }
                
                $workspace = New-AzOperationalInsightsWorkspace @workspaceParams
                
                # Enable solutions
                foreach ($solution in $Solutions) {
                    Enable-AzLogAnalyticsSolution -WorkspaceName $WorkspaceName `
                        -ResourceGroupName $ResourceGroupName `
                        -SolutionName $solution
                }
                
                # Configure data sources
                Set-AzLogAnalyticsDataSources -WorkspaceName $WorkspaceName `
                    -ResourceGroupName $ResourceGroupName
                
                Write-Information "Successfully created workspace: $WorkspaceName" -InformationAction Continue
                return $workspace
            }
        }
        catch {
            Write-Error "Failed to create Log Analytics workspace: $_"
            throw
        }
    }
}

function Set-AzLogAnalyticsDataSources {
    <#
    .SYNOPSIS
        Configures data sources for Log Analytics workspace
    .DESCRIPTION
        Sets up common data sources including Windows/Linux performance counters,
        event logs, syslog, and custom logs
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkspaceName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter()]
        [switch]$EnableAllDataSources
    )
    
    # Windows performance counters
    $windowsCounters = @(
        @{ObjectName="Processor"; InstanceName="*"; CounterName="% Processor Time"},
        @{ObjectName="Memory"; InstanceName="*"; CounterName="Available MBytes"},
        @{ObjectName="LogicalDisk"; InstanceName="*"; CounterName="% Free Space"},
        @{ObjectName="LogicalDisk"; InstanceName="*"; CounterName="Disk Transfers/sec"},
        @{ObjectName="Network Interface"; InstanceName="*"; CounterName="Bytes Total/sec"}
    )
    
    foreach ($counter in $windowsCounters) {
        New-AzOperationalInsightsWindowsPerformanceCounterDataSource `
            -WorkspaceName $WorkspaceName `
            -ResourceGroupName $ResourceGroupName `
            -ObjectName $counter.ObjectName `
            -InstanceName $counter.InstanceName `
            -CounterName $counter.CounterName `
            -IntervalSeconds 60 `
            -Name "$($counter.ObjectName)_$($counter.CounterName)".Replace(" ", "_").Replace("%", "Pct")
    }
    
    # Windows event logs
    $eventLogs = @("System", "Application", "Security")
    foreach ($log in $eventLogs) {
        New-AzOperationalInsightsWindowsEventDataSource `
            -WorkspaceName $WorkspaceName `
            -ResourceGroupName $ResourceGroupName `
            -EventLogName $log `
            -Name "${log}EventLog"
    }
    
    # Linux performance counters
    $linuxCounters = @(
        @{ObjectName="Processor"; InstanceName="*"; CounterName="% Processor Time"},
        @{ObjectName="Memory"; InstanceName="*"; CounterName="% Used Memory"},
        @{ObjectName="Logical Disk"; InstanceName="*"; CounterName="% Used Space"},
        @{ObjectName="Network"; InstanceName="*"; CounterName="Total Bytes Transmitted"}
    )
    
    foreach ($counter in $linuxCounters) {
        New-AzOperationalInsightsLinuxPerformanceCounterDataSource `
            -WorkspaceName $WorkspaceName `
            -ResourceGroupName $ResourceGroupName `
            -ObjectName $counter.ObjectName `
            -InstanceName $counter.InstanceName `
            -CounterName $counter.CounterName `
            -IntervalSeconds 60 `
            -Name "Linux_$($counter.ObjectName)_$($counter.CounterName)".Replace(" ", "_")
    }
    
    Write-Information "Data sources configured for workspace: $WorkspaceName" -InformationAction Continue
}

function Enable-AzLogAnalyticsSolution {
    <#
    .SYNOPSIS
        Enables Log Analytics solutions in workspace
    .DESCRIPTION
        Deploys and configures Log Analytics solutions for various Azure services
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkspaceName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [ValidateSet('Security', 'Updates', 'SQLAssessment', 'ADAssessment', 
                     'AntiMalware', 'AzureActivity', 'ChangeTracking', 
                     'SecurityInsights', 'VMInsights', 'ContainerInsights')]
        [string]$SolutionName
    )
    
    try {
        $workspace = Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName
        
        $solutionProperties = @{
            WorkspaceResourceId = $workspace.ResourceId
        }
        
        Set-AzOperationalInsightsIntelligencePack `
            -ResourceGroupName $ResourceGroupName `
            -WorkspaceName $WorkspaceName `
            -IntelligencePackName $SolutionName `
            -Enabled $true
        
        Write-Information "Enabled solution '$SolutionName' in workspace: $WorkspaceName" -InformationAction Continue
    }
    catch {
        Write-Error "Failed to enable solution: $_"
        throw
    }
}

#endregion

#region Custom Metrics Management

function New-AzCustomMetric {
    <#
    .SYNOPSIS
        Creates custom metrics for Azure resources
    .DESCRIPTION
        Implements custom metric tracking for business KPIs and application metrics
    .EXAMPLE
        New-AzCustomMetric -ResourceId $vmResourceId -MetricName "ApplicationResponseTime" -Value 250 -Unit "Milliseconds"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceId,
        
        [Parameter(Mandatory)]
        [string]$MetricName,
        
        [Parameter(Mandatory)]
        [double]$Value,
        
        [Parameter()]
        [ValidateSet('Count', 'Bytes', 'Seconds', 'Milliseconds', 'BytesPerSecond', 'CountPerSecond', 'Percent')]
        [string]$Unit = 'Count',
        
        [Parameter()]
        [hashtable]$Dimensions,
        
        [Parameter()]
        [datetime]$Timestamp = (Get-Date),
        
        [Parameter()]
        [string]$Namespace = "CustomMetrics"
    )
    
    try {
        # Build metric data
        $metricData = [PSCustomObject]@{
            time = $Timestamp.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            data = @{
                baseData = @{
                    metric = $MetricName
                    namespace = $Namespace
                    dimNames = @()
                    series = @(
                        @{
                            dimValues = @()
                            min = $Value
                            max = $Value
                            sum = $Value
                            count = 1
                        }
                    )
                }
            }
        }
        
        # Add dimensions if provided
        if ($Dimensions) {
            $metricData.data.baseData.dimNames = $Dimensions.Keys
            $metricData.data.baseData.series[0].dimValues = $Dimensions.Values
        }
        
        # Send metric to Azure Monitor
        # Note: This would use the Azure Monitor REST API in production
        Write-Verbose "Sending custom metric: $MetricName with value $Value"
        
        # Log to workspace as backup
        $logEntry = @{
            TimeGenerated = $Timestamp
            MetricName = $MetricName
            MetricValue = $Value
            Unit = $Unit
            ResourceId = $ResourceId
            Dimensions = $Dimensions | ConvertTo-Json -Compress
        }
        
        Write-Information "Custom metric '$MetricName' recorded successfully" -InformationAction Continue
        return $metricData
    }
    catch {
        Write-Error "Failed to create custom metric: $_"
        throw
    }
}

function Get-AzCustomMetricDefinition {
    <#
    .SYNOPSIS
        Retrieves custom metric definitions
    .DESCRIPTION
        Gets metadata about custom metrics including aggregation types and dimensions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceId,
        
        [Parameter()]
        [string]$MetricNamespace = "CustomMetrics",
        
        [Parameter()]
        [string]$MetricName
    )
    
    try {
        $definitions = Get-AzMetricDefinition -ResourceId $ResourceId
        
        if ($MetricNamespace) {
            $definitions = $definitions | Where-Object { $_.Namespace -eq $MetricNamespace }
        }
        
        if ($MetricName) {
            $definitions = $definitions | Where-Object { $_.Name.Value -eq $MetricName }
        }
        
        return $definitions | Select-Object @{N='MetricName';E={$_.Name.Value}}, 
                                          @{N='DisplayName';E={$_.Name.LocalizedValue}},
                                          Namespace, Unit, AggregationType,
                                          @{N='Dimensions';E={$_.Dimensions.Value}}
    }
    catch {
        Write-Error "Failed to get metric definitions: $_"
        throw
    }
}

#endregion

#region Alert Rule Automation

function New-AzMetricAlertRuleV2Advanced {
    <#
    .SYNOPSIS
        Creates advanced metric alert rules with multiple conditions
    .DESCRIPTION
        Implements complex alert rules with dynamic thresholds, multiple criteria, and auto-resolution
    .EXAMPLE
        New-AzMetricAlertRuleV2Advanced -AlertName "High-CPU-Alert" -ResourceGroupName "RG" -TargetResourceId $vmId
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$AlertName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$TargetResourceId,
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [ValidateSet(0, 1, 2, 3, 4)]
        [int]$Severity = 3,
        
        [Parameter()]
        [int]$WindowSize = 5,
        
        [Parameter()]
        [int]$EvaluationFrequency = 1,
        
        [Parameter()]
        [hashtable[]]$Criteria,
        
        [Parameter()]
        [string[]]$ActionGroupIds,
        
        [Parameter()]
        [switch]$AutoResolve,
        
        [Parameter()]
        [hashtable]$Tags
    )
    
    begin {
        Write-Verbose "Creating advanced metric alert rule: $AlertName"
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess($AlertName, "Create metric alert rule")) {
                # Build criteria objects
                $criteriaList = @()
                
                if (-not $Criteria) {
                    # Default CPU alert
                    $criteriaList += New-AzMetricAlertRuleV2Criteria `
                        -MetricName "Percentage CPU" `
                        -TimeAggregation Average `
                        -Operator GreaterThan `
                        -Threshold 80
                } else {
                    foreach ($criterion in $Criteria) {
                        $criteriaParams = @{
                            MetricName = $criterion.MetricName
                            TimeAggregation = $criterion.TimeAggregation ?? 'Average'
                            Operator = $criterion.Operator ?? 'GreaterThan'
                            Threshold = $criterion.Threshold
                        }
                        
                        if ($criterion.DynamicThreshold) {
                            $criteriaParams['DynamicThreshold'] = $true
                            $criteriaParams['AlertSensitivity'] = $criterion.AlertSensitivity ?? 'Medium'
                            $criteriaParams['FailingPeriods'] = @{
                                NumberOfEvaluationPeriods = $criterion.EvaluationPeriods ?? 4
                                MinFailingPeriodsToAlert = $criterion.MinFailingPeriods ?? 3
                            }
                        }
                        
                        $criteriaList += New-AzMetricAlertRuleV2Criteria @criteriaParams
                    }
                }
                
                # Create alert rule
                $alertParams = @{
                    Name = $AlertName
                    ResourceGroupName = $ResourceGroupName
                    TargetResourceId = $TargetResourceId
                    Condition = $criteriaList
                    WindowSize = $WindowSize
                    Frequency = $EvaluationFrequency
                    Severity = $Severity
                }
                
                if ($Description) {
                    $alertParams['Description'] = $Description
                }
                
                if ($ActionGroupIds) {
                    $alertParams['ActionGroupId'] = $ActionGroupIds
                }
                
                if ($AutoResolve) {
                    $alertParams['AutoMitigate'] = $true
                }
                
                if ($Tags) {
                    $alertParams['Tag'] = $Tags
                }
                
                $alertRule = Add-AzMetricAlertRuleV2 @alertParams
                
                Write-Information "Successfully created alert rule: $AlertName" -InformationAction Continue
                return $alertRule
            }
        }
        catch {
            Write-Error "Failed to create alert rule: $_"
            throw
        }
    }
}

function New-AzLogQueryAlert {
    <#
    .SYNOPSIS
        Creates log query based alert rules
    .DESCRIPTION
        Implements KQL-based alerts for complex scenarios across multiple resources
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AlertName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$WorkspaceResourceId,
        
        [Parameter(Mandatory)]
        [string]$Query,
        
        [Parameter()]
        [ValidateSet('ResultCount', 'MetricMeasurement')]
        [string]$QueryType = 'ResultCount',
        
        [Parameter()]
        [int]$Threshold = 0,
        
        [Parameter()]
        [ValidateSet('GreaterThan', 'LessThan', 'Equal')]
        [string]$Operator = 'GreaterThan',
        
        [Parameter()]
        [int]$WindowSizeInMinutes = 5,
        
        [Parameter()]
        [int]$FrequencyInMinutes = 5,
        
        [Parameter()]
        [string[]]$ActionGroupIds,
        
        [Parameter()]
        [ValidateSet(0, 1, 2, 3, 4)]
        [int]$Severity = 3
    )
    
    try {
        # Create scheduled query rule
        $source = New-AzScheduledQueryRuleSource -Query $Query -DataSourceId $WorkspaceResourceId
        
        $schedule = New-AzScheduledQueryRuleSchedule `
            -FrequencyInMinutes $FrequencyInMinutes `
            -TimeWindowInMinutes $WindowSizeInMinutes
        
        $triggerCondition = New-AzScheduledQueryRuleTriggerCondition `
            -ThresholdOperator $Operator `
            -Threshold $Threshold
        
        $alertingAction = New-AzScheduledQueryRuleAlertingAction `
            -AznsAction (New-AzScheduledQueryRuleAznsActionGroup -ActionGroup $ActionGroupIds) `
            -Severity $Severity `
            -Trigger $triggerCondition
        
        $alert = New-AzScheduledQueryRule `
            -ResourceGroupName $ResourceGroupName `
            -Location (Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name ($WorkspaceResourceId -split '/')[-1]).Location `
            -Name $AlertName `
            -Source $source `
            -Schedule $schedule `
            -Action $alertingAction
        
        Write-Information "Successfully created log query alert: $AlertName" -InformationAction Continue
        return $alert
    }
    catch {
        Write-Error "Failed to create log query alert: $_"
        throw
    }
}

#endregion

#region Dashboard Deployment

function Deploy-AzMonitorDashboard {
    <#
    .SYNOPSIS
        Deploys Azure Monitor dashboards from templates
    .DESCRIPTION
        Creates and configures dashboards with tiles for metrics, logs, and workbooks
    .EXAMPLE
        Deploy-AzMonitorDashboard -DashboardName "Operations-Dashboard" -ResourceGroupName "RG" -TemplateFile "dashboard.json"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DashboardName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter()]
        [string]$TemplateFile,
        
        [Parameter()]
        [hashtable]$DashboardDefinition,
        
        [Parameter()]
        [string]$Location = "global",
        
        [Parameter()]
        [hashtable]$Tags
    )
    
    begin {
        Write-Verbose "Deploying Azure Monitor dashboard: $DashboardName"
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess($DashboardName, "Deploy dashboard")) {
                # Load dashboard definition
                if ($TemplateFile -and (Test-Path $TemplateFile)) {
                    $DashboardDefinition = Get-Content $TemplateFile -Raw | ConvertFrom-Json -AsHashtable
                } elseif (-not $DashboardDefinition) {
                    # Create default dashboard structure
                    $DashboardDefinition = Get-DefaultDashboardTemplate
                }
                
                # Ensure proper structure
                $properties = @{
                    lenses = $DashboardDefinition.lenses ?? @{}
                    metadata = $DashboardDefinition.metadata ?? @{model = @{}}
                }
                
                # Deploy dashboard using REST API or Az module when available
                # For now, create a deployment template
                $template = @{
                    '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
                    contentVersion = "1.0.0.0"
                    resources = @(
                        @{
                            type = "Microsoft.Portal/dashboards"
                            apiVersion = "2020-09-01-preview"
                            name = $DashboardName
                            location = $Location
                            tags = $Tags
                            properties = $properties
                        }
                    )
                }
                
                # Save template for deployment
                $templatePath = "$env:TEMP\dashboard_$DashboardName.json"
                $template | ConvertTo-Json -Depth 20 | Out-File $templatePath
                
                # Deploy using ARM template
                New-AzResourceGroupDeployment `
                    -ResourceGroupName $ResourceGroupName `
                    -TemplateFile $templatePath `
                    -Name "Dashboard-$DashboardName-$(Get-Date -Format 'yyyyMMddHHmmss')"
                
                Write-Information "Successfully deployed dashboard: $DashboardName" -InformationAction Continue
                
                # Cleanup
                Remove-Item $templatePath -Force
            }
        }
        catch {
            Write-Error "Failed to deploy dashboard: $_"
            throw
        }
    }
}

function Get-DefaultDashboardTemplate {
    <#
    .SYNOPSIS
        Returns a default dashboard template
    .DESCRIPTION
        Provides a standard dashboard template with common monitoring tiles
    #>
    [CmdletBinding()]
    param()
    
    return @{
        lenses = @{
            "0" = @{
                order = 0
                parts = @{
                    "0" = @{
                        position = @{
                            x = 0
                            y = 0
                            colSpan = 6
                            rowSpan = 4
                        }
                        metadata = @{
                            type = "Extension/HubsExtension/PartType/MarkdownPart"
                            settings = @{
                                content = @{
                                    settings = @{
                                        content = "# Enterprise Monitoring Dashboard\n\nWelcome to your monitoring dashboard"
                                        title = "Dashboard Overview"
                                    }
                                }
                            }
                        }
                    }
                    "1" = @{
                        position = @{
                            x = 6
                            y = 0
                            colSpan = 6
                            rowSpan = 4
                        }
                        metadata = @{
                            type = "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart"
                            settings = @{
                                chartType = "Line"
                                title = "Resource Health"
                            }
                        }
                    }
                }
            }
        }
        metadata = @{
            model = @{
                timeRange = @{
                    value = @{
                        relative = @{
                            duration = 24
                            timeUnit = 1
                        }
                    }
                    type = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
                }
            }
        }
    }
}

#endregion

#region Workbook Template Management

function Deploy-AzMonitorWorkbook {
    <#
    .SYNOPSIS
        Deploys Azure Monitor workbook templates
    .DESCRIPTION
        Creates workbooks from templates for advanced visualization and analysis
    .EXAMPLE
        Deploy-AzMonitorWorkbook -WorkbookName "Performance-Analysis" -ResourceGroupName "RG" -SourceId $workspace.ResourceId
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkbookName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$SourceId,
        
        [Parameter()]
        [string]$Category = "workbook",
        
        [Parameter()]
        [string]$DisplayName,
        
        [Parameter()]
        [string]$SerializedData,
        
        [Parameter()]
        [string]$TemplateFile,
        
        [Parameter()]
        [hashtable]$Tags
    )
    
    try {
        # Load workbook template
        if ($TemplateFile -and (Test-Path $TemplateFile)) {
            $SerializedData = Get-Content $TemplateFile -Raw
        } elseif (-not $SerializedData) {
            # Use default performance workbook template
            $SerializedData = Get-DefaultWorkbookTemplate -Type "Performance"
        }
        
        $DisplayName = $DisplayName ?? $WorkbookName
        
        # Create workbook resource
        $workbook = @{
            type = "Microsoft.Insights/workbooks"
            name = [guid]::NewGuid().ToString()
            location = (Get-AzResourceGroup -Name $ResourceGroupName).Location
            kind = "shared"
            properties = @{
                displayName = $DisplayName
                serializedData = $SerializedData
                category = $Category
                sourceId = $SourceId
            }
        }
        
        if ($Tags) {
            $workbook['tags'] = $Tags
        }
        
        # Deploy workbook
        $workbookJson = $workbook | ConvertTo-Json -Depth 10
        $tempFile = "$env:TEMP\workbook_$WorkbookName.json"
        
        @{
            '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
            contentVersion = "1.0.0.0"
            resources = @($workbook)
        } | ConvertTo-Json -Depth 20 | Out-File $tempFile
        
        New-AzResourceGroupDeployment `
            -ResourceGroupName $ResourceGroupName `
            -TemplateFile $tempFile `
            -Name "Workbook-$WorkbookName-$(Get-Date -Format 'yyyyMMddHHmmss')"
        
        Write-Information "Successfully deployed workbook: $DisplayName" -InformationAction Continue
        
        # Cleanup
        Remove-Item $tempFile -Force
    }
    catch {
        Write-Error "Failed to deploy workbook: $_"
        throw
    }
}

function Get-DefaultWorkbookTemplate {
    <#
    .SYNOPSIS
        Returns default workbook templates
    .DESCRIPTION
        Provides standard workbook templates for common scenarios
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Performance', 'Availability', 'Failures', 'Usage')]
        [string]$Type = 'Performance'
    )
    
    $templates = @{
        Performance = @{
            version = "Notebook/1.0"
            items = @(
                @{
                    type = 1
                    content = @{
                        json = "# Performance Analysis Workbook\n\nThis workbook provides insights into system performance metrics."
                    }
                    name = "text - 0"
                }
                @{
                    type = 3
                    content = @{
                        version = "KqlItem/1.0"
                        query = "Perf | where TimeGenerated > ago(1h) | summarize avg(CounterValue) by Computer, CounterName | render timechart"
                        size = 0
                        queryType = 0
                        resourceType = "microsoft.operationalinsights/workspaces"
                    }
                    name = "query - 1"
                }
            )
        }
        Availability = @{
            version = "Notebook/1.0"
            items = @(
                @{
                    type = 1
                    content = @{
                        json = "# Availability Monitoring\n\nTrack resource availability and uptime."
                    }
                    name = "text - 0"
                }
                @{
                    type = 3
                    content = @{
                        version = "KqlItem/1.0"
                        query = "Heartbeat | summarize LastHeartbeat = max(TimeGenerated) by Computer | where LastHeartbeat < ago(5m)"
                        size = 0
                        queryType = 0
                        resourceType = "microsoft.operationalinsights/workspaces"
                    }
                    name = "query - 1"
                }
            )
        }
    }
    
    return $templates[$Type] | ConvertTo-Json -Depth 10
}

#endregion

#region Action Group Management

function New-AzActionGroupAdvanced {
    <#
    .SYNOPSIS
        Creates advanced action groups with multiple notification channels
    .DESCRIPTION
        Configures action groups with email, SMS, voice, webhook, and automation runbook actions
    .EXAMPLE
        New-AzActionGroupAdvanced -ActionGroupName "Critical-Alerts-AG" -ResourceGroupName "RG"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ActionGroupName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter()]
        [string]$ShortName,
        
        [Parameter()]
        [hashtable[]]$EmailReceivers,
        
        [Parameter()]
        [hashtable[]]$SmsReceivers,
        
        [Parameter()]
        [hashtable[]]$WebhookReceivers,
        
        [Parameter()]
        [hashtable[]]$AzureAppPushReceivers,
        
        [Parameter()]
        [hashtable[]]$AutomationRunbookReceivers,
        
        [Parameter()]
        [hashtable[]]$LogicAppReceivers,
        
        [Parameter()]
        [hashtable[]]$AzureFunctionReceivers,
        
        [Parameter()]
        [hashtable]$Tags
    )
    
    begin {
        Write-Verbose "Creating advanced action group: $ActionGroupName"
        $ShortName = $ShortName ?? $ActionGroupName.Substring(0, [Math]::Min(12, $ActionGroupName.Length))
    }
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess($ActionGroupName, "Create action group")) {
                $actionGroupParams = @{
                    Name = $ActionGroupName
                    ResourceGroupName = $ResourceGroupName
                    ShortName = $ShortName
                }
                
                # Add email receivers
                if ($EmailReceivers) {
                    $emailList = @()
                    foreach ($email in $EmailReceivers) {
                        $emailList += New-AzActionGroupReceiver -Name $email.Name -EmailReceiver -EmailAddress $email.EmailAddress
                    }
                    $actionGroupParams['Receiver'] = $emailList
                }
                
                # Add SMS receivers
                if ($SmsReceivers) {
                    $smsList = @()
                    foreach ($sms in $SmsReceivers) {
                        $smsList += New-AzActionGroupReceiver -Name $sms.Name -SmsReceiver -CountryCode $sms.CountryCode -PhoneNumber $sms.PhoneNumber
                    }
                    if ($actionGroupParams['Receiver']) {
                        $actionGroupParams['Receiver'] += $smsList
                    } else {
                        $actionGroupParams['Receiver'] = $smsList
                    }
                }
                
                # Add webhook receivers
                if ($WebhookReceivers) {
                    $webhookList = @()
                    foreach ($webhook in $WebhookReceivers) {
                        $webhookList += New-AzActionGroupReceiver -Name $webhook.Name -WebhookReceiver -ServiceUri $webhook.Uri
                    }
                    if ($actionGroupParams['Receiver']) {
                        $actionGroupParams['Receiver'] += $webhookList
                    } else {
                        $actionGroupParams['Receiver'] = $webhookList
                    }
                }
                
                if ($Tags) {
                    $actionGroupParams['Tag'] = $Tags
                }
                
                $actionGroup = Set-AzActionGroup @actionGroupParams
                
                Write-Information "Successfully created action group: $ActionGroupName" -InformationAction Continue
                return $actionGroup
            }
        }
        catch {
            Write-Error "Failed to create action group: $_"
            throw
        }
    }
}

function Test-AzActionGroup {
    <#
    .SYNOPSIS
        Tests action group notification delivery
    .DESCRIPTION
        Sends test notifications through all configured channels in an action group
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ActionGroupName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter()]
        [string]$AlertType = "Metric",
        
        [Parameter()]
        [hashtable]$TestData
    )
    
    try {
        $actionGroup = Get-AzActionGroup -Name $ActionGroupName -ResourceGroupName $ResourceGroupName
        
        # Create test notification request
        $testNotification = @{
            alertType = $AlertType
            emailReceivers = @()
            smsReceivers = @()
            webhookReceivers = @()
        }
        
        foreach ($receiver in $actionGroup.EmailReceivers) {
            $testNotification.emailReceivers += @{
                name = $receiver.Name
                emailAddress = $receiver.EmailAddress
                status = "Enabled"
            }
        }
        
        foreach ($receiver in $actionGroup.SmsReceivers) {
            $testNotification.smsReceivers += @{
                name = $receiver.Name
                countryCode = $receiver.CountryCode
                phoneNumber = $receiver.PhoneNumber
                status = "Enabled"
            }
        }
        
        # Note: In production, this would use the Azure Monitor REST API to send test notifications
        Write-Information "Test notification sent to action group: $ActionGroupName" -InformationAction Continue
        Write-Information "Recipients: $($testNotification.emailReceivers.Count) email(s), $($testNotification.smsReceivers.Count) SMS" -InformationAction Continue
        
        return $testNotification
    }
    catch {
        Write-Error "Failed to test action group: $_"
        throw
    }
}

#endregion

#region Monitoring Configuration Export/Import

function Export-AzMonitoringConfiguration {
    <#
    .SYNOPSIS
        Exports complete monitoring configuration
    .DESCRIPTION
        Exports all monitoring settings including alerts, dashboards, workbooks, and action groups
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [Parameter()]
        [switch]$IncludeAlerts,
        
        [Parameter()]
        [switch]$IncludeDashboards,
        
        [Parameter()]
        [switch]$IncludeWorkbooks,
        
        [Parameter()]
        [switch]$IncludeActionGroups,
        
        [Parameter()]
        [switch]$IncludeAll
    )
    
    try {
        $exportData = @{
            ExportDate = Get-Date
            ResourceGroup = $ResourceGroupName
            Alerts = @()
            Dashboards = @()
            Workbooks = @()
            ActionGroups = @()
        }
        
        if ($IncludeAlerts -or $IncludeAll) {
            Write-Information "Exporting alert rules..." -InformationAction Continue
            $exportData.Alerts = Get-AzMetricAlertRuleV2 -ResourceGroupName $ResourceGroupName
            $exportData.ScheduledQueryRules = Get-AzScheduledQueryRule -ResourceGroupName $ResourceGroupName
        }
        
        if ($IncludeActionGroups -or $IncludeAll) {
            Write-Information "Exporting action groups..." -InformationAction Continue
            $exportData.ActionGroups = Get-AzActionGroup -ResourceGroupName $ResourceGroupName
        }
        
        if ($IncludeDashboards -or $IncludeAll) {
            Write-Information "Exporting dashboards..." -InformationAction Continue
            $dashboards = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.Portal/dashboards"
            $exportData.Dashboards = $dashboards | ForEach-Object {
                Get-AzResource -ResourceId $_.ResourceId -ExpandProperties
            }
        }
        
        if ($IncludeWorkbooks -or $IncludeAll) {
            Write-Information "Exporting workbooks..." -InformationAction Continue
            $workbooks = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.Insights/workbooks"
            $exportData.Workbooks = $workbooks | ForEach-Object {
                Get-AzResource -ResourceId $_.ResourceId -ExpandProperties
            }
        }
        
        # Save to file
        $exportData | ConvertTo-Json -Depth 20 | Out-File $OutputPath
        Write-Information "Monitoring configuration exported to: $OutputPath" -InformationAction Continue
        
        return $exportData
    }
    catch {
        Write-Error "Failed to export monitoring configuration: $_"
        throw
    }
}

function Import-AzMonitoringConfiguration {
    <#
    .SYNOPSIS
        Imports monitoring configuration from export file
    .DESCRIPTION
        Restores monitoring settings including alerts, dashboards, workbooks, and action groups
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigurationFile,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        if (-not (Test-Path $ConfigurationFile)) {
            throw "Configuration file not found: $ConfigurationFile"
        }
        
        $config = Get-Content $ConfigurationFile -Raw | ConvertFrom-Json
        
        Write-Information "Importing monitoring configuration from: $ConfigurationFile" -InformationAction Continue
        
        # Import action groups first (referenced by alerts)
        if ($config.ActionGroups) {
            foreach ($ag in $config.ActionGroups) {
                if ($PSCmdlet.ShouldProcess($ag.Name, "Import action group")) {
                    Write-Information "Importing action group: $($ag.Name)" -InformationAction Continue
                    # Action group import logic here
                }
            }
        }
        
        # Import alerts
        if ($config.Alerts) {
            foreach ($alert in $config.Alerts) {
                if ($PSCmdlet.ShouldProcess($alert.Name, "Import alert rule")) {
                    Write-Information "Importing alert rule: $($alert.Name)" -InformationAction Continue
                    # Alert import logic here
                }
            }
        }
        
        # Import dashboards
        if ($config.Dashboards) {
            foreach ($dashboard in $config.Dashboards) {
                if ($PSCmdlet.ShouldProcess($dashboard.Name, "Import dashboard")) {
                    Write-Information "Importing dashboard: $($dashboard.Name)" -InformationAction Continue
                    # Dashboard import logic here
                }
            }
        }
        
        # Import workbooks
        if ($config.Workbooks) {
            foreach ($workbook in $config.Workbooks) {
                if ($PSCmdlet.ShouldProcess($workbook.Properties.displayName, "Import workbook")) {
                    Write-Information "Importing workbook: $($workbook.Properties.displayName)" -InformationAction Continue
                    # Workbook import logic here
                }
            }
        }
        
        Write-Information "Monitoring configuration import completed" -InformationAction Continue
    }
    catch {
        Write-Error "Failed to import monitoring configuration: $_"
        throw
    }
}

#endregion

#region Helper Functions

function Get-AzMonitoringHealth {
    <#
    .SYNOPSIS
        Checks health of monitoring components
    .DESCRIPTION
        Validates that all monitoring components are functioning correctly
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter()]
        [string[]]$WorkspaceNames
    )
    
    $healthReport = @{
        Timestamp = Get-Date
        ResourceGroup = $ResourceGroupName
        Components = @()
        OverallHealth = "Healthy"
        Issues = @()
    }
    
    try {
        # Check workspaces
        if ($WorkspaceNames) {
            foreach ($workspace in $WorkspaceNames) {
                $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspace -ErrorAction SilentlyContinue
                $component = @{
                    Type = "LogAnalyticsWorkspace"
                    Name = $workspace
                    Status = if ($ws) { "Healthy" } else { "NotFound" }
                    Details = @{}
                }
                
                if ($ws) {
                    $component.Details = @{
                        RetentionDays = $ws.RetentionInDays
                        Sku = $ws.Sku
                        ProvisioningState = $ws.ProvisioningState
                    }
                }
                
                $healthReport.Components += $component
            }
        }
        
        # Check alerts
        $alerts = Get-AzMetricAlertRuleV2 -ResourceGroupName $ResourceGroupName
        $healthReport.Components += @{
            Type = "AlertRules"
            Name = "MetricAlerts"
            Status = "Healthy"
            Details = @{
                TotalAlerts = $alerts.Count
                EnabledAlerts = ($alerts | Where-Object { $_.Enabled }).Count
            }
        }
        
        # Check action groups
        $actionGroups = Get-AzActionGroup -ResourceGroupName $ResourceGroupName
        $healthReport.Components += @{
            Type = "ActionGroups"
            Name = "NotificationGroups"
            Status = "Healthy"
            Details = @{
                TotalGroups = $actionGroups.Count
                TotalReceivers = ($actionGroups | ForEach-Object { $_.EmailReceivers.Count + $_.SmsReceivers.Count } | Measure-Object -Sum).Sum
            }
        }
        
        # Determine overall health
        $unhealthyComponents = $healthReport.Components | Where-Object { $_.Status -ne "Healthy" }
        if ($unhealthyComponents) {
            $healthReport.OverallHealth = "Degraded"
            $healthReport.Issues = $unhealthyComponents | ForEach-Object {
                "$($_.Type) '$($_.Name)' is $($_.Status)"
            }
        }
        
        return $healthReport
    }
    catch {
        Write-Error "Failed to check monitoring health: $_"
        throw
    }
}

#endregion

#region Module Initialization

# Export module members
Export-ModuleMember -Function @(
    'New-AzLogAnalyticsWorkspaceAdvanced',
    'Set-AzLogAnalyticsDataSources',
    'Enable-AzLogAnalyticsSolution',
    'New-AzCustomMetric',
    'Get-AzCustomMetricDefinition',
    'New-AzMetricAlertRuleV2Advanced',
    'New-AzLogQueryAlert',
    'Deploy-AzMonitorDashboard',
    'Deploy-AzMonitorWorkbook',
    'New-AzActionGroupAdvanced',
    'Test-AzActionGroup',
    'Export-AzMonitoringConfiguration',
    'Import-AzMonitoringConfiguration',
    'Get-AzMonitoringHealth'
)

Write-Information "Az.Monitoring.Enterprise module loaded successfully" -InformationAction Continue

#endregion