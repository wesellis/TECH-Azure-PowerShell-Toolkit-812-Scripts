<#
.SYNOPSIS
    fix vwan script
.DESCRIPTION
    fix vwan script operation
    Author: Wes Ellis (wes@wesellis.com)
#>
#!/usr/bin/env pwsh

# Fix the Virtual WAN script that has multiple broken function definitions
param([switch]$WhatIf)

$scriptPath = "automation-scripts/Network-Security/Azure-Virtual-WAN-Management-Tool.ps1"
$content = Get-Content $scriptPath -Raw
$originalContent = $content
$issues = @()

# Fix malformed function definitions - remove the erroneous [CmdletBinding()] and -ErrorAction Stop syntax
$content = $content -replace '\[CmdletBinding\(\)\]\s*\nfunction ([^{]+) -ErrorAction Stop \{', 'function $1 {'
$content = $content -replace 'Write-EnhancedLog', 'Write-VWanLog'

# Fix all the logging calls to use consistent parameters
$content = $content -replace 'Write-VWanLog "([^"]+)" "([^"]+)"', 'Write-VWanLog "$1" ''$2'''

# Fix broken splatting in the script
$content = $content -replace '(\$\w+) = New-Az(\w+) -([^@\r\n]+)', '$1 = New-Az$2 @$1Params'

# Fix the main execution try block structure
$content = $content -replace 'try \{\s*Write-EnhancedLog', 'try {' + "`n" + '    Write-VWanLog'

if ($content -ne $originalContent) {
    Write-Host "Fixed Virtual WAN Management Tool script" -ForegroundColor Green
    if (-not $WhatIf) {
        $content | Set-Content $scriptPath -Encoding UTF8
    }
    Write-Host "Applied
}\n