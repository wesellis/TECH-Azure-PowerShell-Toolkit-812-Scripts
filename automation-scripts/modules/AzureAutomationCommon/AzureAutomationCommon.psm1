# ============================================================================
# Module: AzureAutomationCommon
# Author: Wesley Ellis | wes@wesellis.com
# Enhanced common functions for Azure automation
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO", [string]$LogPath, [System.Exception]$Exception)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    if ($Exception) { $logEntry += "`n    Exception: $($Exception.Message)" }
    if ($LogPath) { Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8 }
    $color = switch ($Level) { "ERROR" { "Red" } "WARN" { "Yellow" } "SUCCESS" { "Green" } default { "Cyan" } }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Test-AzureConnection {
    param([string[]]$RequiredModules = @('Az.Accounts', 'Az.Resources'))
    try {
        foreach ($module in $RequiredModules) {
            if (-not (Get-Module $module -ListAvailable)) {
                Write-Log "Required module not found: $module" -Level ERROR
                return $false
            }
        }
        $context = Get-AzContext
        if (-not $context) {
            Write-Log "No Azure context found. Please run Connect-AzAccount" -Level ERROR
            return $false
        }
        Write-Log "✓ Connected to Azure as: $($context.Account.Id)" -Level SUCCESS
        return $true
    } catch {
        Write-Log "Azure connection test failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
        return $false
    }
}

function Invoke-AzureOperation {
    param([scriptblock]$Operation, [string]$OperationName, [int]$MaxRetries = 3, [int]$DelaySeconds = 5)
    $attempt = 0
    do {
        $attempt++
        try {
            Write-Log "Executing $OperationName (Attempt $attempt/$MaxRetries)" -Level INFO
            $result = & $Operation
            Write-Log "✓ $OperationName completed successfully" -Level SUCCESS
            return $result
        } catch {
            Write-Log "$OperationName failed on attempt $attempt`: $($_.Exception.Message)" -Level WARN
            if ($attempt -lt $MaxRetries) {
                Write-Log "Retrying in $DelaySeconds seconds..." -Level INFO
                Start-Sleep -Seconds $DelaySeconds
            } else {
                Write-Log "$OperationName failed after $MaxRetries attempts" -Level ERROR -Exception $_.Exception
                throw
            }
        }
    } while ($attempt -lt $MaxRetries)
}

function Show-Banner {
    param([string]$ScriptName, [string]$Version = "2.0", [string]$Description)
    $banner = @"
╔════════════════════════════════════════════════════════════════════════════════════════════╗
║                              AZURE AUTOMATION SCRIPTS v$Version                              ║
╠════════════════════════════════════════════════════════════════════════════════════════════╣
║ Script: $($ScriptName.PadRight(79)) ║
║ Author: Wesley Ellis | wes@wesellis.com$(' '.PadRight(49)) ║
║ Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")$(' '.PadRight(67)) ║
╚════════════════════════════════════════════════════════════════════════════════════════════╝
"@
    Write-Host $banner -ForegroundColor Cyan
    if ($Description) { Write-Host "Description: $Description" -ForegroundColor Yellow; Write-Host "" }
}

function Write-ProgressStep {
    param([int]$StepNumber, [int]$TotalSteps, [string]$StepName, [string]$Status = "In progress...")
    $percentComplete = [math]::Round(($StepNumber / $TotalSteps) * 100, 0)
    Write-Progress -Activity $StepName -Status $Status -PercentComplete $percentComplete
    Write-Log "[$StepNumber/$TotalSteps] $StepName - $Status" -Level INFO
}

Export-ModuleMember -Function *
