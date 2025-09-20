#Requires -Version 7.0
#Requires -Modules Az.Network
#Requires -Modules Az.Resources
#Requires -Module Az.Resources, Az.Profile, Az.PolicyInsights, Az.ManagementGroups
<#`n.SYNOPSIS
    Deploy Azure Landing Zone following Microsoft best practices
.DESCRIPTION
    Automated deployment of enterprise-scale Azure Landing Zone with proper hub-spoke topology,
    policy assignments, and governance structure following Microsoft Cloud Adoption Framework
.PARAMETER TenantId
    Azure AD Tenant ID for the deployment
.PARAMETER ManagementGroupPrefix
    Prefix for management group structure (e.g., 'CORP', 'ORG')
.PARAMETER HubSubscriptionId
    Subscription ID for the connectivity hub resources
.PARAMETER IdentitySubscriptionId
    Subscription ID for identity and access management resources
.PARAMETER ManagementSubscriptionId
    Subscription ID for management and monitoring resources
.PARAMETER Location
    Primary Azure region for resource deployment
.PARAMETER SecondaryLocation
    Secondary Azure region for disaster recovery
.PARAMETER CompanyName
    Company name for resource naming and tagging
.PARAMETER WhatIf
    Preview changes without actually deploying resources
.EXAMPLE
    .\Azure-Landing-Zone-Deployment-Framework.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -ManagementGroupPrefix "CORP" -HubSubscriptionId "11111111-1111-1111-1111-111111111111" -CompanyName "Contoso"
.EXAMPLE
    .\Azure-Landing-Zone-Deployment-Framework.ps1 -TenantId "12345678-1234-1234-1234-123456789012" -ManagementGroupPrefix "CORP" -WhatIf
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    LastModified: 2025-09-19
    Requires Global Administrator or equivalent permissions

    This script implements Microsoft's Enterprise-Scale Landing Zone architecture:
    - Management Group hierarchy
    - Policy assignments for governance
    - Hub-spoke network topology
    - Identity and access management structure
    - Monitoring and logging configuration
#>

[CmdletBinding(SupportsShouldProcess)]
[CmdletBinding()]

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter(Mandatory)]
    [ValidateLength(2, 6)]
    [ValidatePattern('^[A-Z]+$')]
    [string]$ManagementGroupPrefix,

    [Parameter()]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$HubSubscriptionId,

    [Parameter()]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$IdentitySubscriptionId,

    [Parameter()]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$ManagementSubscriptionId,

    [Parameter()]
    [ValidateSet("eastus", "eastus2", "westus", "westus2", "westus3", "centralus", "northcentralus", "southcentralus", "westcentralus", "canadacentral", "canadaeast", "brazilsouth", "northeurope", "westeurope", "uksouth", "ukwest", "francecentral", "germanywestcentral", "norwayeast", "switzerlandnorth", "swedencentral", "australiaeast", "australiasoutheast", "southeastasia", "eastasia", "japaneast", "japanwest", "koreacentral", "southafricanorth", "uaenorth")]
    [string]$Location = "eastus",

    [Parameter()]
    [ValidateSet("eastus", "eastus2", "westus", "westus2", "westus3", "centralus", "northcentralus", "southcentralus", "westcentralus", "canadacentral", "canadaeast", "brazilsouth", "northeurope", "westeurope", "uksouth", "ukwest", "francecentral", "germanywestcentral", "norwayeast", "switzerlandnorth", "swedencentral", "australiaeast", "australiasoutheast", "southeastasia", "eastasia", "japaneast", "japanwest", "koreacentral", "southafricanorth", "uaenorth")]
    [string]$SecondaryLocation = "westus2",

    [Parameter()]
    [ValidateLength(2, 20)]
    [ValidatePattern('^[A-Za-z0-9\s]+$')]
    [string]$CompanyName = "Enterprise",

    [Parameter()]
    [switch]$WhatIf
)

