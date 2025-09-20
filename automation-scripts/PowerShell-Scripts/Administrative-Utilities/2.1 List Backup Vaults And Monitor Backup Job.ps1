#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    List Backup Vaults And Monitor Backup Job

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
[OutputType([bool])]
 {
    [CmdletBinding(SupportsShouldProcess)]

        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding(SupportsShouldProcess)]

        [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$JobId,
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault]$Vault,
        [Parameter(Mandatory = $false)]
        [int]$RefreshIntervalSeconds = 30
    )
    try {
        Write-Host "Setting vault context for $($Vault.Name)..." -ForegroundColor Yellow
        Set-AzRecoveryServicesVaultContext -Vault $Vault -ErrorAction Stop
        $jobHistory = @()
        $completed = $false
        $startTime = Get-Date -ErrorAction Stop
        while (-not $completed) {
            if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
            $job = Get-AzRecoveryServicesBackupJob -JobId $JobId -ErrorAction Stop
            $elapsedTime = (Get-Date) - $startTime
            # Header
            Write-Host " === Azure Backup Job Monitor ===" -ForegroundColor Cyan
            Write-Host " --------------------------------------------------" -ForegroundColor Gray
            # Basic Info
            Write-Host "Vault:     $($Vault.Name)" -ForegroundColor White
            Write-Host "Job ID:    $JobId" -ForegroundColor White
            Write-Host "Operation: $($job.Operation)" -ForegroundColor White
            Write-Host "Workload:  $($job.WorkloadName)" -ForegroundColor White
            Write-Host " --------------------------------------------------" -ForegroundColor Gray
            # Status Information
$statusColor = switch ($job.Status) {
                "InProgress" { "Yellow" }
                "Completed" { "Green" }
                "Failed" { "Red" }
                default { "White" }
            }
            Write-Host "Status:     $($job.Status)" -ForegroundColor $statusColor
            Write-Host "Duration:   $($job.Duration)" -ForegroundColor White
            Write-Host "Start Time: $($job.StartTime)" -ForegroundColor White
            Write-Host "Monitoring: $($elapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor White
            # Subtasks
            if ($job.SubTasks) {
                Write-Host " --------------------------------------------------" -ForegroundColor Gray
                Write-Host "SubTasks:" -ForegroundColor White
                foreach ($task in $job.SubTasks) {
$taskColor = switch ($task.Status) {
                        "Completed" { "Green" }
                        "InProgress" { "Yellow" }
                        "Failed" { "Red" }
                        default { "Gray" }
                    }
                    Write-Host " * $($task.Name)" -ForegroundColor White
                    Write-Host "Status: $($task.Status)" -ForegroundColor $taskColor
                    if ($task.Duration) {
                        Write-Host "Duration: $($task.Duration)" -ForegroundColor White
                    }
                    Write-Host ""
                }
            }
            Write-Host " --------------------------------------------------" -ForegroundColor Gray
            # Update job history
$jobHistory = $jobHistory + [PSCustomObject]@{
                TimeStamp = Get-Date -ErrorAction Stop
                Status = $job.Status
                WorkloadName = $job.WorkloadName
                Operation = $job.Operation
                Duration = $job.Duration
                SubTasks = ($job.SubTasks | ForEach-Object { " $($_.Name): $($_.Status)" }) -join " ; "
            }
            if ($job.Status -in @("Completed" , "Failed" , "CompletedWithWarnings" )) {
                $completed = $true
                # Generate final reports
                New-HTML -FilePath " .\BackupJobReport.html" -ShowHTML {
                    New-HTMLTable -DataTable $jobHistory -Title "Backup Job History" {
                        New-HTMLTableHeader -Title "Backup Job Report - $($job.WorkloadName)" -BackgroundColor " #007bff" -Color " #ffffff"
                    }
                }
                $jobHistory | Export-Csv -Path " .\BackupJobHistory.csv" -NoTypeInformation
                Write-Host " `nJob completed with status: $($job.Status)" -ForegroundColor $statusColor
                Write-Host "Total duration: $($job.Duration)" -ForegroundColor White
                Write-Host "Reports generated: BackupJobReport.html and BackupJobHistory.csv" -ForegroundColor Green
            }
            else {
                Write-Host " `nRefreshing in $RefreshIntervalSeconds seconds... (Press Ctrl+C to stop)" -ForegroundColor Yellow
                Start-Sleep -Seconds $RefreshIntervalSeconds
            }
        }
        return $jobHistory
    }
    catch {
        Write-Error "Failed to monitor backup job: $_"
        throw
    }
}
try {
    Write-Host "Getting Recovery Services vault details..." -ForegroundColor Cyan
    $vaultInfo = Get-AzureBackupVaultDetails -ErrorAction Stop
    $menuOptions = $vaultInfo.MenuOptions
    Write-Host " `nPlease select a vault:" -ForegroundColor Yellow
    foreach ($key in $menuOptions.Keys | Sort-Object) {
        $vault = $menuOptions[$key]
        Write-Host " [$key] $($vault.Name) (ResourceGroup: $($vault.ResourceGroupName), Location: $($vault.Location))" -ForegroundColor Cyan
    }
    do {
        $selection = Read-Host " `nEnter the number of the vault to use (0-$($menuOptions.Count - 1))"
        $validSelection = $selection -match " ^\d+$" -and $menuOptions.ContainsKey([int]$selection)
        if (-not $validSelection) {
            Write-Host "Invalid selection. Please enter a number between 0 and $($menuOptions.Count - 1)" -ForegroundColor Red
        }
    } while (-not $validSelection)
    $selectedVault = $menuOptions[[int]$selection]
    Write-Host " `nUsing vault: $($selectedVault.Name)" -ForegroundColor Green
    # Get list of backup jobs
    $jobs = Get-BackupJobsList -Vault $selectedVault
    if ($jobs) {
$selectedJob = Select-BackupJob -Jobs $jobs
        Write-Host " `nMonitoring backup job:" -ForegroundColor Cyan
        Write-Host "Job ID: $($selectedJob.JobId)" -ForegroundColor Cyan
        Write-Host "Workload: $($selectedJob.WorkloadName)" -ForegroundColor Cyan
        Write-Host "Operation: $($selectedJob.Operation)" -ForegroundColor Cyan
$jobProgress = Watch-AzureBackupJob -JobId $selectedJob.JobId -Vault $selectedVault -RefreshIntervalSeconds 30
    }
    else {
        Write-Host "No backup jobs found in the vault" -ForegroundColor Red

} catch {
    Write-Error $_
    throw
}\n

