#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    List all Azure VMs

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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
    [string]$extension = [System.IO.Path]::GetExtension($_)
    [string]$extension -in @('.csv', '.json')
    })]
    [string]$ExportPath,
    [Parameter()]
    [switch]$ShowCosts
)
    [string]$ErrorActionPreference = 'Stop'
function Write-Log {
    try {
$context = Get-AzContext
        if (-not $context) {
            Write-Host "Connecting to Azure..." -ForegroundColor Green
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
$VmInfo = [PSCustomObject]@{
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
        try {
$VmExtended = Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
    [string]$NicCount = $VmExtended.NetworkProfile.NetworkInterfaces.Count
    [string]$PrimaryNic = if ($NicCount -gt 0) {
    [string]$NicId = $VmExtended.NetworkProfile.NetworkInterfaces[0].Id
                try {
                    Get-AzNetworkInterface | Where-Object { $_.Id -eq $NicId }
                } catch { $null }
            } else { $null }
    [string]$VmInfo | Add-Member -NotePropertyName 'NetworkInterfaces' -NotePropertyValue $NicCount
    [string]$VmInfo | Add-Member -NotePropertyName 'PrivateIP' -NotePropertyValue (
                if ($PrimaryNic) { $PrimaryNic.IpConfigurations[0].PrivateIpAddress } else { 'None' }
            )
    [string]$VmInfo | Add-Member -NotePropertyName 'PublicIP' -NotePropertyValue (
                if ($PrimaryNic -and $PrimaryNic.IpConfigurations[0].PublicIpAddress) {
                    try {
$pip = Get-AzPublicIpAddress | Where-Object { $_.Id -eq $PrimaryNic.IpConfigurations[0].PublicIpAddress.Id }
                        if ($pip) { $pip.IpAddress } else { 'None' }
                    } catch { 'None' }
                } else { 'None' }
            )
    [string]$DataDisks = $VmExtended.StorageProfile.DataDisks.Count
    [string]$VmInfo | Add-Member -NotePropertyName 'DataDisks' -NotePropertyValue $DataDisks
    [string]$VmInfo | Add-Member -NotePropertyName 'OSDiskSize' -NotePropertyValue "$($VmExtended.StorageProfile.OsDisk.DiskSizeGB) GB"
    [string]$VmInfo | Add-Member -NotePropertyName 'AvailabilitySet' -NotePropertyValue (
                if ($VmExtended.AvailabilitySetReference) {
    [string]$VmExtended.AvailabilitySetReference.Id.Split('/')[-1]
                } else { 'None' }
            )
    [string]$VmAgentStatus = ($VM.Statuses | Where-Object { $_.Code -like 'VMAgent/*' }).DisplayStatus
    [string]$VmInfo | Add-Member -NotePropertyName 'VMAgent' -NotePropertyValue ($VmAgentStatus -or 'Unknown')
    [string]$BootDiag = if ($VmExtended.DiagnosticsProfile -and $VmExtended.DiagnosticsProfile.BootDiagnostics) {
    [string]$VmExtended.DiagnosticsProfile.BootDiagnostics.Enabled
            } else { $false }
    [string]$VmInfo | Add-Member -NotePropertyName 'BootDiagnostics' -NotePropertyValue $BootDiag
        }
        catch {
            Write-Warning "Could not retrieve extended details for VM: $($VM.Name)"
        }
    }
    return $VmInfo
}
function Get-EstimatedCosts {
    param([object[]]$VMs)
    Write-Host "Retrieving cost estimates..." -ForegroundColor Green
    foreach ($vm in $VMs) {
    [string]$vm | Add-Member -NotePropertyName 'EstimatedMonthlyCost' -NotePropertyValue 'N/A (requires Cost Management API)'
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
    [string]$Data | Out-GridView -Title "Azure Virtual Machines"
            return $null
        }
        default {
            Write-Host "`nVirtual Machines:" -ForegroundColor Green
            Write-Host ("=" * 100) -ForegroundColor Gray
            foreach ($vm in $Data) {
    [string]$StateColor = switch -Wildcard ($vm.PowerState) {
                    "*running*" { 'Green' }
                    "*stopped*" { 'Red' }
                    "*deallocated*" { 'Yellow' }
                    default { 'White' }
                }
                Write-Output "VM: " -NoNewline
                Write-Output "$($vm.Name)" -NoNewline -ForegroundColor White
                Write-Output " | RG: " -NoNewline
                Write-Output "$($vm.ResourceGroup)" -NoNewline -ForegroundColor Gray
                Write-Output " | State: " -NoNewline
                Write-Output "$($vm.PowerState)" -NoNewline -ForegroundColor $StateColor
                Write-Output " | Size: " -NoNewline
                Write-Output "$($vm.Size)" -NoNewline -ForegroundColor Cyan
                Write-Output " | Location: " -NoNewline
                Write-Host "$($vm.Location)" -ForegroundColor Green
                if ($IncludeDetails -and $vm.PrivateIP) {
                    Write-Host "    Private IP: $($vm.PrivateIP) | Public IP: $($vm.PublicIP) | Data Disks: $($vm.DataDisks)" -ForegroundColor Green
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
    [string]$extension = [System.IO.Path]::GetExtension($Path).ToLower()
        switch ($extension) {
            '.csv' {
    [string]$Data | Export-Csv -Path $Path -NoTypeInformation -Force
            }
            '.json' {
    [string]$Data | ConvertTo-Json -Depth 3 | Set-Content -Path $Path -Force
            }
        }
        Write-Host "Data exported to: $Path" -ForegroundColor Green
        Write-Host "File size: $([math]::Round((Get-Item $Path).Length / 1KB, 2)) KB" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to export data: $_"
    }
}
Write-Host "`nAzure VM Inventory Tool" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
    [string]$context = Test-AzureConnection
if (-not $context) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
if ($SubscriptionId) {
    try {
        Write-Host "Switching to subscription: $SubscriptionId" -ForegroundColor Green
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
$context = Get-AzContext
    }
    catch {
        Write-Error "Failed to set subscription context: $_"
        throw
    }
}
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green
Write-Host "Account: $($context.Account.Id)" -ForegroundColor Green
try {
    Write-Host "`nRetrieving Virtual Machines..." -ForegroundColor Green
    if ($ResourceGroupName) {
        Write-Host "Scope: Resource Group '$ResourceGroupName'" -ForegroundColor Green
$vms = Get-AzVM -ResourceGroupName $ResourceGroupName -Status
    } else {
        Write-Host "Scope: Entire subscription" -ForegroundColor Green
$vms = Get-AzVM -Status
    }
    if (-not $vms) {
        Write-Host "No virtual machines found." -ForegroundColor Green
        exit 0
    }
    Write-Host "Found $($vms.Count) Virtual Machine(s)" -ForegroundColor Green
    if ($Filter -ne 'All') {
    [string]$OriginalCount = $vms.Count
    [string]$vms = switch ($Filter) {
            'Running' { $vms | Where-Object { ($_.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus -eq 'VM running' } }
            'Stopped' { $vms | Where-Object { ($_.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus -like '*stopped*' } }
            'Deallocated' { $vms | Where-Object { ($_.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus -like '*deallocated*' } }
        }
        Write-Host "Filtered to $($vms.Count) VM(s) with state: $Filter" -ForegroundColor Green
    }
    if (-not $vms) {
        Write-Host "No VMs match the specified filter." -ForegroundColor Green
        exit 0
    }
    Write-Host "Processing VM information..." -ForegroundColor Green
    [string]$VmDetails = @()
    foreach ($vm in $vms) {
        Write-Host "Processing: $($vm.Name)" -ForegroundColor Green
$VmInfo = Get-VMDetailedInfo -VM $vm -IncludeDetails $IncludeDetails
    [string]$VmDetails += $VmInfo
    }
    [string]$VmDetails = switch ($SortBy) {
        'Name' { $VmDetails | Sort-Object Name }
        'ResourceGroup' { $VmDetails | Sort-Object ResourceGroup, Name }
        'PowerState' { $VmDetails | Sort-Object PowerState, Name }
        'Size' { $VmDetails | Sort-Object Size, Name }
        'Location' { $VmDetails | Sort-Object Location, Name }
        default { $VmDetails | Sort-Object Name }
    }
    if ($ShowCosts) {
$VmDetails = Get-EstimatedCosts -VMs $VmDetails
    }
    [string]$output = Format-OutputData -Data $VmDetails -Format $OutputFormat
    if ($output) {
        Write-Output $output
    }
    if ($ExportPath) {
        Export-VMData -Data $VmDetails -Path $ExportPath
    }
    Write-Host "`nSummary:" -ForegroundColor Green
    [string]$RunningCount = ($VmDetails | Where-Object { $_.PowerState -like "*running*" }).Count
    [string]$StoppedCount = ($VmDetails | Where-Object { $_.PowerState -like "*stopped*" -or $_.PowerState -like "*deallocated*" }).Count
    [string]$OtherCount = $VmDetails.Count - $RunningCount - $StoppedCount
    Write-Output "Total VMs: $($VmDetails.Count)"
    Write-Host "Running: $RunningCount" -ForegroundColor Green
    Write-Host "Stopped/Deallocated: $StoppedCount" -ForegroundColor Green
    if ($OtherCount -gt 0) {
        Write-Host "Other States: $OtherCount" -ForegroundColor Green
    }
    [string]$RgGroups = $VmDetails | Group-Object ResourceGroup | Sort-Object Count -Descending
    Write-Output "Resource Groups: $($RgGroups.Count)"
    [string]$LocationGroups = $VmDetails | Group-Object Location | Sort-Object Count -Descending
    Write-Output "Locations: $($LocationGroups.Count)"
    Write-Host "`nOperation completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to retrieve VM information: $_"
    throw`n}
