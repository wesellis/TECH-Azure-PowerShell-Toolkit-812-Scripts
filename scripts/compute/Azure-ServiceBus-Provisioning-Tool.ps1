#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Service Bus

.DESCRIPTION
    Manage Service Bus
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$NamespaceName,
    [string]$Location,
    [string]$SkuName = "Standard",
    [int]$Capacity = 1,
    [bool]$ZoneRedundant = $false,
    [hashtable]$Tags = @{}
)
Write-Output "Provisioning Service Bus Namespace: $NamespaceName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "SKU: $SkuName"
Write-Output "Capacity: $Capacity"
Write-Output "Zone Redundant: $ZoneRedundant"
$ValidSkus = @("Basic", "Standard", "Premium")
if ($SkuName -notin $ValidSkus) {
    throw "Invalid SKU. Valid options are: $($ValidSkus -join ', ')"
}
if ($SkuName -eq "Premium" -and $Capacity -notin @(1, 2, 4, 8, 16)) {
    throw "For Premium SKU, capacity must be 1, 2, 4, 8, or 16"
}
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
if ($Tags.Count -gt 0) {
    Write-Output "`nApplying tags:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Output "  $($Tag.Key): $($Tag.Value)"
    }
    Set-AzResource -ResourceId $ServiceBusNamespace.Id -Tag $Tags -Force
}
Write-Output "`nService Bus Namespace $NamespaceName provisioned successfully"
Write-Output "Namespace ID: $($ServiceBusNamespace.Id)"
Write-Output "Service Bus Endpoint: $($ServiceBusNamespace.ServiceBusEndpoint)"
Write-Output "Provisioning State: $($ServiceBusNamespace.ProvisioningState)"
Write-Output "Status: $($ServiceBusNamespace.Status)"
Write-Output "`nSKU Features:"
switch ($SkuName) {
    "Basic" {
        Write-Output "   Queues only"
        Write-Output "   Up to 100 connections"
        Write-Output "   256 KB message size"
    }
    "Standard" {
        Write-Output "   Queues and Topics/Subscriptions"
        Write-Output "   Up to 1,000 connections"
        Write-Output "   256 KB message size"
        Write-Output "   Auto-forwarding and duplicate detection"
    }
    "Premium" {
        Write-Output "   All Standard features plus:"
        Write-Output "   Dedicated capacity ($Capacity messaging units)"
        Write-Output "   Up to 100 MB message size"
        Write-Output "   Virtual Network integration"
        Write-Output "   Private endpoints support"
        if ($ZoneRedundant) {
            Write-Output "   Zone redundancy enabled"
        }
    }
}
try {
    $AuthRules = Get-AzServiceBusAuthorizationRule -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName
    if ($AuthRules) {
        Write-Output "`nAuthorization Rules:"
        foreach ($Rule in $AuthRules) {
            Write-Output "   $($Rule.Name): $($Rule.Rights -join ', ')"
        }
        $DefaultRule = $AuthRules | Where-Object { $_.Name -eq "RootManageSharedAccessKey" }
        if ($DefaultRule) {
            $Keys = Get-AzServiceBusKey -ResourceGroupName $ResourceGroupName -Namespace $NamespaceName -Name $DefaultRule.Name
            Write-Output "`nConnection Strings:"
            Write-Output "Primary: $($Keys.PrimaryConnectionString.Substring(0,50))..."
            Write-Output "Secondary: $($Keys.SecondaryConnectionString.Substring(0,50))..."
        }
    }
} catch {
    Write-Output "`nConnection Strings: Available via Get-AzServiceBusKey -ErrorAction Stop cmdlet"
}
Write-Output "`nNext Steps:"
Write-Output "1. Create queues for point-to-point messaging"
Write-Output "2. Create topics and subscriptions for publish-subscribe scenarios"
Write-Output "3. Configure message filters and rules"
Write-Output "4. Set up dead letter queues for error handling"
Write-Output "5. Configure auto-scaling (Premium tier)"
Write-Output "`nCommon Use Cases:"
Write-Output "   Decoupling application components"
Write-Output "   Load balancing across worker instances"
Write-Output "   Reliable message delivery"
Write-Output "   Event-driven architectures"
Write-Output "   Integrating on-premises and cloud systems"
Write-Output "`nService Bus Namespace provisioning completed at $(Get-Date)"



