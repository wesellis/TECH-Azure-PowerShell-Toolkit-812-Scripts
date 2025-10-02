#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage containers

.DESCRIPTION
    Manage containers
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$ContainerGroupName
)
Write-Output "Monitoring Container Instance: $ContainerGroupName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "============================================"
$ContainerGroup = Get-AzContainerGroup -ResourceGroupName $ResourceGroupName -Name $ContainerGroupName
Write-Output "Container Group Information:"
Write-Output "Name: $($ContainerGroup.Name)"
Write-Output "Location: $($ContainerGroup.Location)"
Write-Output "Provisioning State: $($ContainerGroup.ProvisioningState)"
Write-Output "OS Type: $($ContainerGroup.OsType)"
Write-Output "Restart Policy: $($ContainerGroup.RestartPolicy)"
Write-Output "IP Address: $($ContainerGroup.IpAddress)"
Write-Output "FQDN: $($ContainerGroup.Fqdn)"
if ($ContainerGroup.IpAddressPorts) {
    Write-Output "`nExposed Ports:"
    foreach ($Port in $ContainerGroup.IpAddressPorts) {
        Write-Output "  - Port: $($Port.Port) ($($Port.Protocol))"
    }
}
Write-Output "`nContainer Details:"
foreach ($Container in $ContainerGroup.Containers) {
    Write-Output "  - Container: $($Container.Name)"
    Write-Output "    Image: $($Container.Image)"
    Write-Output "    CPU Requests: $($Container.RequestCpu)"
    Write-Output "    Memory Requests: $($Container.RequestMemoryInGb) GB"
    if ($Container.LimitsMemoryInGb) {
        Write-Output "    Memory Limits: $($Container.LimitsMemoryInGb) GB"
    }
    if ($Container.LimitsCpu) {
        Write-Output "    CPU Limits: $($Container.LimitsCpu)"
    }
    if ($Container.InstanceViewCurrentState) {
        Write-Output "    Current State: $($Container.InstanceViewCurrentState.State)"
        Write-Output "    Start Time: $($Container.InstanceViewCurrentState.StartTime)"
        if ($Container.InstanceViewCurrentState.ExitCode) {
            Write-Output "    Exit Code: $($Container.InstanceViewCurrentState.ExitCode)"
        }
    }
    if ($Container.InstanceViewPreviousState) {
        Write-Output "    Previous State: $($Container.InstanceViewPreviousState.State)"
        if ($Container.InstanceViewPreviousState.ExitCode) {
            Write-Output "    Previous Exit Code: $($Container.InstanceViewPreviousState.ExitCode)"
        }
    }
    Write-Output "    Restart Count: $($Container.InstanceViewRestartCount)"
    if ($Container.InstanceViewEvents) {
        Write-Output "    Recent Events:"
        $RecentEvents = $Container.InstanceViewEvents | Sort-Object LastTimestamp -Descending | Select-Object -First 3
        foreach ($Event in $RecentEvents) {
            Write-Output "      $($Event.LastTimestamp): $($Event.Message)"
        }
    }
    if ($Container.EnvironmentVariables) {
        Write-Output "    Environment Variables: $($Container.EnvironmentVariables.Count) configured"
        $SafeEnvVars = $Container.EnvironmentVariables | Where-Object {
            $_.Name -notlike "*KEY*" -and
            $_.Name -notlike "*SECRET*" -and
            $_.Name -notlike "*PASSWORD*"
        }
        if ($SafeEnvVars) {
            Write-Output "      Non-sensitive variables: $($SafeEnvVars.Name -join ', ')"
        }
    }
    if ($Container.Ports) {
        Write-Output "    Container Ports:"
        foreach ($Port in $Container.Ports) {
            Write-Output "      - $($Port.Port)/$($Port.Protocol)"
        }
    }
    Write-Output "    ---"
}
if ($ContainerGroup.Volumes) {
    Write-Output "`nVolumes:"
    foreach ($Volume in $ContainerGroup.Volumes) {
        Write-Output "  - Volume: $($Volume.Name)"
        if ($Volume.AzureFile) {
            Write-Output "    Type: Azure File Share"
            Write-Output "    Share Name: $($Volume.AzureFile.ShareName)"
            Write-Output "    Storage Account: $($Volume.AzureFile.StorageAccountName)"
        } elseif ($Volume.EmptyDir) {
            Write-Output "    Type: Empty Directory"
        } elseif ($Volume.Secret) {
            Write-Output "    Type: Secret"
        }
    }
}
Write-Output "`nRecent Container Logs:"
foreach ($Container in $ContainerGroup.Containers) {
    try {
        Write-Output "Container: $($Container.Name)"
        $Logs = Get-AzContainerInstanceLog -ResourceGroupName $ResourceGroupName -ContainerGroupName $ContainerGroupName -ContainerName $Container.Name -Tail 10
        if ($Logs) {
            $LogLines = $Logs -split "`n" | Select-Object -Last 5
            foreach ($Line in $LogLines) {
                if ($Line.Trim()) {
                    Write-Output "    $Line"
                }
            }
        } else {
            Write-Output "    No logs available"
        }
    } catch {
        Write-Output "    Unable to retrieve logs: $($_.Exception.Message)"
    }
    Write-Output "    ---"
}
if ($ContainerGroup.IpAddress -and $ContainerGroup.IpAddressPorts) {
    Write-Output "`nAccess Information:"
    foreach ($Port in $ContainerGroup.IpAddressPorts) {
        $Protocol = if ($Port.Port -eq 443) { "https" } else { "http" }
        Write-Output "  $Protocol`://$($ContainerGroup.IpAddress):$($Port.Port)"
    }
    if ($ContainerGroup.Fqdn -and $ContainerGroup.IpAddressPorts) {
        Write-Output "`nFQDN Access:"
        foreach ($Port in $ContainerGroup.IpAddressPorts) {
            $Protocol = if ($Port.Port -eq 443) { "https" } else { "http" }
            Write-Output "  $Protocol`://$($ContainerGroup.Fqdn):$($Port.Port)"
        }
    }
}
Write-Output "`nContainer Instance monitoring completed at $(Get-Date)"



