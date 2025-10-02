#Requires -Version 7.4
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Springapps Management Tool

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Azure Spring Apps Enterprise Management Tool
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
    .\Azure-SpringApps-Management-Tool.ps1 -ResourceGroupName " spring-rg" -SpringAppsName " enterprise-spring" -Location "East US" -Action Create" -Tier "Enterprise" -EnableApplicationInsights -EnableConfigServer
    .\Azure-SpringApps-Management-Tool.ps1 -ResourceGroupName " spring-rg" -SpringAppsName " enterprise-spring" -Action "Deploy" -AppName " api-service" -ArtifactPath "C:\app\api-service.jar" -InstanceCount 3
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Azure CLI with Spring extension
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SpringAppsName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Create" , "Deploy" , "Scale" , "Monitor" , "Configure" , "Delete" , "Start" , "Stop" , "Restart" )]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Action,
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic" , "Standard" , "Enterprise" )]
    [string]$Tier = "Standard" ,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,
    [Parameter(Mandatory = $false)]
    [string]$DeploymentName = " default" ,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
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
    [ValidateNotNullOrEmpty()]
    [string]$ConfigServerRepo,
    [Parameter(Mandatory = $false)]
    [switch]$EnableServiceRegistry,
    [Parameter(Mandatory = $false)]
    [switch]$EnableGateway,
    [Parameter(Mandatory = $false)]
    [switch]$EnableMonitoring,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$VNetName,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SubnetName,
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Production"
        Application = "SpringApps"
        ManagedBy = "AutomationScript"
    }
)
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
    Write-Output " [$timestamp] $Message" -ForegroundColor $colors[$Level]
}
function Initialize-SpringCLI {
    try {
        Write-Verbose "Log entry"ng Azure CLI Spring extension..." "Info"
    [string]$SpringExtension = az extension list --query " [?name=='spring'].name" -o tsv
        if (-not $SpringExtension) {
            Write-Verbose "Log entry"nstalling Azure CLI Spring extension..." "Info"
            az extension add --name spring
            Write-Verbose "Log entry"nstalled Spring extension" "Success"
        } else {
            Write-Verbose "Log entry"ng extension is already installed" "Success"
        }
        az extension update --name spring
    } catch {
        Write-Verbose "Log entry"nitialize Spring CLI: $($_.Exception.Message)" "Error"
        throw
    }
}
function New-SpringAppsInstance -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Spring Apps instance '$SpringAppsName'" , "Create" )) {
        try {
        Write-Verbose "Log entry"ng Azure Spring Apps instance: $SpringAppsName" "Info"
    [string]$existing = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --query " name" -o tsv 2>$null
        if ($existing) {
            Write-Verbose "Log entry"ng Apps instance already exists: $SpringAppsName" "Warning"
            return
        }
    [string]$CreateCmd = @(
            " az" , "spring" , "create" ,
            " --name" , $SpringAppsName,
            " --resource-group" , $ResourceGroupName,
            " --location" , $Location,
            " --sku" , $Tier
        )
        if ($Tags.Count -gt 0) {
    [string]$TagString = ($Tags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join " "
    [string]$CreateCmd = $CreateCmd + " --tags" , $TagString
        }
        if ($VNetName -and $SubnetName) {
$vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -ErrorAction SilentlyContinue
            if ($vnet) {
    [string]$subnet = $vnet.Subnets | Where-Object { $_.Name -eq $SubnetName }
                if ($subnet) {
    [string]$CreateCmd = $CreateCmd + " --vnet" , $vnet.Id, "--app-subnet" , $subnet.Id
                    Write-Verbose "Log entry"nfiguring VNet integration" "Info"
                }
            }
        }
        & $CreateCmd | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Verbose "Log entry"ng Apps instance: $SpringAppsName" "Success"
        } else {
            throw "Failed to create Spring Apps instance"
        }
        do {
            Start-Sleep -Seconds 30
    [string]$status = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --query " properties.provisioningState" -o tsv
            Write-Verbose "Log entry"nstance provisioning state: $status" "Info"
        } while ($status -eq "Creating" )
        if ($status -eq "Succeeded" ) {
            Write-Verbose "Log entry"ng Apps instance is ready for use" "Success"
        } else {
            throw "Spring Apps instance provisioning failed: $status"
        }
    } catch {
            Write-Verbose "Log entry"ng Apps instance: $($_.Exception.Message)" "Error"
            throw
        }
    }
}
function Set-SpringCloudService -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Spring Cloud services for '$SpringAppsName'" , "Configure" )) {
        try {
        Write-Verbose "Log entry"nfiguring Spring Cloud services..." "Info"
        if ($EnableConfigServer) {
            Write-Verbose "Log entry"nabling Spring Cloud Config Server..." "Info"
            if ($ConfigServerRepo) {
                az spring config-server set --name $SpringAppsName --resource-group $ResourceGroupName --config-file @"
{
  " gitProperty" : {
    " repositories" : [
      {
        " name" : " default" ,
        " pattern" : ["*" ],
        " uri" : " $ConfigServerRepo"
      }
    ]
  }
}
" @
            } else {
                az spring config-server set --name $SpringAppsName --resource-group $ResourceGroupName --config-file @"
{
  " gitProperty" : {
    " repositories" : [
      {
        " name" : " default" ,
        " pattern" : ["*" ],
        " uri" : " https://github.com/Azure-Samples/spring-cloud-config-server-repository"
      }
    ]
  }
}
" @
            }
            Write-Verbose "Log entry"nfigured Config Server" "Success"
        }
        if ($EnableServiceRegistry) {
            Write-Verbose "Log entry"nabling Service Registry..." "Info"
            Write-Verbose "Log entry"n registration" "Success"
        }
        if ($EnableGateway) {
            Write-Verbose "Log entry"nabling Spring Cloud Gateway..." "Info"
            az spring gateway update --name $SpringAppsName --resource-group $ResourceGroupName --assign-endpoint true
            Write-Verbose "Log entry"nfigured Spring Cloud Gateway" "Success"
        }
    } catch {
            Write-Verbose "Log entry"nfigure Spring Cloud services: $($_.Exception.Message)" "Error"
        }
    }
}
function Deploy-SpringApplication {
    try {
        Write-Verbose "Log entry"ng Spring application: $AppName" "Info"
    [string]$ExistingApp = az spring app show --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --query " name" -o tsv 2>$null
        if (-not $ExistingApp) {
            Write-Verbose "Log entry"ng Spring application: $AppName" "Info"
            az spring app create --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --instance-count $InstanceCount --cpu $CpuCount --memory " $($MemoryInGB)Gi"
            Write-Verbose "Log entry"n: $AppName" "Success"
        }
        if ($ArtifactPath -and (Test-Path $ArtifactPath)) {
            Write-Verbose "Log entry"ng artifact: $ArtifactPath" "Info"
    [string]$DeployCmd = @(
                " az" , "spring" , "app" , "deploy" ,
                " --name" , $AppName,
                " --service" , $SpringAppsName,
                " --resource-group" , $ResourceGroupName,
                " --artifact-path" , $ArtifactPath
            )
            if ($DeploymentName) {
    [string]$DeployCmd = $DeployCmd + " --deployment" , $DeploymentName
            }
            & $DeployCmd | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Verbose "Log entry"n: $AppName" "Success"
            } else {
                throw "Failed to deploy application"
            }
        } else {
            Write-Verbose "Log entry"No artifact path specified or file not found, skipping deployment" "Warning"
        }
        az spring app update --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --assign-endpoint true
    [string]$AppUrl = az spring app show --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --query " properties.url" -o tsv
        if ($AppUrl) {
            Write-Verbose "Log entry"n URL: $AppUrl" "Success"
        }
    } catch {
        Write-Verbose "Log entry"ng application: $($_.Exception.Message)" "Error"
        throw
    }
}
function Set-SpringAppScale -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Spring application '$AppName'" , "Scale" )) {
        try {
        Write-Verbose "Log entry"ng Spring application: $AppName" "Info"
        Write-Verbose "Log entry"nstances: $InstanceCount, CPU: $CpuCount, Memory: $($MemoryInGB)Gi" "Info"
        az spring app scale --name $AppName --service $SpringAppsName --resource-group $ResourceGroupName --instance-count $InstanceCount --cpu $CpuCount --memory " $($MemoryInGB)Gi"
        if ($LASTEXITCODE -eq 0) {
            Write-Verbose "Log entry"n: $AppName" "Success"
        } else {
            throw "Failed to scale application"
        }
    } catch {
            Write-Verbose "Log entry"ng application: $($_.Exception.Message)" "Error"
            throw
        }
    }
}
function Set-SpringMonitoring -ErrorAction Stop {
    param()
    if ($PSCmdlet.ShouldProcess("Spring Apps monitoring configuration for '$SpringAppsName'" , "Configure" )) {
        try {
            Write-Verbose "Log entry"nfiguring monitoring for Spring Apps..." "Info"
            if ($EnableApplicationInsights) {
    [string]$AppInsightsName = " $SpringAppsName-insights"
$ExistingInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $AppInsightsName -ErrorAction SilentlyContinue
                if (-not $ExistingInsights) {
                    Write-Verbose "Log entry"ng Application Insights: $AppInsightsName" "Info"
$AppInsights = New-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $AppInsightsName -Location $Location -Kind " java"
                    Write-Verbose "Log entry"n Insights" "Success"
                } else {
    [string]$AppInsights = $ExistingInsights
                }
                az spring build-service builder buildpack-binding create --name " default" --builder-name " default" --service $SpringAppsName --resource-group $ResourceGroupName --type "ApplicationInsights" --properties " connection-string=$($AppInsights.ConnectionString)"
                Write-Verbose "Log entry"ntegrated Application Insights" "Success"
            }
    [string]$WorkspaceName = " law-$ResourceGroupName-spring"
$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
            if (-not $workspace) {
$workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -Location $Location
                Write-Verbose "Log entry"nalytics workspace: $WorkspaceName" "Success"
            }
    [string]$SpringAppsId = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --query " id" -o tsv
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
            Set-AzDiagnosticSetting -ResourceId $SpringAppsId -WorkspaceId $workspace.ResourceId -Log $DiagnosticSettings.logs -Metric $DiagnosticSettings.metrics -Name " $SpringAppsName-diagnostics"
            Write-Verbose "Log entry"nfigured  monitoring" "Success"
        } catch {
            Write-Verbose "Log entry"nfigure monitoring: $($_.Exception.Message)" "Error"
        }
    }
}
function Get-SpringAppsStatus -ErrorAction Stop {
    try {
        Write-Verbose "Log entry"nitoring Spring Apps instance status..." "Info"
    [string]$instance = az spring show --name $SpringAppsName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
        Write-Verbose "Log entry"ng Apps Instance Status:" "Info"
        Write-Verbose "Log entry"Name: $($instance.name)" "Info"
        Write-Verbose "Log entry"n: $($instance.location)" "Info"
        Write-Verbose "Log entry"ning State: $($instance.properties.provisioningState)" "Info"
        Write-Verbose "Log entry"nstance.properties.serviceId)" "Info"
        Write-Verbose "Log entry"Network Profile: $($instance.properties.networkProfile.outboundType)" "Info"
    [string]$apps = az spring app list --service $SpringAppsName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
        if ($apps) {
            Write-Verbose "Log entry"ns:" "Info"
            foreach ($app in $apps) {
                Write-Verbose "Log entry"Name: $($app.name)" "Info"
                Write-Verbose "Log entry"ningState)" "Info"
                Write-Verbose "Log entry"nfo"
                Write-Verbose "Log entry"nfo"
    [string]$deployments = az spring app deployment list --app $app.name --service $SpringAppsName --resource-group $ResourceGroupName --output json | ConvertFrom-Json
                foreach ($deployment in $deployments) {
                    Write-Verbose "Log entry"nt: $($deployment.name) - Status: $($deployment.properties.status)" "Info"
                    Write-Verbose "Log entry"nstances: $($deployment.properties.deploymentSettings.resourceRequests.cpu) CPU, $($deployment.properties.deploymentSettings.resourceRequests.memory) Memory" "Info"
                }
            }
        } else {
            Write-Verbose "Log entry"No applications deployed" "Info"
        }
        Write-Verbose "Log entry"ng Apps monitoring completed" "Success"
    } catch {
        Write-Verbose "Log entry"nitor Spring Apps: $($_.Exception.Message)" "Error"
    }
}
function Invoke-AppLifecycleAction {
    param(
        [ValidateSet("Start" , "Stop" , "Restart" )]
        [string]$LifecycleAction
    )
    try {
        Write-Verbose "Log entry"ng $LifecycleAction action on application: $AppName" "Info"
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
            Write-Verbose "Log entry"n action" "Success"
        } else {
            throw "Failed to execute $LifecycleAction action"
        }
    } catch {
        Write-Verbose "Log entry"n: $($_.Exception.Message)" "Error"
        throw
    }
}
try {
    Write-Verbose "Log entry"ng Azure Spring Apps Management Tool" "Info"
    Write-Verbose "Log entry"n: $Action" "Info"
    Write-Verbose "Log entry"ng Apps Name: $SpringAppsName" "Info"
    Write-Verbose "Log entry"Name" "Info"
    Initialize-SpringCLI
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
            Write-Verbose "Log entry"ng Spring Apps instance: $SpringAppsName" "Warning"
            az spring delete --name $SpringAppsName --resource-group $ResourceGroupName --yes
            if ($LASTEXITCODE -eq 0) {
                Write-Verbose "Log entry"ng Apps instance" "Success"
            } else {
                throw "Failed to delete Spring Apps instance"
            }
        }
    }
    Write-Verbose "Log entry"ng Apps Management Tool completed successfully" "Success"
} catch {
    Write-Verbose "Log entry"n failed: $($_.Exception.Message)" "Error"
    throw`n}
