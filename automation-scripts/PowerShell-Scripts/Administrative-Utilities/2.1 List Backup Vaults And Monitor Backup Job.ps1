<#
.SYNOPSIS
    2.1 List Backup Vaults And Monitor Backup Job

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
    We Enhanced 2.1 List Backup Vaults And Monitor Backup Job

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


function WE-Get-AzureBackupVaultDetails {
    try {
        Write-WELog "Retrieving Recovery Services vaults..." " INFO" -ForegroundColor Yellow
        $vaults = Get-AzRecoveryServicesVault
        
        $vaultDetails = @()
        $menuOptions = @{}
        $menuIndex = 0
        
        foreach ($vault in $vaults) {
            $vaultInfo = [PSCustomObject]@{
                Name             = $vault.Name
                ResourceGroup    = $vault.ResourceGroupName
                Location         = $vault.Location
                SubscriptionId   = (Get-AzContext).Subscription.Id
                SubscriptionName = (Get-AzContext).Subscription.Name
                VaultObject      = $vault
            }
            $vaultDetails = $vaultDetails + $vaultInfo
            $menuOptions[$menuIndex] = $vault
            $menuIndex++
        }

        return @{
            Details     = $vaultDetails
            MenuOptions = $menuOptions
        }
    }
    catch {
        Write-Error " Failed to retrieve vault details: $_"
        throw
    }
}


function WE-Get-BackupJobsList {
    

function Write-WELog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

param(
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault]$WEVault,
        
        [Parameter(Mandatory = $false)]
        [int]$WEDaysToLook = 1
    )
    
    try {
        Write-WELog " Setting vault context for $($WEVault.Name)..." " INFO" -ForegroundColor Yellow
        Set-AzRecoveryServicesVaultContext -Vault $WEVault -ErrorAction Stop
        
        # Get UTC time range
        $startTime = (Get-Date).ToUniversalTime().AddDays(-$WEDaysToLook)
        $endTime = (Get-Date).ToUniversalTime()
        
        Write-WELog " Retrieving backup jobs from $($startTime) to $($endTime) UTC..." " INFO" -ForegroundColor Yellow
        
        $jobs = Get-AzRecoveryServicesBackupJob -From $startTime -To $endTime | 
        Where-Object { $_.WorkloadName -like " *ArcGis*" -or $_.WorkloadName -like " *arcgis*" } |
        Sort-Object StartTime -Descending
            
        if (-not $jobs) {
            Write-WELog " No backup jobs found in the last $WEDaysToLook day(s)" " INFO" -ForegroundColor Red
            Write-WELog " Expanding search to last 7 days..." " INFO" -ForegroundColor Yellow
            
            $startTime = (Get-Date).ToUniversalTime().AddDays(-7)
            $jobs = Get-AzRecoveryServicesBackupJob -From $startTime -To $endTime | 
            Where-Object { $_.WorkloadName -like " *ArcGis*" -or $_.WorkloadName -like " *arcgis*" } |
            Sort-Object StartTime -Descending
        }

        if (-not $jobs) {
            Write-WELog " No ArcGis-related jobs found. Listing all recent jobs..." " INFO" -ForegroundColor Yellow
            $jobs = Get-AzRecoveryServicesBackupJob -From $startTime -To $endTime |
            Sort-Object StartTime -Descending
        }
        
        return $jobs
    }
    catch {
        Write-Error " Failed to retrieve backup jobs: $_"
        throw
    }
}


