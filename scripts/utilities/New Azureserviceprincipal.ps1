#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    New Azureserviceprincipal

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Creates self-signed cert and associated Azure AD Azure Service Principal and Azure AD Application that allows
     Azure ARM authentication using -servicePrincipal flag.
     Requires AzureRM module version 4.2.1 or later.
   Along with creating the service principal and associated application ID, the script outputs a sample login script
   and the exportable PFX that contains the certificate used for authentication.  The certificate is created in the
   currentUser\My store so the authentication will work for the user where the script is executed without importing the PFX
   .
ew-AzureServicePrincipal.ps1 -CertYearsValid 1
.PARAMETER -CertYearsValid[int32]
  The number of years the certificate will be valid.  Defaults to 3
.PARAMETER -Environment [string]
  Name of Environment e.g. AzureUSGovernment.  Defaults to AzureCloud
    Original Author:   https://github.com/JeffBow
 ------------------------------------------------------------------------
               Copyright (C) 2017 Microsoft Corporation
 You have a royalty-free right to use, modify, reproduce and distribute
 this sample script (and/or any modified version) in any way
 you find useful, provided that you agree that Microsoft has no warranty,
 obligations or liability for any sample application or script files.
 ------------------------------------------------------------------------
[CmdletBinding()]
param(
    [Parameter()]
    [int32]$CertYearsValid= 3,
    [Parameter()]
    [string]$Environment= "AzureCloud"
)
if ((Get-Module -ErrorAction Stop AzureRM).Version -lt " 4.2.1" ) {
   Write-warning "Old version of Azure PowerShell module  $((Get-Module -ErrorAction Stop AzureRM).Version.ToString()) detected.  Minimum of 4.2.1 required. Run Update-Module AzureRM"
   BREAK
}
function Roll-Back
{
 [CmdletBinding()]
param($thumbprint, $ApplicationId, $servicePrincipalID)
    if($thumbprint)
    {
        write-verbose "Removing self-signed cert from CurrentUser\My store" -Verbose
        ls cert:\CurrentUser\My | where{$_.Thumbprint -eq $thumbprint} | remove-item -ea SilentlyContinue
    }
    if($servicePrincipalID)
    {
        write-verbose "Removing Azure AD Service Principal with object ID of $servicePrincipalID" -Verbose
        Remove-AzureRmADServicePrincipal -ObjectId $servicePrincipalID -Force -ea SilentlyContinue
    }
    if($ApplicationID)
    {
        write-verbose "Removing Azure AD Application with object ID of $ApplicationID" -Verbose
        Get-AzureRmADApplication -ApplicationId $ApplicationId | Remove-AzureRmADApplication -Force -ea SilentlyContinue
    }
}
Write-Host "Enter credentials for the 'target' Azure Subscription..." -F Yellow
$login= Login-AzureRmAccount -EnvironmentName $Environment
$loginID = $login.context.account.id
$sub = Get-AzureRmSubscription -ErrorAction Stop
$SubscriptionId = $sub.Id
if($sub.count -gt 1) {
    $SubscriptionId = (Get-AzureRmSubscription -ErrorAction Stop | select * | Out-GridView -title "Select Target Subscription" -OutputMode Single).Id
    Select-AzureRmSubscription -SubscriptionId $SubscriptionId| Out-Null
    $sub = Get-AzureRmSubscription -SubscriptionId $SubscriptionId
}
if(! $SubscriptionId)
{
   write-warning "The provided credentials failed to authenticate or are not associcated to a valid subscription. Exiting the script."
   break
}
$TenantID = $sub.TenantId
Write-Host "Logged into $($sub.Name) with subscriptionID $SubscriptionId as $loginID" -f Green
do {
$SecPassword = read-host "Enter password for the exportable self-signed certificate" -AsSecureString
    if($SecPassword.Length -lt 1) {write-warning "Must enter secure password before proceeding. Exiting script." ; EXIT}
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecPassword))
    $SecConfirmPassword = read-host "Confirm password for the exportable self-signed certificate" -AsSecureString
    $confirmpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecConfirmPassword))
}
while($Password -ne $confirmpassword )
[string] $guid = (New-Guid).Guid
[string] $ApplicationDisplayName = "AzureSP" +($guid.Substring(0,8))
write-verbose "Creating self-signed certificate" -Verbose
$CurrentDate = get-date -ErrorAction Stop
$notAfter = $CurrentDate.AddYears($certYearsValid)
$newCert = New-SelfSignedCertificate -DnsName " $ApplicationDisplayName" -CertStoreLocation cert:\CurrentUser\My -NotAfter $notAfter -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider"
$endDate = $newCert.GetExpirationDateString()
$thumbprint = $NewCert.Thumbprint
$KeyValue = [System.Convert]::ToBase64String($newCert.GetRawCertData())
$CertPath = $ApplicationDisplayName + " .pfx"
$xport = Export-PFXCertificate -Cert $newcert -FilePath $CertPath -Password $SecPassword
write-verbose "Creating Azure AD Application and Service Principal" -Verbose
try
{
    $KeyCredential = New-Object -ErrorAction Stop  Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADKeyCredential
    $KeyCredential.StartDate = $CurrentDate
    $KeyCredential.EndDate= $endDate
    $KeyCredential.KeyId = $guid
    #$KeyCredential.Type = "AsymmetricX509Cert"
    #$KeyCredential.Usage = "Verify"
    $KeyCredential.CertValue = $KeyValue
    $Application = New-AzureRmADApplication -DisplayName $ApplicationDisplayName -HomePage (" http://" + $ApplicationDisplayName) -IdentifierUris (" http://" + $guid) -KeyCredentials $keyCredential -ea Stop
    $ApplicationId = $Application.ApplicationId
    write-verbose "Azure AD Application created with application ID of $applicationID" -Verbose
    $servicePrincipal = New-AzureRMADServicePrincipal -ApplicationId $ApplicationId -ea Stop
    $servicePrincipalID = $servicePrincipal.Id
    write-verbose  "Azure AD Service Principal created with object ID of $servicePrincipalID" -Verbose
}
catch
{
 write-error $_
 write-warning "Failed to create Azure AD Application and Service Principal'. Exiting the script"
 roll-back -thumbprint $thumbprint -ApplicationId $ApplicationId -servicePrincipalID $servicePrincipalID
 break
}
write-verbose "Adding Role to Service Principal $servicePrincipalID" -Verbose;
$NewRole = $null;
$Retries = 0;
While ($null -eq $NewRole -and $Retries -le 6)
{
    # Sleep here for a few seconds to allow the service principal application to become active (should only take a couple of seconds normally)
    Sleep 5
    try
    {
        New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $ApplicationId -ea Stop | Write-Verbose
    }
    catch
    {
        write-warning "Waiting 10 seconds for Service Principal to become active before adding Role Assignment'. Retry $Retriest of 5"
    }
    Sleep 10
    $NewRole = Get-AzureRMRoleAssignment -ServicePrincipalName $ApplicationId -ErrorAction SilentlyContinue
    $Retries++;
}
if(! $newRole)
{
    write-warning "Failed to add role to Azure AD Service Principal'. Rolling back creation of certificate, application ID and service principal"
    roll-back -thumbprint $thumbprint -ApplicationId $ApplicationId -servicePrincipalID $servicePrincipalID
}
else
{
    [string]$outstring = @"
`$loginParams = @{
"CertificateThumbprint" = '$thumbprint'
"ApplicationId" = '$ApplicationId'
"TenantId" = '$TenantId'
"EnvironmentName" = '$Environment'
"ServicePrincipal" = `$null
}
try
{
    # Log into Azure
    Login-AzureRmAccount @loginParams -ea Stop | out-null
}
catch
{
    if (! `$CertificateThumbprint)
    {
        `$ErrorMessage = "Certificate `$CertificateThumbprint not found."
        throw `$ErrorMessage
    } else{
        Write-Error -Message `$_.Exception
        throw `$_.Exception
    }
    break
}
Get-AzureRmResourceGroup -ErrorAction Stop
" @
    $outstring | out-file 'Login-AzureRM.ps1'
}


