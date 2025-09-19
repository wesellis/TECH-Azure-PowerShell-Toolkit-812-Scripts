#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Connectto Azure

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Connectto Azure

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

Use this script at the start of a pipeline to install the Az cmdlets and authenticate a machine's PowerShell sessions to Azure using the provided service principal


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string][Parameter(mandatory=$true)] $appId,
    [string][Parameter(mandatory=$true)] $secret,
    [string][Parameter(mandatory=$true)] $tenantId,
    [string][Parameter(mandatory=$true)] $subscriptionId,
    [string] $WEEnvironment = " AzureCloud" ,
    [switch] $WEInstallAzModule,
    [string] $WEModuleVersion
)

#region Functions

if ($WEInstallAzModule){

    Set-PSRepository -InstallationPolicy Trusted -Name PSGallery -verbose

   ;  $WEVersionParam = @{}
    if($null -ne $WEModuleVersion){
        $WEVersionParam.Add(" RequiredVersion" , " $WEModuleVersion" )
    }
    Install-Module -Name Az -AllowClobber -verbose @VersionParam
    Install-Module -Name AzTable -AllowClobber -verbose # need this for updating the deployment status table

}
; 
$pscredential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential($appId, (ConvertTo-SecureString $secret -AsPlainText -Force))

Write-WELog " app Id     : $appId" " INFO"
Write-WELog " sub Id     : $subscriptionId" " INFO"
Write-WELog " tenant Id  : $tenantId" " INFO"
Write-WELog " environment: $WEEnvironment" " INFO"

Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId $tenantId -Subscription $subscriptionId -Environment $WEEnvironment -Verbose



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
