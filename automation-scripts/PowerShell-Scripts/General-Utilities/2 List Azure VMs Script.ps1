#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    2 List Azure Vms Script

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
    We Enhanced 2 List Azure Vms Script

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
function WE-Get-AzureVMDetails -ErrorAction Stop {
    

[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory = $false)]
        [string]$WEResourceGroupName
    )

    try {
        # Ensure Az.Network module is imported
        if (-not (Get-Module -Name Az.Network -ListAvailable)) {
            Write-WELog " Installing Az.Network module..." " INFO" -ForegroundColor Yellow
            Install-Module -Name Az.Network -Force -AllowClobber
        }
        Import-Module -Name Az.Network -ErrorAction Stop

        $vmParams = @{
            ErrorAction = 'Stop'
        }

        if ($WEResourceGroupName) {
            $vmParams.ResourceGroupName = $WEResourceGroupName
        }

        $vms = Get-AzVM -ErrorAction Stop @vmParams

        $vmDetails = foreach ($vm in $vms) {
            $status = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
            # Gracefully handle network interface retrieval
           ;  $privateIP = try {
                (Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id).IpConfigurations[0].PrivateIpAddress
            } catch {
                " N/A"
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
            New-HTMLTable -DataTable $vmDetails -Title " Azure VM Inventory Report" {
                New-HTMLTableHeader -Title " Azure VM Inventory - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -BackgroundColor '#007bff' -Color '#ffffff'
            }
        }

        # Export CSV report
        $vmDetails | Export-Csv -Path " .\AzureVMInventory.csv" -NoTypeInformation

        # Console output
        $vmDetails | Format-Table -AutoSize

        return $vmDetails
    }
    catch {
        Write-Error " Failed to retrieve VM details: $_"
        throw
    }
}


try {
    Write-WELog " Starting Azure VM inventory..." " INFO" -ForegroundColor Cyan
    
    # Get all VMs
    Write-WELog " `nRetrieving VM details..." " INFO" -ForegroundColor Yellow
   ;  $vms = Get-AzureVMDetails -ErrorAction Stop
    
    Write-WELog " `nInventory completed successfully!" " INFO" -ForegroundColor Green
    Write-WELog " Total VMs found: $($vms.Count)" " INFO" -ForegroundColor Green
}
catch {
    Write-WELog " Error during VM inventory: $_" " INFO" -ForegroundColor Red
    throw
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
