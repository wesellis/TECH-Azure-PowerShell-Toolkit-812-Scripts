#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    New Serviceprincipal

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
    We Enhanced New Serviceprincipal

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
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
	[string]$uri = " https://login.microsoft.com/rds-update-certificate-script" ,
	
	[parameter(mandatory=$true)]
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$password,

	[string]$vaultName
)

#region Functions

$app = New-AzureRmADApplication -DisplayName $appName -HomePage $uri -IdentifierUris $uri -password $pwd
; 
$sp = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId

if ($vaultName)
{
	set-azurermkeyvaultaccesspolicy -vaultname $vaultName -serviceprincipalname $sp.ApplicationId -permissionstosecrets get
}
; 
$tenantId = (get-azurermsubscription).TenantId | select -Unique



" application id:  $($app.ApplicationId)"
" tenant id:       $tenantId"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
