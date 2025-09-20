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
# Short description
# Long description
# PS C:\> <example usage>
# Explanation of what the example does
# Inputs (if any)
# Output (if any)
# General notes
[CmdletBinding()]
[OutputType([PSObject])]
 {
    [CmdletBinding()]
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
        [Parameter(ValueFromPipeline)]
        $SubnetConfig,
        [Parameter(ValueFromPipeline)]
        $VnetCONFIG,
        [Parameter(ValueFromPipeline)]
        $GatewaySubnetConfig,
        [Parameter(ValueFromPipeline)]
        $PublicIPConfig,
        [Parameter(ValueFromPipeline)]
        $GatewayPublicIPConfig
    )
    begin {
    }
    process {
        try {
            #region Param-Global
            $LocationName = 'CanadaCentral'
            $CustomerName = 'CCI'
            $VMName = 'VPN505050'
            $CustomerName = 'CanadaComputing'
            $ResourceGroupName = -join ("$CustomerName", "_$VMName", "_RG")
            #EndRegion Param Global
            #region Param-Date
            #Creating the Tag Hashtable for the VM
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
            $newAzResourceGroupSplat = @{
                Name     = $ResourceGroupName
                Location = $LocationName
                Tag      = $Tags
            }
            #endRegion Param Date
            #region Param-VNETSubnet
            $SubnetName = -join (" $VMName" , "-subnet" )
            $SubnetAddressPrefix = " 10.0.0.0/24"
            $newAzVirtualNetworkSubnetConfigSplat = @{
                Name          = $SubnetName
                AddressPrefix = $SubnetAddressPrefix
                # VirtualNetwork = $VNET
            }
            #EndRegion Param VNETSubnet
            #region Param-VNET
            $NetworkName = -join (" $VMName" , "_group-vnet" )
            $VnetAddressPrefix = " 10.0.0.0/16"
            $newAzVirtualNetworkSplat = @{
                Name              = $NetworkName
                ResourceGroupName = $ResourceGroupName
                Location          = $LocationName
                AddressPrefix     = $VnetAddressPrefix
                Subnet            = $SubnetConfig
                Tag               = $Tags
            }
            #EndRegion Param VNET
            $newAzVirtualNetworkConfigSplat = @{
                Name              = $NetworkName
                ResourceGroupName = $ResourceGroupName
            }
            #region Param-VNET Gateway Subnet
            $GatewaySubnetName = 'GatewaySubnet'
            $SubnetAddressPrefix = " 10.0.255.0/27"
            $newAzVirtualNetworkGatewaySubnetConfigSplat = @{
                Name           = $GatewaySubnetName
                AddressPrefix  = $SubnetAddressPrefix
                VirtualNetwork = $VnetCONFIG
            }
            #EndRegion Param VNET Gateway Subnet
            $PublicIPAddressName = -join (" $VMName" , "-ip" )
            $PublicIPAllocationMethod = 'Dynamic'
            $newAzPublicIpAddressSplat = @{
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
            $gwipconfigname = -join (" $VMName" , "-gwipconfig" )
            $NewAzVirtualNetworkGatewayIpConfigSplat = @{
                Name              = $gwipconfigname
                SubnetId          = $GatewaySubnetConfig.ID
                PublicIpAddressId = $PublicIPConfig.ID
            }
            $GatewayName = -join (" $VMName" , '-VNet1GW')
            $GatewayType = 'Vpn'
            $VpnType = 'RouteBased'
            $GatewaySku = 'VpnGw1'
            $newAzVirtualNetworkGatewaysplat = @{
                Name              = $GatewayName
                ResourceGroupName = $ResourceGroupName
                Location          = $LocationName
                IpConfigurations  = $GatewayPublicIPConfig
                GatewayType       = $GatewayType
                VpnType           = $VpnType
                GatewaySku        = $GatewaySku
            }
$mypscustomobject = [PSCustomObject]@{
                newAzResourceGroupSplat                     = $newAzResourceGroupSplat
                newAzVirtualNetworkSubnetConfigSplat        = $newAzVirtualNetworkSubnetConfigSplat
                newAzVirtualNetworkSplat                    = $newAzVirtualNetworkSplat
                newAzVirtualNetworkConfigSplat              = $newAzVirtualNetworkConfigSplat
                newAzVirtualNetworkGatewaySubnetConfigSplat = $newAzVirtualNetworkGatewaySubnetConfigSplat
                newAzPublicIpAddressSplat                   = $newAzPublicIpAddressSplat
                GetAzVirtualNetworkSubnetConfigsplat        = $GetAzVirtualNetworkSubnetConfigsplat
                newAzVirtualNetworkGatewayIpConfigSplat     = $newAzVirtualNetworkGatewayIpConfigSplat
                newAzVirtualNetworkGatewaysplat             = $newAzVirtualNetworkGatewaysplat

} catch {
            Write-Error 'An Error happened when .. script execution will be halted'
            #region CatchAll-Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
$ErrorMessage_1 = $_.Exception.Message
            Write-Host $ErrorMessage_1  -ForegroundColor Red
            Write-Output "Ran into an issue: $PSItem"
            Write-Host "Ran into an issue: $PSItem"
            throw "Ran into an issue: $PSItem"
            throw "I am the catch"
            throw "Ran into an issue: $PSItem"
            $PSItem | Write-Information -ForegroundColor
            $PSItem | Select-Object *
            $PSCmdlet.ThrowTerminatingError($PSitem)
            throw
            throw "Something went wrong"
            Write-Log $PSItem.ToString()
            #EndRegion CatchAll
            Exit
        }
        finally {
        }
    }
    end {
        return $mypscustomobject
    }
}

