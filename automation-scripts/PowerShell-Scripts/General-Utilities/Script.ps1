<#
.SYNOPSIS
    Script

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
    We Enhanced Script

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$appId,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$appPassword,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$tenantId,

    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$vaultName,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$secretName,

    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$adminUsername,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$adminPassword,

    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$adDomainName,

    [Parameter(ValueFromRemainingArguments = $true)]
    $extraParameters
    )

    function log
    {
        [CmdletBinding()]
$ErrorActionPreference = " Stop"
param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$message)

        " `n`n$(get-date -f o)  $message" 
    }


	log " script running..."
	whoami

  #	$WEPSBoundParameters

	if ($extraParameters) 
	{
		log " any extra parameters:"
		$extraParameters
	}

	#  requires WMF 5.0

	#  verify NuGet package
	$nuget = get-packageprovider nuget
	if (-not $nuget -or ($nuget.Version -lt 2.8.5.22))
	{
		log " installing nuget package..."
		install-packageprovider -name NuGet -minimumversion 2.8.5.201 -force
	}

	#  install AzureRM module
	#
	if (-not (get-module AzureRM))
	{
		log " installing AzureRm powershell module..."
		install-module AzureRM -force
	}


	#  log onto azure account
	#
	log " logging onto azure account with app id = $appId ..."

	$creds = new-object System.Management.Automation.PSCredential ($appId, (convertto-securestring $appPassword -asplaintext -force))
	login-azurermaccount -credential $creds -serviceprincipal -tenantid $tenantId -confirm:$false

	#  get the secret from key vault
	#
	log " getting secret '$secretName' from keyvault '$vaultName'..."
	$secret = get-azurekeyvaultsecret -vaultname $vaultName -name $secretName

	$certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection

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
	$admincreds = New-Object System.Management.Automation.PSCredential (($adminUsername + " @" + $adDomainName), (ConvertTo-SecureString $adminPassword -AsPlainText -Force))

	.\New-ImpersonateUser.ps1 -Credential $admincreds
	whoami

	#  apply certificate
	#
	$roles = @(" RDGateway" , " RDWebAccess" , " RDRedirector" , " RDPublishing" )

	$roles | % `
	{
		log " applying certificate for role: $_..."
		set-rdcertificate -role $_ -importpath $pfxFilePath -password (convertto-securestring $password -asplaintext -force) -force
	}

	log " remove impersonation..."
	Remove-ImpersonateUser
	whoami
	
	#  set client access name
	#
	$gatewayConfig = get-rddeploymentgatewayconfiguration

	if ($gatewayConfig -and $gatewayConfig.GatewayExternalFqdn)
	{
		$externalFqdn = $gatewayConfig.GatewayExternalFqdn
	; 	$externalDomainSuffix = $externalFqdn.substring($externalFqdn.IndexOf('.') + 1)

	; 	$clientAccessName = $env:COMPUTERNAME + '.' + $externalDomainSuffix

		log " setting client access name to '$clientAccessName'..."
		.\Set-RDPublishedName.ps1 -ClientAccessName $clientAccessName
	}

	#  clean up
	#  
	if (test-path($pfxFilePath))
	{
		log " running cleanup..."
		remove-item $pfxFilePath
	}

	log " done."



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