function WE-Select-BackupJob {
    

function Write-WELog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

param(
        [Parameter(Mandatory = $true)]
        [Array]$WEJobs
    )
    
    Write-WELog " `nAvailable backup jobs:" " INFO" -ForegroundColor Yellow
    $menuOptions = @{}
    $index = 0
    
    foreach ($job in $WEJobs) {
        $menuOptions[$index] = $job
        Write-WELog " [$index] WorkloadName: $($job.WorkloadName)" " INFO" -ForegroundColor Cyan
        Write-WELog "     Status: $($job.Status)" " INFO" -ForegroundColor Gray
        Write-WELog "     Started: $($job.StartTime) UTC" " INFO" -ForegroundColor Gray
        Write-WELog "     Operation: $($job.Operation)" " INFO" -ForegroundColor Gray
        Write-WELog "     JobId: $($job.JobId)" " INFO" -ForegroundColor Gray
        Write-WELog "" " INFO"
        $index++
    }
    
    do {
        $selection = Read-Host " `nEnter the number of the backup job to monitor (0-$($menuOptions.Count - 1))"
        $validSelection = $selection -match " ^\d+$" -and $menuOptions.ContainsKey([int]$selection)
        
        if (-not $validSelection) {
            Write-WELog " Invalid selection. Please enter a number between 0 and $($menuOptions.Count - 1)" " INFO" -ForegroundColor Red
        }
    } while (-not $validSelection)
    
    return $menuOptions[[int]$selection]
}








function WE-Watch-AzureBackupJob {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
    

function Write-WELog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

param(
        [Parameter(Mandatory = $true)]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEJobId,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault]$WEVault,

        [Parameter(Mandatory = $false)]
        [int]$WERefreshIntervalSeconds = 30
    )

    try {
        Write-WELog " Setting vault context for $($WEVault.Name)..." " INFO" -ForegroundColor Yellow
        Set-AzRecoveryServicesVaultContext -Vault $WEVault -ErrorAction Stop

        $jobHistory = @()
        $completed = $false
        $startTime = Get-Date
        
        while (-not $completed) {
            Clear-Host
            $job = Get-AzRecoveryServicesBackupJob -JobId $WEJobId -ErrorAction Stop
            $elapsedTime = (Get-Date) - $startTime
            
            # Header
            Write-WELog " === Azure Backup Job Monitor ===" " INFO" -ForegroundColor Cyan
            Write-WELog " --------------------------------------------------" " INFO" -ForegroundColor Gray
            
            # Basic Info
            Write-WELog " Vault:     $($WEVault.Name)" " INFO" -ForegroundColor White
            Write-WELog " Job ID:    $WEJobId" " INFO" -ForegroundColor White
            Write-WELog " Operation: $($job.Operation)" " INFO" -ForegroundColor White
            Write-WELog " Workload:  $($job.WorkloadName)" " INFO" -ForegroundColor White
            Write-WELog " --------------------------------------------------" " INFO" -ForegroundColor Gray
            
            # Status Information
           ;  $statusColor = switch ($job.Status) {
                " InProgress" { " Yellow" }
                " Completed" { " Green" }
                " Failed" { " Red" }
                default { " White" }
            }
            
            Write-WELog " Status:     $($job.Status)" " INFO" -ForegroundColor $statusColor
            Write-WELog " Duration:   $($job.Duration)" " INFO" -ForegroundColor White
            Write-WELog " Start Time: $($job.StartTime)" " INFO" -ForegroundColor White
            Write-WELog " Monitoring: $($elapsedTime.ToString('hh\:mm\:ss'))" " INFO" -ForegroundColor White
            
            # Subtasks
            if ($job.SubTasks) {
                Write-WELog " --------------------------------------------------" " INFO" -ForegroundColor Gray
                Write-WELog " SubTasks:" " INFO" -ForegroundColor White
                
                foreach ($task in $job.SubTasks) {
                   ;  $taskColor = switch ($task.Status) {
                        " Completed" { " Green" }
                        " InProgress" { " Yellow" }
                        " Failed" { " Red" }
                        default { " Gray" }
                    }
                    Write-WELog " * $($task.Name)" " INFO" -ForegroundColor White
                    Write-WELog "  Status: $($task.Status)" " INFO" -ForegroundColor $taskColor
                    if ($task.Duration) {
                        Write-WELog "  Duration: $($task.Duration)" " INFO" -ForegroundColor White
                    }
                    Write-WELog "" " INFO"
                }
            }
            
            Write-WELog " --------------------------------------------------" " INFO" -ForegroundColor Gray
            
            # Update job history
           ;  $jobHistory = $jobHistory + [PSCustomObject]@{
                TimeStamp = Get-Date
                Status = $job.Status
                WorkloadName = $job.WorkloadName
                Operation = $job.Operation
                Duration = $job.Duration
                SubTasks = ($job.SubTasks | ForEach-Object { " $($_.Name): $($_.Status)" }) -join " ; "
            }

            if ($job.Status -in @(" Completed" , " Failed" , " CompletedWithWarnings" )) {
                $completed = $true
                
                # Generate final reports
                New-HTML -FilePath " .\BackupJobReport.html" -ShowHTML {
                    New-HTMLTable -DataTable $jobHistory -Title " Backup Job History" {
                        New-HTMLTableHeader -Title " Backup Job Report - $($job.WorkloadName)" -BackgroundColor " #007bff" -Color " #ffffff"
                    }
                }

                $jobHistory | Export-Csv -Path " .\BackupJobHistory.csv" -NoTypeInformation
                
                Write-WELog " `nJob completed with status: $($job.Status)" " INFO" -ForegroundColor $statusColor
                Write-WELog " Total duration: $($job.Duration)" " INFO" -ForegroundColor White
                Write-WELog " Reports generated: BackupJobReport.html and BackupJobHistory.csv" " INFO" -ForegroundColor Green
            }
            else {
                Write-WELog " `nRefreshing in $WERefreshIntervalSeconds seconds... (Press Ctrl+C to stop)" " INFO" -ForegroundColor Yellow
                Start-Sleep -Seconds $WERefreshIntervalSeconds
            }
        }

        return $jobHistory
    }
    catch {
        Write-Error " Failed to monitor backup job: $_"
        throw
    }
}



