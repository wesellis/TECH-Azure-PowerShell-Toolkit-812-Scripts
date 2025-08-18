<#
.SYNOPSIS
    Deploy

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
    We Enhanced Deploy

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$parameters = $args[0]
$scriptUrlBase = $args[1]

$subscriptionId = $parameters['subscriptionId']
$resourceGroupName = $parameters['resourceGroupName']
$certificateNamePrefix = $parameters['certificateNamePrefix']
$location = $parameters['location']

$parameters.Remove('subscriptionId')
try {
    # Main script execution
$parameters.Remove('resourceGroupName')
$parameters.Remove('certificateNamePrefix')
; 
$managedInstanceName = $parameters['managedInstanceName']

function WE-EnsureLogin() 
{
   ;  $context = Get-AzureRmContext -ErrorAction Stop
    If($null -eq $context.Subscription)
    {
        Login-AzureRmAccount | Out-null
    }
}

[CmdletBinding()]
function WE-VerifyPSVersion
{
    Write-WELog "Verifying PowerShell version, must be 5.0 or higher." " INFO"
    if($WEPSVersionTable.PSVersion.Major -ge 5)
    {
        Write-WELog " PowerShell version verified." " INFO" -ForegroundColor Green
    }
    else
    {
        Write-WELog " You need to install PowerShell version 5.0 or heigher." " INFO" -ForegroundColor Red
        Break;
    }
}

[CmdletBinding()]
function WE-VerifyManagedInstanceName
{
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($managedInstanceName)
    Write-WELog " Verifying Managed Instance name, must be globally unique." " INFO"
    if([string]::IsNullOrEmpty($managedInstanceName))
    {
        Write-WELog " Managed Instance name is required parameter." " INFO" -ForegroundColor Red
        break;
    }
    if($null -ne (Resolve-DnsName ($managedInstanceName+'.provisioning.database.windows.net') -ErrorAction SilentlyContinue))
    {
        Write-WELog " Managed Instance name already in use." " INFO" -ForegroundColor Red
        break;
    }
    Write-WELog " Managed Instance name verified." " INFO" -ForegroundColor Green
}

VerifyPSVersion
VerifyManagedInstanceName $managedInstanceName

EnsureLogin

$context = Get-AzureRmContext -ErrorAction Stop
If($context.Subscription.Id -ne $subscriptionId)
{
    # select subscription
    Write-WELog " Selecting subscription '$subscriptionId'" " INFO" ;
    Select-AzureRmSubscription -SubscriptionId $subscriptionId  | Out-null
}

$certificate = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
    -Subject (" CN=$certificateNamePrefix" +" P2SRoot" ) -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation " Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

$certificateThumbprint = $certificate.Thumbprint

New-SelfSignedCertificate -Type Custom -DnsName ($certificateNamePrefix+" P2SChild" ) -KeySpec Signature `
    -Subject (" CN=$certificateNamePrefix" +" P2SChild" ) -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation " Cert:\CurrentUser\My" `
    -Signer $certificate -TextExtension @(" 2.5.29.37={text}1.3.6.1.5.5.7.3.2" ) | Out-null
; 
$publicRootCertData = [Convert]::ToBase64String((Get-Item -ErrorAction Stop cert:\currentuser\my\$certificateThumbprint).RawData)

$parameters['publicRootCertData'] = $publicRootCertData

; 
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-WELog " Resource group '$resourceGroupName' does not exist." " INFO" ;
    Write-WELog " Creating resource group '$resourceGroupName' in location '$location'" " INFO" ;
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location | Out-null
}
else
{
    Write-WELog " Using existing resource group '$resourceGroupName'" " INFO" ;
}



Write-WELog " Starting deployment..." " INFO" ;

New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri ($scriptUrlBase+'/azuredeploy.json') -TemplateParameterObject $parameters



} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
