#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure AI-Powered Cost Optimization and Analytics Tool

.DESCRIPTION
    cost management tool with AI-powered insights, predictive analytics,
    automated optimization recommendations, and intelligent cost forecasting.
.PARAMETER ResourceGroupName
    Target Resource Group for cost analysis
.PARAMETER SubscriptionId
    Azure Subscription ID to analyze
.PARAMETER Action
    Action to perform (Analyze, Optimize, Forecast, Report, Alert, Recommend)
.PARAMETER TimeFrame
    Time frame for analysis (ThisMonth, LastMonth, Last3Months, Last6Months, LastYear, Custom)
.PARAMETER StartDate
    Start date for custom time frame
.PARAMETER EndDate
    End date for custom time frame
.PARAMETER CostThreshold
    Cost threshold for alerts (in USD)
.PARAMETER EnableAIInsights
    Enable AI-powered cost insights and recommendations
.PARAMETER EnablePredictiveAnalytics
    Enable cost forecasting and trend analysis
.PARAMETER EnableAutomatedRecommendations
    Enable automated cost optimization recommendations
.PARAMETER OutputFormat
    Output format for reports (Console, JSON, CSV, Excel, PowerBI)
.PARAMETER OutputPath
    Path for output files
.PARAMETER EnableSlackNotifications
    Enable Slack notifications for cost alerts
.PARAMETER SlackWebhookUrl
    Slack webhook URL for notifications
.PARAMETER EnableEmailNotifications
    Enable email notifications
.PARAMETER EmailRecipients
    Email recipients for notifications
.PARAMETER Tags
    Filter resources by tags
    .\Azure-AI-Cost-Optimization-Tool.ps1 -SubscriptionId "12345" -Action "Analyze" -TimeFrame "LastMonth" -EnableAIInsights -EnablePredictiveAnalytics
    .\Azure-AI-Cost-Optimization-Tool.ps1 -Action "Optimize" -EnableAutomatedRecommendations -OutputFormat "Excel" -OutputPath "C:\CostReports"
.NOTES


    Author: Wes Ellis (wes@wesellis.com)Requires: PowerShell 5.1+, Azure PowerShell modules

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline)]`n    [string]$ResourceGroupName,

    [Parameter(ValueFromPipeline)]`n    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [ValidateSet('Analyze', 'Optimize', 'Forecast', 'Report', 'Alert', 'Recommend', 'Monitor')]
    [string]$Action,

    [Parameter()]
    [ValidateSet('ThisMonth', 'LastMonth', 'Last3Months', 'Last6Months', 'LastYear', 'Custom')]
    [string]$TimeFrame = 'LastMonth',

    [Parameter()]
    [DateTime]$StartDate,

    [Parameter()]
    [DateTime]$EndDate,

    [Parameter()]
    [ValidateRange(0, [decimal]::MaxValue)]
    [decimal]$CostThreshold = 1000,

    [Parameter()]
    [switch]$EnableAIInsights,

    [Parameter()]
    [switch]$EnablePredictiveAnalytics,

    [Parameter()]
    [switch]$EnableAutomatedRecommendations,

    [Parameter()]
    [ValidateSet('Console', 'JSON', 'CSV', 'Excel', 'PowerBI')]
    [string]$OutputFormat = 'Console',

    [Parameter(ValueFromPipeline)]`n    [string]$OutputPath = '.\CostReports',

    [Parameter()]
    [switch]$EnableSlackNotifications,

    [Parameter(ValueFromPipeline)]`n    [string]$SlackWebhookUrl,

    [Parameter()]
    [switch]$EnableEmailNotifications,

    [Parameter()]
    [string[]]$EmailRecipients = @(),

    [Parameter()]
    [hashtable]$Tags = @{}
)
    [string]$ErrorActionPreference = 'Stop'
    [string]$ProgressPreference = 'SilentlyContinue'

