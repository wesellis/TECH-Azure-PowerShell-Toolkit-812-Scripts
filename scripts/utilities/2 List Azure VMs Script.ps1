#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    List Azure VMs Script

.DESCRIPTION
    List Azure VMs Script operation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
[OutputType([bool])]
 -ErrorAction Stop {
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroupName
    )
    try {
        # Ensure Az.Network module is imported
        if (-not (Get-Module -Name Az.Network -ListAvailable)) {
            Write-Host "Installing Az.Network module..." -ForegroundColor Yellow
            Install-Module -Name Az.Network -Force -AllowClobber
        }
        Import-Module -Name Az.Network -ErrorAction Stop
        $vmParams = @{
            ErrorAction = 'Stop'
        }
        if ($ResourceGroupName) {
            $vmParams.ResourceGroupName = $ResourceGroupName
        }
        $vms = Get-AzVM -ErrorAction Stop @vmParams
        $vmDetails = foreach ($vm in $vms) {
            $status = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
            # Gracefully handle network interface retrieval
$privateIP = try {
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
                PrivateIP = $privateIP
                Subscription = (Get-AzContext).Subscription.Name
            }
        }
        # Generate HTML report
        New-HTML -FilePath " .\AzureVMInventory.html" -ShowHTML {
            New-HTMLTable -DataTable $vmDetails -Title "Azure VM Inventory Report" {
                New-HTMLTableHeader -Title "Azure VM Inventory - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -BackgroundColor '#007bff' -Color '#ffffff'
            }
        }
        # Export CSV report
        $vmDetails | Export-Csv -Path " .\AzureVMInventory.csv" -NoTypeInformation
        # Console output
        $vmDetails | Format-Table -AutoSize
        return $vmDetails
    }
    catch {
        Write-Error "Failed to retrieve VM details: $_"
        throw
    }
}
try {
    Write-Host "Starting Azure VM inventory..." -ForegroundColor Cyan
    # Get all VMs
    Write-Host " `nRetrieving VM details..." -ForegroundColor Yellow
$vms = Get-AzureVMDetails -ErrorAction Stop
    Write-Host " `nInventory completed successfully!" -ForegroundColor Green
    Write-Host "Total VMs found: $($vms.Count)" -ForegroundColor Green
}
catch {
    Write-Host "Error during VM inventory: $_" -ForegroundColor Red
    throw
}