# Global variables for consistent naming
$script:DeploymentTimestamp = Get-Date -Format "yyyyMMdd-HHmm"
$script:LogFile = "LandingZone-Deployment-$script:DeploymentTimestamp.log"

[OutputType([PSObject])]
 {
    [CmdletBinding()]

        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to console with appropriate color
    switch ($Level) {
        "Info" { Write-Information $logEntry -InformationAction Continue }
        "Warning" { Write-Warning $logEntry }
        "Error" { Write-Error $logEntry }
        "Success" { Write-Host $logEntry -ForegroundColor Green }
    }

    # Write to log file
    Add-Content -Path $script:LogFile -Value $logEntry
}

function Test-Prerequisites {
    Write-LogMessage "Validating prerequisites..."

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "PowerShell 7.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    }

    # Check Azure PowerShell modules
    $requiredModules = @("Az.Resources", "Az.Profile", "Az.PolicyInsights", "Az.ManagementGroups")
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -Name $module -ListAvailable)) {
            throw "Required module '$module' is not installed. Run: Install-Module -Name $module"
        }
    }

    # Test Azure connection
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-LogMessage "Connecting to Azure..."
            Connect-AzAccount -TenantId $TenantId
            $context = Get-AzContext
        }

        if ($context.Tenant.Id -ne $TenantId) {
            throw "Connected to wrong tenant. Expected: $TenantId, Actual: $($context.Tenant.Id)"
        }

        Write-LogMessage "Connected to Azure tenant: $($context.Tenant.Id)" -Level Success
    }
    catch {
        throw "Failed to connect to Azure: $($_.Exception.Message)"
    }

    # Validate permissions
    try {
        $null = Get-AzManagementGroup -ErrorAction Stop
        Write-LogMessage "Management Group permissions validated" -Level Success
    }
    catch {
        throw "Insufficient permissions. Global Administrator or Management Group Contributor role required."
    }
}

function New-ManagementGroupHierarchy {
    Write-LogMessage "Creating management group hierarchy..."

    $managementGroups = @(
        @{
            Name = "$ManagementGroupPrefix-Root"
            DisplayName = "$CompanyName Root"
            ParentId = $null
        },
        @{
            Name = "$ManagementGroupPrefix-Platform"
            DisplayName = "$CompanyName Platform"
            ParentId = "$ManagementGroupPrefix-Root"
        },
        @{
            Name = "$ManagementGroupPrefix-LandingZones"
            DisplayName = "$CompanyName Landing Zones"
            ParentId = "$ManagementGroupPrefix-Root"
        },
        @{
            Name = "$ManagementGroupPrefix-Sandbox"
            DisplayName = "$CompanyName Sandbox"
            ParentId = "$ManagementGroupPrefix-Root"
        },
        @{
            Name = "$ManagementGroupPrefix-Decommissioned"
            DisplayName = "$CompanyName Decommissioned"
            ParentId = "$ManagementGroupPrefix-Root"
        },
        @{
            Name = "$ManagementGroupPrefix-Management"
            DisplayName = "$CompanyName Management"
            ParentId = "$ManagementGroupPrefix-Platform"
        },
        @{
            Name = "$ManagementGroupPrefix-Connectivity"
            DisplayName = "$CompanyName Connectivity"
            ParentId = "$ManagementGroupPrefix-Platform"
        },
        @{
            Name = "$ManagementGroupPrefix-Identity"
            DisplayName = "$CompanyName Identity"
            ParentId = "$ManagementGroupPrefix-Platform"
        },
        @{
            Name = "$ManagementGroupPrefix-Corp"
            DisplayName = "$CompanyName Corporate"
            ParentId = "$ManagementGroupPrefix-LandingZones"
        },
        @{
            Name = "$ManagementGroupPrefix-Online"
            DisplayName = "$CompanyName Online"
            ParentId = "$ManagementGroupPrefix-LandingZones"
        }
    )

    foreach ($mg in $managementGroups) {
        try {
            $existingMG = Get-AzManagementGroup -GroupName $mg.Name -ErrorAction SilentlyContinue

            if ($existingMG) {
                Write-LogMessage "Management group '$($mg.Name)' already exists" -Level Warning
                continue
            }

            if ($WhatIf) {
                Write-LogMessage "WHATIF: Would create management group '$($mg.Name)'"
                continue
            }

            $mgParams = @{
                GroupName = $mg.Name
                DisplayName = $mg.DisplayName
            }

            if ($mg.ParentId) {
                $mgParams.ParentId = "/providers/Microsoft.Management/managementGroups/$($mg.ParentId)"
            }

            $null = New-AzManagementGroup @mgParams
            Write-LogMessage "Created management group: $($mg.DisplayName)" -Level Success

            # Wait for replication
            Start-Sleep -Seconds 5
        }
        catch {
            Write-LogMessage "Failed to create management group '$($mg.Name)': $($_.Exception.Message)" -Level Error
            throw
        }
    }
}