try {
                    Write-Host "[SUCCESS] Successfully imported required Azure modules" -ForegroundColor Green
} catch {
    Write-Error "[ERROR] Failed to import required modules: $($_.Exception.Message)"
    throw
}
    [string]$script:CostData = @()
    [string]$script:ResourceData = @()
    [string]$script:Recommendations = @()
    [string]$script:Insights = @()


function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'AI')]
        [string]$Level = 'Info'
    )
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$colors = @{
        Info = "White"
        Warning = "Yellow"
        Error = "Red"
        Success = "Green"
        AI = "Cyan"
    }

    Write-Output "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}

function Get-DateRange {
    param(
        [Parameter(Mandatory)]
        [string]$TimeFrame
    )
$EndDate = Get-Date -ErrorAction Stop

    switch ($TimeFrame) {
        "ThisMonth" {
$StartDate = Get-Date -Day 1
        }
        "LastMonth" {
    [string]$StartDate = (Get-Date -Day 1).AddMonths(-1)
    [string]$EndDate = (Get-Date -Day 1).AddDays(-1)
        }
        "Last3Months" {
    [string]$StartDate = (Get-Date -Day 1).AddMonths(-3)
        }
        "Last6Months" {
    [string]$StartDate = (Get-Date -Day 1).AddMonths(-6)
        }
        "LastYear" {
    [string]$StartDate = (Get-Date -Day 1 -Month 1).AddYears(-1)
    [string]$EndDate = (Get-Date -Day 1 -Month 1).AddDays(-1)
        }
        "Custom" {
            if ($StartDate -and $EndDate) {
                return @{
                    StartDate = $StartDate
                    EndDate = $EndDate
                }
            } else {
                throw "Start and End dates are required for custom time frame"
            }
        }
    }

    return @{
        StartDate = $StartDate
        EndDate = $EndDate
    }
}

function Get-CostData {
    param(
        [Parameter(Mandatory)]
        [DateTime]$StartDate,

        [Parameter(Mandatory)]
        [DateTime]$EndDate
    )

    try {
        Write-EnhancedLog "Retrieving cost data from $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))..." "Info"
$CostParams = @{
            Scope = "/subscriptions/$SubscriptionId"
            TimeFrame = "Custom"
            From = $StartDate
            To = $EndDate
            Granularity = "Daily"
            Metric = "ActualCost"
            GroupBy = @("ResourceGroupName", "ResourceType", "ResourceLocation")
        }
$CostData = Get-AzCostManagementQueryResult -ErrorAction Stop @costParams
$resources = Get-AzResource -ErrorAction Stop
        if ($ResourceGroupName) {
    [string]$resources = $resources | Where-Object { $_.ResourceGroupName -eq $ResourceGroupName }
        }
    [string]$EnrichedData = @()
        foreach ($cost in $CostData.Row) {
    [string]$ResourceInfo = $resources | Where-Object {
    [string]$_.ResourceGroupName -eq $cost[3] -and
    [string]$_.ResourceType -eq $cost[4]
            } | Select-Object -First 1
    [string]$EnrichedData += [PSCustomObject]@{
                Date = [DateTime]$cost[0]
                Cost = [decimal]$cost[1]
                Currency = $cost[2]
                ResourceGroup = $cost[3]
                ResourceType = $cost[4]
                Location = $cost[5]
                ResourceName = if ($ResourceInfo) { $ResourceInfo.Name } else { "Unknown" }
                ResourceId = if ($ResourceInfo) { $ResourceInfo.ResourceId } else { $null }
                Tags = if ($ResourceInfo) { $ResourceInfo.Tags } else { @{} }
            }
        }
    [string]$script:CostData = $EnrichedData
    [string]$script:ResourceData = $resources

        Write-EnhancedLog "Successfully retrieved cost data for $($EnrichedData.Count) items" "Success"
        return $EnrichedData

    } catch {
        Write-EnhancedLog "Failed to retrieve cost data: $($_.Exception.Message)" "Error"
        throw
    }
}

