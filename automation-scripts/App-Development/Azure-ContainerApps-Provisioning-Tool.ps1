#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Azure Container Apps Provisioning Tool
# Professional Azure automation script for modern serverless containers
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

#region Functions

# Import common functions
# Module import removed - use #Requires instead

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
    
    Write-Log "[OK] Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

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
        Write-Log "[OK] External ingress enabled for $ContainerAppName" -Level SUCCESS
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
    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                              CONTAINER APP DEPLOYMENT SUCCESSFUL"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    Write-Information " Container App Details:"
    Write-Information "   • Name: $ContainerAppName"
    Write-Information "   • Resource Group: $ResourceGroupName"
    Write-Information "   • Environment: $EnvironmentName"
    Write-Information "   • Image: $ContainerImage"
    Write-Information "   • CPU: $CpuCores cores"
    Write-Information "   • Memory: $Memory"
    Write-Information "   • Replicas: $MinReplicas - $MaxReplicas"
    Write-Information "   • Status: $($finalApp.properties.provisioningState)"
    
    if ($EnableExternalIngress -and $finalApp.properties.configuration.ingress.fqdn) {
        Write-Information ""
        Write-Information "� Access Information:"
        Write-Information "   • External URL: https://$($finalApp.properties.configuration.ingress.fqdn)"
        Write-Information "   • Port: $Port"
    }
    
    Write-Information ""
    Write-Information "� Management Commands:"
    Write-Information "   • View logs: az containerapp logs show --name $ContainerAppName --resource-group $ResourceGroupName"
    Write-Information "   • Scale app: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --min-replicas X --max-replicas Y"
    Write-Information "   • Update image: az containerapp update --name $ContainerAppName --resource-group $ResourceGroupName --image NEW_IMAGE"
    Write-Information ""

    Write-Log " Container App '$ContainerAppName' successfully deployed with modern serverless architecture!" -Level SUCCESS

} catch {
    Write-Log " Container App deployment failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Information ""
    Write-Information " Troubleshooting Tips:"
    Write-Information "   • Verify Azure CLI is installed: az --version"
    Write-Information "   • Check Container Apps extension: az extension add --name containerapp"
    Write-Information "   • Validate image accessibility: docker pull $ContainerImage"
    Write-Information "   • Check resource group permissions"
    Write-Information ""
    
    exit 1
}

Write-Progress -Activity "Container App Deployment" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO


#endregion
