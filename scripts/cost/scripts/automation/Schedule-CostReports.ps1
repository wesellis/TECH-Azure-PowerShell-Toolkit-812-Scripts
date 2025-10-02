<#
.SYNOPSIS
    Schedule CostReports

.DESCRIPTION
    Azure PowerShell automation script

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
#>

#Requires -Version 7.4
#Requires -Modules Az.Resources
    [string]$ErrorActionPreference = 'Stop'

    if ($EmailCredential) {
        return $EmailCredential
    }
    [string]$CredFile = Join-Path $ConfigPath "email-credential.xml"

    if (Test-Path $CredFile) {
        Write-Log "Loading saved email credentials"
        return Import-Clixml $CredFile
    }

    Write-Log "No saved credentials found. Prompting for email authentication."
$cred = Get-Credential -Message "Enter email credentials for sending reports"
    [string]$SaveChoice = Read-Host "Save credentials securely for future use? (y/n)"
    if ($SaveChoice -eq 'y') {
    [string]$cred | Export-Clixml $CredFile
        Write-Log "Email credentials saved securely"
    }

    return $cred
}

function Write-Log {
    param(
        [string]$Subscription,
        [string[]]$ResourceGroupFilter,
        [datetime]$StartDate,
        [datetime]$EndDate
    )

    Write-Log "Retrieving cost data from $StartDate to $EndDate"
$params = @{
        SubscriptionId = $Subscription
        StartDate = $StartDate
        EndDate = $EndDate
        Granularity = "Daily"
        OutputFormat = "Console"
    }

    if ($ResourceGroupFilter) {
        Write-Log "Filtering by resource groups: $($ResourceGroupFilter -join ', ')"
    [string]$AllData = @()
        foreach ($rg in $ResourceGroupFilter) {
    [string]$params.ResourceGroupName = $rg
    [string]$RgData = & (Join-Path $ScriptRoot "..\data-collection\Get-AzureCostData.ps1") @params
    [string]$AllData += $RgData
        }
        return $AllData
    }
    else {
        return & (Join-Path $ScriptRoot "..\data-collection\Get-AzureCostData.ps1") @params
    }
}

