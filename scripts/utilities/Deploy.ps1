#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Accounts

<#
.SYNOPSIS
    Deploy Azure Managed Instance

.DESCRIPTION
    Azure automation script for deploying Azure SQL Managed Instance with VPN certificates
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER Parameters
    Hashtable containing deployment parameters

.PARAMETER ScriptUrlBase
    Base URL for template scripts

.EXAMPLE
    .\Deploy.ps1 -Parameters $deployParams -ScriptUrlBase "https://example.com/templates"

.NOTES
    Deploys Azure SQL Managed Instance with Point-to-Site VPN configuration
    Creates self-signed certificates for VPN authentication
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [hashtable]$Parameters,

    [Parameter(Mandatory)]
    [string]$ScriptUrlBase
)

$ErrorActionPreference = "Stop"

try {
    $SubscriptionId = $Parameters['subscriptionId']
    $ResourceGroupName = $Parameters['resourceGroupName']
    $CertificateNamePrefix = $Parameters['certificateNamePrefix']
    $Location = $Parameters['location']
    $ManagedInstanceName = $Parameters['managedInstanceName']

    # Remove parameters that are not template parameters
    $Parameters.Remove('subscriptionId')
    $Parameters.Remove('resourceGroupName')
    $Parameters.Remove('certificateNamePrefix')

    function Confirm-Login {
        $context = Get-AzContext -ErrorAction SilentlyContinue
        if ($null -eq $context.Subscription) {
            Connect-AzAccount | Out-Null
        }
    }

    function Test-PSVersion {
        Write-Output "Verifying PowerShell version, must be 5.0 or higher."
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            Write-Output "PowerShell version verified."
        }
        else {
            Write-Error "You need to install PowerShell version 5.0 or higher."
            throw "Insufficient PowerShell version"
        }
    }

    function Test-ManagedInstanceName {
        param(
            [Parameter(Mandatory)]
            [string]$ManagedInstanceName
        )

        Write-Output "Verifying Managed Instance name, must be globally unique."
        if ([string]::IsNullOrEmpty($ManagedInstanceName)) {
            Write-Error "Managed Instance name is required parameter."
            throw "Missing managed instance name"
        }

        if ($null -ne (Resolve-DnsName ($ManagedInstanceName + '.provisioning.database.windows.net') -ErrorAction SilentlyContinue)) {
            Write-Error "Managed Instance name already in use."
            throw "Managed instance name conflict"
        }

        Write-Output "Managed Instance name verified."
    }

    # Verify prerequisites
    Test-PSVersion
    Test-ManagedInstanceName $ManagedInstanceName
    Confirm-Login

    # Set subscription context
    $context = Get-AzContext -ErrorAction Stop
    if ($context.Subscription.Id -ne $SubscriptionId) {
        Write-Output "Selecting subscription '$SubscriptionId'"
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }

    # Create root certificate
    $rootCertParams = @{
        KeyUsage = "CertSign"
        HashAlgorithm = "sha256"
        KeySpec = "Signature"
        Type = "Custom"
        KeyLength = "2048"
        KeyExportPolicy = "Exportable"
        Subject = "CN=$CertificateNamePrefix" + "P2SRoot"
        KeyUsageProperty = "Sign"
        CertStoreLocation = "Cert:\CurrentUser\My"
    }
    $rootCertificate = New-SelfSignedCertificate @rootCertParams
    $CertificateThumbprint = $rootCertificate.Thumbprint

    # Create child certificate
    $childCertParams = @{
        Signer = $rootCertificate
        TextExtension = @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
        HashAlgorithm = "sha256"
        KeySpec = "Signature"
        Type = "Custom"
        KeyLength = "2048"
        KeyExportPolicy = "Exportable"
        Subject = "CN=$CertificateNamePrefix" + "P2SChild"
        CertStoreLocation = "Cert:\CurrentUser\My"
        DnsName = "$CertificateNamePrefix" + "P2SChild"
    }
    New-SelfSignedCertificate @childCertParams | Out-Null

    # Get public certificate data
    $PublicRootCertData = [Convert]::ToBase64String((Get-Item -ErrorAction Stop cert:\currentuser\my\$CertificateThumbprint).RawData)
    $Parameters['publicRootCertData'] = $PublicRootCertData

    # Create or verify resource group
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (!$ResourceGroup) {
        Write-Output "Resource group '$ResourceGroupName' does not exist."
        Write-Output "Creating resource group '$ResourceGroupName' in location '$Location'"
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
    }
    else {
        Write-Output "Using existing resource group '$ResourceGroupName'"
    }

    # Start deployment
    Write-Output "Starting deployment..."
    New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri ($ScriptUrlBase + '/azuredeploy.json') -TemplateParameterObject $Parameters

    Write-Output "Deployment completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}