#Requires -Version 7.4

<#
.SYNOPSIS
    Joins a Windows computer to an Active Directory domain

.DESCRIPTION
    This script joins a Windows computer to an Active Directory domain using provided credentials.
    It can optionally restart the computer after joining and place the computer in a specific OU.

.PARAMETER DomainName
    The fully qualified domain name to join (e.g., 'contoso.local')

.PARAMETER DomainCredential
    Credential object with permissions to join computers to the domain

.PARAMETER OrganizationalUnit
    Optional distinguished name of the OU where the computer account should be created

.PARAMETER Restart
    Switch to restart the computer after joining the domain

.PARAMETER NewComputerName
    Optional new name for the computer (will be renamed before joining)

.EXAMPLE
    $cred = Get-Credential
    .\Domainjoin.ps1 -DomainName "contoso.local" -DomainCredential $cred -Restart

.EXAMPLE
    $cred = Get-Credential
    .\Domainjoin.ps1 -DomainName "contoso.local" -DomainCredential $cred -OrganizationalUnit "OU=Servers,DC=contoso,DC=local" -NewComputerName "WebServer01"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires administrative privileges
    Computer must be able to reach domain controllers
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]$DomainCredential,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OrganizationalUnit,

    [Parameter()]
    [switch]$Restart,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$NewComputerName
)

$ErrorActionPreference = "Stop"

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Level = 'Information'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'Information' { Write-Host $logMessage -ForegroundColor Green }
        'Warning' { Write-Warning $logMessage }
        'Error' { Write-Error $logMessage }
    }
}

try {
    Write-Log "Starting domain join process for domain: $DomainName"

    # Check if running on Windows
    if (-not $IsWindows) {
        throw "This script can only be run on Windows systems."
    }

    # Check if computer is already domain joined
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    if ($computerSystem.PartOfDomain) {
        $currentDomain = $computerSystem.Domain
        if ($currentDomain -eq $DomainName) {
            Write-Log "Computer is already joined to domain: $currentDomain" -Level Warning
            return
        }
        else {
            Write-Log "Computer is currently joined to different domain: $currentDomain. Will unjoin first." -Level Warning
        }
    }

    # Rename computer if specified
    if ($NewComputerName -and $env:COMPUTERNAME -ne $NewComputerName) {
        Write-Log "Renaming computer from '$env:COMPUTERNAME' to '$NewComputerName'"
        Rename-Computer -NewName $NewComputerName -Force
        Write-Log "Computer renamed. A restart will be required."
        $Restart = $true
    }

    # Test domain connectivity
    Write-Log "Testing connectivity to domain: $DomainName"
    try {
        $domainController = Resolve-DnsName -Name $DomainName -Type A -ErrorAction Stop
        Write-Log "Successfully resolved domain name: $DomainName"
    }
    catch {
        throw "Failed to resolve domain name '$DomainName'. Please check DNS configuration."
    }

    # Prepare join parameters
    $joinParams = @{
        DomainName = $DomainName
        Credential = $DomainCredential
        Force = $true
    }

    if ($OrganizationalUnit) {
        Write-Log "Computer will be placed in OU: $OrganizationalUnit"
        $joinParams.OUPath = $OrganizationalUnit
    }

    # Join domain
    Write-Log "Joining domain: $DomainName"
    Add-Computer @joinParams

    Write-Log "Successfully joined domain: $DomainName"

    # Configure automatic logon if restart is requested
    if ($Restart) {
        Write-Log "Computer will restart in 10 seconds..."
        Start-Sleep -Seconds 5

        Write-Log "Restarting computer to complete domain join..."
        Restart-Computer -Force
    }
    else {
        Write-Log "Domain join completed. Please restart the computer to complete the process." -Level Warning
    }
}
catch {
    $errorMessage = "Domain join failed: $($_.Exception.Message)"
    Write-Log $errorMessage -Level Error

    # Provide additional troubleshooting information
    Write-Log "Troubleshooting tips:" -Level Information
    Write-Log "1. Verify domain name is correct and reachable" -Level Information
    Write-Log "2. Check DNS configuration points to domain controllers" -Level Information
    Write-Log "3. Ensure provided credentials have domain join permissions" -Level Information
    Write-Log "4. Verify network connectivity to domain controllers" -Level Information

    throw
}