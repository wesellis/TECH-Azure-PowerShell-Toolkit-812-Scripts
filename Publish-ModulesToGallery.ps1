#Requires -Version 7.0
<#
.SYNOPSIS
    Publishes Azure Enterprise Toolkit modules to PowerShell Gallery

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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

    [switch]$Force,

    [switch]$WhatIf
)
$ModulesPath = Join-Path $PSScriptRoot 'automation-scripts\modules'
$Modules = @(
    'accounts\Az.Accounts.Enterprise',
    'resources\Az.Resources.Enterprise',
    'storage\Az.Storage.Enterprise',
    'keyvault\Az.KeyVault.Enterprise',
    'monitoring\Az.Monitoring.Enterprise',
    'security\Az.Security.Enterprise'
)

Write-Output "Azure Enterprise Toolkit - PowerShell Gallery Publisher"
Write-Output "======================================================"
Write-Output ""

Write-Output "Verifying modules..."
$ModulesToPublish = @()

foreach ($module in $Modules) {
    $ModulePath = Join-Path $ModulesPath $module
    $ManifestPath = "$ModulePath.psd1"

    if (Test-Path $ManifestPath) {
        $manifest = Import-PowerShellDataFile $ManifestPath
        $ModuleInfo = @{
            Name = Split-Path $module -Leaf
            Path = $ModulePath
            Version = $manifest.ModuleVersion
            Description = $manifest.Description
        }
        $ModulesToPublish += $ModuleInfo
        Write-Output "  [OK] $($ModuleInfo.Name) v$($ModuleInfo.Version)"
    } else {
        Write-Warning "  [FAIL] Module not found: $module"
    }
}

if ($ModulesToPublish.Count -eq 0) {
    Write-Error "No modules found to publish!"
    return
}

Write-Output ""
Write-Output "Found $($ModulesToPublish.Count) modules to publish"
Write-Output ""

if (-not $Force -and -not $WhatIf) {
    $confirm = Read-Host "Do you want to publish these modules to $Repository? (Y/N)"
    if ($confirm -ne 'Y') {
        Write-Output "Publishing cancelled"
        return
    }
}

foreach ($module in $ModulesToPublish) {
    Write-Output "Publishing $($module.Name) v$($module.Version)..."

    if ($PSCmdlet.ShouldProcess($module.Name, "Publish to $Repository")) {
        try {
            Write-Verbose "Testing module: $($module.Name)"
            $TestResult = Test-ModuleManifest -Path "$($module.Path).psd1" -ErrorAction Stop
            $params = @{
                NuGetApiKey = $ApiKey
                Repository = $Repository
                Path = $module.Path
                ErrorAction = "Stop"
            }
            Publish-Module @params

            Write-Output "  [OK] Successfully published $($module.Name)"
            $ModuleUrl = "https://www.powershellgallery.com/packages/$($module.Name)"
            Write-Output "      View at: $ModuleUrl"

        } catch {
            Write-Error "  [FAIL] Failed to publish $($module.Name): $_"
        }
    } else {
        Write-Output "  [WhatIf] Would publish $($module.Name) to $Repository"
    }

    Write-Output ""
}

Write-Output "Publishing Summary"
Write-Output "=================="
Write-Output ""

if ($WhatIf) {
    Write-Output "WhatIf mode - no modules were actually published"
} else {
    Write-Output "Publishing complete!"
    Write-Output ""
    Write-Output "Next steps:"
    Write-Output "1. Verify modules at https://www.powershellgallery.com/profiles/WesEllis"
    Write-Output "2. Test installation: Install-Module -Name Az.Accounts.Enterprise"
    Write-Output "3. Share on social media and PowerShell communities"
    Write-Output "4. Monitor download statistics"
}
$PublishLog = @{
    PublishDate = Get-Date
    ModulesPublished = $ModulesToPublish
    Repository = $Repository
    Publisher = $env:USERNAME
}
$LogPath = Join-Path $PSScriptRoot "last-publish.json"
$PublishLog | ConvertTo-Json -Depth 3 | Out-File $LogPath -Force

Write-Output ""
Write-Output "Publish log saved to: $LogPath"



