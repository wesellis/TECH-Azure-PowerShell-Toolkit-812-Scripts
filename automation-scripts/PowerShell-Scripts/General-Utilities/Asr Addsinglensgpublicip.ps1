<#
.SYNOPSIS
    We Enhanced Asr Addsinglensgpublicip

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
    .DESCRIPTION 
        This will create a Public IP address for the failed over VM - only in test failover. 
         
        Pre-requisites 
        1. when you create a new Automation Account, make sure you have chosen to create a run-as account with it. 
        2. If you create a run as account on your own, give the Connection Name in the variable - $connectionName 
                 
        What all you need to change in this script? 
        1. Give the name of the Automation account in the variable - $WEAutomationAccountName 
        2. Give the Resource Group name of the Automation Account in $WEAutomationAccountRg 
         
        Do you want to add a NSG to the failed over VM? If yes, follow the below steps - you can skip this step if you dont want to add an NSG. 
        1. Create the NSG that you want to apply 
        2. Create a new Azure automation string variable <RecoveryPlanName>-NSG (example testrp-NSG). Save it with the value of the NSG you want to use. 
        3. Create a new Azure automation string variable <RecoveryPlanName>-NSGRG (example testrp-NSGRG). Save it with the value of the NSG's Resource group you want to use. 
         
        How to add the script? 
        Add this script as a post action in boot up group for which you need a public IP. All the VMs in the group will get a public IP assigned. 
        If the NSG parameters are specified, all the VM's NICs will get the same NSG attached. 
         
        Clean up test failover behavior 
        Clean up test failover will not delete the IP address. You will need to delete the IP address manually 
 
 
    .NOTES 
        AUTHOR: RuturajD@microsoft.com 
        LASTEDIT: 27 January, 2017 

 
 
 
workflow ASR-AddSingleNSGPublicIp { 
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [parameter(Mandatory=$false)] 
        [Object]$WERecoveryPlanContext 
    ) 
 
    $connectionName = "AzureRunAsConnection" 
    $WEAutomationAccountName = "" #Fill this up with you Azure Automation Account Name 
    $WEAutomationAccountRg = ""    #Fill this up with you Azure Automation Account Resource Group 
 
    # This is special code only added for this test run to avoid creating public IPs in S2S VPN network 
    if ($WERecoveryPlanContext.FailoverType -ne " Test") { 
        exit 
    } 
 
    try 
    { 
        # Get the connection " AzureRunAsConnection " 
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName          
 
         
 
        " Logging in to Azure..." 
        #Add-AzureRmAccount ` 
        Login-AzureRmAccount ` 
            -ServicePrincipal ` 
            -TenantId $servicePrincipalConnection.TenantId ` 
            -ApplicationId $servicePrincipalConnection.ApplicationId ` 
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint  
    } 
    catch { 
        if (!$servicePrincipalConnection) 
        { 
            $WEErrorMessage = " Connection $connectionName not found." 
            throw $WEErrorMessage 
        } else{ 
            Write-Error -Message $_.Exception 
            throw $_.Exception 
        } 
    } 
     
    $WEVMinfo = $WERecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name 
     
    Write-output $WERecoveryPlanContext.VmMap 
    Write-output $WERecoveryPlanContext 
     
    # Get the NSG based on the name 
    # if he has not passed this value just create the public IP and go ahead 
     
 
    $WENSGValue = $WERecoveryPlanContext.RecoveryPlanName + " -NSG" 
    $WENSGRGValue = $WERecoveryPlanContext.RecoveryPlanName + " -NSGRG" 
    Write-Output $WENSGValue 
    Write-Output $WENSGRGValue 
     
    $WENSGnameVar = Get-AzureRMAutomationVariable -AutomationAccountName $WEAutomationAccountName -Name $WENSGValue -ResourceGroupName $WEAutomationAccountRg  
    $WERGnameVar = Get-AzureRMAutomationVariable -AutomationAccountName $WEAutomationAccountName -Name $WENSGRGValue -ResourceGroupName $WEAutomationAccountRg  
 
 
    $WENSGname = $WENSGnameVar.value 
    $WENSGRGname = $WERGnameVar.value 
    Write-Output $WENSGname 
    Write-Output $WENSGRGname 
 
    #For all VMs in the group - loop and get the VMs 
 
   ;  $WEVMs = $WERecoveryPlanContext.VmMap; 
     
    $vmMap = $WERecoveryPlanContext.VmMap 
     
    foreach($WEVMID in $WEVMinfo) 
    { 
        $WEVM = $vmMap.$WEVMID                 
 
        if( !(($WEVM -eq $WENull) -Or ($WEVM.ResourceGroupName -eq $WENull) -Or ($WEVM.RoleName -eq $WENull))) { 
            #this is when some data is anot available and it will fail 
            Write-output " Resource group name ", $WEVM.ResourceGroupName 
            Write-output " Rolename " = $WEVM.RoleName 
 
            InlineScript {  
                             
                $azurevm = Get-AzureRMVM -ResourceGroupName $WEUsing:VM.ResourceGroupName -Name $WEUsing:VM.RoleName 
                write-output " Azure VM Id", $azurevm.Id 
                $WENicArmObject = Get-AzureRmResource -ResourceId $azurevm.NetworkInterfaceIDs[0] 
                write-output " Nic Arm Object Id = ", $WENicArmObject.Id 
                $WEVMNetworkInterfaceObject = Get-AzureRmNetworkInterface -Name $WENicArmObject.Name -ResourceGroupName $WENicArmObject.ResourceGroupName 
                write-output " Nic Interface Id", $WEVMNetworkInterfaceObject.Id  
                $WEPIP = New-AzureRmPublicIpAddress -Name $azurevm.Name -ResourceGroupName $WEUsing:VM.ResourceGroupName -Location $azurevm.Location -AllocationMethod Dynamic -Confirm:$false 
                If($WEPIP -ne $WENull) { 
                    Write-output " Public IP Id = ", $WEPIP.Id 
                    $WEVMNetworkInterfaceObject.IpConfigurations[0].PublicIpAddress = $WEPIP  
                } 
                if (($WEUsing:NSGname -ne $WENull) -And ($WEUsing:NSGRGname -ne $WENull)) { 
                   ;  $WENSG = Get-AzureRmNetworkSecurityGroup -Name $WEUsing:NSGname -ResourceGroupName $WEUsing:NSGRGname 
                    Write-output $WENSG.Id 
                    $WEVMNetworkInterfaceObject.NetworkSecurityGroup = $WENSG 
                } 
                #Update the properties now 
                Set-AzureRmNetworkInterface -NetworkInterface $WEVMNetworkInterfaceObject 
            } 
        }  
    }     
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================