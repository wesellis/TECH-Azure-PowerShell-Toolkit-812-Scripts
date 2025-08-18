<#
.SYNOPSIS
    Purge Secrets

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
    We Enhanced Purge Secrets

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string];  $vaultName = " azbotvault" , # name of the vault azbotvaultus for FF
    [switch] $purge
)
; 
$secrets = Get-AzKeyVaultSecret -VaultName $vaultName | Where-Object{$_.ContentType -eq " Wrapped BEK" }

if($purge){
    $secrets | Remove-AzKeyVaultSecret -Force
}else {
    $secrets | Out-String
}

 


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