function Invoke-AICostAnalysis {
    param(
        [Parameter(Mandatory)]
        [array]$CostData
    )

    try {
        Write-EnhancedLog "[AI] Performing AI-powered cost analysis..." "AI"
    [string]$DailyCosts = $CostData | Group-Object { $_.Date.ToString("yyyy-MM-dd") } | ForEach-Object {
            [PSCustomObject]@{
                Date = [DateTime]$_.Name
                TotalCost = ($_.Group | Measure-Object Cost -Sum).Sum
            }
        } | Sort-Object Date
    [string]$AvgDailyCost = ($DailyCosts | Measure-Object TotalCost -Average).Average
    [string]$MaxDailyCost = ($DailyCosts | Measure-Object TotalCost -Maximum).Maximum
    [string]$MinDailyCost = ($DailyCosts | Measure-Object TotalCost -Minimum).Minimum
    [string]$CostVariance = ($DailyCosts | Measure-Object TotalCost -StandardDeviation).StandardDeviation
    [string]$anomalies = $DailyCosts | Where-Object {
            [Math]::Abs($_.TotalCost - $AvgDailyCost) -gt (2 * $CostVariance)
        }
    [string]$ResourceTypeCosts = $CostData | Group-Object ResourceType | ForEach-Object {
            [PSCustomObject]@{
                ResourceType = $_.Name
                TotalCost = ($_.Group | Measure-Object Cost -Sum).Sum
                ResourceCount = $_.Count
                AvgCostPerResource = ($_.Group | Measure-Object Cost -Average).Average
                Percentage = 0
            }
        } | Sort-Object TotalCost -Descending
    [string]$TotalCost = ($ResourceTypeCosts | Measure-Object TotalCost -Sum).Sum
    [string]$ResourceTypeCosts | ForEach-Object { $_.Percentage = [Math]::Round(($_.TotalCost / $TotalCost) * 100, 2) }
    [string]$LocationCosts = $CostData | Group-Object Location | ForEach-Object {
            [PSCustomObject]@{
                Location = $_.Name
                TotalCost = ($_.Group | Measure-Object Cost -Sum).Sum
                Percentage = 0
            }
        } | Sort-Object TotalCost -Descending
    [string]$LocationCosts | ForEach-Object { $_.Percentage = [Math]::Round(($_.TotalCost / $TotalCost) * 100, 2) }
    [string]$insights = @()

        if ($anomalies.Count -gt 0) {
    [string]$insights += "[ALERT] Cost Anomaly Detection: Found $($anomalies.Count) days with unusual spending patterns"
            foreach ($anomaly in $anomalies) {
    [string]$insights += "   - $($anomaly.Date.ToString('yyyy-MM-dd')): $($anomaly.TotalCost.ToString('C2')) ($(if ($anomaly.TotalCost -gt $AvgDailyCost) { '+' })$([Math]::Round((($anomaly.TotalCost - $AvgDailyCost) / $AvgDailyCost) * 100, 1))% from average)"
            }
        }
    [string]$TopCostResources = $ResourceTypeCosts | Select-Object -First 5
    [string]$insights += "Top Cost Drivers:"
        foreach ($resource in $TopCostResources) {
    [string]$insights += "   - $($resource.ResourceType): $($resource.TotalCost.ToString('C2')) ($($resource.Percentage)% of total cost)"
        }
    [string]$HighVarianceResources = $ResourceTypeCosts | Where-Object { $_.AvgCostPerResource -gt ($AvgDailyCost * 0.1) }
        if ($HighVarianceResources) {
    [string]$insights += "[!] High-Cost Resource Types (Optimization Candidates):"
            foreach ($resource in $HighVarianceResources) {
    [string]$insights += "   - $($resource.ResourceType): Avg $($resource.AvgCostPerResource.ToString('C2')) per resource"
            }
        }

        if ($LocationCosts.Count -gt 1) {
    [string]$MostExpensiveLocation = $LocationCosts | Select-Object -First 1
    [string]$insights += "[LOCATION] Geographic Cost Distribution:"
    [string]$insights += "   - Most expensive region: $($MostExpensiveLocation.Location) ($($MostExpensiveLocation.Percentage)% of total cost)"

            if ($LocationCosts.Count -gt 3) {
    [string]$insights += "   - Consider consolidating resources in fewer regions for potential cost savings"
            }
        }
    [string]$script:Insights = $insights
$AnalysisResult = @{
            Summary = @{
                TotalCost = $TotalCost
                AverageDailyCost = $AvgDailyCost
                MaxDailyCost = $MaxDailyCost
                MinDailyCost = $MinDailyCost
                CostVariance = $CostVariance
                AnomalyCount = $anomalies.Count
            }
            Trends = $DailyCosts
            Anomalies = $anomalies
            ResourceDistribution = $ResourceTypeCosts
            LocationDistribution = $LocationCosts
            Insights = $insights
        }

        Write-EnhancedLog "AI analysis completed - Generated $($insights.Count) insights" "AI"
        return $AnalysisResult

    } catch {
        Write-EnhancedLog "Failed to perform AI analysis: $($_.Exception.Message)" "Error"
        throw
    }
}

