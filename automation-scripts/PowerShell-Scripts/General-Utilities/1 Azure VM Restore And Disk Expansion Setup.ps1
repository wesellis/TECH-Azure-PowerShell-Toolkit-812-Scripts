<#
.SYNOPSIS
    Azure VM Restore And Disk Expansion Setup

.DESCRIPTION
    Azure VM Restore And Disk Expansion Setup operation
#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Initialize-RequiredModules {
function Write-Host {
    [CmdletBinding()]
param(
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
param(
        [string[]]$ModuleNames = @('Az.Accounts', 'Az.Compute', 'Az.RecoveryServices', 'PSWriteHTML')
    )
    $results = @()
    foreach ($module in $ModuleNames) {
        $moduleInfo = @{
            ModuleName = $module
            Status = 'Unknown'
            Message = ''
        }
        try {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                $installParams = @{
                    Name = $module
                    Force = $true
                    AllowClobber = $true
                    ErrorAction = 'Stop'
                }
                Install-Module @installParams
                $moduleInfo.Status = 'Installed'
                $moduleInfo.Message = 'Module was installed successfully'
            } else {
                $moduleInfo.Status = 'Present'
                $moduleInfo.Message = 'Module was already installed'
            }
            $importParams = @{
                Name = $module
                ErrorAction = 'Stop'
                DisableNameChecking = $true
            }
            Import-Module @importParams
            if ($moduleInfo.Status -eq 'Unknown') {
                $moduleInfo.Status = 'Imported'
                $moduleInfo.Message = 'Module was imported successfully'

} catch {
            $moduleInfo.Status = 'Error'
            $moduleInfo.Message = $_.Exception.Message
        }
        $results = $results + [PSCustomObject]$moduleInfo
    }
    # Generate HTML report
    New-HTML -FilePath " .\ModuleInstallationReport.html" -ShowHTML {
        New-HTMLTable -DataTable $results -Title "Module Installation Status Report"
    }
    # Export CSV report
    $results | Export-Csv -Path " .\ModuleInstallationReport.csv" -NoTypeInformation
    # Console output
    $results | Format-Table -AutoSize
    return $results
}
function Connect-AzureEnvironment {
function Write-Host {
    [CmdletBinding()]
param(
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
param(
        [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
        [Parameter(Mandatory = $false)]
        [string]$TenantId
    )
    try {
        $connectParams = @{
            ErrorAction = 'Stop'
        }
        if ($TenantId) {
            $connectParams.TenantId = $TenantId
        }
        Connect-AzAccount @connectParams
        if ($SubscriptionId) {
            $subParams = @{
                SubscriptionId = $SubscriptionId
                ErrorAction = 'Stop'
            }
            Set-AzContext -ErrorAction Stop @subParams
        }
        $currentContext = Get-AzContext -ErrorAction Stop
        $connectionInfo = [PSCustomObject]@{
            SubscriptionName = $currentContext.Subscription.Name
            SubscriptionId = $currentContext.Subscription.Id
            TenantId = $currentContext.Tenant.Id
            AccountName = $currentContext.Account.Id
            Environment = $currentContext.Environment.Name
        }
        # Generate connection report
        New-HTML -FilePath " .\AzureConnectionReport.html" -ShowHTML {
            New-HTMLTable -DataTable @($connectionInfo) -Title "Azure Connection Status Report"
        }
        return $connectionInfo
    }
    catch {
        Write-Error "Failed to connect to Azure: $_"
        throw
    }
}
try {
    Write-Host "Starting Azure environment setup..." -ForegroundColor Cyan
    # Initialize modules
    Write-Host " `nInitializing required modules..." -ForegroundColor Yellow
$moduleResults = Initialize-RequiredModules
    # Connect to Azure
    Write-Host " `nConnecting to Azure..." -ForegroundColor Yellow
$connectionInfo = Connect-AzureEnvironment
    Write-Host " `nSetup completed successfully!" -ForegroundColor Green
    Write-Host "Connection established to subscription: $($connectionInfo.SubscriptionName)" -ForegroundColor Green
}
catch {
    Write-Host "Error during setup: $_" -ForegroundColor Red
    throw
}

