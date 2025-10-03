#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    List Azure VMs Script

.DESCRIPTION
    List Azure VMs Script operation

.AUTHOR
    Wes Ellis (wes@wesellis.com)
#>

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        $Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

function Get-AzureVMDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        $ResourceGroupName
    )

    try {
        if (-not (Get-Module -Name Az.Network -ListAvailable)) {
            Write-Host "Installing Az.Network module..." -ForegroundColor Green
            Install-Module -Name Az.Network -Force -AllowClobber
        }
        Import-Module -Name Az.Network -ErrorAction Stop

        $VmParams = @{
            ErrorAction = 'Stop'
        }
        if ($ResourceGroupName) {
            $VmParams.ResourceGroupName = $ResourceGroupName
        }

        $vms = Get-AzVM -ErrorAction Stop @vmParams
        $VmDetails = foreach ($vm in $vms) {
            $status = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
            $PrivateIP = try {
                (Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id).IpConfigurations[0].PrivateIpAddress
            } catch {
                "N/A"
            }
            [PSCustomObject]@{
                Name = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                Location = $vm.Location
                Size = $vm.HardwareProfile.VmSize
                OSType = $vm.StorageProfile.OsDisk.OsType
                Status = $status.Statuses[-1].DisplayStatus
                PrivateIP = $PrivateIP
                Subscription = (Get-AzContext).Subscription.Name
            }
        }

        New-HTML -FilePath ".\AzureVMInventory.html" -ShowHTML {
            New-HTMLTable -DataTable $VmDetails -Title "Azure VM Inventory Report" {
                New-HTMLTableHeader -Title "Azure VM Inventory - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -BackgroundColor '#007bff' -Color '#ffffff'
            }
        }

        $VmDetails | Export-Csv -Path ".\AzureVMInventory.csv" -NoTypeInformation
        $VmDetails | Format-Table -AutoSize
        return $VmDetails
    }
    catch {
        Write-Error "Failed to retrieve VM details: $_"
        throw
    }
}

try {
    Write-Host "Starting Azure VM inventory..." -ForegroundColor Green
    Write-Host "`nRetrieving VM details..." -ForegroundColor Green
    $vms = Get-AzureVMDetails -ErrorAction Stop
    Write-Host "`nInventory completed successfully!" -ForegroundColor Green
    Write-Host "Total VMs found: $($vms.Count)" -ForegroundColor Green
}
catch {
    Write-Host "Error during VM inventory: $_" -ForegroundColor Red
    throw
}