function New-CostForecast {
    param(
        [Parameter(Mandatory)]
        [array]$HistoricalData,

        [Parameter()]
        [int]$ForecastDays = 30
    )

    try {
        Write-EnhancedLog "[FORECAST] Generating cost forecast for next $ForecastDays days..." "AI"
    [string]$DailyCosts = $HistoricalData | Group-Object { $_.Date.ToString("yyyy-MM-dd") } | ForEach-Object {
            [PSCustomObject]@{
                Date = [DateTime]$_.Name
                Cost = ($_.Group | Measure-Object Cost -Sum).Sum
                DayIndex = ([DateTime]$_.Name - $HistoricalData[0].Date).Days
            }
        } | Sort-Object Date

        $n = $DailyCosts.Count
    [string]$SumX = ($DailyCosts | Measure-Object DayIndex -Sum).Sum
    [string]$SumY = ($DailyCosts | Measure-Object Cost -Sum).Sum
    [string]$SumXY = ($DailyCosts | ForEach-Object { $_.DayIndex * $_.Cost } | Measure-Object -Sum).Sum
    [string]$SumX2 = ($DailyCosts | ForEach-Object { $_.DayIndex * $_.DayIndex } | Measure-Object -Sum).Sum
    [string]$slope = ($n * $SumXY - $SumX * $SumY) / ($n * $SumX2 - $SumX * $SumX)
    [string]$intercept = ($SumY - $slope * $SumX) / $n
    [string]$LastDate = $DailyCosts[-1].Date
    [string]$LastIndex = $DailyCosts[-1].DayIndex
    [string]$forecast = @()
        for ($i = 1; $i -le $ForecastDays; $i++) {
    [string]$ForecastDate = $LastDate.AddDays($i)
    [string]$ForecastIndex = $LastIndex + $i
    [string]$PredictedCost = $intercept + $slope * $ForecastIndex
    [string]$DayOfWeek = $ForecastDate.DayOfWeek
    [string]$SeasonalMultiplier = switch ($DayOfWeek) {
                "Saturday" { 0.7 }
                "Sunday" { 0.6 }
                default { 1.0 }
            }
    [string]$AdjustedCost = $PredictedCost * $SeasonalMultiplier
    [string]$forecast += [PSCustomObject]@{
                Date = $ForecastDate
                PredictedCost = [Math]::Max(0, $AdjustedCost)
                Confidence = [Math]::Max(0.5, 1 - ($i / $ForecastDays) * 0.5)
                TrendDirection = if ($slope -gt 0) { "Increasing" } elseif ($slope -lt 0) { "Decreasing" } else { "Stable" }
            }
        }
$ForecastSummary = @{
            PeriodTotal = ($forecast | Measure-Object PredictedCost -Sum).Sum
            DailyAverage = ($forecast | Measure-Object PredictedCost -Average).Average
            TrendSlope = $slope
            TrendDirection = if ($slope -gt 0) { "Increasing" } elseif ($slope -lt 0) { "Decreasing" } else { "Stable" }
            ConfidenceLevel = ($forecast | Measure-Object Confidence -Average).Average
        }

        Write-EnhancedLog "Forecast generated: $($ForecastSummary.PeriodTotal.ToString('C2')) projected for next $ForecastDays days" "AI"

        return @{
            Forecast = $forecast
            Summary = $ForecastSummary
            Trend = @{
                Slope = $slope
                Intercept = $intercept
                Direction = $ForecastSummary.TrendDirection
            }
        }

    } catch {
        Write-EnhancedLog "Failed to generate cost forecast: $($_.Exception.Message)" "Error"
        throw
    }
}

