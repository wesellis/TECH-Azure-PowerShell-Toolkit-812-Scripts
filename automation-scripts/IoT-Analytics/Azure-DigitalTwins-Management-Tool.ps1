#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.Resources, Az.DigitalTwins

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Digital Twins Enterprise Management Tool
.DESCRIPTION
    Comprehensive tool for creating, configuring, and managing Azure Digital Twins instances
    with enterprise-grade security, monitoring, and integration capabilities.
.PARAMETER ResourceGroupName
    Target Resource Group for Digital Twins instance
.PARAMETER InstanceName
    Name of the Azure Digital Twins instance
.PARAMETER Location
    Azure region for the Digital Twins instance
.PARAMETER Action
    Action to perform (Create, Delete, Update, Configure, Monitor)
.PARAMETER ModelDefinitions
    Path to DTDL model definitions directory
.PARAMETER EnablePrivateEndpoint
    Create private endpoint for secure access
.PARAMETER EnableEventRouting
    Configure event routing to Event Hub/Service Bus
.PARAMETER EventHubNamespace
    Event Hub namespace for event routing
.PARAMETER EventHubName
    Event Hub name for telemetry data
.PARAMETER EnableTimeSeriesInsights
    Connect to Time Series Insights for analytics
.PARAMETER Tags
    Tags to apply to resources
.PARAMETER EnableDiagnostics
    Enable diagnostic logging
.PARAMETER AssignRoles
    Assign RBAC roles for Digital Twins access
.EXAMPLE
    .\Azure-DigitalTwins-Management-Tool.ps1 -ResourceGroupName "dt-rg" -InstanceName "factory-dt" -Location "East US" -Action "Create" -EnableEventRouting -EnableTimeSeriesInsights
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Az.DigitalTwins module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$InstanceName,
    
    [Parameter(Mandatory = $true)]
    [string]$Location,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "Delete", "Update", "Configure", "Monitor", "Deploy")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$ModelDefinitions,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnablePrivateEndpoint,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableEventRouting,
    
    [Parameter(Mandatory = $false)]
    [string]$EventHubNamespace,
    
    [Parameter(Mandatory = $false)]
    [string]$EventHubName = "digitaltwins-telemetry",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableTimeSeriesInsights,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Production"
        Application = "DigitalTwins"
        ManagedBy = "AutomationScript"
    },
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableDiagnostics,
    
    [Parameter(Mandatory = $false)]
    [switch]$AssignRoles
)

#region Functions

# Import required modules
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.DigitalTwins -Force -ErrorAction Stop
    Import-Module Az.EventHub -Force -ErrorAction Stop
    Write-Information " Successfully imported required Azure modules"
} catch {
    Write-Error " Failed to import required modules: $($_.Exception.Message)"
    exit 1
}

# Enhanced logging function
[CmdletBinding()]
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
    
    Write-Information "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}

# Create Azure Digital Twins instance
[CmdletBinding()]
function New-DigitalTwinsInstance -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("Digital Twins instance '$InstanceName'", "Create")) {
        try {
            Write-EnhancedLog "Creating Azure Digital Twins instance: $InstanceName" "Info"
        
        # Check if instance already exists
        $existingInstance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName -ErrorAction SilentlyContinue
        if ($existingInstance) {
            Write-EnhancedLog "Digital Twins instance already exists: $InstanceName" "Warning"
            return $existingInstance
        }
        
        # Create Digital Twins instance
        $dtParams = @{
            ResourceGroupName = $ResourceGroupName
            ResourceName = $InstanceName
            Location = $Location
            Tag = $Tags
        }
        
        $digitalTwinsInstance = New-AzDigitalTwinsInstance -ErrorAction Stop @dtParams
        Write-EnhancedLog "Successfully created Digital Twins instance: $($digitalTwinsInstance.Name)" "Success"
        
        # Wait for instance to be ready
        do {
            Start-Sleep -Seconds 30
            $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName
            Write-EnhancedLog "Instance provisioning state: $($instance.ProvisioningState)" "Info"
        } while ($instance.ProvisioningState -eq "Provisioning")
        
        if ($instance.ProvisioningState -eq "Succeeded") {
            Write-EnhancedLog "Digital Twins instance is ready for use" "Success"
            return $instance
        } else {
            throw "Digital Twins instance provisioning failed: $($instance.ProvisioningState)"
        }
        
    } catch {
        Write-EnhancedLog "Failed to create Digital Twins instance: $($_.Exception.Message)" "Error"
        throw
    }
    }
}

