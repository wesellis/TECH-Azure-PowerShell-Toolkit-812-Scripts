#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Deleteresourcegroup Child

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
 Script for deleting the resource group
 Script for deleting the resource group
.\DeleteResourceGroup_Child.ps1
Version History
v1.0   -Initial Release
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [String]$RGName
)
#region Functions
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName
    "Logging in to Azure..."
    $params = @{
        ApplicationId = $servicePrincipalConnection.ApplicationId
        TenantId = $servicePrincipalConnection.TenantId
        CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    }
    Add-AzureRmAccount @params
}
catch
{
    if (!$servicePrincipalConnection)
    {
$ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
try
{
    if ($null -eq $RGName)
    {
        Write-Warning " $($RGName) is empty. Please Verify!"
    }
    else
    {
        Write-Output "Removing the resource group $($RGName)..."
        Remove-AzureRmResourceGroup -Name $RGName.Trim() -Force

} catch
{
    Write-Output "Error Occurred..."
    Write-Output $_.Exception
}\n