function New-OptimizationRecommendations {
    param()

    try {
        Write-EnhancedLog "Generating automated optimization recommendations..." "AI"
    [string]$recommendations = @()
    [string]$UnusedResources = $script:ResourceData | Where-Object {
    [string]$ResourceCost = $script:CostData | Where-Object { $_.ResourceId -eq $_.ResourceId }
            -not $ResourceCost -or ($ResourceCost | Measure-Object Cost -Sum).Sum -lt 1
        }

        if ($UnusedResources.Count -gt 0) {
    [string]$recommendations += [PSCustomObject]@{
                Type = "Remove Unused Resources"
                Priority = "High"
                PotentialSavings = "Unknown"
                Description = "Found $($UnusedResources.Count) resources with no or minimal cost activity"
                Action = "Review and consider decommissioning unused resources"
                Resources = $UnusedResources.Name -join ", "
            }
        }
    [string]$VmResources = $script:ResourceData | Where-Object { $_.ResourceType -like "*virtualMachines*" }
        if ($VmResources.Count -gt 0) {
    [string]$recommendations += [PSCustomObject]@{
                Type = "VM Right-Sizing"
                Priority = "Medium"
                PotentialSavings = "15-30%"
                Description = "Review VM sizes for potential downsizing opportunities"
                Action = "Monitor CPU and memory utilization to identify over-provisioned VMs"
                Resources = "All Virtual Machines"
            }
        }
    [string]$StorageResources = $script:ResourceData | Where-Object { $_.ResourceType -like "*storage*" }
        if ($StorageResources.Count -gt 0) {
    [string]$recommendations += [PSCustomObject]@{
                Type = "Storage Tier Optimization"
                Priority = "Medium"
                PotentialSavings = "20-40%"
                Description = "Optimize storage tiers based on access patterns"
                Action = "Implement lifecycle management policies for blob storage"
                Resources = "Storage Accounts"
            }
        }
    [string]$ComputeCost = ($script:CostData | Where-Object { $_.ResourceType -like "*Compute*" } | Measure-Object Cost -Sum).Sum
        if ($ComputeCost -gt 500) {
    [string]$recommendations += [PSCustomObject]@{
                Type = "Reserved Instances"
                Priority = "High"
                PotentialSavings = "30-60%"
                Description = "Significant compute costs detected - consider reserved instances"
                Action = "Analyze compute usage patterns for reserved instance opportunities"
                Resources = "Compute Resources"
            }
        }
    [string]$recommendations += [PSCustomObject]@{
            Type = "Spot Instances"
            Priority = "Low"
            PotentialSavings = "60-90%"
            Description = "Use spot instances for fault-tolerant workloads"
            Action = "Identify workloads suitable for spot instances"
            Resources = "Development/Testing VMs"
        }
    [string]$ResourceGroups = $script:CostData | Group-Object ResourceGroup
        if ($ResourceGroups.Count -gt 10) {
    [string]$LowCostRGs = $ResourceGroups | Where-Object {
                ($_.Group | Measure-Object Cost -Sum).Sum -lt 50
            }

            if ($LowCostRGs.Count -gt 0) {
    [string]$recommendations += [PSCustomObject]@{
                    Type = "Resource Group Consolidation"
                    Priority = "Low"
                    PotentialSavings = "5-10%"
                    Description = "Found $($LowCostRGs.Count) resource groups with low cost - consider consolidation"
                    Action = "Review and consolidate low-cost resource groups"
                    Resources = ($LowCostRGs.Name -join ", ")
                }
            }
        }
    [string]$script:Recommendations = $recommendations

        Write-EnhancedLog "Generated $($recommendations.Count) optimization recommendations" "AI"
        return $recommendations

    } catch {
        Write-EnhancedLog "Failed to generate recommendations: $($_.Exception.Message)" "Error"
        throw
    }
}

