#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Cognitive Services Manager
# Manage Azure Cognitive Services accounts and endpoints
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$AccountName,
    [Parameter(Mandatory)]
    [ValidateSet("Create", "GetKeys", "RegenerateKey", "Delete", "ListUsage")]
    [string]$Action,
    [ValidateSet("ComputerVision", "Face", "LUIS", "QnAMaker", "SpeechServices", "TextAnalytics", "Translator", "AnomalyDetector", "ContentModerator", "CustomVision", "FormRecognizer", "Personalizer")]
    [string]$Kind = "TextAnalytics",
    [Parameter()]
    [string]$Location = "East US",
    [ValidateSet("F0", "S0", "S1", "S2", "S3", "S4")]
    [string]$Sku = "S0"
)
riptName "Azure Cognitive Services Manager" -Version "1.0" -Description "Manage AI and machine learning services"
try {
    if (-not ((Get-AzContext) -RequiredModules @('Az.CognitiveServices'))) {
        throw "Azure connection validation failed"
    }
    switch ($Action) {
        "Create" {
            
            $account = New-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName -Type $Kind -SkuName $Sku -Location $Location
            
            Write-Host "Endpoint: $($account.Endpoint)"
        }
        "GetKeys" {
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
            Write-Host "Key 1: $($keys.Key1)"
            Write-Host "Key 2: $($keys.Key2)"
        }
        "RegenerateKey" {
            $newKeys = New-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName -KeyName Key1
            
            Write-Host "New Key 1: $($newKeys.Key1)"
            Write-Host "Key 2: $($newKeys.Key2)"
        }
        "ListUsage" {
            $usage = Get-AzCognitiveServicesAccountUsage -ResourceGroupName $ResourceGroupName -Name $AccountName
            $usage | Format-Table Name, CurrentValue, Limit, QuotaPeriod
        }
        "Delete" {
            if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
            
        }
    }
} catch { throw }

