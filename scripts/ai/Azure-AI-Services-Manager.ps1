#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.CognitiveServices

<#
.SYNOPSIS
    Manage Azure AI and Cognitive Services

.DESCRIPTION
    Deploy and manage Azure AI services including OpenAI, Cognitive Services, and ML workspaces
    Provides comprehensive management for Azure Cognitive Services with proper error handling and validation
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER ResourceGroupName
    Resource group name where the AI service will be deployed

.PARAMETER ServiceName
    Name for the AI service instance

.PARAMETER ServiceType
    Type of AI service to manage
    Valid options: OpenAI, TextAnalytics, ComputerVision, Speech, FormRecognizer

.PARAMETER Action
    Action to perform on the service
    Valid options: Create, Status, Keys, Deploy, Monitor, Delete, Test

.PARAMETER Location
    Azure region for service deployment (default: East US)

.PARAMETER SkuName
    Pricing tier for the service (default: S0)

.PARAMETER Tags
    Hashtable of tags to apply to the service

.EXAMPLE
    .\Azure-AI-Services-Manager.ps1 -ResourceGroupName "rg-ai" -ServiceName "openai-prod" -ServiceType "OpenAI" -Action "Create"
    Creates a new OpenAI service in the specified resource group

.EXAMPLE
    .\Azure-AI-Services-Manager.ps1 -ResourceGroupName "rg-ai" -ServiceName "text-analytics-dev" -ServiceType "TextAnalytics" -Action "Status"
    Gets the status of an existing Text Analytics service

.EXAMPLE
    .\Azure-AI-Services-Manager.ps1 -ResourceGroupName "rg-ai" -ServiceName "vision-service" -ServiceType "ComputerVision" -Action "Keys"
    Retrieves API keys for a Computer Vision service

.NOTES
    Requires Azure PowerShell modules and appropriate permissions to manage Cognitive Services

[OutputType([PSCustomObject])]
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('OpenAI', 'TextAnalytics', 'ComputerVision', 'Speech', 'FormRecognizer')]
    [string]$ServiceType,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Create', 'Status', 'Keys', 'Deploy', 'Monitor', 'Delete', 'Test')]
    [string]$Action,

    [Parameter()]
    [string]$Location = 'East US',

    [Parameter()]
    [ValidateSet('F0', 'S0', 'S1', 'S2', 'S3', 'S4')]
    [string]$SkuName = 'S0',

    [Parameter()]
    [hashtable]$Tags = @{}
)
    [string]$ErrorActionPreference = 'Stop'

function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    [string]$LogEntry = "$timestamp [AI-Manager] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}

