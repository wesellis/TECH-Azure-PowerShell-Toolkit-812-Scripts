#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.Resources, Az.Billing, Az.CostManagement

<#
.SYNOPSIS
    Azure AI-Powered Cost Optimization and Analytics Tool
.DESCRIPTION
    Advanced cost management tool with AI-powered insights, predictive analytics,
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
.EXAMPLE
    .\Azure-AI-Cost-Optimization-Tool.ps1 -SubscriptionId "12345" -Action "Analyze" -TimeFrame "LastMonth" -EnableAIInsights -EnablePredictiveAnalytics
.EXAMPLE
    .\Azure-AI-Cost-Optimization-Tool.ps1 -Action "Optimize" -EnableAutomatedRecommendations -OutputFormat "Excel" -OutputPath "C:\CostReports"
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Azure PowerShell modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Analyze", "Optimize", "Forecast", "Report", "Alert", "Recommend", "Monitor")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("ThisMonth", "LastMonth", "Last3Months", "Last6Months", "LastYear", "Custom")]
    [string]$TimeFrame = "LastMonth",
    
    [Parameter(Mandatory = $false)]
    [DateTime]$StartDate,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$EndDate,
    
    [Parameter(Mandatory = $false)]
    [decimal]$CostThreshold = 1000,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableAIInsights,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnablePredictiveAnalytics,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableAutomatedRecommendations,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "JSON", "CSV", "Excel", "PowerBI")]
    [string]$OutputFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\CostReports",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableSlackNotifications,
    
    [Parameter(Mandatory = $false)]
    [string]$SlackWebhookUrl,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableEmailNotifications,
    
    [Parameter(Mandatory = $false)]
    [string[]]$EmailRecipients = @(),
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{}
)

# Import required modules
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.Billing -Force -ErrorAction Stop
    Import-Module Az.CostManagement -Force -ErrorAction Stop
    Write-Host "✅ Successfully imported required Azure modules" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to import required modules: $($_.Exception.Message)"
    exit 1
}

# Global variables for cost data
$script:CostData = @()
$script:ResourceData = @()
$script:Recommendations = @()
$script:Insights = @()

# Enhanced logging function
function Write-EnhancedLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success", "AI")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow" 
        Error = "Red"
        Success = "Green"
        AI = "Cyan"
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}

# Calculate date ranges
function Get-DateRange {
    param([string]$TimeFrame)
    
    $endDate = Get-Date
    
    switch ($TimeFrame) {
        "ThisMonth" {
            $startDate = Get-Date -Day 1
        }
        "LastMonth" {
            $startDate = (Get-Date -Day 1).AddMonths(-1)
            $endDate = (Get-Date -Day 1).AddDays(-1)
        }
        "Last3Months" {
            $startDate = (Get-Date -Day 1).AddMonths(-3)
        }
        "Last6Months" {
            $startDate = (Get-Date -Day 1).AddMonths(-6)
        }
        "LastYear" {
            $startDate = (Get-Date -Day 1 -Month 1).AddYears(-1)
            $endDate = (Get-Date -Day 1 -Month 1).AddDays(-1)
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
        StartDate = $startDate
        EndDate = $endDate
    }
}

# Get comprehensive cost data
function Get-CostData {
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )
    
    try {
        Write-EnhancedLog "Retrieving cost data from $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))..." "Info"
        
        # Get subscription level cost data
        $costParams = @{
            Scope = "/subscriptions/$SubscriptionId"
            TimeFrame = "Custom"
            From = $StartDate
            To = $EndDate
            Granularity = "Daily"
            Metric = "ActualCost"
            GroupBy = @("ResourceGroupName", "ResourceType", "ResourceLocation")
        }
        
        $costData = Get-AzCostManagementQueryResult @costParams
        
        # Get resource usage data
        $resources = Get-AzResource
        if ($ResourceGroupName) {
            $resources = $resources | Where-Object { $_.ResourceGroupName -eq $ResourceGroupName }
        }
        
        # Combine cost and resource data
        $enrichedData = @()
        foreach ($cost in $costData.Row) {
            $resourceInfo = $resources | Where-Object { 
                $_.ResourceGroupName -eq $cost[3] -and 
                $_.ResourceType -eq $cost[4] 
            } | Select-Object -First 1
            
            $enrichedData += [PSCustomObject]@{
                Date = [DateTime]$cost[0]
                Cost = [decimal]$cost[1]
                Currency = $cost[2]
                ResourceGroup = $cost[3]
                ResourceType = $cost[4]
                Location = $cost[5]
                ResourceName = if ($resourceInfo) { $resourceInfo.Name } else { "Unknown" }
                ResourceId = if ($resourceInfo) { $resourceInfo.ResourceId } else { $null }
                Tags = if ($resourceInfo) { $resourceInfo.Tags } else { @{} }
            }
        }
        
        $script:CostData = $enrichedData
        $script:ResourceData = $resources
        
        Write-EnhancedLog "Successfully retrieved cost data for $($enrichedData.Count) items" "Success"
        return $enrichedData
        
    } catch {
        Write-EnhancedLog "Failed to retrieve cost data: $($_.Exception.Message)" "Error"
        throw
    }
}