function Set-PolicyAssignments {
    Write-LogMessage "Configuring policy assignments..."

    # Core policy initiatives for Landing Zone
    $policyAssignments = @(
        @{
            Name = "Enforce-ALZ-Governance"
            DisplayName = "Enforce Azure Landing Zone Governance"
            PolicyDefinitionId = "/providers/Microsoft.Authorization/policySetDefinitions/f9aa1f12-b769-4f22-b2d4-8e9f82da5c8c"
            Scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupPrefix-Root"
            Description = "Core governance policies for Azure Landing Zone"
        },
        @{
            Name = "Enforce-Security-Center"
            DisplayName = "Enable Azure Security Center"
            PolicyDefinitionId = "/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
            Scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupPrefix-Root"
            Description = "Enable and configure Azure Security Center"
        },
        @{
            Name = "Enforce-Monitoring"
            DisplayName = "Enable Monitoring and Logging"
            PolicyDefinitionId = "/providers/Microsoft.Authorization/policySetDefinitions/55f3eceb-5573-4f18-9695-226972c6d74a"
            Scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupPrefix-Platform"
            Description = "Enforce monitoring and logging requirements"
        }
    )

    foreach ($assignment in $policyAssignments) {
        try {
            if ($WhatIf) {
                Write-LogMessage "WHATIF: Would assign policy '$($assignment.DisplayName)' to scope '$($assignment.Scope)'"
                continue
            }

            $existingAssignment = Get-AzPolicyAssignment -Name $assignment.Name -Scope $assignment.Scope -ErrorAction SilentlyContinue

            if ($existingAssignment) {
                Write-LogMessage "Policy assignment '$($assignment.Name)' already exists" -Level Warning
                continue
            }

            $assignmentParams = @{
                Name = $assignment.Name
                DisplayName = $assignment.DisplayName
                PolicySetDefinition = Get-AzPolicySetDefinition -Id $assignment.PolicyDefinitionId
                Scope = $assignment.Scope
                Description = $assignment.Description
                Location = $Location
                AssignIdentity = $true
            }

            $null = New-AzPolicyAssignment @assignmentParams
            Write-LogMessage "Assigned policy: $($assignment.DisplayName)" -Level Success
        }
        catch {
            Write-LogMessage "Failed to assign policy '$($assignment.Name)': $($_.Exception.Message)" -Level Warning
            # Continue with other assignments
        }
    }
}

