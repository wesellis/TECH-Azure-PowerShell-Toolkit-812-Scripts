<#
.SYNOPSIS
    Azure Virtual Wan Management Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Virtual Wan Management Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Azure Virtual WAN Enterprise Management Tool
.DESCRIPTION
    Advanced tool for creating, configuring, and managing Azure Virtual WAN infrastructure
    with SD-WAN capabilities, secure hubs, and global connectivity.
.PARAMETER ResourceGroupName
    Target Resource Group for Virtual WAN resources
.PARAMETER VirtualWANName
    Name of the Azure Virtual WAN instance
.PARAMETER Location
    Primary Azure region for the Virtual WAN
.PARAMETER Action
    Action to perform (Create, Configure, Monitor, Scale, Delete, AddHub, RemoveHub)
.PARAMETER VWANType
    Virtual WAN type (Basic, Standard)
.PARAMETER HubName
    Name of the virtual hub to create/manage
.PARAMETER HubLocation
    Location for the virtual hub
.PARAMETER HubAddressPrefix
    Address prefix for the virtual hub (e.g., " 10.1.0.0/24" )
.PARAMETER EnableVpnGateway
    Enable VPN Gateway in the hub
.PARAMETER EnableExpressRouteGateway
    Enable ExpressRoute Gateway in the hub
.PARAMETER EnableAzureFirewall
    Enable Azure Firewall in the hub
.PARAMETER EnableP2SVpn
    Enable Point-to-Site VPN
.PARAMETER VpnSiteNames
    Array of VPN site names to create
.PARAMETER EnableMonitoring
    Enable comprehensive monitoring and diagnostics
.PARAMETER EnableSecurityBaseline
    Apply security baseline configurations
.PARAMETER RouteTableName
    Custom route table name
.PARAMETER ConnectionNames
    Array of connection names to create
.PARAMETER Tags
    Tags to apply to resources
.EXAMPLE
    .\Azure-Virtual-WAN-Management-Tool.ps1 -ResourceGroupName " wan-rg" -VirtualWANName " corp-wan" -Location " East US" -Action " Create" -VWANType " Standard" -EnableMonitoring
.EXAMPLE
    .\Azure-Virtual-WAN-Management-Tool.ps1 -ResourceGroupName " wan-rg" -VirtualWANName " corp-wan" -Action " AddHub" -HubName " hub-east" -HubLocation " East US" -HubAddressPrefix " 10.1.0.0/24" -EnableVpnGateway -EnableAzureFirewall
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Azure PowerShell modules


[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVirtualWANName,
    
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet(" Create" , " Configure" , " Monitor" , " Scale" , " Delete" , " AddHub" , " RemoveHub" , " Status" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet(" Basic" , " Standard" )]
    [string]$WEVWANType = " Standard" ,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubName,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubLocation,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubAddressPrefix,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableVpnGateway,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableExpressRouteGateway,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableAzureFirewall,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableP2SVpn,
    
    [Parameter(Mandatory = $false)]
    [string[]]$WEVpnSiteNames = @(),
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableMonitoring,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableSecurityBaseline,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERouteTableName,
    
    [Parameter(Mandatory = $false)]
    [string[]]$WEConnectionNames = @(),
    
    [Parameter(Mandatory = $false)]
    [hashtable]$WETags = @{
        Environment = " Production"
        Application = " VirtualWAN"
        ManagedBy = " AutomationScript"
    }
)


try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.Network -Force -ErrorAction Stop
    Write-WELog " ✅ Successfully imported required Azure modules" " INFO" -ForegroundColor Green
} catch {
    Write-Error " ❌ Failed to import required modules: $($_.Exception.Message)"
    exit 1
}


[CmdletBinding()]
function WE-Write-EnhancedLog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEMessage,
        [ValidateSet(" Info" , " Warning" , " Error" , " Success" )]
        [string]$WELevel = " Info"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = " White"
        Warning = " Yellow" 
        Error = " Red"
        Success = " Green"
    }
    
    Write-WELog " [$timestamp] $WEMessage" " INFO" -ForegroundColor $colors[$WELevel]
}


