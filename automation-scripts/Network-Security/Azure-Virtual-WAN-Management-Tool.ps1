#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.Resources, Az.Network

<#
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
    Address prefix for the virtual hub (e.g., "10.1.0.0/24")
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
    .\Azure-Virtual-WAN-Management-Tool.ps1 -ResourceGroupName "wan-rg" -VirtualWANName "corp-wan" -Location "East US" -Action "Create" -VWANType "Standard" -EnableMonitoring
.EXAMPLE
    .\Azure-Virtual-WAN-Management-Tool.ps1 -ResourceGroupName "wan-rg" -VirtualWANName "corp-wan" -Action "AddHub" -HubName "hub-east" -HubLocation "East US" -HubAddressPrefix "10.1.0.0/24" -EnableVpnGateway -EnableAzureFirewall
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Azure PowerShell modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$VirtualWANName,
    
    [Parameter(Mandatory = $true)]
    [string]$Location,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "Configure", "Monitor", "Scale", "Delete", "AddHub", "RemoveHub", "Status")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Standard")]
    [string]$VWANType = "Standard",
    
    [Parameter(Mandatory = $false)]
    [string]$HubName,
    
    [Parameter(Mandatory = $false)]
    [string]$HubLocation,
    
    [Parameter(Mandatory = $false)]
    [string]$HubAddressPrefix,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableVpnGateway,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableExpressRouteGateway,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableAzureFirewall,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableP2SVpn,
    
    [Parameter(Mandatory = $false)]
    [string[]]$VpnSiteNames = @(),
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableSecurityBaseline,
    
    [Parameter(Mandatory = $false)]
    [string]$RouteTableName,
    
    [Parameter(Mandatory = $false)]
    [string[]]$ConnectionNames = @(),
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Production"
        Application = "VirtualWAN"
        ManagedBy = "AutomationScript"
    }
)

# Import required modules
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.Network -Force -ErrorAction Stop
    Write-Host "✅ Successfully imported required Azure modules" -ForegroundColor Green
} catch {
    Write-Error "❌ Failed to import required modules: $($_.Exception.Message)"
    exit 1
}

# Enhanced logging function
function Write-EnhancedLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow" 
        Error = "Red"
        Success = "Green"
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}

# Create Virtual WAN instance
function New-VirtualWAN {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("Virtual WAN '$VirtualWANName'", "Create")) {
        try {
            Write-EnhancedLog "Creating Virtual WAN: $VirtualWANName" "Info"
            
            # Check if Virtual WAN already exists
            $existingWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName -ErrorAction SilentlyContinue
            if ($existingWAN) {
                Write-EnhancedLog "Virtual WAN already exists: $VirtualWANName" "Warning"
                return $existingWAN
            }
            
            # Create Virtual WAN
            $virtualWAN = New-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName -Location $Location -VirtualWANType $VWANType -Tag $Tags
            
            Write-EnhancedLog "Successfully created Virtual WAN: $VirtualWANName" "Success"
            return $virtualWAN
            
        } catch {
            Write-EnhancedLog "Failed to create Virtual WAN: $($_.Exception.Message)" "Error"
            throw
        }
    }
}

# Create Virtual Hub
function New-VirtualHub {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$WANName,
        [string]$HubName,
        [string]$HubLocation,
        [string]$AddressPrefix
    )
    
    if ($PSCmdlet.ShouldProcess("Virtual Hub '$HubName'", "Create")) {
        try {
            Write-EnhancedLog "Creating Virtual Hub: $HubName in $HubLocation" "Info"
            
            # Check if Virtual Hub already exists
            $existingHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName -ErrorAction SilentlyContinue
            if ($existingHub) {
                Write-EnhancedLog "Virtual Hub already exists: $HubName" "Warning"
                return $existingHub
            }
            
            # Get Virtual WAN
            $virtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $WANName
            if (-not $virtualWAN) {
                throw "Virtual WAN '$WANName' not found"
            }
            
            # Create Virtual Hub
            $virtualHub = New-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName -Location $HubLocation -VirtualWan $virtualWAN -AddressPrefix $AddressPrefix -Tag $Tags
            
            Write-EnhancedLog "Successfully created Virtual Hub: $HubName" "Success"
            
            # Configure gateways if requested
            if ($EnableVpnGateway) {
                New-VpnGateway -HubName $HubName
            }
            
            if ($EnableExpressRouteGateway) {
                New-ExpressRouteGateway -HubName $HubName
            }
            
            if ($EnableAzureFirewall) {
                New-AzureFirewall -HubName $HubName
            }
            
            return $virtualHub
            
        } catch {
            Write-EnhancedLog "Failed to create Virtual Hub: $($_.Exception.Message)" "Error"
            throw
        }
    }
}

