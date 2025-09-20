<#
.SYNOPSIS
    List all Azure VMs

.DESCRIPTION
    Get Azure VM inventory with filtering and export options
.PARAMETER SubscriptionId
    Subscription ID
.PARAMETER ResourceGroupName
    Resource group name
.PARAMETER OutputFormat
    Output format: Table, JSON, CSV, or Grid
.PARAMETER IncludeDetails
    Include VM details
.PARAMETER Filter
    Filter VMs by power state: Running, Stopped, Deallocated, All
.PARAMETER SortBy
    Sort results by: Name, ResourceGroup, PowerState, Size, Location
.PARAMETER ExportPath
    Export results to file (CSV or JSON format based on extension)
.PARAMETER ShowCosts
    Include cost estimates
    .\Azure-VM-List-All.ps1
    .\Azure-VM-List-All.ps1 -ResourceGroupName "RG-Production" -OutputFormat Table
    .\Azure-VM-List-All.ps1 -Filter Running -IncludeDetails -ExportPath "running-vms.csv"
#>
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateSet('Table', 'JSON', 'CSV', 'Grid')]
    [string]$OutputFormat = 'Table',
    [Parameter()]
    [switch]$IncludeDetails,
    [Parameter()]
    [ValidateSet('Running', 'Stopped', 'Deallocated', 'All')]
    [string]$Filter = 'All',
    [Parameter()]
    [ValidateSet('Name', 'ResourceGroup', 'PowerState', 'Size', 'Location')]
    [string]$SortBy = 'Name',
    [Parameter()]
    [ValidateScript({
        $extension = [System.IO.Path]::GetExtension($_)
        $extension -in @('.csv', '.json')
    })]
    [string]$ExportPath,
    [Parameter()]
    [switch]$ShowCosts
)
$ErrorActionPreference = 'Stop'
function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "Connecting to Azure..." -ForegroundColor Yellow
            Connect-AzAccount
            $context = Get-AzContext
        }
        return $context
    }
    catch {
        Write-Error "Failed to establish Azure connection: $_"
        return $null
    }
}
function Get-VMDetailedInfo {
    param(
        [object]$VM,
        [bool]$IncludeDetails
    )
    # Base information
    $vmInfo = [PSCustomObject]@{
        Name = $VM.Name
        ResourceGroup = $VM.ResourceGroupName
        Location = $VM.Location
        PowerState = ($VM.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
        ProvisioningState = ($VM.Statuses | Where-Object { $_.Code -like 'ProvisioningState/*' }).DisplayStatus
        Size = $VM.HardwareProfile.VmSize
        OSType = $VM.StorageProfile.OsDisk.OsType
        AdminUsername = $VM.OSProfile.AdminUsername
        Tags = if ($VM.Tags) { ($VM.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; ' } else { 'None' }
    }
    if ($IncludeDetails) {
        # Get additional details
        try {
            $vmExtended = Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
            # Network information
            $nicCount = $vmExtended.NetworkProfile.NetworkInterfaces.Count
            $primaryNic = if ($nicCount -gt 0) {
                $nicId = $vmExtended.NetworkProfile.NetworkInterfaces[0].Id
                try {
                    Get-AzNetworkInterface | Where-Object { $_.Id -eq $nicId }
                } catch { $null }
            } else { $null }
            $vmInfo | Add-Member -NotePropertyName 'NetworkInterfaces' -NotePropertyValue $nicCount
            $vmInfo | Add-Member -NotePropertyName 'PrivateIP' -NotePropertyValue (
                if ($primaryNic) { $primaryNic.IpConfigurations[0].PrivateIpAddress } else { 'None' }
            )
            $vmInfo | Add-Member -NotePropertyName 'PublicIP' -NotePropertyValue (
                if ($primaryNic -and $primaryNic.IpConfigurations[0].PublicIpAddress) {
                    try {
                        $pip = Get-AzPublicIpAddress | Where-Object { $_.Id -eq $primaryNic.IpConfigurations[0].PublicIpAddress.Id }
                        if ($pip) { $pip.IpAddress } else { 'None' }
                    } catch { 'None' }
                } else { 'None' }
            )
            # Storage information
            $dataDisks = $vmExtended.StorageProfile.DataDisks.Count
            $vmInfo | Add-Member -NotePropertyName 'DataDisks' -NotePropertyValue $dataDisks
            $vmInfo | Add-Member -NotePropertyName 'OSDiskSize' -NotePropertyValue "$($vmExtended.StorageProfile.OsDisk.DiskSizeGB) GB"
            # Availability information
            $vmInfo | Add-Member -NotePropertyName 'AvailabilitySet' -NotePropertyValue (
                if ($vmExtended.AvailabilitySetReference) {
                    $vmExtended.AvailabilitySetReference.Id.Split('/')[-1]
                } else { 'None' }
            )
            # VM Agent status
            $vmAgentStatus = ($VM.Statuses | Where-Object { $_.Code -like 'VMAgent/*' }).DisplayStatus
            $vmInfo | Add-Member -NotePropertyName 'VMAgent' -NotePropertyValue ($vmAgentStatus -or 'Unknown')
            # Boot diagnostics
            $bootDiag = if ($vmExtended.DiagnosticsProfile -and $vmExtended.DiagnosticsProfile.BootDiagnostics) {
                $vmExtended.DiagnosticsProfile.BootDiagnostics.Enabled
            } else { $false }
            $vmInfo | Add-Member -NotePropertyName 'BootDiagnostics' -NotePropertyValue $bootDiag
        }
        catch {
            Write-Warning "Could not retrieve extended details for VM: $($VM.Name)"
        }
    }
    return $vmInfo
}
function Get-EstimatedCosts {
    param([object[]]$VMs)
    Write-Host "Retrieving cost estimates..." -ForegroundColor Yellow
    # This would require Azure Cost Management API or Pricing API
    # For demonstration, we'll add placeholder cost estimation
    foreach ($vm in $VMs) {
        $vm | Add-Member -NotePropertyName 'EstimatedMonthlyCost' -NotePropertyValue 'N/A (requires Cost Management API)'
    }
    return $VMs
}
function Format-OutputData {
    param(
        [object[]]$Data,
        [string]$Format
    )
    switch ($Format) {
        'JSON' {
            return ($Data | ConvertTo-Json -Depth 3)
        }
        'CSV' {
            return ($Data | ConvertTo-Csv -NoTypeInformation)
        }
        'Grid' {
            $Data | Out-GridView -Title "Azure Virtual Machines"
            return $null
        }
        default {
            # Table format with color coding
            Write-Host "`nVirtual Machines:" -ForegroundColor Cyan
            Write-Host ("=" * 100) -ForegroundColor Gray
            foreach ($vm in $Data) {
                $stateColor = switch -Wildcard ($vm.PowerState) {
                    "*running*" { 'Green' }
                    "*stopped*" { 'Red' }
                    "*deallocated*" { 'Yellow' }
                    default { 'White' }
                }
                Write-Host "VM: " -NoNewline
                Write-Host "$($vm.Name)" -NoNewline -ForegroundColor White
                Write-Host " | RG: " -NoNewline
                Write-Host "$($vm.ResourceGroup)" -NoNewline -ForegroundColor Gray
                Write-Host " | State: " -NoNewline
                Write-Host "$($vm.PowerState)" -NoNewline -ForegroundColor $stateColor
                Write-Host " | Size: " -NoNewline
                Write-Host "$($vm.Size)" -NoNewline -ForegroundColor Cyan
                Write-Host " | Location: " -NoNewline
                Write-Host "$($vm.Location)" -ForegroundColor Gray
                if ($IncludeDetails -and $vm.PrivateIP) {
                    Write-Host "    Private IP: $($vm.PrivateIP) | Public IP: $($vm.PublicIP) | Data Disks: $($vm.DataDisks)" -ForegroundColor DarkGray
                }
            }
            return $null
        }
    }
}
function Export-VMData {
    param(
        [object[]]$Data,
        [string]$Path
    )
    try {
        $extension = [System.IO.Path]::GetExtension($Path).ToLower()
        switch ($extension) {
            '.csv' {
                $Data | Export-Csv -Path $Path -NoTypeInformation -Force
            }
            '.json' {
                $Data | ConvertTo-Json -Depth 3 | Set-Content -Path $Path -Force
            }
        }
        Write-Host "Data exported to: $Path" -ForegroundColor Green
        Write-Host "File size: $([math]::Round((Get-Item $Path).Length / 1KB, 2)) KB" -ForegroundColor Gray
    }
    catch {
        Write-Error "Failed to export data: $_"
    }
}
# Main execution
Write-Host "`nAzure VM Inventory Tool" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
# Test Azure connection
$context = Test-AzureConnection
if (-not $context) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
# Set subscription context if specified
if ($SubscriptionId) {
    try {
        Write-Host "Switching to subscription: $SubscriptionId" -ForegroundColor Yellow
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        $context = Get-AzContext
    }
    catch {
        Write-Error "Failed to set subscription context: $_"
        throw
    }
}
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
Write-Host "Account: $($context.Account.Id)" -ForegroundColor Gray
try {
    # Retrieve VMs
    Write-Host "`nRetrieving Virtual Machines..." -ForegroundColor Yellow
    if ($ResourceGroupName) {
        Write-Host "Scope: Resource Group '$ResourceGroupName'" -ForegroundColor Gray
        $vms = Get-AzVM -ResourceGroupName $ResourceGroupName -Status
    } else {
        Write-Host "Scope: Entire subscription" -ForegroundColor Gray
        $vms = Get-AzVM -Status
    }
    if (-not $vms) {
        Write-Host "No virtual machines found." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Found $($vms.Count) Virtual Machine(s)" -ForegroundColor Green
    # Apply power state filter
    if ($Filter -ne 'All') {
        $originalCount = $vms.Count
        $vms = switch ($Filter) {
            'Running' { $vms | Where-Object { ($_.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus -eq 'VM running' } }
            'Stopped' { $vms | Where-Object { ($_.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus -like '*stopped*' } }
            'Deallocated' { $vms | Where-Object { ($_.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus -like '*deallocated*' } }
        }
        Write-Host "Filtered to $($vms.Count) VM(s) with state: $Filter" -ForegroundColor Cyan
    }
    if (-not $vms) {
        Write-Host "No VMs match the specified filter." -ForegroundColor Yellow
        exit 0
    }
    # Process VM information
    Write-Host "Processing VM information..." -ForegroundColor Yellow
    $vmDetails = @()
    foreach ($vm in $vms) {
        Write-Host "Processing: $($vm.Name)" -ForegroundColor Gray
        $vmInfo = Get-VMDetailedInfo -VM $vm -IncludeDetails $IncludeDetails
        $vmDetails += $vmInfo
    }
    # Sort results
    $vmDetails = switch ($SortBy) {
        'Name' { $vmDetails | Sort-Object Name }
        'ResourceGroup' { $vmDetails | Sort-Object ResourceGroup, Name }
        'PowerState' { $vmDetails | Sort-Object PowerState, Name }
        'Size' { $vmDetails | Sort-Object Size, Name }
        'Location' { $vmDetails | Sort-Object Location, Name }
        default { $vmDetails | Sort-Object Name }
    }
    # Add cost information if requested
    if ($ShowCosts) {
        $vmDetails = Get-EstimatedCosts -VMs $vmDetails
    }
    # Display results
    $output = Format-OutputData -Data $vmDetails -Format $OutputFormat
    if ($output) {
        Write-Output $output
    }
    # Export data if requested
    if ($ExportPath) {
        Export-VMData -Data $vmDetails -Path $ExportPath
    }
    # Display summary
    Write-Host "`nSummary:" -ForegroundColor Cyan
    $runningCount = ($vmDetails | Where-Object { $_.PowerState -like "*running*" }).Count
    $stoppedCount = ($vmDetails | Where-Object { $_.PowerState -like "*stopped*" -or $_.PowerState -like "*deallocated*" }).Count
    $otherCount = $vmDetails.Count - $runningCount - $stoppedCount
    Write-Host "Total VMs: $($vmDetails.Count)"
    Write-Host "Running: $runningCount" -ForegroundColor Green
    Write-Host "Stopped/Deallocated: $stoppedCount" -ForegroundColor Red
    if ($otherCount -gt 0) {
        Write-Host "Other States: $otherCount" -ForegroundColor Yellow
    }
    # Show resource group distribution
    $rgGroups = $vmDetails | Group-Object ResourceGroup | Sort-Object Count -Descending
    Write-Host "Resource Groups: $($rgGroups.Count)"
    # Show location distribution
    $locationGroups = $vmDetails | Group-Object Location | Sort-Object Count -Descending
    Write-Host "Locations: $($locationGroups.Count)"
    Write-Host "`nOperation completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to retrieve VM information: $_"
    throw
}\n