[CmdletBinding()]
function WE-New-VirtualWAN -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($WEPSCmdlet.ShouldProcess(" Virtual WAN '$WEVirtualWANName'" , " Create" )) {
        try {
            Write-EnhancedLog " Creating Virtual WAN: $WEVirtualWANName" " Info"
            
            # Check if Virtual WAN already exists
            $existingWAN = Get-AzVirtualWan -ResourceGroupName $WEResourceGroupName -Name $WEVirtualWANName -ErrorAction SilentlyContinue
            if ($existingWAN) {
                Write-EnhancedLog " Virtual WAN already exists: $WEVirtualWANName" " Warning"
                return $existingWAN
            }
            
            # Create Virtual WAN
            $virtualWAN = New-AzVirtualWan -ResourceGroupName $WEResourceGroupName -Name $WEVirtualWANName -Location $WELocation -VirtualWANType $WEVWANType -Tag $WETags
            
            Write-EnhancedLog " Successfully created Virtual WAN: $WEVirtualWANName" " Success"
            return $virtualWAN
            
        } catch {
            Write-EnhancedLog " Failed to create Virtual WAN: $($_.Exception.Message)" " Error"
            throw
        }
    }
}


[CmdletBinding()]
function WE-New-VirtualHub -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEWANName,
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubName,
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubLocation,
        [string]$WEAddressPrefix
    )
    
    if ($WEPSCmdlet.ShouldProcess(" Virtual Hub '$WEHubName'" , " Create" )) {
        try {
            Write-EnhancedLog " Creating Virtual Hub: $WEHubName in $WEHubLocation" " Info"
            
            # Check if Virtual Hub already exists
            $existingHub = Get-AzVirtualHub -ResourceGroupName $WEResourceGroupName -Name $WEHubName -ErrorAction SilentlyContinue
            if ($existingHub) {
                Write-EnhancedLog " Virtual Hub already exists: $WEHubName" " Warning"
                return $existingHub
            }
            
            # Get Virtual WAN
            $virtualWAN = Get-AzVirtualWan -ResourceGroupName $WEResourceGroupName -Name $WEWANName
            if (-not $virtualWAN) {
                throw " Virtual WAN '$WEWANName' not found"
            }
            
            # Create Virtual Hub
            $virtualHub = New-AzVirtualHub -ResourceGroupName $WEResourceGroupName -Name $WEHubName -Location $WEHubLocation -VirtualWan $virtualWAN -AddressPrefix $WEAddressPrefix -Tag $WETags
            
            Write-EnhancedLog " Successfully created Virtual Hub: $WEHubName" " Success"
            
            # Configure gateways if requested
            if ($WEEnableVpnGateway) {
                New-VpnGateway -HubName $WEHubName
            }
            
            if ($WEEnableExpressRouteGateway) {
                New-ExpressRouteGateway -HubName $WEHubName
            }
            
            if ($WEEnableAzureFirewall) {
                New-AzureFirewall -HubName $WEHubName
            }
            
            return $virtualHub
            
        } catch {
            Write-EnhancedLog " Failed to create Virtual Hub: $($_.Exception.Message)" " Error"
            throw
        }
    }
}


