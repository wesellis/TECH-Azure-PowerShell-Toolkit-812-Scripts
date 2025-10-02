#Requires -Version 7.4

<#
.SYNOPSIS
    Connect to Azure

.DESCRIPTION
    Azure automation script for authenticating to Azure using service principal credentials.
    Use this script at the start of a pipeline to install the Az cmdlets and authenticate
    a machine's PowerShell sessions to Azure using the provided service principal.

.PARAMETER AppId
    The Application ID of the Azure service principal

.PARAMETER Secret
    The secret/password for the Azure service principal

.PARAMETER TenantId
    The Azure tenant ID

.PARAMETER SubscriptionId
    The Azure subscription ID to connect to

.PARAMETER Environment
    The Azure environment (default: AzureCloud)

.PARAMETER InstallAzModule
    Switch to install the Az PowerShell module

.PARAMETER ModuleVersion
    Specific version of the Az module to install

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$AppId,

    [Parameter(Mandatory=$true)]
    [string]$Secret,

    [Parameter(Mandatory=$true)]
    [string]$TenantId,

    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [string]$Environment = "AzureCloud",

    [switch]$InstallAzModule,

    [string]$ModuleVersion
)

$ErrorActionPreference = "Stop"

try {
    if ($InstallAzModule) {
        Write-Output "Installing Az PowerShell module..."
        Set-PSRepository -InstallationPolicy Trusted -Name PSGallery -Verbose

        $VersionParam = @{}
        if (-not [string]::IsNullOrEmpty($ModuleVersion)) {
            $VersionParam.Add("RequiredVersion", $ModuleVersion)
        }

        Install-Module -Name Az -AllowClobber -Verbose @VersionParam
        Install-Module -Name AzTable -AllowClobber -Verbose
    }

    # Create secure credential object
    $SecureSecret = ConvertTo-SecureString -String $Secret -AsPlainText -Force
    $PSCredential = New-Object System.Management.Automation.PSCredential($AppId, $SecureSecret)

    Write-Output "App ID     : $AppId"
    Write-Output "Sub ID     : $SubscriptionId"
    Write-Output "Tenant ID  : $TenantId"
    Write-Output "Environment: $Environment"

    # Connect to Azure
    Connect-AzAccount -ServicePrincipal -Credential $PSCredential -TenantId $TenantId -Subscription $SubscriptionId -Environment $Environment -Verbose

    Write-Output "Successfully connected to Azure"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}