<#
.SYNOPSIS
    We Enhanced New Azureserviceprincipal

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


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Creates self-signed cert and associated Azure AD Azure Service Principal and Azure AD Application that allows
     Azure ARM authentication using -servicePrincipal flag.
     
     Requires AzureRM module version 4.2.1 or later.
    

.DESCRIPTION
   Along with creating the service principal and associated application ID, the script outputs a sample login script
   and the exportable PFX that contains the certificate used for authentication.  The certificate is created in the
   currentUser\My store so the authentication will work for the user where the script is executed without importing the PFX
   

.EXAMPLE
   .\New-AzureServicePrincipal.ps1 -CertYearsValid 1



.PARAMETER -CertYearsValid[int32]
  The number of years the certificate will be valid.  Defaults to 3

.PARAMETER -Environment [string]
  Name of Environment e.g. AzureUSGovernment.  Defaults to AzureCloud

.NOTES

    Original Author:   https://github.com/JeffBow

 ------------------------------------------------------------------------
               Copyright (C) 2017 Microsoft Corporation

 You have a royalty-free right to use, modify, reproduce and distribute
 this sample script (and/or any modified version) in any way
 you find useful, provided that you agree that Microsoft has no warranty,
 obligations or liability for any sample application or script files.
 ------------------------------------------------------------------------


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [int32]$WECertYearsValid= 3,
 
    [Parameter(Mandatory=$false)]
    [string]$WEEnvironment= " AzureCloud"
)

import-module AzureRM 

if ((Get-Module AzureRM).Version -lt " 4.2.1") {
   Write-warning " Old version of Azure PowerShell module  $((Get-Module AzureRM).Version.ToString()) detected.  Minimum of 4.2.1 required. Run Update-Module AzureRM"
   BREAK
}


function WE-Roll-Back 
{
 [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($thumbprint, $WEApplicationId, $servicePrincipalID)
    
    if($thumbprint) 
    {
        write-verbose " Removing self-signed cert from CurrentUser\My store" -Verbose
        ls cert:\CurrentUser\My | where{$_.Thumbprint -eq $thumbprint} | remove-item -ea SilentlyContinue
    }

    if($servicePrincipalID)
    {
        write-verbose " Removing Azure AD Service Principal with object ID of $servicePrincipalID" -Verbose
        Remove-AzureRmADServicePrincipal -ObjectId $servicePrincipalID -Force -ea SilentlyContinue
    }

    if($WEApplicationID)
    {
        write-verbose " Removing Azure AD Application with object ID of $WEApplicationID" -Verbose
        Get-AzureRmADApplication -ApplicationId $WEApplicationId | Remove-AzureRmADApplication -Force -ea SilentlyContinue
    }

} 



write-host " Enter credentials for the 'target' Azure Subscription..." -F Yellow
$login= Login-AzureRmAccount -EnvironmentName $WEEnvironment
$loginID = $login.context.account.id
$sub = Get-AzureRmSubscription 
$WESubscriptionId = $sub.Id


if($sub.count -gt 1) {
    $WESubscriptionId = (Get-AzureRmSubscription | select * | Out-GridView -title " Select Target Subscription" -OutputMode Single).Id
    Select-AzureRmSubscription -SubscriptionId $WESubscriptionId| Out-Null
    $sub = Get-AzureRmSubscription -SubscriptionId $WESubscriptionId
}


if(! $WESubscriptionId) 
{
   write-warning " The provided credentials failed to authenticate or are not associcated to a valid subscription. Exiting the script."
   break
}


$WETenantID = $sub.TenantId 

write-host " Logged into $($sub.Name) with subscriptionID $WESubscriptionId as $loginID" -f Green



do {
   ;  $WESecPassword = read-host " Enter password for the exportable self-signed certificate" -AsSecureString
    if($WESecPassword.Length -lt 1) {write-warning " Must enter secure password before proceeding. Exiting script." ; EXIT}
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($WESecPassword)) 
    $WESecConfirmPassword = read-host " Confirm password for the exportable self-signed certificate" -AsSecureString
    $confirmpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($WESecConfirmPassword)) 
}
while($WEPassword -ne $confirmpassword ) 


