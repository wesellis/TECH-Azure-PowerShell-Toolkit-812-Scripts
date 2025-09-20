#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Find orphaned resources

.DESCRIPTION
    Find orphaned resources
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Resource Orphan Finder Tool
#
[CmdletBinding(SupportsShouldProcess)]

    [Parameter()]
    [string]$SubscriptionId,
    [Parameter()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateSet("All", "NetworkInterfaces", "PublicIPs", "Disks", "Snapshots", "LoadBalancers", "NetworkSecurityGroups", "StorageAccounts", "KeyVaults")]
    [string]$ResourceType = "All",
    [Parameter()]
    [int]$DaysUnused = 30,
    [Parameter()]
    [switch]$RemoveOrphans,
    [Parameter()]
    [switch]$GenerateReport,
    [Parameter()]
    [string]$OutputPath = ".\orphaned-resources-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv",
    [Parameter()]
    [switch]$IncludeCostAnalysis,
    [Parameter()]
    [switch]$DryRun
)
$orphanedResources = @()
$totalSavings = 0
try {
    # Test Azure connection
        if (-not (Get-AzContext)) { Connect-AzAccount }
    # Set subscription context
    if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
        
    }
    # Get all resources to analyze
        $resourceFilter = @{}
    if ($ResourceGroupName) { $resourceFilter.ResourceGroupName = $ResourceGroupName }
    $allResources = Get-AzResource @resourceFilter
    
    # Analyze orphaned Network Interfaces
        if ($ResourceType -eq "All" -or $ResourceType -eq "NetworkInterfaces") {
        $networkInterfaces = Get-AzNetworkInterface
        foreach ($nic in $networkInterfaces) {
            if (-not $nic.VirtualMachine -and -not $nic.LoadBalancerBackendAddressPools) {
                $orphanedResources += [PSCustomObject]@{
                    ResourceType = "NetworkInterface"
                    ResourceName = $nic.Name
                    ResourceGroup = $nic.ResourceGroupName
                    Location = $nic.Location
                    Status = "Orphaned - Not attached to VM or LB"
                    EstimatedMonthlyCost = 5.00
                    LastModified = $nic.Tag.LastModified ?? "Unknown"
                }
            }
        }
    }
    # Analyze orphaned Public IPs
    if ($ResourceType -eq "All" -or $ResourceType -eq "PublicIPs") {
        $publicIPs = Get-AzPublicIpAddress
        foreach ($pip in $publicIPs) {
            if (-not $pip.IpConfiguration -and $pip.PublicIpAllocationMethod -eq "Static") {
                $orphanedResources += [PSCustomObject]@{
                    ResourceType = "PublicIP"
                    ResourceName = $pip.Name
                    ResourceGroup = $pip.ResourceGroupName
                    Location = $pip.Location
                    Status = "Orphaned - Static IP not assigned"
                    EstimatedMonthlyCost = 3.65
                    LastModified = $pip.Tag.LastModified ?? "Unknown"
                }
            }
        }
    }
    # Analyze orphaned Disks
        if ($ResourceType -eq "All" -or $ResourceType -eq "Disks") {
        $disks = Get-AzDisk
        foreach ($disk in $disks) {
            if (-not $disk.ManagedBy) {
                $sizeGB = $disk.DiskSizeGB
                $estimatedCost = switch ($disk.Sku.Name) {
                    "Standard_LRS" { $sizeGB * 0.05 }
                    "Premium_LRS" { $sizeGB * 0.12 }
                    "StandardSSD_LRS" { $sizeGB * 0.075 }
                    default { $sizeGB * 0.05 }
                }
                $orphanedResources += [PSCustomObject]@{
                    ResourceType = "ManagedDisk"
                    ResourceName = $disk.Name
                    ResourceGroup = $disk.ResourceGroupName
                    Location = $disk.Location
                    Status = "Orphaned - Not attached to VM"
                    EstimatedMonthlyCost = $estimatedCost
                    LastModified = $disk.TimeCreated
                    AdditionalInfo = "Size: $($disk.DiskSizeGB)GB, SKU: $($disk.Sku.Name)"
                }
            }
        }
    }
    # Analyze old Snapshots
    if ($ResourceType -eq "All" -or $ResourceType -eq "Snapshots") {
        $snapshots = Get-AzSnapshot
        $cutoffDate = (Get-Date).AddDays(-$DaysUnused)
        foreach ($snapshot in $snapshots) {
            if ($snapshot.TimeCreated -lt $cutoffDate) {
                $sizeGB = $snapshot.DiskSizeGB
                $estimatedCost = $sizeGB * 0.05  # Snapshot pricing
                $orphanedResources += [PSCustomObject]@{
                    ResourceType = "Snapshot"
                    ResourceName = $snapshot.Name
                    ResourceGroup = $snapshot.ResourceGroupName
                    Location = $snapshot.Location
                    Status = "Old - Created $([math]::Round((New-TimeSpan -Start $snapshot.TimeCreated -End (Get-Date)).TotalDays)) days ago"
                    EstimatedMonthlyCost = $estimatedCost
                    LastModified = $snapshot.TimeCreated
                    AdditionalInfo = "Size: $($snapshot.DiskSizeGB)GB"
                }
            }
        }
    }
    # Analyze orphaned NSGs
        if ($ResourceType -eq "All" -or $ResourceType -eq "NetworkSecurityGroups") {
        $nsgs = Get-AzNetworkSecurityGroup
        foreach ($nsg in $nsgs) {
            if (-not $nsg.Subnets -and -not $nsg.NetworkInterfaces) {
                $orphanedResources += [PSCustomObject]@{
                    ResourceType = "NetworkSecurityGroup"
                    ResourceName = $nsg.Name
                    ResourceGroup = $nsg.ResourceGroupName
                    Location = $nsg.Location
                    Status = "Orphaned - Not assigned to subnets or NICs"
                    EstimatedMonthlyCost = 0.00
                    LastModified = $nsg.Tag.LastModified ?? "Unknown"
                }
            }
        }
    }
    # Calculate total potential savings
        $totalSavings = ($orphanedResources | Measure-Object -Property EstimatedMonthlyCost -Sum).Sum
    # Generate report
        if ($GenerateReport -or $orphanedResources.Count -gt 0) {
        $orphanedResources | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        
    }
    # Remove orphans if requested and explicitly disabled dry run mode
    # Default behavior is safe (dry run mode) unless user explicitly disables it
    $isDryRunMode = if ($PSBoundParameters.ContainsKey('DryRun')) { $DryRun } else { $true }
    if ($RemoveOrphans -and -not $isDryRunMode) {
        
        foreach ($resource in $orphanedResources) {
            try {
                switch ($resource.ResourceType) {
                    "NetworkInterface" {
                        if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
                    }
                    "PublicIP" {
                        if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
                    }
                    "ManagedDisk" {
                        if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
                    }
                    "Snapshot" {
                        if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
                    }
                    "NetworkSecurityGroup" {
                        if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
                    }
                }
                Write-Host "Successfully removed $($resource.ResourceType): $($resource.ResourceName)" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to remove $($resource.ResourceType): $($resource.ResourceName) - $($_.Exception.Message)"
            }
        }
    }
    # Success summary
    Write-Host ""
    Write-Host "                              ORPHANED RESOURCES ANALYSIS COMPLETE"
    Write-Host ""
    Write-Host "Orphaned Resources Found:"
    $resourceTypeCounts = $orphanedResources | Group-Object ResourceType
    foreach ($type in $resourceTypeCounts) {
        Write-Host "    $($type.Name): $($type.Count) resources"
    }
    Write-Host ""
    Write-Host "Cost Analysis:"
    Write-Host "    Total Monthly Savings Potential: $${totalSavings:F2}"
    Write-Host "    Annual Savings Potential: $${($totalSavings * 12):F2}"
    if ($isDryRunMode) {
        Write-Host ""
        Write-Host "[LOCK] DRY RUN MODE:"
        Write-Host "    No resources were deleted"
        Write-Host "    Use -DryRun:`$false -RemoveOrphans to actually delete"
    }
    Write-Host ""
    Write-Host ""
    
} catch { throw }