# AI-powered cost analysis
function Invoke-AICostAnalysis {
    param([array]$CostData)
    
    try {
        Write-EnhancedLog "🤖 Performing AI-powered cost analysis..." "AI"
        
        # Cost trend analysis
        $dailyCosts = $CostData | Group-Object { $_.Date.ToString("yyyy-MM-dd") } | ForEach-Object {
            [PSCustomObject]@{
                Date = [DateTime]$_.Name
                TotalCost = ($_.Group | Measure-Object Cost -Sum).Sum
            }
        } | Sort-Object Date
        
        # Calculate trends
        $avgDailyCost = ($dailyCosts | Measure-Object TotalCost -Average).Average
        $maxDailyCost = ($dailyCosts | Measure-Object TotalCost -Maximum).Maximum
        $minDailyCost = ($dailyCosts | Measure-Object TotalCost -Minimum).Minimum
        $costVariance = ($dailyCosts | Measure-Object TotalCost -StandardDeviation).StandardDeviation
        
        # Identify cost anomalies using statistical analysis
        $anomalies = $dailyCosts | Where-Object { 
            [Math]::Abs($_.TotalCost - $avgDailyCost) -gt (2 * $costVariance) 
        }
        
        # Resource cost distribution analysis
        $resourceTypeCosts = $CostData | Group-Object ResourceType | ForEach-Object {
            [PSCustomObject]@{
                ResourceType = $_.Name
                TotalCost = ($_.Group | Measure-Object Cost -Sum).Sum
                ResourceCount = $_.Count
                AvgCostPerResource = ($_.Group | Measure-Object Cost -Average).Average
                Percentage = 0  # Will be calculated below
            }
        } | Sort-Object TotalCost -Descending
        
        $totalCost = ($resourceTypeCosts | Measure-Object TotalCost -Sum).Sum
        $resourceTypeCosts | ForEach-Object { $_.Percentage = [Math]::Round(($_.TotalCost / $totalCost) * 100, 2) }
        
        # Geographic cost distribution
        $locationCosts = $CostData | Group-Object Location | ForEach-Object {
            [PSCustomObject]@{
                Location = $_.Name
                TotalCost = ($_.Group | Measure-Object Cost -Sum).Sum
                Percentage = 0
            }
        } | Sort-Object TotalCost -Descending
        
        $locationCosts | ForEach-Object { $_.Percentage = [Math]::Round(($_.TotalCost / $totalCost) * 100, 2) }
        
        # Generate AI insights
        $insights = @()
        
        # Cost trend insights
        if ($anomalies.Count -gt 0) {
            $insights += "🚨 Cost Anomaly Detection: Found $($anomalies.Count) days with unusual spending patterns"
            foreach ($anomaly in $anomalies) {
                $insights += "   • $($anomaly.Date.ToString('yyyy-MM-dd')): $($anomaly.TotalCost.ToString('C2')) ($(if ($anomaly.TotalCost -gt $avgDailyCost) { '+' })$([Math]::Round((($anomaly.TotalCost - $avgDailyCost) / $avgDailyCost) * 100, 1))% from average)"
            }
        }
        
        # Resource optimization insights
        $topCostResources = $resourceTypeCosts | Select-Object -First 5
        $insights += "💰 Top Cost Drivers:"
        foreach ($resource in $topCostResources) {
            $insights += "   • $($resource.ResourceType): $($resource.TotalCost.ToString('C2')) ($($resource.Percentage)% of total cost)"
        }
        
        # Cost efficiency insights
        $highVarianceResources = $resourceTypeCosts | Where-Object { $_.AvgCostPerResource -gt ($avgDailyCost * 0.1) }
        if ($highVarianceResources) {
            $insights += "⚡ High-Cost Resource Types (Optimization Candidates):"
            foreach ($resource in $highVarianceResources) {
                $insights += "   • $($resource.ResourceType): Avg $($resource.AvgCostPerResource.ToString('C2')) per resource"
            }
        }
        
        # Geographic cost insights
        if ($locationCosts.Count -gt 1) {
            $mostExpensiveLocation = $locationCosts | Select-Object -First 1
            $insights += "🌍 Geographic Cost Distribution:"
            $insights += "   • Most expensive region: $($mostExpensiveLocation.Location) ($($mostExpensiveLocation.Percentage)% of total cost)"
            
            if ($locationCosts.Count -gt 3) {
                $insights += "   • Consider consolidating resources in fewer regions for potential cost savings"
            }
        }
        
        $script:Insights = $insights
        
        $analysisResult = @{
            Summary = @{
                TotalCost = $totalCost
                AverageDailyCost = $avgDailyCost
                MaxDailyCost = $maxDailyCost
                MinDailyCost = $minDailyCost
                CostVariance = $costVariance
                AnomalyCount = $anomalies.Count
            }
            Trends = $dailyCosts
            Anomalies = $anomalies
            ResourceDistribution = $resourceTypeCosts
            LocationDistribution = $locationCosts
            Insights = $insights
        }
        
        Write-EnhancedLog "🎯 AI analysis completed - Generated $($insights.Count) insights" "AI"
        return $analysisResult
        
    } catch {
        Write-EnhancedLog "Failed to perform AI analysis: $($_.Exception.Message)" "Error"
        throw
    }
}

