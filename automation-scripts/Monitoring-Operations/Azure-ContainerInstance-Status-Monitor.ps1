# ============================================================================
# Script Name: Azure Container Instance Status Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Container Instance status, resource usage, and container logs
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$ContainerGroupName
)

Write-Information "Monitoring Container Instance: $ContainerGroupName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get Container Group details
$ContainerGroup = Get-AzContainerGroup -ResourceGroupName $ResourceGroupName -Name $ContainerGroupName

Write-Information "Container Group Information:"
Write-Information "  Name: $($ContainerGroup.Name)"
Write-Information "  Location: $($ContainerGroup.Location)"
Write-Information "  Provisioning State: $($ContainerGroup.ProvisioningState)"
Write-Information "  OS Type: $($ContainerGroup.OsType)"
Write-Information "  Restart Policy: $($ContainerGroup.RestartPolicy)"
Write-Information "  IP Address: $($ContainerGroup.IpAddress)"
Write-Information "  FQDN: $($ContainerGroup.Fqdn)"

# Network information
if ($ContainerGroup.IpAddressPorts) {
    Write-Information "`nExposed Ports:"
    foreach ($Port in $ContainerGroup.IpAddressPorts) {
        Write-Information "  - Port: $($Port.Port) ($($Port.Protocol))"
    }
}

# Container details
Write-Information "`nContainer Details:"
foreach ($Container in $ContainerGroup.Containers) {
    Write-Information "  - Container: $($Container.Name)"
    Write-Information "    Image: $($Container.Image)"
    Write-Information "    CPU Requests: $($Container.RequestCpu)"
    Write-Information "    Memory Requests: $($Container.RequestMemoryInGb) GB"
    
    if ($Container.LimitsMemoryInGb) {
        Write-Information "    Memory Limits: $($Container.LimitsMemoryInGb) GB"
    }
    if ($Container.LimitsCpu) {
        Write-Information "    CPU Limits: $($Container.LimitsCpu)"
    }
    
    # Container state
    if ($Container.InstanceViewCurrentState) {
        Write-Information "    Current State: $($Container.InstanceViewCurrentState.State)"
        Write-Information "    Start Time: $($Container.InstanceViewCurrentState.StartTime)"
        if ($Container.InstanceViewCurrentState.ExitCode) {
            Write-Information "    Exit Code: $($Container.InstanceViewCurrentState.ExitCode)"
        }
    }
    
    # Previous state (if any)
    if ($Container.InstanceViewPreviousState) {
        Write-Information "    Previous State: $($Container.InstanceViewPreviousState.State)"
        if ($Container.InstanceViewPreviousState.ExitCode) {
            Write-Information "    Previous Exit Code: $($Container.InstanceViewPreviousState.ExitCode)"
        }
    }
    
    # Restart count
    Write-Information "    Restart Count: $($Container.InstanceViewRestartCount)"
    
    # Events
    if ($Container.InstanceViewEvents) {
        Write-Information "    Recent Events:"
        $RecentEvents = $Container.InstanceViewEvents | Sort-Object LastTimestamp -Descending | Select-Object -First 3
        foreach ($Event in $RecentEvents) {
            Write-Information "      $($Event.LastTimestamp): $($Event.Message)"
        }
    }
    
    # Environment variables (without values for security)
    if ($Container.EnvironmentVariables) {
        Write-Information "    Environment Variables: $($Container.EnvironmentVariables.Count) configured"
        $SafeEnvVars = $Container.EnvironmentVariables | Where-Object { 
            $_.Name -notlike "*KEY*" -and 
            $_.Name -notlike "*SECRET*" -and 
            $_.Name -notlike "*PASSWORD*" 
        }
        if ($SafeEnvVars) {
            Write-Information "      Non-sensitive variables: $($SafeEnvVars.Name -join ', ')"
        }
    }
    
    # Ports
    if ($Container.Ports) {
        Write-Information "    Container Ports:"
        foreach ($Port in $Container.Ports) {
            Write-Information "      - $($Port.Port)/$($Port.Protocol)"
        }
    }
    
    Write-Information "    ---"
}

# Volume mounts
if ($ContainerGroup.Volumes) {
    Write-Information "`nVolumes:"
    foreach ($Volume in $ContainerGroup.Volumes) {
        Write-Information "  - Volume: $($Volume.Name)"
        if ($Volume.AzureFile) {
            Write-Information "    Type: Azure File Share"
            Write-Information "    Share Name: $($Volume.AzureFile.ShareName)"
            Write-Information "    Storage Account: $($Volume.AzureFile.StorageAccountName)"
        } elseif ($Volume.EmptyDir) {
            Write-Information "    Type: Empty Directory"
        } elseif ($Volume.Secret) {
            Write-Information "    Type: Secret"
        }
    }
}

# Try to get recent logs (last 50 lines)
Write-Information "`nRecent Container Logs:"
foreach ($Container in $ContainerGroup.Containers) {
    try {
        Write-Information "  Container: $($Container.Name)"
        $Logs = Get-AzContainerInstanceLog -ResourceGroupName $ResourceGroupName -ContainerGroupName $ContainerGroupName -ContainerName $Container.Name -Tail 10
        if ($Logs) {
            $LogLines = $Logs -split "`n" | Select-Object -Last 5
            foreach ($Line in $LogLines) {
                if ($Line.Trim()) {
                    Write-Information "    $Line"
                }
            }
        } else {
            Write-Information "    No logs available"
        }
    } catch {
        Write-Information "    Unable to retrieve logs: $($_.Exception.Message)"
    }
    Write-Information "    ---"
}

# Access URLs
if ($ContainerGroup.IpAddress -and $ContainerGroup.IpAddressPorts) {
    Write-Information "`nAccess Information:"
    foreach ($Port in $ContainerGroup.IpAddressPorts) {
        $Protocol = if ($Port.Port -eq 443) { "https" } else { "http" }
        Write-Information "  $Protocol`://$($ContainerGroup.IpAddress):$($Port.Port)"
    }
    
    if ($ContainerGroup.Fqdn -and $ContainerGroup.IpAddressPorts) {
        Write-Information "`nFQDN Access:"
        foreach ($Port in $ContainerGroup.IpAddressPorts) {
            $Protocol = if ($Port.Port -eq 443) { "https" } else { "http" }
            Write-Information "  $Protocol`://$($ContainerGroup.Fqdn):$($Port.Port)"
        }
    }
}

Write-Information "`nContainer Instance monitoring completed at $(Get-Date)"
