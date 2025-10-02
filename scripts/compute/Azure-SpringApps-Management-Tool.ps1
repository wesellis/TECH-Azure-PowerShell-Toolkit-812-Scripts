#Requires -Version 7.4
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Spring Apps Enterprise Management Tool

.DESCRIPTION
    Tool for managing Azure Spring Apps instances with enterprise features,
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
    Enable  monitoring
.PARAMETER VNetName
    Virtual Network name for network isolation
.PARAMETER SubnetName
    Subnet name for Spring Apps deployment
.PARAMETER Tags
    Tags to apply to resources
    .\Azure-SpringApps-Management-Tool.ps1 -ResourceGroupName "spring-rg" -SpringAppsName "enterprise-spring" -Location "East US" -Action "Create" -Tier "Enterprise" -EnableApplicationInsights -EnableConfigServer
    .\Azure-SpringApps-Management-Tool.ps1 -ResourceGroupName "spring-rg" -SpringAppsName "enterprise-spring" -Action "Deploy" -AppName "api-service" -ArtifactPath "C:\app\api-service.jar" -InstanceCount 3
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Azure CLI with Spring extension
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
    [string]$ErrorActionPreference = 'Stop'

function Write-Log {
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
    Write-Output "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}
function Initialize-SpringCLI {
    try {
        Write-Output "Checking Azure CLI Spring extension..." "Info"
    [string]$SpringExtension = az extension list --query "[?name=='spring'].name" -o tsv
        if (-not $SpringExtension) {
            Write-Output "Installing Azure CLI Spring extension..." "Info"
            az extension add --name spring
            Write-Output "Successfully installed Spring extension" "Success"
        } else {
            Write-Output "Spring extension is already installed" "Success"
        }
        az extension update --name spring
    } catch {
        Write-Output "Failed to initialize Spring CLI: $($_.Exception.Message)" "Error"
        throw
    }
}
function New-SpringAppsInstance -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Spring Apps instance '$SpringAppsName'", "Create")) {
        try {
        Write-Output "Creating Azure Spring Apps instance: $SpringAppsName" "Info"
    [string]$existing = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
        if ($existing) {
            Write-Output "Spring Apps instance already exists: $SpringAppsName" "Warning"
            return
        }
    [string]$CreateCmd = @(
            "az", "spring", "create",
            "--name", $SpringAppsName,
            "--resource-group", $ResourceGroupName,
            "--location", $Location,
            "--sku", $Tier
        )
        if ($Tags.Count -gt 0) {
    [string]$TagString = ($Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " "
    [string]$CreateCmd += "--tags", $TagString
        }
        if ($VNetName -and $SubnetName) {
$vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -ErrorAction SilentlyContinue
            if ($vnet) {
    [string]$subnet = $vnet.Subnets | Where-Object { $_.Name -eq $SubnetName }
                if ($subnet) {
    [string]$CreateCmd += "--vnet", $vnet.Id, "--app-subnet", $subnet.Id
                    Write-Output "Configuring VNet integration" "Info"
                }
            }
        }
        & $CreateCmd | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "Successfully created Spring Apps instance: $SpringAppsName" "Success"
        } else {
            throw "Failed to create Spring Apps instance"
        }
        do {
            Start-Sleep -Seconds 30
    [string]$status = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --query "properties.provisioningState" -o tsv
            Write-Output "Instance provisioning state: $status" "Info"
        } while ($status -eq "Creating")
        if ($status -eq "Succeeded") {
            Write-Output "Spring Apps instance is ready for use" "Success"
        } else {
            throw "Spring Apps instance provisioning failed: $status"
        }
    } catch {
            Write-Output "Failed to create Spring Apps instance: $($_.Exception.Message)" "Error"
            throw
        }
    }
}
function Set-SpringCloudService -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Spring Cloud services for '$SpringAppsName'", "Configure")) {
        try {
        Write-Output "Configuring Spring Cloud services..." "Info"
        if ($EnableConfigServer) {
            Write-Output "Enabling Spring Cloud Config Server..." "Info"
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
            Write-Output "Successfully configured Config Server" "Success"
        }
        if ($EnableServiceRegistry) {
            Write-Output "Enabling Service Registry..." "Info"
            Write-Output "Service Registry is available for application registration" "Success"
        }
        if ($EnableGateway) {
            Write-Output "Enabling Spring Cloud Gateway..." "Info"
            az spring gateway update --name $SpringAppsName --resource-group $ResourceGroupName --assign-endpoint true
            Write-Output "Successfully configured Spring Cloud Gateway" "Success"
        }
    } catch {
            Write-Output "Failed to configure Spring Cloud services: $($_.Exception.Message)" "Error"
        }
    }
}
function Install-SpringApplication {
    try {
        Write-Output "Deploying Spring application: $AppName" "Info"
    [string]$ExistingApp = az spring app show --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
        if (-not $ExistingApp) {
            Write-Output "Creating Spring application: $AppName" "Info"
            az spring app create --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --instance-count $InstanceCount --cpu $CpuCount --memory "$($MemoryInGB)Gi"
            Write-Output "Successfully created application: $AppName" "Success"
        }
        if ($ArtifactPath -and (Test-Path $ArtifactPath)) {
            Write-Output "Deploying artifact: $ArtifactPath" "Info"
    [string]$DeployCmd = @(
                "az", "spring", "app", "deploy",
                "--name", $AppName,
                "--service", $SpringAppsName,
                "--resource-group", $ResourceGroupName,
                "--artifact-path", $ArtifactPath
            )
            if ($DeploymentName) {
    [string]$DeployCmd += "--deployment", $DeploymentName
            }
            & $DeployCmd | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Output "Successfully deployed application: $AppName" "Success"
            } else {
                throw "Failed to deploy application"
            }
        } else {
            Write-Output "No artifact path specified or file not found, skipping deployment" "Warning"
        }
        az spring app update --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --assign-endpoint true
    [string]$AppUrl = az spring app show --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --query "properties.url" -o tsv
        if ($AppUrl) {
            Write-Output "Application URL: $AppUrl" "Success"
        }
    } catch {
        Write-Output "Failed to deploy Spring application: $($_.Exception.Message)" "Error"
        throw
    }
}
function Set-SpringAppScale -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Spring application '$AppName'", "Scale")) {
        try {
        Write-Output "Scaling Spring application: $AppName" "Info"
        Write-Output "Target instances: $InstanceCount, CPU: $CpuCount, Memory: $($MemoryInGB)Gi" "Info"
        az spring app scale --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --instance-count $InstanceCount --cpu $CpuCount --memory "$($MemoryInGB)Gi"
        if ($LASTEXITCODE -eq 0) {
            Write-Output "Successfully scaled application: $AppName" "Success"
        } else {
            throw "Failed to scale application"
        }
    } catch {
            Write-Output "Failed to scale Spring application: $($_.Exception.Message)" "Error"
            throw
        }
    }
}
function Set-SpringMonitoring -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Spring Apps monitoring configuration for '$SpringAppsName'", "Configure")) {
        try {
            Write-Output "Configuring monitoring for Spring Apps..." "Info"
            if ($EnableApplicationInsights) {
    [string]$AppInsightsName = "$SpringAppsName-insights"
$ExistingInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $AppInsightsName -ErrorAction SilentlyContinue
                if (-not $ExistingInsights) {
                    Write-Output "Creating Application Insights: $AppInsightsName" "Info"
$AppInsights = New-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $AppInsightsName -Location $Location -Kind "java"
                    Write-Output "Successfully created Application Insights" "Success"
                } else {
    [string]$AppInsights = $ExistingInsights
                }
                az spring build-service builder buildpack-binding create --name "default" --builder-name "default" --service $SpringAppsName --resource-group $ResourceGroupName --type "ApplicationInsights" --properties "connection-string=$($AppInsights.ConnectionString)"
                Write-Output "Successfully integrated Application Insights" "Success"
            }
    [string]$WorkspaceName = "law-$ResourceGroupName-spring"
$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
            if (-not $workspace) {
$workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Location $Location
                Write-Output "Created Log Analytics workspace: $WorkspaceName" "Success"
            }
    [string]$SpringAppsId = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --query "id" -o tsv
$DiagnosticSettings = @{
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
            Set-AzDiagnosticSetting -ResourceId $SpringAppsId -WorkspaceId $workspace.ResourceId -Log $DiagnosticSettings.logs -Metric $DiagnosticSettings.metrics -Name "$SpringAppsName-diagnostics"
            Write-Output "Successfully configured  monitoring" "Success"
        } catch {
            Write-Output "Failed to configure monitoring: $($_.Exception.Message)" "Error"
        }
    }
}
function Get-SpringAppsStatus -ErrorAction Stop {
    try {
        Write-Output "Monitoring Spring Apps instance status..." "Info"
    [string]$instance = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
        Write-Output "Spring Apps Instance Status:" "Info"
        Write-Output "Name: $($instance.name)" "Info"
        Write-Output "Location: $($instance.location)" "Info"
        Write-Output "Provisioning State: $($instance.properties.provisioningState)" "Info"
        Write-Output "Service ID: $($instance.properties.serviceId)" "Info"
        Write-Output "Network Profile: $($instance.properties.networkProfile.outboundType)" "Info"
    [string]$apps = az spring app list --service $SpringAppsName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
        if ($apps) {
            Write-Output "Applications:" "Info"
            foreach ($app in $apps) {
                Write-Output "  - Name: $($app.name)" "Info"
                Write-Output "    State: $($app.properties.provisioningState)" "Info"
                Write-Output "    Public: $($app.properties.public)" "Info"
                Write-Output "    URL: $($app.properties.url)" "Info"
    [string]$deployments = az spring app deployment list --app $app.name --service $SpringAppsName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
                foreach ($deployment in $deployments) {
                    Write-Output "    Deployment: $($deployment.name) - Status: $($deployment.properties.status)" "Info"
                    Write-Output "    Instances: $($deployment.properties.deploymentSettings.resourceRequests.cpu) CPU, $($deployment.properties.deploymentSettings.resourceRequests.memory) Memory" "Info"
                }
            }
        } else {
            Write-Output "No applications deployed" "Info"
        }
        Write-Output "Spring Apps monitoring completed" "Success"
    } catch {
        Write-Output "Failed to monitor Spring Apps: $($_.Exception.Message)" "Error"
    }
}
function Invoke-AppLifecycleAction {
    param(
        [ValidateSet("Start", "Stop", "Restart")]
        [string]$LifecycleAction
    )
    try {
        Write-Output "Executing $LifecycleAction action on application: $AppName" "Info"
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
            Write-Output "Successfully executed $LifecycleAction action" "Success"
        } else {
            throw "Failed to execute $LifecycleAction action"
        }
    } catch {
        Write-Output "Failed to execute lifecycle action: $($_.Exception.Message)" "Error"
        throw
    }
}
try {
    Write-Output "Starting Azure Spring Apps Management Tool" "Info"
    Write-Output "Action: $Action" "Info"
    Write-Output "Spring Apps Name: $SpringAppsName" "Info"
    Write-Output "Resource Group: $ResourceGroupName" "Info"
    Initialize-SpringCLI
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
            New-SpringAppsInstance -ErrorAction Stop
            Set-SpringCloudService
            if ($EnableMonitoring -or $EnableApplicationInsights) {
                Set-SpringMonitoring -ErrorAction Stop
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
            Set-SpringAppScale -ErrorAction Stop
        }
        "Monitor" {
            Get-SpringAppsStatus -ErrorAction Stop
        }
        "Configure" {
            Set-SpringCloudService -ErrorAction Stop
            if ($EnableMonitoring -or $EnableApplicationInsights) {
                Set-SpringMonitoring -ErrorAction Stop
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
            Write-Output "Deleting Spring Apps instance: $SpringAppsName" "Warning"
            az spring delete --name $SpringAppsName --resource-group $ResourceGroupName --yes
            if ($LASTEXITCODE -eq 0) {
                Write-Output "Successfully deleted Spring Apps instance" "Success"
            } else {
                throw "Failed to delete Spring Apps instance"
            }
        }
    }
    Write-Output "Azure Spring Apps Management Tool completed successfully" "Success"
} catch {
    Write-Output "Tool execution failed: $($_.Exception.Message)" "Error"
    throw`n}