# Generate predictive cost forecasting
function New-CostForecast {
    param(
        [array]$HistoricalData,
        [int]$ForecastDays = 30
    )
    
    try {
        Write-EnhancedLog "🔮 Generating cost forecast for next $ForecastDays days..." "AI"
        
        # Prepare time series data
        $dailyCosts = $HistoricalData | Group-Object { $_.Date.ToString("yyyy-MM-dd") } | ForEach-Object {
            [PSCustomObject]@{
                Date = [DateTime]$_.Name
                Cost = ($_.Group | Measure-Object Cost -Sum).Sum
                DayIndex = ([DateTime]$_.Name - $HistoricalData[0].Date).Days
            }
        } | Sort-Object Date
        
        # Simple linear regression for trend
        $n = $dailyCosts.Count
        $sumX = ($dailyCosts | Measure-Object DayIndex -Sum).Sum
        $sumY = ($dailyCosts | Measure-Object Cost -Sum).Sum
        $sumXY = ($dailyCosts | ForEach-Object { $_.DayIndex * $_.Cost } | Measure-Object -Sum).Sum
        $sumX2 = ($dailyCosts | ForEach-Object { $_.DayIndex * $_.DayIndex } | Measure-Object -Sum).Sum
        
        $slope = ($n * $sumXY - $sumX * $sumY) / ($n * $sumX2 - $sumX * $sumX)
        $intercept = ($sumY - $slope * $sumX) / $n
        
        # Generate forecast
        $lastDate = $dailyCosts[-1].Date
        $lastIndex = $dailyCosts[-1].DayIndex
        
        $forecast = @()
        for ($i = 1; $i -le $ForecastDays; $i++) {
            $forecastDate = $lastDate.AddDays($i)
            $forecastIndex = $lastIndex + $i
            $predictedCost = $intercept + $slope * $forecastIndex
            
            # Add seasonal adjustment (simple weekly pattern)
            $dayOfWeek = $forecastDate.DayOfWeek
            $seasonalMultiplier = switch ($dayOfWeek) {
                "Saturday" { 0.7 }
                "Sunday" { 0.6 }
                default { 1.0 }
            }
            
            $adjustedCost = $predictedCost * $seasonalMultiplier
            
            $forecast += [PSCustomObject]@{
                Date = $forecastDate
                PredictedCost = [Math]::Max(0, $adjustedCost)
                Confidence = [Math]::Max(0.5, 1 - ($i / $ForecastDays) * 0.5)  # Decreasing confidence over time
                TrendDirection = if ($slope -gt 0) { "Increasing" } elseif ($slope -lt 0) { "Decreasing" } else { "Stable" }
            }
        }
        
        # Calculate forecast summary
        $forecastSummary = @{
            PeriodTotal = ($forecast | Measure-Object PredictedCost -Sum).Sum
            DailyAverage = ($forecast | Measure-Object PredictedCost -Average).Average
            TrendSlope = $slope
            TrendDirection = if ($slope -gt 0) { "Increasing" } elseif ($slope -lt 0) { "Decreasing" } else { "Stable" }
            ConfidenceLevel = ($forecast | Measure-Object Confidence -Average).Average
        }
        
        Write-EnhancedLog "📊 Forecast generated: $($forecastSummary.PeriodTotal.ToString('C2')) projected for next $ForecastDays days" "AI"
        
        return @{
            Forecast = $forecast
            Summary = $forecastSummary
            Trend = @{
                Slope = $slope
                Intercept = $intercept
                Direction = $forecastSummary.TrendDirection
            }
        }
        
    } catch {
        Write-EnhancedLog "Failed to generate cost forecast: $($_.Exception.Message)" "Error"
        throw
    }
}

