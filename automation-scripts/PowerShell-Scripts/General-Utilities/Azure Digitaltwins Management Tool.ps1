<#
.SYNOPSIS
    Azure Digitaltwins Management Tool

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
    We Enhanced Azure Digitaltwins Management Tool

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
    .\Azure-DigitalTwins-Management-Tool.ps1 -ResourceGroupName " dt-rg" -InstanceName " factory-dt" -Location " East US" -Action " Create" -EnableEventRouting -EnableTimeSeriesInsights
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Az.DigitalTwins module


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
    [string]$WEInstanceName,
    
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet(" Create" , " Delete" , " Update" , " Configure" , " Monitor" , " Deploy" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEModelDefinitions,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnablePrivateEndpoint,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableEventRouting,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEEventHubNamespace,
    
    [Parameter(Mandatory = $false)]
    [string]$WEEventHubName = " digitaltwins-telemetry" ,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableTimeSeriesInsights,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$WETags = @{
        Environment = " Production"
        Application = " DigitalTwins"
        ManagedBy = " AutomationScript"
    },
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableDiagnostics,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEAssignRoles
)


try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.DigitalTwins -Force -ErrorAction Stop
    Import-Module Az.EventHub -Force -ErrorAction Stop
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
function WE-New-DigitalTwinsInstance -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($WEPSCmdlet.ShouldProcess(" Digital Twins instance '$WEInstanceName'" , " Create" )) {
        try {
            Write-EnhancedLog " Creating Azure Digital Twins instance: $WEInstanceName" " Info"
        
        # Check if instance already exists
        $existingInstance = Get-AzDigitalTwinsInstance -ResourceGroupName $WEResourceGroupName -ResourceName $WEInstanceName -ErrorAction SilentlyContinue
        if ($existingInstance) {
            Write-EnhancedLog " Digital Twins instance already exists: $WEInstanceName" " Warning"
            return $existingInstance
        }
        
        # Create Digital Twins instance
        $dtParams = @{
            ResourceGroupName = $WEResourceGroupName
            ResourceName = $WEInstanceName
            Location = $WELocation
            Tag = $WETags
        }
        
        $digitalTwinsInstance = New-AzDigitalTwinsInstance -ErrorAction Stop @dtParams
        Write-EnhancedLog " Successfully created Digital Twins instance: $($digitalTwinsInstance.Name)" " Success"
        
        # Wait for instance to be ready
        do {
            Start-Sleep -Seconds 30
            $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $WEResourceGroupName -ResourceName $WEInstanceName
            Write-EnhancedLog " Instance provisioning state: $($instance.ProvisioningState)" " Info"
        } while ($instance.ProvisioningState -eq " Provisioning" )
        
        if ($instance.ProvisioningState -eq " Succeeded" ) {
            Write-EnhancedLog " Digital Twins instance is ready for use" " Success"
            return $instance
        } else {
            throw " Digital Twins instance provisioning failed: $($instance.ProvisioningState)"
        }
        
    } catch {
        Write-EnhancedLog " Failed to create Digital Twins instance: $($_.Exception.Message)" " Error"
        throw
    }
    }
}


[CmdletBinding()]
function WE-New-PrivateEndpoint -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$WEDigitalTwinsInstance)
    
    if ($WEPSCmdlet.ShouldProcess(" Private endpoint for '$WEInstanceName'" , " Create" )) {
        try {
            Write-EnhancedLog " Configuring private endpoint for Digital Twins instance" " Info"
        
        # Create private DNS zone
        $privateDnsZoneName = " privatelink.digitaltwins.azure.net"
        $privateDnsZone = New-AzPrivateDnsZone -ResourceGroupName $WEResourceGroupName -Name $privateDnsZoneName
        Write-EnhancedLog " Created private DNS zone: $($privateDnsZone.Name)" " Success"
        
        # Create private endpoint
        $privateEndpointName = " $WEInstanceName-pe"
        $vnetName = " $WEResourceGroupName-vnet"
        $subnetName = " privatelink-subnet"
        
        # Create VNet if not exists
        $vnet = Get-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Name $vnetName -ErrorAction SilentlyContinue
        if (-not $vnet) {
            $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix " 10.0.1.0/24"
            $vnet = New-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Location $WELocation -Name $vnetName -AddressPrefix " 10.0.0.0/16" -Subnet $subnetConfig
        }
        
        # Create private endpoint connection
        $privateEndpointConnection = New-AzPrivateLinkServiceConnection -Name " $privateEndpointName-connection" -PrivateLinkServiceId $WEDigitalTwinsInstance.Id -GroupId " API"
        $privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $WEResourceGroupName -Name $privateEndpointName -Location $WELocation -Subnet $vnet.Subnets[0] -PrivateLinkServiceConnection $privateEndpointConnection
        
        Write-EnhancedLog " Successfully configured private endpoint: $privateEndpointName" " Success"
        return $privateEndpoint
        
    } catch {
        Write-EnhancedLog " Failed to configure private endpoint: $($_.Exception.Message)" " Error"
    }
    }
}


