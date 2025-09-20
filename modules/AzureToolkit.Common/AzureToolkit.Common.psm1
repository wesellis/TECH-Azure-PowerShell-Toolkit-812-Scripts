#Requires -Version 7.0

<#
.SYNOPSIS
    Common functions for Azure PowerShell Toolkit
.DESCRIPTION
    Shared functionality including configuration management, logging, and utilities
#>

# Global variables
$script:ToolkitConfig = $null
$script:LogPath = $null

function Get-ToolkitConfig {
    <#
    .SYNOPSIS
        Load toolkit configuration for specified environment
    .PARAMETER Environment
        Environment name (development, staging, production)
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('development', 'staging', 'production')]
        [string]$Environment
    )

    if ($script:ToolkitConfig -and $script:ToolkitConfig.Environment -eq $Environment) {
        return $script:ToolkitConfig
    }

    $configPath = Join-Path $PSScriptRoot "../../config/environments.json"

    if (-not (Test-Path $configPath)) {
        throw "Configuration file not found: $configPath"
    }

    try {
        $allConfigs = Get-Content $configPath | ConvertFrom-Json
        $config = $allConfigs.$Environment

        if (-not $config) {
            throw "Environment '$Environment' not found in configuration"
        }

        # Add environment name to config
        $config | Add-Member -NotePropertyName "Environment" -NotePropertyValue $Environment

        $script:ToolkitConfig = $config
        return $config
    }
    catch {
        throw "Failed to load configuration: $_"
    }
}

function Initialize-ToolkitLogging {
    <#
    .SYNOPSIS
        Initialize centralized logging for toolkit operations
    .PARAMETER LogPath
        Path for log files
    .PARAMETER Environment
        Environment name for log context
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$LogPath = (Join-Path $env:TEMP "azure-toolkit-logs"),

        [Parameter()]
        [string]$Environment = "unknown"
    )

    # Create log directory
    if (-not (Test-Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
    }

    $script:LogPath = $LogPath
    $logFile = Join-Path $LogPath "toolkit-$(Get-Date -Format 'yyyyMMdd').log"

    # Start transcript if not already running
    try {
        Stop-Transcript -ErrorAction SilentlyContinue
    } catch { }

    Start-Transcript -Path $logFile -Append

    Write-ToolkitLog "Logging initialized for environment: $Environment" -Level Info
}

function Write-ToolkitLog {
    <#
    .SYNOPSIS
        Write structured log entries
    .PARAMETER Message
        Log message
    .PARAMETER Level
        Log level (Info, Warning, Error, Debug)
    .PARAMETER Source
        Source script or function
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',

        [Parameter()]
        [string]$Source = (Get-PSCallStack)[1].Command
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$Source] $Message"

    switch ($Level) {
        'Info' { Write-Host $logEntry -ForegroundColor Green }
        'Warning' { Write-Warning $logEntry }
        'Error' { Write-Error $logEntry }
        'Debug' { Write-Verbose $logEntry }
    }

    # Also write to log file if logging is initialized
    if ($script:LogPath) {
        $logFile = Join-Path $script:LogPath "toolkit-$(Get-Date -Format 'yyyyMMdd').log"
        Add-Content -Path $logFile -Value $logEntry
    }
}

function Test-AzureConnection {
    <#
    .SYNOPSIS
        Test Azure PowerShell connection and context
    .PARAMETER SubscriptionId
        Expected subscription ID
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [string]$SubscriptionId
    )

    try {
        $context = Get-AzContext

        if (-not $context) {
            Write-ToolkitLog "No Azure context found. Please run Connect-AzAccount" -Level Error
            return $false
        }

        if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
            Write-ToolkitLog "Current subscription ($($context.Subscription.Id)) doesn't match expected ($SubscriptionId)" -Level Warning
        }

        Write-ToolkitLog "Azure connection validated. Subscription: $($context.Subscription.Name)" -Level Info
        return $true
    }
    catch {
        Write-ToolkitLog "Failed to validate Azure connection: $_" -Level Error
        return $false
    }
}

function Invoke-ToolkitCommand {
    <#
    .SYNOPSIS
        Execute toolkit commands with error handling and logging
    .PARAMETER ScriptBlock
        Command to execute
    .PARAMETER Description
        Description of the operation
    .PARAMETER WhatIf
        Preview mode
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter()]
        [switch]$WhatIf
    )

    Write-ToolkitLog "Starting: $Description" -Level Info

    if ($WhatIf -or $PSCmdlet.ShouldProcess($Description)) {
        if ($WhatIf) {
            Write-ToolkitLog "WHATIF: Would execute - $Description" -Level Info
            return
        }

        try {
            $result = & $ScriptBlock
            Write-ToolkitLog "Completed: $Description" -Level Info
            return $result
        }
        catch {
            Write-ToolkitLog "Failed: $Description - $_" -Level Error
            throw
        }
    }
}

function Get-ResourceTags {
    <#
    .SYNOPSIS
        Get standard resource tags for environment
    .PARAMETER Environment
        Environment name
    .PARAMETER AdditionalTags
        Additional tags to merge
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Environment,

        [Parameter()]
        [hashtable]$AdditionalTags = @{}
    )

    $config = Get-ToolkitConfig -Environment $Environment
    $tags = @{}

    # Copy environment tags
    foreach ($key in $config.tags.PSObject.Properties.Name) {
        $tags[$key] = $config.tags.$key
    }

    # Add standard tags
    $tags['CreatedBy'] = 'Azure-PowerShell-Toolkit'
    $tags['CreatedDate'] = (Get-Date).ToString('yyyy-MM-dd')

    # Merge additional tags
    foreach ($key in $AdditionalTags.Keys) {
        $tags[$key] = $AdditionalTags[$key]
    }

    return $tags
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-ToolkitConfig',
    'Initialize-ToolkitLogging',
    'Write-ToolkitLog',
    'Test-AzureConnection',
    'Invoke-ToolkitCommand',
    'Get-ResourceTags'
)