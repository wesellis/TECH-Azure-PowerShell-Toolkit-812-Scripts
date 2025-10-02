#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    New Serviceprincipal

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
	$AppName = " rds-update-certificate-script" ,
	$uri = "https://login.microsoft.com/rds-update-certificate-script" ,
	[parameter(mandatory=$true)]
	[Parameter()]
    [ValidateNotNullOrEmpty()]
    $password,
	$VaultName
)
    $app = New-AzureRmADApplication -DisplayName $AppName -HomePage $uri -IdentifierUris $uri -password $pwd
    $sp = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
if ($VaultName)
{
	set-azurermkeyvaultaccesspolicy -vaultname $VaultName -serviceprincipalname $sp.ApplicationId -permissionstosecrets get
}
    $TenantId = (get-azurermsubscription).TenantId | select -Unique
" application id:  $($app.ApplicationId)"
" tenant id:       $TenantId"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
