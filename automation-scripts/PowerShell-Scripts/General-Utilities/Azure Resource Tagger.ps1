<#
.SYNOPSIS
    Azure Resource Tagger

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
    We Enhanced Azure Resource Tagger

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
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [hashtable]$WETags = @{},
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceType,
    [switch]$WEWhatIf,
    [switch]$WEForce
)

Write-WELog " Azure Resource Tagger" " INFO" -ForegroundColor Cyan
Write-WELog " =====================" " INFO" -ForegroundColor Cyan

if ($WETags.Count -eq 0) {
    Write-WELog " No tags specified. Example usage:" " INFO" -ForegroundColor Yellow
    Write-WELog "  .\Azure-Resource-Tagger.ps1 -ResourceGroupName 'MyRG' -Tags @{Environment='Prod'; Owner='IT'}" " INFO" -ForegroundColor White
    return
}

Write-WELog " Target Resource Group: $WEResourceGroupName" " INFO" -ForegroundColor Green
Write-WELog " Tags to Apply:" " INFO" -ForegroundColor Green
foreach ($tag in $WETags.GetEnumerator()) {
    Write-WELog "  $($tag.Key): $($tag.Value)" " INFO" -ForegroundColor White
}

if ($WEWhatIf) {
    Write-WELog " `n[WHAT-IF MODE] - No changes will be made" " INFO" -ForegroundColor Yellow
}


$resources = if ($WEResourceType) {
    Get-AzResource -ResourceGroupName $WEResourceGroupName -ResourceType $WEResourceType
} else {
    Get-AzResource -ResourceGroupName $WEResourceGroupName
}

Write-WELog " `nFound $($resources.Count) resources to tag" " INFO" -ForegroundColor Green
; 
$taggedCount = 0
foreach ($resource in $resources) {
    try {
        if ($WEWhatIf) {
            Write-WELog "  [WHAT-IF] Would tag: $($resource.Name) ($($resource.ResourceType))" " INFO" -ForegroundColor Yellow
        } else {
            # Merge existing tags with new tags
           ;  $existingTags = $resource.Tags ?? @{}
            foreach ($tag in $WETags.GetEnumerator()) {
                $existingTags[$tag.Key] = $tag.Value
            }
            
            Set-AzResource -ResourceId $resource.ResourceId -Tag $existingTags -Force:$WEForce
            Write-WELog "  ✓ Tagged: $($resource.Name)" " INFO" -ForegroundColor Green
            $taggedCount++
        }
    } catch {
        Write-Warning " Failed to tag resource '$($resource.Name)': $($_.Exception.Message)"
    }
}

if (-not $WEWhatIf) {
    Write-WELog " `n✓ Successfully tagged $taggedCount resources" " INFO" -ForegroundColor Green
}

Write-WELog " `nResource tagging completed at $(Get-Date)" " INFO" -ForegroundColor Cyan


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================