[string] $guid = (New-Guid).Guid
[string] $WEApplicationDisplayName = " AzureSP"+($guid.Substring(0,8))


write-verbose " Creating self-signed certificate" -Verbose

$WECurrentDate = get-date
$notAfter = $WECurrentDate.AddYears($certYearsValid)
$newCert = New-SelfSignedCertificate -DnsName " $WEApplicationDisplayName" -CertStoreLocation cert:\CurrentUser\My -NotAfter $notAfter -KeyExportPolicy Exportable -Provider " Microsoft Enhanced RSA and AES Cryptographic Provider"
$endDate = $newCert.GetExpirationDateString()
$thumbprint = $WENewCert.Thumbprint
$WEKeyValue = [System.Convert]::ToBase64String($newCert.GetRawCertData())
$WECertPath = $WEApplicationDisplayName + " .pfx"
$xport = Export-PFXCertificate -Cert $newcert -FilePath $WECertPath -Password $WESecPassword

write-verbose " Creating Azure AD Application and Service Principal" -Verbose
try
{   
    $WEKeyCredential = New-Object  Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADKeyCredential
    $WEKeyCredential.StartDate = $WECurrentDate
    $WEKeyCredential.EndDate= $endDate
    $WEKeyCredential.KeyId = $guid
    #$WEKeyCredential.Type = " AsymmetricX509Cert"
    #$WEKeyCredential.Usage = " Verify"
    $WEKeyCredential.CertValue = $WEKeyValue

    $WEApplication = New-AzureRmADApplication -DisplayName $WEApplicationDisplayName -HomePage (" http://" + $WEApplicationDisplayName) -IdentifierUris (" http://" + $guid) -KeyCredentials $keyCredential -ea Stop
    $WEApplicationId = $WEApplication.ApplicationId
    write-verbose " Azure AD Application created with application ID of $applicationID" -Verbose
    $servicePrincipal = New-AzureRMADServicePrincipal -ApplicationId $WEApplicationId -ea Stop
    $servicePrincipalID = $servicePrincipal.Id
    write-verbose  " Azure AD Service Principal created with object ID of $servicePrincipalID" -Verbose

}
catch
{
 write-error $_
 write-warning " Failed to create Azure AD Application and Service Principal'. Exiting the script" 
 roll-back -thumbprint $thumbprint -ApplicationId $WEApplicationId -servicePrincipalID $servicePrincipalID
 break
}

write-verbose " Adding Role to Service Principal $servicePrincipalID" -Verbose
$WENewRole = $null; 
$WERetries = 0;
While ($WENewRole -eq $null -and $WERetries -le 6)
{
    # Sleep here for a few seconds to allow the service principal application to become active (should only take a couple of seconds normally)
    Sleep 5
    try
    {
        New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $WEApplicationId -ea Stop | Write-Verbose 
    }
    catch
    {
        write-warning " Waiting 10 seconds for Service Principal to become active before adding Role Assignment'. Retry $WERetriest of 5"
    }
    Sleep 10
    $WENewRole = Get-AzureRMRoleAssignment -ServicePrincipalName $WEApplicationId -ErrorAction SilentlyContinue
    $WERetries++;
} 


if(! $newRole)
{
    write-warning " Failed to add role to Azure AD Service Principal'. Rolling back creation of certificate, application ID and service principal" 
    roll-back -thumbprint $thumbprint -ApplicationId $WEApplicationId -servicePrincipalID $servicePrincipalID
}
else
{
    [string]$outstring = @"
`$loginParams = @{
" CertificateThumbprint" = '$thumbprint'
" ApplicationId" = '$WEApplicationId'
" TenantId" = '$WETenantId'
" EnvironmentName" = '$WEEnvironment'
" ServicePrincipal" = `$null
}



try
{
    # Log into Azure
    Login-AzureRmAccount @loginParams -ea Stop | out-null
}
catch 
{
    if (! `$WECertificateThumbprint)
    {
        `$WEErrorMessage = " Certificate `$WECertificateThumbprint not found."
        throw `$WEErrorMessage
    } else{
        Write-Error -Message `$_.Exception
        throw `$_.Exception
    }

    break     
}


Get-AzureRmResourceGroup

" @
  
    $outstring | out-file 'Login-AzureRM.ps1'
}





# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================