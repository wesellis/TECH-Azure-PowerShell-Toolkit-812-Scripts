#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.KeyVault, Az.Accounts, Az.Profile

<#
.SYNOPSIS
    Create Gen Artifacts

.DESCRIPTION
    Azure automation script to create the GEN artifacts needed by the pipeline to test templates.
    Creates resource groups, storage accounts, key vaults, certificates, and networking components.

.PARAMETER ResourceGroupName
    Name of the resource group to create or use (default: 'ttk-gen-artifacts')

.PARAMETER Location
    Azure location where resources will be created

.PARAMETER KeyVaultName
    Name of the Key Vault to create (must be globally unique, default: 'azbotvault')

.PARAMETER CertPass
    Password for certificates (auto-generated if not provided)

.PARAMETER CertDNSName
    DNS name for the certificate (default: 'azbot-cert-dns')

.PARAMETER KeyVaultSelfSignedCertName
    Name of the self-signed certificate in Key Vault (default: 'azbot-sscert')

.PARAMETER KeyVaultNotSecretName
    Name of the password secret in Key Vault (default: 'notSecretPassword')

.PARAMETER ServicePrincipalObjectId
    Object ID of the service principal for access policies

.PARAMETER AppConfigStoreName
    Name of the App Configuration store (must be globally unique, default: 'azbotappconfigstore')

.PARAMETER MsiName
    Name of the managed service identity (default: 'azbot-msi')

.PARAMETER SshPublicKeyValue
    SSH public key value (reads from scratch.pub if not provided)