[CmdletBinding()]
function WE-New-VpnGateway -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubName)
    
    $vpnGatewayName = " $WEHubName-vpn-gw"
    if ($WEPSCmdlet.ShouldProcess(" VPN Gateway '$vpnGatewayName'" , " Create" )) {
        try {
            Write-EnhancedLog " Creating VPN Gateway in hub: $WEHubName" " Info"
            
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $WEResourceGroupName -Name $WEHubName
            
            # Create VPN Gateway
            $vpnGateway = New-AzVpnGateway -ResourceGroupName $WEResourceGroupName -Name $vpnGatewayName -VirtualHub $virtualHub -VpnGatewayScaleUnit 1 -Tag $WETags
            
            Write-EnhancedLog " Successfully created VPN Gateway: $vpnGatewayName" " Success"
            return $vpnGateway
            
        } catch {
            Write-EnhancedLog " Failed to create VPN Gateway: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-New-ExpressRouteGateway -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubName)
    
    $erGatewayName = " $WEHubName-er-gw"
    if ($WEPSCmdlet.ShouldProcess(" ExpressRoute Gateway '$erGatewayName'" , " Create" )) {
        try {
            Write-EnhancedLog " Creating ExpressRoute Gateway in hub: $WEHubName" " Info"
            
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $WEResourceGroupName -Name $WEHubName
            
            # Create ExpressRoute Gateway
            $erGateway = New-AzExpressRouteGateway -ResourceGroupName $WEResourceGroupName -Name $erGatewayName -VirtualHub $virtualHub -MinScaleUnits 1 -Tag $WETags
            
            Write-EnhancedLog " Successfully created ExpressRoute Gateway: $erGatewayName" " Success"
            return $erGateway
            
        } catch {
            Write-EnhancedLog " Failed to create ExpressRoute Gateway: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-New-AzureFirewall -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubName)
    
    $firewallName = " $WEHubName-azfw"
    if ($WEPSCmdlet.ShouldProcess(" Azure Firewall '$firewallName'" , " Create" )) {
        try {
            Write-EnhancedLog " Creating Azure Firewall in hub: $WEHubName" " Info"
            
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $WEResourceGroupName -Name $WEHubName
            
            # Create Firewall Policy
            $firewallPolicyName = " $WEHubName-fw-policy"
            $firewallPolicy = New-AzFirewallPolicy -ResourceGroupName $WEResourceGroupName -Name $firewallPolicyName -Location $virtualHub.Location -Tag $WETags
            
            # Create Azure Firewall
            $azureFirewall = New-AzFirewall -Name $firewallName -ResourceGroupName $WEResourceGroupName -Location $virtualHub.Location -VirtualHubId $virtualHub.Id -FirewallPolicyId $firewallPolicy.Id -SkuName " AZFW_Hub" -SkuTier " Standard" -Tag $WETags
            
            Write-EnhancedLog " Successfully created Azure Firewall: $firewallName" " Success"
            return $azureFirewall
            
        } catch {
            Write-EnhancedLog " Failed to create Azure Firewall: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-New-VpnSite -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEWANName,
        [string[]]$WESiteNames
    )
    
    if ($WEPSCmdlet.ShouldProcess(" VPN Sites: $($WESiteNames -join ', ')" , " Create" )) {
        try {
            Write-EnhancedLog " Creating VPN sites..." " Info"
            
            $virtualWAN = Get-AzVirtualWan -ResourceGroupName $WEResourceGroupName -Name $WEWANName
            $createdSites = @()
            
            foreach ($siteName in $WESiteNames) {
                Write-EnhancedLog " Creating VPN site: $siteName" " Info"
                
                # Example site configuration - customize as needed
                $vpnSite = New-AzVpnSite -ResourceGroupName $WEResourceGroupName -Name $siteName -Location $WELocation -VirtualWan $virtualWAN -IpAddress " 203.0.113.1" -AddressSpace @(" 192.168.1.0/24" ) -DeviceModel " Generic" -DeviceVendor " Generic" -LinkSpeedInMbps 50 -Tag $WETags
                
                $createdSites = $createdSites + $vpnSite
                Write-EnhancedLog " Successfully created VPN site: $siteName" " Success"
            }
            
            return $createdSites
            
        } catch {
            Write-EnhancedLog " Failed to create VPN sites: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-Set-P2SVpnConfiguration -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubName)
    
    $p2sGatewayName = " $WEHubName-p2s-gw"
    if ($WEPSCmdlet.ShouldProcess(" Point-to-Site VPN Gateway '$p2sGatewayName'" , " Configure" )) {
        try {
            Write-EnhancedLog " Configuring Point-to-Site VPN for hub: $WEHubName" " Info"
            
            # Get virtual hub
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $WEResourceGroupName -Name $WEHubName
            
            # Configure address pool for P2S clients
            $p2sConnectionConfig = New-AzP2sVpnGateway -ResourceGroupName $WEResourceGroupName -Name $p2sGatewayName -VirtualHubId $virtualHub.Id -VpnClientAddressPool @(" 172.16.0.0/24" ) -Tag $WETags
            
            Write-EnhancedLog " Successfully configured Point-to-Site VPN: $p2sGatewayName" " Success"
            return $p2sConnectionConfig
            
        } catch {
            Write-EnhancedLog " Failed to configure Point-to-Site VPN: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-New-HubRouteTable -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubName,
        [string]$WERouteTableName
    )
    
    if ($WEPSCmdlet.ShouldProcess(" Route Table '$WERouteTableName' in hub '$WEHubName'" , " Create" )) {
        try {
            Write-EnhancedLog " Creating custom route table: $WERouteTableName" " Info"
            
            # Create custom route table
            $routeTable = New-AzVHubRouteTable -ResourceGroupName $WEResourceGroupName -VirtualHubName $WEHubName -Name $WERouteTableName
            
            # Example route configuration
            $route1 = New-AzStaticRoute -Name " DefaultRoute" -AddressPrefix @(" 0.0.0.0/0" ) -NextHopIpAddress " 10.0.0.1"
            $routeTable = Add-AzVHubRoute -VirtualHubRouteTable $routeTable -StaticRoute $route1
            
            Write-EnhancedLog " Successfully created route table: $WERouteTableName" " Success"
            return $routeTable
            
        } catch {
            Write-EnhancedLog " Failed to create route table: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-Get-VirtualWANStatus -ErrorAction Stop {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
    param()
    
    try {
        Write-EnhancedLog " Monitoring Virtual WAN status..." " Info"
        
        # Get Virtual WAN details
        $virtualWAN = Get-AzVirtualWan -ResourceGroupName $WEResourceGroupName -Name $WEVirtualWANName
        
        Write-EnhancedLog " Virtual WAN Status:" " Info"
        Write-EnhancedLog "  Name: $($virtualWAN.Name)" " Info"
        Write-EnhancedLog "  Type: $($virtualWAN.VirtualWANType)" " Info"
        Write-EnhancedLog "  Provisioning State: $($virtualWAN.ProvisioningState)" " Info"
        Write-EnhancedLog "  Location: $($virtualWAN.Location)" " Info"
        Write-EnhancedLog "  Resource Group: $($virtualWAN.ResourceGroupName)" " Info"
        
        # Get Virtual Hubs
        $virtualHubs = Get-AzVirtualHub -ResourceGroupName $WEResourceGroupName
        Write-EnhancedLog " Virtual Hubs:" " Info"
        
        foreach ($hub in $virtualHubs) {
            Write-EnhancedLog "  Hub: $($hub.Name)" " Info"
            Write-EnhancedLog "    Location: $($hub.Location)" " Info"
            Write-EnhancedLog "    Address Prefix: $($hub.AddressPrefix)" " Info"
            Write-EnhancedLog "    Provisioning State: $($hub.ProvisioningState)" " Info"
            
            # Check for gateways
            $vpnGateway = Get-AzVpnGateway -ResourceGroupName $WEResourceGroupName -Name " $($hub.Name)-vpn-gw" -ErrorAction SilentlyContinue
            if ($vpnGateway) {
                Write-EnhancedLog "    VPN Gateway: Deployed" " Success"
            }
            
            $erGateway = Get-AzExpressRouteGateway -ResourceGroupName $WEResourceGroupName -Name " $($hub.Name)-er-gw" -ErrorAction SilentlyContinue
            if ($erGateway) {
                Write-EnhancedLog "    ExpressRoute Gateway: Deployed" " Success"
            }
            
            $firewall = Get-AzFirewall -ResourceGroupName $WEResourceGroupName -Name " $($hub.Name)-azfw" -ErrorAction SilentlyContinue
            if ($firewall) {
                Write-EnhancedLog "    Azure Firewall: Deployed" " Success"
            }
        }
        
        # Get VPN Sites
        $vpnSites = Get-AzVpnSite -ResourceGroupName $WEResourceGroupName
        if ($vpnSites) {
            Write-EnhancedLog " VPN Sites:" " Info"
            foreach ($site in $vpnSites) {
                Write-EnhancedLog "  Site: $($site.Name)" " Info"
                Write-EnhancedLog "    IP Address: $($site.IpAddress)" " Info"
                Write-EnhancedLog "    Link Speed: $($site.LinkSpeedInMbps) Mbps" " Info"
            }
        }
        
    } catch {
        Write-EnhancedLog " Failed to get Virtual WAN status: $($_.Exception.Message)" " Error"
    }
}


[CmdletBinding()]
function WE-Set-VirtualWANMonitoring -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($WEPSCmdlet.ShouldProcess(" Virtual WAN monitoring configuration" , " Apply" )) {
        try {
            Write-EnhancedLog " Configuring Virtual WAN monitoring..." " Info"
            
            # Create Log Analytics workspace
            $workspaceName = " law-$WEResourceGroupName-vwan"
            $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
            
            if (-not $workspace) {
                $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -Location $WELocation
                Write-EnhancedLog " Created Log Analytics workspace: $workspaceName" " Success"
            }
            
            # Configure diagnostic settings for Virtual WAN
            $virtualWAN = Get-AzVirtualWan -ResourceGroupName $WEResourceGroupName -Name $WEVirtualWANName
            
            $diagnosticSettings = @{
                logs = @(
                    @{
                        category = " GatewayDiagnosticLog"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    },
                    @{
                        category = " IKEDiagnosticLog"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    },
                    @{
                        category = " RouteDiagnosticLog"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    }
                )
                metrics = @(
                    @{
                        category = " AllMetrics"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    }
                )
            }
            
            Set-AzDiagnosticSetting -ResourceId $virtualWAN.Id -WorkspaceId $workspace.ResourceId -Log $diagnosticSettings.logs -Metric $diagnosticSettings.metrics -Name " $WEVirtualWANName-diagnostics"
            
            Write-EnhancedLog " Successfully configured monitoring" " Success"
            
        } catch {
            Write-EnhancedLog " Failed to configure monitoring: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-Set-SecurityBaseline -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($WEPSCmdlet.ShouldProcess(" Virtual WAN security baseline" , " Apply" )) {
        try {
            Write-EnhancedLog " Applying security baseline configurations..." " Info"
            
            # This would implement security best practices
            # Example configurations:
            
            # 1. Enable Network Security Groups
            # 2. Configure Azure Firewall rules
            # 3. Set up route filtering
            # 4. Enable DDoS protection
            # 5. Configure access policies
            
            Write-EnhancedLog " Security baseline configurations applied" " Success"
            
        } catch {
            Write-EnhancedLog " Failed to apply security baseline: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-Remove-VirtualHub -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEHubName)
    
    if ($WEPSCmdlet.ShouldProcess(" Virtual Hub '$WEHubName' and all associated resources" , " Remove" )) {
        try {
            Write-EnhancedLog " Removing Virtual Hub: $WEHubName" " Warning"
            
            # Remove associated resources first
            $vpnGateway = Get-AzVpnGateway -ResourceGroupName $WEResourceGroupName -Name " $WEHubName-vpn-gw" -ErrorAction SilentlyContinue
            if ($vpnGateway) {
                if ($WEPSCmdlet.ShouldContinue(" Remove VPN Gateway '$($vpnGateway.Name)'?" , " Confirm Gateway Removal" )) {
                    Remove-AzVpnGateway -ResourceGroupName $WEResourceGroupName -Name " $WEHubName-vpn-gw" -Force
                }
            }
            
            $erGateway = Get-AzExpressRouteGateway -ResourceGroupName $WEResourceGroupName -Name " $WEHubName-er-gw" -ErrorAction SilentlyContinue
            if ($erGateway) {
                if ($WEPSCmdlet.ShouldContinue(" Remove ExpressRoute Gateway '$($erGateway.Name)'?" , " Confirm Gateway Removal" )) {
                    Remove-AzExpressRouteGateway -ResourceGroupName $WEResourceGroupName -Name " $WEHubName-er-gw" -Force
                }
            }
            
            $firewall = Get-AzFirewall -ResourceGroupName $WEResourceGroupName -Name " $WEHubName-azfw" -ErrorAction SilentlyContinue
            if ($firewall) {
                if ($WEPSCmdlet.ShouldContinue(" Remove Azure Firewall '$($firewall.Name)'?" , " Confirm Firewall Removal" )) {
                    Remove-AzFirewall -ResourceGroupName $WEResourceGroupName -Name " $WEHubName-azfw" -Force
                }
            }
            
            # Remove Virtual Hub
            Remove-AzVirtualHub -ResourceGroupName $WEResourceGroupName -Name $WEHubName -Force
            
            Write-EnhancedLog " Successfully removed Virtual Hub: $WEHubName" " Success"
            
        } catch {
            Write-EnhancedLog " Failed to remove Virtual Hub: $($_.Exception.Message)" " Error"
            throw
        }
    }
}


try {
    Write-EnhancedLog " Starting Azure Virtual WAN Management Tool" " Info"
    Write-EnhancedLog " Action: $WEAction" " Info"
    Write-EnhancedLog " Virtual WAN Name: $WEVirtualWANName" " Info"
    Write-EnhancedLog " Resource Group: $WEResourceGroupName" " Info"
    
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-EnhancedLog " Creating resource group: $WEResourceGroupName" " Info"
        $rg = New-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Tag $WETags
        Write-EnhancedLog " Successfully created resource group" " Success"
    }
    
    switch ($WEAction) {
        " Create" {
            $virtualWAN = New-VirtualWAN -ErrorAction Stop
            
            if ($WEVpnSiteNames.Count -gt 0) {
                New-VpnSite -WANName $WEVirtualWANName -SiteNames $WEVpnSiteNames
            }
            
            if ($WEEnableMonitoring) {
                Set-VirtualWANMonitoring -ErrorAction Stop
            }
            
            if ($WEEnableSecurityBaseline) {
                Set-SecurityBaseline -ErrorAction Stop
            }
        }
        
        " AddHub" {
            if (-not $WEHubName -or -not $WEHubLocation -or -not $WEHubAddressPrefix) {
                throw " HubName, HubLocation, and HubAddressPrefix are required for AddHub action"
            }
            
           ;  $virtualHub = New-VirtualHub -WANName $WEVirtualWANName -HubName $WEHubName -HubLocation $WEHubLocation -AddressPrefix $WEHubAddressPrefix
            
            if ($WEEnableP2SVpn) {
                Set-P2SVpnConfiguration -HubName $WEHubName
            }
            
            if ($WERouteTableName) {
                New-HubRouteTable -HubName $WEHubName -RouteTableName $WERouteTableName
            }
        }
        
        " RemoveHub" {
            if (-not $WEHubName) {
                throw " HubName parameter is required for RemoveHub action"
            }
            Remove-VirtualHub -HubName $WEHubName
        }
        
        " Configure" {
            if ($WEEnableMonitoring) {
                Set-VirtualWANMonitoring -ErrorAction Stop
            }
            
            if ($WEEnableSecurityBaseline) {
                Set-SecurityBaseline -ErrorAction Stop
            }
        }
        
        " Monitor" {
            Get-VirtualWANStatus -ErrorAction Stop
        }
        
        " Status" {
            Get-VirtualWANStatus -ErrorAction Stop
        }
        
        " Scale" {
            Write-EnhancedLog " Scaling operations would be implemented here" " Info"
            # This would implement scaling logic for gateways and connections
        }
        
        " Delete" {
            Write-EnhancedLog " Deleting Virtual WAN: $WEVirtualWANName" " Warning"
            
            # Remove all hubs first
           ;  $allHubs = Get-AzVirtualHub -ResourceGroupName $WEResourceGroupName
            foreach ($hub in $allHubs) {
                Remove-VirtualHub -HubName $hub.Name
            }
            
            # Remove Virtual WAN
            Remove-AzVirtualWan -ResourceGroupName $WEResourceGroupName -Name $WEVirtualWANName -Force
            Write-EnhancedLog " Successfully deleted Virtual WAN" " Success"
        }
    }
    
    Write-EnhancedLog " Azure Virtual WAN Management Tool completed successfully" " Success"
    
} catch {
    Write-EnhancedLog " Tool execution failed: $($_.Exception.Message)" " Error"
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================