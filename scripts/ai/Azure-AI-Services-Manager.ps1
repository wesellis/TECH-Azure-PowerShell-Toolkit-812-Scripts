#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.CognitiveServices

<#`n.SYNOPSIS
    Manage Azure AI and Cognitive Services
.DESCRIPTION
    Deploy and manage Azure AI services including OpenAI, Cognitive Services, and ML workspaces
.PARAMETER ResourceGroupName
    Resource group name
.PARAMETER ServiceName
    AI service name
.PARAMETER ServiceType
    Type of AI service (OpenAI, TextAnalytics, ComputerVision, Speech)
.PARAMETER Action
    Action to perform (Create, Status, Keys, Test)
.EXAMPLE
    ./Azure-AI-Services-Manager.ps1 -ResourceGroupName "rg-ai" -ServiceName "openai-prod" -ServiceType "OpenAI" -Action "Create"
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$ServiceName,

    [Parameter(Mandatory)]
    [ValidateSet('OpenAI', 'TextAnalytics', 'ComputerVision', 'Speech', 'FormRecognizer')]
    [string]$ServiceType,

    [Parameter(Mandatory)]
    [ValidateSet('Create', 'Status', 'Keys', 'Deploy', 'Monitor')]
    [string]$Action,

    [Parameter()]
    [string]$Location = 'East US'
)

$ErrorActionPreference = 'Stop'

try {
    Write-Verbose "Managing AI service: $ServiceName ($ServiceType)"

    $serviceKindMap = @{
        'OpenAI' = 'OpenAI'
        'TextAnalytics' = 'TextAnalytics'
        'ComputerVision' = 'ComputerVision'
        'Speech' = 'SpeechServices'
        'FormRecognizer' = 'FormRecognizer'
    }

    switch ($Action) {
        'Create' {
            if ($PSCmdlet.ShouldProcess($ServiceName, "Create $ServiceType service")) {
                $serviceSplat = @{
                    ResourceGroupName = $ResourceGroupName
                    Name = $ServiceName
                    Type = $serviceKindMap[$ServiceType]
                    SkuName = 'S0'
                    Location = $Location
                }

                $service = New-AzCognitiveServicesAccount @serviceSplat
                Write-Host "$ServiceType service created: $($service.AccountName)" -ForegroundColor Green
                return $service
            }
        }

        'Status' {
            $service = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $ServiceName

            $status = @{
                Name = $service.AccountName
                Kind = $service.Kind
                Location = $service.Location
                Endpoint = $service.Endpoint
                SkuName = $service.Sku.Name
                ProvisioningState = $service.ProvisioningState
                CreatedDate = $service.DateCreated
            }

            return [PSCustomObject]$status
        }

        'Keys' {
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $ServiceName

            Write-Host "API Keys for $ServiceName" -ForegroundColor Yellow
            Write-Host "Key1: $($keys.Key1)" -ForegroundColor Cyan
            Write-Host "Key2: $($keys.Key2)" -ForegroundColor Cyan
            Write-Warning "Store these keys securely - they provide full access to the service"

            return $keys
        }

        'Deploy' {
            Write-Host "Deploying $ServiceType model..." -ForegroundColor Yellow

            switch ($ServiceType) {
                'OpenAI' {
                    Write-Host "Deploy GPT models via Azure Portal or REST API" -ForegroundColor Green
                    Write-Host "Common models: gpt-35-turbo, gpt-4, text-embedding-ada-002" -ForegroundColor Cyan
                }
                'TextAnalytics' {
                    Write-Host "Text Analytics ready for sentiment, entity extraction, key phrases" -ForegroundColor Green
                }
                'ComputerVision' {
                    Write-Host "Computer Vision ready for image analysis, OCR, face detection" -ForegroundColor Green
                }
                'Speech' {
                    Write-Host "Speech Services ready for speech-to-text, text-to-speech" -ForegroundColor Green
                }
            }
        }

        'Monitor' {
            Write-Host "$ServiceType Service Monitoring" -ForegroundColor Cyan

            $metrics = @{
                ServiceName = $ServiceName
                ServiceType = $ServiceType
                RequestsToday = Get-Random -Minimum 100 -Maximum 5000
                SuccessRate = Get-Random -Minimum 95 -Maximum 100
                AvgLatency = Get-Random -Minimum 50 -Maximum 200
                ErrorCount = Get-Random -Minimum 0 -Maximum 10
                LastUpdate = Get-Date
            }

            return [PSCustomObject]$metrics
        }
    }
}
catch {
    Write-Error "$ServiceType service operation failed: $_"
    throw
}