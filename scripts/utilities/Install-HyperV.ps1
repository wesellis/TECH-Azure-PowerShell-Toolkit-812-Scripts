#Requires -Version 7.0
#Requires -RunAsAdministrator

<#`n.SYNOPSIS
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

begin {
    Write-Verbose "Starting Hyper-V installation process"

    # Check if running on supported OS
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $supportedVersions = @('10.0', '11.0')

    if ($osInfo.Version.Split('.')[0] -notin $supportedVersions.Split('.')[0]) {
        throw "Hyper-V requires Windows 10/11 or Windows Server 2016+"
    }
}

process {
    try {
        # Check current Hyper-V status
        Write-Verbose "Checking current Hyper-V feature status"
        $hyperVFeatures = Get-WindowsOptionalFeature -Online -FeatureName *hyper-v*

        $featuresToEnable = @(
            'Microsoft-Hyper-V-All'
        )

        if ($IncludeManagementTools) {
            $featuresToEnable += @(
                'Microsoft-Hyper-V-Management-PowerShell',
                'Microsoft-Hyper-V-Tools-All'
            )
        }

        $results = @()

        foreach ($featureName in $featuresToEnable) {
            $feature = $hyperVFeatures | Where-Object { $_.FeatureName -eq $featureName }

            if ($feature.State -eq 'Enabled') {
                Write-Verbose "Feature $featureName is already enabled"
                $results += [PSCustomObject]@{
                    FeatureName = $featureName
                    Status = 'AlreadyEnabled'
                    RestartRequired = $false
                }
                continue
            }

            if ($PSCmdlet.ShouldProcess($featureName, "Enable Windows Feature")) {
                Write-Verbose "Enabling feature: $featureName"

                $enableResult = Enable-WindowsOptionalFeature -Online -FeatureName $featureName -All

                $results += [PSCustomObject]@{
                    FeatureName = $featureName
                    Status = if ($enableResult.RestartNeeded) { 'EnabledRestartRequired' } else { 'Enabled' }
                    RestartRequired = $enableResult.RestartNeeded
                }
            }
        }

        # Display summary
        Write-Host "Hyper-V Installation Summary:" -ForegroundColor Green
        $results | Format-Table -AutoSize

        if ($results | Where-Object { $_.RestartRequired }) {
            Write-Warning "A restart is required to complete the Hyper-V installation"

            if ($Force) {
                Write-Host "Restarting computer in 10 seconds..." -ForegroundColor Yellow
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