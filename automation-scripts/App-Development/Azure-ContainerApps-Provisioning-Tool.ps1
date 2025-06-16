# Azure Container Apps Provisioning Tool
# Professional Azure automation script for modern serverless containers
# Author: Wesley Ellis | wes@wesellis.com
# Version: 2.0 | Enhanced for enterprise environments

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerAppName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerImage,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "$ContainerAppName-env",
    
    [Parameter(Mandatory=$false)]
    [int]$MinReplicas = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxReplicas = 10,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$EnvironmentVariables = @{},
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 80,
    
    [Parameter(Mandatory=$false)]
    [decimal]$CpuCores = 0.25,
    
    [Parameter(Mandatory=$false)]
    [string]$Memory = "0.5Gi",
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableExternalIngress,
    
    [Parameter(Mandatory=$false)]
    [string]$LogAnalyticsWorkspace
)

# Import common functions
Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

# Professional banner
Show-Banner -ScriptName "Azure Container Apps Provisioning Tool" -Version "2.0" -Description "Deploy modern serverless containers with enterprise features"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 8 -StepName "Azure Connection" -Status "Validating connection and modules"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.ContainerInstance'))) {
        throw "Azure connection validation failed"
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 8 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    
    Write-Log "✓ Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    # Create Container Apps Environment
    Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Container Environment" -Status "Creating Container Apps Environment"
    
    $environmentParams = @{
        ResourceGroupName = $ResourceGroupName
        Name = $EnvironmentName
        Location = $Location
    }
    
    if ($LogAnalyticsWorkspace) {
        $environmentParams.LogAnalyticsWorkspace = $LogAnalyticsWorkspace
    }
    
    $environment = Invoke-AzureOperation -Operation {
        # Note: Using Azure CLI as Az.ContainerApps module is still in preview
        $envJson = az containerapp env create `
            --name $EnvironmentName `
            --resource-group $ResourceGroupName `
            --location $Location `
            --output json 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Container Apps Environment"
        }
        
        return ($envJson | ConvertFrom-Json)
    } -OperationName "Create Container Apps Environment"
    
    Write-Log "✓ Container Apps Environment created: $EnvironmentName" -Level SUCCESS

    # Prepare environment variables
    Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName "Configuration" -Status "Preparing container configuration"
    $envVarsString = ""
    if ($EnvironmentVariables.Count -gt 0) {
        $envVarArray = @()
        foreach ($key in $EnvironmentVariables.Keys) {
            $envVarArray += "$key=$($EnvironmentVariables[$key])"
        }
        $envVarsString = $envVarArray -join " "
    }

    # Create Container App
    Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName "Container App Creation" -Status "Deploying container application"
    
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
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName "Advanced Configuration" -Status "Configuring ingress and scaling"
    
    if ($EnableExternalIngress) {
        Write-Log "✓ External ingress enabled for $ContainerAppName" -Level SUCCESS
        Write-Log "🌐 Application URL: https://$($containerApp.properties.configuration.ingress.fqdn)" -Level SUCCESS
    }

    # Add tags for enterprise governance
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName "Tagging" -Status "Applying enterprise tags"
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
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName "Validation" -Status "Verifying deployment"
    
    $finalApp = Invoke-AzureOperation -Operation {
        $appJson = az containerapp show --name $ContainerAppName --resource-group $ResourceGroupName --output json 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to retrieve Container App details"
        }
        return ($appJson | ConvertFrom-Json)
    } -OperationName "Validate Container App"

    # Success summary
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                              CONTAINER APP DEPLOYMENT SUCCESSFUL" -ForegroundColor Green  
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Container App Details:" -ForegroundColor Cyan
    Write-Host "   • Name: $ContainerAppName" -ForegroundColor White
    Write-Host "   • Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "   • Environment: $EnvironmentName" -ForegroundColor White
    Write-Host "   • Image: $ContainerImage" -ForegroundColor White
    Write-Host "   • CPU: $CpuCores cores" -ForegroundColor White
    Write-Host "   • Memory: $Memory" -ForegroundColor White
    Write-Host "   • Replicas: $MinReplicas - $MaxReplicas" -ForegroundColor White
    Write-Host "   • Status: $($finalApp.properties.provisioningState)" -ForegroundColor Green
    
    if ($EnableExternalIngress -and $finalApp.properties.configuration.ingress.fqdn) {
        Write-Host ""
        Write-Host "🌐 Access Information:" -ForegroundColor Cyan
        Write-Host "   • External URL: https://$($finalApp.properties.configuration.ingress.fqdn)" -ForegroundColor Yellow
        Write-Host "   • Port: $Port" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "💡 Management Commands:" -ForegroundColor Cyan
    Write-Host "   • View logs: az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroupName" -ForegroundColor White
    Write-Host "   • Scale app: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --min-replicas X --max-replicas Y" -ForegroundColor White
    Write-Host "   • Update image: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --image NEW_IMAGE" -ForegroundColor White
    Write-Host ""

    Write-Log "✅ Container App '$ContainerAppName' successfully deployed with modern serverless architecture!" -Level SUCCESS

} catch {
    Write-Log "❌ Container App deployment failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Host ""
    Write-Host "🔧 Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "   • Verify Azure CLI is installed: az --version" -ForegroundColor White
    Write-Host "   • Check Container Apps extension: az extension add --name containerapp" -ForegroundColor White
    Write-Host "   • Validate image accessibility: docker pull $ContainerImage" -ForegroundColor White
    Write-Host "   • Check resource group permissions" -ForegroundColor White
    Write-Host ""
    
    exit 1
}

Write-Progress -Activity "Container App Deployment" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
