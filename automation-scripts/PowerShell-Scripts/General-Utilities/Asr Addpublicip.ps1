<#
.SYNOPSIS
    Asr Addpublicip

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
    We Enhanced Asr Addpublicip

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
    .DESCRIPTION 
        This will create a Public IP address for the failed over VM(s)
try {
    # Main script execution
. 
         
        Pre-requisites 
        All resources involved are based on Azure Resource Manager (NOT Azure Classic)

        The following AzureRm Modules are required
        - AzureRm.Profile
        - AzureRm.Resources
        - AzureRm.Compute
        - AzureRm.Network

        How to add the script? 
        Add the runbook as a post action in boot up group containing the VMs, where you want to assign a public IP.. 
         
        Clean up test failover behavior 
        You must manually remove the Public IP interfaces 
 
    .NOTES 
        AUTHOR: krnese@microsoft.com 
        LASTEDIT: 20 March, 2017 

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Object]$WERecoveryPlanContext 
      ) 

Write-Output $WERecoveryPlanContext

if($WERecoveryPlanContext.FailoverDirection -ne 'PrimaryToSecondary')
{
    Write-Output 'Script is ignored since Azure is not the target'
}
else
{

    $WEVMinfo = $WERecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name

    Write-Output (" Found the following VMGuid(s): `n" + $WEVMInfo)

    if ($WEVMInfo -is [system.array])
    {
        $WEVMinfo = $WEVMinfo[0]

        Write-Output " Found multiple VMs in the Recovery Plan"
    }
    else
    {
        Write-Output " Found only a single VM in the Recovery Plan"
    }

    $WERGName = $WERecoveryPlanContext.VmMap.$WEVMInfo.ResourceGroupName

    Write-OutPut (" Name of resource group: " + $WERGName)
Try
 {
    " Logging in to Azure..."
    $WEConn = Get-AutomationConnection -Name AzureRunAsConnection 
     Add-AzureRMAccount -ServicePrincipal -Tenant $WEConn.TenantID -ApplicationId $WEConn.ApplicationID -CertificateThumbprint $WEConn.CertificateThumbprint

    " Selecting Azure subscription..."
    Select-AzureRmSubscription -SubscriptionId $WEConn.SubscriptionID -TenantId $WEConn.tenantid 
 }
Catch
 {
      $WEErrorMessage = 'Login to Azure subscription failed.'
      $WEErrorMessage = $WEErrorMessage + " `n"
      $WEErrorMessage = $WEErrorMessage + 'Error: '
      $WEErrorMessage = $WEErrorMessage + $_
      Write-Error -Message $WEErrorMessage `
                    -ErrorAction Stop
 }
    # Get VMs within the Resource Group
Try
 {
    $WEVMs = Get-AzureRmVm -ResourceGroupName $WERGName
    Write-Output (" Found the following VMs: `n " + $WEVMs.Name) 
 }
Catch
 {
      $WEErrorMessage = 'Failed to find any VMs in the Resource Group.'
      $WEErrorMessage = $WEErrorMessage + " `n"
      $WEErrorMessage = $WEErrorMessage + 'Error: '
      $WEErrorMessage = $WEErrorMessage + $_
      Write-Error -Message $WEErrorMessage `
                    -ErrorAction Stop
 }
Try
 {
    foreach ($WEVM in $WEVMs)
    {
        $WEARMNic = Get-AzureRmResource -ResourceId $WEVM.NetworkInterfaceIDs[0]
        $WENIC = Get-AzureRmNetworkInterface -Name $WEARMNic.Name -ResourceGroupName $WEARMNic.ResourceGroupName
       ;  $WEPIP = New-AzureRmPublicIpAddress -Name $WEVM.Name -ResourceGroupName $WERGName -Location $WEVM.Location -AllocationMethod Dynamic
        $WENIC.IpConfigurations[0].PublicIpAddress = $WEPIP
        Set-AzureRmNetworkInterface -NetworkInterface $WENIC     
        Write-Output (" Added public IP address to the following VM: " + $WEVM.Name)  
    }
    Write-Output (" Operation completed on the following VM(s): `n" + $WEVMs.Name)
 }
Catch
 {
     ;  $WEErrorMessage = 'Failed to add public IP address to the VM.'
      $WEErrorMessage = $WEErrorMessage + " `n"
      $WEErrorMessage = $WEErrorMessage + 'Error: '
     ;  $WEErrorMessage = $WEErrorMessage + $_
      Write-Error -Message $WEErrorMessage `
                    -ErrorAction Stop
 }
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