.PARAMETER SshPrivateKeyValue
    SSH private key value (reads from scratch if not provided)

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
    Use this script to create the GEN artifacts needed by the pipeline to test templates.
    Be sure to set the appropriate Context before running the script
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = 'ttk-gen-artifacts',

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName = 'azbotvault',

    [Parameter(Mandatory = $false)]
    [string]$CertPass = ("cI#" + (New-Guid).ToString().Replace("-", "").Substring(0, 17)),

    [Parameter(Mandatory = $false)]
    [string]$CertDNSName = 'azbot-cert-dns',

    [Parameter(Mandatory = $false)]
    [string]$KeyVaultSelfSignedCertName = 'azbot-sscert',

    [Parameter(Mandatory = $false)]
    [string]$KeyVaultNotSecretName = 'notSecretPassword',

    [Parameter(Mandatory = $false)]
    [string]$ServicePrincipalObjectId,

    [Parameter(Mandatory = $false)]
    [string]$AppConfigStoreName = 'azbotappconfigstore',

    [Parameter(Mandatory = $false)]
    [string]$MsiName = 'azbot-msi',

    [Parameter(Mandatory = $false)]
    [string]$SshPublicKeyValue,

    [Parameter(Mandatory = $false)]
    [string]$SshPrivateKeyValue
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Starting Azure Gen Artifacts creation..."

    # Create or get resource group
    if ((Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue) -eq $null) {
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
        Write-Output "Created resource group: $ResourceGroupName"
    }

    # Create storage account
    $StorageAccountName = 'stage' + ((Get-AzContext).Subscription.Id).Replace('-', '').substring(0, 19)
    $StorageAccount = (Get-AzStorageAccount -ErrorAction SilentlyContinue | Where-Object { $_.StorageAccountName -eq $StorageAccountName })

    if ($null -eq $StorageAccount) {
        $StorageResourceGroupName = 'ARM_Deploy_Staging'
        New-AzResourceGroup -Location $Location -Name $StorageResourceGroupName -Force
        $StorageAccount = New-AzStorageAccount -StorageAccountName $StorageAccountName -SkuName 'Standard_LRS' -ResourceGroupName $StorageResourceGroupName -Location $Location
        Write-Output "Created storage account: $StorageAccountName"
    }

    # Create managed identity
    $msi = (az identity create -g $ResourceGroupName -n $MsiName --verbose) | ConvertFrom-Json

    # Initialize output JSON
    $json = New-Object System.Collections.Specialized.OrderedDictionary
    $json.Add("USER-ASSIGNED-IDENTITY-NAME", $MsiName)
    $json.Add("USER-ASSIGNED-IDENTITY-RESOURCEGROUP-NAME", $ResourceGroupName)

    # Configure service principal permissions
    if ($ServicePrincipalObjectId) {
        $RoleDef = Get-AzRoleDefinition -Name 'Contributor'
        New-AzRoleAssignment -RoleDefinitionId $RoleDef.id -ObjectId $ServicePrincipalObjectId -Scope $StorageAccount.Id

        $RoleDef = Get-AzRoleDefinition -Name 'Managed Identity Operator'
        $MsiId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$MsiName"
        New-AzRoleAssignment -RoleDefinitionId $RoleDef.id -ObjectId $ServicePrincipalObjectId -Scope $MsiId
    }

    # Create virtual network
    $subnet1 = New-AzVirtualNetworkSubnetConfig -Name 'azbot-subnet-1' -AddressPrefix '10.0.1.0/24'
    $subnet2 = New-AzVirtualNetworkSubnetConfig -Name 'azbot-subnet-2' -AddressPrefix '10.0.2.0/24'
    $VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name 'azbot-vnet' -AddressPrefix '10.0.0.0/16' -Location $location -Subnet $subnet1, $subnet2 -Force

    $json.Add("VNET-RESOURCEGROUP-NAME", $VNet.ResourceGroupName)
    $json.Add("VNET-NAME", $VNet.Name)
    $json.Add("VNET-SUBNET1-NAME", $VNet.Subnets[0].Name)
    $json.Add("VNET-SUBNET2-NAME", $VNet.Subnets[1].Name)

    # Create Key Vault
    $vault = Get-AzKeyVault -VaultName $KeyVaultName -ErrorAction SilentlyContinue
    if ($null -eq $vault) {
        $vault = New-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $Location
        Write-Output "Created Key Vault: $KeyVaultName"
    }

    # Create App Configuration Store
    $AppConfigStore = $(az appconfig create -g $ResourceGroupName -n $AppConfigStoreName -l $Location -o json --verbose) | ConvertFrom-Json

    # Configure Key Vault access policies
    if ($ServicePrincipalObjectId) {
        # Create custom role definitions if needed
        $role = Get-AzRoleDefinition -Name "KeyVault Deployment Action" -ErrorAction SilentlyContinue
        if ($null -eq $role) {
            $RoleDef = New-Object -TypeName "Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition"
            $RoleDef.Id = $null
            $RoleDef.Name = "KeyVault Deployment Action"
            $RoleDef.Description = "KeyVault Deploy Action for Template Reference Parameter Use"
            $RoleDef.Actions = @("Microsoft.KeyVault/vaults/deploy/action")
            $RoleDef.AssignableScopes = @("/subscriptions/$((Get-AzContext).Subscription.Id)")
            $role = New-AzRoleDefinition -Role $RoleDef
        }
        New-AzRoleAssignment -RoleDefinitionId $role.Id -ObjectId $ServicePrincipalObjectId -Scope $vault.ResourceId

        $role = Get-AzRoleDefinition -Name "Join Subnets" -ErrorAction SilentlyContinue
        if ($null -eq $role) {
            $RoleDef = New-Object -TypeName "Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition"
            $RoleDef.Id = $null
            $RoleDef.Name = "Join Subnets"
            $RoleDef.Description = "Join a VM to a subnet"
            $RoleDef.Actions = @("Microsoft.Network/virtualNetworks/subnets/join/action")
            $RoleDef.AssignableScopes = @("/subscriptions/$((Get-AzContext).Subscription.Id)")
            $role = New-AzRoleDefinition -Role $RoleDef
        }
        $scope = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName"
        New-AzRoleAssignment -RoleDefinitionId $role.Id -ObjectId $ServicePrincipalObjectId -Scope $scope

        $RoleDef = Get-AzRoleDefinition -Name 'Contributor'
        New-AzRoleAssignment -RoleDefinitionId $RoleDef.id -ObjectId $ServicePrincipalObjectId -Scope $vault.ResourceId
        New-AzRoleAssignment -RoleDefinitionId $RoleDef.id -ObjectId $ServicePrincipalObjectId -Scope $AppConfigStore.id

        Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $ServicePrincipalObjectId -PermissionsToKeys "get,restore" -PermissionsToSecrets "get,set" -PermissionsToCertificates "get"
    }

    # Configure service principal access for Azure services
    $mlsp = Get-AzADServicePrincipal -ServicePrincipalName '0736f41a-0425-4b46-bdb5-1563eff02385'
    if ($mlsp) {
        $RoleDef = Get-AzRoleDefinition -Name 'Contributor'
        New-AzRoleAssignment -RoleDefinitionId $RoleDef.id -ObjectId $mlsp.Id -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)"
        $json.Add("MACHINE-LEARNING-SP-OBJECTID", $mlsp.Id)
    }

    $cosmossp = Get-AzADServicePrincipal -ServicePrincipalName "a232010e-820c-4083-83bb-3ace5fc29d0b"
    if ($cosmossp) {
        Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $cosmossp.Id -PermissionsToKeys get,unwrapKey,wrapKey
        $json.Add("COSMOS-DB-SP-OBJECTID", $cosmossp.Id)
    }

    $webapp = Get-AzADServicePrincipal -ServicePrincipalName "abfa0a7c-a6b6-4736-8310-5855508787cd"
    if ($webapp) {
        Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -ObjectId $webapp.Id -PermissionsToSecrets get
    }

    # Add secrets to Key Vault
    $SecretValue = Read-Host -Prompt "Enter secure value for password secret" -AsSecureString
    Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultNotSecretName -SecretValue $SecretValue

    $json.Add("KEYVAULT-NAME", $vault.VaultName)
    $json.Add("KEYVAULT-RESOURCEGROUP-NAME", $vault.ResourceGroupName)
    $json.Add("KEYVAULT-PASSWORD-SECRET-NAME", $KeyVaultNotSecretName)
    $json.Add("KEYVAULT-SUBSCRIPTION-ID", $vault.ResourceId.Split('/')[2])
    $json.Add("KEYVAULT-RESOURCE-ID", $vault.ResourceId)

    $RefParam = @{
        reference = @{
            keyVault = @{
                id = $vault.ResourceId
            }
            secretName = $KeyVaultNotSecretName
        }
    }
    $json.Add("KEYVAULT-PASSWORD-REFERENCE", $RefParam)

    # Create self-signed certificate
    $SecurePassword = Read-Host -Prompt "Enter secure value for certificate" -AsSecureString
    $CertFileFullPath = $(Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "\$CertDNSName.pfx")

    if ($(Get-Module 'PKI' -ListAvailable) -eq $null) {
        Write-Warning "PKI module not available. Using New-SelfSignedCertificate cmdlet."
    }

    $NewCert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -DnsName $CertDNSName -NotAfter (Get-Date).AddYears(10)
    Export-PfxCertificate -FilePath $CertFileFullPath -Password $SecurePassword -Cert $NewCert

    # Create Service Fabric certificate
    $Bytes = [System.IO.File]::ReadAllBytes($CertFileFullPath)
    $Base64 = [System.Convert]::ToBase64String($Bytes)
    $JSONBlob = @{
        data = $Base64
        dataType = 'pfx'
        password = $CertPass
    } | ConvertTo-Json
    $ContentBytes = [System.Text.Encoding]::UTF8.GetBytes($JSONBlob)
    $Content = [System.Convert]::ToBase64String($ContentBytes)

    $SFSecretValue = Read-Host -Prompt "Enter secure value for SF cert" -AsSecureString
    $NewSecret = Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name "azbot-sf-cert" -SecretValue $SFSecretValue
    $json.Add("SF-CERT-URL", $NewSecret.Id)
    $json.Add("SF-CERT-THUMBPRINT", $NewCert.Thumbprint)

    # Create disk encryption key
    $key = Add-AzKeyVaultKey -VaultName $KeyVaultName -Name "azbot-diskkey" -Destination "Software"
    $json.Add("KEYVAULT-ENCRYPTION-KEY", $key.Name)
    $json.Add("KEYVAULT-ENCRYPTION-KEY-URI", $key.id)
    $json.Add("KEYVAULT-ENCRYPTION-KEY-VERSION", $key.Version)

    # Handle SSH keys
    if (-not $SshPublicKeyValue -and (Test-Path "scratch.pub")) {
        $SshPublicKeyValue = Get-Content -Path "scratch.pub" -Raw
    }
    if (-not $SshPrivateKeyValue -and (Test-Path "scratch")) {
        $SshPrivateKeyValue = Get-Content -Path "scratch" -Raw
    }

    if ($SshPublicKeyValue) {
        $json.Add("SSH-PUB-KEY", $SshPublicKeyValue)
        $SshPublicKeySecretValue = Read-Host -Prompt "Enter SSH public key secret" -AsSecureString
        Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name "sshPublicKey" -SecretValue $SshPublicKeySecretValue
        $json.Add("KEYVAULT-SSH-PUBLIC-KEY-NAME", "sshPublicKey")
    }

    if ($SshPrivateKeyValue) {
        $SshPrivateKeySecretValue = Read-Host -Prompt "Enter SSH private key secret" -AsSecureString
        Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name "sshPrivateKey" -SecretValue $SshPrivateKeySecretValue
        $json.Add("KEYVAULT-SSH-PRIVATE-KEY-NAME", "sshPrivateKey")
    }

    # Create SSL certificate
    $PfxFileFullPath = $(Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "\$CertDNSName.pfx")
    $CerFileFullPath = $(Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "\$CertDNSName.cer")

    Export-PfxCertificate -Cert $NewCert -FilePath $PfxFileFullPath -Password $(Read-Host -AsSecureString -Prompt "Enter certificate password")
    Export-Certificate -Cert $NewCert -FilePath $CerFileFullPath

    $KvCert = Import-AzKeyVaultCertificate -VaultName $KeyVaultName -Name "azbot-ssl-cert" -FilePath $PfxFileFullPath -Password $(Read-Host -AsSecureString -Prompt "Enter certificate password")

    $json.Add("KEYVAULT-SSL-SECRET-NAME", $KvCert.Name)
    $json.Add("KEYVAULT-SSL-SECRET-URI", $KvCert.Id)
    $json.Add("SELFSIGNED-CERT-PFXDATA", [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($PfxFileFullPath)))
    $json.Add("SELFSIGNED-CERT-CERDATA", [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($CerFileFullPath)))
    $json.Add("SELFSIGNED-CERT-PASSWORD", $CertPass)
    $json.Add("SELFSIGNED-CERT-THUMBPRINT", $KvCert.Thumbprint)
    $json.Add("SELFSIGNED-CERT-DNSNAME", $CertDNSName)

    # Create URL signing secrets
    $SecretValue1 = Read-Host -Prompt "Enter secure value for URL sign secret 1" -AsSecureString
    $s1 = Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'url-sign-secret-1' -SecretValue $SecretValue1
    $SecretValue2 = Read-Host -Prompt "Enter secure value for URL sign secret 2" -AsSecureString
    $s2 = Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'url-sign-secret-2' -SecretValue $SecretValue2

    $json.Add("KEYVAULT-URLSIGN-SECRET1-NAME", 'url-sign-secret-1')
    $json.Add("KEYVAULT-URLSIGN-SECRET2-NAME", 'url-sign-secret-2')
    $json.Add("KEYVAULT-URLSIGN-SECRET1-VERSION", $s1.Version)
    $json.Add("KEYVAULT-URLSIGN-SECRET2-VERSION", $s2.Version)

    # Configure App Configuration Store
    az appconfig kv set -n $AppConfigStoreName --key 'key1' --value 'value1' --label 'template' -y
    az appconfig kv set -n $AppConfigStoreName --key 'windowsOSVersion' --value '2019-Datacenter' --label 'template' -y
    az appconfig kv set -n $AppConfigStoreName --key 'diskSizeGB' --value '1023' --label 'template' -y

    $json.Add("APPCONFIGSTORE-NAME", $AppConfigStoreName)
    $json.Add("APPCONFIGSTORE-RESOURCEGROUP-NAME", $ResourceGroupName)
    $json.Add("APPCONFIGSTORE-KEY1", "key1")
    $json.Add("APPCONFIGSTORE-KEY2", "windowsOSVersion")
    $json.Add("APPCONFIGSTORE-KEY3", "diskSizeGB")

    Write-Output $($json | ConvertTo-json -Depth 30)
    Write-Output "Azure Gen Artifacts creation completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}