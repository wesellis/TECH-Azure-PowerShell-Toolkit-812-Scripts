<#
.SYNOPSIS
    We Enhanced Create Gen Artifacts

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
Use this script to create the GEN artifacts needed by the pipeline to test templates.  


The Crypto module (PKI)
try {
    # Main script execution
is not supported on PS Core so this is using older AzureRM modules.


Be sure to set the appropriate Context before running the script



[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string] $WEResourceGroupName = 'ttk-gen-artifacts',
    [string] [Parameter(mandatory = $true)] $WELocation, #The location where resources will be deployed in the pipeline, in many cases they need to be in the same region.
    [string] $WEKeyVaultName = 'azbotvault', # This must be gloablly unique
    [string] $WECertPass = $("cI#" + (New-Guid).ToString().Replace(" -", "" ).Substring(0, 17)),
    [string] $WECertDNSName = 'azbot-cert-dns',
    [string] $WEKeyVaultSelfSignedCertName = 'azbot-sscert',
    [string] $WEKeyVaultNotSecretName = 'notSecretPassword',
    [string] $WEServicePrincipalObjectId, #if not provided assigning perms to the Vault must be done manually
    [string] $appConfigStoreName = 'azbotappconfigstore', # This must be gloablly unique
    [string] $msiName = 'azbot-msi',
    #
    # You must generate a public/private key pair and pass to the script use the following command with no passphrase:
    #   ssh-keygen -t rsa -b 4096 -f scratch
    # 
    [string] $sshPublicKeyValue = $(Get-Content -Path scratch.pub -Raw),
    [string] $sshPrivateKeyValue = $(Get-Content -Path scratch -Raw)

)


if ((Get-AzureRMResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -ErrorAction SilentlyContinue) -eq $null) {
    New-AzureRMResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -Force
}


$WEStorageAccountName = 'stage' + ((Get-AzureRmContext).Subscription.Id).Replace('-', '').substring(0, 19)
$WEStorageAccount = (Get-AzureRmStorageAccount | Where-Object { $_.StorageAccountName -eq $WEStorageAccountName })

if ($WEStorageAccount -eq $null) {
    $WEStorageResourceGroupName = 'ARM_Deploy_Staging'
    New-AzureRmResourceGroup -Location "$WELocation" -Name $WEStorageResourceGroupName -Force
    $WEStorageAccount = New-AzureRmStorageAccount -StorageAccountName $WEStorageAccountName -Type 'Standard_LRS' -ResourceGroupName $WEStorageResourceGroupName -Location " $WELocation"
}


$msi = (az identity create -g " $WEResourceGroupName" -n " $msiName" --verbose) | ConvertFrom-Json

$json.Add(" USER-ASSIGNED-IDENTITY-NAME", $msiName)
$json.Add(" USER-ASSIGNED-IDENTITY-RESOURCEGROUP-NAME", $WEResourceGroupName)


if ($WEServicePrincipalObjectId) {
    # to be able to write to the staging storage account (deployment script stages artifacts)
    $roleDef = Get-AzureRmRoleDefinition -Name 'Contributor'
    New-AzureRMRoleAssignment -RoleDefinitionId $roleDef.id -ObjectId $WEServicePrincipalObjectId -Scope $WEStorageAccount.Id -Verbose
    # to use the MSI on a resource (the msi should have very limited permissions)
    $roleDef = Get-AzureRmRoleDefinition -Name 'Managed Identity Operator'
    $msiId = " /subscriptions/$((Get-AzureRMContext).Subscription.Id)/resourceGroups/$WEResourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$msiName"
    New-AzureRMRoleAssignment -RoleDefinitionId $roleDef.id -ObjectId $WEServicePrincipalObjectId -Scope $msiId -Verbose
}



