#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage containers

.DESCRIPTION
    Manage containers
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ContainerAppName,
    [Parameter(Mandatory)]
    [string]$ContainerImage,
    [Parameter()]
    [string]$Location = "East US",
    [Parameter()]
    [string]$EnvironmentName = "$ContainerAppName-env",
    [Parameter()]
    [int]$MinReplicas = 0,
    [Parameter()]
    [int]$MaxReplicas = 10,
    [Parameter()]
    [hashtable]$EnvironmentVariables = @{},
    [Parameter()]
    [int]$Port = 80,
    [Parameter()]
    [decimal]$CpuCores = 0.25,
    [Parameter()]
    [string]$Memory = "0.5Gi",
    [Parameter()]
    [switch]$EnableExternalIngress,
    [Parameter()]
    [string]$LogAnalyticsWorkspace
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    $ResourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    $EnvironmentParams = @{
        ResourceGroupName = $ResourceGroupName
        Name = $EnvironmentName
        Location = $Location
    }
    if ($LogAnalyticsWorkspace) {
        $EnvironmentParams.LogAnalyticsWorkspace = $LogAnalyticsWorkspace
    }
    Invoke-AzureOperation -Operation {
        $params = @{
            Level = "SUCCESS"
            name = $EnvironmentName
            location = $Location
            ne = "0) { throw "Failed to create Container Apps Environment" }  return ($EnvJson | ConvertFrom-Json) }"
            output = "json 2>$null  if ($LASTEXITCODE"
            group = $ResourceGroupName
            OperationName = "Create Container Apps Environment" | Out-Null  Write-Log "[OK] Container Apps Environment created: $EnvironmentName"
        }
        $EnvJson @params
    $EnvVarsString = ""
    if ($EnvironmentVariables.Count -gt 0) {
        $EnvVarArray = @()
        foreach ($key in $EnvironmentVariables.Keys) {
            $EnvVarArray += "$key=$($EnvironmentVariables[$key])"
        }
        $EnvVarsString = $EnvVarArray -join " "
    }
    $ContainerAppArgs = @(
        "containerapp", "create"
        "--name", $ContainerAppName
        "--resource-group", $ResourceGroupName
        "--environment", $EnvironmentName
        "--image", $ContainerImage
        "--target-port", $Port.ToString()
        "--cpu", $CpuCores.ToString()
        "--memory", $Memory
        "--min-replicas", $MinReplicas.ToString()
        "--max-replicas", $MaxReplicas.ToString()
        "--output", "json"
    )
    if ($EnableExternalIngress) {
        $ContainerAppArgs += @("--ingress", "external")
    }
    if ($EnvVarsString) {
        $ContainerAppArgs += @("--env-vars", $EnvVarsString)
    }
    $ContainerApp = Invoke-AzureOperation -Operation {
        $AppJson = & az @containerAppArgs 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Container App"
        }
        return ($AppJson | ConvertFrom-Json)
    } -OperationName "Create Container App"
    if ($EnableExternalIngress) {

    }
    $tags = @{
        'Environment' = 'Production'
        'ManagedBy' = 'Azure-Automation'
        'CreatedBy' = $env:USERNAME
        'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
        'Service' = 'ContainerApps'
        'Application' = $ContainerAppName
    }
    $TagString = ($tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " "
    az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --set-env-vars $TagString --output none 2>$null
    $FinalApp = Invoke-AzureOperation -Operation {
        $AppJson = az containerapp show --name $ContainerAppName --resource-group $ResourceGroupName --output json 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to retrieve Container App details"
        }
        return ($AppJson | ConvertFrom-Json)
    } -OperationName "Validate Container App"
    Write-Output ""
    Write-Output "                              CONTAINER APP DEPLOYMENT SUCCESSFUL"
    Write-Output ""
    Write-Output "Container App Details:"
    Write-Output "    Name: $ContainerAppName"
    Write-Output "    Resource Group: $ResourceGroupName"
    Write-Output "    Environment: $EnvironmentName"
    Write-Output "    Image: $ContainerImage"
    Write-Output "    CPU: $CpuCores cores"
    Write-Output "    Memory: $Memory"
    Write-Output "    Replicas: $MinReplicas - $MaxReplicas"
    Write-Output "    Status: $($FinalApp.properties.provisioningState)"
    if ($EnableExternalIngress -and $FinalApp.properties.configuration.ingress.fqdn) {
        Write-Output ""
        Write-Output "    External URL: https://$($FinalApp.properties.configuration.ingress.fqdn)"
        Write-Output "    Port: $Port"
    }
    Write-Output ""
    Write-Output "    View logs: az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroupName"
    Write-Output "    Scale app: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --min-replicas X --max-replicas Y"
    Write-Output "    Update image: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --image NEW_IMAGE"
    Write-Output ""

} catch {

    Write-Output ""
    Write-Output "Troubleshooting Tips:"
    Write-Output "    Verify Azure CLI is installed: az --version"
    Write-Output "    Check Container Apps extension: az extension add --name containerapp"
    Write-Output "    Validate image accessibility: docker pull $ContainerImage"
    Write-Output "    Check resource group permissions"
    Write-Output ""
    throw`n}
