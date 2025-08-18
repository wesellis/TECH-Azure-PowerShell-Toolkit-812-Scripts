<#
.SYNOPSIS
    Azure Backup Vault Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Backup Vault Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
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
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVaultName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [string]$WEStorageType = " GeoRedundant"
)

Write-WELog " Creating Recovery Services Vault: $WEVaultName" " INFO"

; 
$WEVault = New-AzRecoveryServicesVault -ErrorAction Stop `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEVaultName `
    -Location $WELocation


Set-AzRecoveryServicesVaultContext -Vault $WEVault


Set-AzRecoveryServicesBackupProperty -ErrorAction Stop `
    -Vault $WEVault `
    -BackupStorageRedundancy $WEStorageType

Write-WELog " ✅ Recovery Services Vault created successfully:" " INFO"
Write-WELog "  Name: $($WEVault.Name)" " INFO"
Write-WELog "  Location: $($WEVault.Location)" " INFO"
Write-WELog "  Storage Type: $WEStorageType" " INFO"
Write-WELog "  Resource ID: $($WEVault.ID)" " INFO"


Write-WELog " `nDefault Backup Policies:" " INFO" ; 
$WEPolicies = Get-AzRecoveryServicesBackupProtectionPolicy -VaultId $WEVault.ID
foreach ($WEPolicy in $WEPolicies) {
    Write-WELog "  • $($WEPolicy.Name) [$($WEPolicy.WorkloadType)]" " INFO"
}

Write-WELog " `nVault Capabilities:" " INFO"
Write-WELog " • VM backup and restore" " INFO"
Write-WELog " • File and folder backup" " INFO"
Write-WELog " • SQL Server backup" " INFO"
Write-WELog " • Azure File Shares backup" " INFO"
Write-WELog " • Cross-region restore" " INFO"
Write-WELog " • Point-in-time recovery" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Configure backup policies" " INFO"
Write-WELog " 2. Enable backup for resources" " INFO"
Write-WELog " 3. Schedule backup jobs" " INFO"
Write-WELog " 4. Test restore procedures" " INFO"
Write-WELog " 5. Monitor backup status" " INFO"

Write-WELog " `nSupported Workloads:" " INFO"
Write-WELog " • Azure Virtual Machines" " INFO"
Write-WELog " • Azure File Shares" " INFO"
Write-WELog " • SQL Server in Azure VMs" " INFO"
Write-WELog " • SAP HANA in Azure VMs" " INFO"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
