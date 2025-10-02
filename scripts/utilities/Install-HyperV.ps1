#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Install Hyper-V features on Windows

.DESCRIPTION
    Installs Hyper-V role and management tools on Windows. This script enables all Hyper-V features
    including the hypervisor, management tools, and PowerShell module.

.PARAMETER IncludeManagementTools
    Include Hyper-V management tools and PowerShell module

.PARAMETER Force
    Force installation without confirmation prompts

.EXAMPLE
    .\Install-HyperV.ps1
    Installs Hyper-V with default settings

.EXAMPLE
    .\Install-HyperV.ps1 -IncludeManagementTools -Force
    Installs Hyper-V with management tools, no confirmation prompts

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0
    Requires: Windows 10/11 Pro/Enterprise or Windows Server
    Requires: Administrator privileges
#>

[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter()]
    [switch]$IncludeManagementTools = $true,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

begin {
    Write-Verbose "Starting Hyper-V installation process"
    $OsInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $SupportedVersions = @('10.0', '11.0')

    if ($OsInfo.Version.Split('.')[0] -notin $SupportedVersions.Split('.')[0]) {
        throw "Hyper-V requires Windows 10/11 or Windows Server 2016+"
    }
}

process {
    try {
        Write-Verbose "Checking current Hyper-V feature status"
        $HyperVFeatures = Get-WindowsOptionalFeature -Online -FeatureName *hyper-v*
        $FeaturesToEnable = @(
            'Microsoft-Hyper-V-All'
        )

        if ($IncludeManagementTools) {
            $FeaturesToEnable += @(
                'Microsoft-Hyper-V-Management-PowerShell',
                'Microsoft-Hyper-V-Tools-All'
            )
        }
        $results = @()

        foreach ($FeatureName in $FeaturesToEnable) {
            $feature = $HyperVFeatures | Where-Object { $_.FeatureName -eq $FeatureName }

            if ($feature.State -eq 'Enabled') {
                Write-Verbose "Feature $FeatureName is already enabled"
                $results += [PSCustomObject]@{
                    FeatureName = $FeatureName
                    Status = 'AlreadyEnabled'
                    RestartRequired = $false
                }
                continue
            }

            if ($PSCmdlet.ShouldProcess($FeatureName, "Enable Windows Feature")) {
                Write-Verbose "Enabling feature: $FeatureName"
                $EnableResult = Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -All
                $results += [PSCustomObject]@{
                    FeatureName = $FeatureName
                    Status = if ($EnableResult.RestartNeeded) { 'EnabledRestartRequired' } else { 'Enabled' }
                    RestartRequired = $EnableResult.RestartNeeded
                }
            }
        }

        Write-Output "Hyper-V Installation Summary:"
        $results | Format-Table -AutoSize

        if ($results | Where-Object { $_.RestartRequired }) {
            Write-Warning "A restart is required to complete the Hyper-V installation"

            if ($Force) {
                Write-Output "Restarting computer in 10 seconds..."
                Start-Sleep -Seconds 10
                Restart-Computer -Force
            } else {
                $restart = Read-Host "Restart now? (Y/N)"
                if ($restart -eq 'Y') {
                    Restart-Computer
                }
            }
        }

        return $results

    } catch {
        Write-Error "Failed to install Hyper-V: $($_.Exception.Message)"
        throw
    }
}

end {
    Write-Verbose "Hyper-V installation process completed"
}