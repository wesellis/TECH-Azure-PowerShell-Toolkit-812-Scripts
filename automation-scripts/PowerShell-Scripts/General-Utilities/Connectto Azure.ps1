<#
.SYNOPSIS
    Connectto Azure

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
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
    [string] $Environment = "AzureCloud" ,
    [switch] $InstallAzModule,
    [string] $ModuleVersion
)
if ($InstallAzModule){
    Set-PSRepository -InstallationPolicy Trusted -Name PSGallery -verbose
$VersionParam = @{}
    if($null -ne $ModuleVersion){
        $VersionParam.Add("RequiredVersion" , "$ModuleVersion" )
    }
    Install-Module -Name Az -AllowClobber -verbose @VersionParam
    Install-Module -Name AzTable -AllowClobber -verbose # need this for updating the deployment status table
}
$pscredential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential($appId, (ConvertTo-SecureString $secret -AsPlainText -Force))
Write-Host " app Id     : $appId"
Write-Host " sub Id     : $subscriptionId"
Write-Host " tenant Id  : $tenantId"
Write-Host " environment: $Environment"
Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId $tenantId -Subscription $subscriptionId -Environment $Environment -Verbose
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n