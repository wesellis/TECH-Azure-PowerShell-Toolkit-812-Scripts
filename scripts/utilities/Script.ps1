#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Script

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
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
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$appId,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$appPassword,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$tenantId,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$vaultName,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$secretName,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$adminUsername,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$adminPassword,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$adDomainName,
    [Parameter(ValueFromRemainingArguments = $true)]
    $extraParameters
    )
    [CmdletBinding()]
function log
    {
        [CmdletBinding()]
param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$message)
        " `n`n$(get-date -f o)  $message"
    }
	log " script running..."
	whoami
  #	$PSBoundParameters
	if ($extraParameters)
	{
		log " any extra parameters:"
		$extraParameters
	}
	#  requires WMF 5.0
	#  verify NuGet package
	$nuget = get-packageprovider -ErrorAction Stop nuget
	if (-not $nuget -or ($nuget.Version -lt 2.8.5.22))
	{
		log " installing nuget package..."
		install-packageprovider -name NuGet -minimumversion 2.8.5.201 -force
	}
	#  install AzureRM module
	#
	if (-not (get-module -ErrorAction Stop AzureRM))
	{
		log " installing AzureRm powershell module..."
		install-module AzureRM -force
	}
	#  log onto azure account
	#
	log " logging onto azure account with app id = $appId ..."
	$creds = new-object -ErrorAction Stop System.Management.Automation.PSCredential ($appId, (convertto-securestring $appPassword -asplaintext -force))
	login-azurermaccount -credential $creds -serviceprincipal -tenantid $tenantId -confirm:$false
	#  get the secret from key vault
	#
	log " getting secret '$secretName' from keyvault '$vaultName'..."
	$secret = get-azurekeyvaultsecret -vaultname $vaultName -name $secretName
	$certCollection = New-Object -ErrorAction Stop System.Security.Cryptography.X509Certificates.X509Certificate2Collection
	$bytes = [System.Convert]::FromBase64String($secret.SecretValueText)
	$certCollection.Import($bytes, $null, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
	add-type -AssemblyName System.Web
	$password = [System.Web.Security.Membership]::GeneratePassword(38,5)
	$protectedCertificateBytes = $certCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $password)
	$pfxFilePath = join-path $env:TEMP " $([guid]::NewGuid()).pfx"
	log " writing the cert as '$pfxFilePath'..."
	[io.file]::WriteAllBytes($pfxFilePath, $protectedCertificateBytes)
	#  apply certificate
	#
	ipmo remotedesktop -DisableNameChecking
	#  impersonate as admin
	#
	log " impersonating as '$adminUsername'..."
	$admincreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (($adminUsername + " @" + $adDomainName), (Read-Host -Prompt "Enter secure value" -AsSecureString))
	.
ew-ImpersonateUser.ps1 -Credential $admincreds
	whoami
	#  apply certificate
	#
	$roles = @("RDGateway" , "RDWebAccess" , "RDRedirector" , "RDPublishing" )
	$params = @{
	    force = "}"
	    role = $_
	    password = "(convertto-securestring $password"
	    importpath = $pfxFilePath
	}
	$roles @params
	log " remove impersonation..."
	Remove-ImpersonateUser -ErrorAction Stop
	whoami
	#  set client access name
	#
	$gatewayConfig = get-rddeploymentgatewayconfiguration -ErrorAction Stop
	if ($gatewayConfig -and $gatewayConfig.GatewayExternalFqdn)
	{
		$externalFqdn = $gatewayConfig.GatewayExternalFqdn
$externalDomainSuffix = $externalFqdn.substring($externalFqdn.IndexOf('.') + 1)
$clientAccessName = $env:COMPUTERNAME + '.' + $externalDomainSuffix
		log " setting client access name to '$clientAccessName'..."
		.\Set-RDPublishedName.ps1 -ClientAccessName $clientAccessName
	}
	#  clean up
	#
	if (test-path($pfxFilePath))
	{
		log " running cleanup..."
		remove-item -ErrorAction Stop $pfxFilePath
	}
	log " done."
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