# Generate automated optimization recommendations
function New-OptimizationRecommendations {
    try {
        Write-EnhancedLog "🎯 Generating automated optimization recommendations..." "AI"
        
        $recommendations = @()
        
        # Analyze unused resources
        $unusedResources = $script:ResourceData | Where-Object {
            $resourceCost = $script:CostData | Where-Object { $_.ResourceId -eq $_.ResourceId }
            -not $resourceCost -or ($resourceCost | Measure-Object Cost -Sum).Sum -lt 1
        }
        
        if ($unusedResources.Count -gt 0) {
            $recommendations += [PSCustomObject]@{
                Type = "Remove Unused Resources"
                Priority = "High"
                PotentialSavings = "Unknown"
                Description = "Found $($unusedResources.Count) resources with no or minimal cost activity"
                Action = "Review and consider decommissioning unused resources"
                Resources = $unusedResources.Name -join ", "
            }
        }
        
        # Analyze oversized VMs
        $vmResources = $script:ResourceData | Where-Object { $_.ResourceType -like "*virtualMachines*" }
        if ($vmResources.Count -gt 0) {
            $recommendations += [PSCustomObject]@{
                Type = "VM Right-Sizing"
                Priority = "Medium"
                PotentialSavings = "15-30%"
                Description = "Review VM sizes for potential downsizing opportunities"
                Action = "Monitor CPU and memory utilization to identify over-provisioned VMs"
                Resources = "All Virtual Machines"
            }
        }
        
        # Analyze storage optimization
        $storageResources = $script:ResourceData | Where-Object { $_.ResourceType -like "*storage*" }
        if ($storageResources.Count -gt 0) {
            $recommendations += [PSCustomObject]@{
                Type = "Storage Tier Optimization"
                Priority = "Medium"
                PotentialSavings = "20-40%"
                Description = "Optimize storage tiers based on access patterns"
                Action = "Implement lifecycle management policies for blob storage"
                Resources = "Storage Accounts"
            }
        }
        
        # Analyze reserved instances opportunities
        $computeCost = ($script:CostData | Where-Object { $_.ResourceType -like "*Compute*" } | Measure-Object Cost -Sum).Sum
        if ($computeCost -gt 500) {
            $recommendations += [PSCustomObject]@{
                Type = "Reserved Instances"
                Priority = "High"
                PotentialSavings = "30-60%"
                Description = "Significant compute costs detected - consider reserved instances"
                Action = "Analyze compute usage patterns for reserved instance opportunities"
                Resources = "Compute Resources"
            }
        }
        
        # Analyze spot instance opportunities
        $recommendations += [PSCustomObject]@{
            Type = "Spot Instances"
            Priority = "Low"
            PotentialSavings = "60-90%"
            Description = "Use spot instances for fault-tolerant workloads"
            Action = "Identify workloads suitable for spot instances"
            Resources = "Development/Testing VMs"
        }
        
        # Analyze resource group consolidation
        $resourceGroups = $script:CostData | Group-Object ResourceGroup
        if ($resourceGroups.Count -gt 10) {
            $lowCostRGs = $resourceGroups | Where-Object { 
                ($_.Group | Measure-Object Cost -Sum).Sum -lt 50 
            }
            
            if ($lowCostRGs.Count -gt 0) {
                $recommendations += [PSCustomObject]@{
                    Type = "Resource Group Consolidation"
                    Priority = "Low"
                    PotentialSavings = "5-10%"
                    Description = "Found $($lowCostRGs.Count) resource groups with low cost - consider consolidation"
                    Action = "Review and consolidate low-cost resource groups"
                    Resources = ($lowCostRGs.Name -join ", ")
                }
            }
        }
        
        $script:Recommendations = $recommendations
        
        Write-EnhancedLog "✅ Generated $($recommendations.Count) optimization recommendations" "AI"
        return $recommendations
        
    } catch {
        Write-EnhancedLog "Failed to generate recommendations: $($_.Exception.Message)" "Error"
        throw
    }
}

