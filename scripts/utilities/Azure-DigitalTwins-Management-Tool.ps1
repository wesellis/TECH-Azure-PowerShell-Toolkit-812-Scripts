#Requires -Version 7.4
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Digital Twins Enterprise Management Tool

.DESCRIPTION
    Tool for creating, configuring, and managing Azure Digital Twins instances
    with  security, monitoring, and integration capabilities.
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
    .\Azure-DigitalTwins-Management-Tool.ps1 -ResourceGroupName "dt-rg" -InstanceName "factory-dt" -Location "East US" -Action "Create" -EnableEventRouting -EnableTimeSeriesInsights
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Az.DigitalTwins module
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    $InstanceName,
    [Parameter(Mandatory = $true)]
    $Location,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "Delete", "Update", "Configure", "Monitor", "Deploy")]
    $Action,
    [Parameter(Mandatory = $false)]
    $ModelDefinitions,
    [Parameter(Mandatory = $false)]
    [switch]$EnablePrivateEndpoint,
    [Parameter(Mandatory = $false)]
    [switch]$EnableEventRouting,
    [Parameter(Mandatory = $false)]
    $EventHubNamespace,
    [Parameter(Mandatory = $false)]
    $EventHubName = "digitaltwins-telemetry",
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
    $ErrorActionPreference = 'Stop'