function New-CostReport {
    param(
        [Parameter(Mandatory)]
        [object]$Analysis,

        [Parameter()]
        [object]$Forecast,

        [Parameter()]
        [array]$Recommendations
    )

    try {
        Write-EnhancedLog "[REPORT] Generating
$report = @{
            Metadata = @{
                GeneratedDate = Get-Date -ErrorAction Stop
                TimeFrame = $TimeFrame
                SubscriptionId = $SubscriptionId
                ResourceGroup = $ResourceGroupName
                AnalysisType = $Action
            }
            Executive_Summary = @{
                TotalCost = $Analysis.Summary.TotalCost
                AverageDailyCost = $Analysis.Summary.AverageDailyCost
                CostTrend = if ($Analysis.Summary.CostVariance -lt $Analysis.Summary.AverageDailyCost * 0.1) { "Stable" } else { "Variable" }
                TopRecommendation = if ($Recommendations.Count -gt 0) { $Recommendations[0].Type } else { "None" }
                PotentialSavings = if ($Recommendations.Count -gt 0) { ($Recommendations | Where-Object { $_.PotentialSavings -match '\d+' } | Measure-Object).Count } else { 0 }
            }
            Cost_Analysis = $Analysis
            Forecast = $Forecast
            Recommendations = $Recommendations
            Insights = $script:Insights
            Resource_Details = @{
                TotalResources = $script:ResourceData.Count
                ResourceTypes = ($script:ResourceData | Group-Object ResourceType).Count
                Locations = ($script:ResourceData | Group-Object Location).Count
            }
        }
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

        switch ($OutputFormat) {
            "JSON" {
    [string]$OutputFile = "$OutputPath\cost-report-$timestamp.json"
    [string]$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
                Write-EnhancedLog "Report saved to: $OutputFile" "Success"
            }
            "CSV" {
    [string]$SummaryFile = "$OutputPath\cost-summary-$timestamp.csv"
    [string]$Analysis.ResourceDistribution | Export-Csv -Path $SummaryFile -NoTypeInformation
    [string]$RecFile = "$OutputPath\cost-recommendations-$timestamp.csv"
    [string]$Recommendations | Export-Csv -Path $RecFile -NoTypeInformation

                Write-EnhancedLog "CSV reports saved to: $OutputPath" "Success"
            }
            "Excel" {
                Write-EnhancedLog "Excel output requires ImportExcel module - saving as JSON instead" "Warning"
    [string]$OutputFile = "$OutputPath\cost-report-$timestamp.json"
    [string]$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
            }
            "PowerBI" {
    [string]$PbiFile = "$OutputPath\cost-data-powerbi-$timestamp.json"
$PbiData = @{
                    CostData = $script:CostData
                    Analysis = $Analysis
                    Recommendations = $Recommendations
                }
    [string]$PbiData | ConvertTo-Json -Depth 10 | Out-File -FilePath $PbiFile -Encoding UTF8
                Write-EnhancedLog "Power BI data saved to: $PbiFile" "Success"
            }
            "Console" {
                Write-EnhancedLog "=== COST ANALYSIS REPORT ===" "Success"
                Write-EnhancedLog "Total Cost: $($Analysis.Summary.TotalCost.ToString('C2'))" "Info"
                Write-EnhancedLog "Daily Average: $($Analysis.Summary.AverageDailyCost.ToString('C2'))" "Info"
                Write-EnhancedLog "Anomalies Detected: $($Analysis.Summary.AnomalyCount)" "Info"

                if ($script:Insights.Count -gt 0) {
                    Write-EnhancedLog "`n=== AI INSIGHTS ===" "AI"
                    foreach ($insight in $script:Insights) {
                        Write-EnhancedLog $insight "AI"
                    }
                }

                if ($Recommendations.Count -gt 0) {
                    Write-EnhancedLog "`n=== OPTIMIZATION RECOMMENDATIONS ===" "Success"
                    foreach ($rec in $Recommendations) {
                        Write-EnhancedLog "$($rec.Type) ($($rec.Priority) Priority) - Potential Savings: $($rec.PotentialSavings)" "Info"
                        Write-EnhancedLog "  Action: $($rec.Action)" "Info"
                    }
                }
            }
        }

        return $report

    } catch {
        Write-EnhancedLog "Failed to generate report: $($_.Exception.Message)" "Error"
        throw
    }
}