function Move-SubscriptionsToManagementGroups {
    Write-LogMessage "Moving subscriptions to appropriate management groups..."

    $subscriptionMappings = @()

    if ($HubSubscriptionId) {
        $subscriptionMappings += @{
            SubscriptionId = $HubSubscriptionId
            ManagementGroup = "$ManagementGroupPrefix-Connectivity"
            Purpose = "Hub/Connectivity"
        }
    }

    if ($IdentitySubscriptionId) {
        $subscriptionMappings += @{
            SubscriptionId = $IdentitySubscriptionId
            ManagementGroup = "$ManagementGroupPrefix-Identity"
            Purpose = "Identity"
        }
    }

    if ($ManagementSubscriptionId) {
        $subscriptionMappings += @{
            SubscriptionId = $ManagementSubscriptionId
            ManagementGroup = "$ManagementGroupPrefix-Management"
            Purpose = "Management/Monitoring"
        }
    }

    foreach ($mapping in $subscriptionMappings) {
        try {
            if ($WhatIf) {
                Write-LogMessage "WHATIF: Would move subscription '$($mapping.SubscriptionId)' to management group '$($mapping.ManagementGroup)'"
                continue
            }

            # Verify subscription exists and is accessible
            $subscription = Get-AzSubscription -SubscriptionId $mapping.SubscriptionId -ErrorAction Stop

            $null = New-AzManagementGroupSubscription -GroupName $mapping.ManagementGroup -SubscriptionId $mapping.SubscriptionId
            Write-LogMessage "Moved $($mapping.Purpose) subscription '$($subscription.Name)' to management group '$($mapping.ManagementGroup)'" -Level Success
        }
        catch {
            Write-LogMessage "Failed to move subscription '$($mapping.SubscriptionId)': $($_.Exception.Message)" -Level Warning
            # Continue with other subscriptions
        }
    }
}

function New-HubNetworkInfrastructure {
    if (-not $HubSubscriptionId) {
        Write-LogMessage "Hub subscription not specified, skipping hub network creation" -Level Warning
        return
    }

    Write-LogMessage "Creating hub network infrastructure..."

    try {
        # Set context to hub subscription
        $null = Set-AzContext -SubscriptionId $HubSubscriptionId

        $resourceGroupName = "rg-$ManagementGroupPrefix-connectivity-$Location"
        $vnetName = "vnet-$ManagementGroupPrefix-hub-$Location"
        $bastionName = "bas-$ManagementGroupPrefix-hub-$Location"
        $firewallName = "afw-$ManagementGroupPrefix-hub-$Location"

        if ($WhatIf) {
            Write-LogMessage "WHATIF: Would create hub network infrastructure in subscription '$HubSubscriptionId'"
            return
        }

        # Create resource group
        $rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
        if (-not $rg) {
            $resourcegroupSplat = @{
    Name = $resourceGroupName
    Location = $Location
    Tag = @{
}
New-AzResourceGroup @resourcegroupSplat
                Purpose = "Connectivity Hub"
                Environment = "Production"
                Owner = $CompanyName
            }
            Write-LogMessage "Created resource group: $resourceGroupName" -Level Success
        }

        # Create hub virtual network
        $existingVnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName -ErrorAction SilentlyContinue
        if (-not $existingVnet) {
            $subnetConfigs = @(
                New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix "10.0.0.0/24"
                New-AzVirtualNetworkSubnetConfig -Name "AzureFirewallSubnet" -AddressPrefix "10.0.1.0/24"
                New-AzVirtualNetworkSubnetConfig -Name "AzureBastionSubnet" -AddressPrefix "10.0.2.0/24"
                New-AzVirtualNetworkSubnetConfig -Name "SharedServices" -AddressPrefix "10.0.10.0/24"
            )

            $virtualnetworkSplat = @{
    Name = $vnetName
    ResourceGroupName = $resourceGroupName
    Location = $Location
    AddressPrefix = "10.0.0.0/16"
    Subnet = $subnetConfigs
}
New-AzVirtualNetwork @virtualnetworkSplat
            Write-LogMessage "Created hub virtual network: $vnetName" -Level Success
        } else {
            Write-LogMessage "Hub virtual network already exists: $vnetName" -Level Warning
        }

        Write-LogMessage "Hub network infrastructure setup completed" -Level Success
    }
    catch {
        Write-LogMessage "Failed to create hub network infrastructure: $($_.Exception.Message)" -Level Error
        throw
    }
}

