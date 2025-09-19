#Requires -Module PowerShellGet
<#
#endregion

#region Main-Execution
.SYNOPSIS
    Publishes Azure Enterprise Toolkit modules to PowerShell Gallery
    
.DESCRIPTION
    This script publishes all enterprise modules to the PowerShell Gallery
    Run this after obtaining your API key from https://www.powershellgallery.com/
    
.PARAMETER ApiKey
    Your PowerShell Gallery API key
    
.PARAMETER WhatIf
    Shows what would be published without actually publishing
    
.EXAMPLE
    .\Publish-ModulesToGallery.ps1 -ApiKey "your-api-key-here"
    
.EXAMPLE
    .\Publish-ModulesToGallery.ps1 -ApiKey $env:PSGALLERY_API_KEY -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ApiKey,
    
    [string]$Repository = 'PSGallery',
    
    [switch]$Force
)

#region Functions

# Module directory
$ModulesPath = Join-Path $PSScriptRoot 'automation-scripts\modules'

# Modules to publish
$Modules = @(
    'accounts\Az.Accounts.Enterprise',
    'resources\Az.Resources.Enterprise',
    'storage\Az.Storage.Enterprise',
    'keyvault\Az.KeyVault.Enterprise',
    'monitoring\Az.Monitoring.Enterprise',
    'security\Az.Security.Enterprise'
)

Write-Information "Azure Enterprise Toolkit - PowerShell Gallery Publisher"
Write-Information "======================================================"
Write-Information ""

# Verify modules exist
Write-Information "Verifying modules..."
$modulesToPublish = @()

foreach ($module in $Modules) {
    $modulePath = Join-Path $ModulesPath $module
    $manifestPath = "$modulePath.psd1"
    
    if (Test-Path $manifestPath) {
        $manifest = Import-PowerShellDataFile $manifestPath
        $moduleInfo = @{
            Name = Split-Path $module -Leaf
            Path = $modulePath
            Version = $manifest.ModuleVersion
            Description = $manifest.Description
        }
        $modulesToPublish += $moduleInfo
        Write-Information "  [OK] $($moduleInfo.Name) v$($moduleInfo.Version)"
    } else {
        Write-Warning "  [FAIL] Module not found: $module"
    }
}

if ($modulesToPublish.Count -eq 0) {
    Write-Error "No modules found to publish!"
    return
}

Write-Information ""
Write-Information "Found $($modulesToPublish.Count) modules to publish"
Write-Information ""

# Confirm before publishing
if (-not $Force -and -not $WhatIf) {
    $confirm = Read-Host "Do you want to publish these modules to $Repository? (Y/N)"
    if ($confirm -ne 'Y') {
        Write-Information "Publishing cancelled"
        return
    }
}

# Publish each module
foreach ($module in $modulesToPublish) {
    Write-Information "Publishing $($module.Name) v$($module.Version)..."
    
    if ($PSCmdlet.ShouldProcess($module.Name, "Publish to $Repository")) {
        try {
            # Test the module first
            Write-Verbose "Testing module: $($module.Name)"
            $testResult = Test-ModuleManifest -Path "$($module.Path).psd1" -ErrorAction Stop
            
            # Publish to gallery
            $params = @{
                NuGetApiKey = $ApiKey
                Repository = $Repository
                Path = $module.Path
                ErrorAction = "Stop  Write-Information "  [OK] Successfully published $($module.Name)"  # Display module URL $moduleUrl = "https://www.powershellgallery.com/packages/$($module.Name)" Write-Information "   View at: $moduleUrl"  } catch { Write-Error "  [FAIL] Failed to publish $($module.Name): $_" } } else { Write-Information "  [WhatIf] Would publish $($module.Name) to $Repository" }  Write-Information "
            }
            Publish-Module @params
}

# Summary
Write-Information "Publishing Summary"
Write-Information "=================="
Write-Information ""

if ($WhatIf) {
    Write-Information "WhatIf mode - no modules were actually published"
} else {
    Write-Information "Publishing complete!"
    Write-Information ""
    Write-Information "Next steps:"
    Write-Information "1. Verify modules at https://www.powershellgallery.com/profiles/WesEllis"
    Write-Information "2. Test installation: Install-Module -Name Az.Accounts.Enterprise"
    Write-Information "3. Share on social media and PowerShell communities"
    Write-Information "4. Monitor download statistics"
}

# Create a simple tracking file
$publishLog = @{
    PublishDate = Get-Date -ErrorAction Stop
    ModulesPublished = $modulesToPublish
    Repository = $Repository
    Publisher = $env:USERNAME
}

$logPath = Join-Path $PSScriptRoot "last-publish.json"
$publishLog | ConvertTo-Json -Depth 3 | Out-File $logPath -Force

Write-Information ""
Write-Information "Publish log saved to: $logPath"

#endregion