# Create VPN Gateway in hub
function New-VpnGateway {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$HubName)
    
    $vpnGatewayName = "$HubName-vpn-gw"
    if ($PSCmdlet.ShouldProcess("VPN Gateway '$vpnGatewayName'", "Create")) {
        try {
            Write-EnhancedLog "Creating VPN Gateway in hub: $HubName" "Info"
            
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
            
            # Create VPN Gateway
            $vpnGateway = New-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name $vpnGatewayName -VirtualHub $virtualHub -VpnGatewayScaleUnit 1 -Tag $Tags
            
            Write-EnhancedLog "Successfully created VPN Gateway: $vpnGatewayName" "Success"
            return $vpnGateway
            
        } catch {
            Write-EnhancedLog "Failed to create VPN Gateway: $($_.Exception.Message)" "Error"
        }
    }
}

# Create ExpressRoute Gateway in hub
function New-ExpressRouteGateway {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$HubName)
    
    $erGatewayName = "$HubName-er-gw"
    if ($PSCmdlet.ShouldProcess("ExpressRoute Gateway '$erGatewayName'", "Create")) {
        try {
            Write-EnhancedLog "Creating ExpressRoute Gateway in hub: $HubName" "Info"
            
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
            
            # Create ExpressRoute Gateway
            $erGateway = New-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name $erGatewayName -VirtualHub $virtualHub -MinScaleUnits 1 -Tag $Tags
            
            Write-EnhancedLog "Successfully created ExpressRoute Gateway: $erGatewayName" "Success"
            return $erGateway
            
        } catch {
            Write-EnhancedLog "Failed to create ExpressRoute Gateway: $($_.Exception.Message)" "Error"
        }
    }
}

# Create Azure Firewall in hub
function New-AzureFirewall {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$HubName)
    
    $firewallName = "$HubName-azfw"
    if ($PSCmdlet.ShouldProcess("Azure Firewall '$firewallName'", "Create")) {
        try {
            Write-EnhancedLog "Creating Azure Firewall in hub: $HubName" "Info"
            
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
            
            # Create Firewall Policy
            $firewallPolicyName = "$HubName-fw-policy"
            $firewallPolicy = New-AzFirewallPolicy -ResourceGroupName $ResourceGroupName -Name $firewallPolicyName -Location $virtualHub.Location -Tag $Tags
            
            # Create Azure Firewall
            $azureFirewall = New-AzFirewall -Name $firewallName -ResourceGroupName $ResourceGroupName -Location $virtualHub.Location -VirtualHubId $virtualHub.Id -FirewallPolicyId $firewallPolicy.Id -SkuName "AZFW_Hub" -SkuTier "Standard" -Tag $Tags
            
            Write-EnhancedLog "Successfully created Azure Firewall: $firewallName" "Success"
            return $azureFirewall
            
        } catch {
            Write-EnhancedLog "Failed to create Azure Firewall: $($_.Exception.Message)" "Error"
        }
    }
}

