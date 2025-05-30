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

Write-Host "Monitoring Container Instance: $ContainerGroupName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get Container Group details
$ContainerGroup = Get-AzContainerGroup -ResourceGroupName $ResourceGroupName -Name $ContainerGroupName

Write-Host "Container Group Information:"
Write-Host "  Name: $($ContainerGroup.Name)"
Write-Host "  Location: $($ContainerGroup.Location)"
Write-Host "  Provisioning State: $($ContainerGroup.ProvisioningState)"
Write-Host "  OS Type: $($ContainerGroup.OsType)"
Write-Host "  Restart Policy: $($ContainerGroup.RestartPolicy)"
Write-Host "  IP Address: $($ContainerGroup.IpAddress)"
Write-Host "  FQDN: $($ContainerGroup.Fqdn)"

# Network information
if ($ContainerGroup.IpAddressPorts) {
    Write-Host "`nExposed Ports:"
    foreach ($Port in $ContainerGroup.IpAddressPorts) {
        Write-Host "  - Port: $($Port.Port) ($($Port.Protocol))"
    }
}

# Container details
Write-Host "`nContainer Details:"
foreach ($Container in $ContainerGroup.Containers) {
    Write-Host "  - Container: $($Container.Name)"
    Write-Host "    Image: $($Container.Image)"
    Write-Host "    CPU Requests: $($Container.RequestCpu)"
    Write-Host "    Memory Requests: $($Container.RequestMemoryInGb) GB"
    
    if ($Container.LimitsMemoryInGb) {
        Write-Host "    Memory Limits: $($Container.LimitsMemoryInGb) GB"
    }
    if ($Container.LimitsCpu) {
        Write-Host "    CPU Limits: $($Container.LimitsCpu)"
    }
    
    # Container state
    if ($Container.InstanceViewCurrentState) {
        Write-Host "    Current State: $($Container.InstanceViewCurrentState.State)"
        Write-Host "    Start Time: $($Container.InstanceViewCurrentState.StartTime)"
        if ($Container.InstanceViewCurrentState.ExitCode) {
            Write-Host "    Exit Code: $($Container.InstanceViewCurrentState.ExitCode)"
        }
    }
    
    # Previous state (if any)
    if ($Container.InstanceViewPreviousState) {
        Write-Host "    Previous State: $($Container.InstanceViewPreviousState.State)"
        if ($Container.InstanceViewPreviousState.ExitCode) {
            Write-Host "    Previous Exit Code: $($Container.InstanceViewPreviousState.ExitCode)"
        }
    }
    
    # Restart count
    Write-Host "    Restart Count: $($Container.InstanceViewRestartCount)"
    
    # Events
    if ($Container.InstanceViewEvents) {
        Write-Host "    Recent Events:"
        $RecentEvents = $Container.InstanceViewEvents | Sort-Object LastTimestamp -Descending | Select-Object -First 3
        foreach ($Event in $RecentEvents) {
            Write-Host "      $($Event.LastTimestamp): $($Event.Message)"
        }
    }
    
    # Environment variables (without values for security)
    if ($Container.EnvironmentVariables) {
        Write-Host "    Environment Variables: $($Container.EnvironmentVariables.Count) configured"
        $SafeEnvVars = $Container.EnvironmentVariables | Where-Object { 
            $_.Name -notlike "*KEY*" -and 
            $_.Name -notlike "*SECRET*" -and 
            $_.Name -notlike "*PASSWORD*" 
        }
        if ($SafeEnvVars) {
            Write-Host "      Non-sensitive variables: $($SafeEnvVars.Name -join ', ')"
        }
    }
    
    # Ports
    if ($Container.Ports) {
        Write-Host "    Container Ports:"
        foreach ($Port in $Container.Ports) {
            Write-Host "      - $($Port.Port)/$($Port.Protocol)"
        }
    }
    
    Write-Host "    ---"
}

# Volume mounts
if ($ContainerGroup.Volumes) {
    Write-Host "`nVolumes:"
    foreach ($Volume in $ContainerGroup.Volumes) {
        Write-Host "  - Volume: $($Volume.Name)"
        if ($Volume.AzureFile) {
            Write-Host "    Type: Azure File Share"
            Write-Host "    Share Name: $($Volume.AzureFile.ShareName)"
            Write-Host "    Storage Account: $($Volume.AzureFile.StorageAccountName)"
        } elseif ($Volume.EmptyDir) {
            Write-Host "    Type: Empty Directory"
        } elseif ($Volume.Secret) {
            Write-Host "    Type: Secret"
        }
    }
}

# Try to get recent logs (last 50 lines)
Write-Host "`nRecent Container Logs:"
foreach ($Container in $ContainerGroup.Containers) {
    try {
        Write-Host "  Container: $($Container.Name)"
        $Logs = Get-AzContainerInstanceLog -ResourceGroupName $ResourceGroupName -ContainerGroupName $ContainerGroupName -ContainerName $Container.Name -Tail 10
        if ($Logs) {
            $LogLines = $Logs -split "`n" | Select-Object -Last 5
            foreach ($Line in $LogLines) {
                if ($Line.Trim()) {
                    Write-Host "    $Line"
                }
            }
        } else {
            Write-Host "    No logs available"
        }
    } catch {
        Write-Host "    Unable to retrieve logs: $($_.Exception.Message)"
    }
    Write-Host "    ---"
}

# Access URLs
if ($ContainerGroup.IpAddress -and $ContainerGroup.IpAddressPorts) {
    Write-Host "`nAccess Information:"
    foreach ($Port in $ContainerGroup.IpAddressPorts) {
        $Protocol = if ($Port.Port -eq 443) { "https" } else { "http" }
        Write-Host "  $Protocol`://$($ContainerGroup.IpAddress):$($Port.Port)"
    }
    
    if ($ContainerGroup.Fqdn -and $ContainerGroup.IpAddressPorts) {
        Write-Host "`nFQDN Access:"
        foreach ($Port in $ContainerGroup.IpAddressPorts) {
            $Protocol = if ($Port.Port -eq 443) { "https" } else { "http" }
            Write-Host "  $Protocol`://$($ContainerGroup.Fqdn):$($Port.Port)"
        }
    }
}

Write-Host "`nContainer Instance monitoring completed at $(Get-Date)"
