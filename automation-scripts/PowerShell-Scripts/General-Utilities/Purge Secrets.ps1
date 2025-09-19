#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Purge Secrets

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
    We Enhanced Purge Secrets

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

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

#region Functions
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


#endregion
