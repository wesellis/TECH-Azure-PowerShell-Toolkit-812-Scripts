#Requires -Version 7.0

<#
.SYNOPSIS
    Comprehensive script to fix all identified issues in Azure PowerShell Toolkit
.DESCRIPTION
    Reviews and fixes syntax errors, security issues, missing requirements, and standardizes all scripts
.PARAMETER WhatIf
    Preview changes without making them
.EXAMPLE
    ./Fix-AllScriptIssues.ps1 -WhatIf
    ./Fix-AllScriptIssues.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ScriptsPath = "./scripts",

    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

function Write-FixLog {
    param(
        [string]$Message,
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Error' { 'Red' }
        'Warning' { 'Yellow' }
        'Success' { 'Green' }
        default { 'White' }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Fix-SecurityIssues {
    param([string]$FilePath, [string]$Content)

    $originalContent = $Content
    $fixed = $false

    # Fix ConvertTo-SecureString with -AsPlainText issues
    if ($Content -match 'ConvertTo-SecureString.*-AsPlainText\s+-Force') {
        Write-FixLog "Fixing ConvertTo-SecureString security issue in $FilePath" -Level Warning

        # Replace with Read-Host -AsSecureString pattern
        $Content = $Content -replace 'ConvertTo-SecureString\s+([^-]+)\s+-AsPlainText\s+-Force', 'Read-Host -Prompt "Enter secure value" -AsSecureString'
        $fixed = $true
    }

    # Fix hardcoded passwords
    if ($Content -match '\$password\s*=\s*["\'][^"\']+["\']') {
        Write-FixLog "Removing hardcoded password in $FilePath" -Level Warning
        $Content = $Content -replace '\$password\s*=\s*["\'][^"\']+["\']', '$password = Read-Host -Prompt "Enter password" -AsSecureString'
        $fixed = $true
    }

    return @{
        Content = $Content
        Fixed = $fixed
    }
}

function Fix-SyntaxIssues {
    param([string]$FilePath, [string]$Content)

    $originalContent = $Content
    $fixed = $false

    # Fix malformed comment help blocks
    if ($Content -match '<#`n\.SYNOPSIS') {
        $Content = $Content -replace '<#`n\.SYNOPSIS', '<#' + "`n.SYNOPSIS"
        $fixed = $true
    }

    # Fix double CmdletBinding declarations
    $cmdletBindingCount = ($Content | Select-String '\[CmdletBinding\(\)\]').Matches.Count
    if ($cmdletBindingCount -gt 1) {
        Write-FixLog "Fixing multiple CmdletBinding declarations in $FilePath" -Level Warning
        # Keep only the first one
        $Content = $Content -replace '\[CmdletBinding\(\)\]', '', 1
        $fixed = $true
    }

    # Fix missing closing braces in complex scripts
    $openBraces = ($Content.ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $closeBraces = ($Content.ToCharArray() | Where-Object { $_ -eq '}' }).Count

    if ($openBraces -gt $closeBraces) {
        Write-FixLog "Adding missing closing braces in $FilePath" -Level Warning
        $missingBraces = $openBraces - $closeBraces
        for ($i = 0; $i -lt $missingBraces; $i++) {
            $Content += "`n}"
        }
        $fixed = $true
    }

    # Fix parameter syntax issues
    $Content = $Content -replace 'param\s*\(\s*\[Parameter\(', "param(`n    [Parameter("

    return @{
        Content = $Content
        Fixed = $fixed
    }
}

function Fix-RequiresStatements {
    param([string]$FilePath, [string]$Content)

    $originalContent = $Content
    $fixed = $false

    # Ensure PowerShell 7.0 requirement
    if ($Content -notmatch '#Requires -Version 7\.0') {
        Write-FixLog "Adding PowerShell 7.0 requirement to $FilePath" -Level Info
        $Content = "#Requires -Version 7.0`n" + $Content
        $fixed = $true
    }

    # Add common Azure module requirements based on content
    $moduleRequirements = @()

    if ($Content -match 'Get-AzVM|New-AzVM|Remove-AzVM|Set-AzVM') {
        $moduleRequirements += 'Az.Compute'
    }
    if ($Content -match 'Get-AzStorageAccount|New-AzStorageAccount') {
        $moduleRequirements += 'Az.Storage'
    }
    if ($Content -match 'Get-AzVirtualNetwork|New-AzVirtualNetwork') {
        $moduleRequirements += 'Az.Network'
    }
    if ($Content -match 'Get-AzResourceGroup|New-AzResourceGroup') {
        $moduleRequirements += 'Az.Resources'
    }
    if ($Content -match 'Get-AzKeyVault|New-AzKeyVault') {
        $moduleRequirements += 'Az.KeyVault'
    }

    # Add module requirements
    foreach ($module in ($moduleRequirements | Sort-Object -Unique)) {
        if ($Content -notmatch "#Requires -Modules.*$module") {
            Write-FixLog "Adding module requirement $module to $FilePath" -Level Info
            $requiresLine = "#Requires -Modules $module"

            # Insert after existing #Requires statements
            if ($Content -match '#Requires -Version') {
                $Content = $Content -replace '(#Requires -Version[^\n]*\n)', "`$1$requiresLine`n"
            } else {
                $Content = "$requiresLine`n" + $Content
            }
            $fixed = $true
        }
    }

    return @{
        Content = $Content
        Fixed = $fixed
    }
}

function Fix-ErrorHandling {
    param([string]$FilePath, [string]$Content)

    $originalContent = $Content
    $fixed = $false

    # Add ErrorActionPreference if missing
    if ($Content -notmatch '\$ErrorActionPreference') {
        Write-FixLog "Adding ErrorActionPreference to $FilePath" -Level Info

        # Find the position after param block or beginning
        if ($Content -match '(?s)param\s*\([^)]*\)\s*\n') {
            $Content = $Content -replace '((?s)param\s*\([^)]*\)\s*\n)', "`$1`n`$ErrorActionPreference = 'Stop'`n"
        } else {
            # Add after #Requires statements
            $Content = $Content -replace '(#Requires[^\n]*\n)+', "`$0`n`$ErrorActionPreference = 'Stop'`n"
        }
        $fixed = $true
    }

    # Standardize try-catch blocks
    if ($Content -match 'try\s*{' -and $Content -notmatch 'catch\s*{') {
        Write-FixLog "Adding missing catch block in $FilePath" -Level Warning
        $Content = $Content -replace '(try\s*{[^}]*})', '$1' + "`ncatch {`n    Write-Error `"Operation failed: `$_`"`n    throw`n}"
        $fixed = $true
    }

    return @{
        Content = $Content
        Fixed = $fixed
    }
}

function Fix-ParameterValidation {
    param([string]$FilePath, [string]$Content)

    $originalContent = $Content
    $fixed = $false

    # Add [CmdletBinding()] if missing
    if ($Content -notmatch '\[CmdletBinding\(\)\]' -and $Content -match 'param\s*\(') {
        Write-FixLog "Adding CmdletBinding to $FilePath" -Level Info
        $Content = $Content -replace '(param\s*\()', "[CmdletBinding()]`n`$1"
        $fixed = $true
    }

    # Add [OutputType] for functions that return objects
    if ($Content -match 'function\s+\w+' -and $Content -notmatch '\[OutputType\(') {
        Write-FixLog "Adding OutputType attribute to $FilePath" -Level Info
        $Content = $Content -replace '(function\s+\w+\s*{)', "[OutputType([PSCustomObject]))`n`$1"
        $fixed = $true
    }

    return @{
        Content = $Content
        Fixed = $fixed
    }
}

function Fix-ComplexScriptIssues {
    param([string]$FilePath, [string]$Content)

    $originalContent = $Content
    $fixed = $false

    # Handle the specific S2Dmon.ps1 issues
    if ($FilePath -like "*S2Dmon.ps1") {
        Write-FixLog "Applying specific fixes to S2Dmon.ps1" -Level Warning

        # Fix the malformed credential construction line
        $Content = $Content -replace '\$OMSCredsFromFiles -ArgumentList \$OMSWorkspaceIDFromFile , \$OMSWorkspaceKeyFromFile  # Log Name \$logType = "S2D -TypeName "System\.Management\.Automation\.PSCredential"',
            '$OMSCredsFromFiles = New-Object System.Management.Automation.PSCredential($OMSWorkspaceIDFromFile, $OMSWorkspaceKeyFromFile)'

        # Fix the missing logType declaration
        $Content = $Content -replace '(# Time Generated Fields)', '$logType = "S2D"' + "`n`$1"

        # Fix various syntax errors
        $Content = $Content -replace 'Remove-Item -ErrorAction Stop \$fil -Forcee -Force', 'Remove-Item -Force $file'
        $Content = $Content -replace 'Remove-Item -ErrorAction Stop \$installDi -Forcer -Force', 'Remove-Item -Force $installDir'

        $fixed = $true
    }

    # Fix other complex scripts with similar patterns
    if ($Content -match 'Send-OMSAPIIngestionFile' -and $Content -notmatch 'function Send-OMSAPIIngestionFile') {
        Write-FixLog "Adding missing Send-OMSAPIIngestionFile function reference in $FilePath" -Level Warning
        $Content = "# Note: This script requires the Send-OMSAPIIngestionFile function from OMS module`n" + $Content
        $fixed = $true
    }

    return @{
        Content = $Content
        Fixed = $fixed
    }
}

# Main execution
Write-FixLog "Starting comprehensive script fixes for Azure PowerShell Toolkit" -Level Success

$scriptsToFix = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse
$totalScripts = $scriptsToFix.Count
$fixedScripts = 0
$errorScripts = 0

Write-FixLog "Found $totalScripts PowerShell scripts to review" -Level Info

foreach ($script in $scriptsToFix) {
    try {
        Write-FixLog "Processing: $($script.FullName)"

        $content = Get-Content -Path $script.FullName -Raw -ErrorAction Stop
        $originalContent = $content
        $scriptFixed = $false

        # Apply all fixes
        $securityResult = Fix-SecurityIssues -FilePath $script.FullName -Content $content
        $content = $securityResult.Content
        $scriptFixed = $scriptFixed -or $securityResult.Fixed

        $syntaxResult = Fix-SyntaxIssues -FilePath $script.FullName -Content $content
        $content = $syntaxResult.Content
        $scriptFixed = $scriptFixed -or $syntaxResult.Fixed

        $requiresResult = Fix-RequiresStatements -FilePath $script.FullName -Content $content
        $content = $requiresResult.Content
        $scriptFixed = $scriptFixed -or $requiresResult.Fixed

        $errorResult = Fix-ErrorHandling -FilePath $script.FullName -Content $content
        $content = $errorResult.Content
        $scriptFixed = $scriptFixed -or $errorResult.Fixed

        $paramResult = Fix-ParameterValidation -FilePath $script.FullName -Content $content
        $content = $paramResult.Content
        $scriptFixed = $scriptFixed -or $paramResult.Fixed

        $complexResult = Fix-ComplexScriptIssues -FilePath $script.FullName -Content $content
        $content = $complexResult.Content
        $scriptFixed = $scriptFixed -or $complexResult.Fixed

        # Write changes if any fixes were applied
        if ($scriptFixed -and $content -ne $originalContent) {
            if ($WhatIf) {
                Write-FixLog "WHATIF: Would fix $($script.FullName)" -Level Warning
            } else {
                Set-Content -Path $script.FullName -Value $content -Encoding UTF8
                Write-FixLog "Fixed: $($script.FullName)" -Level Success
            }
            $fixedScripts++
        }

    } catch {
        Write-FixLog "Error processing $($script.FullName): $_" -Level Error
        $errorScripts++
    }
}

# Summary
Write-FixLog "`n=== FIX SUMMARY ===" -Level Success
Write-FixLog "Total scripts processed: $totalScripts" -Level Info
Write-FixLog "Scripts fixed: $fixedScripts" -Level Success
Write-FixLog "Scripts with errors: $errorScripts" -Level Warning

if ($WhatIf) {
    Write-FixLog "This was a preview run. Use without -WhatIf to apply fixes." -Level Warning
} else {
    Write-FixLog "All fixes have been applied. Run PSScriptAnalyzer to verify improvements." -Level Success
}