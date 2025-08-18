<#
.SYNOPSIS
    Azure Containerinstance Status Monitor

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
    We Enhanced Azure Containerinstance Status Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



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
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [string]$WEContainerGroupName
)

Write-WELog " Monitoring Container Instance: $WEContainerGroupName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"


$WEContainerGroup = Get-AzContainerGroup -ResourceGroupName $WEResourceGroupName -Name $WEContainerGroupName

Write-WELog " Container Group Information:" " INFO"
Write-WELog "  Name: $($WEContainerGroup.Name)" " INFO"
Write-WELog "  Location: $($WEContainerGroup.Location)" " INFO"
Write-WELog "  Provisioning State: $($WEContainerGroup.ProvisioningState)" " INFO"
Write-WELog "  OS Type: $($WEContainerGroup.OsType)" " INFO"
Write-WELog "  Restart Policy: $($WEContainerGroup.RestartPolicy)" " INFO"
Write-WELog "  IP Address: $($WEContainerGroup.IpAddress)" " INFO"
Write-WELog "  FQDN: $($WEContainerGroup.Fqdn)" " INFO"


if ($WEContainerGroup.IpAddressPorts) {
    Write-WELog " `nExposed Ports:" " INFO"
    foreach ($WEPort in $WEContainerGroup.IpAddressPorts) {
        Write-WELog "  - Port: $($WEPort.Port) ($($WEPort.Protocol))" " INFO"
    }
}


Write-WELog " `nContainer Details:" " INFO"
foreach ($WEContainer in $WEContainerGroup.Containers) {
    Write-WELog "  - Container: $($WEContainer.Name)" " INFO"
    Write-WELog "    Image: $($WEContainer.Image)" " INFO"
    Write-WELog "    CPU Requests: $($WEContainer.RequestCpu)" " INFO"
    Write-WELog "    Memory Requests: $($WEContainer.RequestMemoryInGb) GB" " INFO"
    
    if ($WEContainer.LimitsMemoryInGb) {
        Write-WELog "    Memory Limits: $($WEContainer.LimitsMemoryInGb) GB" " INFO"
    }
    if ($WEContainer.LimitsCpu) {
        Write-WELog "    CPU Limits: $($WEContainer.LimitsCpu)" " INFO"
    }
    
    # Container state
    if ($WEContainer.InstanceViewCurrentState) {
        Write-WELog "    Current State: $($WEContainer.InstanceViewCurrentState.State)" " INFO"
        Write-WELog "    Start Time: $($WEContainer.InstanceViewCurrentState.StartTime)" " INFO"
        if ($WEContainer.InstanceViewCurrentState.ExitCode) {
            Write-WELog "    Exit Code: $($WEContainer.InstanceViewCurrentState.ExitCode)" " INFO"
        }
    }
    
    # Previous state (if any)
    if ($WEContainer.InstanceViewPreviousState) {
        Write-WELog "    Previous State: $($WEContainer.InstanceViewPreviousState.State)" " INFO"
        if ($WEContainer.InstanceViewPreviousState.ExitCode) {
            Write-WELog "    Previous Exit Code: $($WEContainer.InstanceViewPreviousState.ExitCode)" " INFO"
        }
    }
    
    # Restart count
    Write-WELog "    Restart Count: $($WEContainer.InstanceViewRestartCount)" " INFO"
    
    # Events
    if ($WEContainer.InstanceViewEvents) {
        Write-WELog "    Recent Events:" " INFO"
        $WERecentEvents = $WEContainer.InstanceViewEvents | Sort-Object LastTimestamp -Descending | Select-Object -First 3
        foreach ($WEEvent in $WERecentEvents) {
            Write-WELog "      $($WEEvent.LastTimestamp): $($WEEvent.Message)" " INFO"
        }
    }
    
    # Environment variables (without values for security)
    if ($WEContainer.EnvironmentVariables) {
        Write-WELog "    Environment Variables: $($WEContainer.EnvironmentVariables.Count) configured" " INFO"
        $WESafeEnvVars = $WEContainer.EnvironmentVariables | Where-Object { 
            $_.Name -notlike " *KEY*" -and 
            $_.Name -notlike " *SECRET*" -and 
            $_.Name -notlike " *PASSWORD*" 
        }
        if ($WESafeEnvVars) {
            Write-WELog "      Non-sensitive variables: $($WESafeEnvVars.Name -join ', ')" " INFO"
        }
    }
    
    # Ports
    if ($WEContainer.Ports) {
        Write-WELog "    Container Ports:" " INFO"
        foreach ($WEPort in $WEContainer.Ports) {
            Write-WELog "      - $($WEPort.Port)/$($WEPort.Protocol)" " INFO"
        }
    }
    
    Write-WELog "    ---" " INFO"
}


if ($WEContainerGroup.Volumes) {
    Write-WELog " `nVolumes:" " INFO"
    foreach ($WEVolume in $WEContainerGroup.Volumes) {
        Write-WELog "  - Volume: $($WEVolume.Name)" " INFO"
        if ($WEVolume.AzureFile) {
            Write-WELog "    Type: Azure File Share" " INFO"
            Write-WELog "    Share Name: $($WEVolume.AzureFile.ShareName)" " INFO"
            Write-WELog "    Storage Account: $($WEVolume.AzureFile.StorageAccountName)" " INFO"
        } elseif ($WEVolume.EmptyDir) {
            Write-WELog "    Type: Empty Directory" " INFO"
        } elseif ($WEVolume.Secret) {
            Write-WELog "    Type: Secret" " INFO"
        }
    }
}


Write-WELog " `nRecent Container Logs:" " INFO"
foreach ($WEContainer in $WEContainerGroup.Containers) {
    try {
        Write-WELog "  Container: $($WEContainer.Name)" " INFO"
        $WELogs = Get-AzContainerInstanceLog -ResourceGroupName $WEResourceGroupName -ContainerGroupName $WEContainerGroupName -ContainerName $WEContainer.Name -Tail 10
        if ($WELogs) {
            $WELogLines = $WELogs -split " `n" | Select-Object -Last 5
            foreach ($WELine in $WELogLines) {
                if ($WELine.Trim()) {
                    Write-WELog "    $WELine" " INFO"
                }
            }
        } else {
            Write-WELog "    No logs available" " INFO"
        }
    } catch {
        Write-WELog "    Unable to retrieve logs: $($_.Exception.Message)" " INFO"
    }
    Write-WELog "    ---" " INFO"
}


if ($WEContainerGroup.IpAddress -and $WEContainerGroup.IpAddressPorts) {
    Write-WELog " `nAccess Information:" " INFO"
    foreach ($WEPort in $WEContainerGroup.IpAddressPorts) {
       ;  $WEProtocol = if ($WEPort.Port -eq 443) { " https" } else { " http" }
        Write-WELog "  $WEProtocol`://$($WEContainerGroup.IpAddress):$($WEPort.Port)" " INFO"
    }
    
    if ($WEContainerGroup.Fqdn -and $WEContainerGroup.IpAddressPorts) {
        Write-WELog " `nFQDN Access:" " INFO"
        foreach ($WEPort in $WEContainerGroup.IpAddressPorts) {
           ;  $WEProtocol = if ($WEPort.Port -eq 443) { " https" } else { " http" }
            Write-WELog "  $WEProtocol`://$($WEContainerGroup.Fqdn):$($WEPort.Port)" " INFO"
        }
    }
}

Write-WELog " `nContainer Instance monitoring completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================