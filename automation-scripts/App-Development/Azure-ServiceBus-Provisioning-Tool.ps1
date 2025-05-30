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

Write-Host "Provisioning Service Bus Namespace: $NamespaceName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "SKU: $SkuName"
Write-Host "Capacity: $Capacity"
Write-Host "Zone Redundant: $ZoneRedundant"

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

$ServiceBusNamespace = New-AzServiceBusNamespace @ServiceBusParams

# Apply tags if provided
if ($Tags.Count -gt 0) {
    Write-Host "`nApplying tags:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Host "  $($Tag.Key): $($Tag.Value)"
    }
    Set-AzResource -ResourceId $ServiceBusNamespace.Id -Tag $Tags -Force
}

Write-Host "`nService Bus Namespace $NamespaceName provisioned successfully"
Write-Host "Namespace ID: $($ServiceBusNamespace.Id)"
Write-Host "Service Bus Endpoint: $($ServiceBusNamespace.ServiceBusEndpoint)"
Write-Host "Provisioning State: $($ServiceBusNamespace.ProvisioningState)"
Write-Host "Status: $($ServiceBusNamespace.Status)"

# Display SKU-specific features
Write-Host "`nSKU Features:"
switch ($SkuName) {
    "Basic" {
        Write-Host "  • Queues only"
        Write-Host "  • Up to 100 connections"
        Write-Host "  • 256 KB message size"
    }
    "Standard" {
        Write-Host "  • Queues and Topics/Subscriptions"
        Write-Host "  • Up to 1,000 connections"
        Write-Host "  • 256 KB message size"
        Write-Host "  • Auto-forwarding and duplicate detection"
    }
    "Premium" {
        Write-Host "  • All Standard features plus:"
        Write-Host "  • Dedicated capacity ($Capacity messaging units)"
        Write-Host "  • Up to 100 MB message size"
        Write-Host "  • Virtual Network integration"
        Write-Host "  • Private endpoints support"
        if ($ZoneRedundant) {
            Write-Host "  • Zone redundancy enabled"
        }
    }
}

# Get connection strings
try {
    $AuthRules = Get-AzServiceBusAuthorizationRule -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName
    if ($AuthRules) {
        Write-Host "`nAuthorization Rules:"
        foreach ($Rule in $AuthRules) {
            Write-Host "  • $($Rule.Name): $($Rule.Rights -join ', ')"
        }
        
        $DefaultRule = $AuthRules | Where-Object { $_.Name -eq "RootManageSharedAccessKey" }
        if ($DefaultRule) {
            $Keys = Get-AzServiceBusKey -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName -Name $DefaultRule.Name
            Write-Host "`nConnection Strings:"
            Write-Host "  Primary: $($Keys.PrimaryConnectionString.Substring(0,50))..."
            Write-Host "  Secondary: $($Keys.SecondaryConnectionString.Substring(0,50))..."
        }
    }
} catch {
    Write-Host "`nConnection Strings: Available via Get-AzServiceBusKey cmdlet"
}

Write-Host "`nNext Steps:"
Write-Host "1. Create queues for point-to-point messaging"
Write-Host "2. Create topics and subscriptions for publish-subscribe scenarios"
Write-Host "3. Configure message filters and rules"
Write-Host "4. Set up dead letter queues for error handling"
Write-Host "5. Configure auto-scaling (Premium tier)"

Write-Host "`nCommon Use Cases:"
Write-Host "  • Decoupling application components"
Write-Host "  • Load balancing across worker instances"
Write-Host "  • Reliable message delivery"
Write-Host "  • Event-driven architectures"
Write-Host "  • Integrating on-premises and cloud systems"

Write-Host "`nService Bus Namespace provisioning completed at $(Get-Date)"