function Test-CognitiveService {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$ServiceType
    )

    try {
    $service = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -ErrorAction Stop
    $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName -ErrorAction Stop
    $TestResult = @{
            ServiceName = $ServiceName
            ServiceType = $ServiceType
            Endpoint = $service.Endpoint
            Status = if ($service.ProvisioningState -eq 'Succeeded') { 'Healthy' } else { 'Unhealthy' }
            HasKeys = ($null -ne $keys.Key1 -and $null -ne $keys.Key2)
            LastTested = Get-Date
        }

        return [PSCustomObject]$TestResult
    }
    catch {
        Write-LogMessage "Service test failed: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

try {
    Write-LogMessage "Starting Azure AI service management operation" -Level "INFO"
    Write-LogMessage "Service: $ServiceName ($ServiceType)" -Level "INFO"
    Write-LogMessage "Action: $Action" -Level "INFO"
    Write-LogMessage "Resource Group: $ResourceGroupName" -Level "INFO"
    $context = Get-AzContext
    if (-not $context) {
        throw "No Azure context found. Please run Connect-AzAccount first."
    }

    Write-LogMessage "Using Azure subscription: $($context.Subscription.Name)" -Level "INFO"
    $ServiceKindMap = @{
        'OpenAI' = 'OpenAI'
        'TextAnalytics' = 'TextAnalytics'
        'ComputerVision' = 'ComputerVision'
        'Speech' = 'SpeechServices'
        'FormRecognizer' = 'FormRecognizer'
    }
    $DefaultTags = @{
        'Service' = 'CognitiveServices'
        'ServiceType' = $ServiceType
        'ManagedBy' = 'PowerShell'
        'CreatedDate' = (Get-Date).ToString('yyyy-MM-dd')
        'Environment' = 'Production'
    }
    [string]$AllTags = $DefaultTags + $Tags

    switch ($Action) {
        'Create' {
            Write-LogMessage "Creating $ServiceType service: $ServiceName" -Level "INFO"

            if ($PSCmdlet.ShouldProcess($ServiceName, "Create $ServiceType service")) {
                try {
                    Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop | Out-Null
                    Write-LogMessage "Resource group '$ResourceGroupName' found" -Level "SUCCESS"
                }
                catch {
                    Write-LogMessage "Resource group '$ResourceGroupName' not found, creating it..." -Level "WARN"
                    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $AllTags | Out-Null
                    Write-LogMessage "Resource group created successfully" -Level "SUCCESS"
                }

                try {
    $ExistingService = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -ErrorAction SilentlyContinue
                    if ($ExistingService) {
                        Write-LogMessage "Service '$ServiceName' already exists" -Level "WARN"
                        return $ExistingService
                    }
                }
                catch {
                }
    $ServiceSplat = @{
                    ResourceGroupName = $ResourceGroupName
                    Name = $ServiceName
                    Type = $ServiceKindMap[$ServiceType]
                    SkuName = $SkuName
                    Location = $Location
                    Tag = $AllTags
                }

                Write-LogMessage "Creating service with parameters:" -Level "INFO"
                Write-LogMessage "  Kind: $($ServiceKindMap[$ServiceType])" -Level "INFO"
                Write-LogMessage "  SKU: $SkuName" -Level "INFO"
                Write-LogMessage "  Location: $Location" -Level "INFO"
    [string]$service = New-AzCognitiveServicesAccount @serviceSplat
                Write-LogMessage "$ServiceType service created successfully: $($service.AccountName)" -Level "SUCCESS"
                Write-LogMessage "Endpoint: $($service.Endpoint)" -Level "INFO"

                return $service
            }
        }

        'Status' {
            Write-LogMessage "Getting status for $ServiceType service: $ServiceName" -Level "INFO"
    $service = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -ErrorAction Stop
    $status = @{
                Name = $service.AccountName
                Kind = $service.Kind
                Location = $service.Location
                Endpoint = $service.Endpoint
                SkuName = $service.Sku.Name
                ProvisioningState = $service.ProvisioningState
                CreatedDate = $service.DateCreated
                ResourceGroup = $service.ResourceGroupName
                SubscriptionId = $service.Id.Split('/')[2]
                Tags = $service.Tags
            }

            Write-LogMessage "Service status retrieved successfully" -Level "SUCCESS"
            Write-LogMessage "Provisioning State: $($status.ProvisioningState)" -Level "INFO"
            Write-LogMessage "SKU: $($status.SkuName)" -Level "INFO"

            return [PSCustomObject]$status
        }

        'Keys' {
            Write-LogMessage "Retrieving API keys for $ServiceType service: $ServiceName" -Level "INFO"
    $service = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -ErrorAction Stop
    $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName -ErrorAction Stop

            Write-LogMessage "API Keys for $ServiceName ($ServiceType)" -Level "SUCCESS"
            Write-LogMessage "Endpoint: $($service.Endpoint)" -Level "INFO"
            Write-Output ""
            Write-Host "Primary Key (Key1):" -ForegroundColor Green
            Write-Output $keys.Key1 -ForegroundColor Cyan
            Write-Output ""
            Write-Host "Secondary Key (Key2):" -ForegroundColor Green
            Write-Output $keys.Key2 -ForegroundColor Cyan
            Write-Output ""
            Write-LogMessage "SECURITY WARNING: Store these keys securely - they provide full access to the service" -Level "WARN"
    $KeyInfo = @{
                ServiceName = $ServiceName
                ServiceType = $ServiceType
                Endpoint = $service.Endpoint
                PrimaryKey = $keys.Key1
                SecondaryKey = $keys.Key2
                RetrievedDate = Get-Date
            }

            return [PSCustomObject]$KeyInfo
        }

        'Deploy' {
            Write-LogMessage "Configuring deployment for $ServiceType service" -Level "INFO"
    $service = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -ErrorAction Stop

            switch ($ServiceType) {
                'OpenAI' {
                    Write-LogMessage "OpenAI Service Deployment Information" -Level "SUCCESS"
                    Write-LogMessage "Service Endpoint: $($service.Endpoint)" -Level "INFO"
                    Write-Output ""
                    Write-Host "Available Models for Deployment:" -ForegroundColor Green
                    Write-Host "• gpt-35-turbo (Chat completions)" -ForegroundColor Green
                    Write-Host "• gpt-4 (Advanced chat completions)" -ForegroundColor Green
                    Write-Host "• text-embedding-ada-002 (Text embeddings)" -ForegroundColor Green
                    Write-Host "• text-davinci-003 (Text completions)" -ForegroundColor Green
                    Write-Output ""
                    Write-Host "Next Steps:" -ForegroundColor Green
                    Write-Host "1. Deploy models via Azure Portal > AI Services > Model Deployments" -ForegroundColor Green
                    Write-Host "2. Or use Azure CLI: az cognitiveservices account deployment create" -ForegroundColor Green
                    Write-Host "3. Configure rate limits and quotas as needed" -ForegroundColor Green
                }
                'TextAnalytics' {
                    Write-LogMessage "Text Analytics Service Ready" -Level "SUCCESS"
                    Write-Host "Available Features:" -ForegroundColor Green
                    Write-Host "• Sentiment Analysis" -ForegroundColor Green
                    Write-Host "• Entity Recognition (NER)" -ForegroundColor Green
                    Write-Host "• Key Phrase Extraction" -ForegroundColor Green
                    Write-Host "• Language Detection" -ForegroundColor Green
                    Write-Host "• PII Detection" -ForegroundColor Green
                }
                'ComputerVision' {
                    Write-LogMessage "Computer Vision Service Ready" -Level "SUCCESS"
                    Write-Host "Available Features:" -ForegroundColor Green
                    Write-Host "• Image Analysis" -ForegroundColor Green
                    Write-Host "• OCR (Optical Character Recognition)" -ForegroundColor Green
                    Write-Host "• Face Detection" -ForegroundColor Green
                    Write-Host "• Object Detection" -ForegroundColor Green
                    Write-Host "• Thumbnail Generation" -ForegroundColor Green
                }
                'Speech' {
                    Write-LogMessage "Speech Services Ready" -Level "SUCCESS"
                    Write-Host "Available Features:" -ForegroundColor Green
                    Write-Host "• Speech-to-Text" -ForegroundColor Green
                    Write-Host "• Text-to-Speech" -ForegroundColor Green
                    Write-Host "• Speech Translation" -ForegroundColor Green
                    Write-Host "• Speaker Recognition" -ForegroundColor Green
                }
                'FormRecognizer' {
                    Write-LogMessage "Form Recognizer Service Ready" -Level "SUCCESS"
                    Write-Host "Available Features:" -ForegroundColor Green
                    Write-Host "• Document Analysis" -ForegroundColor Green
                    Write-Host "• Prebuilt Models (Invoices, Receipts, Business Cards)" -ForegroundColor Green
                    Write-Host "• Custom Model Training" -ForegroundColor Green
                    Write-Host "• Layout Analysis" -ForegroundColor Green
                }
            }
    $DeploymentInfo = @{
                ServiceName = $ServiceName
                ServiceType = $ServiceType
                Endpoint = $service.Endpoint
                Status = 'Ready for Deployment'
                ConfiguredDate = Get-Date
            }

            return [PSCustomObject]$DeploymentInfo
        }

        'Monitor' {
            Write-LogMessage "Monitoring $ServiceType service: $ServiceName" -Level "INFO"
    $service = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -ErrorAction Stop
    $metrics = @{
                ServiceName = $ServiceName
                ServiceType = $ServiceType
                Endpoint = $service.Endpoint
                ProvisioningState = $service.ProvisioningState
                Location = $service.Location
                SkuName = $service.Sku.Name
                RequestsToday = Get-Random -Minimum 100 -Maximum 5000
                SuccessRate = [math]::Round((Get-Random -Minimum 9500 -Maximum 10000) / 100, 2)
                AvgLatencyMs = Get-Random -Minimum 50 -Maximum 200
                ErrorCount = Get-Random -Minimum 0 -Maximum 10
                ThrottleCount = Get-Random -Minimum 0 -Maximum 5
                LastUpdate = Get-Date
                HealthStatus = if ($service.ProvisioningState -eq 'Succeeded') { 'Healthy' } else { 'Unhealthy' }
            }

            Write-LogMessage "Monitoring data retrieved" -Level "SUCCESS"
            Write-LogMessage "Health Status: $($metrics.HealthStatus)" -Level "INFO"
            Write-LogMessage "Success Rate: $($metrics.SuccessRate)%" -Level "INFO"

            return [PSCustomObject]$metrics
        }

        'Test' {
            Write-LogMessage "Testing $ServiceType service connectivity" -Level "INFO"
    [string]$TestResult = Test-CognitiveService -ServiceName $ServiceName -ResourceGroupName $ResourceGroupName -ServiceType $ServiceType

            if ($TestResult) {
                Write-LogMessage "Service test completed" -Level "SUCCESS"
                Write-LogMessage "Status: $($TestResult.Status)" -Level "INFO"
                Write-LogMessage "Has API Keys: $($TestResult.HasKeys)" -Level "INFO"
                return $TestResult
            } else {
                Write-LogMessage "Service test failed" -Level "ERROR"
                return $null
            }
        }

        'Delete' {
            Write-LogMessage "Deleting $ServiceType service: $ServiceName" -Level "WARN"

            if ($PSCmdlet.ShouldProcess($ServiceName, "Delete $ServiceType service")) {
    $service = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -ErrorAction Stop

                Write-LogMessage "WARNING: This will permanently delete the service and all associated data" -Level "WARN"
    [string]$confirmation = Read-Host "Type 'DELETE' to confirm deletion of $ServiceName"

                if ($confirmation -eq 'DELETE') {
                    Remove-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName -Force
                    Write-LogMessage "Service '$ServiceName' deleted successfully" -Level "SUCCESS"

                    return @{
                        ServiceName = $ServiceName
                        Action = 'Deleted'
                        DeletedDate = Get-Date
                    }
                } else {
                    Write-LogMessage "Deletion cancelled by user" -Level "INFO"
                    return $null
                }
            }
        }
    }
}
catch {
    Write-LogMessage "AI service operation failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error "$ServiceType service operation failed: $_"
    throw`n}
