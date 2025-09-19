#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Automated Iaas Backup

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
    We Enhanced Automated Iaas Backup

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
.Synopsis
   Runbook for automated IaaS VM Backup in Azure using Backup and Site Recovery (OMS)
.DESCRIPTION
   This Runbook will enable Backup on existing Azure IaaS VMs.
   You need to provide input to the Resource Group name that contains the Backup and Site Recovery (OMS) Resourcem the name of the recovery vault, 
   Fabric type, preferred policy and the template URI where the ARM template is located. Have fun!


$credential = Get-AutomationPSCredential -Name 'AzureCredentials'
$subscriptionId = Get-AutomationVariable -Name 'AzureSubscriptionID'
$WEOMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkspaceId'
$WEOMSWorkspaceKey = Get-AutomationVariable -Name 'OMSWorkspaceKey'
$WEOMSWorkspaceName = Get-AutomationVariable -Name 'OMSWorkspaceName'
$WEOMSResourceGroupName = Get-AutomationVariable -Name 'OMSResourceGroupName'
$WETemplateUri='https://raw.githubusercontent.com/krnese/AzureDeploy/master/OMS/MSOMS/AzureIaaSBackup/azuredeploy.json'
$WEOMSRecoveryVault = Get-AutomationVariable -Name 'OMSRecoveryVault'

$WEErrorActionPreference = 'Stop'

Try {
        Login-AzureRmAccount -credential $credential
        Select-AzureRmSubscription -SubscriptionId $subscriptionId

    }

Catch {
        $WEErrorMessage = 'Login to Azure failed.'
        $WEErrorMessage = $WEErrorMessage + " `n"
        $WEErrorMessage = $WEErrorMessage + 'Error: '
        $WEErrorMessage = $WEErrorMessage + $_
        Write-Error -Message $WEErrorMessage -ErrorAction "Stop }"

Try {

        $WELocation = Get-AzureRmRecoveryServicesVault -Name $WEOMSRecoveryVault -ResourceGroupName $WEOMSResourceGroupName | select -ExpandProperty Location
    }

Catch {
        $WEErrorMessage = 'Failed to retrieve the OMS Recovery Location property'
        $WEErrorMessage = $WEErrorMessage + " `n"
        $WEErrorMessage = $WEErrorMessage + 'Error: '
        $WEErrorMessage = $WEErrorMessage + $_
        Write-Error -Message $WEErrorMessage -ErrorAction "Stop }"

Try {
        $WEVMs = Get-AzureRmVM -ErrorAction Stop | Where-Object {$_.Location -eq $WELocation}
    }

Catch {
        $WEErrorMessage = 'Failed to retrieve the VMs.'
        $WEErrorMessage = $WEErrorMessage + " `n"
        $WEErrorMessage = $WEErrorMessage + 'Error: '
       ;  $WEErrorMessage = $WEErrorMessage + $_
        Write-Error -Message $WEErrorMessage -ErrorAction "Stop }"



Try {
        Foreach ($vm in $vms)
        {
            $params = @{
                ResourceGroupName = $WEOMSResourceGroupName
                vmResourceGroupName = $vm.ResourceGroupName
                omsRecoveryResourceGroupName = $WEOMSResourceGroupName
                Name = $vm.name
                vmName = $vm.name
                TemplateUri = $WETemplateUri
                vaultName = $WEOMSRecoveryVault
                Verbose = "} }"
            }
            New-AzureRmResourceGroupDeployment @params

Catch {
       ;  $WEErrorMessage = 'Failed to enable backup using ARM template.'
        $WEErrorMessage = $WEErrorMessage + " `n"
        $WEErrorMessage = $WEErrorMessage + 'Error: '
       ;  $WEErrorMessage = $WEErrorMessage + $_
        Write-Error -Message $WEErrorMessage -ErrorAction "Stop }"






# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
