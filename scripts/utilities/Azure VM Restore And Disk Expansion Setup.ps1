#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure VM Restore And Disk Expansion Setup

.DESCRIPTION
    Azure VM Restore And Disk Expansion Setup operation


    Author: Wes Ellis (wes@wesellis.com)
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Log {
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
        [string[]]$ModuleNames = @('Az.Accounts', 'Az.Compute', 'Az.RecoveryServices', 'PSWriteHTML')
    )
    $results = @()
    foreach ($module in $ModuleNames) {
    $ModuleInfo = @{
            ModuleName = $module
            Status = 'Unknown'
            Message = ''
        }
        try {
            if (-not (Get-Module -ListAvailable -Name $module)) {
    $InstallParams = @{
                    Name = $module
                    Force = $true
                    AllowClobber = $true
                    ErrorAction = 'Stop'
                }
                Install-Module @installParams
    $ModuleInfo.Status = 'Installed'
    $ModuleInfo.Message = 'Module was installed successfully'
            } else {
    $ModuleInfo.Status = 'Present'
    $ModuleInfo.Message = 'Module was already installed'
            }
    $ImportParams = @{
                Name = $module
                ErrorAction = 'Stop'
                DisableNameChecking = $true
            }
            Import-Module @importParams
            if ($ModuleInfo.Status -eq 'Unknown') {
    $ModuleInfo.Status = 'Imported'
    $ModuleInfo.Message = 'Module was imported successfully'

} catch {
    $ModuleInfo.Status = 'Error'
    $ModuleInfo.Message = $_.Exception.Message
        }
    $results = $results + [PSCustomObject]$ModuleInfo
    }
    New-HTML -FilePath " .\ModuleInstallationReport.html" -ShowHTML {
        New-HTMLTable -DataTable $results -Title "Module Installation Status Report"
    }
    $results | Export-Csv -Path " .\ModuleInstallationReport.csv" -NoTypeInformation
    $results | Format-Table -AutoSize
    return $results
}
function Connect-AzureEnvironment {
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
        [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    $SubscriptionId,
        [Parameter(Mandatory = $false)]
        $TenantId
    )
    try {
    $ConnectParams = @{
            ErrorAction = 'Stop'
        }
        if ($TenantId) {
    $ConnectParams.TenantId = $TenantId
        }
        Connect-AzAccount @connectParams
        if ($SubscriptionId) {
    $SubParams = @{
                SubscriptionId = $SubscriptionId
                ErrorAction = 'Stop'
            }
            Set-AzContext -ErrorAction Stop @subParams
        }
    $CurrentContext = Get-AzContext -ErrorAction Stop
    $ConnectionInfo = [PSCustomObject]@{
            SubscriptionName = $CurrentContext.Subscription.Name
            SubscriptionId = $CurrentContext.Subscription.Id
            TenantId = $CurrentContext.Tenant.Id
            AccountName = $CurrentContext.Account.Id
            Environment = $CurrentContext.Environment.Name
        }
        New-HTML -FilePath " .\AzureConnectionReport.html" -ShowHTML {
            New-HTMLTable -DataTable @($ConnectionInfo) -Title "Azure Connection Status Report"
        }
        return $ConnectionInfo
    }
    catch {
        Write-Error "Failed to connect to Azure: $_"
        throw
    }
}
try {
    Write-Output "Starting Azure environment setup..." # Color: $2
    Write-Output " `nInitializing required modules..." # Color: $2
    $ModuleResults = Initialize-RequiredModules
    Write-Output " `nConnecting to Azure..." # Color: $2
    $ConnectionInfo = Connect-AzureEnvironment
    Write-Output " `nSetup completed successfully!" # Color: $2
    Write-Output "Connection established to subscription: $($ConnectionInfo.SubscriptionName)" # Color: $2
}
catch {
    Write-Output "Error during setup: $_" # Color: $2
    throw`n}
