#Requires -Version 7.4

<#
.SYNOPSIS
    Install SafeKit Cluster

.DESCRIPTION
    Azure automation script that installs and configures SafeKit cluster software

.PARAMETER PublicIPFormat
    The format for public IP addresses

.PARAMETER PrivateIPList
    Comma-separated list of private IP addresses

.PARAMETER VMList
    Comma-separated list of virtual machine names

.PARAMETER LBList
    Comma-separated list of load balancer configurations

.PARAMETER Password
    Password for cluster configuration

.EXAMPLE
    .\Installcluster.ps1 -PublicIPFormat "10.0.1.{0}" -PrivateIPList "10.0.1.10,10.0.1.11" -VMList "vm1,vm2" -LBList "lb1,lb2" -Password "ClusterPass123!"
    Installs SafeKit cluster with specified configuration

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrator privileges and SafeKit software
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PublicIPFormat,

    [Parameter(Mandatory = $true)]
    [string]$PrivateIPList,

    [Parameter(Mandatory = $true)]
    [string]$VMList,

    [Parameter(Mandatory = $true)]
    [string]$LBList,

    [Parameter(Mandatory = $true)]
    [string]$Password
)

$ErrorActionPreference = "Stop"

try {
    $TargetDir = "."

    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message
        )

        $Stamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
        Add-Content ./installsk.log "$stamp [installCluster.ps1] $Message"
    }

    Write-Log "Starting cluster installation..."
    Write-Log "VM List: $VMList"
    Write-Log "Public IP Format: $PublicIPFormat"
    Write-Log "Private IP List: $PrivateIPList"

    # Set SafeKit environment variables
    $env:SAFEBASE = "/safekit"
    $env:SAFEKITCMD = "/safekit/safekit.exe"
    $env:SAFEVAR = "/safekit/var"
    $env:SAFEWEBCONF = "/safekit/web/conf"

    Write-Log "Configuring cluster..."

    # Call cluster configuration script
    if (Test-Path "./configCluster.ps1") {
        & ./configCluster.ps1 -vmlist $VMList -publicipfmt $PublicIPFormat -privateiplist $PrivateIPList -lblist $LBList -Passwd $Password
    }
    else {
        Write-Warning "configCluster.ps1 not found in current directory. Cluster configuration skipped."
    }

    Write-Log "Cluster installation completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}