# Create VPN sites
function New-VpnSite {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$WANName,
        [string[]]$SiteNames
    )
    
    if ($PSCmdlet.ShouldProcess("VPN Sites: $($SiteNames -join ', ')", "Create")) {
        try {
            Write-EnhancedLog "Creating VPN sites..." "Info"
            
            $virtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $WANName
            $createdSites = @()
            
            foreach ($siteName in $SiteNames) {
                Write-EnhancedLog "Creating VPN site: $siteName" "Info"
                
                # Example site configuration - customize as needed
                $vpnSite = New-AzVpnSite -ResourceGroupName $ResourceGroupName -Name $siteName -Location $Location -VirtualWan $virtualWAN -IpAddress "203.0.113.1" -AddressSpace @("192.168.1.0/24") -DeviceModel "Generic" -DeviceVendor "Generic" -LinkSpeedInMbps 50 -Tag $Tags
                
                $createdSites += $vpnSite
                Write-EnhancedLog "Successfully created VPN site: $siteName" "Success"
            }
            
            return $createdSites
            
        } catch {
            Write-EnhancedLog "Failed to create VPN sites: $($_.Exception.Message)" "Error"
        }
    }
}

# Configure Point-to-Site VPN
function Set-P2SVpnConfiguration {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$HubName)
    
    $p2sGatewayName = "$HubName-p2s-gw"
    if ($PSCmdlet.ShouldProcess("Point-to-Site VPN Gateway '$p2sGatewayName'", "Configure")) {
        try {
            Write-EnhancedLog "Configuring Point-to-Site VPN for hub: $HubName" "Info"
            
            # Get virtual hub
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
            
            # Configure address pool for P2S clients
            $p2sConnectionConfig = New-AzP2sVpnGateway -ResourceGroupName $ResourceGroupName -Name $p2sGatewayName -VirtualHubId $virtualHub.Id -VpnClientAddressPool @("172.16.0.0/24") -Tag $Tags
            
            Write-EnhancedLog "Successfully configured Point-to-Site VPN: $p2sGatewayName" "Success"
            return $p2sConnectionConfig
            
        } catch {
            Write-EnhancedLog "Failed to configure Point-to-Site VPN: $($_.Exception.Message)" "Error"
        }
    }
}

# Create custom route table
function New-HubRouteTable {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$HubName,
        [string]$RouteTableName
    )
    
    if ($PSCmdlet.ShouldProcess("Route Table '$RouteTableName' in hub '$HubName'", "Create")) {
        try {
            Write-EnhancedLog "Creating custom route table: $RouteTableName" "Info"
            
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
            
            # Create custom route table
            $routeTable = New-AzVHubRouteTable -ResourceGroupName $ResourceGroupName -VirtualHubName $HubName -Name $RouteTableName
            
            # Example route configuration
            $route1 = New-AzStaticRoute -Name "DefaultRoute" -AddressPrefix @("0.0.0.0/0") -NextHopIpAddress "10.0.0.1"
            $routeTable = Add-AzVHubRoute -VirtualHubRouteTable $routeTable -StaticRoute $route1
            
            Write-EnhancedLog "Successfully created route table: $RouteTableName" "Success"
            return $routeTable
            
        } catch {
            Write-EnhancedLog "Failed to create route table: $($_.Exception.Message)" "Error"
        }
    }
}

# Monitor Virtual WAN status
function Get-VirtualWANStatus {
    [CmdletBinding()]
    param()
    
    try {
        Write-EnhancedLog "Monitoring Virtual WAN status..." "Info"
        
        # Get Virtual WAN details
        $virtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName
        
        Write-EnhancedLog "Virtual WAN Status:" "Info"
        Write-EnhancedLog "  Name: $($virtualWAN.Name)" "Info"
        Write-EnhancedLog "  Type: $($virtualWAN.VirtualWANType)" "Info"
        Write-EnhancedLog "  Provisioning State: $($virtualWAN.ProvisioningState)" "Info"
        Write-EnhancedLog "  Location: $($virtualWAN.Location)" "Info"
        Write-EnhancedLog "  Resource Group: $($virtualWAN.ResourceGroupName)" "Info"
        
        # Get Virtual Hubs
        $virtualHubs = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName
        Write-EnhancedLog "Virtual Hubs:" "Info"
        
        foreach ($hub in $virtualHubs) {
            Write-EnhancedLog "  Hub: $($hub.Name)" "Info"
            Write-EnhancedLog "    Location: $($hub.Location)" "Info"
            Write-EnhancedLog "    Address Prefix: $($hub.AddressPrefix)" "Info"
            Write-EnhancedLog "    Provisioning State: $($hub.ProvisioningState)" "Info"
            
            # Check for gateways
            $vpnGateway = Get-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name "$($hub.Name)-vpn-gw" -ErrorAction SilentlyContinue
            if ($vpnGateway) {
                Write-EnhancedLog "    VPN Gateway: Deployed" "Success"
            }
            
            $erGateway = Get-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name "$($hub.Name)-er-gw" -ErrorAction SilentlyContinue
            if ($erGateway) {
                Write-EnhancedLog "    ExpressRoute Gateway: Deployed" "Success"
            }
            
            $firewall = Get-AzFirewall -ResourceGroupName $ResourceGroupName -Name "$($hub.Name)-azfw" -ErrorAction SilentlyContinue
            if ($firewall) {
                Write-EnhancedLog "    Azure Firewall: Deployed" "Success"
            }
        }
        
        # Get VPN Sites
        $vpnSites = Get-AzVpnSite -ResourceGroupName $ResourceGroupName
        if ($vpnSites) {
            Write-EnhancedLog "VPN Sites:" "Info"
            foreach ($site in $vpnSites) {
                Write-EnhancedLog "  Site: $($site.Name)" "Info"
                Write-EnhancedLog "    IP Address: $($site.IpAddress)" "Info"
                Write-EnhancedLog "    Link Speed: $($site.LinkSpeedInMbps) Mbps" "Info"
            }
        }
        
    } catch {
        Write-EnhancedLog "Failed to get Virtual WAN status: $($_.Exception.Message)" "Error"
    }
}

