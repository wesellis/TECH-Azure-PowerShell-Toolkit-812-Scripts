#Requires -Version 7.4
#Requires -Modules Az.CognitiveServices, Az.Resources

<#
.SYNOPSIS
    Azure Cognitive Services Manager

.DESCRIPTION
    Automate Azure Cognitive Services operations including creation, key management,
    and usage monitoring for AI and machine learning services

.PARAMETER ResourceGroupName
    Name of the resource group

.PARAMETER AccountName
    Name of the Cognitive Services account

.PARAMETER Action
    Action to perform: Create, GetKeys, RegenerateKey, Delete, ListUsage

.PARAMETER Kind
    Type of Cognitive Service to create

.PARAMETER Location
    Azure region for the service

.PARAMETER Sku
    Pricing tier for the service

.EXAMPLE
    .\Azure-Cognitive-Services-Manager.ps1 -ResourceGroupName "ai-rg" -AccountName "myai" -Action Create -Kind TextAnalytics

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AccountName,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Create", "GetKeys", "RegenerateKey", "Delete", "ListUsage", "GetDetails")]
    [string]$Action,

    [Parameter()]
    [ValidateSet("ComputerVision", "Face", "LUIS", "QnAMaker", "SpeechServices",
                 "TextAnalytics", "Translator", "AnomalyDetector", "ContentModerator",
                 "CustomVision", "FormRecognizer", "Personalizer", "OpenAI")]
    [string]$Kind = "TextAnalytics",

    [Parameter()]
    [string]$Location = "East US",

    [Parameter()]
    [ValidateSet("F0", "S0", "S1", "S2", "S3", "S4")]
    [string]$Sku = "S0"
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }

    $logEntry = "$timestamp [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

try {
    Write-ColorOutput "Azure Cognitive Services Manager - Starting" -Level INFO
    Write-Host "============================================" -ForegroundColor DarkGray

    # Verify Azure connection
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-ColorOutput "Connecting to Azure..." -Level INFO
        Connect-AzAccount
    }

    Write-ColorOutput "Connected to subscription: $($context.Subscription.Name)" -Level INFO

    # Perform the requested action
    switch ($Action) {
        "Create" {
            Write-ColorOutput "Creating Cognitive Services account..." -Level INFO

            # Check if resource group exists
            $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $rg) {
                Write-ColorOutput "Creating resource group: $ResourceGroupName" -Level INFO
                New-AzResourceGroup -Name $ResourceGroupName -Location $Location
            }

            # Create the account
            $accountParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $AccountName
                Type = $Kind
                SkuName = $Sku
                Location = $Location
            }

            $account = New-AzCognitiveServicesAccount @accountParams

            Write-ColorOutput "Cognitive Services account created successfully" -Level SUCCESS
            Write-Host "`nAccount Details:" -ForegroundColor Cyan
            Write-Host "Name: $($account.AccountName)"
            Write-Host "Type: $($account.Kind)"
            Write-Host "SKU: $($account.Sku.Name)"
            Write-Host "Endpoint: $($account.Endpoint)"
            Write-Host "Location: $($account.Location)"
        }

        "GetKeys" {
            Write-ColorOutput "Retrieving account keys..." -Level INFO

            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName

            Write-ColorOutput "Keys retrieved successfully" -Level SUCCESS
            Write-Host "`nAccount Keys:" -ForegroundColor Cyan
            Write-Host "Key 1: $($keys.Key1)"
            Write-Host "Key 2: $($keys.Key2)"

            Write-Warning "Keep these keys secure and do not share them"
        }

        "RegenerateKey" {
            Write-ColorOutput "Regenerating account key..." -Level INFO

            if ($PSCmdlet.ShouldProcess("Key1 for $AccountName", "Regenerate")) {
                $newKeys = New-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName -KeyName Key1

                Write-ColorOutput "Key regenerated successfully" -Level SUCCESS
                Write-Host "`nUpdated Keys:" -ForegroundColor Cyan
                Write-Host "New Key 1: $($newKeys.Key1)"
                Write-Host "Key 2 (unchanged): $($newKeys.Key2)"
            }
        }

        "ListUsage" {
            Write-ColorOutput "Retrieving usage information..." -Level INFO

            $usage = Get-AzCognitiveServicesAccountUsage -ResourceGroupName $ResourceGroupName -Name $AccountName

            if ($usage) {
                Write-ColorOutput "Usage information retrieved" -Level SUCCESS
                Write-Host "`nUsage Details:" -ForegroundColor Cyan
                $usage | Format-Table Name, CurrentValue, Limit, @{Name="Period"; Expression={$_.QuotaPeriod}}, Unit -AutoSize
            }
            else {
                Write-ColorOutput "No usage data available" -Level WARN
            }
        }

        "GetDetails" {
            Write-ColorOutput "Retrieving account details..." -Level INFO

            $account = Get-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName

            Write-ColorOutput "Account details retrieved" -Level SUCCESS
            Write-Host "`nCognitive Services Account Details:" -ForegroundColor Cyan
            Write-Host "=================================" -ForegroundColor DarkGray
            Write-Host "Name: $($account.AccountName)"
            Write-Host "Type: $($account.Kind)"
            Write-Host "SKU: $($account.Sku.Name)"
            Write-Host "Location: $($account.Location)"
            Write-Host "Resource Group: $($account.ResourceGroupName)"
            Write-Host "Endpoint: $($account.Endpoint)"
            Write-Host "Provisioning State: $($account.Properties.ProvisioningState)"

            if ($account.Tags.Count -gt 0) {
                Write-Host "`nTags:" -ForegroundColor Cyan
                foreach ($tag in $account.Tags.GetEnumerator()) {
                    Write-Host "  $($tag.Key): $($tag.Value)"
                }
            }

            # Show capabilities
            Write-Host "`nCapabilities:" -ForegroundColor Cyan
            switch ($account.Kind) {
                "TextAnalytics" {
                    Write-Host "  • Sentiment Analysis"
                    Write-Host "  • Key Phrase Extraction"
                    Write-Host "  • Language Detection"
                    Write-Host "  • Entity Recognition"
                }
                "ComputerVision" {
                    Write-Host "  • Image Analysis"
                    Write-Host "  • OCR (Optical Character Recognition)"
                    Write-Host "  • Face Detection"
                    Write-Host "  • Object Detection"
                }
                "SpeechServices" {
                    Write-Host "  • Speech to Text"
                    Write-Host "  • Text to Speech"
                    Write-Host "  • Speech Translation"
                    Write-Host "  • Speaker Recognition"
                }
                "OpenAI" {
                    Write-Host "  • GPT Models"
                    Write-Host "  • DALL-E Image Generation"
                    Write-Host "  • Embeddings"
                    Write-Host "  • Fine-tuning"
                }
                default {
                    Write-Host "  • Service-specific capabilities"
                }
            }
        }

        "Delete" {
            Write-ColorOutput "Preparing to delete Cognitive Services account..." -Level WARN

            if ($PSCmdlet.ShouldProcess("$AccountName in $ResourceGroupName", "Delete Cognitive Services Account")) {
                Remove-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName -Force

                Write-ColorOutput "Account deleted successfully" -Level SUCCESS
            }
            else {
                Write-ColorOutput "Deletion cancelled" -Level INFO
            }
        }
    }

    Write-ColorOutput "`nOperation completed successfully" -Level SUCCESS
}
catch {
    Write-ColorOutput "Operation failed: $($_.Exception.Message)" -Level ERROR
    throw
}