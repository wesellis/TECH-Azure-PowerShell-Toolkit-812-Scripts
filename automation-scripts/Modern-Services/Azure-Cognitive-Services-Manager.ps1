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
# Azure Cognitive Services Manager
# Manage Azure Cognitive Services accounts and endpoints
# Version: 1.0

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AccountName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Create", "GetKeys", "RegenerateKey", "Delete", "ListUsage")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("ComputerVision", "Face", "LUIS", "QnAMaker", "SpeechServices", "TextAnalytics", "Translator", "AnomalyDetector", "ContentModerator", "CustomVision", "FormRecognizer", "Personalizer")]
    [string]$Kind = "TextAnalytics",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("F0", "S0", "S1", "S2", "S3", "S4")]
    [string]$Sku = "S0"
)

#region Functions

# Module import removed - use #Requires instead
Show-Banner -ScriptName "Azure Cognitive Services Manager" -Version "1.0" -Description "Manage AI and machine learning services"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.CognitiveServices'))) {
        throw "Azure connection validation failed"
    }

    switch ($Action) {
        "Create" {
            Write-Log "🧠 Creating Cognitive Services account..." -Level INFO
            $account = New-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName -Type $Kind -SkuName $Sku -Location $Location
            Write-Log "[OK] Created $Kind account: $AccountName" -Level SUCCESS
            Write-Information "Endpoint: $($account.Endpoint)"
        }
        
        "GetKeys" {
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
            Write-Information "Key 1: $($keys.Key1)"
            Write-Information "Key 2: $($keys.Key2)"
        }
        
        "RegenerateKey" {
            $newKeys = New-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName -KeyName Key1
            Write-Log "[OK] Key regenerated successfully" -Level SUCCESS
            Write-Information "New Key 1: $($newKeys.Key1)"
            Write-Information "Key 2: $($newKeys.Key2)"
        }
        
        "ListUsage" {
            $usage = Get-AzCognitiveServicesAccountUsage -ResourceGroupName $ResourceGroupName -Name $AccountName
            $usage | Format-Table Name, CurrentValue, Limit, QuotaPeriod
        }
        
        "Delete" {
            Remove-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName -Force
            Write-Log "[OK] Cognitive Services account deleted" -Level SUCCESS
        }
    }

} catch {
    Write-Log " Cognitive Services operation failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}


#endregion