# Configure private endpoint
[CmdletBinding()]
function New-PrivateEndpoint -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$DigitalTwinsInstance)
    
    if ($PSCmdlet.ShouldProcess("Private endpoint for '$InstanceName'", "Create")) {
        try {
            Write-EnhancedLog "Configuring private endpoint for Digital Twins instance" "Info"
        
        # Create private DNS zone
        $privateDnsZoneName = "privatelink.digitaltwins.azure.net"
        $privateDnsZone = New-AzPrivateDnsZone -ResourceGroupName $ResourceGroupName -Name $privateDnsZoneName
        Write-EnhancedLog "Created private DNS zone: $($privateDnsZone.Name)" "Success"
        
        # Create private endpoint
        $privateEndpointName = "$InstanceName-pe"
        $vnetName = "$ResourceGroupName-vnet"
        $subnetName = "privatelink-subnet"
        
        # Create VNet if not exists
        $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $vnetName -ErrorAction SilentlyContinue
        if (-not $vnet) {
            $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.1.0/24"
            $vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $vnetName -AddressPrefix "10.0.0.0/16" -Subnet $subnetConfig
        }
        
        # Create private endpoint connection
        $privateEndpointConnection = New-AzPrivateLinkServiceConnection -Name "$privateEndpointName-connection" -PrivateLinkServiceId $DigitalTwinsInstance.Id -GroupId "API"
        $privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -Name $privateEndpointName -Location $Location -Subnet $vnet.Subnets[0] -PrivateLinkServiceConnection $privateEndpointConnection
        
        Write-EnhancedLog "Successfully configured private endpoint: $privateEndpointName" "Success"
        return $privateEndpoint
        
    } catch {
        Write-EnhancedLog "Failed to configure private endpoint: $($_.Exception.Message)" "Error"
    }
    }
}

# Configure event routing
[CmdletBinding()]
function Set-EventRouting -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$DigitalTwinsInstance)
    
    if ($PSCmdlet.ShouldProcess("Event routing for '$InstanceName'", "Configure")) {
        try {
            Write-EnhancedLog "Configuring event routing for Digital Twins instance" "Info"
        
        # Create Event Hub namespace if not exists
        if (-not $EventHubNamespace) {
            $EventHubNamespace = "$InstanceName-eventhub-ns"
        }
        
        $ehNamespace = Get-AzEventHubNamespace -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -ErrorAction SilentlyContinue
        if (-not $ehNamespace) {
            $ehNamespace = New-AzEventHubNamespace -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -Location $Location -SkuName "Standard"
            Write-EnhancedLog "Created Event Hub namespace: $EventHubNamespace" "Success"
        }
        
        # Create Event Hub
        $eventHub = Get-AzEventHub -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -EventHubName $EventHubName -ErrorAction SilentlyContinue
        if (-not $eventHub) {
            $eventHub = New-AzEventHub -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -EventHubName $EventHubName -MessageRetentionInDays 7 -PartitionCount 4
            Write-EnhancedLog "Created Event Hub: $EventHubName" "Success"
        }
        
        # Create event route endpoint
        $endpointName = "telemetry-endpoint"
        $endpointParams = @{
            ResourceGroupName = $ResourceGroupName
            ResourceName = $InstanceName
            EndpointName = $endpointName
            EndpointType = "EventHub"
            ConnectionString = (Get-AzEventHubKey -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -AuthorizationRuleName "RootManageSharedAccessKey").PrimaryConnectionString
            EventHubName = $EventHubName
        }
        
        New-AzDigitalTwinsEndpoint -ErrorAction Stop @endpointParams
        
        # Create event route
        $routeName = "telemetry-route"
        $filter = "type = 'Microsoft.DigitalTwins.Twin.Telemetry'"
        
        New-AzDigitalTwinsEventRoute -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName -EventRouteName $routeName -EndpointName $endpointName -Filter $filter
        
        Write-EnhancedLog "Successfully configured event routing to Event Hub" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to configure event routing: $($_.Exception.Message)" "Error"
    }
    }
}

