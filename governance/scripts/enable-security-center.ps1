#Requires -Module Az.Security
#Requires -Module Az.Resources
#Requires -Version 5.1
<#
.SYNOPSIS
    enable security center
.DESCRIPTION
    enable security center operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Enables and configures Azure Security Center (Microsoft Defender for Cloud)

    Automates the enablement and configuration of Azure Security Center
    (now Microsoft Defender for Cloud) with security policies, pricing tiers,
    and monitoring configurations.
.PARAMETER SubscriptionId
    Target subscription for Security Center enablement
.PARAMETER PricingTier
    Pricing tier: Free, Standard
.PARAMETER EnableAutoProvisioning
    Enable automatic provisioning of security agents
.PARAMETER EnableDefenderPlans
    Enable specific Defender plans (VMs, Storage, SQL, etc.)
.PARAMETER DefenderPlans
    Array of Defender plans to enable
.PARAMETER WorkspaceResourceId
    Log Analytics workspace for security data
.PARAMETER SecurityContactEmail
    Email for security notifications
.PARAMETER SecurityContactPhone
    Phone number for security notifications
.PARAMETER EnableNotifications
    Enable security alert notifications
.PARAMETER NotifyAdmins
    Send notifications to subscription admins

    .\enable-security-center.ps1 -PricingTier Standard -EnableAutoProvisioning

    Enables Security Center with Standard tier and auto-provisioning

    .\enable-security-center.ps1 -DefenderPlans @("VirtualMachines", "Storage") -SecurityContactEmail "security@example.com"

    Enables specific Defender plans with security contact#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [Parameter()]
    [ValidateSet('Free', 'Standard')]
    [string]$PricingTier = 'Standard',

    [Parameter()]
    [switch]$EnableAutoProvisioning,

    [Parameter()]
    [switch]$EnableDefenderPlans,

    [Parameter()]
    [ValidateSet('VirtualMachines', 'AppServices', 'SqlServers', 'SqlServerVirtualMachines',
                 'StorageAccounts', 'KubernetesService', 'ContainerRegistry', 'KeyVaults')]
    [string[]]$DefenderPlans = @('VirtualMachines', 'StorageAccounts', 'SqlServers'),

    [Parameter()]
    [string]$WorkspaceResourceId,

    [Parameter()]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$SecurityContactEmail,

    [Parameter()]
    [ValidatePattern('^\+?[1-9]\d{1,14}$')]
    [string]$SecurityContactPhone,

    [Parameter()]
    [switch]$EnableNotifications,

    [Parameter()]
    [switch]$NotifyAdmins
)

$ErrorActionPreference = 'Stop'

function Test-AzureConnection {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    return Get-AzContext
}

