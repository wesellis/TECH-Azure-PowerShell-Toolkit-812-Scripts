#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    enable security center
.DESCRIPTION
    enable security center operation
    Author: Wes Ellis (wes@wesellis.com)

    Enables and configures Azure Security Center (Microsoft Defender for Cloud)

    Automates the enablement and configuration of Azure Security Center
    (now Microsoft Defender for Cloud) with security policies, pricing tiers,
    and monitoring configurations.
.parameter SubscriptionId
    Target subscription for Security Center enablement
.parameter PricingTier
    Pricing tier: Free, Standard
.parameter EnableAutoProvisioning
    Enable automatic provisioning of security agents
.parameter EnableDefenderPlans
    Enable specific Defender plans (VMs, Storage, SQL, etc.)
.parameter DefenderPlans
    Array of Defender plans to enable
.parameter WorkspaceResourceId
    Log Analytics workspace for security data
.parameter SecurityContactEmail
    Email for security notifications
.parameter SecurityContactPhone
    Phone number for security notifications
.parameter EnableNotifications
    Enable security alert notifications
.parameter NotifyAdmins
    Send notifications to subscription admins

    .\enable-security-center.ps1 -PricingTier Standard -EnableAutoProvisioning

    Enables Security Center with Standard tier and auto-provisioning

    .\enable-security-center.ps1 -DefenderPlans @("VirtualMachines", "Storage") -SecurityContactEmail "security@example.com"

    Enables specific Defender plans with security contact

[parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [parameter()]
    [ValidateSet('Free', 'Standard')]
    [string]$PricingTier = 'Standard',

    [parameter()]
    [switch]$EnableAutoProvisioning,

    [parameter()]
    [switch]$EnableDefenderPlans,

    [parameter()]
    [ValidateSet('VirtualMachines', 'AppServices', 'SqlServers', 'SqlServerVirtualMachines',
                 'StorageAccounts', 'KubernetesService', 'ContainerRegistry', 'KeyVaults')]
    [string[]]$DefenderPlans = @('VirtualMachines', 'StorageAccounts', 'SqlServers'),

    [parameter()]
    [string]$WorkspaceResourceId,

    [parameter()]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$SecurityContactEmail,

    [parameter()]
    [ValidatePattern('^\+?[1-9]\d{1,14}$')]
    [string]$SecurityContactPhone,

    [parameter()]
    [switch]$EnableNotifications,

    [parameter()]
    [switch]$NotifyAdmins
)

$ErrorActionPreference = 'Stop'

[OutputType([PSCustomObject])] 
 {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    return Get-AzContext
}

function Set-SecurityPricing {
    [string]$Tier,
        [string[]]$ResourceTypes
    )

    Write-Host "Configuring Security Center pricing..." -ForegroundColor Green

    foreach ($ResourceType in $ResourceTypes) {
        try {
            if ($PSCmdlet.ShouldProcess($ResourceType, "Set pricing tier to $Tier")) {
                $params = @{
                    Name = $ResourceType
                    PricingTier = $Tier
                }
                Set-AzSecurityPricing @params
                Write-Host "  $ResourceType: $Tier tier enabled" -ForegroundColor Green

} catch {
            write-Warning "Failed to set pricing for $ResourceType : $_"
        }
    }
}

function Enable-AutoProvisioning {
    [string]$WorkspaceId)

    Write-Host "Enabling auto-provisioning..." -ForegroundColor Green

    try {
        if ($PSCmdlet.ShouldProcess("Auto-provisioning", "Enable")) {
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
        write-Warning "Failed to enable auto-provisioning: $_"
    }
}

function Set-SecurityContact {
    [string]$Email,
        [string]$Phone,
        [bool]$EnableNotifications,
        [bool]$NotifyAdmins
    )

    if (-not $Email) {
        Write-Host "No security contact email provided, skipping contact configuration" -ForegroundColor Green
        return
    }

    Write-Host "Configuring security contact..." -ForegroundColor Green

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
        write-Warning "Failed to configure security contact: $_"
    }
}

function Enable-DefenderForCloud {
    [string[]]$Plans)

    Write-Host "Enabling Microsoft Defender plans..." -ForegroundColor Green

    $PlanMapping = @{
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
        if ($PlanMapping.ContainsKey($plan)) {
            try {
                if ($PSCmdlet.ShouldProcess($plan, "Enable Defender plan")) {
                    $params = @{
                        Name = $PlanMapping[$plan]
                        PricingTier = 'Standard'
                    }
                    Set-AzSecurityPricing @params
                    Write-Host "Microsoft Defender for $plan: Enabled" -ForegroundColor Green

} catch {
                write-Warning "Failed to enable Defender for $plan : $_"
            }
        }
        else {
            write-Warning "Unknown Defender plan: $plan"
        }
    }
}

