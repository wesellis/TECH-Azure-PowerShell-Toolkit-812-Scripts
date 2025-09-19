#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Resource Orphan Finder

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Resource Orphan Finder

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" All" , " NetworkInterfaces" , " PublicIPs" , " Disks" , " Snapshots" , " LoadBalancers" , " NetworkSecurityGroups" , " StorageAccounts" , " KeyVaults" )]
    [string]$WEResourceType = " All" ,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDaysUnused = 30,
    
    [Parameter(Mandatory=$false)]
    [switch]$WERemoveOrphans,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEGenerateReport,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputPath = " .\orphaned-resources-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" ,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEIncludeCostAnalysis,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEDryRun
)

#region Functions


# Module import removed - use #Requires instead


Show-Banner -ScriptName " Azure Resource Orphan Finder Tool" -Version " 1.0" -Description " Identify and cleanup unused Azure resources for cost optimization"

$orphanedResources = @()
$totalSavings = 0

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 8 -StepName " Azure Connection" -Status " Validating connection and modules"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Network', 'Az.Storage'))) {
        throw " Azure connection validation failed"
    }

    # Set subscription context
    if ($WESubscriptionId) {
        Write-ProgressStep -StepNumber 2 -TotalSteps 8 -StepName " Subscription Context" -Status " Setting subscription context"
        Set-AzContext -SubscriptionId $WESubscriptionId
        Write-Log " [OK] Subscription context set to: $WESubscriptionId" -Level SUCCESS
    }

    # Get all resources to analyze
    Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName " Resource Discovery" -Status " Discovering resources for analysis"
    
    $resourceFilter = @{}
    if ($WEResourceGroupName) { $resourceFilter.ResourceGroupName = $WEResourceGroupName }
    
    $allResources = Get-AzResource -ErrorAction Stop @resourceFilter
    Write-Log " Found $($allResources.Count) total resources to analyze" -Level INFO

    # Analyze orphaned Network Interfaces
    Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName " Network Analysis" -Status " Finding orphaned network interfaces"
    
    if ($WEResourceType -eq " All" -or $WEResourceType -eq " NetworkInterfaces" ) {
        $networkInterfaces = Get-AzNetworkInterface -ErrorAction Stop
        foreach ($nic in $networkInterfaces) {
            if (-not $nic.VirtualMachine -and -not $nic.LoadBalancerBackendAddressPools) {
                $orphanedResources = $orphanedResources + [PSCustomObject]@{
                    ResourceType = " NetworkInterface"
                    ResourceName = $nic.Name
                    ResourceGroup = $nic.ResourceGroupName
                    Location = $nic.Location
                    Status = " Orphaned - Not attached to VM or LB"
                    EstimatedMonthlyCost = 5.00
                    LastModified = $nic.Tag.LastModified ?? " Unknown"
                }
            }
        }
    }

    # Analyze orphaned Public IPs
    if ($WEResourceType -eq " All" -or $WEResourceType -eq " PublicIPs" ) {
        $publicIPs = Get-AzPublicIpAddress -ErrorAction Stop
        foreach ($pip in $publicIPs) {
            if (-not $pip.IpConfiguration -and $pip.PublicIpAllocationMethod -eq " Static" ) {
                $orphanedResources = $orphanedResources + [PSCustomObject]@{
                    ResourceType = " PublicIP"
                    ResourceName = $pip.Name
                    ResourceGroup = $pip.ResourceGroupName
                    Location = $pip.Location
                    Status = " Orphaned - Static IP not assigned"
                    EstimatedMonthlyCost = 3.65
                    LastModified = $pip.Tag.LastModified ?? " Unknown"
                }
            }
        }
    }

    # Analyze orphaned Disks
    Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName " Storage Analysis" -Status " Finding orphaned disks and snapshots"
    
    if ($WEResourceType -eq " All" -or $WEResourceType -eq " Disks" ) {
        $disks = Get-AzDisk -ErrorAction Stop
        foreach ($disk in $disks) {
            if (-not $disk.ManagedBy) {
                $sizeGB = $disk.DiskSizeGB
                $estimatedCost = switch ($disk.Sku.Name) {
                    " Standard_LRS" { $sizeGB * 0.05 }
                    " Premium_LRS" { $sizeGB * 0.12 }
                    " StandardSSD_LRS" { $sizeGB * 0.075 }
                    default { $sizeGB * 0.05 }
                }
                
                $orphanedResources = $orphanedResources + [PSCustomObject]@{
                    ResourceType = " ManagedDisk"
                    ResourceName = $disk.Name
                    ResourceGroup = $disk.ResourceGroupName
                    Location = $disk.Location
                    Status = " Orphaned - Not attached to VM"
                    EstimatedMonthlyCost = $estimatedCost
                    LastModified = $disk.TimeCreated
                    AdditionalInfo = " Size: $($disk.DiskSizeGB)GB, SKU: $($disk.Sku.Name)"
                }
            }
        }
    }

    # Analyze old Snapshots
    if ($WEResourceType -eq " All" -or $WEResourceType -eq " Snapshots" ) {
        $snapshots = Get-AzSnapshot -ErrorAction Stop
        $cutoffDate = (Get-Date).AddDays(-$WEDaysUnused)
        
        foreach ($snapshot in $snapshots) {
            if ($snapshot.TimeCreated -lt $cutoffDate) {
                $sizeGB = $snapshot.DiskSizeGB
                $estimatedCost = $sizeGB * 0.05  # Snapshot pricing
                
                $orphanedResources = $orphanedResources + [PSCustomObject]@{
                    ResourceType = " Snapshot"
                    ResourceName = $snapshot.Name
                    ResourceGroup = $snapshot.ResourceGroupName
                    Location = $snapshot.Location
                    Status = " Old - Created $([math]::Round((New-TimeSpan -Start $snapshot.TimeCreated -End (Get-Date)).TotalDays)) days ago"
                    EstimatedMonthlyCost = $estimatedCost
                    LastModified = $snapshot.TimeCreated
                    AdditionalInfo = " Size: $($snapshot.DiskSizeGB)GB"
                }
            }
        }
    }

    # Analyze orphaned NSGs
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName " Security Analysis" -Status " Finding orphaned security groups"
    
    if ($WEResourceType -eq " All" -or $WEResourceType -eq " NetworkSecurityGroups" ) {
        $nsgs = Get-AzNetworkSecurityGroup -ErrorAction Stop
        foreach ($nsg in $nsgs) {
            if (-not $nsg.Subnets -and -not $nsg.NetworkInterfaces) {
                $orphanedResources = $orphanedResources + [PSCustomObject]@{
                    ResourceType = " NetworkSecurityGroup"
                    ResourceName = $nsg.Name
                    ResourceGroup = $nsg.ResourceGroupName
                    Location = $nsg.Location
                    Status = " Orphaned - Not assigned to subnets or NICs"
                    EstimatedMonthlyCost = 0.00
                    LastModified = $nsg.Tag.LastModified ?? " Unknown"
                }
            }
        }
    }

    # Calculate total potential savings
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName " Cost Analysis" -Status " Calculating potential savings"
    
    $totalSavings = ($orphanedResources | Measure-Object -Property EstimatedMonthlyCost -Sum).Sum
    
    # Generate report
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName " Report Generation" -Status " Generating orphan report"
    
    if ($WEGenerateReport -or $orphanedResources.Count -gt 0) {
        $orphanedResources | Export-Csv -Path $WEOutputPath -NoTypeInformation -Encoding UTF8
        Write-Log " [OK] Orphaned resources report saved to: $WEOutputPath" -Level SUCCESS
    }

    # Remove orphans if requested and explicitly disabled dry run mode  
    # Default behavior is safe (dry run mode) unless user explicitly disables it
   ;  $isDryRunMode = if ($WEPSBoundParameters.ContainsKey('DryRun')) { $WEDryRun } else { $true }
    
    if ($WERemoveOrphans -and -not $isDryRunMode) {
        Write-Log " 🗑️ Removing orphaned resources..." -Level WARNING
        
        foreach ($resource in $orphanedResources) {
            try {
                switch ($resource.ResourceType) {
                    " NetworkInterface" {
                        Remove-AzNetworkInterface -Name $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                    " PublicIP" {
                        Remove-AzPublicIpAddress -Name $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                    " ManagedDisk" {
                        Remove-AzDisk -DiskName $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                    " Snapshot" {
                        Remove-AzSnapshot -SnapshotName $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                    " NetworkSecurityGroup" {
                        Remove-AzNetworkSecurityGroup -Name $resource.ResourceName -ResourceGroupName $resource.ResourceGroup -Force
                    }
                }
                Write-Log " [OK] Removed $($resource.ResourceType): $($resource.ResourceName)" -Level SUCCESS
            } catch {
                Write-Log "  Failed to remove $($resource.ResourceName): $($_.Exception.Message)" -Level ERROR
            }
        }
    }

    # Success summary
    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                              ORPHANED RESOURCES ANALYSIS COMPLETE" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    Write-WELog "  Orphaned Resources Found:" " INFO" -ForegroundColor Cyan
    
   ;  $resourceTypeCounts = $orphanedResources | Group-Object ResourceType
    foreach ($type in $resourceTypeCounts) {
        Write-WELog "   • $($type.Name): $($type.Count) resources" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog "  Cost Analysis:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Total Monthly Savings Potential: $${totalSavings:F2}" " INFO" -ForegroundColor Green
    Write-WELog "   • Annual Savings Potential: $${($totalSavings * 12):F2}" " INFO" -ForegroundColor Green
    
    if ($isDryRunMode) {
        Write-WELog "" " INFO"
        Write-WELog " [LOCK] DRY RUN MODE:" " INFO" -ForegroundColor Yellow
        Write-WELog "   • No resources were deleted" " INFO" -ForegroundColor White
        Write-WELog "   • Use -DryRun:`$false -RemoveOrphans to actually delete" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 📋 Report Location: $WEOutputPath" " INFO" -ForegroundColor Cyan
    Write-WELog "" " INFO"

    Write-Log "  Orphaned resources analysis completed successfully!" -Level SUCCESS

} catch {
    Write-Log "  Orphaned resources analysis failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity " Orphaned Resources Analysis" -Completed
Write-Log " Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
