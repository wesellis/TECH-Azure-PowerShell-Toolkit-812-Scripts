<#
.SYNOPSIS
    Purge Secrets

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
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
$secrets = Get-AzKeyVaultSecret -VaultName $vaultName | Where-Object{$_.ContentType -eq "Wrapped BEK" }
if($purge){
    $secrets | Remove-AzKeyVaultSecret -Force
}else {
    $secrets | Out-String
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n