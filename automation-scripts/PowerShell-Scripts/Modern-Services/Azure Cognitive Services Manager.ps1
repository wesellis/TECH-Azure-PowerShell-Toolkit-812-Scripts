<#
.SYNOPSIS
    We Enhanced Azure Cognitive Services Manager

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAccountName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet(" Create", " GetKeys", " RegenerateKey", " Delete", " ListUsage")]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" ComputerVision", " Face", " LUIS", " QnAMaker", " SpeechServices", " TextAnalytics", " Translator", " AnomalyDetector", " ContentModerator", " CustomVision", " FormRecognizer", " Personalizer")]
    [string]$WEKind = " TextAnalytics",
    
    [Parameter(Mandatory=$false)]
    [string]$WELocation = " East US",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" F0", " S0", " S1", " S2", " S3", " S4")]
    [string]$WESku = " S0"
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName " Azure Cognitive Services Manager" -Version " 1.0" -Description " Manage AI and machine learning services"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.CognitiveServices'))) {
        throw " Azure connection validation failed"
    }

    switch ($WEAction) {
        " Create" {
            Write-Log " 🧠 Creating Cognitive Services account..." -Level INFO
            $account = New-AzCognitiveServicesAccount -ResourceGroupName $WEResourceGroupName -Name $WEAccountName -Type $WEKind -SkuName $WESku -Location $WELocation
            Write-Log " ✓ Created $WEKind account: $WEAccountName" -Level SUCCESS
            Write-WELog " Endpoint: $($account.Endpoint)" " INFO" -ForegroundColor Green
        }
        
        " GetKeys" {
            $keys = Get-AzCognitiveServicesAccountKey -ResourceGroupName $WEResourceGroupName -Name $WEAccountName
            Write-WELog " Key 1: $($keys.Key1)" " INFO" -ForegroundColor Cyan
            Write-WELog " Key 2: $($keys.Key2)" " INFO" -ForegroundColor Cyan
        }
        
        " RegenerateKey" {
            $newKeys = New-AzCognitiveServicesAccountKey -ResourceGroupName $WEResourceGroupName -Name $WEAccountName -KeyName Key1
            Write-Log " ✓ Key regenerated successfully" -Level SUCCESS
            Write-WELog " New Key 1: $($newKeys.Key1)" " INFO" -ForegroundColor Green
            Write-WELog " Key 2: $($newKeys.Key2)" " INFO" -ForegroundColor Cyan
        }
        
        " ListUsage" {
           ;  $usage = Get-AzCognitiveServicesAccountUsage -ResourceGroupName $WEResourceGroupName -Name $WEAccountName
            $usage | Format-Table Name, CurrentValue, Limit, QuotaPeriod
        }
        
        " Delete" {
            Remove-AzCognitiveServicesAccount -ResourceGroupName $WEResourceGroupName -Name $WEAccountName -Force
            Write-Log " ✓ Cognitive Services account deleted" -Level SUCCESS
        }
    }

} catch {
    Write-Log " ❌ Cognitive Services operation failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================