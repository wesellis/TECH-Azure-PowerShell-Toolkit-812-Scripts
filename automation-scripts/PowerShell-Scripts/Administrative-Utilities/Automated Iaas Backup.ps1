<#
.SYNOPSIS
    Automated Iaas Backup

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
   Runbook for automated IaaS VM Backup in Azure using Backup and Site Recovery (OMS)
   This Runbook will enable Backup on existing Azure IaaS VMs.
   You need to provide input to the Resource Group name that contains the Backup and Site Recovery (OMS) Resourcem the name of the recovery vault,
   Fabric type, preferred policy and the template URI where the ARM template is located. Have fun!
$credential = Get-AutomationPSCredential -Name 'AzureCredentials'
$subscriptionId = Get-AutomationVariable -Name 'AzureSubscriptionID'
$OMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkspaceId'
$OMSWorkspaceKey = Get-AutomationVariable -Name 'OMSWorkspaceKey'
$OMSWorkspaceName = Get-AutomationVariable -Name 'OMSWorkspaceName'
$OMSResourceGroupName = Get-AutomationVariable -Name 'OMSResourceGroupName'
$TemplateUri='https://raw.githubusercontent.com/krnese/AzureDeploy/master/OMS/MSOMS/AzureIaaSBackup/azuredeploy.json'
$OMSRecoveryVault = Get-AutomationVariable -Name 'OMSRecoveryVault'
$ErrorActionPreference = 'Stop'
Try {
        Login-AzureRmAccount -credential $credential
        Select-AzureRmSubscription -SubscriptionId $subscriptionId
    }
Catch {
        $ErrorMessage = 'Login to Azure failed.'
        $ErrorMessage = $ErrorMessage + " `n"
        $ErrorMessage = $ErrorMessage + 'Error: '
        $ErrorMessage = $ErrorMessage + $_
        Write-Error -Message $ErrorMessage -ErrorAction "Stop }"
Try {
        $Location = Get-AzureRmRecoveryServicesVault -Name $OMSRecoveryVault -ResourceGroupName $OMSResourceGroupName | select -ExpandProperty Location
    }
Catch {
        $ErrorMessage = 'Failed to retrieve the OMS Recovery Location property'
        $ErrorMessage = $ErrorMessage + " `n"
        $ErrorMessage = $ErrorMessage + 'Error: '
        $ErrorMessage = $ErrorMessage + $_
        Write-Error -Message $ErrorMessage -ErrorAction "Stop }"
Try {
        $VMs = Get-AzureRmVM -ErrorAction Stop | Where-Object {$_.Location -eq $Location}
    }
Catch {
        $ErrorMessage = 'Failed to retrieve the VMs.'
        $ErrorMessage = $ErrorMessage + " `n"
        $ErrorMessage = $ErrorMessage + 'Error: '
$ErrorMessage = $ErrorMessage + $_
        Write-Error -Message $ErrorMessage -ErrorAction "Stop }"
Try {
        Foreach ($vm in $vms)
        {
            $params = @{
                ResourceGroupName = $OMSResourceGroupName
                vmResourceGroupName = $vm.ResourceGroupName
                omsRecoveryResourceGroupName = $OMSResourceGroupName
                Name = $vm.name
                vmName = $vm.name
                TemplateUri = $TemplateUri
                vaultName = $OMSRecoveryVault
                Verbose = "} }"
            }
            New-AzureRmResourceGroupDeployment @params
Catch {
$ErrorMessage = 'Failed to enable backup using ARM template.'
        $ErrorMessage = $ErrorMessage + " `n"
        $ErrorMessage = $ErrorMessage + 'Error: '
$ErrorMessage = $ErrorMessage + $_
        Write-Error -Message $ErrorMessage -ErrorAction "Stop }"\n