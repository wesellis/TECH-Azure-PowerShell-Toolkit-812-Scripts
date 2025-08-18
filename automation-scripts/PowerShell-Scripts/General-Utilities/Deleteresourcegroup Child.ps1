<#
.SYNOPSIS
    Deleteresourcegroup Child

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
    We Enhanced Deleteresourcegroup Child

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS  
 Script for deleting the resource group
.DESCRIPTION  
 Script for deleting the resource group
.EXAMPLE  
.\DeleteResourceGroup_Child.ps1 
Version History  
v1.0   -Initial Release  


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [String]$WERGName
)
$connectionName = " AzureRunAsConnection"
try
{
    # Get the connection " AzureRunAsConnection "
   ;  $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    " Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$servicePrincipalConnection)
    {
       ;  $WEErrorMessage = " Connection $connectionName not found."
        throw $WEErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

try
{
    if ($WERGName -eq $null)
    {
        Write-Warning " $($WERGName) is empty. Please Verify!"
    }
    else
    {  
        Write-Output " Removing the resource group $($WERGName)..."
        Remove-AzureRmResourceGroup -Name $WERGName.Trim() -Force
    }
    
}
catch
{
    Write-Output " Error Occurred..."
    Write-Output $_.Exception
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================