#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Springapps Management Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Springapps Management Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

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
    .\Azure-SpringApps-Management-Tool.ps1 -ResourceGroupName " spring-rg" -SpringAppsName " enterprise-spring" -Location " East US" -Action " Create" -Tier " Enterprise" -EnableApplicationInsights -EnableConfigServer
.EXAMPLE
    .\Azure-SpringApps-Management-Tool.ps1 -ResourceGroupName " spring-rg" -SpringAppsName " enterprise-spring" -Action " Deploy" -AppName " api-service" -ArtifactPath " C:\app\api-service.jar" -InstanceCount 3
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Azure CLI with Spring extension


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
    [string]$WESpringAppsName,
    
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet(" Create" , " Deploy" , " Scale" , " Monitor" , " Configure" , " Delete" , " Start" , " Stop" , " Restart" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet(" Basic" , " Standard" , " Enterprise" )]
    [string]$WETier = " Standard" ,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAppName,
    
    [Parameter(Mandatory = $false)]
    [string]$WEDeploymentName = " default" ,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEArtifactPath,
    
    [Parameter(Mandatory = $false)]
    [int]$WEInstanceCount = 1,
    
    [Parameter(Mandatory = $false)]
    [int]$WECpuCount = 1,
    
    [Parameter(Mandatory = $false)]
    [int]$WEMemoryInGB = 2,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableApplicationInsights,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableConfigServer,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEConfigServerRepo,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableServiceRegistry,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableGateway,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableMonitoring,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVNetName,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubnetName,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$WETags = @{
        Environment = " Production"
        Application = " SpringApps"
        ManagedBy = " AutomationScript"
    }
)

#region Functions


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
function WE-Initialize-SpringCLI {
    try {
        Write-EnhancedLog " Checking Azure CLI Spring extension..." " Info"
        
        $springExtension = az extension list --query " [?name=='spring'].name" -o tsv
        if (-not $springExtension) {
            Write-EnhancedLog " Installing Azure CLI Spring extension..." " Info"
            az extension add --name spring
            Write-EnhancedLog " Successfully installed Spring extension" " Success"
        } else {
            Write-EnhancedLog " Spring extension is already installed" " Success"
        }
        
        # Update to latest version
        az extension update --name spring
        
    } catch {
        Write-EnhancedLog " Failed to initialize Spring CLI: $($_.Exception.Message)" " Error"
        throw
    }
}


[CmdletBinding()]
function WE-New-SpringAppsInstance -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($WEPSCmdlet.ShouldProcess(" Spring Apps instance '$WESpringAppsName'" , " Create" )) {
        try {
        Write-EnhancedLog " Creating Azure Spring Apps instance: $WESpringAppsName" " Info"
        
        # Check if instance already exists
        $existing = az spring show --name $WESpringAppsName --resource-group $WEResourceGroupName --query " name" -o tsv 2>$null
        if ($existing) {
            Write-EnhancedLog " Spring Apps instance already exists: $WESpringAppsName" " Warning"
            return
        }
        
        # Build creation command
        $createCmd = @(
            " az" , " spring" , " create" ,
            " --name" , $WESpringAppsName,
            " --resource-group" , $WEResourceGroupName,
            " --location" , $WELocation,
            " --sku" , $WETier
        )
        
        # Add tags
        if ($WETags.Count -gt 0) {
            $tagString = ($WETags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join " "
            $createCmd = $createCmd + " --tags" , $tagString
        }
        
        # Add VNet integration if specified
        if ($WEVNetName -and $WESubnetName) {
            $vnet = Get-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Name $WEVNetName -ErrorAction SilentlyContinue
            if ($vnet) {
                $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $WESubnetName }
                if ($subnet) {
                    $createCmd = $createCmd + " --vnet" , $vnet.Id, " --app-subnet" , $subnet.Id
                    Write-EnhancedLog " Configuring VNet integration" " Info"
                }
            }
        }
        
        # Execute creation
        & $createCmd | Out-Null
        if ($WELASTEXITCODE -eq 0) {
            Write-EnhancedLog " Successfully created Spring Apps instance: $WESpringAppsName" " Success"
        } else {
            throw " Failed to create Spring Apps instance"
        }
        
        # Wait for instance to be ready
        do {
            Start-Sleep -Seconds 30
            $status = az spring show --name $WESpringAppsName --resource-group $WEResourceGroupName --query " properties.provisioningState" -o tsv
            Write-EnhancedLog " Instance provisioning state: $status" " Info"
        } while ($status -eq " Creating" )
        
        if ($status -eq " Succeeded" ) {
            Write-EnhancedLog " Spring Apps instance is ready for use" " Success"
        } else {
            throw " Spring Apps instance provisioning failed: $status"
        }
        
    } catch {
            Write-EnhancedLog " Failed to create Spring Apps instance: $($_.Exception.Message)" " Error"
            throw
        }
    }
}


