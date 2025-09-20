#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Containerapps Provisioning Tool

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
    # Test Azure connection
    # Progress stepNumber 1 -TotalSteps 8 -StepName "Azure Connection" -Status "Validating connection and modules"
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    # Validate resource group
    # Progress stepNumber 2 -TotalSteps 8 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    # Create Container Apps Environment
    # Progress stepNumber 3 -TotalSteps 8 -StepName "Container Environment" -Status "Creating Container Apps Environment"
    $environmentParams = @{
        ResourceGroupName = $ResourceGroupName
        Name = $EnvironmentName
        Location = $Location
    }
    if ($LogAnalyticsWorkspace) {
        $environmentParams.LogAnalyticsWorkspace = $LogAnalyticsWorkspace
    }
    Invoke-AzureOperation -Operation {
        # Note: Using Azure CLI as Az.ContainerApps module is still in preview
        $params = @{
            Level = "SUCCESS"
            name = $EnvironmentName
            location = $Location
            ne = "0) { throw "Failed to create Container Apps Environment" }  return ($envJson | ConvertFrom-Json) }"
            output = "json 2>$null  if ($LASTEXITCODE"
            group = $ResourceGroupName
            OperationName = "Create Container Apps Environment" | Out-Null  Write-Log "[OK] Container Apps Environment created: $EnvironmentName"
        }
        $envJson @params
    # Prepare environment variables
    # Progress stepNumber 4 -TotalSteps 8 -StepName "Configuration" -Status "Preparing container configuration"
    $envVarsString = ""
    if ($EnvironmentVariables.Count -gt 0) {
        $envVarArray = @()
        foreach ($key in $EnvironmentVariables.Keys) {
            $envVarArray = $envVarArray + " $key=$($EnvironmentVariables[$key])"
        }
        $envVarsString = $envVarArray -join " "
    }
    # Create Container App
    # Progress stepNumber 5 -TotalSteps 8 -StepName "Container App Creation" -Status "Deploying container application"
    $containerAppArgs = @(
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
        $containerAppArgs = $containerAppArgs + @(" --ingress" , "external" )
    }
    if ($envVarsString) {
        $containerAppArgs = $containerAppArgs + @(" --env-vars" , $envVarsString)
    }
    $containerApp = Invoke-AzureOperation -Operation {
        $appJson = & az @containerAppArgs 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Container App"
        }
        return ($appJson | ConvertFrom-Json)
    } -OperationName "Create Container App"
    # Configure ingress and scaling
    # Progress stepNumber 6 -TotalSteps 8 -StepName "  Configuration" -Status "Configuring ingress and scaling"
    if ($EnableExternalIngress) {

    }
    # Add tags for enterprise governance
    # Progress stepNumber 7 -TotalSteps 8 -StepName "Tagging" -Status "Applying enterprise tags"
    $tags = @{
        'Environment' = 'Production'
        'ManagedBy' = 'Azure-Automation'
        'CreatedBy' = $env:USERNAME
        'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
        'Service' = 'ContainerApps'
        'Application' = $ContainerAppName
    }
    # Note: Container Apps tagging via CLI
    $tagString = ($tags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join " "
    az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --set-env-vars $tagString --output none 2>$null
    # Final validation and summary
    # Progress stepNumber 8 -TotalSteps 8 -StepName "Validation" -Status "Verifying deployment"
$finalApp = Invoke-AzureOperation -Operation {
$appJson = az containerapp show --name $ContainerAppName --resource-group $ResourceGroupName --output json 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to retrieve Container App details"
        }
        return ($appJson | ConvertFrom-Json)
    } -OperationName "Validate Container App"
    # Success summary
    Write-Host ""
    Write-Host "                              CONTAINER APP DEPLOYMENT SUCCESSFUL" -ForegroundColor Green
    Write-Host ""
    Write-Host "Container App Details:" -ForegroundColor Cyan
    Write-Host "    Name: $ContainerAppName" -ForegroundColor White
    Write-Host "    Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "    Environment: $EnvironmentName" -ForegroundColor White
    Write-Host "    Image: $ContainerImage" -ForegroundColor White
    Write-Host "    CPU: $CpuCores cores" -ForegroundColor White
    Write-Host "    Memory: $Memory" -ForegroundColor White
    Write-Host "    Replicas: $MinReplicas - $MaxReplicas" -ForegroundColor White
    Write-Host "    Status: $($finalApp.properties.provisioningState)" -ForegroundColor Green
    if ($EnableExternalIngress -and $finalApp.properties.configuration.ingress.fqdn) {
        Write-Host ""
        Write-Host "Access Information:" -ForegroundColor Cyan
        Write-Host "    External URL: https://$($finalApp.properties.configuration.ingress.fqdn)" -ForegroundColor Yellow
        Write-Host "    Port: $Port" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Management Commands:" -ForegroundColor Cyan
    Write-Host "    View logs: az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroupName" -ForegroundColor White
    Write-Host "    Scale app: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --min-replicas X --max-replicas Y" -ForegroundColor White
    Write-Host "    Update image: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --image NEW_IMAGE" -ForegroundColor White
    Write-Host ""

} catch {

    Write-Host ""
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "    Verify Azure CLI is installed: az --version" -ForegroundColor White
    Write-Host "    Check Container Apps extension: az extension add --name containerapp" -ForegroundColor White
    Write-Host "    Validate image accessibility: docker pull $ContainerImage" -ForegroundColor White
    Write-Host "    Check resource group permissions" -ForegroundColor White
    Write-Host ""
    throw
}\n