# Deploy Digital Twins model
[CmdletBinding()]
function Install-DigitalTwinsModel {
    param(
        [object]$DigitalTwinsInstance,
        [string]$ModelsPath
    )
    
    try {
        if (-not $ModelsPath -or -not (Test-Path $ModelsPath)) {
            Write-EnhancedLog "Creating sample Digital Twins models..." "Info"
            
            # Create sample DTDL models
            $factoryModel = @{
                "@id" = "dtmi:com:example:Factory;1"
                "@type" = "Interface"
                "displayName" = "Factory"
                "@context" = "dtmi:dtdl:context;2"
                "contents" = @(
                    @{
                        "@type" = "Property"
                        "name" = "FactoryName"
                        "schema" = "string"
                    },
                    @{
                        "@type" = "Property"
                        "name" = "Location"
                        "schema" = "string"
                    },
                    @{
                        "@type" = "Telemetry"
                        "name" = "Temperature"
                        "schema" = "double"
                    },
                    @{
                        "@type" = "Relationship"
                        "name" = "contains"
                        "target" = "dtmi:com:example:ProductionLine;1"
                    }
                )
            }
            
            $productionLineModel = @{
                "@id" = "dtmi:com:example:ProductionLine;1"
                "@type" = "Interface"
                "displayName" = "Production Line"
                "@context" = "dtmi:dtdl:context;2"
                "contents" = @(
                    @{
                        "@type" = "Property"
                        "name" = "LineNumber"
                        "schema" = "integer"
                    },
                    @{
                        "@type" = "Property"
                        "name" = "Status"
                        "schema" = "string"
                    },
                    @{
                        "@type" = "Telemetry"
                        "name" = "Throughput"
                        "schema" = "double"
                    },
                    @{
                        "@type" = "Telemetry"
                        "name" = "Efficiency"
                        "schema" = "double"
                    }
                )
            }
            
            # Deploy models using Azure CLI (as Az.DigitalTwins doesn't have direct model upload)
            $factoryModelJson = $factoryModel | ConvertTo-Json -Depth 10
            $productionLineModelJson = $productionLineModel | ConvertTo-Json -Depth 10
            
            $factoryModelJson | Out-File -FilePath ".\factory-model.json" -Encoding UTF8
            $productionLineModelJson | Out-File -FilePath ".\production-line-model.json" -Encoding UTF8
            
            # Use Azure CLI to upload models
            
            az dt model create --dt-name $InstanceName --models ".\factory-model.json" ".\production-line-model.json"
            
            Write-EnhancedLog "Successfully deployed sample Digital Twins models" "Success"
            
            # Create sample twins
            $factoryTwin = @{
                "\$metadata" = @{
                    "\$model" = "dtmi:com:example:Factory;1"
                }
                "FactoryName" = "Main Production Facility"
                "Location" = "Seattle, WA"
            }
            
            $productionLineTwin = @{
                "\$metadata" = @{
                    "\$model" = "dtmi:com:example:ProductionLine;1"
                }
                "LineNumber" = 1
                "Status" = "Running"
            }
            
            $factoryTwinJson = $factoryTwin | ConvertTo-Json -Depth 10
            $productionLineTwinJson = $productionLineTwin | ConvertTo-Json -Depth 10
            
            $factoryTwinJson | Out-File -FilePath ".\factory-twin.json" -Encoding UTF8
            $productionLineTwinJson | Out-File -FilePath ".\production-line-twin.json" -Encoding UTF8
            
            # Create twins
            az dt twin create --dt-name $InstanceName --dtmi "dtmi:com:example:Factory;1" --twin-id "Factory-001" --properties ".\factory-twin.json"
            az dt twin create --dt-name $InstanceName --dtmi "dtmi:com:example:ProductionLine;1" --twin-id "ProductionLine-001" --properties ".\production-line-twin.json"
            
            # Create relationship
            az dt twin relationship create --dt-name $InstanceName --relationship-id "factory-contains-line" --relationship "contains" --source "Factory-001" --target "ProductionLine-001"
            
            Write-EnhancedLog "Successfully created sample digital twins and relationships" "Success"
            
        } else {
            Write-EnhancedLog "Deploying models from: $ModelsPath" "Info"
            $modelFiles = Get-ChildItem -Path $ModelsPath -Filter "*.json"
            
            foreach ($modelFile in $modelFiles) {
                az dt model create --dt-name $InstanceName --models $modelFile.FullName
                Write-EnhancedLog "Deployed model: $($modelFile.Name)" "Success"
            }
        }
        
    } catch {
        Write-EnhancedLog "Failed to deploy Digital Twins models: $($_.Exception.Message)" "Error"
    }
}

# Configure diagnostic setting
[CmdletBinding()]
function Set-DiagnosticSetting -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$DigitalTwinsInstance)
    
    if ($PSCmdlet.ShouldProcess("Diagnostic settings for '$InstanceName'", "Configure")) {
        try {
            Write-EnhancedLog "Configuring diagnostic settings for Digital Twins instance" "Info"
        
        # Create Log Analytics workspace
        $workspaceName = "law-$ResourceGroupName-dt"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location
            Write-EnhancedLog "Created Log Analytics workspace: $workspaceName" "Success"
        }
        
        # Configure diagnostic settings
        $diagnosticName = "$InstanceName-diagnostics"
        $logs = @(
            @{
                Category = "DigitalTwinsOperation"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            },
            @{
                Category = "EventRoutesOperation"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            },
            @{
                Category = "ModelsOperation"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            },
            @{
                Category = "QueryOperation"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            }
        )
        
        $metrics = @(
            @{
                Category = "AllMetrics"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            }
        )
        
        Set-AzDiagnosticSetting -ResourceId $DigitalTwinsInstance.Id -WorkspaceId $workspace.ResourceId -Log $logs -Metric $metrics -Name $diagnosticName
        
        Write-EnhancedLog "Successfully configured diagnostic settings" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to configure diagnostic settings: $($_.Exception.Message)" "Error"
    }
    }
}

