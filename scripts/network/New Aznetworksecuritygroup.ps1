#Requires -Version 7.4
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Create new Azure Network Security Group

.DESCRIPTION
    Creates a new Azure Network Security Group with configurable security rules
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0

.PARAMETER ResourceGroupName
    Name of the resource group where the NSG will be created

.PARAMETER Name
    Name of the Network Security Group

.PARAMETER Location
    Azure region where the NSG will be created

.PARAMETER SecurityRules
    Array of security rule objects created with New-AzNetworkSecurityRuleConfig

.PARAMETER Tags
    Hashtable of tags to apply to the NSG

.EXAMPLE
    .\11-New-Aznetworksecuritygroup.ps1 -ResourceGroupName "rg-prod" -Name "nsg-frontend" -Location "eastus"
    Creates an NSG with no initial rules

.EXAMPLE
    $rule1 = New-AzNetworkSecurityRuleConfig -Name "allow-https" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443
    .\11-New-Aznetworksecuritygroup.ps1 -ResourceGroupName "rg-prod" -Name "nsg-frontend" -Location "eastus" -SecurityRules $rule1
    Creates an NSG with a single HTTPS allow rule

.EXAMPLE
    $rule1 = New-AzNetworkSecurityRuleConfig -Name "allow-rdp" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
    $rule2 = New-AzNetworkSecurityRuleConfig -Name "allow-http" -Access Allow -Protocol Tcp -Direction Outbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80
    .\11-New-Aznetworksecuritygroup.ps1 -ResourceGroupName "rg-prod" -Name "nsg-frontend" -Location "eastus" -SecurityRules $rule1,$rule2
    Creates an NSG with multiple rules

.NOTES
    Requires Az.Network module and appropriate permissions
    Security rules can be added later using Add-AzNetworkSecurityRuleConfig
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter()]
    [Microsoft.Azure.Commands.Network.Models.PSSecurityRule[]]$SecurityRules = @(),

    [Parameter()]
    [hashtable]$Tags = @{}
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { 'Continue' } else { 'SilentlyContinue' }

function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO"    = "Cyan"
        "WARN"    = "Yellow"
        "ERROR"   = "Red"
        "SUCCESS" = "Green"
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

try {
    Write-LogMessage "Creating Azure Network Security Group" -Level "INFO"
    Write-LogMessage "Resource Group: $ResourceGroupName" -Level "INFO"
    Write-LogMessage "NSG Name: $Name" -Level "INFO"
    Write-LogMessage "Location: $Location" -Level "INFO"
    Write-LogMessage "Security Rules Count: $($SecurityRules.Count)" -Level "INFO"

    # Add default tags
    $datetime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $defaultTags = @{
        "CreatedDate" = $datetime
        "ManagedBy"   = "Azure PowerShell Toolkit"
        "Location"    = $Location
        "ResourceType" = "Network Security Group"
    }

    # Merge default tags with provided tags (provided tags take precedence)
    $finalTags = $defaultTags.Clone()
    foreach ($key in $Tags.Keys) {
        $finalTags[$key] = $Tags[$key]
    }

    Write-Verbose "Final tags: $($finalTags | Out-String)"

    # Build NSG parameters
    $nsgParams = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $Location
        Name              = $Name
        Tag               = $finalTags
    }

    # Add security rules if provided
    if ($SecurityRules.Count -gt 0) {
        $nsgParams['SecurityRules'] = $SecurityRules
        Write-LogMessage "Adding $($SecurityRules.Count) security rule(s)" -Level "INFO"

        foreach ($rule in $SecurityRules) {
            Write-Verbose "Rule: $($rule.Name) - $($rule.Direction) $($rule.Access) on port(s) $($rule.DestinationPortRange)"
        }
    } else {
        Write-LogMessage "No security rules specified - NSG will be created with default rules only" -Level "WARN"
    }

    # Create the NSG
    Write-LogMessage "Creating Network Security Group..." -Level "INFO"
    $nsg = New-AzNetworkSecurityGroup @nsgParams -ErrorAction Stop

    Write-LogMessage "Network Security Group created successfully" -Level "SUCCESS"
    Write-LogMessage "NSG ID: $($nsg.Id)" -Level "INFO"
    Write-LogMessage "Provisioning State: $($nsg.ProvisioningState)" -Level "INFO"

    if ($nsg.SecurityRules.Count -gt 0) {
        Write-LogMessage "Custom Rules: $($nsg.SecurityRules.Count)" -Level "INFO"
    }
    if ($nsg.DefaultSecurityRules.Count -gt 0) {
        Write-LogMessage "Default Rules: $($nsg.DefaultSecurityRules.Count)" -Level "INFO"
    }

    # Return the NSG object
    return $nsg

} catch {
    Write-LogMessage "Failed to create Network Security Group: $($_.Exception.Message)" -Level "ERROR"
    throw
}
