#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Script

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $AppId,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $AppPassword,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $TenantId,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $VaultName,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SecretName,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $AdminUsername,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $AdminPassword,
    [parameter(mandatory = $true)][ValidateNotNullOrEmpty()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $AdDomainName,
    [Parameter(ValueFromRemainingArguments = $true)]
    $ExtraParameters
    )
    function log
    {
        param([Parameter()]
    [ValidateNotNullOrEmpty()]
    $message)
        " `n`n$(get-date -f o)  $message"
    }
	log " script running..."
	whoami
	if ($ExtraParameters)
	{
		log " any extra parameters:"
    $ExtraParameters
	}
    $nuget = get-packageprovider -ErrorAction Stop nuget
	if (-not $nuget -or ($nuget.Version -lt 2.8.5.22))
	{
		log " installing nuget package..."
		install-packageprovider -name NuGet -minimumversion 2.8.5.201 -force
	}
	if (-not (get-module -ErrorAction Stop AzureRM))
	{
		log " installing AzureRm powershell module..."
		install-module AzureRM -force
	}
	log " logging onto azure account with app id = $AppId ..."
    $creds = new-object -ErrorAction Stop System.Management.Automation.PSCredential ($AppId, (convertto-securestring $AppPassword -asplaintext -force))
	login-azurermaccount -credential $creds -serviceprincipal -tenantid $TenantId -confirm:$false
	log " getting secret '$SecretName' from keyvault '$VaultName'..."
    $secret = get-azurekeyvaultsecret -vaultname $VaultName -name $SecretName
    $CertCollection = New-Object -ErrorAction Stop System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $bytes = [System.Convert]::FromBase64String($secret.SecretValueText)
    $CertCollection.Import($bytes, $null, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
	add-type -AssemblyName System.Web
    $password = [System.Web.Security.Membership]::GeneratePassword(38,5)
    $ProtectedCertificateBytes = $CertCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $password)
    $PfxFilePath = join-path $env:TEMP " $([guid]::NewGuid()).pfx"
	log " writing the cert as '$PfxFilePath'..."
	[io.file]::WriteAllBytes($PfxFilePath, $ProtectedCertificateBytes)
	ipmo remotedesktop -DisableNameChecking
	log " impersonating as '$AdminUsername'..."
    $admincreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (($AdminUsername + " @" + $AdDomainName), (Read-Host -Prompt "Enter secure value" -AsSecureString))
	.
ew-ImpersonateUser.ps1 -Credential $admincreds
	whoami
    $roles = @("RDGateway" , "RDWebAccess" , "RDRedirector" , "RDPublishing" )
    $params = @{
	    force = "}"
	    role = $_
	    # Use Get-Credential for secure password input
	    importpath = $PfxFilePath
	}
    $roles @params
	log " remove impersonation..."
	Remove-ImpersonateUser -ErrorAction Stop
	whoami
    $GatewayConfig = get-rddeploymentgatewayconfiguration -ErrorAction Stop
	if ($GatewayConfig -and $GatewayConfig.GatewayExternalFqdn)
	{
    $ExternalFqdn = $GatewayConfig.GatewayExternalFqdn
    $ExternalDomainSuffix = $ExternalFqdn.substring($ExternalFqdn.IndexOf('.') + 1)
    $ClientAccessName = $env:COMPUTERNAME + '.' + $ExternalDomainSuffix
		log " setting client access name to '$ClientAccessName'..."
		.\Set-RDPublishedName.ps1 -ClientAccessName $ClientAccessName
	}
	if (test-path($PfxFilePath))
	{
		log " running cleanup..."
		remove-item -ErrorAction Stop $PfxFilePath
	}
	log " done."
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
