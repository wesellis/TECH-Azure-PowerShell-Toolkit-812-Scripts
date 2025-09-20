#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Deploy

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
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
$managedInstanceName = $parameters['managedInstanceName']
function EnsureLogin()
{
$context = Get-AzureRmContext -ErrorAction Stop
    If($null -eq $context.Subscription)
    {
        Login-AzureRmAccount | Out-null
    }
}
[CmdletBinding()]
function VerifyPSVersion
{
    Write-Host "Verifying PowerShell version, must be 5.0 or higher."
    if($PSVersionTable.PSVersion.Major -ge 5)
    {
        Write-Host "PowerShell version verified." -ForegroundColor Green
    }
    else
    {
        Write-Host "You need to install PowerShell version 5.0 or heigher." -ForegroundColor Red
        Break;
    }
}
function VerifyManagedInstanceName
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter()]
    $managedInstanceName)
    Write-Host "Verifying Managed Instance name, must be globally unique."
    if([string]::IsNullOrEmpty($managedInstanceName))
    {
        Write-Host "Managed Instance name is required parameter." -ForegroundColor Red
        break;
    }
    if($null -ne (Resolve-DnsName ($managedInstanceName+'.provisioning.database.windows.net') -ErrorAction SilentlyContinue))
    {
        Write-Host "Managed Instance name already in use." -ForegroundColor Red
        break;
    }
    Write-Host "Managed Instance name verified." -ForegroundColor Green
}
VerifyPSVersion
VerifyManagedInstanceName $managedInstanceName
EnsureLogin
$context = Get-AzureRmContext -ErrorAction Stop
If($context.Subscription.Id -ne $subscriptionId)
{
    # select subscription
    Write-Host "Selecting subscription '$subscriptionId'" ;
    Select-AzureRmSubscription -SubscriptionId $subscriptionId  | Out-null
}
$params = @{
    KeyUsage = "CertSign"
    HashAlgorithm = "sha256"
    KeySpec = "Signature"
    Type = "Custom"
    KeyLength = "2048"
    KeyExportPolicy = "Exportable"
    Subject = "("CN=$certificateNamePrefix" +"P2SRoot" )"
    KeyUsageProperty = "Sign"
    CertStoreLocation = "Cert:\CurrentUser\My"
}
$certificate @params
$certificateThumbprint = $certificate.Thumbprint
$params = @{
    Signer = $certificate
    TextExtension = "@(" 2.5.29.37={text}1.3.6.1.5.5.7.3.2" ) | Out-null"
    HashAlgorithm = "sha256"
    KeySpec = "Signature"
    Type = "Custom"
    KeyLength = "2048"
    KeyExportPolicy = "Exportable"
    Subject = "("CN=$certificateNamePrefix" +"P2SChild" )"
    CertStoreLocation = "Cert:\CurrentUser\My"
    DnsName = "($certificateNamePrefix+"P2SChild" )"
}
New-SelfSignedCertificate @params
$publicRootCertData = [Convert]::ToBase64String((Get-Item -ErrorAction Stop cert:\currentuser\my\$certificateThumbprint).RawData)
$parameters['publicRootCertData'] = $publicRootCertData
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist." ;
    Write-Host "Creating resource group '$resourceGroupName' in location '$location'" ;
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $location | Out-null
}
else
{
    Write-Host "Using existing resource group '$resourceGroupName'" ;
}
Write-Host "Starting deployment..." ;
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri ($scriptUrlBase+'/azuredeploy.json') -TemplateParameterObject $parameters
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