[CmdletBinding()]
function WE-Set-SpringCloudService -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($WEPSCmdlet.ShouldProcess(" Spring Cloud services for '$WESpringAppsName'" , " Configure" )) {
        try {
        Write-EnhancedLog " Configuring Spring Cloud services..." " Info"
        
        # Configure Config Server
        if ($WEEnableConfigServer) {
            Write-EnhancedLog " Enabling Spring Cloud Config Server..." " Info"
            
            if ($WEConfigServerRepo) {
                az spring config-server set --name $WESpringAppsName --resource-group $WEResourceGroupName --config-file @"
{
  " gitProperty" : {
    " repositories" : [
      {
        " name" : " default" ,
        " pattern" : [" *" ],
        " uri" : " $WEConfigServerRepo"
      }
    ]
  }
}
" @
            } else {
                # Default public config repo for demo
                az spring config-server set --name $WESpringAppsName --resource-group $WEResourceGroupName --config-file @"
{
  " gitProperty" : {
    " repositories" : [
      {
        " name" : " default" ,
        " pattern" : [" *" ],
        " uri" : " https://github.com/Azure-Samples/spring-cloud-config-server-repository"
      }
    ]
  }
}
" @
            }
            Write-EnhancedLog " Successfully configured Config Server" " Success"
        }
        
        # Enable Service Registry (Eureka)
        if ($WEEnableServiceRegistry) {
            Write-EnhancedLog " Enabling Service Registry..." " Info"
            # Service Registry is enabled by default in Standard/Enterprise tiers
            Write-EnhancedLog " Service Registry is available for application registration" " Success"
        }
        
        # Configure Gateway
        if ($WEEnableGateway) {
            Write-EnhancedLog " Enabling Spring Cloud Gateway..." " Info"
            az spring gateway update --name $WESpringAppsName --resource-group $WEResourceGroupName --assign-endpoint true
            Write-EnhancedLog " Successfully configured Spring Cloud Gateway" " Success"
        }
        
    } catch {
            Write-EnhancedLog " Failed to configure Spring Cloud services: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-Deploy-SpringApplication {
    try {
        Write-EnhancedLog " Deploying Spring application: $WEAppName" " Info"
        
        # Create app if it doesn't exist
        $existingApp = az spring app show --name $WEAppName --service $WESpringAppsName --resource-group $WEResourceGroupName --query " name" -o tsv 2>$null
        if (-not $existingApp) {
            Write-EnhancedLog " Creating Spring application: $WEAppName" " Info"
            az spring app create --name $WEAppName --service $WESpringAppsName --resource-group $WEResourceGroupName --instance-count $WEInstanceCount --cpu $WECpuCount --memory " $($WEMemoryInGB)Gi"
            Write-EnhancedLog " Successfully created application: $WEAppName" " Success"
        }
        
        # Deploy application
        if ($WEArtifactPath -and (Test-Path $WEArtifactPath)) {
            Write-EnhancedLog " Deploying artifact: $WEArtifactPath" " Info"
            
            $deployCmd = @(
                " az" , " spring" , " app" , " deploy" ,
                " --name" , $WEAppName,
                " --service" , $WESpringAppsName,
                " --resource-group" , $WEResourceGroupName,
                " --artifact-path" , $WEArtifactPath
            )
            
            if ($WEDeploymentName) {
                $deployCmd = $deployCmd + " --deployment" , $WEDeploymentName
            }
            
            & $deployCmd | Out-Null
            if ($WELASTEXITCODE -eq 0) {
                Write-EnhancedLog " Successfully deployed application: $WEAppName" " Success"
            } else {
                throw " Failed to deploy application"
            }
        } else {
            Write-EnhancedLog " No artifact path specified or file not found, skipping deployment" " Warning"
        }
        
        # Assign public endpoint if needed
        az spring app update --name $WEAppName --service $WESpringAppsName --resource-group $WEResourceGroupName --assign-endpoint true
        
        # Get application URL
        $appUrl = az spring app show --name $WEAppName --service $WESpringAppsName --resource-group $WEResourceGroupName --query " properties.url" -o tsv
        if ($appUrl) {
            Write-EnhancedLog " Application URL: $appUrl" " Success"
        }
        
    } catch {
        Write-EnhancedLog " Failed to deploy Spring application: $($_.Exception.Message)" " Error"
        throw
    }
}


[CmdletBinding()]
function WE-Set-SpringAppScale -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($WEPSCmdlet.ShouldProcess(" Spring application '$WEAppName'" , " Scale" )) {
        try {
        Write-EnhancedLog " Scaling Spring application: $WEAppName" " Info"
        Write-EnhancedLog " Target instances: $WEInstanceCount, CPU: $WECpuCount, Memory: $($WEMemoryInGB)Gi" " Info"
        
        az spring app scale --name $WEAppName --service $WESpringAppsName --resource-group $WEResourceGroupName --instance-count $WEInstanceCount --cpu $WECpuCount --memory " $($WEMemoryInGB)Gi"
        
        if ($WELASTEXITCODE -eq 0) {
            Write-EnhancedLog " Successfully scaled application: $WEAppName" " Success"
        } else {
            throw " Failed to scale application"
        }
        
    } catch {
            Write-EnhancedLog " Failed to scale Spring application: $($_.Exception.Message)" " Error"
            throw
        }
    }
}


