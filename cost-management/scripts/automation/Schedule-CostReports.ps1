#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Sets up automated Azure cost reporting with email notifications.

.DESCRIPTION
    This script configures scheduled Azure cost reports to be automatically generated
    and emailed to specified recipients. Supports daily, weekly, and monthly schedules
    with customizable report formats and content.

.PARAMETER Type
    Report frequency: Daily, Weekly, Monthly, or Custom.

.PARAMETER Recipients
    Array of email addresses to receive reports.

.PARAMETER Format
    Report format: Excel, CSV, PDF, or HTML. Default is Excel.

.PARAMETER SubscriptionId
    Azure subscription ID. Uses default subscription if not specified.

.PARAMETER ResourceGroups
    Optional array of resource group names to filter reports.

.PARAMETER BudgetThreshold
    Budget percentage threshold for alerts (default: 80%).

.PARAMETER SMTPServer
    SMTP server for sending emails. Uses Office 365 by default.

.PARAMETER EmailCredential
    PSCredential object for email authentication.

.EXAMPLE
    .\Schedule-CostReports.ps1 -Type "Daily" -Recipients @("finance@company.com", "manager@company.com")

.EXAMPLE
    .\Schedule-CostReports.ps1 -Type "Weekly" -Format "PDF" -Recipients @("executives@company.com") -BudgetThreshold 90

.EXAMPLE
    .\Schedule-CostReports.ps1 -Type "Monthly" -ResourceGroups @("Production-RG", "Development-RG") -Recipients @("team@company.com")

.NOTES
    Author: Wesley Ellis
    Email: wes@wesellis.com
    Created: May 23, 2025
    Version: 1.0

    Prerequisites:
    - Azure PowerShell module (Az)
    - Email server access (SMTP)
    - Cost Management Reader permissions
    - Windows Task Scheduler access (for automation)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Daily", "Weekly", "Monthly", "Custom")]
    [string]$Type,
    
    [Parameter(Mandatory = $true)]
    [string[]]$Recipients,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Excel", "CSV", "PDF", "HTML")]
    [string]$Format = "Excel",
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string[]]$ResourceGroups,
    
    [Parameter(Mandatory = $false)]
    [int]$BudgetThreshold = 80,
    
    [Parameter(Mandatory = $false)]
    [string]$SMTPServer = "smtp.office365.com",
    
    [Parameter(Mandatory = $false)]
    [PSCredential]$EmailCredential
)

#region Functions

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path (Split-Path $ScriptRoot -Parent) "config"
$LogPath = Join-Path (Split-Path $ScriptRoot -Parent) "logs"
$ReportPath = Join-Path (Split-Path $ScriptRoot -Parent) "reports"

# Ensure directories exist
@($LogPath, $ReportPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# Logging function
[CmdletBinding()]
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Output $logEntry
    Add-Content -Path (Join-Path $LogPath "cost-reports.log") -Value $logEntry
}

[CmdletBinding()]
function Get-EmailCredential -ErrorAction Stop {
    <#
    .SYNOPSIS
        Gets email credentials from secure storage or prompts user
    #>
    if ($EmailCredential) {
        return $EmailCredential
    }
    
    $credFile = Join-Path $ConfigPath "email-credential.xml"
    
    if (Test-Path $credFile) {
        Write-Log "Loading saved email credentials"
        return Import-Clixml $credFile
    }
    
    Write-Log "No saved credentials found. Prompting for email authentication."
    $cred = Get-Credential -Message "Enter email credentials for sending reports"
    
    # Offer to save credentials securely
    $saveChoice = Read-Host "Save credentials securely for future use? (y/n)"
    if ($saveChoice -eq 'y') {
        $cred | Export-Clixml $credFile
        Write-Log "Email credentials saved securely"
    }
    
    return $cred
}

[CmdletBinding()]
function Get-CostReportData -ErrorAction Stop {
    <#
    .SYNOPSIS
        Retrieves cost data for the specified time period
    #>
    param(
        [string]$Subscription,
        [string[]]$ResourceGroupFilter,
        [datetime]$StartDate,
        [datetime]$EndDate
    )
    
    Write-Log "Retrieving cost data from $StartDate to $EndDate"
    
    # Build filter parameters
    $params = @{
        SubscriptionId = $Subscription
        StartDate = $StartDate
        EndDate = $EndDate
        Granularity = "Daily"
        OutputFormat = "Console"
    }
    
    if ($ResourceGroupFilter) {
        Write-Log "Filtering by resource groups: $($ResourceGroupFilter -join ', ')"
        # For multiple resource groups, we'll combine the results
        $allData = @()
        foreach ($rg in $ResourceGroupFilter) {
            $params.ResourceGroupName = $rg
            $rgData = & (Join-Path $ScriptRoot "..\data-collection\Get-AzureCostData.ps1") @params
            $allData += $rgData
        }
        return $allData
    }
    else {
        return & (Join-Path $ScriptRoot "..\data-collection\Get-AzureCostData.ps1") @params
    }
}