try {
                    Write-Output "Successfully imported required Azure modules"
} catch {
    Write-Error "Failed to import required modules: $($_.Exception.Message)"
    throw
}
function Write-Log {
    param(
        $Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        $Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow"
        Error = "Red"
        Success = "Green"
    }
    Write-Output "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}
function New-DigitalTwinsInstance -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Digital Twins instance '$InstanceName'", "Create")) {
        try {
            Write-Output "Creating Azure Digital Twins instance: $InstanceName" "Info"
    $ExistingInstance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName -ErrorAction SilentlyContinue
        if ($ExistingInstance) {
            Write-Output "Digital Twins instance already exists: $InstanceName" "Warning"
            return $ExistingInstance
        }
    $DtParams = @{
            ResourceGroupName = $ResourceGroupName
            ResourceName = $InstanceName
            Location = $Location
            Tag = $Tags
        }
    $DigitalTwinsInstance = New-AzDigitalTwinsInstance -ErrorAction Stop @dtParams
        Write-Output "Successfully created Digital Twins instance: $($DigitalTwinsInstance.Name)" "Success"
        do {
            Start-Sleep -Seconds 30
    $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName
            Write-Output "Instance provisioning state: $($instance.ProvisioningState)" "Info"
        } while ($instance.ProvisioningState -eq "Provisioning")
        if ($instance.ProvisioningState -eq "Succeeded") {
            Write-Output "Digital Twins instance is ready for use" "Success"
            return $instance
        } else {
            throw "Digital Twins instance provisioning failed: $($instance.ProvisioningState)"
        }
    } catch {
        Write-Output "Failed to create Digital Twins instance: $($_.Exception.Message)" "Error"
        throw
    }
    }
}
function New-PrivateEndpoint -ErrorAction Stop {
    param([object]$DigitalTwinsInstance)
    if ($PSCmdlet.ShouldProcess("Private endpoint for '$InstanceName'", "Create")) {
        try {
            Write-Output "Configuring private endpoint for Digital Twins instance" "Info"
    $PrivateDnsZoneName = "privatelink.digitaltwins.azure.net"
    $PrivateDnsZone = New-AzPrivateDnsZone -ResourceGroupName $ResourceGroupName -Name $PrivateDnsZoneName
        Write-Output "Created private DNS zone: $($PrivateDnsZone.Name)" "Success"
    $PrivateEndpointName = "$InstanceName-pe"
    $VnetName = "$ResourceGroupName-vnet"
    $SubnetName = "privatelink-subnet"
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VnetName -ErrorAction SilentlyContinue
        if (-not $vnet) {
    $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix "10.0.1.0/24"
    $VirtualnetworkSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    Name = $VnetName
    AddressPrefix = "10.0.0.0/16"
    Subnet = $SubnetConfig
}
New-AzVirtualNetwork @virtualnetworkSplat
        }
    $PrivateEndpointConnection = New-AzPrivateLinkServiceConnection -Name "$PrivateEndpointName-connection" -PrivateLinkServiceId $DigitalTwinsInstance.Id -GroupId "API"
    $PrivateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -Name $PrivateEndpointName -Location $Location -Subnet $vnet.Subnets[0] -PrivateLinkServiceConnection $PrivateEndpointConnection
        Write-Output "Successfully configured private endpoint: $PrivateEndpointName" "Success"
        return $PrivateEndpoint
    } catch {
        Write-Output "Failed to configure private endpoint: $($_.Exception.Message)" "Error"
    }
    }
}
function Set-EventRouting -ErrorAction Stop {
    param([object]$DigitalTwinsInstance)
    if ($PSCmdlet.ShouldProcess("Event routing for '$InstanceName'", "Configure")) {
        try {
            Write-Output "Configuring event routing for Digital Twins instance" "Info"
        if (-not $EventHubNamespace) {
    $EventHubNamespace = "$InstanceName-eventhub-ns"
        }
    $EhNamespace = Get-AzEventHubNamespace -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -ErrorAction SilentlyContinue
        if (-not $EhNamespace) {
    $EhNamespace = New-AzEventHubNamespace -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -Location $Location -SkuName "Standard"
            Write-Output "Created Event Hub namespace: $EventHubNamespace" "Success"
        }
    $EventHub = Get-AzEventHub -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -EventHubName $EventHubName -ErrorAction SilentlyContinue
        if (-not $EventHub) {
    $EventHub = New-AzEventHub -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -EventHubName $EventHubName -MessageRetentionInDays 7 -PartitionCount 4
            Write-Output "Created Event Hub: $EventHubName" "Success"
        }
    $EndpointName = "telemetry-endpoint"
    $EndpointParams = @{
            ResourceGroupName = $ResourceGroupName
            ResourceName = $InstanceName
            EndpointName = $EndpointName
            EndpointType = "EventHub"
            ConnectionString = (Get-AzEventHubKey -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -AuthorizationRuleName "RootManageSharedAccessKey").PrimaryConnectionString
            EventHubName = $EventHubName
        }
        New-AzDigitalTwinsEndpoint -ErrorAction Stop @endpointParams
    $RouteName = "telemetry-route"
    $filter = "type = 'Microsoft.DigitalTwins.Twin.Telemetry'"
        New-AzDigitalTwinsEventRoute -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName -EventRouteName $RouteName -EndpointName $EndpointName -Filter $filter
        Write-Output "Successfully configured event routing to Event Hub" "Success"
    } catch {
        Write-Output "Failed to configure event routing: $($_.Exception.Message)" "Error"
    }
    }
}
function Install-DigitalTwinsModel {
    param(
        [object]$DigitalTwinsInstance,
        $ModelsPath
    )
    try {
        if (-not $ModelsPath -or -not (Test-Path $ModelsPath)) {
            Write-Output "Creating sample Digital Twins models..." "Info"
    $FactoryModel = @{
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
    $ProductionLineModel = @{
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
    $FactoryModelJson = $FactoryModel | ConvertTo-Json -Depth 10
    $ProductionLineModelJson = $ProductionLineModel | ConvertTo-Json -Depth 10
    $FactoryModelJson | Out-File -FilePath ".\factory-model.json" -Encoding UTF8
    $ProductionLineModelJson | Out-File -FilePath ".\production-line-model.json" -Encoding UTF8
            az dt model create --dt-name $InstanceName --models ".\factory-model.json" ".\production-line-model.json"
            Write-Output "Successfully deployed sample Digital Twins models" "Success"
    $FactoryTwin = @{
                "\$metadata" = @{
                    "\$model" = "dtmi:com:example:Factory;1"
                }
                "FactoryName" = "Main Production Facility"
                "Location" = "Seattle, WA"
            }
    $ProductionLineTwin = @{
                "\$metadata" = @{
                    "\$model" = "dtmi:com:example:ProductionLine;1"
                }
                "LineNumber" = 1
                "Status" = "Running"
            }
    $FactoryTwinJson = $FactoryTwin | ConvertTo-Json -Depth 10
    $ProductionLineTwinJson = $ProductionLineTwin | ConvertTo-Json -Depth 10
    $FactoryTwinJson | Out-File -FilePath ".\factory-twin.json" -Encoding UTF8
    $ProductionLineTwinJson | Out-File -FilePath ".\production-line-twin.json" -Encoding UTF8
            az dt twin create --dt-name $InstanceName --dtmi "dtmi:com:example:Factory;1" --twin-id "Factory-001" --properties ".\factory-twin.json"
            az dt twin create --dt-name $InstanceName --dtmi "dtmi:com:example:ProductionLine;1" --twin-id "ProductionLine-001" --properties ".\production-line-twin.json"
            az dt twin relationship create --dt-name $InstanceName --relationship-id "factory-contains-line" --relationship "contains" --source "Factory-001" --target "ProductionLine-001"
            Write-Output "Successfully created sample digital twins and relationships" "Success"
        } else {
            Write-Output "Deploying models from: $ModelsPath" "Info"
    $ModelFiles = Get-ChildItem -Path $ModelsPath -Filter "*.json"
            foreach ($ModelFile in $ModelFiles) {
                az dt model create --dt-name $InstanceName --models $ModelFile.FullName
                Write-Output "Deployed model: $($ModelFile.Name)" "Success"
            }
        }
    } catch {
        Write-Output "Failed to deploy Digital Twins models: $($_.Exception.Message)" "Error"
    }
}
function Set-DiagnosticSetting -ErrorAction Stop {
    param([object]$DigitalTwinsInstance)
    if ($PSCmdlet.ShouldProcess("Diagnostic settings for '$InstanceName'", "Configure")) {
        try {
            Write-Output "Configuring diagnostic settings for Digital Twins instance" "Info"
    $WorkspaceName = "law-$ResourceGroupName-dt"
    $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
        if (-not $workspace) {
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Location $Location
            Write-Output "Created Log Analytics workspace: $WorkspaceName" "Success"
        }
    $DiagnosticName = "$InstanceName-diagnostics"
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
        Set-AzDiagnosticSetting -ResourceId $DigitalTwinsInstance.Id -WorkspaceId $workspace.ResourceId -Log $logs -Metric $metrics -Name $DiagnosticName
        Write-Output "Successfully configured diagnostic settings" "Success"
    } catch {
        Write-Output "Failed to configure diagnostic settings: $($_.Exception.Message)" "Error"
    }
    }
}
function Set-RoleAssignment -ErrorAction Stop {
    param([object]$DigitalTwinsInstance)
    if ($PSCmdlet.ShouldProcess("RBAC roles for '$InstanceName'", "Configure")) {
        try {
            Write-Output "Configuring RBAC roles for Digital Twins instance" "Info"
    $CurrentUser = Get-AzContext -ErrorAction Stop
        New-AzRoleAssignment -ObjectId $CurrentUser.Account.Id -RoleDefinitionName "Azure Digital Twins Data Owner" -Scope $DigitalTwinsInstance.Id
        Write-Output "Successfully assigned Digital Twins Data Owner role to current user" "Success"
    } catch {
        Write-Output "Failed to assign RBAC roles: $($_.Exception.Message)" "Error"
    }
    }
}
function Get-DigitalTwinsStatus -ErrorAction Stop {
    param([object]$DigitalTwinsInstance)
    try {
        Write-Output "Monitoring Digital Twins instance status..." "Info"
    $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName
        Write-Output "Instance Status:" "Info"
        Write-Output "Name: $($instance.Name)" "Info"
        Write-Output "Location: $($instance.Location)" "Info"
        Write-Output "Provisioning State: $($instance.ProvisioningState)" "Info"
        Write-Output "Host Name: $($instance.HostName)" "Info"
        Write-Output "Created Time: $($instance.CreatedTime)" "Info"
    $ModelsCount = (az dt model list --dt-name $InstanceName --query "length(@)")
        Write-Output "Models Count: $ModelsCount" "Info"
    $TwinsCount = (az dt twin query --dt-name $InstanceName --query-command "SELECT COUNT() FROM DIGITALTWINS" --query "result[0].COUNT")
        Write-Output "Twins Count: $TwinsCount" "Info"
        Write-Output "Digital Twins monitoring completed" "Success"
    } catch {
        Write-Output "Failed to monitor Digital Twins instance: $($_.Exception.Message)" "Error"
    }
}
try {
    Write-Output "Starting Azure Digital Twins Management Tool" "Info"
    Write-Output "Action: $Action" "Info"
    Write-Output "Instance Name: $InstanceName" "Info"
    Write-Output "Resource Group: $ResourceGroupName" "Info"
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Output "Creating resource group: $ResourceGroupName" "Info"
    $ResourcegroupSplat = @{
    Name = $ResourceGroupName
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
        Write-Output "Successfully created resource group" "Success"
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
            Write-Output "Deleting Digital Twins instance: $InstanceName" "Warning"
            Remove-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName -Force
            Write-Output "Successfully deleted Digital Twins instance" "Success"
        }
    }
    Write-Output "Azure Digital Twins Management Tool completed successfully" "Success"
} catch {
    Write-Output "Tool execution failed: $($_.Exception.Message)" "Error"
    throw`n}