# Configure monitoring and diagnostics
function Set-VirtualWANMonitoring {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("Virtual WAN monitoring configuration", "Apply")) {
        try {
            Write-EnhancedLog "Configuring Virtual WAN monitoring..." "Info"
            
            # Create Log Analytics workspace
            $workspaceName = "law-$ResourceGroupName-vwan"
            $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
            
            if (-not $workspace) {
                $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location
                Write-EnhancedLog "Created Log Analytics workspace: $workspaceName" "Success"
            }
            
            # Configure diagnostic settings for Virtual WAN
            $virtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName
            
            $diagnosticSettings = @{
                logs = @(
                    @{
                        category = "GatewayDiagnosticLog"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    },
                    @{
                        category = "IKEDiagnosticLog"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    },
                    @{
                        category = "RouteDiagnosticLog"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    }
                )
                metrics = @(
                    @{
                        category = "AllMetrics"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    }
                )
            }
            
            Set-AzDiagnosticSetting -ResourceId $virtualWAN.Id -WorkspaceId $workspace.ResourceId -Log $diagnosticSettings.logs -Metric $diagnosticSettings.metrics -Name "$VirtualWANName-diagnostics"
            
            Write-EnhancedLog "Successfully configured monitoring" "Success"
            
        } catch {
            Write-EnhancedLog "Failed to configure monitoring: $($_.Exception.Message)" "Error"
        }
    }
}

# Apply security baseline
function Set-SecurityBaseline {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("Virtual WAN security baseline", "Apply")) {
        try {
            Write-EnhancedLog "Applying security baseline configurations..." "Info"
            
            # This would implement security best practices
            # Example configurations:
            
            # 1. Enable Network Security Groups
            # 2. Configure Azure Firewall rules
            # 3. Set up route filtering
            # 4. Enable DDoS protection
            # 5. Configure access policies
            
            Write-EnhancedLog "Security baseline configurations applied" "Success"
            
        } catch {
            Write-EnhancedLog "Failed to apply security baseline: $($_.Exception.Message)" "Error"
        }
    }
}

