#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Scheduledsnooze Child

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
    We Enhanced Scheduledsnooze Child

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
.SYNOPSIS  
 Wrapper script for start & stop AzureRM VM's
.DESCRIPTION  
 Wrapper script for start & stop AzureRM VM's
.EXAMPLE  
.\ScheduledSnooze_Child.ps1 -VMName "Value1" -Action " Value2" -ResourceGroupName " Value3" 
Version History  
v1.0   - Initial Release  

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
[string]$WEVMName = $(throw " Value for VMName is missing" ),
[String]$WEAction = $(throw " Value for Action is missing" ),
[String]$WEResourceGroupName = $(throw " Value for ResourceGroupName is missing" )
)

#region Functions


$connectionName = " AzureRunAsConnection"
try
{
    # Get the connection " AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    " Logging in to Azure..."
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
        $WEErrorMessage = " Connection $connectionName not found."
        throw $WEErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

try
{          
    Write-Output " VM action is : $($WEAction)"
            
    if ($WEAction.Trim().ToLower() -eq " stop" )
    {
        Write-Output " Stopping the VM : $($WEVMName)"

       ;  $WEStatus = Stop-AzureRmVM -Name $WEVMName -ResourceGroupName $WEResourceGroupName -Force
        if($null -eq $WEStatus)
        {
            Write-Output " Error occured while stopping the Virtual Machine."
        }
        else
        {
           Write-Output " Successfully stopped the VM $WEVMName"
        }
    }
    elseif($WEAction.Trim().ToLower() -eq " start" )
    {
        Write-Output " Starting the VM : $($WEVMName)"

       ;  $WEStatus = Start-AzureRmVM -Name $WEVMName -ResourceGroupName $WEResourceGroupName
        if($null -eq $WEStatus)
        {
            Write-Output " Error occured while starting the Virtual Machine $($WEVMName)"
        }
        else
        {
            Write-Output " Successfully started the VM $($WEVMName)"
        }
    }      
    
}
catch
{
    Write-Output " Error Occurred..."
    Write-Output $_.Exception
}





# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