[CmdletBinding()]
function WE-Set-SpringMonitoring -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    if ($WEPSCmdlet.ShouldProcess(" Spring Apps monitoring configuration for '$WESpringAppsName'" , " Configure" )) {
        try {
            Write-EnhancedLog " Configuring monitoring for Spring Apps..." " Info"
        
            # Create Application Insights if enabled
            if ($WEEnableApplicationInsights) {
                $appInsightsName = " $WESpringAppsName-insights"
                
                # Check if Application Insights exists
                $existingInsights = Get-AzApplicationInsights -ResourceGroupName $WEResourceGroupName -Name $appInsightsName -ErrorAction SilentlyContinue
                if (-not $existingInsights) {
                    Write-EnhancedLog " Creating Application Insights: $appInsightsName" " Info"
                    $appInsights = New-AzApplicationInsights -ResourceGroupName $WEResourceGroupName -Name $appInsightsName -Location $WELocation -Kind " java"
                    Write-EnhancedLog " Successfully created Application Insights" " Success"
                } else {
                    $appInsights = $existingInsights
                }
                
                # Configure Application Insights for Spring Apps
                az spring build-service builder buildpack-binding create --name " default" --builder-name " default" --service $WESpringAppsName --resource-group $WEResourceGroupName --type " ApplicationInsights" --properties " connection-string=$($appInsights.ConnectionString)"
                Write-EnhancedLog " Successfully integrated Application Insights" " Success"
            }
            
            # Create Log Analytics workspace
            $workspaceName = " law-$WEResourceGroupName-spring"
            $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
            
            if (-not $workspace) {
                $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -Location $WELocation
                Write-EnhancedLog " Created Log Analytics workspace: $workspaceName" " Success"
            }
            
            # Configure diagnostic settings
            $springAppsId = az spring show --name $WESpringAppsName --resource-group $WEResourceGroupName --query " id" -o tsv
            
            $diagnosticSettings = @{
                logs = @(
                    @{
                        category = " ApplicationConsole"
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    },
                    @{
                        category = " SystemLogs" 
                        enabled = $true
                        retentionPolicy = @{
                            enabled = $true
                            days = 90
                        }
                    },
                    @{
                        category = " IngressLogs"
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
            
            Set-AzDiagnosticSetting -ResourceId $springAppsId -WorkspaceId $workspace.ResourceId -Log $diagnosticSettings.logs -Metric $diagnosticSettings.metrics -Name " $WESpringAppsName-diagnostics"
            
            Write-EnhancedLog " Successfully configured comprehensive monitoring" " Success"
            
        } catch {
            Write-EnhancedLog " Failed to configure monitoring: $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-Get-SpringAppsStatus -ErrorAction Stop {
    try {
        Write-EnhancedLog " Monitoring Spring Apps instance status..." " Info"
        
        # Get instance details
        $instance = az spring show --name $WESpringAppsName --resource-group $WEResourceGroupName --output json | ConvertFrom-Json
        
        Write-EnhancedLog " Spring Apps Instance Status:" " Info"
        Write-EnhancedLog "  Name: $($instance.name)" " Info"
        Write-EnhancedLog "  Location: $($instance.location)" " Info"
        Write-EnhancedLog "  Provisioning State: $($instance.properties.provisioningState)" " Info"
        Write-EnhancedLog "  Service ID: $($instance.properties.serviceId)" " Info"
        Write-EnhancedLog "  Network Profile: $($instance.properties.networkProfile.outboundType)" " Info"
        
        # Get applications
        $apps = az spring app list --service $WESpringAppsName --resource-group $WEResourceGroupName --output json | ConvertFrom-Json
        
        if ($apps) {
            Write-EnhancedLog " Applications:" " Info"
            foreach ($app in $apps) {
                Write-EnhancedLog "  - Name: $($app.name)" " Info"
                Write-EnhancedLog "    State: $($app.properties.provisioningState)" " Info"
                Write-EnhancedLog "    Public: $($app.properties.public)" " Info"
                Write-EnhancedLog "    URL: $($app.properties.url)" " Info"
                
                # Get deployment status
                $deployments = az spring app deployment list --app $app.name --service $WESpringAppsName --resource-group $WEResourceGroupName --output json | ConvertFrom-Json
                foreach ($deployment in $deployments) {
                    Write-EnhancedLog "    Deployment: $($deployment.name) - Status: $($deployment.properties.status)" " Info"
                    Write-EnhancedLog "    Instances: $($deployment.properties.deploymentSettings.resourceRequests.cpu) CPU, $($deployment.properties.deploymentSettings.resourceRequests.memory) Memory" " Info"
                }
            }
        } else {
            Write-EnhancedLog " No applications deployed" " Info"
        }
        
        Write-EnhancedLog " Spring Apps monitoring completed" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to monitor Spring Apps: $($_.Exception.Message)" " Error"
    }
}


[CmdletBinding()]
function WE-Invoke-AppLifecycleAction {
    param(
        [ValidateSet(" Start" , " Stop" , " Restart" )]
        [string]$WELifecycleAction
    )
    
    try {
        Write-EnhancedLog " Executing $WELifecycleAction action on application: $WEAppName" " Info"
        
        switch ($WELifecycleAction) {
            " Start" {
                az spring app start --name $WEAppName --service $WESpringAppsName --resource-group $WEResourceGroupName
            }
            " Stop" {
                az spring app stop --name $WEAppName --service $WESpringAppsName --resource-group $WEResourceGroupName
            }
            " Restart" {
                az spring app restart --name $WEAppName --service $WESpringAppsName --resource-group $WEResourceGroupName
            }
        }
        
        if ($WELASTEXITCODE -eq 0) {
            Write-EnhancedLog " Successfully executed $WELifecycleAction action" " Success"
        } else {
            throw " Failed to execute $WELifecycleAction action"
        }
        
    } catch {
        Write-EnhancedLog " Failed to execute lifecycle action: $($_.Exception.Message)" " Error"
        throw
    }
}


try {
    Write-EnhancedLog " Starting Azure Spring Apps Management Tool" " Info"
    Write-EnhancedLog " Action: $WEAction" " Info"
    Write-EnhancedLog " Spring Apps Name: $WESpringAppsName" " Info"
    Write-EnhancedLog " Resource Group: $WEResourceGroupName" " Info"
    
    # Initialize Spring CLI extension
    Initialize-SpringCLI
    
    # Ensure resource group exists
   ;  $rg = Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-EnhancedLog " Creating resource group: $WEResourceGroupName" " Info"
       ;  $rg = New-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Tag $WETags
        Write-EnhancedLog " Successfully created resource group" " Success"
    }
    
    switch ($WEAction) {
        " Create" {
            New-SpringAppsInstance -ErrorAction Stop
            Set-SpringCloudService
            
            if ($WEEnableMonitoring -or $WEEnableApplicationInsights) {
                Set-SpringMonitoring -ErrorAction Stop
            }
        }
        
        " Deploy" {
            if (-not $WEAppName) {
                throw " AppName parameter is required for Deploy action"
            }
            Deploy-SpringApplication
        }
        
        " Scale" {
            if (-not $WEAppName) {
                throw " AppName parameter is required for Scale action"
            }
            Set-SpringAppScale -ErrorAction Stop
        }
        
        " Monitor" {
            Get-SpringAppsStatus -ErrorAction Stop
        }
        
        " Configure" {
            Set-SpringCloudService -ErrorAction Stop
            if ($WEEnableMonitoring -or $WEEnableApplicationInsights) {
                Set-SpringMonitoring -ErrorAction Stop
            }
        }
        
        " Start" {
            if (-not $WEAppName) {
                throw " AppName parameter is required for Start action"
            }
            Invoke-AppLifecycleAction -LifecycleAction " Start"
        }
        
        " Stop" {
            if (-not $WEAppName) {
                throw " AppName parameter is required for Stop action"
            }
            Invoke-AppLifecycleAction -LifecycleAction " Stop"
        }
        
        " Restart" {
            if (-not $WEAppName) {
                throw " AppName parameter is required for Restart action"
            }
            Invoke-AppLifecycleAction -LifecycleAction " Restart"
        }
        
        " Delete" {
            Write-EnhancedLog " Deleting Spring Apps instance: $WESpringAppsName" " Warning"
            az spring delete --name $WESpringAppsName --resource-group $WEResourceGroupName --yes
            if ($WELASTEXITCODE -eq 0) {
                Write-EnhancedLog " Successfully deleted Spring Apps instance" " Success"
            } else {
                throw " Failed to delete Spring Apps instance"
            }
        }
    }
    
    Write-EnhancedLog " Azure Spring Apps Management Tool completed successfully" " Success"
    
} catch {
    Write-EnhancedLog " Tool execution failed: $($_.Exception.Message)" " Error"
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