function New-CostReport {
    param(
        [object[]]$CostData,
        [string]$ReportType,
        [string]$OutputFormat,
        [string]$OutputPath
    )

    Write-Log "Generating $ReportType cost report in $OutputFormat format"
    [string]$TotalCost = ($CostData | Measure-Object -Property Cost -Sum).Sum
    [string]$ResourceGroupSummary = $CostData | Group-Object ResourceGroup |
        Select-Object Name, @{Name="Cost"; Expression={($_.Group | Measure-Object Cost -Sum).Sum}} |
        Sort-Object Cost -Descending
    [string]$ServiceSummary = $CostData | Group-Object ServiceName |
        Select-Object Name, @{Name="Cost"; Expression={($_.Group | Measure-Object Cost -Sum).Sum}} |
        Sort-Object Cost -Descending

    switch ($OutputFormat) {
        "Excel" {
    [string]$ExcelPath = $OutputPath -replace '\.[^.]*$', '.xlsx'
    [string]$CostData | Export-Excel -Path $ExcelPath -WorksheetName "Detailed Costs" -AutoSize -FreezeTopRow -BoldTopRow
    [string]$ResourceGroupSummary | Export-Excel -Path $ExcelPath -WorksheetName "By Resource Group" -AutoSize -FreezeTopRow -BoldTopRow
    [string]$ServiceSummary | Export-Excel -Path $ExcelPath -WorksheetName "By Service" -AutoSize -FreezeTopRow -BoldTopRow
$SummaryData = [PSCustomObject]@{
                "Report Type" = $ReportType
                "Generated Date" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                "Total Cost" = $TotalCost.ToString("C")
                "Record Count" = $CostData.Count
                "Top Resource Group" = $ResourceGroupSummary[0].Name
                "Top Service" = $ServiceSummary[0].Name
            }
    [string]$SummaryData | Export-Excel -Path $ExcelPath -WorksheetName "Summary" -AutoSize

            return $ExcelPath
        }

        "CSV" {
    [string]$CSVPath = $OutputPath -replace '\.[^.]*$', '.csv'
    [string]$CostData | Export-Csv -Path $CSVPath -NoTypeInformation
            return $CSVPath
        }

        "HTML" {
    [string]$HTMLPath = $OutputPath -replace '\.[^.]*$', '.html'
    [string]$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Cost Report - $ReportType</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 20px; }
        .header { background:
        .summary { background:
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid
        th { background-color:
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
        <p><strong>Total Cost:</strong> $($TotalCost.ToString("C"))</p>
        <p><strong>Number of Records:</strong> $($CostData.Count)</p>
        <p><strong>Top Resource Group:</strong> $($ResourceGroupSummary[0].Name) ($($ResourceGroupSummary[0].Cost.ToString("C")))</p>
        <p><strong>Top Service:</strong> $($ServiceSummary[0].Name) ($($ServiceSummary[0].Cost.ToString("C")))</p>
    </div>

    <h2>Top Resource Groups</h2>
    <table>
        <tr><th>Resource Group</th><th>Cost</th></tr>
"@
            foreach ($rg in $ResourceGroupSummary | Select-Object -First 10) {
    [string]$html += "<tr><td>$($rg.Name)</td><td class='cost'>$($rg.Cost.ToString('C'))</td></tr>"
            }
    [string]$html += @"
    </table>

    <h2>Top Services</h2>
    <table>
        <tr><th>Service</th><th>Cost</th></tr>
"@
            foreach ($service in $ServiceSummary | Select-Object -First 10) {
    [string]$html += "<tr><td>$($service.Name)</td><td class='cost'>$($service.Cost.ToString('C'))</td></tr>"
            }
    [string]$html += "</table></body></html>"
    [string]$html | Out-File -FilePath $HTMLPath -Encoding UTF8
            return $HTMLPath
        }
    }
}

function Send-CostReport {
    param(
        [string]$ReportPath,
        [string[]]$ToAddresses,
        [string]$ReportType,
        [decimal]$TotalCost,
        [PSCredential]$Credential
    )

    Write-Log "Sending $ReportType report to $($ToAddresses -join ', ')"
    [string]$subject = "Azure Cost Report - $ReportType - $(Get-Date -Format 'yyyy-MM-dd')"
    [string]$body = @"
Azure Cost Management Report

Report Type: $ReportType
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Total Cost: $($TotalCost.ToString('C'))

Please find the detailed cost report attached.

For questions or issues, please contact the IT team.

Best regards,
Azure Cost Management System
"@
$MailParams = @{
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

function New-ScheduledTask {
    param(
        [string]$TaskName,
        [string]$ReportType,
        [string]$ScriptPath,
        [hashtable]$Parameters
    )

    Write-Log "Creating scheduled task: $TaskName"
    [string]$ParamString = ""
    foreach ($key in $Parameters.Keys) {
    [string]$value = $Parameters[$key]
        if ($value -is [array]) {
    [string]$ParamString += " -$key @('$($value -join "','")')"
        }
        else {
    [string]$ParamString += " -$key '$value'"
        }
    }
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`"$ParamString"
    [string]$trigger = switch ($ReportType) {
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

try {
    Write-Log "Starting automated cost report setup - Type: $Type"
$context = Get-AzContext -ErrorAction Stop
    if (-not $context) {
        throw "Not connected to Azure. Please run Connect-AzAccount first."
    }

    if (-not $SubscriptionId) {
    [string]$SubscriptionId = $context.Subscription.Id
    }

    Write-Log "Using subscription: $SubscriptionId"
$EmailCred = Get-EmailCredential -ErrorAction Stop
$EndDate = Get-Date -ErrorAction Stop
    [string]$StartDate = switch ($Type) {
        "Daily" { $EndDate.AddDays(-1) }
        "Weekly" { $EndDate.AddDays(-7) }
        "Monthly" { $EndDate.AddDays(-30) }
    }

    Write-Log "Generating test report to verify configuration"
$CostData = Get-CostReportData -Subscription $SubscriptionId -ResourceGroupFilter $ResourceGroups -StartDate $StartDate -EndDate $EndDate

    if ($CostData.Count -eq 0) {
        Write-Warning "No cost data found for the specified criteria. Please verify your subscription has resources and cost data."
        return
    }
    [string]$TotalCost = ($CostData | Measure-Object -Property Cost -Sum).Sum
    [string]$ReportFileName = "Azure-Cost-Report-Test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    [string]$ReportPath = Join-Path $ReportPath $ReportFileName
$GeneratedReport = New-CostReport -CostData $CostData -ReportType "Test-$Type" -OutputFormat $Format -OutputPath $ReportPath

    Send-CostReport -ReportPath $GeneratedReport -ToAddresses $Recipients -ReportType "Test-$Type" -TotalCost $TotalCost -Credential $EmailCred
    [string]$TaskName = "Azure-Cost-Report-$Type"
    [string]$ScriptPath = $MyInvocation.MyCommand.Path
$TaskParams = @{
        Type = $Type
        Recipients = $Recipients
        Format = $Format
        SubscriptionId = $SubscriptionId
        BudgetThreshold = $BudgetThreshold
    }

    if ($ResourceGroups) {
    [string]$TaskParams.ResourceGroups = $ResourceGroups
    }

    New-ScheduledTask -TaskName $TaskName -ReportType $Type -ScriptPath $ScriptPath -Parameters $TaskParams

    Write-Log "Automated cost reporting setup completed successfully" -Level "SUCCESS"

    Write-Host "`n[SETUP COMPLETE]" -ForegroundColor Green
    Write-Host "[EMAIL] Test report sent to: $($Recipients -join ', ')" -ForegroundColor Green
    Write-Host "[TASK] Scheduled task created: $TaskName" -ForegroundColor Green
    Write-Host "[FORMAT] Report format: $Format" -ForegroundColor Green
    Write-Host "[COST] Total cost in test period: $($TotalCost.ToString('C'))" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Green
    Write-Host "- Check your email for the test report" -ForegroundColor Green
    Write-Host "- Verify the scheduled task in Task Scheduler" -ForegroundColor Green
    Write-Host "- Monitor the logs in: $LogPath" -ForegroundColor Green
    Write-Host "- Reports will be saved in: $ReportPath" -ForegroundColor Green
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    throw
}
finally {
    Write-Log "Cost report scheduling script completed"`n}