[CmdletBinding()]
function New-CostReport -ErrorAction Stop {
    <#
    .SYNOPSIS
        Generates a formatted cost report
    #>
    param(
        [object[]]$CostData,
        [string]$ReportType,
        [string]$OutputFormat,
        [string]$OutputPath
    )
    
    Write-Log "Generating $ReportType cost report in $OutputFormat format"
    
    # Calculate summary statistics
    $totalCost = ($CostData | Measure-Object -Property Cost -Sum).Sum
    $resourceGroupSummary = $CostData | Group-Object ResourceGroup | 
        Select-Object Name, @{Name="Cost"; Expression={($_.Group | Measure-Object Cost -Sum).Sum}} |
        Sort-Object Cost -Descending
    $serviceSummary = $CostData | Group-Object ServiceName |
        Select-Object Name, @{Name="Cost"; Expression={($_.Group | Measure-Object Cost -Sum).Sum}} |
        Sort-Object Cost -Descending
    
    # Generate report based on format
    switch ($OutputFormat) {
        "Excel" {
            $ExcelPath = $OutputPath -replace '\.[^.]*$', '.xlsx'
            $CostData | Export-Excel -Path $ExcelPath -WorksheetName "Detailed Costs" -AutoSize -FreezeTopRow -BoldTopRow
            $resourceGroupSummary | Export-Excel -Path $ExcelPath -WorksheetName "By Resource Group" -AutoSize -FreezeTopRow -BoldTopRow
            $serviceSummary | Export-Excel -Path $ExcelPath -WorksheetName "By Service" -AutoSize -FreezeTopRow -BoldTopRow
            
            # Add summary worksheet
            $summaryData = [PSCustomObject]@{
                "Report Type" = $ReportType
                "Generated Date" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                "Total Cost" = $totalCost.ToString("C")
                "Record Count" = $CostData.Count
                "Top Resource Group" = $resourceGroupSummary[0].Name
                "Top Service" = $serviceSummary[0].Name
            }
            $summaryData | Export-Excel -Path $ExcelPath -WorksheetName "Summary" -AutoSize
            
            return $ExcelPath
        }
        
        "CSV" {
            $CSVPath = $OutputPath -replace '\.[^.]*$', '.csv'
            $CostData | Export-Csv -Path $CSVPath -NoTypeInformation
            return $CSVPath
        }
        
        "HTML" {
            $HTMLPath = $OutputPath -replace '\.[^.]*$', '.html'
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Cost Report - $ReportType</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 20px; }
        .header { background: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .summary { background: #f8f9fa; padding: 15px; margin: 20px 0; border-radius: 5px; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #0078d4; color: white; }
        .cost { text-align: right; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Azure Cost Report</h1>
        <p>Report Type: $ReportType | Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Total Cost:</strong> $($totalCost.ToString("C"))</p>
        <p><strong>Number of Records:</strong> $($CostData.Count)</p>
        <p><strong>Top Resource Group:</strong> $($resourceGroupSummary[0].Name) ($($resourceGroupSummary[0].Cost.ToString("C")))</p>
        <p><strong>Top Service:</strong> $($serviceSummary[0].Name) ($($serviceSummary[0].Cost.ToString("C")))</p>
    </div>
    
    <h2>Top Resource Groups</h2>
    <table>
        <tr><th>Resource Group</th><th>Cost</th></tr>
"@
            foreach ($rg in $resourceGroupSummary | Select-Object -First 10) {
                $html += "<tr><td>$($rg.Name)</td><td class='cost'>$($rg.Cost.ToString('C'))</td></tr>"
            }
            
            $html += @"
    </table>
    
    <h2>Top Services</h2>
    <table>
        <tr><th>Service</th><th>Cost</th></tr>
"@
            foreach ($service in $serviceSummary | Select-Object -First 10) {
                $html += "<tr><td>$($service.Name)</td><td class='cost'>$($service.Cost.ToString('C'))</td></tr>"
            }
            
            $html += "</table></body></html>"
            
            $html | Out-File -FilePath $HTMLPath -Encoding UTF8
            return $HTMLPath
        }
    }
}

[CmdletBinding()]
function Send-CostReport {
    <#
    .SYNOPSIS
        Sends the cost report via email
    #>
    param(
        [string]$ReportPath,
        [string[]]$ToAddresses,
        [string]$ReportType,
        [decimal]$TotalCost,
        [PSCredential]$Credential
    )
    
    Write-Log "Sending $ReportType report to $($ToAddresses -join ', ')"
    
    $subject = "Azure Cost Report - $ReportType - $(Get-Date -Format 'yyyy-MM-dd')"
    $body = @"
Azure Cost Management Report

Report Type: $ReportType
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Total Cost: $($TotalCost.ToString('C'))

Please find the detailed cost report attached.

This is an automated report generated by the Azure Cost Management Dashboard.
For questions or issues, please contact the IT team.

Best regards,
Azure Cost Management System
"@

    $mailParams = @{
        SmtpServer = $SMTPServer
        Port = 587
        UseSSL = $true
        Credential = $Credential
        From = $Credential.UserName
        To = $ToAddresses
        Subject = $subject
        Body = $body
        Attachments = $ReportPath
    }
    
    try {
        Send-MailMessage @mailParams
        Write-Log "Email sent successfully to $($ToAddresses -join ', ')"
    }
    catch {
        Write-Log "Failed to send email: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

[CmdletBinding()]
function New-ScheduledTask -ErrorAction Stop {
    <#
    .SYNOPSIS
        Creates a Windows scheduled task for automated reports
    #>
    param(
        [string]$TaskName,
        [string]$ReportType,
        [string]$ScriptPath,
        [hashtable]$Parameters
    )
    
    Write-Log "Creating scheduled task: $TaskName"
    
    # Build parameter string
    $paramString = ""
    foreach ($key in $Parameters.Keys) {
        $value = $Parameters[$key]
        if ($value -is [array]) {
            $paramString += " -$key @('$($value -join "','")')"
        }
        else {
            $paramString += " -$key '$value'"
        }
    }
    
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`"$paramString"
    
    $trigger = switch ($ReportType) {
        "Daily" { New-ScheduledTaskTrigger -Daily -At "06:00AM" }
        "Weekly" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "07:00AM" }
        "Monthly" { New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Monday -At "08:00AM" }
    }
    
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType ServiceAccount
    
    try {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
        Write-Log "Scheduled task '$TaskName' created successfully"
    }
    catch {
        Write-Log "Failed to create scheduled task: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

# Main execution
try {
    Write-Log "Starting automated cost report setup - Type: $Type"
    
    # Validate Azure connection
    $context = Get-AzContext -ErrorAction Stop
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }
    
    # Set subscription
    if (-not $SubscriptionId) {
        $SubscriptionId = $context.Subscription.Id
    }
    
    Write-Log "Using subscription: $SubscriptionId"
    
    # Get email credentials
    $emailCred = Get-EmailCredential -ErrorAction Stop
    
    # Determine date range based on report type
    $endDate = Get-Date -ErrorAction Stop
    $startDate = switch ($Type) {
        "Daily" { $endDate.AddDays(-1) }
        "Weekly" { $endDate.AddDays(-7) }
        "Monthly" { $endDate.AddDays(-30) }
    }
    
    # Generate test report to verify configuration
    Write-Log "Generating test report to verify configuration"
    $costData = Get-CostReportData -Subscription $SubscriptionId -ResourceGroupFilter $ResourceGroups -StartDate $startDate -EndDate $endDate
    
    if ($costData.Count -eq 0) {
        Write-Warning "No cost data found for the specified criteria. Please verify your subscription has resources and cost data."
        return
    }
    
    $totalCost = ($costData | Measure-Object -Property Cost -Sum).Sum
    $reportFileName = "Azure-Cost-Report-Test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $reportPath = Join-Path $ReportPath $reportFileName
    
    $generatedReport = New-CostReport -CostData $costData -ReportType "Test-$Type" -OutputFormat $Format -OutputPath $reportPath
    
    # Send test report
    Send-CostReport -ReportPath $generatedReport -ToAddresses $Recipients -ReportType "Test-$Type" -TotalCost $totalCost -Credential $emailCred
    
    # Create scheduled task for automation
    $taskName = "Azure-Cost-Report-$Type"
    $scriptPath = $MyInvocation.MyCommand.Path
    $taskParams = @{
        Type = $Type
        Recipients = $Recipients
        Format = $Format
        SubscriptionId = $SubscriptionId
        BudgetThreshold = $BudgetThreshold
    }
    
    if ($ResourceGroups) {
        $taskParams.ResourceGroups = $ResourceGroups
    }
    
    New-ScheduledTask -TaskName $taskName -ReportType $Type -ScriptPath $scriptPath -Parameters $taskParams
    
    Write-Log "Automated cost reporting setup completed successfully" -Level "SUCCESS"
    
    Write-Information "`n SETUP COMPLETE!"
    Write-Information "� Test report sent to: $($Recipients -join ', ')"
    Write-Information "⏰ Scheduled task created: $taskName"
    Write-Information " Report format: $Format"
    Write-Information " Total cost in test period: $($totalCost.ToString('C'))"
    Write-Information "`nNext steps:"
    Write-Information "• Check your email for the test report"
    Write-Information "• Verify the scheduled task in Task Scheduler"
    Write-Information "• Monitor the logs in: $LogPath"
    Write-Information "• Reports will be saved in: $ReportPath"
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    exit 1
}


#endregion
