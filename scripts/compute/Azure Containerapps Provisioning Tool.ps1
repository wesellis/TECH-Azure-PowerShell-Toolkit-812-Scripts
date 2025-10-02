#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Containerapps Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerAppName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ContainerImage,
    [Parameter()]
    [string]$Location = "East US" ,
    [Parameter()]
    [string]$EnvironmentName = " $ContainerAppName-env" ,
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
    [string]$Memory = " 0.5Gi" ,
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
    [string]$ResourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    $EnvironmentParams = @{
        ResourceGroupName = $ResourceGroupName
        Name = $EnvironmentName
        Location = $Location
    }
    if ($LogAnalyticsWorkspace) {
    [string]$EnvironmentParams.LogAnalyticsWorkspace = $LogAnalyticsWorkspace
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
    [string]$EnvJson @params
    [string]$EnvVarsString = ""
    if ($EnvironmentVariables.Count -gt 0) {
    [string]$EnvVarArray = @()
        foreach ($key in $EnvironmentVariables.Keys) {
    [string]$EnvVarArray = $EnvVarArray + " $key=$($EnvironmentVariables[$key])"
        }
    [string]$EnvVarsString = $EnvVarArray -join " "
    }
    [string]$ContainerAppArgs = @(
        " containerapp" , "create"
        " --name" , $ContainerAppName
        " --resource-group" , $ResourceGroupName
        " --environment" , $EnvironmentName
        " --image" , $ContainerImage
        " --target-port" , $Port.ToString()
        " --cpu" , $CpuCores.ToString()
        " --memory" , $Memory
        " --min-replicas" , $MinReplicas.ToString()
        " --max-replicas" , $MaxReplicas.ToString()
        " --output" , "json"
    )
    if ($EnableExternalIngress) {
    [string]$ContainerAppArgs = $ContainerAppArgs + @(" --ingress" , "external" )
    }
    if ($EnvVarsString) {
    [string]$ContainerAppArgs = $ContainerAppArgs + @(" --env-vars" , $EnvVarsString)
    }
    [string]$ContainerApp = Invoke-AzureOperation -Operation {
    [string]$AppJson = & az @containerAppArgs 2>$null
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
    [string]$TagString = ($tags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join " "
    az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --set-env-vars $TagString --output none 2>$null
    [string]$FinalApp = Invoke-AzureOperation -Operation {
    [string]$AppJson = az containerapp show --name $ContainerAppName --resource-group $ResourceGroupName --output json 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to retrieve Container App details"
        }
        return ($AppJson | ConvertFrom-Json)
    } -OperationName "Validate Container App"
    Write-Output ""
    Write-Host "                              CONTAINER APP DEPLOYMENT SUCCESSFUL" -ForegroundColor Green
    Write-Output ""
    Write-Host "Container App Details:" -ForegroundColor Green
    Write-Host "    Name: $ContainerAppName" -ForegroundColor Green
    Write-Host "    Resource Group: $ResourceGroupName" -ForegroundColor Green
    Write-Host "    Environment: $EnvironmentName" -ForegroundColor Green
    Write-Host "    Image: $ContainerImage" -ForegroundColor Green
    Write-Host "    CPU: $CpuCores cores" -ForegroundColor Green
    Write-Host "    Memory: $Memory" -ForegroundColor Green
    Write-Host "    Replicas: $MinReplicas - $MaxReplicas" -ForegroundColor Green
    Write-Host "    Status: $($FinalApp.properties.provisioningState)" -ForegroundColor Green
    if ($EnableExternalIngress -and $FinalApp.properties.configuration.ingress.fqdn) {
        Write-Output ""
        Write-Host "Access Information:" -ForegroundColor Green
        Write-Host "    External URL: https://$($FinalApp.properties.configuration.ingress.fqdn)" -ForegroundColor Green
        Write-Host "    Port: $Port" -ForegroundColor Green
    }
    Write-Output ""
    Write-Host "Management Commands:" -ForegroundColor Green
    Write-Host "    View logs: az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroupName" -ForegroundColor Green
    Write-Host "    Scale app: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --min-replicas X --max-replicas Y" -ForegroundColor Green
    Write-Host "    Update image: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --image NEW_IMAGE" -ForegroundColor Green
    Write-Output ""

} catch {

    Write-Output ""
    Write-Host "Troubleshooting Tips:" -ForegroundColor Green
    Write-Host "    Verify Azure CLI is installed: az --version" -ForegroundColor Green
    Write-Host "    Check Container Apps extension: az extension add --name containerapp" -ForegroundColor Green
    Write-Host "    Validate image accessibility: docker pull $ContainerImage" -ForegroundColor Green
    Write-Host "    Check resource group permissions" -ForegroundColor Green
    Write-Output ""
    throw`n}