function Set-SecurityPricing {
    param(
        [string]$Tier,
        [string[]]$ResourceTypes
    )

    Write-Host "Configuring Security Center pricing..." -ForegroundColor Yellow

    foreach ($resourceType in $ResourceTypes) {
        try {
            if ($PSCmdlet.ShouldProcess($resourceType, "Set pricing tier to $Tier")) {
                $params = @{
                    Name = $resourceType
                    PricingTier = $Tier
                }
                Set-AzSecurityPricing @params
                Write-Host "  $resourceType: $Tier tier enabled" -ForegroundColor Green
            
} catch {
            Write-Warning "Failed to set pricing for $resourceType : $_"
        }
    }
}

function Enable-AutoProvisioning {
    param([string]$WorkspaceId)

    Write-Host "Enabling auto-provisioning..." -ForegroundColor Yellow

    try {
        if ($PSCmdlet.ShouldProcess("Auto-provisioning", "Enable")) {
            # Enable auto-provisioning for Log Analytics agent
            $params = @{
                Name = 'default'
                EnableAutoProvision = $true
            }

            if ($WorkspaceId) {
                $params['WorkspaceId'] = $WorkspaceId
            }

            Set-AzSecurityAutoProvisioningSetting @params
            Write-Host "Auto-provisioning enabled successfully" -ForegroundColor Green
        
} catch {
        Write-Warning "Failed to enable auto-provisioning: $_"
    }
}

function Set-SecurityContact {
    param(
        [string]$Email,
        [string]$Phone,
        [bool]$EnableNotifications,
        [bool]$NotifyAdmins
    )

    if (-not $Email) {
        Write-Host "No security contact email provided, skipping contact configuration" -ForegroundColor Yellow
        return
    }

    Write-Host "Configuring security contact..." -ForegroundColor Yellow

    try {
        if ($PSCmdlet.ShouldProcess("Security contact", "Configure")) {
            $params = @{
                Name = 'default1'
                Email = $Email
                AlertNotifications = if ($EnableNotifications) { 'On' } else { 'Off' }
                AlertsToAdmins = if ($NotifyAdmins) { 'On' } else { 'Off' }
            }

            if ($Phone) {
                $params['Phone'] = $Phone
            }

            Set-AzSecurityContact @params
            Write-Host "Security contact configured successfully" -ForegroundColor Green
        
} catch {
        Write-Warning "Failed to configure security contact: $_"
    }
}

function Enable-DefenderForCloud {
    param([string[]]$Plans)

    Write-Host "Enabling Microsoft Defender plans..." -ForegroundColor Yellow

    $planMapping = @{
        'VirtualMachines' = 'VirtualMachines'
        'AppServices' = 'AppServices'
        'SqlServers' = 'SqlServers'
        'SqlServerVirtualMachines' = 'SqlServerVirtualMachines'
        'StorageAccounts' = 'StorageAccounts'
        'KubernetesService' = 'KubernetesService'
        'ContainerRegistry' = 'ContainerRegistry'
        'KeyVaults' = 'KeyVaults'
    }

    foreach ($plan in $Plans) {
        if ($planMapping.ContainsKey($plan)) {
            try {
                if ($PSCmdlet.ShouldProcess($plan, "Enable Defender plan")) {
                    $params = @{
                        Name = $planMapping[$plan]
                        PricingTier = 'Standard'
                    }
                    Set-AzSecurityPricing @params
                    Write-Host "Microsoft Defender for $plan: Enabled" -ForegroundColor Green
                
} catch {
                Write-Warning "Failed to enable Defender for $plan : $_"
            }
        }
        else {
            Write-Warning "Unknown Defender plan: $plan"
        }
    }
}

function Get-SecurityCenterStatus {
    Write-Host "Retrieving Security Center status..." -ForegroundColor Yellow

    try {
        # Get pricing information
        $pricing = Get-AzSecurityPricing

        # Get auto-provisioning settings
        $autoProvisioning = Get-AzSecurityAutoProvisioningSetting

        # Get security contacts
        $contacts = Get-AzSecurityContact

        $status = @{
            PricingTiers = $pricing
            AutoProvisioning = $autoProvisioning
            SecurityContacts = $contacts
            EnabledPlans = ($pricing | Where-Object { $_.PricingTier -eq 'Standard' }).Name
        }

        return $status
    }
    catch {
        Write-Warning "Failed to retrieve Security Center status: $_"
        return $null
    }
}

function Show-SecurityCenterSummary {
    param([object]$Status)

    if (-not $Status) {
        Write-Host "Unable to retrieve Security Center status" -ForegroundColor Red
        return
    }

    Write-Host "`nSecurity Center Configuration Summary" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan

    Write-Host "`nEnabled Defender Plans:" -ForegroundColor Cyan
    if ($Status.EnabledPlans.Count -gt 0) {
        $Status.EnabledPlans | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Green
        }
    } else {
        Write-Host "No Defender plans enabled (Free tier)" -ForegroundColor Yellow
    }

    Write-Host "`nAuto-Provisioning:" -ForegroundColor Cyan
    $autoProvStatus = $Status.AutoProvisioning | Where-Object { $_.Name -eq 'default' }
    if ($autoProvStatus -and $autoProvStatus.AutoProvision -eq 'On') {
        Write-Host "Enabled" -ForegroundColor Green
    } else {
        Write-Host "Disabled" -ForegroundColor Yellow
    }

    Write-Host "`nSecurity Contacts:" -ForegroundColor Cyan
    if ($Status.SecurityContacts.Count -gt 0) {
        $Status.SecurityContacts | ForEach-Object {
            Write-Host "Email: $($_.Email)"
            Write-Host "Notifications: $($_.AlertNotifications)"
            Write-Host "Admin Alerts: $($_.AlertsToAdmins)"
        }
    } else {
        Write-Host "No security contacts configured" -ForegroundColor Yellow
    }
}

function Get-SecurityRecommendations {
    Write-Host "Retrieving security recommendations..." -ForegroundColor Yellow

    try {
        $tasks = Get-AzSecurityTask | Select-Object -First 10

        if ($tasks.Count -gt 0) {
            Write-Host "`nTop Security Recommendations:" -ForegroundColor Cyan
            $tasks | ForEach-Object {
                $severity = switch ($_.RecommendationSeverity) {
                    'High' { 'Red' }
                    'Medium' { 'Yellow' }
                    'Low' { 'Green' }
                    default { 'White' }
                }
                Write-Host "  - $($_.RecommendationDisplayName)" -ForegroundColor $severity
            }
        } else {
            Write-Host "No security recommendations available" -ForegroundColor Green
        }

        return $tasks
    }
    catch {
        Write-Warning "Failed to retrieve security recommendations: $_"
        return @()
    }
}

# Main execution
Write-Host "`nAzure Security Center Configuration" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

# Set subscription context if provided
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
}

# Configure pricing tiers
if ($EnableDefenderPlans) {
    Enable-DefenderForCloud -Plans $DefenderPlans
} else {
    $standardPlans = @('VirtualMachines', 'StorageAccounts')
    Set-SecurityPricing -Tier $PricingTier -ResourceTypes $standardPlans
}

# Enable auto-provisioning if requested
if ($EnableAutoProvisioning) {
    Enable-AutoProvisioning -WorkspaceId $WorkspaceResourceId
}

# Configure security contact
if ($SecurityContactEmail) {
    Set-SecurityContact -Email $SecurityContactEmail -Phone $SecurityContactPhone -EnableNotifications $EnableNotifications -NotifyAdmins $NotifyAdmins
}

# Get current status and show summary
$status = Get-SecurityCenterStatus
Show-SecurityCenterSummary -Status $status

# Get security recommendations
$recommendations = Get-SecurityRecommendations

Write-Host "`nSecurity Center configuration completed!" -ForegroundColor Green

# Return status object
return @{
    Status = $status
    Recommendations = $recommendations
}\n