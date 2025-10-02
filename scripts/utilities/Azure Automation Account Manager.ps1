#Requires -Version 7.4
#Requires -Modules Az.Automation

<#
.SYNOPSIS
    Azure Automation Account Manager

.DESCRIPTION
    Manages Azure Automation accounts including creation, configuration,
    runbook management, and monitoring

.PARAMETER ResourceGroupName
    Name of the resource group containing the automation account

.PARAMETER AccountName
    Name of the Azure Automation account

.PARAMETER Action
    Action to perform: Get, Create, Update, Delete, ListRunbooks, ListSchedules

.PARAMETER Location
    Azure region for new automation accounts

.PARAMETER Tags
    Tags to apply to the automation account

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AccountName,

    [Parameter()]
    [ValidateSet("Get", "Create", "Update", "Delete", "ListRunbooks", "ListSchedules", "ListVariables")]
    [string]$Action = "Get",

    [Parameter()]
    [string]$Location = "East US",

    [Parameter()]
    [hashtable]$Tags = @{}
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }

    $logEntry = "$timestamp [Automation-Manager] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

try {
    Write-ColorOutput "Azure Automation Account Manager - Starting" -Level INFO
    Write-ColorOutput "Action: $Action" -Level INFO

    switch ($Action) {
        "Get" {
            Write-ColorOutput "Retrieving automation account information..." -Level INFO

            $automationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AccountName -ErrorAction Stop

            Write-Host "`nAutomation Account Details:" -ForegroundColor Cyan
            Write-Host "=============================" -ForegroundColor DarkGray
            Write-Host "Name: $($automationAccount.AutomationAccountName)"
            Write-Host "Resource Group: $($automationAccount.ResourceGroupName)"
            Write-Host "Location: $($automationAccount.Location)"
            Write-Host "State: $($automationAccount.State)"
            Write-Host "Creation Time: $($automationAccount.CreationTime)"
            Write-Host "Last Modified: $($automationAccount.LastModifiedTime)"
            Write-Host "Endpoint: $($automationAccount.Endpoint)"

            if ($automationAccount.Tags.Count -gt 0) {
                Write-Host "`nTags:" -ForegroundColor Cyan
                foreach ($tag in $automationAccount.Tags.GetEnumerator()) {
                    Write-Host "  $($tag.Key): $($tag.Value)"
                }
            }

            # Get additional statistics
            $runbooks = Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -ErrorAction SilentlyContinue
            $schedules = Get-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -ErrorAction SilentlyContinue
            $variables = Get-AzAutomationVariable -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -ErrorAction SilentlyContinue

            Write-Host "`nStatistics:" -ForegroundColor Cyan
            Write-Host "  Runbooks: $($runbooks.Count)"
            Write-Host "  Schedules: $($schedules.Count)"
            Write-Host "  Variables: $($variables.Count)"

            Write-ColorOutput "Automation account information retrieved successfully" -Level SUCCESS
        }

        "Create" {
            Write-ColorOutput "Creating new automation account..." -Level INFO

            # Check if resource group exists
            $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $rg) {
                Write-ColorOutput "Creating resource group: $ResourceGroupName" -Level INFO
                $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tags $Tags -ErrorAction Stop
            }

            # Create automation account
            $automationParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $AccountName
                Location = $Location
                Plan = "Basic"
            }

            if ($Tags.Count -gt 0) {
                $automationParams['Tags'] = $Tags
            }

            $automationAccount = New-AzAutomationAccount @automationParams -ErrorAction Stop

            Write-ColorOutput "Automation account created successfully" -Level SUCCESS
            Write-Host "Name: $($automationAccount.AutomationAccountName)"
            Write-Host "Resource ID: $($automationAccount.AutomationAccountId)"
        }

        "Update" {
            Write-ColorOutput "Updating automation account..." -Level INFO

            $updateParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $AccountName
            }

            if ($Tags.Count -gt 0) {
                $updateParams['Tags'] = $Tags
            }

            Set-AzAutomationAccount @updateParams -ErrorAction Stop
            Write-ColorOutput "Automation account updated successfully" -Level SUCCESS
        }

        "Delete" {
            Write-ColorOutput "Deleting automation account..." -Level WARN

            $confirmation = Read-Host "Are you sure you want to delete the automation account '$AccountName'? (yes/no)"
            if ($confirmation -eq 'yes') {
                Remove-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AccountName -Force -ErrorAction Stop
                Write-ColorOutput "Automation account deleted successfully" -Level SUCCESS
            }
            else {
                Write-ColorOutput "Deletion cancelled" -Level INFO
            }
        }

        "ListRunbooks" {
            Write-ColorOutput "Listing runbooks..." -Level INFO

            $runbooks = Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -ErrorAction Stop

            if ($runbooks) {
                Write-Host "`nRunbooks in Automation Account:" -ForegroundColor Cyan
                Write-Host "================================" -ForegroundColor DarkGray

                foreach ($runbook in $runbooks) {
                    $statusColor = switch ($runbook.State) {
                        "Published" { "Green" }
                        "Draft" { "Yellow" }
                        default { "White" }
                    }

                    Write-Host "`nName: $($runbook.Name)"
                    Write-Host "  Type: $($runbook.RunbookType)"
                    Write-Host "  State: " -NoNewline
                    Write-Host $runbook.State -ForegroundColor $statusColor
                    Write-Host "  Last Modified: $($runbook.LastModifiedTime)"
                    Write-Host "  Location: $($runbook.Location)"

                    if ($runbook.Description) {
                        Write-Host "  Description: $($runbook.Description)"
                    }
                }

                Write-Host "`nTotal runbooks: $($runbooks.Count)" -ForegroundColor Cyan
            }
            else {
                Write-ColorOutput "No runbooks found" -Level WARN
            }
        }

        "ListSchedules" {
            Write-ColorOutput "Listing schedules..." -Level INFO

            $schedules = Get-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -ErrorAction Stop

            if ($schedules) {
                Write-Host "`nSchedules in Automation Account:" -ForegroundColor Cyan
                Write-Host "=================================" -ForegroundColor DarkGray

                foreach ($schedule in $schedules) {
                    $statusColor = if ($schedule.IsEnabled) { "Green" } else { "Red" }

                    Write-Host "`nName: $($schedule.Name)"
                    Write-Host "  Enabled: " -NoNewline
                    Write-Host $schedule.IsEnabled -ForegroundColor $statusColor
                    Write-Host "  Frequency: $($schedule.Frequency)"
                    Write-Host "  Start Time: $($schedule.StartTime)"
                    Write-Host "  Next Run: $($schedule.NextRun)"
                    Write-Host "  Time Zone: $($schedule.TimeZone)"

                    if ($schedule.Description) {
                        Write-Host "  Description: $($schedule.Description)"
                    }
                }

                Write-Host "`nTotal schedules: $($schedules.Count)" -ForegroundColor Cyan
            }
            else {
                Write-ColorOutput "No schedules found" -Level WARN
            }
        }

        "ListVariables" {
            Write-ColorOutput "Listing variables..." -Level INFO

            $variables = Get-AzAutomationVariable -ResourceGroupName $ResourceGroupName -AutomationAccountName $AccountName -ErrorAction Stop

            if ($variables) {
                Write-Host "`nVariables in Automation Account:" -ForegroundColor Cyan
                Write-Host "================================" -ForegroundColor DarkGray

                foreach ($variable in $variables) {
                    Write-Host "`nName: $($variable.Name)"
                    Write-Host "  Encrypted: $($variable.IsEncrypted)"
                    Write-Host "  Created: $($variable.CreationTime)"
                    Write-Host "  Last Modified: $($variable.LastModifiedTime)"

                    if (-not $variable.IsEncrypted -and $variable.Value) {
                        Write-Host "  Value: $($variable.Value)"
                    }

                    if ($variable.Description) {
                        Write-Host "  Description: $($variable.Description)"
                    }
                }

                Write-Host "`nTotal variables: $($variables.Count)" -ForegroundColor Cyan
            }
            else {
                Write-ColorOutput "No variables found" -Level WARN
            }
        }
    }

    Write-ColorOutput "`nOperation completed successfully" -Level SUCCESS
}
catch {
    Write-ColorOutput "Operation failed: $($_.Exception.Message)" -Level ERROR
    throw
}