$subnet1 = New-AzureRMVirtualNetworkSubnetConfig -Name 'azbot-subnet-1' -AddressPrefix '10.0.1.0/24'
$subnet2 = New-AzureRMVirtualNetworkSubnetConfig -Name 'azbot-subnet-2' -AddressPrefix '10.0.2.0/24'
$vNet = New-AzureRMVirtualNetwork -ResourceGroupName $WEResourceGroupName -Name 'azbot-vnet' -AddressPrefix '10.0.0.0/16' -Location $location -Subnet $subnet1, $subnet2 -Verbose -Force

$json = New-Object System.Collections.Specialized.OrderedDictionary #This keeps things in the order we entered them, instead of: New-Object -TypeName Hashtable
$json.Add(" VNET-RESOURCEGROUP-NAME", $vNet.ResourceGroupName)
$json.Add(" VNET-NAME", $vNet.Name)
$json.Add(" VNET-SUBNET1-NAME", $vNet.Subnets[0].Name)
$json.Add(" VNET-SUBNET2-NAME", $vNet.Subnets[1].Name)

<#
Creat a KeyVault and add:
    0) The principal deploying templates will need access to the vault (if needed for vm deployments)
    1) Sample Password
    2) Service Fabric Cert
    3) Disk Encryption Key
    4) SSL Cert Secret
    5) Self-Signed Cert


$vault = Get-AzureRMKeyVault -VaultName $WEKeyVaultName -verbose -ErrorAction SilentlyContinue
if ($vault -eq $null) {
    $vault = New-AzureRMKeyVault -VaultName $WEKeyVaultName `
                                 -ResourceGroupName $WEResourceGroupName `
                                 -Location $WELocation `
                                 -EnabledForTemplateDeployment `
                                 -EnabledForDiskEncryption `
                                 -EnabledForDeployment `
                                 -EnableSoftDelete `
                                 -Verbose
}




$appConfigStore = $(az appconfig create -g appconfig -n bjmappconf1 -l westus -o json --verbose) | ConvertFrom-Json

if ($WEServicePrincipalObjectId) {

    # See if the roleDef already exists
    $role = Get-AzureRmRoleDefinition -Name " KeyVault Deployment Action"

    if ($role -eq $null) {
        $roleDef = New-Object -TypeName " Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition"

        $roleDef.Id = $null
        $roleDef.Name = " KeyVault Deployment Action"
        $roleDef.Description = " KeyVault Deploy Action for Template Reference Parameter Use"
        $roleDef.Actions = @(" Microsoft.KeyVault/vaults/deploy/action")
        $roleDef.AssignableScopes = @(" /subscriptions/$((Get-AzureRMContext).Subscription.Id)")

        $roleDef | Out-String

        $role = New-AzureRMRoleDefinition -Role $roleDef -Verbose
    }

    New-AzureRMRoleAssignment -RoleDefinitionId $role.Id -ObjectId $WEServicePrincipalObjectId -Scope $vault.ResourceId -Verbose

    # SP needs perms to join the existing vnet

    # See if the roleDef already exists
    $role = Get-AzureRmRoleDefinition -Name " Join Subnets"

    if ($role -eq $null) {
        $roleDef.Id = $null
        $roleDef.Name = " Join Subnets"
        $roleDef.Description = " Join a VM to a subnet"
        $roleDef.Actions = @(" Microsoft.Network/virtualNetworks/subnets/join/action")
        $roleDef.AssignableScopes = @(" /subscriptions/$((Get-AzureRMContext).Subscription.Id)")

        $roleDef | Out-String

        $role = New-AzureRMRoleDefinition -Role $roleDef -Verbose
    }
    
    $scope = " /subscriptions/$((Get-AzureRMContext).Subscription.Id)/resourceGroups/$WEResourceGroupName"
    New-AzureRMRoleAssignment -RoleDefinitionId $role.Id -ObjectId $WEServicePrincipalObjectId -Scope $scope -Verbose


    # Need contributor access to be able to add secrets during a template deployment
    $roleDef = Get-AzureRmRoleDefinition -Name 'Contributor'

    # Need contributor rights on vault to run pull reference params - some samples also add secrets
    New-AzureRMRoleAssignment -RoleDefinitionId $roleDef.id -ObjectId $WEServicePrincipalObjectId -Scope $vault.ResourceId -Verbose

    # Need contributor rights on config store to run list*() actions
    New-AzureRMRoleAssignment -RoleDefinitionId $roleDef.id -ObjectId $WEServicePrincipalObjectId -Scope $appConfigStore.id -Verbose

    # Set the Data Plane Access Policy for the Principal to retrieve secrets via reference parameters
    Set-AzureRMKeyVaultAccessPolicy -VaultName $WEKeyVaultName 
                                    -ObjectId $WEServicePrincipalObjectId `
                                    -PermissionsToKeys get, restore `
                                    -PermissionsToSecrets get, set `
                                    -PermissionsToCertificates get

    # Set the Data Plane Access Policy for the UserAssigned MSI to retrieve secrets via reference parameters
    Set-AzureRMKeyVaultAccessPolicy -VaultName $WEKeyVaultName
                                    -ObjectId $msi.principalId `
                                    -PermissionsToKeys get `
                                    -PermissionsToSecrets get `
                                    -PermissionsToCertificates get

    # Assign the SP perms to the NetworkWatcherRG for deploying flowlogs
    New-AzureRMRoleAssignment -RoleDefinitionId 'b24988ac-6180-42a0-ab88-20f7382dd24c' `
                              -ObjectId $WEServicePrincipalObjectId `
                              -Scope $(Get-AzureRmResourceGroup -Name 'NetworkWatcherRG').ResourceId `
                              -Verbose
                              
    # TODO - Add the " Cognitive Services Contributor" role 25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68 to be able to deploy CS

}


