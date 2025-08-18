<#
.SYNOPSIS
    We Enhanced Asr Dns Updateip

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
        This script updates the DNS of virtual machine being failed over  
         
        Pre-requisites 
        1. When you create a new Automation Account, make sure you have chosen to create a run-as account with it. 
        2. If you create a run as account on your own, give the Connection Name in the variable - $connectionName 
        3. Do a test failover of DNS virtual machine in the test network
         

        What all you need to change in this script? 
        1. Change the value of $WELocation in the runbook, with the region where the Azure VMs will be running
        2. Change the value of TestDNSVMName with the name of the DNS Azure virtual machine created in test network
        3. Change the value of TestDNSVMRG with the name resource group of the DNS Azure virtual machine created in test network
        4. Change the value of ProdDNSVMName with the name of the DNS Azure virtual machine in your Azure production network
        5. Change the value of ProdDNSVMRG with the name resource group of the DNS Azure virtual machine in your Azure production network
        

        How to add the script? 
        Add this script as a post action in a recovery plan group which has the virtual machines for which DNS has to be updated 
         
        Input Parameters
        Create an input parameter using the following powershell script. 
        $WEInputObject = @{"#VMIdAsAvailableINASRVMProperties" =@{"Zone" ="#ZoneFortheVirtualMachine" ;"VMName" ="#HostNameofTheVirtualMachine" };"#VMIdAsAvailableINASRVMProperties2" =@{"Zone" ="#ZoneFortheVirtualMachine2" ;"VMName" ="#HostNameofTheVirtualMachine2" }}
        $WERPDetails = New-Object -TypeName PSObject -Property $WEInputObject  | ConvertTo-Json
        New-AzureRmAutomationVariable -Name "#RecoveryPlanName" -ResourceGroupName " #AutomationAccountResourceGroup" -AutomationAccountName " #AutomationAccountName" -Value $WERPDetails -Encrypted $false  

        Replace all strings starting with a '#' with appropriate value

        1. VMIdAsAvailableINASRVMProperties : VM Id as shown in virtual machine properties inside Recovery services vault (https://docs.microsoft.com/en-in/azure/site-recovery/site-recovery-runbook-automation#using-complex-variable-to-store-more-information)
try {
    # Main script execution
2. ZoneFortheVirtualMachine : Zone of the virtual machine
        3. HostNameofTheVirtualMachine : Host name of the virtual machine. For example for a virtual machine with FQDN myvm.contoso.com HostNameofTheVirtualMachine is myvm and Zone is contoso.com. You can add more such blocks if there are more virtual machines being failed over as part of the recovery plan. 
        4. RecoveryPlanName : Name of the RecoveryPlanName where this script will be added.
        5. AutomationAccountName : Name of the Automation Account where this script is stored.
        6. AutomationAccountResourceGroup : Name of the Resource Group of Automation Account where this script is stored.

 
    .NOTES 
        AUTHOR: Prateek.Sharma@microsoft.com 
        LASTEDIT: 20 April, 2017 




workflow ASR-DNS-UpdateIP
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [parameter(Mandatory=$false)] 
        [Object]$WERecoveryPlanContext 
    ) 
 
    $connectionName = " AzureRunAsConnection" 
    $scriptpath = " https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/asr-automation-recovery/scripts/UpdateDNS.ps1"

    $WELocation = ""
    $WETestDNSVMName = ""
    $WETestDNSVMRG = ""
    $WEProdDNSVMName = ""
    $WEProdDNSVMRG = ""
    
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

 
    $WEVMinfo = $WERecoveryPlanContext.VmMap | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
    $vmMap = $WERecoveryPlanContext.VmMap

    if ($WERecoveryPlanContext.FailoverType -ne " Test") { 
         $WEDNSVMRG =   $WEProdDNSVMRG
         $WEDNSVMName =   $WEProdDNSVMName   
    }
    else {
         $WEDNSVMRG =   $WETestDNSVMRG
         $WEDNSVMName =   $WETestDNSVMName

    }

    $WERPVariable = Get-AutomationVariable -Name $WERecoveryPlanContext.RecoveryPlanName

    $WERPVariable = $WERPVariable | convertfrom-json

    Write-Output $WERPVariable

 foreach($WEVMID in $WEVMinfo) 
    { 
        
           $WEVM = $vmMap.$WEVMID
           $WEVMDetails = $WERPVariable.$WEVMID
           Write-output " VMDetails:" $WEVMDetails
        if( !(($WEVM -eq $WENull) -Or ($WEVM.ResourceGroupName -eq $WENull) -Or ($WEVM.RoleName -eq $WENull) -Or ($WEVMDetails -eq $WENull) -Or ($WEVMDetails.zone -eq $WENull) -Or ($WEVMDetails.VMName -eq $WENull))) { 
            #this is when some data is not available and it will fail 
 
            InlineScript{
                $azurevm = Get-AzureRMVM -ResourceGroupName $WEUsing:VM.ResourceGroupName -Name $WEUsing:VM.RoleName 
                write-output " Updating DNS for" $azurevm.Id 
                $WENicArmObject = Get-AzureRmResource -ResourceId $azurevm.NetworkInterfaceIDs[0] 
                $WEVMNetworkInterfaceObject = Get-AzureRmNetworkInterface -Name $WENicArmObject.Name -ResourceGroupName $WENicArmObject.ResourceGroupName
                $WEIPconfiguration = $WEVMNetworkInterfaceObject.IpConfigurations[0]
                $WEIP =  $WEIPconfiguration.PrivateIpAddress
                $zone = $WEUsing:VMDetails.Zone
                $WEVMName = $WEUsing:VMDetails.VMName

                $argument = " -Zone " + $WEZone + " -name " + $WEVMName + " -IP " + $WEIP

                Write-Output " Removing older custom script extension"
                $WEDNSVM = Get-AzureRMVM -ResourceGroupName $WEUsing:DNSVMRG -Name $WEUsing:DNSVMName
               ;  $csextension = $WEDNSVM.Extensions |  Where-Object {$_.VirtualMachineExtensionType -eq " CustomScriptExtension"}
                Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $WEUsing:DNSVMRG -VMName $WEUsing:DNSVMName -Name $csextension.Name -Force

                Write-output " Updating DNS with arguments:" $argument
                Set-AzureRmVMCustomScriptExtension -ResourceGroupName $WEUsing:DNSVMRG -VMName $WEUsing:DNSVMName -Location $WEUsing:Location -FileUri $WEUsing:scriptpath -Run UpdateDNS.ps1 -Name UpdateDNSCustomScript -Argument $argument 
                Write-output " Completed DNS Update"
            }
        }  

    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