function New-MonitoringInfrastructure {
    if (-not $ManagementSubscriptionId) {
        Write-LogMessage "Management subscription not specified, skipping monitoring infrastructure" -Level Warning
        return
    }

    Write-LogMessage "Creating monitoring infrastructure..."

    try {
        # Set context to management subscription
        $null = Set-AzContext -SubscriptionId $ManagementSubscriptionId

        $resourceGroupName = "rg-$ManagementGroupPrefix-management-$Location"
        $workspaceName = "law-$ManagementGroupPrefix-$Location"
        $automationAccountName = "aa-$ManagementGroupPrefix-$Location"

        if ($WhatIf) {
            Write-LogMessage "WHATIF: Would create monitoring infrastructure in subscription '$ManagementSubscriptionId'"
            return
        }

        # Create resource group
        $rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
        if (-not $rg) {
            $resourcegroupSplat = @{
    Name = $resourceGroupName
    Location = $Location
    Tag = @{
}
New-AzResourceGroup @resourcegroupSplat
                Purpose = "Management and Monitoring"
                Environment = "Production"
                Owner = $CompanyName
            }
            Write-LogMessage "Created resource group: $resourceGroupName" -Level Success
        }

        # Create Log Analytics workspace
        $existingWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        if (-not $existingWorkspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName -Location $Location -Sku "PerGB2018"
            Write-LogMessage "Created Log Analytics workspace: $workspaceName" -Level Success
        } else {
            Write-LogMessage "Log Analytics workspace already exists: $workspaceName" -Level Warning
        }

        Write-LogMessage "Monitoring infrastructure setup completed" -Level Success
    }
    catch {
        Write-LogMessage "Failed to create monitoring infrastructure: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Write-DeploymentSummary {
    Write-LogMessage "=== AZURE LANDING ZONE DEPLOYMENT SUMMARY ===" -Level Success
    Write-LogMessage ""
    Write-LogMessage "Tenant ID: $TenantId"
    Write-LogMessage "Management Group Prefix: $ManagementGroupPrefix"
    Write-LogMessage "Primary Location: $Location"
    Write-LogMessage "Secondary Location: $SecondaryLocation"
    Write-LogMessage "Company Name: $CompanyName"
    Write-LogMessage ""

    if ($WhatIf) {
        Write-LogMessage "*** WHATIF MODE - NO CHANGES WERE MADE ***" -Level Warning
    } else {
        Write-LogMessage "Deployment completed successfully!" -Level Success
    }

    Write-LogMessage ""
    Write-LogMessage "Next Steps:"
    Write-LogMessage "1. Review and customize policy assignments"
    Write-LogMessage "2. Configure network connectivity (ExpressRoute/VPN)"
    Write-LogMessage "3. Set up identity and access management"
    Write-LogMessage "4. Deploy workload landing zones"
    Write-LogMessage "5. Configure monitoring and alerting"
    Write-LogMessage ""
    Write-LogMessage "Log file: $script:LogFile"
}

# Main execution
try {
    Write-LogMessage "Starting Azure Landing Zone deployment..." -Level Success
    Write-LogMessage "Deployment ID: LZ-$script:DeploymentTimestamp"

    # Phase 1: Prerequisites
    Test-Prerequisites

    # Phase 2: Management Groups
    New-ManagementGroupHierarchy

    # Phase 3: Policy Assignments
    Set-PolicyAssignments

    # Phase 4: Subscription Management
    Move-SubscriptionsToManagementGroups

    # Phase 5: Hub Network (if specified)
    if ($HubSubscriptionId) {
        New-HubNetworkInfrastructure
    }

    # Phase 6: Monitoring Infrastructure (if specified)
    if ($ManagementSubscriptionId) {
        New-MonitoringInfrastructure
    }

    # Phase 7: Summary
    Write-DeploymentSummary
}
catch {
    Write-LogMessage "DEPLOYMENT FAILED: $($_.Exception.Message)" -Level Error
    Write-LogMessage "Check log file for details: $script:LogFile" -Level Error
    throw
}

