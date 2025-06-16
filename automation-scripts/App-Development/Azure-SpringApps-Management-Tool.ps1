#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.Resources

<#
.SYNOPSIS
    Azure Spring Apps Enterprise Management Tool
.DESCRIPTION
    Comprehensive tool for managing Azure Spring Apps instances with enterprise features,
    including monitoring, security, scaling, and application deployment automation.
.PARAMETER ResourceGroupName
    Target Resource Group for Spring Apps instance
.PARAMETER SpringAppsName
    Name of the Azure Spring Apps instance
.PARAMETER Location
    Azure region for the Spring Apps instance
.PARAMETER Action
    Action to perform (Create, Deploy, Scale, Monitor, Configure, Delete)
.PARAMETER Tier
    Service tier (Basic, Standard, Enterprise)
.PARAMETER AppName
    Name of the Spring application
.PARAMETER DeploymentName
    Name of the deployment
.PARAMETER ArtifactPath
    Path to application JAR file or source code
.PARAMETER InstanceCount
    Number of application instances
.PARAMETER CpuCount
    CPU allocation per instance
.PARAMETER MemoryInGB
    Memory allocation per instance in GB
.PARAMETER EnableApplicationInsights
    Enable Application Insights integration
.PARAMETER EnableConfigServer
    Enable Spring Cloud Config Server
.PARAMETER ConfigServerRepo
    Git repository URL for config server
.PARAMETER EnableServiceRegistry
    Enable Eureka service registry
.PARAMETER EnableGateway
    Enable Spring Cloud Gateway
.PARAMETER EnableMonitoring
    Enable comprehensive monitoring
.PARAMETER VNetName
    Virtual Network name for network isolation
.PARAMETER SubnetName
    Subnet name for Spring Apps deployment
.PARAMETER Tags
    Tags to apply to resources
.EXAMPLE
    .\Azure-SpringApps-Management-Tool.ps1 -ResourceGroupName "spring-rg" -SpringAppsName "enterprise-spring" -Location "East US" -Action "Create" -Tier "Enterprise" -EnableApplicationInsights -EnableConfigServer
.EXAMPLE
    .\Azure-SpringApps-Management-Tool.ps1 -ResourceGroupName "spring-rg" -SpringAppsName "enterprise-spring" -Action "Deploy" -AppName "api-service" -ArtifactPath "C:\app\api-service.jar" -InstanceCount 3
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Azure CLI with Spring extension
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$SpringAppsName,
    
    [Parameter(Mandatory = $true)]
    [string]$Location,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "Deploy", "Scale", "Monitor", "Configure", "Delete", "Start", "Stop", "Restart")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Standard", "Enterprise")]
    [string]$Tier = "Standard",
    
    [Parameter(Mandatory = $false)]
    [string]$AppName,
    
    [Parameter(Mandatory = $false)]
    [string]$DeploymentName = "default",
    
    [Parameter(Mandatory = $false)]
    [string]$ArtifactPath,
    
    [Parameter(Mandatory = $false)]
    [int]$InstanceCount = 1,
    
    [Parameter(Mandatory = $false)]
    [int]$CpuCount = 1,
    
    [Parameter(Mandatory = $false)]
    [int]$MemoryInGB = 2,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableApplicationInsights,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableConfigServer,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigServerRepo,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableServiceRegistry,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableGateway,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory = $false)]
    [string]$VNetName,
    
    [Parameter(Mandatory = $false)]
    [string]$SubnetName,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Production"
        Application = "SpringApps"
        ManagedBy = "AutomationScript"
    }
)

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

# Check and install Azure CLI Spring extension
function Initialize-SpringCLI {
    try {
        Write-EnhancedLog "Checking Azure CLI Spring extension..." "Info"
        
        $springExtension = az extension list --query "[?name=='spring'].name" -o tsv
        if (-not $springExtension) {
            Write-EnhancedLog "Installing Azure CLI Spring extension..." "Info"
            az extension add --name spring
            Write-EnhancedLog "Successfully installed Spring extension" "Success"
        } else {
            Write-EnhancedLog "Spring extension is already installed" "Success"
        }
        
        # Update to latest version
        az extension update --name spring
        
    } catch {
        Write-EnhancedLog "Failed to initialize Spring CLI: $($_.Exception.Message)" "Error"
        throw
    }
}