$mlsp = Get-AzureRmADServicePrincipal -ServicePrincipalName '0736f41a-0425-4b46-bdb5-1563eff02385' #-DisplayName " Azure Machine Learning"
$roleDef = Get-AzureRmRoleDefinition -Name 'Contributor'
New-AzureRMRoleAssignment -RoleDefinitionId $roleDef.id -ObjectId $mlsp.id -Scope " /subscriptions/$((Get-AzureRMContext).Subscription.Id)" -Verbose
$json.Add(" MACHINE-LEARNING-SP-OBJECTID", $mlsp.id)

$cosmossp = Get-AzureRmADServicePrincipal -ServicePrincipalName " a232010e-820c-4083-83bb-3ace5fc29d0b" # -DisplayName " Azure Cosmos DB"
Set-AzureRMKeyVaultAccessPolicy -VaultName $WEKeyVaultName -ObjectId $cosmossp.id -PermissionsToKeys get, unwrapKey, wrapKey 
$json.Add(" COSMOS-DB-SP-OBJECTID", $cosmossp.id)

$webapp = Get-AzureRmADServicePrincipal -ServicePrincipalName " abfa0a7c-a6b6-4736-8310-5855508787cd" # Web App SP for certificate scenarios - not available in Fairfax?
Set-AzureRMKeyVaultAccessPolicy -VaultName $WEKeyVaultName -ObjectId $webapp.id -PermissionsToSecrets get 


$cdn = New-AzureRmADServicePrincipal -ApplicationId 205478c0-bd83-4e1b-a9d6-db63a3e1e1c8

Set-AzureRMKeyVaultAccessPolicy -VaultName $WEKeyVaultName -ObjectId $cdn.id -PermissionsToSecrets get 


$frontDoor = New-AzureRmADServicePrincipal -ApplicationId 'ad0e1c7e-6d38-4ba4-9efd-0bc77ba9f037'

Set-AzureRMKeyVaultAccessPolicy -VaultName $WEKeyVaultName -ObjectId $frontDoor.id -PermissionsToSecrets get -PermissionsToCertificates get


$WESecretValue = ConvertTo-SecureString -String $WECertPass -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $WEKeyVaultName -Name $WEKeyVaultNotSecretName -SecretValue $WESecretValue -Verbose