[CmdletBinding()]
function WE-Set-EventRouting -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$WEDigitalTwinsInstance)
    
    if ($WEPSCmdlet.ShouldProcess(" Event routing for '$WEInstanceName'" , " Configure" )) {
        try {
            Write-EnhancedLog " Configuring event routing for Digital Twins instance" " Info"
        
        # Create Event Hub namespace if not exists
        if (-not $WEEventHubNamespace) {
            $WEEventHubNamespace = " $WEInstanceName-eventhub-ns"
        }
        
        $ehNamespace = Get-AzEventHubNamespace -ResourceGroupName $WEResourceGroupName -NamespaceName $WEEventHubNamespace -ErrorAction SilentlyContinue
        if (-not $ehNamespace) {
            $ehNamespace = New-AzEventHubNamespace -ResourceGroupName $WEResourceGroupName -NamespaceName $WEEventHubNamespace -Location $WELocation -SkuName " Standard"
            Write-EnhancedLog " Created Event Hub namespace: $WEEventHubNamespace" " Success"
        }
        
        # Create Event Hub
        $eventHub = Get-AzEventHub -ResourceGroupName $WEResourceGroupName -NamespaceName $WEEventHubNamespace -EventHubName $WEEventHubName -ErrorAction SilentlyContinue
        if (-not $eventHub) {
            $eventHub = New-AzEventHub -ResourceGroupName $WEResourceGroupName -NamespaceName $WEEventHubNamespace -EventHubName $WEEventHubName -MessageRetentionInDays 7 -PartitionCount 4
            Write-EnhancedLog " Created Event Hub: $WEEventHubName" " Success"
        }
        
        # Create event route endpoint
        $endpointName = " telemetry-endpoint"
        $endpointParams = @{
            ResourceGroupName = $WEResourceGroupName
            ResourceName = $WEInstanceName
            EndpointName = $endpointName
            EndpointType = " EventHub"
            ConnectionString = (Get-AzEventHubKey -ResourceGroupName $WEResourceGroupName -NamespaceName $WEEventHubNamespace -AuthorizationRuleName " RootManageSharedAccessKey" ).PrimaryConnectionString
            EventHubName = $WEEventHubName
        }
        
        New-AzDigitalTwinsEndpoint -ErrorAction Stop @endpointParams
        
        # Create event route
        $routeName = " telemetry-route"
       ;  $filter = " type = 'Microsoft.DigitalTwins.Twin.Telemetry'"
        
        New-AzDigitalTwinsEventRoute -ResourceGroupName $WEResourceGroupName -ResourceName $WEInstanceName -EventRouteName $routeName -EndpointName $endpointName -Filter $filter
        
        Write-EnhancedLog " Successfully configured event routing to Event Hub" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to configure event routing: $($_.Exception.Message)" " Error"
    }
    }
}


