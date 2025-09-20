#Requires -Version 7.0
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Digitaltwins Management Tool

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Azure Digital Twins Enterprise Management Tool
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
    .\Azure-DigitalTwins-Management-Tool.ps1 -ResourceGroupName " dt-rg" -InstanceName " factory-dt" -Location "East US" -Action Create" -EnableEventRouting -EnableTimeSeriesInsights
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Az.DigitalTwins module
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$InstanceName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create" , "Delete" , "Update" , "Configure" , "Monitor" , "Deploy" )]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Action,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ModelDefinitions,
    [Parameter(Mandatory = $false)]
    [switch]$EnablePrivateEndpoint,
    [Parameter(Mandatory = $false)]
    [switch]$EnableEventRouting,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$EventHubNamespace,
    [Parameter(Mandatory = $false)]
    [string]$EventHubName = " digitaltwins-telemetry" ,
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
function New-DigitalTwinsInstance -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    if ($PSCmdlet.ShouldProcess("Digital Twins instance '$InstanceName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"ng Azure Digital Twins instance: $InstanceName" "Info"
        # Check if instance already exists
        $existingInstance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName -ErrorAction SilentlyContinue
        if ($existingInstance) {
            Write-Verbose "Log entry"ns instance already exists: $InstanceName" "Warning"
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
        Write-Verbose "Log entry"ns instance: $($digitalTwinsInstance.Name)" "Success"
        # Wait for instance to be ready
        do {
            Start-Sleep -Seconds 30
            $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName
            Write-Verbose "Log entry"nstance provisioning state: $($instance.ProvisioningState)" "Info"
        } while ($instance.ProvisioningState -eq "Provisioning" )
        if ($instance.ProvisioningState -eq "Succeeded" ) {
            Write-Verbose "Log entry"ns instance is ready for use" "Success"
            return $instance
        } else {
            throw "Digital Twins instance provisioning failed: $($instance.ProvisioningState)"
        }
    } catch {
        Write-Verbose "Log entry"ns instance: $($_.Exception.Message)" "Error"
        throw
    }
    }
}
function New-PrivateEndpoint -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$DigitalTwinsInstance)
    if ($PSCmdlet.ShouldProcess("Private endpoint for '$InstanceName'" , "Create" )) {
        try {
            Write-Verbose "Log entry"nfiguring private endpoint for Digital Twins instance" "Info"
        # Create private DNS zone
        $privateDnsZoneName = " privatelink.digitaltwins.azure.net"
        $privateDnsZone = New-AzPrivateDnsZone -ResourceGroupName $ResourceGroupName -Name $privateDnsZoneName
        Write-Verbose "Log entry"NS zone: $($privateDnsZone.Name)" "Success"
        # Create private endpoint
        $privateEndpointName = " $InstanceName-pe"
        $vnetName = " $ResourceGroupName-vnet"
        $subnetName = " privatelink-subnet"
        # Create VNet if not exists
        $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $vnetName -ErrorAction SilentlyContinue
        if (-not $vnet) {
            $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix " 10.0.1.0/24"
            $virtualnetworkSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    Name = $vnetName
    AddressPrefix = " 10.0.0.0/16"
    Subnet = $subnetConfig
}
New-AzVirtualNetwork @virtualnetworkSplat
        }
        # Create private endpoint connection
        $privateEndpointConnection = New-AzPrivateLinkServiceConnection -Name " $privateEndpointName-connection" -PrivateLinkServiceId $DigitalTwinsInstance.Id -GroupId "API"
        $privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -Name $privateEndpointName -Location $Location -Subnet $vnet.Subnets[0] -PrivateLinkServiceConnection $privateEndpointConnection
        Write-Verbose "Log entry"nfigured private endpoint: $privateEndpointName" "Success"
        return $privateEndpoint
    } catch {
        Write-Verbose "Log entry"nfigure private endpoint: $($_.Exception.Message)" "Error"
    }
    }
}
function Set-EventRouting -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$DigitalTwinsInstance)
    if ($PSCmdlet.ShouldProcess("Event routing for '$InstanceName'" , "Configure" )) {
        try {
            Write-Verbose "Log entry"nfiguring event routing for Digital Twins instance" "Info"
        # Create Event Hub namespace if not exists
        if (-not $EventHubNamespace) {
            $EventHubNamespace = " $InstanceName-eventhub-ns"
        }
        $ehNamespace = Get-AzEventHubNamespace -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -ErrorAction SilentlyContinue
        if (-not $ehNamespace) {
            $ehNamespace = New-AzEventHubNamespace -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -Location $Location -SkuName "Standard"
            Write-Verbose "Log entry"nt Hub namespace: $EventHubNamespace" "Success"
        }
        # Create Event Hub
        $eventHub = Get-AzEventHub -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -EventHubName $EventHubName -ErrorAction SilentlyContinue
        if (-not $eventHub) {
            $eventHub = New-AzEventHub -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -EventHubName $EventHubName -MessageRetentionInDays 7 -PartitionCount 4
            Write-Verbose "Log entry"nt Hub: $EventHubName" "Success"
        }
        # Create event route endpoint
        $endpointName = " telemetry-endpoint"
        $endpointParams = @{
            ResourceGroupName = $ResourceGroupName
            ResourceName = $InstanceName
            EndpointName = $endpointName
            EndpointType = "EventHub"
            ConnectionString = (Get-AzEventHubKey -ResourceGroupName $ResourceGroupName -NamespaceName $EventHubNamespace -AuthorizationRuleName "RootManageSharedAccessKey" ).PrimaryConnectionString
            EventHubName = $EventHubName
        }
        New-AzDigitalTwinsEndpoint -ErrorAction Stop @endpointParams
        # Create event route
        $routeName = " telemetry-route"
$filter = " type = 'Microsoft.DigitalTwins.Twin.Telemetry'"
        New-AzDigitalTwinsEventRoute -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName -EventRouteName $routeName -EndpointName $endpointName -Filter $filter
        Write-Verbose "Log entry"nfigured event routing to Event Hub" "Success"
    } catch {
        Write-Verbose "Log entry"nfigure event routing: $($_.Exception.Message)" "Error"
    }
    }
}
function Deploy-DigitalTwinsModel {
    param(
        [object]$DigitalTwinsInstance,
        [string]$ModelsPath
    )
    try {
        if (-not $ModelsPath -or -not (Test-Path $ModelsPath)) {
            Write-Verbose "Log entry"ng sample Digital Twins models..." "Info"
            # Create sample DTDL models
$factoryModel = @{
                " @id" = " dtmi:com:example:Factory;1"
                " @type" = "Interface"
                " displayName" = "Factory"
                " @context" = " dtmi:dtdl:context;2"
                " contents" = @(
                    @{
                        " @type" = "Property"
                        " name" = "FactoryName"
                        " schema" = " string"
                    },
                    @{
                        " @type" = "Property"
                        " name" = "Location"
                        " schema" = " string"
                    },
                    @{
                        " @type" = "Telemetry"
                        " name" = "Temperature"
                        " schema" = " double"
                    },
                    @{
                        " @type" = "Relationship"
                        " name" = " contains"
                        " target" = " dtmi:com:example:ProductionLine;1"
                    }
                )
            }
            $productionLineModel = @{
                " @id" = " dtmi:com:example:ProductionLine;1"
                " @type" = "Interface"
                " displayName" = "Production Line"
                " @context" = " dtmi:dtdl:context;2"
                " contents" = @(
                    @{
                        " @type" = "Property"
                        " name" = "LineNumber"
                        " schema" = " integer"
                    },
                    @{
                        " @type" = "Property"
                        " name" = "Status"
                        " schema" = " string"
                    },
                    @{
                        " @type" = "Telemetry"
                        " name" = "Throughput"
                        " schema" = " double"
                    },
                    @{
                        " @type" = "Telemetry"
                        " name" = "Efficiency"
                        " schema" = " double"
                    }
                )
            }
            # Deploy models using Azure CLI (as Az.DigitalTwins doesn't have direct model upload)
            $factoryModelJson = $factoryModel | ConvertTo-Json -Depth 10
$productionLineModelJson = $productionLineModel | ConvertTo-Json -Depth 10
            $factoryModelJson | Out-File -FilePath " .\factory-model.json" -Encoding UTF8
            $productionLineModelJson | Out-File -FilePath " .\production-line-model.json" -Encoding UTF8
            # Use Azure CLI to upload models
            az dt model create --dt-name $InstanceName --models " .\factory-model.json" " .\production-line-model.json"
            Write-Verbose "Log entry"ns models" "Success"
            # Create sample twins
$factoryTwin = @{
                " \$metadata" = @{
                    " \$model" = " dtmi:com:example:Factory;1"
                }
                "FactoryName" = "Main Production Facility"
                "Location" = "Seattle, WA"
            }
            $productionLineTwin = @{
                " \$metadata" = @{
                    " \$model" = " dtmi:com:example:ProductionLine;1"
                }
                "LineNumber" = 1
                "Status" = "Running"
            }
            $factoryTwinJson = $factoryTwin | ConvertTo-Json -Depth 10
$productionLineTwinJson = $productionLineTwin | ConvertTo-Json -Depth 10
            $factoryTwinJson | Out-File -FilePath " .\factory-twin.json" -Encoding UTF8
            $productionLineTwinJson | Out-File -FilePath " .\production-line-twin.json" -Encoding UTF8
            # Create twins
            az dt twin create --dt-name $InstanceName --dtmi " dtmi:com:example:Factory;1" --twin-id "Factory-001" --properties " .\factory-twin.json"
            az dt twin create --dt-name $InstanceName --dtmi " dtmi:com:example:ProductionLine;1" --twin-id "ProductionLine-001" --properties " .\production-line-twin.json"
            # Create relationship
            az dt twin relationship create --dt-name $InstanceName --relationship-id " factory-contains-line" --relationship " contains" --source "Factory-001" --target "ProductionLine-001"
            Write-Verbose "Log entry"ns and relationships" "Success"
        } else {
            Write-Verbose "Log entry"ng models from: $ModelsPath" "Info"
            $modelFiles = Get-ChildItem -Path $ModelsPath -Filter " *.json"
            foreach ($modelFile in $modelFiles) {
                az dt model create --dt-name $InstanceName --models $modelFile.FullName
                Write-Verbose "Log entry"Name)" "Success"
            }
        }
    } catch {
        Write-Verbose "Log entry"ns models: $($_.Exception.Message)" "Error"
    }
}
function Set-DiagnosticSetting -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$DigitalTwinsInstance)
    if ($PSCmdlet.ShouldProcess("Diagnostic settings for '$InstanceName'" , "Configure" )) {
        try {
            Write-Verbose "Log entry"nfiguring diagnostic settings for Digital Twins instance" "Info"
        # Create Log Analytics workspace
        $workspaceName = " law-$ResourceGroupName-dt"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location
            Write-Verbose "Log entry"nalytics workspace: $workspaceName" "Success"
        }
        # Configure diagnostic settings
        $diagnosticName = " $InstanceName-diagnostics"
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
        Write-Verbose "Log entry"nfigured diagnostic settings" "Success"
    } catch {
        Write-Verbose "Log entry"nfigure diagnostic settings: $($_.Exception.Message)" "Error"
    }
    }
}
function Set-RoleAssignment -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$DigitalTwinsInstance)
    if ($PSCmdlet.ShouldProcess("RBAC roles for '$InstanceName'" , "Configure" )) {
        try {
            Write-Verbose "Log entry"nfiguring RBAC roles for Digital Twins instance" "Info"
        # Get current user
        $currentUser = Get-AzContext -ErrorAction Stop
        # Assign Azure Digital Twins Data Owner role
        New-AzRoleAssignment -ObjectId $currentUser.Account.Id -RoleDefinitionName "Azure Digital Twins Data Owner" -Scope $DigitalTwinsInstance.Id
        Write-Verbose "Log entry"ned Digital Twins Data Owner role to current user" "Success"
    } catch {
        Write-Verbose "Log entry"n RBAC roles: $($_.Exception.Message)" "Error"
    }
    }
}
function Get-DigitalTwinsStatus -ErrorAction Stop {
    param([object]$DigitalTwinsInstance)
    try {
        Write-Verbose "Log entry"nitoring Digital Twins instance status..." "Info"
        # Get instance details
        $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName
        Write-Verbose "Log entry"nstance Status:" "Info"
        Write-Verbose "Log entry"Name: $($instance.Name)" "Info"
        Write-Verbose "Log entry"n: $($instance.Location)" "Info"
        Write-Verbose "Log entry"ning State: $($instance.ProvisioningState)" "Info"
        Write-Verbose "Log entry"Name: $($instance.HostName)" "Info"
        Write-Verbose "Log entry"nstance.CreatedTime)" "Info"
        # Get models count
        $modelsCount = (az dt model list --dt-name $InstanceName --query " length(@)" )
        Write-Verbose "Log entry"nt: $modelsCount" "Info"
        # Get twins count
        $twinsCount = (az dt twin query --dt-name $InstanceName --query-command "SELECT COUNT() FROM DIGITALTWINS" --query " result[0].COUNT" )
        Write-Verbose "Log entry"ns Count: $twinsCount" "Info"
        Write-Verbose "Log entry"ns monitoring completed" "Success"
    } catch {
        Write-Verbose "Log entry"nitor Digital Twins instance: $($_.Exception.Message)" "Error"
    }
}
try {
    Write-Verbose "Log entry"ng Azure Digital Twins Management Tool" "Info"
    Write-Verbose "Log entry"n: $Action" "Info"
    Write-Verbose "Log entry"nstance Name: $InstanceName" "Info"
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
            Write-Verbose "Log entry"ng Digital Twins instance: $InstanceName" "Warning"
            Remove-AzDigitalTwinsInstance -ResourceGroupName $ResourceGroupName -ResourceName $InstanceName -Force
            Write-Verbose "Log entry"ns instance" "Success"
        }
    }
    Write-Verbose "Log entry"ns Management Tool completed successfully" "Success"
} catch {
    Write-Verbose "Log entry"n failed: $($_.Exception.Message)" "Error"
    throw
}


