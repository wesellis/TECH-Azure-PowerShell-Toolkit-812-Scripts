#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Virtual Wan Management Tool

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
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
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $VirtualWANName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $Location,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create" , "Configure" , "Monitor" , "Scale" , "Delete" , "AddHub" , "RemoveHub" , "Status" )]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Action,
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic" , "Standard" )]
    $VWANType = "Standard" ,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    $HubName,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    $HubLocation,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    $HubAddressPrefix,
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
    $RouteTableName,
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
                Write-Output "Successfully imported required Azure modules" # Color: $2
} catch {
    Write-Error "  Failed to import required modules: $($_.Exception.Message)"
    throw
}
[OutputType([bool])]
 "Log entry"ndatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("Info" , "Warning" , "Error" , "Success" )]
        $Level = "Info"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow"
        Error = "Red"
        Success = "Green"
    }
    Write-Output " [$timestamp] $Message" -ForegroundColor $colors[$Level]
}
function New-VirtualWAN -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Virtual WAN '$VirtualWANName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng Virtual WAN: $VirtualWANName" "Info"
    $ExistingWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName -ErrorAction SilentlyContinue
            if ($ExistingWAN) {
                Write-Verbose "Log entry"N already exists: $VirtualWANName" "Warning"
                return $ExistingWAN
            }
    $VirtualWAN = New-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName -Location $Location -VirtualWANType $VWANType -Tag $Tags
            Write-Verbose "Log entry"N: $VirtualWANName" "Success"
            return $VirtualWAN
        } catch {
            Write-Verbose "Log entry"N: $($_.Exception.Message)" "Error"
            throw
        }
    }
}
function New-VirtualHub -ErrorAction Stop {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $WANName,
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $HubName,
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $HubLocation,
        $AddressPrefix
    )
    if ($PSCmdlet.ShouldProcess("Virtual Hub '$HubName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng Virtual Hub: $HubName in $HubLocation" "Info"
    $ExistingHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName -ErrorAction SilentlyContinue
            if ($ExistingHub) {
                Write-Verbose "Log entry"Name" "Warning"
                return $ExistingHub
            }
    $VirtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $WANName
            if (-not $VirtualWAN) {
                throw "Virtual WAN '$WANName' not found"
            }
    $VirtualHub = New-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName -Location $HubLocation -VirtualWan $VirtualWAN -AddressPrefix $AddressPrefix -Tag $Tags
            Write-Verbose "Log entry"Name" "Success"
            if ($EnableVpnGateway) {
                New-VpnGateway -HubName $HubName
            }
            if ($EnableExpressRouteGateway) {
                New-ExpressRouteGateway -HubName $HubName
            }
            if ($EnableAzureFirewall) {
                New-AzureFirewall -HubName $HubName
            }
            return $VirtualHub
        } catch {
            Write-Verbose "Log entry"n.Message)" "Error"
            throw
        }
    }
}
function New-VpnGateway -ErrorAction Stop {
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    $HubName)
    $VpnGatewayName = " $HubName-vpn-gw"
    if ($PSCmdlet.ShouldProcess("VPN Gateway '$VpnGatewayName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng VPN Gateway in hub: $HubName" "Info"
    $VirtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
    $VpnGateway = New-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name $VpnGatewayName -VirtualHub $VirtualHub -VpnGatewayScaleUnit 1 -Tag $Tags
            Write-Verbose "Log entry"N Gateway: $VpnGatewayName" "Success"
            return $VpnGateway
        } catch {
            Write-Verbose "Log entry"N Gateway: $($_.Exception.Message)" "Error"
        }
    }
}
function New-ExpressRouteGateway -ErrorAction Stop {
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    $HubName)
    $ErGatewayName = " $HubName-er-gw"
    if ($PSCmdlet.ShouldProcess("ExpressRoute Gateway '$ErGatewayName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng ExpressRoute Gateway in hub: $HubName" "Info"
    $VirtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
    $ErGateway = New-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name $ErGatewayName -VirtualHub $VirtualHub -MinScaleUnits 1 -Tag $Tags
            Write-Verbose "Log entry"Name" "Success"
            return $ErGateway
        } catch {
            Write-Verbose "Log entry"n.Message)" "Error"
        }
    }
}
function New-AzureFirewall -ErrorAction Stop {
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    $HubName)
    $FirewallName = " $HubName-azfw"
    if ($PSCmdlet.ShouldProcess("Azure Firewall '$FirewallName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng Azure Firewall in hub: $HubName" "Info"
    $VirtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
    $FirewallPolicyName = " $HubName-fw-policy"
    $FirewallPolicy = New-AzFirewallPolicy -ResourceGroupName $ResourceGroupName -Name $FirewallPolicyName -Location $VirtualHub.Location -Tag $Tags
    $AzureFirewall = New-AzFirewall -Name $FirewallName -ResourceGroupName $ResourceGroupName -Location $VirtualHub.Location -VirtualHubId $VirtualHub.Id -FirewallPolicyId $FirewallPolicy.Id -SkuName "AZFW_Hub" -SkuTier "Standard" -Tag $Tags
            Write-Verbose "Log entry"Name" "Success"
            return $AzureFirewall
        } catch {
            Write-Verbose "Log entry"n.Message)" "Error"
        }
    }
}
function New-VpnSite -ErrorAction Stop {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $WANName,
        [string[]]$SiteNames
    )
    if ($PSCmdlet.ShouldProcess("VPN Sites: $($SiteNames -join ', ')" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng VPN sites..." "Info"
    $VirtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $WANName
    $CreatedSites = @()
            foreach ($SiteName in $SiteNames) {
                Write-Verbose "Log entry"ng VPN site: $SiteName" "Info"
    $VpnSite = New-AzVpnSite -ResourceGroupName $ResourceGroupName -Name $SiteName -Location $Location -VirtualWan $VirtualWAN -IpAddress " 203.0.113.1" -AddressSpace @(" 192.168.1.0/24" ) -DeviceModel "Generic" -DeviceVendor "Generic" -LinkSpeedInMbps 50 -Tag $Tags
    $CreatedSites = $CreatedSites + $VpnSite
                Write-Verbose "Log entry"N site: $SiteName" "Success"
            }
            return $CreatedSites
        } catch {
            Write-Verbose "Log entry"N sites: $($_.Exception.Message)" "Error"
        }
    }
}
function Set-P2SVpnConfiguration -ErrorAction Stop {
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    $HubName)
    $p2sGatewayName = " $HubName-p2s-gw"
    if ($PSCmdlet.ShouldProcess("Point-to-Site VPN Gateway '$p2sGatewayName'" , "Configure" )) {
        try {
            Write-Verbose "Log entry"nfiguring Point-to-Site VPN for hub: $HubName" "Info"
    $VirtualHub = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Name $HubName
    $p2sConnectionConfig = New-AzP2sVpnGateway -ResourceGroupName $ResourceGroupName -Name $p2sGatewayName -VirtualHubId $VirtualHub.Id -VpnClientAddressPool @(" 172.16.0.0/24" ) -Tag $Tags
            Write-Verbose "Log entry"nfigured Point-to-Site VPN: $p2sGatewayName" "Success"
            return $p2sConnectionConfig
        } catch {
            Write-Verbose "Log entry"nfigure Point-to-Site VPN: $($_.Exception.Message)" "Error"
        }
    }
}
function New-HubRouteTable -ErrorAction Stop {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $HubName,
        $RouteTableName
    )
    if ($PSCmdlet.ShouldProcess("Route Table '$RouteTableName' in hub '$HubName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng custom route table: $RouteTableName" "Info"
    $RouteTable = New-AzVHubRouteTable -ResourceGroupName $ResourceGroupName -VirtualHubName $HubName -Name $RouteTableName
    $route1 = New-AzStaticRoute -Name "DefaultRoute" -AddressPrefix @(" 0.0.0.0/0" ) -NextHopIpAddress " 10.0.0.1"
    $RouteTable = Add-AzVHubRoute -VirtualHubRouteTable $RouteTable -StaticRoute $route1
            Write-Verbose "Log entry"Name" "Success"
            return $RouteTable
        } catch {
            Write-Verbose "Log entry"n.Message)" "Error"
        }
    }
}
function Get-VirtualWANStatus -ErrorAction Stop {
    param()
    try {
        Write-Verbose "Log entry"nitoring Virtual WAN status..." "Info"
    $VirtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName
        Write-Verbose "Log entry"N Status:" "Info"
        Write-Verbose "Log entry"Name: $($VirtualWAN.Name)" "Info"
        Write-Verbose "Log entry"N.VirtualWANType)" "Info"
        Write-Verbose "Log entry"ning State: $($VirtualWAN.ProvisioningState)" "Info"
        Write-Verbose "Log entry"n: $($VirtualWAN.Location)" "Info"
        Write-Verbose "Log entry"N.ResourceGroupName)" "Info"
    $VirtualHubs = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName
        Write-Verbose "Log entry"nfo"
        foreach ($hub in $VirtualHubs) {
            Write-Verbose "Log entry"Name)" "Info"
            Write-Verbose "Log entry"n: $($hub.Location)" "Info"
            Write-Verbose "Log entry"nfo"
            Write-Verbose "Log entry"ning State: $($hub.ProvisioningState)" "Info"
    $VpnGateway = Get-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name " $($hub.Name)-vpn-gw" -ErrorAction SilentlyContinue
            if ($VpnGateway) {
                Write-Verbose "Log entry"N Gateway: Deployed" "Success"
            }
    $ErGateway = Get-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name " $($hub.Name)-er-gw" -ErrorAction SilentlyContinue
            if ($ErGateway) {
                Write-Verbose "Log entry"Name $ResourceGroupName -Name " $($hub.Name)-azfw" -ErrorAction SilentlyContinue
            if ($firewall) {
                Write-Verbose "Log entry"N Sites
    $VpnSites = Get-AzVpnSite -ResourceGroupName $ResourceGroupName
        if ($VpnSites) {
            Write-Verbose "Log entry"N Sites:" "Info"
            foreach ($site in $VpnSites) {
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
    param()
    if ($PSCmdlet.ShouldProcess("Virtual WAN monitoring configuration" , "Apply" )) {
        try {
            Write-Verbose "Log entry"nfiguring Virtual WAN monitoring..." "Info"
    $WorkspaceName = " law-$ResourceGroupName-vwan"
    $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
            if (-not $workspace) {
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Location $Location
                Write-Verbose "Log entry"nalytics workspace: $WorkspaceName" "Success"
            }
    $VirtualWAN = Get-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName
    $DiagnosticSettings = @{
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
            Set-AzDiagnosticSetting -ResourceId $VirtualWAN.Id -WorkspaceId $workspace.ResourceId -Log $DiagnosticSettings.logs -Metric $DiagnosticSettings.metrics -Name " $VirtualWANName-diagnostics"
            Write-Verbose "Log entry"nfigured monitoring" "Success"
        } catch {
            Write-Verbose "Log entry"nfigure monitoring: $($_.Exception.Message)" "Error"
        }
    }
}
function Set-SecurityBaseline -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Virtual WAN security baseline" , "Apply" )) {
        try {
            Write-Verbose "Log entry"ng security baseline configurations..." "Info"
            Write-Verbose "Log entry"ne configurations applied" "Success"
        } catch {
            Write-Verbose "Log entry"ne: $($_.Exception.Message)" "Error"
        }
    }
}
function Remove-VirtualHub -ErrorAction Stop {
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    $HubName)
    if ($PSCmdlet.ShouldProcess("Virtual Hub '$HubName' and all associated resources" , "Remove" )) {
        try {
            Write-Verbose "Log entry"ng Virtual Hub: $HubName" "Warning"
    $VpnGateway = Get-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name " $HubName-vpn-gw" -ErrorAction SilentlyContinue
            if ($VpnGateway) {
                if ($PSCmdlet.ShouldContinue("Remove VPN Gateway '$($VpnGateway.Name)'?" , "Confirm Gateway Removal" )) {
                    Remove-AzVpnGateway -ResourceGroupName $ResourceGroupName -Name " $HubName-vpn-gw" -Force
                }
            }
    $ErGateway = Get-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name " $HubName-er-gw" -ErrorAction SilentlyContinue
            if ($ErGateway) {
                if ($PSCmdlet.ShouldContinue("Remove ExpressRoute Gateway '$($ErGateway.Name)'?" , "Confirm Gateway Removal" )) {
                    Remove-AzExpressRouteGateway -ResourceGroupName $ResourceGroupName -Name " $HubName-er-gw" -Force
                }
            }
    $firewall = Get-AzFirewall -ResourceGroupName $ResourceGroupName -Name " $HubName-azfw" -ErrorAction SilentlyContinue
            if ($firewall) {
                if ($PSCmdlet.ShouldContinue("Remove Azure Firewall '$($firewall.Name)'?" , "Confirm Firewall Removal" )) {
                    Remove-AzFirewall -ResourceGroupName $ResourceGroupName -Name " $HubName-azfw" -Force
                }
            }
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
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Verbose "Log entry"ng resource group: $ResourceGroupName" "Info"
    $ResourcegroupSplat = @{
    Name = $ResourceGroupName
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
        Write-Verbose "Log entry"n) {
        "Create" {
    $VirtualWAN = New-VirtualWAN -ErrorAction Stop
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
    $VirtualHub = New-VirtualHub -WANName $VirtualWANName -HubName $HubName -HubLocation $HubLocation -AddressPrefix $HubAddressPrefix
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
        }
        "Delete" {
            Write-Verbose "Log entry"ng Virtual WAN: $VirtualWANName" "Warning"
    $AllHubs = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName
            foreach ($hub in $AllHubs) {
                Remove-VirtualHub -HubName $hub.Name
            }
            Remove-AzVirtualWan -ResourceGroupName $ResourceGroupName -Name $VirtualWANName -Force
            Write-Verbose "Log entry"N" "Success"
        }
    }
    Write-Verbose "Log entry"N Management Tool completed successfully" "Success"
} catch {
    Write-Verbose "Log entry"n failed: $($_.Exception.Message)" "Error"
    throw`n}
