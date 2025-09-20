#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Cognitive Services Manager

.DESCRIPTION
    Azure automation tool for managing Azure Cognitive Services
.AUTHOR
    Wes Ellis (wes@wesellis.com)
.VERSION
    1.0
.NOTES
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$AccountName,
    [Parameter(Mandatory)]
    [ValidateSet("Create", "GetKeys", "RegenerateKey", "Delete", "ListUsage")]
    [string]$Action,
    [Parameter()]
    [ValidateSet("ComputerVision", "Face", "LUIS", "QnAMaker", "SpeechServices", "TextAnalytics", "Translator", "AnomalyDetector", "ContentModerator", "CustomVision", "FormRecognizer", "Personalizer")]
    [string]$Kind = "TextAnalytics",
    [Parameter()]
    [string]$Location = "East US",
    [Parameter()]
    [ValidateSet("F0", "S0", "S1", "S2", "S3", "S4")]
    [string]$Sku = "S0"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    switch ($Action) {
        "Create" {
            $account = New-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName -Type $Kind -SkuName $Sku -Location $Location
            Write-Host "Endpoint: $($account.Endpoint)" -ForegroundColor Green
        }
        "GetKeys" {
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName
            Write-Host "Key 1: $($keys.Key1)" -ForegroundColor Cyan
            Write-Host "Key 2: $($keys.Key2)" -ForegroundColor Cyan
        }
        "RegenerateKey" {
            $newKeys = New-AzCognitiveServicesAccountKey -ResourceGroupName $ResourceGroupName -Name $AccountName -KeyName Key1
            Write-Host "New Key 1: $($newKeys.Key1)" -ForegroundColor Green
            Write-Host "Key 2: $($newKeys.Key2)" -ForegroundColor Cyan
        }
        "ListUsage" {
            $usage = Get-AzCognitiveServicesAccountUsage -ResourceGroupName $ResourceGroupName -Name $AccountName
            $usage | Format-Table Name, CurrentValue, Limit, QuotaPeriod
        }
        "Delete" {
            Remove-AzCognitiveServicesAccount -ResourceGroupName $ResourceGroupName -Name $AccountName -Force
            Write-Host "Cognitive Services account deleted successfully" -ForegroundColor Green
        }
    }
} catch { throw }\n