# Assign RBAC role
[CmdletBinding()]
function Set-RoleAssignment -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$DigitalTwinsInstance)
    
    if ($PSCmdlet.ShouldProcess("RBAC roles for '$InstanceName'", "Configure")) {
        try {
            Write-EnhancedLog "Configuring RBAC roles for Digital Twins instance" "Info"
        
        # Get current user
        $currentUser = Get-AzContext -ErrorAction Stop
        
        # Assign Azure Digital Twins Data Owner role
        New-AzRoleAssignment -ObjectId $currentUser.Account.Id -RoleDefinitionName "Azure Digital Twins Data Owner" -Scope $DigitalTwinsInstance.Id
        
        Write-EnhancedLog "Successfully assigned Digital Twins Data Owner role to current user" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to assign RBAC roles: $($_.Exception.Message)" "Error"
    }
    }
}

# Monitor Digital Twins instance
[CmdletBinding()]
function Get-DigitalTwinsStatus -ErrorAction Stop {
    param([object]$DigitalTwinsInstance)
    
    try {
        Write-EnhancedLog "Monitoring Digital Twins instance status..." "Info"
        
        # Get instance details
        $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName
        
        Write-EnhancedLog "Instance Status:" "Info"
        Write-EnhancedLog "  Name: $($instance.Name)" "Info"
        Write-EnhancedLog "  Location: $($instance.Location)" "Info"
        Write-EnhancedLog "  Provisioning State: $($instance.ProvisioningState)" "Info"
        Write-EnhancedLog "  Host Name: $($instance.HostName)" "Info"
        Write-EnhancedLog "  Created Time: $($instance.CreatedTime)" "Info"
        
        # Get models count
        $modelsCount = (az dt model list --dt-name $InstanceName --query "length(@)") 
        Write-EnhancedLog "  Models Count: $modelsCount" "Info"
        
        # Get twins count
        $twinsCount = (az dt twin query --dt-name $InstanceName --query-command "SELECT COUNT() FROM DIGITALTWINS" --query "result[0].COUNT")
        Write-EnhancedLog "  Twins Count: $twinsCount" "Info"
        
        Write-EnhancedLog "Digital Twins monitoring completed" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to monitor Digital Twins instance: $($_.Exception.Message)" "Error"
    }
}

# Main execution
try {
    Write-EnhancedLog "Starting Azure Digital Twins Management Tool" "Info"
    Write-EnhancedLog "Action: $Action" "Info"
    Write-EnhancedLog "Instance Name: $InstanceName" "Info"
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
            $instance = New-DigitalTwinsInstance -ErrorAction Stop
            
            if ($EnablePrivateEndpoint) {
                New-PrivateEndpoint -DigitalTwinsInstance $instance
            }
            
            if ($EnableEventRouting) {
                Set-EventRouting -DigitalTwinsInstance $instance
            }
            
            if ($EnableDiagnostics) {
                Set-DiagnosticSetting -DigitalTwinsInstance $instance
            }
            
            if ($AssignRoles) {
                Set-RoleAssignment -DigitalTwinsInstance $instance
            }
        }
        
        "Deploy" {
            $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName
            Deploy-DigitalTwinsModel -DigitalTwinsInstance $instance -ModelsPath $ModelDefinitions
        }
        
        "Monitor" {
            $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName
            Get-DigitalTwinsStatus -DigitalTwinsInstance $instance
        }
        
        "Configure" {
            $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName
            
            if ($EnableEventRouting) {
                Set-EventRouting -DigitalTwinsInstance $instance
            }
            
            if ($EnableDiagnostics) {
                Set-DiagnosticSetting -DigitalTwinsInstance $instance
            }
        }
        
        "Delete" {
            Write-EnhancedLog "Deleting Digital Twins instance: $InstanceName" "Warning"
            Remove-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName -Force
            Write-EnhancedLog "Successfully deleted Digital Twins instance" "Success"
        }
    }
    
    Write-EnhancedLog "Azure Digital Twins Management Tool completed successfully" "Success"
    
} catch {
    Write-EnhancedLog "Tool execution failed: $($_.Exception.Message)" "Error"
    exit 1
}

#endregion