try {
    Write-WELog " Getting Recovery Services vault details..." " INFO" -ForegroundColor Cyan
    $vaultInfo = Get-AzureBackupVaultDetails
    $menuOptions = $vaultInfo.MenuOptions
    
    Write-WELog " `nPlease select a vault:" " INFO" -ForegroundColor Yellow
    foreach ($key in $menuOptions.Keys | Sort-Object) {
        $vault = $menuOptions[$key]
        Write-WELog " [$key] $($vault.Name) (ResourceGroup: $($vault.ResourceGroupName), Location: $($vault.Location))" " INFO" -ForegroundColor Cyan
    }
    
    do {
        $selection = Read-Host " `nEnter the number of the vault to use (0-$($menuOptions.Count - 1))"
        $validSelection = $selection -match " ^\d+$" -and $menuOptions.ContainsKey([int]$selection)
        
        if (-not $validSelection) {
            Write-WELog " Invalid selection. Please enter a number between 0 and $($menuOptions.Count - 1)" " INFO" -ForegroundColor Red
        }
    } while (-not $validSelection)

    $selectedVault = $menuOptions[[int]$selection]
    Write-WELog " `nUsing vault: $($selectedVault.Name)" " INFO" -ForegroundColor Green

    # Get list of backup jobs
    $jobs = Get-BackupJobsList -Vault $selectedVault
    if ($jobs) {
      
       ;  $selectedJob = Select-BackupJob -Jobs $jobs
        Write-WELog " `nMonitoring backup job:" " INFO" -ForegroundColor Cyan
        Write-WELog " Job ID: $($selectedJob.JobId)" " INFO" -ForegroundColor Cyan
        Write-WELog " Workload: $($selectedJob.WorkloadName)" " INFO" -ForegroundColor Cyan
        Write-WELog " Operation: $($selectedJob.Operation)" " INFO" -ForegroundColor Cyan
        
       ;  $jobProgress = Watch-AzureBackupJob -JobId $selectedJob.JobId -Vault $selectedVault -RefreshIntervalSeconds 30
        




    }
    else {
        Write-WELog " No backup jobs found in the vault" " INFO" -ForegroundColor Red
    }
}
catch {
    Write-Error $_
    throw
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================