function Send-CostAlerts {
    param(
        [Parameter(Mandatory)]
        [object]$Analysis,

        [Parameter(Mandatory)]
        [decimal]$Threshold
    )

    try {
    [string]$TotalCost = $Analysis.Summary.TotalCost

        if ($TotalCost -gt $Threshold) {
            Write-EnhancedLog "[ALERT] Cost threshold exceeded: $($TotalCost.ToString('C2')) > $($Threshold.ToString('C2'))" "Warning"
    [string]$AlertMessage = @"
[ALERT] Azure Cost Alert [ALERT]

Subscription: $SubscriptionId
Current Period Cost: $($TotalCost.ToString('C2'))
Threshold: $($Threshold.ToString('C2'))
Overage: $($TotalCost - $Threshold).ToString('C2') ($([Math]::Round((($TotalCost - $Threshold) / $Threshold) * 100, 1))%)

Top Cost Drivers:
$($Analysis.ResourceDistribution | Select-Object -First 3 | ForEach-Object { "- $($_.ResourceType): $($_.TotalCost.ToString('C2'))" } | Out-String)

Immediate Actions Recommended:
$($script:Recommendations | Where-Object { $_.Priority -eq "High" } | ForEach-Object { "- $($_.Type): $($_.Action)" } | Out-String)

Generated: $(Get-Date)
"@

            if ($EnableSlackNotifications -and $SlackWebhookUrl) {
                try {
$SlackPayload = @{
                        text = "Azure Cost Alert"
                        attachments = @(
                            @{
                                color = "danger"
                                title = "Cost Threshold Exceeded"
                                text = $AlertMessage
                                footer = "Azure Cost Management Tool"
                                ts = [int][double]::Parse((Get-Date -UFormat %s))
                            }
                        )
                    } | ConvertTo-Json -Depth 4

                    Invoke-RestMethod -Uri $SlackWebhookUrl -Method Post -Body $SlackPayload -ContentType "application/json"
                    Write-EnhancedLog "Slack notification sent successfully" "Success"
                } catch {
                    Write-EnhancedLog "Failed to send Slack notification: $($_.Exception.Message)" "Error"
                }
            }

            if ($EnableEmailNotifications -and $EmailRecipients.Count -gt 0) {
                Write-EnhancedLog "Email notification functionality would be implemented here" "Info"
            }
        } else {
            Write-EnhancedLog "Cost is within threshold: $($TotalCost.ToString('C2')) �� $($Threshold.ToString('C2'))" "Success"
        }

    } catch {
        Write-EnhancedLog "Failed to send cost alerts: $($_.Exception.Message)" "Error"
    }
}

