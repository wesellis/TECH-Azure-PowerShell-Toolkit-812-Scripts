<#
.SYNOPSIS
    We Enhanced Asr Sql Failoverag

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
        This script fails over SQL Always On Availability Group inside an Azure virtual machine  
         
        Pre-requisites 
        1. When you create a new Automation Account, make sure you have chosen to create a run-as account with it. 
        2. If you create a run as account on your own, give the Connection Name in the variable - $connectionName 
        3. Setup Azure Backup on the SQL Always On Azure virtual machine
        4. Before doing a test failover, restore a copy of the SQL Always On Azure virtual machine in the test network
         

        What all you need to change in this script? 
        1. Change the value of $WELocaton with the region where SQl Always On Azure virtual machine is running 

        How to add the script? 
        Add this script as a pre action of the first group of the recovery plan 
         
        Input Parameters
        Create an input parameter using the following powershell script. 
        $WEInputObject = @{"TestSQLVMName" = " #TestSQLVMName" ; " TestSQLVMRG" = " #TestSQLVMRG" ; " ProdSQLVMName" = " #ProdSQLVMName" ; " ProdSQLVMRG" = " #ProdSQLVMRG"; " Paths" = @{" 1"=" #sqlserver:\sql\sqlazureVM\default\availabilitygroups\ag1";" 2"=" #sqlserver:\sql\sqlazureVM\default\availabilitygroups\ag2"}}
        $WERPDetails = New-Object -TypeName PSObject -Property $WEInputObject  | ConvertTo-Json
        New-AzureRmAutomationVariable -Name " #RecoveryPlanName" -ResourceGroupName " #AutomationAccountResourceGroup" -AutomationAccountName " #AutomationAccountName" -Value $WERPDetails -Encrypted $false  

        Replace all strings starting with a '#' with appropriate value

        1. TestSQLVMName : Name of the Azure virtual machine where you will restore SQL Always On Azure virtual machine using Azure Backup.
        2. TestSQLVMRG : Name of Resource Group of the Azure virtual machine where you will restore SQL Always On Azure virtual machine using Azure Backup.
        3. ProdSQLVMName : Name of the SQL Always On Azure virtual machine. 
        4. ProdSQLVMRG : Name of Resource Group of the SQL Always On Azure virtual machine.
        5. Paths : Fully qualified paths of the availability groups. You can add more such blocks if there are more availability groups to be failed over. This example shows two availability groups.  
        6. RecoveryPlanName : Name of the RecoveryPlanName where this script will be added.
        7. AutomationAccountName : Name of the Automation Account where this script is stored.
        8. AutomationAccountResourceGroup : Name of the Resource Group of Automation Account where this script is stored.

 
    .NOTES 
        AUTHOR: Prateek.Sharma@microsoft.com 
        LASTEDIT: 27 March, 2017 





workflow ASR-SQL-FailoverAG
{
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
        [parameter(Mandatory=$false)] 
        [Object]$WERecoveryPlanContext 
    ) 
 
    $connectionName = " AzureRunAsConnection" 
    $scriptpath = " https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/asr-automation-recovery/scripts/SQLAGFailover.ps1"
    $WELocation = " Southeast Asia"
    
    
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


    $WERPVariable = Get-AutomationVariable -Name $WERecoveryPlanContext.RecoveryPlanName
    $WERPVariable = $WERPVariable | convertfrom-json

    Write-Output $WERPVariable

    if ($WERecoveryPlanContext.FailoverType -ne " Test") { 
         $WESQLVMRG =   $WERPVariable.ProdSQLVMRG
         $WESQLVMName =   $WERPVariable.ProdSQLVMName   
    }
    else {
         $WESQLVMRG =   $WERPVariable.TestSQLVMRG
         $WESQLVMName =   $WERPVariable.TestSQLVMName
    }

    
    $WEPathSqno = $WERPVariable.Paths | Get-Member | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name 
    $WEPathDetails = $WERPVariable.Paths


 foreach($sqno in $WEPathSqno) 
    { 


      If(!(($sqno -eq " PSComputerName") -Or ($sqno -eq " PSShowComputerName") -Or ($sqno -eq " PSSourceJobInstanceId")))
      {  
  
           $WEAGPath = $WEPathDetails.$sqno
        if(!($WEAGPath -eq $WENull)){  
            #this is when some data is not available and it will fail 
 
            InlineScript{

                Write-Output " Removing older custom script extension"
                $WESQLVM = Get-AzureRMVM -ResourceGroupName $WEUsing:SQLVMRG -Name $WEUsing:SQLVMName
                $csextension = $WESQLVM.Extensions |  Where-Object {$_.VirtualMachineExtensionType -eq " CustomScriptExtension"}
                Remove-AzureRmVMCustomScriptExtension -ResourceGroupName $WEUsing:SQLVMRG -VMName $WEUsing:SQLVMName -Name $csextension.Name -Force

               ;  $argument = " -Path " + $WEUsing:AGPath

                Write-output " Failing over:" $argument
                Set-AzureRmVMCustomScriptExtension -ResourceGroupName $WEUsing:SQLVMRG -VMName $WEUsing:SQLVMName -Location $WEUsing:Location -FileUri $WEUsing:scriptpath -Run SQLAGFailover.ps1 -Name SQLAGCustomscript -Argument $argument 
                Write-output " Completed AG Failover"
            }
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
