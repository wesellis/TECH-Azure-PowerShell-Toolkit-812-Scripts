#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Resource Orphan Finder

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionId,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter()]
    [ValidateSet("All" , "NetworkInterfaces" , "PublicIPs" , "Disks" , "Snapshots" , "LoadBalancers" , "NetworkSecurityGroups" , "StorageAccounts" , "KeyVaults" )]
    $ResourceType = "All" ,
    [Parameter()]
    [int]$DaysUnused = 30,
    [Parameter()]
    [switch]$RemoveOrphans,
    [Parameter()]
    [switch]$GenerateReport,
    [Parameter(ValueFromPipeline)]`n    $OutputPath = " .\orphaned-resources-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" ,
    [Parameter()]
    [switch]$IncludeCostAnalysis,
    [Parameter()]
    [switch]$DryRun
)
Write-Output "Script Started" # Color: $2
    $OrphanedResources = @()
    $TotalSavings = 0
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId

    }
    $ResourceFilter = @{}
    if ($ResourceGroupName) { $ResourceFilter.ResourceGroupName = $ResourceGroupName }
    $AllResources = Get-AzResource -ErrorAction Stop @resourceFilter

    if ($ResourceType -eq "All" -or $ResourceType -eq "NetworkInterfaces" ) {
    $NetworkInterfaces = Get-AzNetworkInterface -ErrorAction Stop
        foreach ($nic in $NetworkInterfaces) {
            if (-not $nic.VirtualMachine -and -not $nic.LoadBalancerBackendAddressPools) {
    $OrphanedResources = $OrphanedResources + [PSCustomObject]@{
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
    if ($ResourceType -eq "All" -or $ResourceType -eq "PublicIPs" ) {
    $PublicIPs = Get-AzPublicIpAddress -ErrorAction Stop
        foreach ($pip in $PublicIPs) {
            if (-not $pip.IpConfiguration -and $pip.PublicIpAllocationMethod -eq "Static" ) {
    $OrphanedResources = $OrphanedResources + [PSCustomObject]@{
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
    if ($ResourceType -eq "All" -or $ResourceType -eq "Disks" ) {
    $disks = Get-AzDisk -ErrorAction Stop
        foreach ($disk in $disks) {
            if (-not $disk.ManagedBy) {
    $SizeGB = $disk.DiskSizeGB
    $EstimatedCost = switch ($disk.Sku.Name) {
                    "Standard_LRS" { $SizeGB * 0.05 }
                    "Premium_LRS" { $SizeGB * 0.12 }
                    "StandardSSD_LRS" { $SizeGB * 0.075 }
                    default { $SizeGB * 0.05 }
                }
    $OrphanedResources = $OrphanedResources + [PSCustomObject]@{
                    ResourceType = "ManagedDisk"
                    ResourceName = $disk.Name
                    ResourceGroup = $disk.ResourceGroupName
                    Location = $disk.Location
                    Status = "Orphaned - Not attached to VM"
                    EstimatedMonthlyCost = $EstimatedCost
                    LastModified = $disk.TimeCreated
                    AdditionalInfo = "Size: $($disk.DiskSizeGB)GB, SKU: $($disk.Sku.Name)"
                }
            }
        }
    }
    if ($ResourceType -eq "All" -or $ResourceType -eq "Snapshots" ) {
    $snapshots = Get-AzSnapshot -ErrorAction Stop
    $CutoffDate = (Get-Date).AddDays(-$DaysUnused)
        foreach ($snapshot in $snapshots) {
            if ($snapshot.TimeCreated -lt $CutoffDate) {
    $SizeGB = $snapshot.DiskSizeGB
    $EstimatedCost = $SizeGB * 0.05
    $OrphanedResources = $OrphanedResources + [PSCustomObject]@{
                    ResourceType = "Snapshot"
                    ResourceName = $snapshot.Name
                    ResourceGroup = $snapshot.ResourceGroupName
                    Location = $snapshot.Location
                    Status = "Old - Created $([math]::Round((New-TimeSpan -Start $snapshot.TimeCreated -End (Get-Date)).TotalDays)) days ago"
                    EstimatedMonthlyCost = $EstimatedCost
                    LastModified = $snapshot.TimeCreated
                    AdditionalInfo = "Size: $($snapshot.DiskSizeGB)GB"
                }
            }
        }
    }
    if ($ResourceType -eq "All" -or $ResourceType -eq "NetworkSecurityGroups" ) {
    $nsgs = Get-AzNetworkSecurityGroup -ErrorAction Stop
        foreach ($nsg in $nsgs) {
            if (-not $nsg.Subnets -and -not $nsg.NetworkInterfaces) {
    $OrphanedResources = $OrphanedResources + [PSCustomObject]@{
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
    $TotalSavings = ($OrphanedResources | Measure-Object -Property EstimatedMonthlyCost -Sum).Sum
    if ($GenerateReport -or $OrphanedResources.Count -gt 0) {
    $OrphanedResources | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    }
    $IsDryRunMode = if ($PSBoundParameters.ContainsKey('DryRun')) { $DryRun } else { $true }
    if ($RemoveOrphans -and -not $IsDryRunMode) {

        foreach ($resource in $OrphanedResources) {
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

            } catch {

            }
        }
    }
    Write-Output ""
    Write-Output "                              ORPHANED RESOURCES ANALYSIS COMPLETE" # Color: $2
    Write-Output ""
    Write-Output "Orphaned Resources Found:" # Color: $2
    $ResourceTypeCounts = $OrphanedResources | Group-Object ResourceType
    foreach ($type in $ResourceTypeCounts) {
        Write-Output "    $($type.Name): $($type.Count) resources" # Color: $2
    }
    Write-Output ""
    Write-Output "Cost Analysis:" # Color: $2
    Write-Output "    Total Monthly Savings Potential: $${totalSavings:F2}" # Color: $2
    Write-Output "    Annual Savings Potential: $${($TotalSavings * 12):F2}" # Color: $2
    if ($IsDryRunMode) {
        Write-Output ""
        Write-Output " [LOCK] DRY RUN MODE:" # Color: $2
        Write-Output "    No resources were deleted" # Color: $2
        Write-Output "    Use -DryRun:`$false -RemoveOrphans to actually delete" # Color: $2
    }
    Write-Output ""
    Write-Output "Report Location: $OutputPath" # Color: $2
    Write-Output ""

} catch { throw`n}