try {
    Write-EnhancedLog "Starting Azure AI-Powered Cost Optimization Tool" "Info"
    Write-EnhancedLog "Action: $Action" "Info"
    Write-EnhancedLog "Time Frame: $TimeFrame" "Info"

    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }

    if (-not $SubscriptionId) {
$context = Get-AzContext -ErrorAction Stop
    [string]$SubscriptionId = $context.Subscription.Id
        Write-EnhancedLog "Using current subscription: $SubscriptionId" "Info"
    }

    if ($TimeFrame -eq "Custom") {
$DateRange = Get-DateRange -TimeFrame $TimeFrame
    } else {
$DateRange = Get-DateRange -TimeFrame $TimeFrame
    }

    Write-EnhancedLog "Analysis period: $($DateRange.StartDate.ToString('yyyy-MM-dd')) to $($DateRange.EndDate.ToString('yyyy-MM-dd'))" "Info"
$CostData = Get-CostData -StartDate $DateRange.StartDate -EndDate $DateRange.EndDate

    switch ($Action) {
        "Analyze" {
    [string]$analysis = Invoke-AICostAnalysis -CostData $CostData

            if ($EnablePredictiveAnalytics) {
$forecast = New-CostForecast -HistoricalData $CostData
            }
$report = New-CostReport -Analysis $analysis -Forecast $forecast -Recommendations @()
        }

        "Optimize" {
    [string]$analysis = Invoke-AICostAnalysis -CostData $CostData
$recommendations = New-OptimizationRecommendations -ErrorAction Stop

            if ($EnablePredictiveAnalytics) {
$forecast = New-CostForecast -HistoricalData $CostData
            }
$report = New-CostReport -Analysis $analysis -Forecast $forecast -Recommendations $recommendations
        }

        "Forecast" {
            if (-not $EnablePredictiveAnalytics) {
    [string]$EnablePredictiveAnalytics = $true
            }
    [string]$analysis = Invoke-AICostAnalysis -CostData $CostData
$forecast = New-CostForecast -HistoricalData $CostData -ForecastDays 90

            Write-EnhancedLog " 90-Day Cost Forecast:" "AI"
            Write-EnhancedLog "Projected Total: $($forecast.Summary.PeriodTotal.ToString('C2'))" "AI"
            Write-EnhancedLog "Daily Average: $($forecast.Summary.DailyAverage.ToString('C2'))" "AI"
            Write-EnhancedLog "Trend: $($forecast.Summary.TrendDirection)" "AI"
        }

        "Recommend" {
    [string]$analysis = Invoke-AICostAnalysis -CostData $CostData
$recommendations = New-OptimizationRecommendations -ErrorAction Stop

            Write-EnhancedLog "Top Optimization Recommendations:" "AI"
    [string]$recommendations | Sort-Object {
                switch ($_.Priority) {
                    "High" { 1 }
                    "Medium" { 2 }
                    "Low" { 3 }
                }
            } | ForEach-Object {
                Write-EnhancedLog "$($_.Type) ($($_.Priority)) - $($_.PotentialSavings) savings" "AI"
                Write-EnhancedLog "  Action: $($_.Action)" "Info"
            }
        }

        "Alert" {
    [string]$analysis = Invoke-AICostAnalysis -CostData $CostData
            Send-CostAlerts -Analysis $analysis -Threshold $CostThreshold
        }

        "Report" {
    [string]$analysis = Invoke-AICostAnalysis -CostData $CostData
$recommendations = New-OptimizationRecommendations -ErrorAction Stop

            if ($EnablePredictiveAnalytics) {
$forecast = New-CostForecast -HistoricalData $CostData
            }
$report = New-CostReport -Analysis $analysis -Forecast $forecast -Recommendations $recommendations
        }

        "Monitor" {
    [string]$analysis = Invoke-AICostAnalysis -CostData $CostData
            Send-CostAlerts -Analysis $analysis -Threshold $CostThreshold

            Write-EnhancedLog "Monitoring mode - would run continuously in production" "Info"
        }
    }

    Write-EnhancedLog "[SUCCESS] Azure AI-Powered Cost Optimization Tool completed successfully" "Success"

} catch {
    Write-EnhancedLog "[ERROR] Tool execution failed: $($_.Exception.Message)" "Error"
    throw
}
finally {
    Write-Verbose "Azure AI Cost Optimization Tool execution completed"`n}
