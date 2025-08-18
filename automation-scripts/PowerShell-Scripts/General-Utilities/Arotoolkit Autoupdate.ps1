<#
.SYNOPSIS
    Arotoolkit Autoupdate

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
    We Enhanced Arotoolkit Autoupdate

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
 AutoUpdate Module for ARO Toolkit future releases
.DESCRIPTION  
 AutoUpdate Module for ARO Toolkit future releases
.EXAMPLE  
.\AROToolkit_AutoUpdate.ps1 
Version History  
v1.0   - <dev> - Initial Release  



$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection " AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

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
        $WEErrorMessage = " Connection $connectionName not found."
        throw $WEErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

try
{
    Write-Output " AutoUpdate Wrapper execution starts..."
    
    #Local Variables

    $WEGithubRootPath    = " https://raw.githubusercontent.com/Microsoft/MSITARM"
    $WEGithubBranch  = " azure-resource-optimization-toolkit"
    $WEScriptPath    = " azure-resource-optimization-toolkit/scripts"
    $WEFileName = " AutoUpdateWorker.ps1"
    $WEGithubFullPath = " $($WEGithubRootPath)/$($WEGithubBranch)/$($WEScriptPath)/$($WEFileName)"

    $automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'

    #[System.Reflection.Assembly]::LoadWithPartialName(" System.Web.Extensions" )

    $WEWebClient = New-Object System.Net.WebClient

    Write-Output " Download the AutoUpdateWorker script from GitHub..."

    $WEWebClient.DownloadFile($($WEGithubFullPath)," $WEPSScriptRoot\$($WEFileName)" )    
   ;  $psScriptPath = " $WEPSScriptRoot\$($WEFileName)"
   ;  $WERunbookName = $WEFileName.Substring(0,$WEFileName.Length-4).Trim()

    Write-Output " Creating the worker runbook in the Automation Account..." 

    New-AzureRmAutomationRunbook -Name $WERunbookName -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Type PowerShell -Description " New autoupdate worker runbook"

    Import-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Path $psScriptPath -Name $WERunbookName -Force -Type PowerShell 

    Write-Output " Publishing the new Runbook $($WERunbookName)..."
    Publish-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Name $WERunbookName

    Write-Output " Executing the new Runbook $($WERunbookName)..."
    Start-AzureRmAutomationRunbook -Name $WERunbookName -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Wait

    Write-Output " Runbook $($WERunbookName) execution completed. Deleting the runbook..."
    Remove-AzureRmAutomationRunbook -Name $WERunbookName -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Force 
    
    Write-Output " AutoUpdate Wrapper execution completed..."
}
catch
{
    Write-Output " Error Occurred in the AutoUpdate wrapper runbook..."
    Write-Output $_.Exception
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================