# ============================================================================
# Script Name: Azure Service Bus Namespace Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Service Bus namespaces for reliable messaging and queuing
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$NamespaceName,
    [string]$Location,
    [string]$SkuName = "Standard",
    [int]$Capacity = 1,
    [bool]$ZoneRedundant = $false,
    [hashtable]$Tags = @{}
)

Write-Information "Provisioning Service Bus Namespace: $NamespaceName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "SKU: $SkuName"
Write-Information "Capacity: $Capacity"
Write-Information "Zone Redundant: $ZoneRedundant"

# Validate SKU and capacity
$ValidSkus = @("Basic", "Standard", "Premium")
if ($SkuName -notin $ValidSkus) {
    throw "Invalid SKU. Valid options are: $($ValidSkus -join ', ')"
}

if ($SkuName -eq "Premium" -and $Capacity -notin @(1, 2, 4, 8, 16)) {
    throw "For Premium SKU, capacity must be 1, 2, 4, 8, or 16"
}

# Create the Service Bus Namespace
$ServiceBusParams = @{
    ResourceGroupName = $ResourceGroupName
    Name = $NamespaceName
    Location = $Location
    SkuName = $SkuName
}

if ($SkuName -eq "Premium") {
    $ServiceBusParams.SkuCapacity = $Capacity
    if ($ZoneRedundant) {
        $ServiceBusParams.ZoneRedundant = $true
    }
}

$ServiceBusNamespace = New-AzServiceBusNamespace -ErrorAction Stop @ServiceBusParams

# Apply tags if provided
if ($Tags.Count -gt 0) {
    Write-Information "`nApplying tags:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Information "  $($Tag.Key): $($Tag.Value)"
    }
    Set-AzResource -ResourceId $ServiceBusNamespace.Id -Tag $Tags -Force
}

Write-Information "`nService Bus Namespace $NamespaceName provisioned successfully"
Write-Information "Namespace ID: $($ServiceBusNamespace.Id)"
Write-Information "Service Bus Endpoint: $($ServiceBusNamespace.ServiceBusEndpoint)"
Write-Information "Provisioning State: $($ServiceBusNamespace.ProvisioningState)"
Write-Information "Status: $($ServiceBusNamespace.Status)"

# Display SKU-specific features
Write-Information "`nSKU Features:"
switch ($SkuName) {
    "Basic" {
        Write-Information "  • Queues only"
        Write-Information "  • Up to 100 connections"
        Write-Information "  • 256 KB message size"
    }
    "Standard" {
        Write-Information "  • Queues and Topics/Subscriptions"
        Write-Information "  • Up to 1,000 connections"
        Write-Information "  • 256 KB message size"
        Write-Information "  • Auto-forwarding and duplicate detection"
    }
    "Premium" {
        Write-Information "  • All Standard features plus:"
        Write-Information "  • Dedicated capacity ($Capacity messaging units)"
        Write-Information "  • Up to 100 MB message size"
        Write-Information "  • Virtual Network integration"
        Write-Information "  • Private endpoints support"
        if ($ZoneRedundant) {
            Write-Information "  • Zone redundancy enabled"
        }
    }
}

# Get connection strings
try {
    $AuthRules = Get-AzServiceBusAuthorizationRule -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName
    if ($AuthRules) {
        Write-Information "`nAuthorization Rules:"
        foreach ($Rule in $AuthRules) {
            Write-Information "  • $($Rule.Name): $($Rule.Rights -join ', ')"
        }
        
        $DefaultRule = $AuthRules | Where-Object { $_.Name -eq "RootManageSharedAccessKey" }
        if ($DefaultRule) {
            $Keys = Get-AzServiceBusKey -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName -Name $DefaultRule.Name
            Write-Information "`nConnection Strings:"
            Write-Information "  Primary: $($Keys.PrimaryConnectionString.Substring(0,50))..."
            Write-Information "  Secondary: $($Keys.SecondaryConnectionString.Substring(0,50))..."
        }
    }
} catch {
    Write-Information "`nConnection Strings: Available via Get-AzServiceBusKey -ErrorAction Stop cmdlet"
}

Write-Information "`nNext Steps:"
Write-Information "1. Create queues for point-to-point messaging"
Write-Information "2. Create topics and subscriptions for publish-subscribe scenarios"
Write-Information "3. Configure message filters and rules"
Write-Information "4. Set up dead letter queues for error handling"
Write-Information "5. Configure auto-scaling (Premium tier)"

Write-Information "`nCommon Use Cases:"
Write-Information "  • Decoupling application components"
Write-Information "  • Load balancing across worker instances"
Write-Information "  • Reliable message delivery"
Write-Information "  • Event-driven architectures"
Write-Information "  • Integrating on-premises and cloud systems"

Write-Information "`nService Bus Namespace provisioning completed at $(Get-Date)"
