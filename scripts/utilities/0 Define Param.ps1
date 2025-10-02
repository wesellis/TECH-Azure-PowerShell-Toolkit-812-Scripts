#Requires -Version 7.4

<#
.SYNOPSIS
    Define Param

.DESCRIPTION
    Define Param operation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline)]
    [object]$SubnetConfig,
    [Parameter(ValueFromPipeline)]
    [object]$VnetCONFIG,
    [Parameter(ValueFromPipeline)]
    [object]$GatewaySubnetConfig,
    [Parameter(ValueFromPipeline)]
    [object]$PublicIPConfig,
    [Parameter(ValueFromPipeline)]
    [object]$GatewayPublicIPConfig
)
begin {
}
process {
    try {
        $LocationName = 'CanadaCentral'
        $CustomerName = 'CCI'
        $VMName = 'VPN505050'
        $CustomerName = 'CanadaComputing'
        $ResourceGroupName = -join ("$CustomerName", "_$VMName", "_RG")
        $datetime = [System.DateTime]::Now.ToString("yyyy_MM_dd_HH_mm_ss")
        [hashtable]$Tags = @{
            "Autoshutown"     = 'ON'
            "Createdby"       = 'Abdullah Ollivierre'
            "CustomerName"    = "$CustomerName"
            "DateTimeCreated" = "$datetime"
            "Environment"     = 'Production'
            "Application"     = 'VPN'
            "Purpose"         = 'VPN'
            "Uptime"          = '24/7'
            "Workload"        = 'VPN'
            "RebootCaution"   = 'Schedule a window first before rebooting'
            "VMSize"          = 'B2MS'
            "Location"        = "$LocationName"
            "Approved By"     = "Abdullah Ollivierre"
            "Approved On"     = ""
        }
        $NewAzResourceGroupSplat = @{
            Name     = $ResourceGroupName
            Location = $LocationName
            Tag      = $Tags
        }
        $SubnetName = -join ("$VMName" , "-subnet" )
        $SubnetAddressPrefix = "10.0.0.0/24"
        $NewAzVirtualNetworkSubnetConfigSplat = @{
            Name          = $SubnetName
            AddressPrefix = $SubnetAddressPrefix
        }
        $NetworkName = -join ("$VMName" , "_group-vnet" )
        $VnetAddressPrefix = "10.0.0.0/16"
        $NewAzVirtualNetworkSplat = @{
            Name              = $NetworkName
            ResourceGroupName = $ResourceGroupName
            Location          = $LocationName
            AddressPrefix     = $VnetAddressPrefix
            Subnet            = $SubnetConfig
            Tag               = $Tags
        }
        $NewAzVirtualNetworkConfigSplat = @{
            Name              = $NetworkName
            ResourceGroupName = $ResourceGroupName
        }
        $GatewaySubnetName = 'GatewaySubnet'
        $SubnetAddressPrefix = "10.0.255.0/27"
        $NewAzVirtualNetworkGatewaySubnetConfigSplat = @{
            Name           = $GatewaySubnetName
            AddressPrefix  = $SubnetAddressPrefix
            VirtualNetwork = $VnetCONFIG
        }
        $PublicIPAddressName = -join ("$VMName" , "-ip" )
        $PublicIPAllocationMethod = 'Dynamic'
        $DNSNameLabel = $VMName.ToLower()
        $NewAzPublicIpAddressSplat = @{
            Name              = $PublicIPAddressName
            DomainNameLabel   = $DNSNameLabel
            ResourceGroupName = $ResourceGroupName
            Location          = $LocationName
            AllocationMethod  = $PublicIPAllocationMethod
            Tag               = $Tags
        }
        $GetAzVirtualNetworkSubnetConfigsplat = @{
            Name              = $GatewaySubnetName
            VirtualNetwork    = $NetworkName
        }
        $gwipconfigname = -join ("$VMName" , "-gwipconfig" )
        $NewAzVirtualNetworkGatewayIpConfigSplat = @{
            Name              = $gwipconfigname
            SubnetId          = $GatewaySubnetConfig.ID
            PublicIpAddressId = $PublicIPConfig.ID
        }
        $GatewayName = -join ("$VMName" , '-VNet1GW')
        $GatewayType = 'Vpn'
        $VpnType = 'RouteBased'
        $GatewaySku = 'VpnGw1'
        $NewAzVirtualNetworkGatewaysplat = @{
            Name              = $GatewayName
            ResourceGroupName = $ResourceGroupName
            Location          = $LocationName
            IpConfigurations  = $GatewayPublicIPConfig
            GatewayType       = $GatewayType
            VpnType           = $VpnType
            GatewaySku        = $GatewaySku
        }
        $mypscustomobject = [PSCustomObject]@{
            newAzResourceGroupSplat                     = $NewAzResourceGroupSplat
            newAzVirtualNetworkSubnetConfigSplat        = $NewAzVirtualNetworkSubnetConfigSplat
            newAzVirtualNetworkSplat                    = $NewAzVirtualNetworkSplat
            newAzVirtualNetworkConfigSplat              = $NewAzVirtualNetworkConfigSplat
            newAzVirtualNetworkGatewaySubnetConfigSplat = $NewAzVirtualNetworkGatewaySubnetConfigSplat
            newAzPublicIpAddressSplat                   = $NewAzPublicIpAddressSplat
            GetAzVirtualNetworkSubnetConfigsplat        = $GetAzVirtualNetworkSubnetConfigsplat
            newAzVirtualNetworkGatewayIpConfigSplat     = $NewAzVirtualNetworkGatewayIpConfigSplat
            newAzVirtualNetworkGatewaysplat             = $NewAzVirtualNetworkGatewaysplat
        }
    } catch {
        Write-Error 'An Error happened when .. script execution will be halted'
        Write-Output "Displaying the Catch Statement ErrorCode"
        $PSItem
        Write-Output $PSItem.ScriptStackTrace
        $ErrorMessage_1 = $_.Exception.Message
        Write-Output $ErrorMessage_1
        Write-Output "Ran into an issue: $PSItem"
        Write-Output "Ran into an issue: $PSItem"
        throw "Ran into an issue: $PSItem"
        throw "I am the catch"
        throw "Ran into an issue: $PSItem"
        $PSItem | Write-Information
        $PSItem | Select-Object *
        $PSCmdlet.ThrowTerminatingError($PSitem)
        throw
        throw "Something went wrong"
        Write-Log $PSItem.ToString()
        Exit
    }
    finally {
    }
}
end {
    return $mypscustomobject
}
}