[CmdletBinding()]
function WE-Deploy-DigitalTwinsModel {
    param(
        [object]$WEDigitalTwinsInstance,
        [string]$WEModelsPath
    )
    
    try {
        if (-not $WEModelsPath -or -not (Test-Path $WEModelsPath)) {
            Write-EnhancedLog " Creating sample Digital Twins models..." " Info"
            
            # Create sample DTDL models
           ;  $factoryModel = @{
                " @id" = " dtmi:com:example:Factory;1"
                " @type" = " Interface"
                " displayName" = " Factory"
                " @context" = " dtmi:dtdl:context;2"
                " contents" = @(
                    @{
                        " @type" = " Property"
                        " name" = " FactoryName"
                        " schema" = " string"
                    },
                    @{
                        " @type" = " Property"
                        " name" = " Location"
                        " schema" = " string"
                    },
                    @{
                        " @type" = " Telemetry"
                        " name" = " Temperature"
                        " schema" = " double"
                    },
                    @{
                        " @type" = " Relationship"
                        " name" = " contains"
                        " target" = " dtmi:com:example:ProductionLine;1"
                    }
                )
            }
            
            $productionLineModel = @{
                " @id" = " dtmi:com:example:ProductionLine;1"
                " @type" = " Interface"
                " displayName" = " Production Line"
                " @context" = " dtmi:dtdl:context;2"
                " contents" = @(
                    @{
                        " @type" = " Property"
                        " name" = " LineNumber"
                        " schema" = " integer"
                    },
                    @{
                        " @type" = " Property"
                        " name" = " Status"
                        " schema" = " string"
                    },
                    @{
                        " @type" = " Telemetry"
                        " name" = " Throughput"
                        " schema" = " double"
                    },
                    @{
                        " @type" = " Telemetry"
                        " name" = " Efficiency"
                        " schema" = " double"
                    }
                )
            }
            
            # Deploy models using Azure CLI (as Az.DigitalTwins doesn't have direct model upload)
            $factoryModelJson = $factoryModel | ConvertTo-Json -Depth 10
           ;  $productionLineModelJson = $productionLineModel | ConvertTo-Json -Depth 10
            
            $factoryModelJson | Out-File -FilePath " .\factory-model.json" -Encoding UTF8
            $productionLineModelJson | Out-File -FilePath " .\production-line-model.json" -Encoding UTF8
            
            # Use Azure CLI to upload models
            
            az dt model create --dt-name $WEInstanceName --models " .\factory-model.json" " .\production-line-model.json"
            
            Write-EnhancedLog " Successfully deployed sample Digital Twins models" " Success"
            
            # Create sample twins
           ;  $factoryTwin = @{
                " \$metadata" = @{
                    " \$model" = " dtmi:com:example:Factory;1"
                }
                " FactoryName" = " Main Production Facility"
                " Location" = " Seattle, WA"
            }
            
            $productionLineTwin = @{
                " \$metadata" = @{
                    " \$model" = " dtmi:com:example:ProductionLine;1"
                }
                " LineNumber" = 1
                " Status" = " Running"
            }
            
            $factoryTwinJson = $factoryTwin | ConvertTo-Json -Depth 10
           ;  $productionLineTwinJson = $productionLineTwin | ConvertTo-Json -Depth 10
            
            $factoryTwinJson | Out-File -FilePath " .\factory-twin.json" -Encoding UTF8
            $productionLineTwinJson | Out-File -FilePath " .\production-line-twin.json" -Encoding UTF8
            
            # Create twins
            az dt twin create --dt-name $WEInstanceName --dtmi " dtmi:com:example:Factory;1" --twin-id " Factory-001" --properties " .\factory-twin.json"
            az dt twin create --dt-name $WEInstanceName --dtmi " dtmi:com:example:ProductionLine;1" --twin-id " ProductionLine-001" --properties " .\production-line-twin.json"
            
            # Create relationship
            az dt twin relationship create --dt-name $WEInstanceName --relationship-id " factory-contains-line" --relationship " contains" --source " Factory-001" --target " ProductionLine-001"
            
            Write-EnhancedLog " Successfully created sample digital twins and relationships" " Success"
            
        } else {
            Write-EnhancedLog " Deploying models from: $WEModelsPath" " Info"
            $modelFiles = Get-ChildItem -Path $WEModelsPath -Filter " *.json"
            
            foreach ($modelFile in $modelFiles) {
                az dt model create --dt-name $WEInstanceName --models $modelFile.FullName
                Write-EnhancedLog " Deployed model: $($modelFile.Name)" " Success"
            }
        }
        
    } catch {
        Write-EnhancedLog " Failed to deploy Digital Twins models: $($_.Exception.Message)" " Error"
    }
}


[CmdletBinding()]
function WE-Set-DiagnosticSetting -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$WEDigitalTwinsInstance)
    
    if ($WEPSCmdlet.ShouldProcess(" Diagnostic settings for '$WEInstanceName'" , " Configure" )) {
        try {
            Write-EnhancedLog " Configuring diagnostic settings for Digital Twins instance" " Info"
        
        # Create Log Analytics workspace
        $workspaceName = " law-$WEResourceGroupName-dt"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -Location $WELocation
            Write-EnhancedLog " Created Log Analytics workspace: $workspaceName" " Success"
        }
        
        # Configure diagnostic settings
        $diagnosticName = " $WEInstanceName-diagnostics"
        $logs = @(
            @{
                Category = " DigitalTwinsOperation"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            },
            @{
                Category = " EventRoutesOperation"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            },
            @{
                Category = " ModelsOperation"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            },
            @{
                Category = " QueryOperation"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            }
        )
        
        $metrics = @(
            @{
                Category = " AllMetrics"
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 90
                }
            }
        )
        
        Set-AzDiagnosticSetting -ResourceId $WEDigitalTwinsInstance.Id -WorkspaceId $workspace.ResourceId -Log $logs -Metric $metrics -Name $diagnosticName
        
        Write-EnhancedLog " Successfully configured diagnostic settings" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to configure diagnostic settings: $($_.Exception.Message)" " Error"
    }
    }
}


