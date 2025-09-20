#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Nsg Rule Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding()];
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$NsgName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RuleName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Protocol,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SourcePortRange,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationPortRange,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Access,
    [Parameter(Mandatory)]
    [int]$Priority
)
Write-Host "Adding security rule to NSG: $NsgName" "INFO"

$Nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NsgName
$params = @{
    DestinationAddressPrefix = " *"
    Direction = "Inbound"
    Protocol = $Protocol
    Name = $RuleName
    Priority = $Priority
    DestinationPortRange = $DestinationPortRange
    SourcePortRange = $SourcePortRange
    Access = $Access
    NetworkSecurityGroup = $Nsg
    SourceAddressPrefix = " *"
}
Add-AzNetworkSecurityRuleConfig @params
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $Nsg
Write-Host "Security rule '$RuleName' added successfully to NSG: $NsgName" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


