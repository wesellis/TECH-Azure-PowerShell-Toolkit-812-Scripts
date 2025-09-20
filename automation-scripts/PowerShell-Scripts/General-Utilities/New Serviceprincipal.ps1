<#
.SYNOPSIS
    New Serviceprincipal

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[cmdletbinding()
try {
    # Main script execution
]
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
	[string]$appName = " rds-update-certificate-script" ,
	# has to be a valid format URI; URI's not validated for single-tenant application
	[string]$uri = "https://login.microsoft.com/rds-update-certificate-script" ,
	[parameter(mandatory=$true)]
	[Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$password,
	[string]$vaultName
)
$app = New-AzureRmADApplication -DisplayName $appName -HomePage $uri -IdentifierUris $uri -password $pwd
$sp = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
if ($vaultName)
{
	set-azurermkeyvaultaccesspolicy -vaultname $vaultName -serviceprincipalname $sp.ApplicationId -permissionstosecrets get
}
$tenantId = (get-azurermsubscription).TenantId | select -Unique
" application id:  $($app.ApplicationId)"
" tenant id:       $tenantId"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n