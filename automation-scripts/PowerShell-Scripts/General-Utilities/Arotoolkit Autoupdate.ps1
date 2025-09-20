<#
.SYNOPSIS
    Arotoolkit Autoupdate

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
 AutoUpdate Module for ARO Toolkit future releases
 AutoUpdate Module for ARO Toolkit future releases
.\AROToolkit_AutoUpdate.ps1
Version History
v1.0   - <dev> - Initial Release
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
    Write-Output "AutoUpdate Wrapper execution starts..."
    #Local Variables
    $GithubRootPath    = "https://raw.githubusercontent.com/Microsoft/MSITARM"
    $GithubBranch  = " azure-resource-optimization-toolkit"
    $ScriptPath    = " azure-resource-optimization-toolkit/scripts"
    $FileName = "AutoUpdateWorker.ps1"
    $GithubFullPath = " $($GithubRootPath)/$($GithubBranch)/$($ScriptPath)/$($FileName)"
    $automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'
    #[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions" )
    $WebClient = New-Object -ErrorAction Stop System.Net.WebClient
    Write-Output "Download the AutoUpdateWorker script from GitHub..."
    $WebClient.DownloadFile($($GithubFullPath)," $PSScriptRoot\$($FileName)" )
$psScriptPath = " $PSScriptRoot\$($FileName)"
$RunbookName = $FileName.Substring(0,$FileName.Length-4).Trim()
    Write-Output "Creating the worker runbook in the Automation Account..."
    New-AzureRmAutomationRunbook -Name $RunbookName -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Type PowerShell -Description "New autoupdate worker runbook"
    Import-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Path $psScriptPath -Name $RunbookName -Force -Type PowerShell
    Write-Output "Publishing the new Runbook $($RunbookName)..."
    Publish-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Name $RunbookName
    Write-Output "Executing the new Runbook $($RunbookName)..."
    Start-AzureRmAutomationRunbook -Name $RunbookName -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Wait
    Write-Output "Runbook $($RunbookName) execution completed. Deleting the runbook..."
    Remove-AzureRmAutomationRunbook -Name $RunbookName -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Force
    Write-Output "AutoUpdate Wrapper execution completed..."
}
catch
{
    Write-Output "Error Occurred in the AutoUpdate wrapper runbook..."
    Write-Output $_.Exception
}