# Create Azure Spring Apps instance
function New-SpringAppsInstance {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("Spring Apps instance '$SpringAppsName'", "Create")) {
        try {
        Write-EnhancedLog "Creating Azure Spring Apps instance: $SpringAppsName" "Info"
        
        # Check if instance already exists
        $existing = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
        if ($existing) {
            Write-EnhancedLog "Spring Apps instance already exists: $SpringAppsName" "Warning"
            return
        }
        
        # Build creation command
        $createCmd = @(
            "az", "spring", "create",
            "--name", $SpringAppsName,
            "--resource-group", $ResourceGroupName,
            "--location", $Location,
            "--sku", $Tier
        )
        
        # Add tags
        if ($Tags.Count -gt 0) {
            $tagString = ($Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " "
            $createCmd += "--tags", $tagString
        }
        
        # Add VNet integration if specified
        if ($VNetName -and $SubnetName) {
            $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -ErrorAction SilentlyContinue
            if ($vnet) {
                $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $SubnetName }
                if ($subnet) {
                    $createCmd += "--vnet", $vnet.Id, "--app-subnet", $subnet.Id
                    Write-EnhancedLog "Configuring VNet integration" "Info"
                }
            }
        }
        
        # Execute creation
        & $createCmd | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-EnhancedLog "Successfully created Spring Apps instance: $SpringAppsName" "Success"
        } else {
            throw "Failed to create Spring Apps instance"
        }
        
        # Wait for instance to be ready
        do {
            Start-Sleep -Seconds 30
            $status = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --query "properties.provisioningState" -o tsv
            Write-EnhancedLog "Instance provisioning state: $status" "Info"
        } while ($status -eq "Creating")
        
        if ($status -eq "Succeeded") {
            Write-EnhancedLog "Spring Apps instance is ready for use" "Success"
        } else {
            throw "Spring Apps instance provisioning failed: $status"
        }
        
    } catch {
            Write-EnhancedLog "Failed to create Spring Apps instance: $($_.Exception.Message)" "Error"
            throw
        }
    }
}

# Configure Spring Cloud services
function Set-SpringCloudService {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("Spring Cloud services for '$SpringAppsName'", "Configure")) {
        try {
        Write-EnhancedLog "Configuring Spring Cloud services..." "Info"
        
        # Configure Config Server
        if ($EnableConfigServer) {
            Write-EnhancedLog "Enabling Spring Cloud Config Server..." "Info"
            
            if ($ConfigServerRepo) {
                az spring config-server set --name $SpringAppsName --resource-group $ResourceGroupName --config-file @"
{
  "gitProperty": {
    "repositories": [
      {
        "name": "default",
        "pattern": ["*"],
        "uri": "$ConfigServerRepo"
      }
    ]
  }
}
"@
            } else {
                # Default public config repo for demo
                az spring config-server set --name $SpringAppsName --resource-group $ResourceGroupName --config-file @"
{
  "gitProperty": {
    "repositories": [
      {
        "name": "default",
        "pattern": ["*"],
        "uri": "https://github.com/Azure-Samples/spring-cloud-config-server-repository"
      }
    ]
  }
}
"@
            }
            Write-EnhancedLog "Successfully configured Config Server" "Success"
        }
        
        # Enable Service Registry (Eureka)
        if ($EnableServiceRegistry) {
            Write-EnhancedLog "Enabling Service Registry..." "Info"
            # Service Registry is enabled by default in Standard/Enterprise tiers
            Write-EnhancedLog "Service Registry is available for application registration" "Success"
        }
        
        # Configure Gateway
        if ($EnableGateway) {
            Write-EnhancedLog "Enabling Spring Cloud Gateway..." "Info"
            az spring gateway update --name $SpringAppsName --resource-group $ResourceGroupName --assign-endpoint true
            Write-EnhancedLog "Successfully configured Spring Cloud Gateway" "Success"
        }
        
    } catch {
            Write-EnhancedLog "Failed to configure Spring Cloud services: $($_.Exception.Message)" "Error"
        }
    }
}

# Deploy Spring application
function Deploy-SpringApplication {
    try {
        Write-EnhancedLog "Deploying Spring application: $AppName" "Info"
        
        # Create app if it doesn't exist
        $existingApp = az spring app show --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
        if (-not $existingApp) {
            Write-EnhancedLog "Creating Spring application: $AppName" "Info"
            az spring app create --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --instance-count $InstanceCount --cpu $CpuCount --memory "$($MemoryInGB)Gi"
            Write-EnhancedLog "Successfully created application: $AppName" "Success"
        }
        
        # Deploy application
        if ($ArtifactPath -and (Test-Path $ArtifactPath)) {
            Write-EnhancedLog "Deploying artifact: $ArtifactPath" "Info"
            
            $deployCmd = @(
                "az", "spring", "app", "deploy",
                "--name", $AppName,
                "--service", $SpringAppsName,
                "--resource-group", $ResourceGroupName,
                "--artifact-path", $ArtifactPath
            )
            
            if ($DeploymentName) {
                $deployCmd += "--deployment", $DeploymentName
            }
            
            & $deployCmd | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-EnhancedLog "Successfully deployed application: $AppName" "Success"
            } else {
                throw "Failed to deploy application"
            }
        } else {
            Write-EnhancedLog "No artifact path specified or file not found, skipping deployment" "Warning"
        }
        
        # Assign public endpoint if needed
        az spring app update --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --assign-endpoint true
        
        # Get application URL
        $appUrl = az spring app show --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --query "properties.url" -o tsv
        if ($appUrl) {
            Write-EnhancedLog "Application URL: $appUrl" "Success"
        }
        
    } catch {
        Write-EnhancedLog "Failed to deploy Spring application: $($_.Exception.Message)" "Error"
        throw
    }
}

