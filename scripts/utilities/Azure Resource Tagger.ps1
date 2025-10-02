#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Resource Tagger

.DESCRIPTION
    Azure automation for tagging resources in bulk

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [hashtable]$Tags,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceType,

    [Parameter()]
    [switch]$WhatIf,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

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
    $LogEntry = "$timestamp [Resource-Tagger] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Azure Resource Tagger" "INFO"
    Write-Log "=====================" "INFO"

    if ($Tags.Count -eq 0) {
        Write-Log "No tags specified. Example usage:" "WARN"
        Write-Log "  .\Azure-Resource-Tagger.ps1 -ResourceGroupName 'MyRG' -Tags @{Environment='Prod'; Owner='IT'}" "INFO"
        return
    }

    Write-Log "Target Resource Group: $ResourceGroupName" "INFO"
    Write-Log "Tags to Apply:" "INFO"
    foreach ($tag in $Tags.GetEnumerator()) {
        Write-Log "  $($tag.Key): $($tag.Value)" "INFO"
    }

    if ($WhatIf) {
        Write-Log "`n[WHAT-IF MODE] - No changes will be made" "WARN"
    }

    # Get resources
    $resources = if ($ResourceType) {
        Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType
    } else {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    }

    Write-Log "`nFound $($resources.Count) resources to tag" "INFO"

    $TaggedCount = 0
    foreach ($resource in $resources) {
        try {
            if ($WhatIf) {
                Write-Log "  [WHAT-IF] Would tag: $($resource.Name) ($($resource.ResourceType))" "INFO"
            } else {
                $ExistingTags = $resource.Tags ?? @{}
                foreach ($tag in $Tags.GetEnumerator()) {
                    $ExistingTags[$tag.Key] = $tag.Value
                }
                Set-AzResource -ResourceId $resource.ResourceId -Tag $ExistingTags -Force:$Force
                Write-Log "  [OK] Tagged: $($resource.Name)" "SUCCESS"
                $TaggedCount++
            }
        } catch {
            Write-Log "  [ERROR] Failed to tag $($resource.Name): $_" "ERROR"
        }
    }

    if (-not $WhatIf) {
        Write-Log "`nSuccessfully tagged $TaggedCount of $($resources.Count) resources" "SUCCESS"
    }

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}