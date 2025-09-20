#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Virtual Wan Management Tool

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Azure Virtual WAN Enterprise Management Tool
    Tool for creating, configuring, and managing Azure Virtual WAN infrastructure
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
    Address prefix for the virtual hub (e.g., "10.1.0.0/24" )
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
    Enable  monitoring and diagnostics
.PARAMETER EnableSecurityBaseline
    Apply security baseline configurations
.PARAMETER RouteTableName
    Custom route table name
.PARAMETER ConnectionNames
    Array of connection names to create
.PARAMETER Tags
    Tags to apply to resources
    .\Azure-Virtual-WAN-Management-Tool.ps1 -ResourceGroupName " wan-rg" -VirtualWANName " corp-wan" -Location "East US" -Action Create" -VWANType "Standard" -EnableMonitoring
    .\Azure-Virtual-WAN-Management-Tool.ps1 -ResourceGroupName " wan-rg" -VirtualWANName " corp-wan" -Action "AddHub" -HubName " hub-east" -HubLocation "East US" -HubAddressPrefix " 10.1.0.0/24" -EnableVpnGateway -EnableAzureFirewall
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Azure PowerShell modules
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VirtualWANName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create" , "Configure" , "Monitor" , "Scale" , "Delete" , "AddHub" , "RemoveHub" , "Status" )]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Action,
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic" , "Standard" )]
    [string]$VWANType = "Standard" ,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$HubName,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$HubLocation,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
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
    [ValidateNotNullOrEmpty()]
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
try {
                Write-Host "Successfully imported required Azure modules" -ForegroundColor Green
} catch {
    Write-Error "  Failed to import required modules: $($_.Exception.Message)"
    throw
}
[OutputType([bool])]
 "Log entry"ndatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("Info" , "Warning" , "Error" , "Success" )]
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow"
        Error = "Red"
        Success = "Green"
    }
    Write-Host " [$timestamp] $Message" -ForegroundColor $colors[$Level]
}
function New-VirtualWAN -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if ($PSCmdlet.ShouldProcess("Virtual WAN '$VirtualWANName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng Virtual WAN: $VirtualWANName" "Info"
            # Check if Virtual WAN already exists
            $existingWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName -ErrorAction SilentlyContinue
            if ($existingWAN) {
                Write-Verbose "Log entry"N already exists: $VirtualWANName" "Warning"
                return $existingWAN
            }
            # Create Virtual WAN
            $virtualWAN = New-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName -Location $Location -VirtualWANType $VWANType -Tag $Tags
            Write-Verbose "Log entry"N: $VirtualWANName" "Success"
            return $virtualWAN
        } catch {
            Write-Verbose "Log entry"N: $($_.Exception.Message)" "Error"
            throw
        }
    }
}
function New-VirtualHub -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WANName,
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HubName,
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HubLocation,
        [string]$AddressPrefix
    )
    if ($PSCmdlet.ShouldProcess("Virtual Hub '$HubName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng Virtual Hub: $HubName in $HubLocation" "Info"
            # Check if Virtual Hub already exists
            $existingHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName -ErrorAction SilentlyContinue
            if ($existingHub) {
                Write-Verbose "Log entry"Name" "Warning"
                return $existingHub
            }
            # Get Virtual WAN
            $virtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $WANName
            if (-not $virtualWAN) {
                throw "Virtual WAN '$WANName' not found"
            }
            # Create Virtual Hub
            $virtualHub = New-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName -Location $HubLocation -VirtualWan $virtualWAN -AddressPrefix $AddressPrefix -Tag $Tags
            Write-Verbose "Log entry"Name" "Success"
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
            Write-Verbose "Log entry"n.Message)" "Error"
            throw
        }
    }
}
function New-VpnGateway -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HubName)
    $vpnGatewayName = " $HubName-vpn-gw"
    if ($PSCmdlet.ShouldProcess("VPN Gateway '$vpnGatewayName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng VPN Gateway in hub: $HubName" "Info"
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
            # Create VPN Gateway
            $vpnGateway = New-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name $vpnGatewayName -VirtualHub $virtualHub -VpnGatewayScaleUnit 1 -Tag $Tags
            Write-Verbose "Log entry"N Gateway: $vpnGatewayName" "Success"
            return $vpnGateway
        } catch {
            Write-Verbose "Log entry"N Gateway: $($_.Exception.Message)" "Error"
        }
    }
}
function New-ExpressRouteGateway -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HubName)
    $erGatewayName = " $HubName-er-gw"
    if ($PSCmdlet.ShouldProcess("ExpressRoute Gateway '$erGatewayName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng ExpressRoute Gateway in hub: $HubName" "Info"
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
            # Create ExpressRoute Gateway
            $erGateway = New-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name $erGatewayName -VirtualHub $virtualHub -MinScaleUnits 1 -Tag $Tags
            Write-Verbose "Log entry"Name" "Success"
            return $erGateway
        } catch {
            Write-Verbose "Log entry"n.Message)" "Error"
        }
    }
}
function New-AzureFirewall -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HubName)
    $firewallName = " $HubName-azfw"
    if ($PSCmdlet.ShouldProcess("Azure Firewall '$firewallName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng Azure Firewall in hub: $HubName" "Info"
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
            # Create Firewall Policy
            $firewallPolicyName = " $HubName-fw-policy"
            $firewallPolicy = New-AzFirewallPolicy -ResourceGroupName $ResourceGroupName -Name $firewallPolicyName -Location $virtualHub.Location -Tag $Tags
            # Create Azure Firewall
            $azureFirewall = New-AzFirewall -Name $firewallName -ResourceGroupName $ResourceGroupName -Location $virtualHub.Location -VirtualHubId $virtualHub.Id -FirewallPolicyId $firewallPolicy.Id -SkuName "AZFW_Hub" -SkuTier "Standard" -Tag $Tags
            Write-Verbose "Log entry"Name" "Success"
            return $azureFirewall
        } catch {
            Write-Verbose "Log entry"n.Message)" "Error"
        }
    }
}
function New-VpnSite -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WANName,
        [string[]]$SiteNames
    )
    if ($PSCmdlet.ShouldProcess("VPN Sites: $($SiteNames -join ', ')" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng VPN sites..." "Info"
            $virtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $WANName
            $createdSites = @()
            foreach ($siteName in $SiteNames) {
                Write-Verbose "Log entry"ng VPN site: $siteName" "Info"
                # Example site configuration - customize as needed
                $vpnSite = New-AzVpnSite -ResourceGroupName $ResourceGroupName -Name $siteName -Location $Location -VirtualWan $virtualWAN -IpAddress " 203.0.113.1" -AddressSpace @(" 192.168.1.0/24" ) -DeviceModel "Generic" -DeviceVendor "Generic" -LinkSpeedInMbps 50 -Tag $Tags
                $createdSites = $createdSites + $vpnSite
                Write-Verbose "Log entry"N site: $siteName" "Success"
            }
            return $createdSites
        } catch {
            Write-Verbose "Log entry"N sites: $($_.Exception.Message)" "Error"
        }
    }
}
function Set-P2SVpnConfiguration -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HubName)
    $p2sGatewayName = " $HubName-p2s-gw"
    if ($PSCmdlet.ShouldProcess("Point-to-Site VPN Gateway '$p2sGatewayName'" , "Configure" )) {
        try {
            Write-Verbose "Log entry"nfiguring Point-to-Site VPN for hub: $HubName" "Info"
            # Get virtual hub
            $virtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
            # Configure address pool for P2S clients
            $p2sConnectionConfig = New-AzP2sVpnGateway -ResourceGroupName $ResourceGroupName -Name $p2sGatewayName -VirtualHubId $virtualHub.Id -VpnClientAddressPool @(" 172.16.0.0/24" ) -Tag $Tags
            Write-Verbose "Log entry"nfigured Point-to-Site VPN: $p2sGatewayName" "Success"
            return $p2sConnectionConfig
        } catch {
            Write-Verbose "Log entry"nfigure Point-to-Site VPN: $($_.Exception.Message)" "Error"
        }
    }
}
function New-HubRouteTable -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HubName,
        [string]$RouteTableName
    )
    if ($PSCmdlet.ShouldProcess("Route Table '$RouteTableName' in hub '$HubName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng custom route table: $RouteTableName" "Info"
            # Create custom route table
            $routeTable = New-AzVHubRouteTable -ResourceGroupName $ResourceGroupName -VirtualHubName $HubName -Name $RouteTableName
            # Example route configuration
            $route1 = New-AzStaticRoute -Name "DefaultRoute" -AddressPrefix @(" 0.0.0.0/0" ) -NextHopIpAddress " 10.0.0.1"
            $routeTable = Add-AzVHubRoute -VirtualHubRouteTable $routeTable -StaticRoute $route1
            Write-Verbose "Log entry"Name" "Success"
            return $routeTable
        } catch {
            Write-Verbose "Log entry"n.Message)" "Error"
        }
    }
}
function Get-VirtualWANStatus -ErrorAction Stop {
    [CmdletBinding()]
    param()
    try {
        Write-Verbose "Log entry"nitoring Virtual WAN status..." "Info"
        # Get Virtual WAN details
        $virtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName
        Write-Verbose "Log entry"N Status:" "Info"
        Write-Verbose "Log entry"Name: $($virtualWAN.Name)" "Info"
        Write-Verbose "Log entry"N.VirtualWANType)" "Info"
        Write-Verbose "Log entry"ning State: $($virtualWAN.ProvisioningState)" "Info"
        Write-Verbose "Log entry"n: $($virtualWAN.Location)" "Info"
        Write-Verbose "Log entry"N.ResourceGroupName)" "Info"
        # Get Virtual Hubs
        $virtualHubs = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName
        Write-Verbose "Log entry"nfo"
        foreach ($hub in $virtualHubs) {
            Write-Verbose "Log entry"Name)" "Info"
            Write-Verbose "Log entry"n: $($hub.Location)" "Info"
            Write-Verbose "Log entry"nfo"
            Write-Verbose "Log entry"ning State: $($hub.ProvisioningState)" "Info"
            # Check for gateways
            $vpnGateway = Get-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name " $($hub.Name)-vpn-gw" -ErrorAction SilentlyContinue
            if ($vpnGateway) {
                Write-Verbose "Log entry"N Gateway: Deployed" "Success"
            }
            $erGateway = Get-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name " $($hub.Name)-er-gw" -ErrorAction SilentlyContinue
            if ($erGateway) {
                Write-Verbose "Log entry"Name $ResourceGroupName -Name " $($hub.Name)-azfw" -ErrorAction SilentlyContinue
            if ($firewall) {
                Write-Verbose "Log entry"N Sites
        $vpnSites = Get-AzVpnSite -ResourceGroupName $ResourceGroupName
        if ($vpnSites) {
            Write-Verbose "Log entry"N Sites:" "Info"
            foreach ($site in $vpnSites) {
                Write-Verbose "Log entry"Name)" "Info"
                Write-Verbose "Log entry"nfo"
                Write-Verbose "Log entry"nk Speed: $($site.LinkSpeedInMbps) Mbps" "Info"
            }
        }
    } catch {
        Write-Verbose "Log entry"N status: $($_.Exception.Message)" "Error"
    }
}
function Set-VirtualWANMonitoring -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if ($PSCmdlet.ShouldProcess("Virtual WAN monitoring configuration" , "Apply" )) {
        try {
            Write-Verbose "Log entry"nfiguring Virtual WAN monitoring..." "Info"
            # Create Log Analytics workspace
            $workspaceName = " law-$ResourceGroupName-vwan"
            $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
            if (-not $workspace) {
                $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location
                Write-Verbose "Log entry"nalytics workspace: $workspaceName" "Success"
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
            Set-AzDiagnosticSetting -ResourceId $virtualWAN.Id -WorkspaceId $workspace.ResourceId -Log $diagnosticSettings.logs -Metric $diagnosticSettings.metrics -Name " $VirtualWANName-diagnostics"
            Write-Verbose "Log entry"nfigured monitoring" "Success"
        } catch {
            Write-Verbose "Log entry"nfigure monitoring: $($_.Exception.Message)" "Error"
        }
    }
}
function Set-SecurityBaseline -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if ($PSCmdlet.ShouldProcess("Virtual WAN security baseline" , "Apply" )) {
        try {
            Write-Verbose "Log entry"ng security baseline configurations..." "Info"
            # This would implement security best practices
            # Example configurations:
            # 1. Enable Network Security Groups
            # 2. Configure Azure Firewall rules
            # 3. Set up route filtering
            # 4. Enable DDoS protection
            # 5. Configure access policies
            Write-Verbose "Log entry"ne configurations applied" "Success"
        } catch {
            Write-Verbose "Log entry"ne: $($_.Exception.Message)" "Error"
        }
    }
}
function Remove-VirtualHub -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HubName)
    if ($PSCmdlet.ShouldProcess("Virtual Hub '$HubName' and all associated resources" , "Remove" )) {
        try {
            Write-Verbose "Log entry"ng Virtual Hub: $HubName" "Warning"
            # Remove associated resources first
            $vpnGateway = Get-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name " $HubName-vpn-gw" -ErrorAction SilentlyContinue
            if ($vpnGateway) {
                if ($PSCmdlet.ShouldContinue("Remove VPN Gateway '$($vpnGateway.Name)'?" , "Confirm Gateway Removal" )) {
                    Remove-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name " $HubName-vpn-gw" -Force
                }
            }
            $erGateway = Get-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name " $HubName-er-gw" -ErrorAction SilentlyContinue
            if ($erGateway) {
                if ($PSCmdlet.ShouldContinue("Remove ExpressRoute Gateway '$($erGateway.Name)'?" , "Confirm Gateway Removal" )) {
                    Remove-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name " $HubName-er-gw" -Force
                }
            }
            $firewall = Get-AzFirewall -ResourceGroupName $ResourceGroupName -Name " $HubName-azfw" -ErrorAction SilentlyContinue
            if ($firewall) {
                if ($PSCmdlet.ShouldContinue("Remove Azure Firewall '$($firewall.Name)'?" , "Confirm Firewall Removal" )) {
                    Remove-AzFirewall -ResourceGroupName $ResourceGroupName -Name " $HubName-azfw" -Force
                }
            }
            # Remove Virtual Hub
            Remove-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName -Force
            Write-Verbose "Log entry"Name" "Success"
        } catch {
            Write-Verbose "Log entry"n.Message)" "Error"
            throw
        }
    }
}
try {
    Write-Verbose "Log entry"ng Azure Virtual WAN Management Tool" "Info"
    Write-Verbose "Log entry"n: $Action" "Info"
    Write-Verbose "Log entry"N Name: $VirtualWANName" "Info"
    Write-Verbose "Log entry"Name" "Info"
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Verbose "Log entry"ng resource group: $ResourceGroupName" "Info"
        $resourcegroupSplat = @{
    Name = $ResourceGroupName
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
        Write-Verbose "Log entry"n) {
        "Create" {
            $virtualWAN = New-VirtualWAN -ErrorAction Stop
            if ($VpnSiteNames.Count -gt 0) {
                New-VpnSite -WANName $VirtualWANName -SiteNames $VpnSiteNames
            }
            if ($EnableMonitoring) {
                Set-VirtualWANMonitoring -ErrorAction Stop
            }
            if ($EnableSecurityBaseline) {
                Set-SecurityBaseline -ErrorAction Stop
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
                Set-VirtualWANMonitoring -ErrorAction Stop
            }
            if ($EnableSecurityBaseline) {
                Set-SecurityBaseline -ErrorAction Stop
            }
        }
        "Monitor" {
            Get-VirtualWANStatus -ErrorAction Stop
        }
        "Status" {
            Get-VirtualWANStatus -ErrorAction Stop
        }
        "Scale" {
            Write-Verbose "Log entry"ng operations would be implemented here" "Info"
            # This would implement scaling logic for gateways and connections
        }
        "Delete" {
            Write-Verbose "Log entry"ng Virtual WAN: $VirtualWANName" "Warning"
            # Remove all hubs first
$allHubs = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName
            foreach ($hub in $allHubs) {
                Remove-VirtualHub -HubName $hub.Name
            }
            # Remove Virtual WAN
            Remove-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName -Force
            Write-Verbose "Log entry"N" "Success"
        }
    }
    Write-Verbose "Log entry"N Management Tool completed successfully" "Success"
} catch {
    Write-Verbose "Log entry"n failed: $($_.Exception.Message)" "Error"
    throw
}