function Get-SecurityCenterStatus {
    Write-Host "Retrieving Security Center status..." -ForegroundColor Green

    try {
        $pricing = Get-AzSecurityPricing

        $AutoProvisioning = Get-AzSecurityAutoProvisioningSetting

        $contacts = Get-AzSecurityContact

        $status = @{
            PricingTiers = $pricing
            AutoProvisioning = $AutoProvisioning
            SecurityContacts = $contacts
            EnabledPlans = ($pricing | Where-Object { $_.PricingTier -eq 'Standard' }).Name
        }

        return $status
    }
    catch {
        write-Warning "Failed to retrieve Security Center status: $_"
        return $null
    }
}

function Show-SecurityCenterSummary {
    [object]$Status)

    if (-not $Status) {
        Write-Host "Unable to retrieve Security Center status" -ForegroundColor Green
        return
    }

    Write-Host "`nSecurity Center Configuration Summary" -ForegroundColor Green
    write-Host ("=" * 50) -ForegroundColor Cyan

    Write-Host "`nEnabled Defender Plans:" -ForegroundColor Green
    if ($Status.EnabledPlans.Count -gt 0) {
        $Status.EnabledPlans | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Green
        }
    } else {
        Write-Host "No Defender plans enabled (Free tier)" -ForegroundColor Green
    }

    Write-Host "`nAuto-Provisioning:" -ForegroundColor Green
    $AutoProvStatus = $Status.AutoProvisioning | Where-Object { $_.Name -eq 'default' }
    if ($AutoProvStatus -and $AutoProvStatus.AutoProvision -eq 'On') {
        Write-Host "Enabled" -ForegroundColor Green
    } else {
        Write-Host "Disabled" -ForegroundColor Green
    }

    Write-Host "`nSecurity Contacts:" -ForegroundColor Green
    if ($Status.SecurityContacts.Count -gt 0) {
        $Status.SecurityContacts | ForEach-Object {
            Write-Output "Email: $($_.Email)"
            Write-Output "Notifications: $($_.AlertNotifications)"
            Write-Output "Admin Alerts: $($_.AlertsToAdmins)"
        }
    } else {
        Write-Host "No security contacts configured" -ForegroundColor Green
    }
}

function Get-SecurityRecommendations {
    Write-Host "Retrieving security recommendations..." -ForegroundColor Green

    try {
        $tasks = Get-AzSecurityTask | Select-Object -First 10

        if ($tasks.Count -gt 0) {
            Write-Host "`nTop Security Recommendations:" -ForegroundColor Green
            $tasks | ForEach-Object {
                $severity = switch ($_.RecommendationSeverity) {
                    'High' { 'Red' }
                    'Medium' { 'Yellow' }
                    'Low' { 'Green' }
                    default { 'White' }
                }
                Write-Output "  - $($_.RecommendationDisplayName)" -ForegroundColor $severity
            }
        } else {
            Write-Host "No security recommendations available" -ForegroundColor Green
        }

        return $tasks
    }
    catch {
        write-Warning "Failed to retrieve security recommendations: $_"
        return @()
    }
}

Write-Host "`nAzure Security Center Configuration" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
}

if ($EnableDefenderPlans) {
    Enable-DefenderForCloud -Plans $DefenderPlans
} else {
    $StandardPlans = @('VirtualMachines', 'StorageAccounts')
    Set-SecurityPricing -Tier $PricingTier -ResourceTypes $StandardPlans
}

if ($EnableAutoProvisioning) {
    Enable-AutoProvisioning -WorkspaceId $WorkspaceResourceId
}

if ($SecurityContactEmail) {
    Set-SecurityContact -Email $SecurityContactEmail -Phone $SecurityContactPhone -EnableNotifications $EnableNotifications -NotifyAdmins $NotifyAdmins
}

$status = Get-SecurityCenterStatus
Show-SecurityCenterSummary -Status $status

$recommendations = Get-SecurityRecommendations

Write-Host "`nSecurity Center configuration completed!" -ForegroundColor Green

return @{
    Status = $status
    Recommendations = $recommendations
}\n



