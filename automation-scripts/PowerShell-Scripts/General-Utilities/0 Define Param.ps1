#Requires -Version 7.0

<#
.SYNOPSIS
    0 Define Param

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 0 Define Param

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes


[CmdletBinding()]
function WE-Invoke-DefineParam {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
    

function Write-WELog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

param(
        [Parameter(ValueFromPipeline)]
        $WESubnetConfig,
        [Parameter(ValueFromPipeline)]
        $WEVnetCONFIG,
        [Parameter(ValueFromPipeline)]
        $WEGatewaySubnetConfig,
        [Parameter(ValueFromPipeline)]
        $WEPublicIPConfig,
        [Parameter(ValueFromPipeline)]
        $WEGatewayPublicIPConfig
        
    )
    
    begin {
        
    }
    
    process {


        try {

            #Region Param Global
            $WELocationName = 'CanadaCentral'
            $WECustomerName = 'CCI'
            $WEVMName = 'VPN505050'
            $WECustomerName = 'CanadaComputing'
            $WEResourceGroupName = -join (" $WECustomerName" , " _$WEVMName" , " _RG" )
            #EndRegion Param Global
    
    
            #Region Param Date
            #Creating the Tag Hashtable for the VM
            $datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
            [hashtable]$WETags = @{
    
                " Autoshutown"     = 'ON'
                " Createdby"       = 'Abdullah Ollivierre'
                " CustomerName"    = " $WECustomerName"
                " DateTimeCreated" = " $datetime"
                " Environment"     = 'Production'
                " Application"     = 'VPN'  
                " Purpose"         = 'VPN'
                " Uptime"          = '24/7'
                " Workload"        = 'VPN'
                " RebootCaution"   = 'Schedule a window first before rebooting'
                " VMSize"          = 'B2MS'
                " Location"        = " $WELocationName"
                " Approved By"     = " Abdullah Ollivierre"
                " Approved On"     = ""
    
            }
    
    
            $newAzResourceGroupSplat = @{
                Name     = $WEResourceGroupName
                Location = $WELocationName
                Tag      = $WETags
            }
    
            #endRegion Param Date



            #Region Param VNETSubnet

            $WESubnetName = -join (" $WEVMName" , " -subnet" )
            $WESubnetAddressPrefix = " 10.0.0.0/24"
       
            $newAzVirtualNetworkSubnetConfigSplat = @{
                Name          = $WESubnetName
                AddressPrefix = $WESubnetAddressPrefix
                # VirtualNetwork = $WEVNET
            }
            #EndRegion Param VNETSubnet     
    
            #Region Param VNET
            $WENetworkName = -join (" $WEVMName" , " _group-vnet" )
            $WEVnetAddressPrefix = " 10.0.0.0/16"

    
            $newAzVirtualNetworkSplat = @{
                Name              = $WENetworkName
                ResourceGroupName = $WEResourceGroupName
                Location          = $WELocationName
                AddressPrefix     = $WEVnetAddressPrefix
                Subnet            = $WESubnetConfig
                Tag               = $WETags
            }
            #EndRegion Param VNET




            $newAzVirtualNetworkConfigSplat = @{
                Name              = $WENetworkName
                ResourceGroupName = $WEResourceGroupName
            }


            #Region Param VNET Gateway Subnet

            $WEGatewaySubnetName = 'GatewaySubnet'
            $WESubnetAddressPrefix = " 10.0.255.0/27"
                   
            $newAzVirtualNetworkGatewaySubnetConfigSplat = @{
                Name           = $WEGatewaySubnetName
                AddressPrefix  = $WESubnetAddressPrefix
                VirtualNetwork = $WEVnetCONFIG
            }
            #EndRegion Param VNET Gateway Subnet 



            $WEPublicIPAddressName = -join (" $WEVMName" , " -ip" )
            $WEPublicIPAllocationMethod = 'Dynamic' 
        
            $newAzPublicIpAddressSplat = @{
                Name              = $WEPublicIPAddressName
                DomainNameLabel   = $WEDNSNameLabel
                ResourceGroupName = $WEResourceGroupName
                Location          = $WELocationName
                AllocationMethod  = $WEPublicIPAllocationMethod
                Tag               = $WETags
            }



            $WEGetAzVirtualNetworkSubnetConfigsplat = @{
                Name              = $WEGatewaySubnetName
                VirtualNetwork    = $WENetworkName
            }


            $gwipconfigname = -join (" $WEVMName" , " -gwipconfig" )
            $WENewAzVirtualNetworkGatewayIpConfigSplat = @{
                Name              = $gwipconfigname
                SubnetId          = $WEGatewaySubnetConfig.ID
                PublicIpAddressId = $WEPublicIPConfig.ID
            }


            $WEGatewayName = -join (" $WEVMName" , '-VNet1GW')
            $WEGatewayType = 'Vpn'
            $WEVpnType = 'RouteBased'
            $WEGatewaySku = 'VpnGw1'

            $newAzVirtualNetworkGatewaysplat = @{
                Name              = $WEGatewayName
                ResourceGroupName = $WEResourceGroupName
                Location          = $WELocationName
                IpConfigurations  = $WEGatewayPublicIPConfig
                GatewayType       = $WEGatewayType
                VpnType           = $WEVpnType
                GatewaySku        = $WEGatewaySku
            }

           ;  $mypscustomobject = [PSCustomObject]@{
                newAzResourceGroupSplat                     = $newAzResourceGroupSplat
                newAzVirtualNetworkSubnetConfigSplat        = $newAzVirtualNetworkSubnetConfigSplat
                newAzVirtualNetworkSplat                    = $newAzVirtualNetworkSplat
                newAzVirtualNetworkConfigSplat              = $newAzVirtualNetworkConfigSplat
                newAzVirtualNetworkGatewaySubnetConfigSplat = $newAzVirtualNetworkGatewaySubnetConfigSplat
                newAzPublicIpAddressSplat                   = $newAzPublicIpAddressSplat
                GetAzVirtualNetworkSubnetConfigsplat        = $WEGetAzVirtualNetworkSubnetConfigsplat
                newAzVirtualNetworkGatewayIpConfigSplat     = $newAzVirtualNetworkGatewayIpConfigSplat
                newAzVirtualNetworkGatewaysplat             = $newAzVirtualNetworkGatewaysplat
            }
             
  
        }
         

        catch {
    
            Write-Error 'An Error happened when .. script execution will be halted'
         
            #Region CatchAll
         
            Write-WELog " A Terminating Error (Exception) happened" " INFO" -ForegroundColor Magenta
            Write-WELog " Displaying the Catch Statement ErrorCode" " INFO" -ForegroundColor Yellow
            $WEPSItem
            Write-Information $WEPSItem.ScriptStackTrace -ForegroundColor Red
            
            
           ;  $WEErrorMessage_1 = $_.Exception.Message
            Write-Information $WEErrorMessage_1  -ForegroundColor Red
            Write-Output " Ran into an issue: $WEPSItem"
            Write-Information " Ran into an issue: $WEPSItem"
            throw " Ran into an issue: $WEPSItem"
            throw " I am the catch"
            throw " Ran into an issue: $WEPSItem"
            $WEPSItem | Write-Information -ForegroundColor
            $WEPSItem | Select-Object *
            $WEPSCmdlet.ThrowTerminatingError($WEPSitem)
            throw
            throw " Something went wrong"
            Write-Log $WEPSItem.ToString()
         
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









# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