$json.Add(" KEYVAULT-NAME", $vault.VaultName)
$json.Add(" KEYVAULT-RESOURCEGROUP-NAME", $vault.ResourceGroupName)
$json.Add(" KEYVAULT-PASSWORD-SECRET-NAME", $WEKeyVaultNotSecretName)
$json.Add(" KEYVAULT-SUBSCRIPTION-ID", $vault.ResourceId.Split('/')[2])
$json.Add(" KEYVAULT-RESOURCE-ID", $vault.ResourceId)

$refParam = @"
{
    " reference": {
        " keyVault": {
        " id": " $($vault.ResourceId)"
        },
        " secretName": " $WEKeyVaultNotSecretName"
    }
}
" @

$json.Add("KEYVAULT-PASSWORD-REFERENCE" , (ConvertFrom-Json $refParam))


$WESecurePassword = ConvertTo-SecureString -String $WECertPass -AsPlainText -Force
$WECertFileFullPath = $(Join-Path (Split-Path -Parent $WEMyInvocation.MyCommand.Definition) "\$WECertDNSName.pfx" )

if ($(Get-Module 'PKI') -eq $null) { Import-Module "PKI" -SkipEditionCheck -Verbose }
$WENewCert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -DnsName $WECertDNSName -NotAfter (Get-Date).AddYears(10)
Export-PfxCertificate -FilePath $WECertFileFullPath -Password $WESecurePassword -Cert $WENewCert

$WEBytes = [System.IO.File]::ReadAllBytes($WECertFileFullPath)
$WEBase64 = [System.Convert]::ToBase64String($WEBytes)

$WEJSONBlob = @{
    data = $WEBase64
    dataType = 'pfx'
    password = $WECertPass
} | ConvertTo-Json

$WEContentBytes = [System.Text.Encoding]::UTF8.GetBytes($WEJSONBlob)
$WEContent = [System.Convert]::ToBase64String($WEContentBytes)

$WESFSecretValue = ConvertTo-SecureString -String $WEContent -AsPlainText -Force
$WENewSecret = Set-AzureKeyVaultSecret -VaultName $WEKeyVaultName -Name " azbot-sf-cert" -SecretValue $WESFSecretValue -Verbose

$json.Add(" SF-CERT-URL", $WENewSecret.Id) #need to verify this one, it should be the secret uri
$json.Add(" SF-CERT-THUMBPRINT", $WENewCert.Thumbprint)


$key = Add-AzureKeyVaultKey -VaultName $keyVaultName -Name " azbot-diskkey" -Destination " Software"

$json.Add(" KEYVAULT-ENCRYPTION-KEY", $key.Name)
$json.Add(" KEYVAULT-ENCRYPTION-KEY-URI", $key.id)
$json.Add(" KEYVAULT-ENCRYPTION-KEY-VERSION", $key.Version)


$sshPublicKeySecretName = " sshPublicKey"
$sshPrivateKeySecretName = " sshPrivateKey"


$json.Add(" SSH-PUB-KEY", $sshPublicKeyValue)

$sshPublicKeyValue = ConvertTo-SecureString -String (Get-Content -Path scratch.pub -Raw) -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $WEKeyVaultName -Name $sshPublicKeySecretName -SecretValue $sshPublicKeyValue -Verbose

$sshPrivateKeyValue = ConvertTo-SecureString -String (Get-Content -Path scratch -Raw) -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $WEKeyVaultName -Name $sshPrivateKeySecretName -SecretValue $sshPrivateKeyValue -Verbose

$json.Add(" KEYVAULT-SSH-PRIVATE-KEY-NAME", $sshPrivateKeySecretName)
$json.Add(" KEYVAULT-SSH-PUBLIC-KEY-NAME", $sshPublicKeySecretName)

$refParam = @"
{
    " reference": {
        " keyVault": {
        " id": " $($vault.ResourceId)"
        },
        " secretName": " $sshPrivateKeySecretName"
    }
}
" @
$json.Add("KEYVAULT-SSH-PRIVATE-KEY-REFERENCE" , (ConvertFrom-Json $refParam))