# Generate comprehensive cost report
function New-CostReport {
    param(
        [object]$Analysis,
        [object]$Forecast,
        [array]$Recommendations
    )
    
    try {
        Write-EnhancedLog "📋 Generating comprehensive cost report..." "Info"
        
        $report = @{
            Metadata = @{
                GeneratedDate = Get-Date
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
        
        # Save report based on output format
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        
        switch ($OutputFormat) {
            "JSON" {
                $outputFile = "$OutputPath\cost-report-$timestamp.json"
                $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
                Write-EnhancedLog "Report saved to: $outputFile" "Success"
            }
            "CSV" {
                # Create summary CSV
                $summaryFile = "$OutputPath\cost-summary-$timestamp.csv"
                $Analysis.ResourceDistribution | Export-Csv -Path $summaryFile -NoTypeInformation
                
                # Create recommendations CSV
                $recFile = "$OutputPath\cost-recommendations-$timestamp.csv"
                $Recommendations | Export-Csv -Path $recFile -NoTypeInformation
                
                Write-EnhancedLog "CSV reports saved to: $OutputPath" "Success"
            }
            "Excel" {
                # This would require ImportExcel module
                Write-EnhancedLog "Excel output requires ImportExcel module - saving as JSON instead" "Warning"
                $outputFile = "$OutputPath\cost-report-$timestamp.json"
                $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
            }
            "PowerBI" {
                # Create Power BI compatible JSON
                $pbiFile = "$OutputPath\cost-data-powerbi-$timestamp.json"
                $pbiData = @{
                    CostData = $script:CostData
                    Analysis = $Analysis
                    Recommendations = $Recommendations
                }
                $pbiData | ConvertTo-Json -Depth 10 | Out-File -FilePath $pbiFile -Encoding UTF8
                Write-EnhancedLog "Power BI data saved to: $pbiFile" "Success"
            }
            "Console" {
                # Display summary in console
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

# Send cost alerts
function Send-CostAlerts {
    param(
        [object]$Analysis,
        [decimal]$Threshold
    )
    
    try {
        $totalCost = $Analysis.Summary.TotalCost
        
        if ($totalCost -gt $Threshold) {
            Write-EnhancedLog "🚨 Cost threshold exceeded: $($totalCost.ToString('C2')) > $($Threshold.ToString('C2'))" "Warning"
            
            $alertMessage = @"
🚨 Azure Cost Alert 🚨

Subscription: $SubscriptionId
Current Period Cost: $($totalCost.ToString('C2'))
Threshold: $($Threshold.ToString('C2'))
Overage: $($totalCost - $Threshold).ToString('C2') ($([Math]::Round((($totalCost - $Threshold) / $Threshold) * 100, 1))%)

Top Cost Drivers:
$($Analysis.ResourceDistribution | Select-Object -First 3 | ForEach-Object { "• $($_.ResourceType): $($_.TotalCost.ToString('C2'))" } | Out-String)

Immediate Actions Recommended:
$($script:Recommendations | Where-Object { $_.Priority -eq "High" } | ForEach-Object { "• $($_.Type): $($_.Action)" } | Out-String)

Generated: $(Get-Date)
"@
            
            # Send Slack notification
            if ($EnableSlackNotifications -and $SlackWebhookUrl) {
                try {
                    $slackPayload = @{
                        text = "Azure Cost Alert"
                        attachments = @(
                            @{
                                color = "danger"
                                title = "Cost Threshold Exceeded"
                                text = $alertMessage
                                footer = "Azure Cost Management Tool"
                                ts = [int][double]::Parse((Get-Date -UFormat %s))
                            }
                        )
                    } | ConvertTo-Json -Depth 4
                    
                    Invoke-RestMethod -Uri $SlackWebhookUrl -Method Post -Body $slackPayload -ContentType "application/json"
                    Write-EnhancedLog "Slack notification sent successfully" "Success"
                } catch {
                    Write-EnhancedLog "Failed to send Slack notification: $($_.Exception.Message)" "Error"
                }
            }
            
            # Send email notification
            if ($EnableEmailNotifications -and $EmailRecipients.Count -gt 0) {
                Write-EnhancedLog "Email notification functionality would be implemented here" "Info"
                # Implementation would depend on available email service (SendGrid, etc.)
            }
        } else {
            Write-EnhancedLog "✅ Cost is within threshold: $($totalCost.ToString('C2')) ≤ $($Threshold.ToString('C2'))" "Success"
        }
        
    } catch {
        Write-EnhancedLog "Failed to send cost alerts: $($_.Exception.Message)" "Error"
    }
}

# Main execution
try {
    Write-EnhancedLog "🚀 Starting Azure AI-Powered Cost Optimization Tool" "Info"
    Write-EnhancedLog "Action: $Action" "Info"
    Write-EnhancedLog "Time Frame: $TimeFrame" "Info"
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Get current subscription if not provided
    if (-not $SubscriptionId) {
        $context = Get-AzContext
        $SubscriptionId = $context.Subscription.Id
        Write-EnhancedLog "Using current subscription: $SubscriptionId" "Info"
    }
    
    # Calculate date range
    if ($TimeFrame -eq "Custom") {
        $dateRange = Get-DateRange -TimeFrame $TimeFrame
    } else {
        $dateRange = Get-DateRange -TimeFrame $TimeFrame
    }
    
    Write-EnhancedLog "Analysis period: $($dateRange.StartDate.ToString('yyyy-MM-dd')) to $($dateRange.EndDate.ToString('yyyy-MM-dd'))" "Info"
    
    # Get cost data
    $costData = Get-CostData -StartDate $dateRange.StartDate -EndDate $dateRange.EndDate
    
    switch ($Action) {
        "Analyze" {
            $analysis = Invoke-AICostAnalysis -CostData $costData
            
            if ($EnablePredictiveAnalytics) {
                $forecast = New-CostForecast -HistoricalData $costData
            }
            
            $report = New-CostReport -Analysis $analysis -Forecast $forecast -Recommendations @()
        }
        
        "Optimize" {
            $analysis = Invoke-AICostAnalysis -CostData $costData
            $recommendations = New-OptimizationRecommendations
            
            if ($EnablePredictiveAnalytics) {
                $forecast = New-CostForecast -HistoricalData $costData
            }
            
            $report = New-CostReport -Analysis $analysis -Forecast $forecast -Recommendations $recommendations
        }
        
        "Forecast" {
            if (-not $EnablePredictiveAnalytics) {
                $EnablePredictiveAnalytics = $true
            }
            
            $analysis = Invoke-AICostAnalysis -CostData $costData
            $forecast = New-CostForecast -HistoricalData $costData -ForecastDays 90
            
            Write-EnhancedLog "📈 90-Day Cost Forecast:" "AI"
            Write-EnhancedLog "Projected Total: $($forecast.Summary.PeriodTotal.ToString('C2'))" "AI"
            Write-EnhancedLog "Daily Average: $($forecast.Summary.DailyAverage.ToString('C2'))" "AI"
            Write-EnhancedLog "Trend: $($forecast.Summary.TrendDirection)" "AI"
        }
        
        "Recommend" {
            $analysis = Invoke-AICostAnalysis -CostData $costData
            $recommendations = New-OptimizationRecommendations
            
            Write-EnhancedLog "🎯 Top Optimization Recommendations:" "AI"
            $recommendations | Sort-Object { 
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
            $analysis = Invoke-AICostAnalysis -CostData $costData
            Send-CostAlerts -Analysis $analysis -Threshold $CostThreshold
        }
        
        "Report" {
            $analysis = Invoke-AICostAnalysis -CostData $costData
            $recommendations = New-OptimizationRecommendations
            
            if ($EnablePredictiveAnalytics) {
                $forecast = New-CostForecast -HistoricalData $costData
            }
            
            $report = New-CostReport -Analysis $analysis -Forecast $forecast -Recommendations $recommendations
        }
        
        "Monitor" {
            $analysis = Invoke-AICostAnalysis -CostData $costData
            Send-CostAlerts -Analysis $analysis -Threshold $CostThreshold
            
            # This would typically run as a scheduled job
            Write-EnhancedLog "Monitoring mode - would run continuously in production" "Info"
        }
    }
    
    Write-EnhancedLog "🎉 Azure AI-Powered Cost Optimization Tool completed successfully" "Success"
    
} catch {
    Write-EnhancedLog "❌ Tool execution failed: $($_.Exception.Message)" "Error"
    exit 1
}
