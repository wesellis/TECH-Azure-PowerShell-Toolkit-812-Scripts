<#
.SYNOPSIS
    Azure Containerapps Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Containerapps Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEContainerAppName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEContainerImage,
    
    [Parameter(Mandatory=$false)]
    [string]$WELocation = " East US" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WEEnvironmentName = " $WEContainerAppName-env" ,
    
    [Parameter(Mandatory=$false)]
    [int]$WEMinReplicas = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$WEMaxReplicas = 10,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$WEEnvironmentVariables = @{},
    
    [Parameter(Mandatory=$false)]
    [int]$WEPort = 80,
    
    [Parameter(Mandatory=$false)]
    [decimal]$WECpuCores = 0.25,
    
    [Parameter(Mandatory=$false)]
    [string]$WEMemory = " 0.5Gi" ,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableExternalIngress,
    
    [Parameter(Mandatory=$false)]
    [string]$WELogAnalyticsWorkspace
)


Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1" ) -Force


Show-Banner -ScriptName " Azure Container Apps Provisioning Tool" -Version " 2.0" -Description " Deploy modern serverless containers with enterprise features"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 8 -StepName " Azure Connection" -Status " Validating connection and modules"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.ContainerInstance'))) {
        throw " Azure connection validation failed"
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 8 -StepName " Resource Group Validation" -Status " Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction Stop
    } -OperationName " Get Resource Group"
    
    Write-Log " ✓ Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    # Create Container Apps Environment
    Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " Container Environment" -Status " Creating Container Apps Environment"
    
    $environmentParams = @{
        ResourceGroupName = $WEResourceGroupName
        Name = $WEEnvironmentName
        Location = $WELocation
    }
    
    if ($WELogAnalyticsWorkspace) {
        $environmentParams.LogAnalyticsWorkspace = $WELogAnalyticsWorkspace
    }
    
    Invoke-AzureOperation -Operation {
        # Note: Using Azure CLI as Az.ContainerApps module is still in preview
        $envJson = az containerapp env create `
            --name $WEEnvironmentName `
            --resource-group $WEResourceGroupName `
            --location $WELocation `
            --output json 2>$null
        
        if ($WELASTEXITCODE -ne 0) {
            throw " Failed to create Container Apps Environment"
        }
        
        return ($envJson | ConvertFrom-Json)
    } -OperationName " Create Container Apps Environment" | Out-Null
    
    Write-Log " ✓ Container Apps Environment created: $WEEnvironmentName" -Level SUCCESS

    # Prepare environment variables
    Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName " Configuration" -Status " Preparing container configuration"
    $envVarsString = ""
    if ($WEEnvironmentVariables.Count -gt 0) {
        $envVarArray = @()
        foreach ($key in $WEEnvironmentVariables.Keys) {
            $envVarArray = $envVarArray + " $key=$($WEEnvironmentVariables[$key])"
        }
        $envVarsString = $envVarArray -join " "
    }

    # Create Container App
    Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName " Container App Creation" -Status " Deploying container application"
    
    $containerAppArgs = @(
        " containerapp" , " create"
        " --name" , $WEContainerAppName
        " --resource-group" , $WEResourceGroupName
        " --environment" , $WEEnvironmentName
        " --image" , $WEContainerImage
        " --target-port" , $WEPort.ToString()
        " --cpu" , $WECpuCores.ToString()
        " --memory" , $WEMemory
        " --min-replicas" , $WEMinReplicas.ToString()
        " --max-replicas" , $WEMaxReplicas.ToString()
        " --output" , " json"
    )
    
    if ($WEEnableExternalIngress) {
        $containerAppArgs = $containerAppArgs + @(" --ingress" , " external" )
    }
    
    if ($envVarsString) {
        $containerAppArgs = $containerAppArgs + @(" --env-vars" , $envVarsString)
    }
    
    $containerApp = Invoke-AzureOperation -Operation {
        $appJson = & az @containerAppArgs 2>$null
        
        if ($WELASTEXITCODE -ne 0) {
            throw " Failed to create Container App"
        }
        
        return ($appJson | ConvertFrom-Json)
    } -OperationName " Create Container App"

    # Configure ingress and scaling
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName " Advanced Configuration" -Status " Configuring ingress and scaling"
    
    if ($WEEnableExternalIngress) {
        Write-Log " ✓ External ingress enabled for $WEContainerAppName" -Level SUCCESS
        Write-Log " 🌐 Application URL: https://$($containerApp.properties.configuration.ingress.fqdn)" -Level SUCCESS
    }

    # Add tags for enterprise governance
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName " Tagging" -Status " Applying enterprise tags"
    $tags = @{
        'Environment' = 'Production'
        'ManagedBy' = 'Azure-Automation'
        'CreatedBy' = $env:USERNAME
        'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
        'Service' = 'ContainerApps'
        'Application' = $WEContainerAppName
    }
    
    # Note: Container Apps tagging via CLI
    $tagString = ($tags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join " "
    az containerapp update --name $WEContainerAppName --resource-group $WEResourceGroupName --set-env-vars $tagString --output none 2>$null

    # Final validation and summary
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName " Validation" -Status " Verifying deployment"
    
   ;  $finalApp = Invoke-AzureOperation -Operation {
       ;  $appJson = az containerapp show --name $WEContainerAppName --resource-group $WEResourceGroupName --output json 2>$null
        if ($WELASTEXITCODE -ne 0) {
            throw " Failed to retrieve Container App details"
        }
        return ($appJson | ConvertFrom-Json)
    } -OperationName " Validate Container App"

    # Success summary
    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                              CONTAINER APP DEPLOYMENT SUCCESSFUL" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    Write-WELog " 📦 Container App Details:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Name: $WEContainerAppName" " INFO" -ForegroundColor White
    Write-WELog "   • Resource Group: $WEResourceGroupName" " INFO" -ForegroundColor White
    Write-WELog "   • Environment: $WEEnvironmentName" " INFO" -ForegroundColor White
    Write-WELog "   • Image: $WEContainerImage" " INFO" -ForegroundColor White
    Write-WELog "   • CPU: $WECpuCores cores" " INFO" -ForegroundColor White
    Write-WELog "   • Memory: $WEMemory" " INFO" -ForegroundColor White
    Write-WELog "   • Replicas: $WEMinReplicas - $WEMaxReplicas" " INFO" -ForegroundColor White
    Write-WELog "   • Status: $($finalApp.properties.provisioningState)" " INFO" -ForegroundColor Green
    
    if ($WEEnableExternalIngress -and $finalApp.properties.configuration.ingress.fqdn) {
        Write-WELog "" " INFO"
        Write-WELog " 🌐 Access Information:" " INFO" -ForegroundColor Cyan
        Write-WELog "   • External URL: https://$($finalApp.properties.configuration.ingress.fqdn)" " INFO" -ForegroundColor Yellow
        Write-WELog "   • Port: $WEPort" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 💡 Management Commands:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • View logs: az containerapp logs show --name $WEContainerAppName --resource-group $WEResourceGroupName" " INFO" -ForegroundColor White
    Write-WELog "   • Scale app: az containerapp update --name $WEContainerAppName --resource-group $WEResourceGroupName --min-replicas X --max-replicas Y" " INFO" -ForegroundColor White
    Write-WELog "   • Update image: az containerapp update --name $WEContainerAppName --resource-group $WEResourceGroupName --image NEW_IMAGE" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"

    Write-Log " ✅ Container App '$WEContainerAppName' successfully deployed with modern serverless architecture!" -Level SUCCESS

} catch {
    Write-Log " ❌ Container App deployment failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-WELog "" " INFO"
    Write-WELog " 🔧 Troubleshooting Tips:" " INFO" -ForegroundColor Yellow
    Write-WELog "   • Verify Azure CLI is installed: az --version" " INFO" -ForegroundColor White
    Write-WELog "   • Check Container Apps extension: az extension add --name containerapp" " INFO" -ForegroundColor White
    Write-WELog "   • Validate image accessibility: docker pull $WEContainerImage" " INFO" -ForegroundColor White
    Write-WELog "   • Check resource group permissions" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"
    
    exit 1
}

Write-Progress -Activity " Container App Deployment" -Completed
Write-Log " Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================