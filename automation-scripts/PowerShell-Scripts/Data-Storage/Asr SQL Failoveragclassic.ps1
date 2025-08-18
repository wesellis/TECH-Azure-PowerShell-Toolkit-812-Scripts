<#
.SYNOPSIS
    Asr Sql Failoveragclassic

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
    We Enhanced Asr Sql Failoveragclassic

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
        This script fails over SQL Always On Availability Group inside a Classic Azure virtual machine  
         
	Pre-requisites 
	The script below assumes that the SQL Availability Group is hosted in a classic Azure VM
	
	and that the name of restored virtual machine in Step-2 is SQLAzureVM-Test. Modify the script, based on the name you use for the recovered virtual machine.


	What all you need to change in this script? 
        1. Change the name of the Azure virtual machine. This script assumes that the SQL virtual machine created for test failover is named SQLAzureVM-Test and the SQL virtual machine that will be used in failvoer is named SQLAzureVM-Test
	2. Change service  
	3. Change the IP address to be used for load balancer.
	4. Change the path of the availability group. 

        How to add the script? 
        Add this script as a pre action of the first group of the recovery plan 
 
    .NOTES 
        AUTHOR: Prateek.Sharma@microsoft.com 
        LASTEDIT: 15 May, 2017 




workflow ASR-SQL-FailoverAGClassic
 {

     [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
         [Object]$WERecoveryPlanContext
     )

     $WECred = Get-AutomationPSCredential -name 'AzureCredential'

     #Connect to Azure
     $WEAzureAccount = Add-AzureAccount -Credential $WECred
    ;  $WEAzureSubscriptionName = Get-AutomationVariable -ErrorAction Stop –Name ‘AzureSubscriptionName’
     Select-AzureSubscription -SubscriptionName $WEAzureSubscriptionName

     InLineScript
     {
     ;  $scriptpath = " https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/asr-automation-recovery/scripts/SQLAGFailover.ps1"



      Write-output " failovertype " + $WEUsing:RecoveryPlanContext.FailoverType;

      if ($WEUsing:RecoveryPlanContext.FailoverType -eq " Test" )
            {
                Write-output " tfo"

                Write-Output " Creating ILB"
                Add-AzureInternalLoadBalancer -InternalLoadBalancerName SQLAGILB -SubnetName Subnet-1 -ServiceName SQLAzureVM-Test -StaticVNetIPAddress #IP
                Write-Output " ILB Created"

                #Update the script with name of the virtual machine recovered using Azure Backup
                Write-Output " Adding SQL AG Endpoint"
                Get-AzureVM -ServiceName " SQLAzureVM-Test" -Name " SQLAzureVM-Test" | Add-AzureEndpoint -Name sqlag -LBSetName sqlagset -Protocol tcp -LocalPort 1433 -PublicPort 1433 -ProbePort 59999 -ProbeProtocol tcp -ProbeIntervalInSeconds 10 -InternalLoadBalancerName SQLAGILB | Update-AzureVM

                Write-Output " Added Endpoint"

                $WEVM = Get-AzureVM -Name " SQLAzureVM-Test" -ServiceName " SQLAzureVM-Test"

                Write-Output " UnInstalling custom script extension"
                Set-AzureVMCustomScriptExtension -Uninstall -ReferenceName CustomScriptExtension -VM $WEVM |Update-AzureVM
                Write-Output " Installing custom script extension"
                Set-AzureVMExtension -ExtensionName CustomScriptExtension -VM $vm -Publisher Microsoft.Compute -Version 1.*| Update-AzureVM   

                Write-output " Starting AG Failover"
                Set-AzureVMCustomScriptExtension -VM $WEVM -FileUri $scriptpath -Run " SQLAGFailover.ps1" -Argument " -Path sqlserver:\sql\sqlazureVM\default\availabilitygroups\testag"  | Update-AzureVM
                Write-output " Completed AG Failover"
            }
      else
            {
            Write-output " pfo/ufo" ;
            #Get the SQL Azure Replica VM.
            #Update the script to use the name of your VM and Cloud Service
            $WEVM = Get-AzureVM -Name " SQLAzureVM" -ServiceName " SQLAzureReplica" ;     

            Write-Output " Installing custom script extension"
            #Install the Custom Script Extension on teh SQL Replica VM
            Set-AzureVMExtension -ExtensionName CustomScriptExtension -VM $WEVM -Publisher Microsoft.Compute -Version 1.*| Update-AzureVM;

            Write-output " Starting AG Failover" ;
            #Execute the SQL Failover script
            #Pass the SQL AG path as the argument.

            $WEAGArgs=" -SQLAvailabilityGroupPath sqlserver:\sql\sqlazureVM\default\availabilitygroups\testag" ;

            Set-AzureVMCustomScriptExtension -VM $WEVM -FileUri $scriptpath -Run " SQLAGFailover.ps1" -Argument $WEAGArgs | Update-AzureVM;

            Write-output " Completed AG Failover" ;

            }

     }
 }



} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
