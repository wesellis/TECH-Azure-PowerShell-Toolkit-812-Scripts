#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    1 Azure Vm Restore And Disk Expansion Setup

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 1 Azure Vm Restore And Disk Expansion Setup

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Initialize-RequiredModules {
    

[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
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
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [string[]]$WEModuleNames = @('Az.Accounts', 'Az.Compute', 'Az.RecoveryServices', 'PSWriteHTML')
    )

    $results = @()
    foreach ($module in $WEModuleNames) {
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
            }
        }
        catch {
            $moduleInfo.Status = 'Error'
            $moduleInfo.Message = $_.Exception.Message
        }
        
        $results = $results + [PSCustomObject]$moduleInfo
    }

    # Generate HTML report
    New-HTML -FilePath " .\ModuleInstallationReport.html" -ShowHTML {
        New-HTMLTable -DataTable $results -Title " Module Installation Status Report"
    }

    # Export CSV report
    $results | Export-Csv -Path " .\ModuleInstallationReport.csv" -NoTypeInformation

    # Console output
    $results | Format-Table -AutoSize

    return $results
}


[CmdletBinding()]
function WE-Connect-AzureEnvironment {
    

[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
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
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory = $false)]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
        [Parameter(Mandatory = $false)]
        [string]$WETenantId
    )

    try {
        $connectParams = @{
            ErrorAction = 'Stop'
        }

        if ($WETenantId) {
            $connectParams.TenantId = $WETenantId
        }

        Connect-AzAccount @connectParams

        if ($WESubscriptionId) {
            $subParams = @{
                SubscriptionId = $WESubscriptionId
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
            New-HTMLTable -DataTable @($connectionInfo) -Title " Azure Connection Status Report"
        }

        return $connectionInfo
    }
    catch {
        Write-Error " Failed to connect to Azure: $_"
        throw
    }
}


try {
    Write-WELog " Starting Azure environment setup..." " INFO" -ForegroundColor Cyan
    
    # Initialize modules
    Write-WELog " `nInitializing required modules..." " INFO" -ForegroundColor Yellow
   ;  $moduleResults = Initialize-RequiredModules
    
    # Connect to Azure
    Write-WELog " `nConnecting to Azure..." " INFO" -ForegroundColor Yellow
   ;  $connectionInfo = Connect-AzureEnvironment
    
    Write-WELog " `nSetup completed successfully!" " INFO" -ForegroundColor Green
    Write-WELog " Connection established to subscription: $($connectionInfo.SubscriptionName)" " INFO" -ForegroundColor Green
}
catch {
    Write-WELog " Error during setup: $_" " INFO" -ForegroundColor Red
    throw
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
