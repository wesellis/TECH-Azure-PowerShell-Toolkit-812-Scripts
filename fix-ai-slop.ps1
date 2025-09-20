#Requires -Version 5.1
#Requires -Module Az.Accounts
<#
.SYNOPSIS
    fix ai slop
.DESCRIPTION
    fix ai slop operation
    Author: Wes Ellis (wes@wesellis.com)
#>

#!/usr/bin/env pwsh

# Fix AI slop in PowerShell scripts
param([switch]$WhatIf)

$files = Get-ChildItem -Path "automation-scripts" -Filter "*.ps1" -Recurse
$fixedCount = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content

    # Fix undefined function calls
    $content = $content -replace 'Show-Banner[^`r`n]*', 'Write-Host "Azure Script" -ForegroundColor Cyan'
    $content = $content -replace 'Write-ProgressStep[^`r`n]*', 'Write-Progress -Activity "Processing" -Status "Working"'
    $content = $content -replace 'Test-AzureConnection[^`r`n]*', 'Get-AzContext'
    $content = $content -replace 'Write-Log\s+"([^"]+)"\s+-Level\s+\w+', 'Write-Host "$1"'

    # Fix broken splatting
    $content = $content -replace '(\$\w+)\s+(@params)', '$1 = Invoke-Command @params'

    # Fix generic descriptions
    $content = $content -replace '* operations in Azure', 'Manages Azure resources and operations'

    if ($content -ne $originalContent) {
        Write-Host "Fixed: $($file.Name)" -ForegroundColor Green
        if (-not $WhatIf) {
            $content | Set-Content $file.FullName -Encoding UTF8
        }
        $fixedCount++
    }
}

Write-Host "Fixed $fixedCount files" -ForegroundColor Cyan\n