#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Stop Azurev2Vmrunbook

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
  Azure Automation runbook that stops of all VMs in the specified Azure subscription or resource group
  This Azure runbook connects to Azure and stops all VMs in an Azure subscription or resource group.
  You can attach a schedule to this runbook to run it at a specific time. Note that this runbook does not stop
  Azure classic VMs. Use https://gallery.technet.microsoft.com/scriptcenter/Stop-Azure-Classic-VMs-7a4ae43e for that.
.PARAMETER automationConnectionName
   Optional with default of "AzureRunAsConnection" .
   The name of an Automation Connection used to authenticate
.PARAMETER ResourceGroupName
   Required
   Allows you to specify the resource group containing the VMs to stop.
   If this parameter is included, only VMs in the specified resource group will be stopped, otherwise all VMs in the subscription will be stopped.
   AUTHOR: Jeff Bowles
   LASTEDIT: Sept 6, 2016
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline)]`n    $AutomationConnectionName = 'AzureRunAsConnection',
    [Parameter()]
    [String] $ResourceGroupName
)
try
{
    $ServicePrincipalConnection = Get-AutomationConnection -Name $AutomationConnectionName
    $params = @{
        ApplicationId = $ServicePrincipalConnection.ApplicationId
        TenantId = $ServicePrincipalConnection.TenantId
        CertificateThumbprint = $ServicePrincipalConnection.CertificateThumbprint
    }
    $login @params
}
catch
{
    if (!$ServicePrincipalConnection)
    {
    $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
write-output "Logged in as $($login.Context.Account.id) to subscriptionID $($login.Context.Subscription.SubscriptionId)."
if ($ResourceGroupName)
{
    $VMs = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
}
else
{
    $VMs = Get-AzureRmVM -ErrorAction Stop
}
foreach ($VM in $VMs)
{
    $VmName = $vm.Name
    $ResourceGroupName = $vm.resourceGroupName
    $status = ((Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VmName -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
    if($status -ne 'VM deallocated')
    {
    $StopRtn = Stop-AzureRMVM -Name $VMName -ResourceGroupName $ResourceGroupName -force -ea SilentlyContinue
		if (-not($StopRtn))
		{
        	Write-Output ($VMName + " failed to stop" )
        	Write-Error ($VMName + " failed to stop. Error was:" ) -ErrorAction Continue
			Write-Error (ConvertTo-Json $StopRtn.Error) -ErrorAction Continue
		}
		else
		{
			Write-Output ($VMName + " has been stopped" )
		}
	}
	else
	{
		Write-Output ($VMName + " is already stopped" )
	}
`n}
