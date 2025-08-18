<#
.SYNOPSIS
    Azure Servicebus Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Servicebus Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WENamespaceName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [string]$WESkuName = " Standard" ,
    [int]$WECapacity = 1,
    [bool]$WEZoneRedundant = $false,
    [hashtable]$WETags = @{}
)

Write-WELog " Provisioning Service Bus Namespace: $WENamespaceName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " SKU: $WESkuName" " INFO"
Write-WELog " Capacity: $WECapacity" " INFO"
Write-WELog " Zone Redundant: $WEZoneRedundant" " INFO"


$WEValidSkus = @(" Basic" , " Standard" , " Premium" )
if ($WESkuName -notin $WEValidSkus) {
    throw " Invalid SKU. Valid options are: $($WEValidSkus -join ', ')"
}

if ($WESkuName -eq " Premium" -and $WECapacity -notin @(1, 2, 4, 8, 16)) {
    throw " For Premium SKU, capacity must be 1, 2, 4, 8, or 16"
}


$WEServiceBusParams = @{
    ResourceGroupName = $WEResourceGroupName
    Name = $WENamespaceName
    Location = $WELocation
    SkuName = $WESkuName
}

if ($WESkuName -eq " Premium" ) {
    $WEServiceBusParams.SkuCapacity = $WECapacity
    if ($WEZoneRedundant) {
        $WEServiceBusParams.ZoneRedundant = $true
    }
}

$WEServiceBusNamespace = New-AzServiceBusNamespace @ServiceBusParams


if ($WETags.Count -gt 0) {
    Write-WELog " `nApplying tags:" " INFO"
    foreach ($WETag in $WETags.GetEnumerator()) {
        Write-WELog "  $($WETag.Key): $($WETag.Value)" " INFO"
    }
    Set-AzResource -ResourceId $WEServiceBusNamespace.Id -Tag $WETags -Force
}

Write-WELog " `nService Bus Namespace $WENamespaceName provisioned successfully" " INFO"
Write-WELog " Namespace ID: $($WEServiceBusNamespace.Id)" " INFO"
Write-WELog " Service Bus Endpoint: $($WEServiceBusNamespace.ServiceBusEndpoint)" " INFO"
Write-WELog " Provisioning State: $($WEServiceBusNamespace.ProvisioningState)" " INFO"
Write-WELog " Status: $($WEServiceBusNamespace.Status)" " INFO"


Write-WELog " `nSKU Features:" " INFO"
switch ($WESkuName) {
    " Basic" {
        Write-WELog "  • Queues only" " INFO"
        Write-WELog "  • Up to 100 connections" " INFO"
        Write-WELog "  • 256 KB message size" " INFO"
    }
    " Standard" {
        Write-WELog "  • Queues and Topics/Subscriptions" " INFO"
        Write-WELog "  • Up to 1,000 connections" " INFO"
        Write-WELog "  • 256 KB message size" " INFO"
        Write-WELog "  • Auto-forwarding and duplicate detection" " INFO"
    }
    " Premium" {
        Write-WELog "  • All Standard features plus:" " INFO"
        Write-WELog "  • Dedicated capacity ($WECapacity messaging units)" " INFO"
        Write-WELog "  • Up to 100 MB message size" " INFO"
        Write-WELog "  • Virtual Network integration" " INFO"
        Write-WELog "  • Private endpoints support" " INFO"
        if ($WEZoneRedundant) {
            Write-WELog "  • Zone redundancy enabled" " INFO"
        }
    }
}


try {
    $WEAuthRules = Get-AzServiceBusAuthorizationRule -ResourceGroupName $WEResourceGroupName -Namespace $WENamespaceName
    if ($WEAuthRules) {
        Write-WELog " `nAuthorization Rules:" " INFO"
        foreach ($WERule in $WEAuthRules) {
            Write-WELog "  • $($WERule.Name): $($WERule.Rights -join ', ')" " INFO"
        }
        
       ;  $WEDefaultRule = $WEAuthRules | Where-Object { $_.Name -eq " RootManageSharedAccessKey" }
        if ($WEDefaultRule) {
           ;  $WEKeys = Get-AzServiceBusKey -ResourceGroupName $WEResourceGroupName -Namespace $WENamespaceName -Name $WEDefaultRule.Name
            Write-WELog " `nConnection Strings:" " INFO"
            Write-WELog "  Primary: $($WEKeys.PrimaryConnectionString.Substring(0,50))..." " INFO"
            Write-WELog "  Secondary: $($WEKeys.SecondaryConnectionString.Substring(0,50))..." " INFO"
        }
    }
} catch {
    Write-WELog " `nConnection Strings: Available via Get-AzServiceBusKey cmdlet" " INFO"
}

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Create queues for point-to-point messaging" " INFO"
Write-WELog " 2. Create topics and subscriptions for publish-subscribe scenarios" " INFO"
Write-WELog " 3. Configure message filters and rules" " INFO"
Write-WELog " 4. Set up dead letter queues for error handling" " INFO"
Write-WELog " 5. Configure auto-scaling (Premium tier)" " INFO"

Write-WELog " `nCommon Use Cases:" " INFO"
Write-WELog "  • Decoupling application components" " INFO"
Write-WELog "  • Load balancing across worker instances" " INFO"
Write-WELog "  • Reliable message delivery" " INFO"
Write-WELog "  • Event-driven architectures" " INFO"
Write-WELog "  • Integrating on-premises and cloud systems" " INFO"

Write-WELog " `nService Bus Namespace provisioning completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================