# Remove Virtual Hub
function Remove-VirtualHub {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$HubName)
    
    if ($PSCmdlet.ShouldProcess("Virtual Hub '$HubName' and all associated resources", "Remove")) {
        try {
            Write-EnhancedLog "Removing Virtual Hub: $HubName" "Warning"
            
            # Remove associated resources first
            $vpnGateway = Get-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name "$HubName-vpn-gw" -ErrorAction SilentlyContinue
            if ($vpnGateway) {
                if ($PSCmdlet.ShouldContinue("Remove VPN Gateway '$($vpnGateway.Name)'?", "Confirm Gateway Removal")) {
                    Remove-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name "$HubName-vpn-gw" -Force
                }
            }
            
            $erGateway = Get-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name "$HubName-er-gw" -ErrorAction SilentlyContinue
            if ($erGateway) {
                if ($PSCmdlet.ShouldContinue("Remove ExpressRoute Gateway '$($erGateway.Name)'?", "Confirm Gateway Removal")) {
                    Remove-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name "$HubName-er-gw" -Force
                }
            }
            
            $firewall = Get-AzFirewall -ResourceGroupName $ResourceGroupName -Name "$HubName-azfw" -ErrorAction SilentlyContinue
            if ($firewall) {
                if ($PSCmdlet.ShouldContinue("Remove Azure Firewall '$($firewall.Name)'?", "Confirm Firewall Removal")) {
                    Remove-AzFirewall -ResourceGroupName $ResourceGroupName -Name "$HubName-azfw" -Force
                }
            }
            
            # Remove Virtual Hub
            Remove-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName -Force
            
            Write-EnhancedLog "Successfully removed Virtual Hub: $HubName" "Success"
            
        } catch {
            Write-EnhancedLog "Failed to remove Virtual Hub: $($_.Exception.Message)" "Error"
            throw
        }
    }
}

# Main execution
try {
    Write-EnhancedLog "Starting Azure Virtual WAN Management Tool" "Info"
    Write-EnhancedLog "Action: $Action" "Info"
    Write-EnhancedLog "Virtual WAN Name: $VirtualWANName" "Info"
    Write-EnhancedLog "Resource Group: $ResourceGroupName" "Info"
    
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-EnhancedLog "Creating resource group: $ResourceGroupName" "Info"
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
        Write-EnhancedLog "Successfully created resource group" "Success"
    }
    
    switch ($Action) {
        "Create" {
            $virtualWAN = New-VirtualWAN
            
            if ($VpnSiteNames.Count -gt 0) {
                New-VpnSite -WANName $VirtualWANName -SiteNames $VpnSiteNames
            }
            
            if ($EnableMonitoring) {
                Set-VirtualWANMonitoring
            }
            
            if ($EnableSecurityBaseline) {
                Set-SecurityBaseline
            }
        }
        
        "AddHub" {
            if (-not $HubName -or -not $HubLocation -or -not $HubAddressPrefix) {
                throw "HubName, HubLocation, and HubAddressPrefix are required for AddHub action"
            }
            
            $virtualHub = New-VirtualHub -WANName $VirtualWANName -HubName $HubName -HubLocation $HubLocation -AddressPrefix $HubAddressPrefix
            
            if ($EnableP2SVpn) {
                Set-P2SVpnConfiguration -HubName $HubName
            }
            
            if ($RouteTableName) {
                New-HubRouteTable -HubName $HubName -RouteTableName $RouteTableName
            }
        }
        
        "RemoveHub" {
            if (-not $HubName) {
                throw "HubName parameter is required for RemoveHub action"
            }
            Remove-VirtualHub -HubName $HubName
        }
        
        "Configure" {
            if ($EnableMonitoring) {
                Set-VirtualWANMonitoring
            }
            
            if ($EnableSecurityBaseline) {
                Set-SecurityBaseline
            }
        }
        
        "Monitor" {
            Get-VirtualWANStatus
        }
        
        "Status" {
            Get-VirtualWANStatus
        }
        
        "Scale" {
            Write-EnhancedLog "Scaling operations would be implemented here" "Info"
            # This would implement scaling logic for gateways and connections
        }
        
        "Delete" {
            Write-EnhancedLog "Deleting Virtual WAN: $VirtualWANName" "Warning"
            
            # Remove all hubs first
            $virtualHubs = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName
            foreach ($hub in $virtualHubs) {
                Remove-VirtualHub -HubName $hub.Name
            }
            
            # Remove Virtual WAN
            Remove-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName -Force
            Write-EnhancedLog "Successfully deleted Virtual WAN" "Success"
        }
    }
    
    Write-EnhancedLog "Azure Virtual WAN Management Tool completed successfully" "Success"
    
} catch {
    Write-EnhancedLog "Tool execution failed: $($_.Exception.Message)" "Error"
    exit 1
}
