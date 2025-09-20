<#
.SYNOPSIS
    Manage containers

.DESCRIPTION
    Manage containers
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Container Apps Provisioning Tool
#
param(
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
            $envVarArray += "$key=$($EnvironmentVariables[$key])"
        }
        $envVarsString = $envVarArray -join " "
    }
    # Create Container App
    # Progress stepNumber 5 -TotalSteps 8 -StepName "Container App Creation" -Status "Deploying container application"
    $containerAppArgs = @(
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
        $containerAppArgs += @("--ingress", "external")
    }
    if ($envVarsString) {
        $containerAppArgs += @("--env-vars", $envVarsString)
    }
    $containerApp = Invoke-AzureOperation -Operation {
        $appJson = & az @containerAppArgs 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Container App"
        }
        return ($appJson | ConvertFrom-Json)
    } -OperationName "Create Container App"
    # Configure ingress and scaling
    # Progress stepNumber 6 -TotalSteps 8 -StepName "Configuration" -Status "Configuring ingress and scaling"
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
    $tagString = ($tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " "
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
    Write-Host "                              CONTAINER APP DEPLOYMENT SUCCESSFUL"
    Write-Host ""
    Write-Host "Container App Details:"
    Write-Host "    Name: $ContainerAppName"
    Write-Host "    Resource Group: $ResourceGroupName"
    Write-Host "    Environment: $EnvironmentName"
    Write-Host "    Image: $ContainerImage"
    Write-Host "    CPU: $CpuCores cores"
    Write-Host "    Memory: $Memory"
    Write-Host "    Replicas: $MinReplicas - $MaxReplicas"
    Write-Host "    Status: $($finalApp.properties.provisioningState)"
    if ($EnableExternalIngress -and $finalApp.properties.configuration.ingress.fqdn) {
        Write-Host ""
        Write-Host "    External URL: https://$($finalApp.properties.configuration.ingress.fqdn)"
        Write-Host "    Port: $Port"
    }
    Write-Host ""
    Write-Host "    View logs: az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroupName"
    Write-Host "    Scale app: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --min-replicas X --max-replicas Y"
    Write-Host "    Update image: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --image NEW_IMAGE"
    Write-Host ""
    
} catch {
    
    Write-Host ""
    Write-Host "Troubleshooting Tips:"
    Write-Host "    Verify Azure CLI is installed: az --version"
    Write-Host "    Check Container Apps extension: az extension add --name containerapp"
    Write-Host "    Validate image accessibility: docker pull $ContainerImage"
    Write-Host "    Check resource group permissions"
    Write-Host ""
    throw
}