[CmdletBinding()]
function WE-Set-RoleAssignment -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([object]$WEDigitalTwinsInstance)
    
    if ($WEPSCmdlet.ShouldProcess(" RBAC roles for '$WEInstanceName'" , " Configure" )) {
        try {
            Write-EnhancedLog " Configuring RBAC roles for Digital Twins instance" " Info"
        
        # Get current user
        $currentUser = Get-AzContext -ErrorAction Stop
        
        # Assign Azure Digital Twins Data Owner role
        New-AzRoleAssignment -ObjectId $currentUser.Account.Id -RoleDefinitionName " Azure Digital Twins Data Owner" -Scope $WEDigitalTwinsInstance.Id
        
        Write-EnhancedLog " Successfully assigned Digital Twins Data Owner role to current user" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to assign RBAC roles: $($_.Exception.Message)" " Error"
    }
    }
}


[CmdletBinding()]
function WE-Get-DigitalTwinsStatus -ErrorAction Stop {
    param([object]$WEDigitalTwinsInstance)
    
    try {
        Write-EnhancedLog " Monitoring Digital Twins instance status..." " Info"
        
        # Get instance details
        $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $WEResourceGroupName -ResourceName $WEInstanceName
        
        Write-EnhancedLog " Instance Status:" " Info"
        Write-EnhancedLog "  Name: $($instance.Name)" " Info"
        Write-EnhancedLog "  Location: $($instance.Location)" " Info"
        Write-EnhancedLog "  Provisioning State: $($instance.ProvisioningState)" " Info"
        Write-EnhancedLog "  Host Name: $($instance.HostName)" " Info"
        Write-EnhancedLog "  Created Time: $($instance.CreatedTime)" " Info"
        
        # Get models count
        $modelsCount = (az dt model list --dt-name $WEInstanceName --query " length(@)" ) 
        Write-EnhancedLog "  Models Count: $modelsCount" " Info"
        
        # Get twins count
        $twinsCount = (az dt twin query --dt-name $WEInstanceName --query-command " SELECT COUNT() FROM DIGITALTWINS" --query " result[0].COUNT" )
        Write-EnhancedLog "  Twins Count: $twinsCount" " Info"
        
        Write-EnhancedLog " Digital Twins monitoring completed" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to monitor Digital Twins instance: $($_.Exception.Message)" " Error"
    }
}


try {
    Write-EnhancedLog " Starting Azure Digital Twins Management Tool" " Info"
    Write-EnhancedLog " Action: $WEAction" " Info"
    Write-EnhancedLog " Instance Name: $WEInstanceName" " Info"
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
            $instance = New-DigitalTwinsInstance -ErrorAction Stop
            
            if ($WEEnablePrivateEndpoint) {
                New-PrivateEndpoint -DigitalTwinsInstance $instance
            }
            
            if ($WEEnableEventRouting) {
                Set-EventRouting -DigitalTwinsInstance $instance
            }
            
            if ($WEEnableDiagnostics) {
                Set-DiagnosticSetting -DigitalTwinsInstance $instance
            }
            
            if ($WEAssignRoles) {
                Set-RoleAssignment -DigitalTwinsInstance $instance
            }
        }
        
        " Deploy" {
            $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $WEResourceGroupName -ResourceName $WEInstanceName
            Deploy-DigitalTwinsModel -DigitalTwinsInstance $instance -ModelsPath $WEModelDefinitions
        }
        
        " Monitor" {
           ;  $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $WEResourceGroupName -ResourceName $WEInstanceName
            Get-DigitalTwinsStatus -DigitalTwinsInstance $instance
        }
        
        " Configure" {
           ;  $instance = Get-AzDigitalTwinsInstance -ResourceGroupName $WEResourceGroupName -ResourceName $WEInstanceName
            
            if ($WEEnableEventRouting) {
                Set-EventRouting -DigitalTwinsInstance $instance
            }
            
            if ($WEEnableDiagnostics) {
                Set-DiagnosticSetting -DigitalTwinsInstance $instance
            }
        }
        
        " Delete" {
            Write-EnhancedLog " Deleting Digital Twins instance: $WEInstanceName" " Warning"
            Remove-AzDigitalTwinsInstance -ResourceGroupName $WEResourceGroupName -ResourceName $WEInstanceName -Force
            Write-EnhancedLog " Successfully deleted Digital Twins instance" " Success"
        }
    }
    
    Write-EnhancedLog " Azure Digital Twins Management Tool completed successfully" " Success"
    
} catch {
    Write-EnhancedLog " Tool execution failed: $($_.Exception.Message)" " Error"
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================