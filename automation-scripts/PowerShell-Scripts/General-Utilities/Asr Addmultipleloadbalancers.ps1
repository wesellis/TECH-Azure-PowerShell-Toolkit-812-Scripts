<#
.SYNOPSIS
    Asr Addmultipleloadbalancers

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
    We Enhanced Asr Addmultipleloadbalancers

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
        This runbook will attach an existing load balancer to the vNics of the virtual machines, in the Recovery Plan during failover. 
         
        This will create a Public IP address for the failed over VM(s)
try {
    # Main script execution
. 
         
        Pre-requisites 
        All resources involved are based on Azure Resource Manager (NOT Azure Classic)

        - A Load Balancer(s) with a backend pool
        - A complex Automation Variable, containing the VMGUID for each VM, ResourceGroupName for the Load Balancer(s) and the Load Balancer(s) name.
        Example:
        
        $WERPdetails = @{"6949b3a9-ae82-5e90-882c-30e48dffdcd8" =@{" ResourceGroupName" =" knlb" ;" LBName" =" knextlb" };" 6dce5d61-2416-546c-9bcd-c1bc79a5a678" =@{" ResourceGroupName" =" knlb" ;" LBName" =" knintlb" }}

        $myASRobject = New-Object -TypeName PSObject -Property $WERPdetails

        $WEASRVariable = $myASRobject | ConvertTo-Json

        New-AzureRmAutomationVariable -Name <recoveryPlanName> -ResourceGroupName <automationResourceGroup> -AutomationAccountName <automationAccountName> -Value $WEASRVariable -Encrypted $false 

        The following AzureRm Modules are required
        - AzureRm.Profile
        - AzureRm.Resources
        - AzureRm.Compute
        - AzureRm.Network          
         
        How to add the script? 
        Add this script as a post action in boot up group where you need to associate the VMs with the existing Load Balancer                
 
    .NOTES 
        AUTHOR: krnese@microsoft.com - AzureCAT
        LASTEDIT: 20 March, 2017 

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Object]$WERecoveryPlanContext 
      ) 

Write-output $WERecoveryPlanContext



$WEErrorActionPreference = " Stop"

if ($WERecoveryPlanContext.FailoverDirection -ne " PrimaryToSecondary" ) 
    {
        Write-Output " Failover Direction is not Azure, and the script will stop."
    }
else {
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
Try 
 {
    #Logging in to Azure...

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
Try
 {
    $WERPVariable = Get-AutomationVariable -Name $WERecoveryPlanContext.RecoveryPlanName

    $WERPVariable = $WERPVariable | convertfrom-json

    Write-Output $WERPVariable
 }
Catch
 {
    $WEErrorMessage = 'Failed to retrieve Load Balancer info from Automation variables.'
    $WEErrorMessage = $WEErrorMessage + " `n"
    $WEErrorMessage = $WEErrorMessage + 'Error: '
    $WEErrorMessage = $WEErrorMessage + $_
    Write-Error -Message $WEErrorMessage `
                   -ErrorAction Stop
 }
    #Getting VM details from the Recovery Plan Group, and associate the vNics with the Load Balancer
Try
 {
    $WEVMinfo = $WERecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
    $WEVMs = $WERecoveryPlanContext.VmMap
    $vmMap = $WERecoveryPlanContext.VmMap
    foreach ($WEVMID in $WEVMinfo)
    {
        $WEVM = $vmMap.$WEVMID
        $WEVMDetails = $WERPVariable.$WEVMID

        if( !(($WEVM -eq $WENull) -Or ($WEVM.ResourceGroupName -eq $WENull) -Or ($WEVM.RoleName -eq $WENull) -Or ($WEVMDetails -eq $WENull) -Or ($WEVMDetails.ResourceGroupName -eq $WENull) -Or ($WEVMDetails.LBName -eq $WENull))) { 

            $WELoadBalancer = Get-AzureRmLoadBalancer -ResourceGroupName $WERPVariable.$WEVMID.ResourceGroupName -Name $WERPVariable.$WEVMID.LBName 
            Write-Output $WELoadBalancer
            $WEVM = $vmMap.$WEVMID
            Write-Output $WEVM.ResourceGroupName
            Write-Output $WEVM.RoleName    
            $WEAzureVm = Get-AzureRmVm -ResourceGroupName $WEVM.ResourceGroupName -Name $WEVM.RoleName    
            If ($WEAzureVm.AvailabilitySetReference -eq $null)
            {
                Write-Output " No Availability Set is present for VM: `n" $WEAzureVm.Name
            }
            else
            {
                Write-Output " Availability Set is present for VM: `n" $WEAzureVm.Name
            }
            #Join the VMs NICs to backend pool of the Load Balancer
           ;  $WEARMNic = Get-AzureRmResource -ResourceId $WEAzureVm.NetworkInterfaceIDs[0]
           ;  $WENic = Get-AzureRmNetworkInterface -Name $WEARMNic.Name -ResourceGroupName $WEARMNic.ResourceGroupName
            $WENic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($WELoadBalancer.BackendAddressPools[0]);        
            $WENic | Set-AzureRmNetworkInterface    
            Write-Output " Done configuring Load Balancing for VM" $WEAzureVm.Name    
        }
    }
 }
Catch
 {
    $WEErrorMessage = 'Failed to associate the VM with the Load Balancer.'
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