# Scale Spring application
function Set-SpringAppScale {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($PSCmdlet.ShouldProcess("Spring application '$AppName'", "Scale")) {
        try {
        Write-EnhancedLog "Scaling Spring application: $AppName" "Info"
        Write-EnhancedLog "Target instances: $InstanceCount, CPU: $CpuCount, Memory: $($MemoryInGB)Gi" "Info"
        
        az spring app scale --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --instance-count $InstanceCount --cpu $CpuCount --memory "$($MemoryInGB)Gi"
        
        if ($LASTEXITCODE -eq 0) {
            Write-EnhancedLog "Successfully scaled application: $AppName" "Success"
        } else {
            throw "Failed to scale application"
        }
        
    } catch {
            Write-EnhancedLog "Failed to scale Spring application: $($_.Exception.Message)" "Error"
            throw
        }
    }
}

# Configure monitoring
function Set-SpringMonitoring {
    try {
        Write-EnhancedLog "Configuring monitoring for Spring Apps..." "Info"
        
            # Create Application Insights if enabled
            if ($EnableApplicationInsights) {
                $appInsightsName = "$SpringAppsName-insights"
                
                # Check if Application Insights exists
                $existingInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $appInsightsName -ErrorAction SilentlyContinue
                if (-not $existingInsights) {
                    Write-EnhancedLog "Creating Application Insights: $appInsightsName" "Info"
                    $appInsights = New-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $appInsightsName -Location $Location -Kind "java"
                    Write-EnhancedLog "Successfully created Application Insights" "Success"
                } else {
                    $appInsights = $existingInsights
                }
                
                # Configure Application Insights for Spring Apps
                az spring build-service builder buildpack-binding create --name "default" --builder-name "default" --service $SpringAppsName --resource-group $ResourceGroupName --type "ApplicationInsights" --properties "connection-string=$($appInsights.ConnectionString)"
                Write-EnhancedLog "Successfully integrated Application Insights" "Success"
            }
            
            # Create Log Analytics workspace
            $workspaceName = "law-$ResourceGroupName-spring"
            $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
            
            if (-not $workspace) {
                $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location
                Write-EnhancedLog "Created Log Analytics workspace: $workspaceName" "Success"
            }
            
            # Configure diagnostic settings
            $springAppsId = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --query "id" -o tsv
            
            $diagnosticSettings = @{
                logs = @(
                    @{
                        category = "ApplicationConsole"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    },
                    @{
                        category = "SystemLogs" 
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    },
                    @{
                        category = "IngressLogs"
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
            
            Set-AzDiagnosticSetting -ResourceId $springAppsId -WorkspaceId $workspace.ResourceId -Log $diagnosticSettings.logs -Metric $diagnosticSettings.metrics -Name "$SpringAppsName-diagnostics"
            
            Write-EnhancedLog "Successfully configured comprehensive monitoring" "Success"
            
    } catch {
        Write-EnhancedLog "Failed to configure monitoring: $($_.Exception.Message)" "Error"
    }
}

# Monitor Spring Apps status
function Get-SpringAppsStatus {
    try {
        Write-EnhancedLog "Monitoring Spring Apps instance status..." "Info"
        
        # Get instance details
        $instance = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
        
        Write-EnhancedLog "Spring Apps Instance Status:" "Info"
        Write-EnhancedLog "  Name: $($instance.name)" "Info"
        Write-EnhancedLog "  Location: $($instance.location)" "Info"
        Write-EnhancedLog "  Provisioning State: $($instance.properties.provisioningState)" "Info"
        Write-EnhancedLog "  Service ID: $($instance.properties.serviceId)" "Info"
        Write-EnhancedLog "  Network Profile: $($instance.properties.networkProfile.outboundType)" "Info"
        
        # Get applications
        $apps = az spring app list --service $SpringAppsName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
        
        if ($apps) {
            Write-EnhancedLog "Applications:" "Info"
            foreach ($app in $apps) {
                Write-EnhancedLog "  - Name: $($app.name)" "Info"
                Write-EnhancedLog "    State: $($app.properties.provisioningState)" "Info"
                Write-EnhancedLog "    Public: $($app.properties.public)" "Info"
                Write-EnhancedLog "    URL: $($app.properties.url)" "Info"
                
                # Get deployment status
                $deployments = az spring app deployment list --app $app.name --service $SpringAppsName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
                foreach ($deployment in $deployments) {
                    Write-EnhancedLog "    Deployment: $($deployment.name) - Status: $($deployment.properties.status)" "Info"
                    Write-EnhancedLog "    Instances: $($deployment.properties.deploymentSettings.resourceRequests.cpu) CPU, $($deployment.properties.deploymentSettings.resourceRequests.memory) Memory" "Info"
                }
            }
        } else {
            Write-EnhancedLog "No applications deployed" "Info"
        }
        
        Write-EnhancedLog "Spring Apps monitoring completed" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to monitor Spring Apps: $($_.Exception.Message)" "Error"
    }
}

# Application lifecycle management
function Invoke-AppLifecycleAction {
    param(
        [ValidateSet("Start", "Stop", "Restart")]
        [string]$LifecycleAction
    )
    
    try {
        Write-EnhancedLog "Executing $LifecycleAction action on application: $AppName" "Info"
        
        switch ($LifecycleAction) {
            "Start" {
                az spring app start --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName
            }
            "Stop" {
                az spring app stop --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName
            }
            "Restart" {
                az spring app restart --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName
            }
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-EnhancedLog "Successfully executed $LifecycleAction action" "Success"
        } else {
            throw "Failed to execute $LifecycleAction action"
        }
        
    } catch {
        Write-EnhancedLog "Failed to execute lifecycle action: $($_.Exception.Message)" "Error"
        throw
    }
}

# Main execution
try {
    Write-EnhancedLog "Starting Azure Spring Apps Management Tool" "Info"
    Write-EnhancedLog "Action: $Action" "Info"
    Write-EnhancedLog "Spring Apps Name: $SpringAppsName" "Info"
    Write-EnhancedLog "Resource Group: $ResourceGroupName" "Info"
    
    # Initialize Spring CLI extension
    Initialize-SpringCLI
    
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-EnhancedLog "Creating resource group: $ResourceGroupName" "Info"
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
        Write-EnhancedLog "Successfully created resource group" "Success"
    }
    
    switch ($Action) {
        "Create" {
            New-SpringAppsInstance
            Set-SpringCloudService
            
            if ($EnableMonitoring -or $EnableApplicationInsights) {
                Set-SpringMonitoring
            }
        }
        
        "Deploy" {
            if (-not $AppName) {
                throw "AppName parameter is required for Deploy action"
            }
            Deploy-SpringApplication
        }
        
        "Scale" {
            if (-not $AppName) {
                throw "AppName parameter is required for Scale action"
            }
            Set-SpringAppScale
        }
        
        "Monitor" {
            Get-SpringAppsStatus
        }
        
        "Configure" {
            Set-SpringCloudService
            if ($EnableMonitoring -or $EnableApplicationInsights) {
                Set-SpringMonitoring
            }
        }
        
        "Start" {
            if (-not $AppName) {
                throw "AppName parameter is required for Start action"
            }
            Invoke-AppLifecycleAction -LifecycleAction "Start"
        }
        
        "Stop" {
            if (-not $AppName) {
                throw "AppName parameter is required for Stop action"
            }
            Invoke-AppLifecycleAction -LifecycleAction "Stop"
        }
        
        "Restart" {
            if (-not $AppName) {
                throw "AppName parameter is required for Restart action"
            }
            Invoke-AppLifecycleAction -LifecycleAction "Restart"
        }
        
        "Delete" {
            Write-EnhancedLog "Deleting Spring Apps instance: $SpringAppsName" "Warning"
            az spring delete --name $SpringAppsName --resource-group $ResourceGroupName --yes
            if ($LASTEXITCODE -eq 0) {
                Write-EnhancedLog "Successfully deleted Spring Apps instance" "Success"
            } else {
                throw "Failed to delete Spring Apps instance"
            }
        }
    }
    
    Write-EnhancedLog "Azure Spring Apps Management Tool completed successfully" "Success"
    
} catch {
    Write-EnhancedLog "Tool execution failed: $($_.Exception.Message)" "Error"
    exit 1
}
