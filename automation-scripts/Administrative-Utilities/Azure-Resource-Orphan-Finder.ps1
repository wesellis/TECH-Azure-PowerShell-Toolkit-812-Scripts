# Azure Resource Orphan Finder Tool
# Professional Azure utility script for identifying unused and orphaned resources
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0 | Advanced resource cleanup and cost optimization

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("All", "NetworkInterfaces", "PublicIPs", "Disks", "Snapshots", "LoadBalancers", "NetworkSecurityGroups", "StorageAccounts", "KeyVaults")]
    [string]$ResourceType = "All",
    
    [Parameter(Mandatory=$false)]
    [int]$DaysUnused = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveOrphans,
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\orphaned-resources-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeCostAnalysis,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import common functions
Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

# Professional banner
Show-Banner -ScriptName "Azure Resource Orphan Finder Tool" -Version "1.0" -Description "Identify and cleanup unused Azure resources for cost optimization"

$orphanedResources = @()
$totalSavings = 0

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 8 -StepName "Azure Connection" -Status "Validating connection and modules"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Network', 'Az.Storage'))) {
        throw "Azure connection validation failed"
    }

    # Set subscription context
    if ($SubscriptionId) {
        Write-ProgressStep -StepNumber 2 -TotalSteps 8 -StepName "Subscription Context" -Status "Setting subscription context"
        Set-AzContext -SubscriptionId $SubscriptionId
        Write-Log "✓ Subscription context set to: $SubscriptionId" -Level SUCCESS
    }

    # Get all resources to analyze
    Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Resource Discovery" -Status "Discovering resources for analysis"
    
    $resourceFilter = @{}
    if ($ResourceGroupName) { $resourceFilter.ResourceGroupName = $ResourceGroupName }
    
    $allResources = Get-AzResource -ErrorAction Stop @resourceFilter
    Write-Log "Found $($allResources.Count) total resources to analyze" -Level INFO

    # Analyze orphaned Network Interfaces
    Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName "Network Analysis" -Status "Finding orphaned network interfaces"
    
    if ($ResourceType -eq "All" -or $ResourceType -eq "NetworkInterfaces") {
        $networkInterfaces = Get-AzNetworkInterface -ErrorAction Stop
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
        $publicIPs = Get-AzPublicIpAddress -ErrorAction Stop
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
    Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName "Storage Analysis" -Status "Finding orphaned disks and snapshots"
    
    if ($ResourceType -eq "All" -or $ResourceType -eq "Disks") {
        $disks = Get-AzDisk -ErrorAction Stop
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
        $snapshots = Get-AzSnapshot -ErrorAction Stop
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
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName "Security Analysis" -Status "Finding orphaned security groups"
    
    if ($ResourceType -eq "All" -or $ResourceType -eq "NetworkSecurityGroups") {
        $nsgs = Get-AzNetworkSecurityGroup -ErrorAction Stop
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
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName "Cost Analysis" -Status "Calculating potential savings"
    
    $totalSavings = ($orphanedResources | Measure-Object -Property EstimatedMonthlyCost -Sum).Sum
    
    # Generate report
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName "Report Generation" -Status "Generating orphan report"
    
    if ($GenerateReport -or $orphanedResources.Count -gt 0) {
        $orphanedResources | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Log "✓ Orphaned resources report saved to: $OutputPath" -Level SUCCESS
    }

    # Remove orphans if requested and explicitly disabled dry run mode  
    # Default behavior is safe (dry run mode) unless user explicitly disables it
    $isDryRunMode = if ($PSBoundParameters.ContainsKey('DryRun')) { $DryRun } else { $true }
    
    if ($RemoveOrphans -and -not $isDryRunMode) {
        Write-Log "🗑️ Removing orphaned resources..." -Level WARNING
        
        foreach ($resource in $orphanedResources) {
            try {
                switch ($resource.ResourceType) {
                    "NetworkInterface" {
                        Remove-AzNetworkInterface -Name $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                    "PublicIP" {
                        Remove-AzPublicIpAddress -Name $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                    "ManagedDisk" {
                        Remove-AzDisk -DiskName $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                    "Snapshot" {
                        Remove-AzSnapshot -SnapshotName $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                    "NetworkSecurityGroup" {
                        Remove-AzNetworkSecurityGroup -Name $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                }
                Write-Log "✓ Removed $($resource.ResourceType): $($resource.ResourceName)" -Level SUCCESS
            } catch {
                Write-Log "❌ Failed to remove $($resource.ResourceName): $($_.Exception.Message)" -Level ERROR
            }
        }
    }

    # Success summary
    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                              ORPHANED RESOURCES ANALYSIS COMPLETE"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    Write-Information "📊 Orphaned Resources Found:"
    
    $resourceTypeCounts = $orphanedResources | Group-Object ResourceType
    foreach ($type in $resourceTypeCounts) {
        Write-Information "   • $($type.Name): $($type.Count) resources"
    }
    
    Write-Information ""
    Write-Information "💰 Cost Analysis:"
    Write-Information "   • Total Monthly Savings Potential: $${totalSavings:F2}"
    Write-Information "   • Annual Savings Potential: $${($totalSavings * 12):F2}"
    
    if ($isDryRunMode) {
        Write-Information ""
        Write-Information "🔒 DRY RUN MODE:"
        Write-Information "   • No resources were deleted"
        Write-Information "   • Use -DryRun:`$false -RemoveOrphans to actually delete"
    }
    
    Write-Information ""
    Write-Information "📋 Report Location: $OutputPath"
    Write-Information ""

    Write-Log "✅ Orphaned resources analysis completed successfully!" -Level SUCCESS

} catch {
    Write-Log "❌ Orphaned resources analysis failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity "Orphaned Resources Analysis" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO