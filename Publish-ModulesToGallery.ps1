<#
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
[CmdletBinding()]

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

Write-Host "Azure Enterprise Toolkit - PowerShell Gallery Publisher"
Write-Host "======================================================"
Write-Host ""

# Verify modules exist
Write-Host "Verifying modules..."
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
        Write-Host "  [OK] $($moduleInfo.Name) v$($moduleInfo.Version)"
    } else {
        Write-Warning "  [FAIL] Module not found: $module"
    }
}

if ($modulesToPublish.Count -eq 0) {
    Write-Error "No modules found to publish!"
    return
}

Write-Host ""
Write-Host "Found $($modulesToPublish.Count) modules to publish"
Write-Host ""

# Confirm before publishing
if (-not $Force -and -not $WhatIf) {
    $confirm = Read-Host "Do you want to publish these modules to $Repository? (Y/N)"
    if ($confirm -ne 'Y') {
        Write-Host "Publishing cancelled"
        return
    }
}

# Publish each module
foreach ($module in $modulesToPublish) {
    Write-Host "Publishing $($module.Name) v$($module.Version)..."
    
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
                ErrorAction = "Stop"
            }
            Publish-Module @params

            Write-Host "  [OK] Successfully published $($module.Name)"

            # Display module URL
            $moduleUrl = "https://www.powershellgallery.com/packages/$($module.Name)"
            Write-Host "      View at: $moduleUrl"

        } catch {
            Write-Error "  [FAIL] Failed to publish $($module.Name): $_"
        }
    } else {
        Write-Host "  [WhatIf] Would publish $($module.Name) to $Repository"
    }

    Write-Host ""
}

# Summary
Write-Host "Publishing Summary"
Write-Host "=================="
Write-Host ""

if ($WhatIf) {
    Write-Host "WhatIf mode - no modules were actually published"
} else {
    Write-Host "Publishing complete!"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Verify modules at https://www.powershellgallery.com/profiles/WesEllis"
    Write-Host "2. Test installation: Install-Module -Name Az.Accounts.Enterprise"
    Write-Host "3. Share on social media and PowerShell communities"
    Write-Host "4. Monitor download statistics"
}

# Create a simple tracking file
$publishLog = @{
    PublishDate = Get-Date
    ModulesPublished = $modulesToPublish
    Repository = $Repository
    Publisher = $env:USERNAME
}

$logPath = Join-Path $PSScriptRoot "last-publish.json"
$publishLog | ConvertTo-Json -Depth 3 | Out-File $logPath -Force

Write-Host ""
Write-Host "Publish log saved to: $logPath"

#endregion\n