$refParam = @"
{
    " reference": {
        " keyVault": {
        " id": " $($vault.ResourceId)"
        },
        " secretName": " $sshPublicKeySecretName"
    }
}
" @
$json.Add("KEYVAULT-SSH-PUBLIC-KEY-REFERENCE" , (ConvertFrom-Json $refParam))





$pfxFileFullPath = $(Join-Path (Split-Path -Parent $WEMyInvocation.MyCommand.Definition) "\$WECertDNSName.pfx" )
$cerFileFullPath = $(Join-Path (Split-Path -Parent $WEMyInvocation.MyCommand.Definition) "\$WECertDNSName.cer" )

Export-PfxCertificate -Cert $WENewCert -FilePath "$pfxFileFullPath" -Password $(ConvertTo-SecureString -String $WECertPass -Force -AsPlainText)
Export-Certificate -Cert $WENewCert -FilePath " $cerFileFullPath"

$kvCert = Import-AzureKeyVaultCertificate -VaultName $WEKeyVaultName -Name " azbot-ssl-cert" -FilePath $pfxFileFullPath -Password $(ConvertTo-SecureString -String $WECertPass -Force -AsPlainText)

$json.Add(" KEYVAULT-SSL-SECRET-NAME", $kvCert.Name)
$json.Add(" KEYVAULT-SSL-SECRET-URI", $kvCert.Id)
$json.Add(" SELFSIGNED-CERT-PFXDATA", [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes(" $pfxFileFullPath")))
$json.Add(" SELFSIGNED-CERT-CERDATA", [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes(" $cerFileFullPath")))
$json.Add(" SELFSIGNED-CERT-PASSWORD", $WECertPass)
$json.Add(" SELFSIGNED-CERT-THUMBPRINT", $kvCert.Thumbprint)
$json.Add(" SELFSIGNED-CERT-DNSNAME", $WECertDNSName)


$WESecretValue = ConvertTo-SecureString -String $(new-guid) -AsPlainText -Force
$s1 = Set-AzureKeyVaultSecret -VaultName $WEKeyVaultName -Name 'url-sign-secret-1' -SecretValue $WESecretValue -Verbose
$WESecretValue = ConvertTo-SecureString -String $(new-guid) -AsPlainText -Force; 
$s2 = Set-AzureKeyVaultSecret -VaultName $WEKeyVaultName -Name 'url-sign-secret-2' -SecretValue $WESecretValue -Verbose
 
$json.Add(" KEYVAULT-URLSIGN-SECRET1-NAME", 'url-sign-secret-1')
$json.Add(" KEYVAULT-URLSIGN-SECRET2-NAME", 'url-sign-secret-2')

$json.Add(" KEYVAULT-URLSIGN-SECRET1-VERSION", $s1.Version)
$json.Add(" KEYVAULT-URLSIGN-SECRET2-VERSION", $s2.Version)


az appconfig create -g " $WEResourceGroupName" -n " $appConfigStoreName" -l " $WELocation" --verbose 
az appconfig kv set -n " $appConfigStoreName" --key 'key1' --value " value1" --label 'template' -y --verbose
az appconfig kv set -n " $appConfigStoreName" --key 'windowsOSVersion' --value '2019-Datacenter' --label 'template' -y --verbose
az appconfig kv set -n " $appConfigStoreName" --key 'diskSizeGB' --value " 1023" --label 'template' -y --verbose

$json.Add(" APPCONFIGSTORE-NAME", $appConfigStoreName)
$json.Add(" APPCONFIGSTORE-RESOURCEGROUP-NAME", $WEResourceGroupName)
$json.Add(" APPCONFIGSTORE-KEY1", " key1")
$json.Add(" APPCONFIGSTORE-KEY1", " windowsOSVersion")
$json.Add(" APPCONFIGSTORE-KEY1", " diskSizeGB")


Write-Output $($json | ConvertTo-json -Depth 30)


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
