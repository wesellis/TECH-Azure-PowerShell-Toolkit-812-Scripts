<#
.SYNOPSIS
    Azurevminventory Schedules Ms Mgmt

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
    We Enhanced Azurevminventory Schedules Ms Mgmt

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter (Mandatory= $false)]
    [int] $frequency=30,
        [Parameter(Mandatory=$false)] [bool] $getNICandNSG=$true,
    [Parameter(Mandatory=$false)] [bool] $getDiskInfo=$true,
    [Parameter(Mandatory=$false)] [bool] $clearLocks=$false
    )




Write-Verbose " Logging in to Azure..."
$WEConn = Get-AutomationConnection -Name AzureRunAsConnection 


$retry = 6
$syncOk = $false
do
{ 
	try
	{  
		Add-AzureRMAccount -ServicePrincipal -Tenant $WEConn.TenantID -ApplicationId $WEConn.ApplicationID -CertificateThumbprint $WEConn.CertificateThumbprint
		$syncOk = $true
	}
	catch
	{
		$WEErrorMessage = $_.Exception.Message
		$WEStackTrace = $_.Exception.StackTrace
		Write-Warning " Error during sync: $WEErrorMessage, stack: $WEStackTrace. Retry attempts left: $retry"
		$retry = $retry - 1       
		Start-Sleep -s 60        
	}
} while (-not $syncOk -and $retry -ge 0)

Write-Verbose " Selecting Azure subscription..."
Select-AzureRmSubscription -SubscriptionId $WEConn.SubscriptionID -TenantId $WEConn.tenantid 




$WEAAResourceGroup = Get-AutomationVariable -Name 'AzureVMInventory-AzureAutomationResourceGroup-MS-Mgmt'
$WEAAAccount = Get-AutomationVariable -Name 'AzureVMInventory-AzureAutomationAccount-MS-Mgmt'
$WERunbookName = " AzureVMInventory-MS-Mgmt"
$WEScheduleName = " AzureVMInventory-Scheduler-Hourly"
$schedulerrunbookname=" AzureVMInventory-Schedules-MS-Mgmt"
$varVMIopsList=" AzureVMInventory-VM-IOPSLimits"




If ($clearLocks)
{
        $lockList = Get-AzureRmResourceLock -ErrorAction Stop `
		-ResourceGroupName $WEAAResourceGroup
        " $($locklist|where {$_.Name -match " AzureVMInventory" }).count) locks found "

            foreach ($l in $lockList|where {$_.Name -match " AzureVMInventory" }) 
            {

                    Write-Verbose " CleanUp:  Removing lock $l "
                    Remove-AzureRmResourceLock -LockId $l.LockId -Force

            }
 }
   

; 
$iopslist=Get-AzureRmAutomationVariable -Name $varVMIopsList -ResourceGroupName $WEAAResourceGroup -AutomationAccountName $WEAAAccount
If (!$iopslist)
{
   ;  $vmiolimits=@{" Basic_A0" =300;
" Basic_A1" =300;
" Basic_A2" =300;
" Basic_A3" =300;
" Basic_A4" =300;
" ExtraSmall" =500;
" Small" =500;
" Medium" =500;
" Large" =500;
" ExtraLarge" =500;
" Standard_A0" =500;
" Standard_A1" =500;
" Standard_A2" =500;
" Standard_A3" =500;
" Standard_A4" =500;
" Standard_A5" =500;
" Standard_A6" =500;
" Standard_A7" =500;
" Standard_A8" =500;
" Standard_A9" =500;
" Standard_A10" =500;
" Standard_A11" =500;
" Standard_A1_v2" =500;
" Standard_A2_v2" =500;
" Standard_A4_v2" =500;
" Standard_A8_v2" =500;
" Standard_A2m_v2" =500;
" Standard_A4m_v2" =500;
" Standard_A8m_v2" =500;
" Standard_D1" =500;
" Standard_D2" =500;
" Standard_D3" =500;
" Standard_D4" =500;
" Standard_D11" =500;
" Standard_D12" =500;
" Standard_D13" =500;
" Standard_D14" =500;
" Standard_D1_v2" =500;
" Standard_D2_v2" =500;
" Standard_D3_v2" =500;
" Standard_D4_v2" =500;
" Standard_D5_v2" =500;
" Standard_D11_v2" =500;
" Standard_D12_v2" =500;
" Standard_D13_v2" =500;
" Standard_D14_v2" =500;
" Standard_D15_v2" =500;
" Standard_DS1" =3200;
" Standard_DS2" =6400;
" Standard_DS3" =12800;
" Standard_DS4" =25600;
" Standard_DS11" =6400;
" Standard_DS12" =12800;
" Standard_DS13" =25600;
" Standard_DS14" =51200;
" Standard_DS1_v2" =3200;
" Standard_DS2_v2" =6400;
" Standard_DS3_v2" =12800;
" Standard_DS4_v2" =25600;
" Standard_DS5_v2" =51200;
" Standard_DS11_v2" =6400;
" Standard_DS12_v2" =12800;
" Standard_DS13_v2" =25600;
" Standard_DS14_v2" =51200;
" Standard_DS15_v2" =64000;
" Standard_F1" =500;
" Standard_F2" =500;
" Standard_F4" =500;
" Standard_F8" =500;
" Standard_F16" =500;
" Standard_F1s" =3200;
" Standard_F2s" =6400;
" Standard_F4s" =12800;
" Standard_F8s" =25600;
" Standard_F16s" =51200;
" Standard_G1" =500;
" Standard_G2" =500;
" Standard_G3" =500;
" Standard_G4" =500;
" Standard_G5" =500;
" Standard_GS1" =5000;
" Standard_GS2" =10000;
" Standard_GS3" =20000;
" Standard_GS4" =40000;
" Standard_GS5" =80000;
" Standard_H8" =500;
" Standard_H16" =500;
" Standard_H8m" =500;
" Standard_H16m" =500;
" Standard_H16r" =500;
" Standard_H16mr" =500;
" Standard_NV6" =500;
" Standard_NV12" =500;
" Standard_NV24" =500;
" Standard_NC6" =500;
" Standard_NC12" =500;
" Standard_NC24" =500;
" Standard_NC24r" =500}
    New-AzureRmAutomationVariable -Name $varVMIopsList -Description " Variable to store IOPS limits for Azure VM Sizes." -Value $vmiolimits -Encrypted 0 -ResourceGroupName $WEAAResourceGroup -AutomationAccountName $WEAAAccount  -ea 0

}






" Rescheduling the runbook to check and fix scheules weekly"


    $WERunbookStartTime = $WEDate = $([DateTime]::Now.AddMinutes(10))
    $WERunbookScheduleTime=$([DateTime]::Now.AddMinutes($WEFrequency))

    $WERBsch=$null

    $WERBsch=get-AzureRmAutomationScheduledRunbook -RunbookName $schedulerrunbookname -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup 

    # Pattern matching for validation; 
# Pattern matching for validation
$WERBsch=$WERBsch|where{$_.ScheduleName -match 'AzureVMInventory-Scheduler'}

   
    IF([string]::IsNullOrEmpty($WERBsch))
    {
   
          " No schedule found, will create a new weekly schedule"
    
        if(Get-AzureRmAutomationSchedule -Name 'AzureVMInventory-Scheduler-Weekly' -ResourceGroupName $WEAAResourceGroup -AutomationAccountName $WEAAAccount)
        {
            remove-AzureRmAutomationSchedule -Name 'AzureVMInventory-Scheduler-Weekly' -ResourceGroupName $WEAAResourceGroup -AutomationAccountName $WEAAAccount  -Force
        }
    
   ;  $params1 = @{" frequency" =$frequency;" getNICandNSG" =$getNICandNSG;" getDiskInfo" = $getDiskInfo}
	$WESchedule1 = New-AzureRmAutomationSchedule -Name 'AzureVMInventory-Scheduler-Weekly' -StartTime $WERunbookScheduleTime -DayInterval 7 -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup
    $WESch1 = Register-AzureRmAutomationScheduledRunbook -RunbookName $schedulerrunbookname -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup -ScheduleName 'AzureVMInventory-Scheduler-Weekly' -Parameters $params1
    
    $runnow=$true

    
    }Elseif($WERBsch|where{$_.ScheduleName  -match 'Hourly'})
    {
    
        " Initial schedule found. We will replace initital schedule with a weekly one"
        

        if(Get-AzureRmAutomationSchedule -Name 'AzureVMInventory-Scheduler-Weekly' -ResourceGroupName $WEAAResourceGroup -AutomationAccountName $WEAAAccount)
        {
            remove-AzureRmAutomationSchedule -Name 'AzureVMInventory-Scheduler-Weekly' -ResourceGroupName $WEAAResourceGroup -AutomationAccountName $WEAAAccount  -Force
        }

        $hourlysch=$WERBsch|where{$_.ScheduleName  -match 'Hourly'}
               ;  $WERunbookStartTime = $WERunbookStartTime.Addhours(24)
       ;  $params1 = @{" frequency" =$frequency;" getNICandNSG" =$getNICandNSG;" getDiskInfo" = $getDiskInfo;" clearLocks" =0}

	 Remove-AzureRmAutomationSchedule -AutomationAccountName $WEAAAccount -Name $hourlysch.ScheduleName  -ResourceGroupName $WEAAResourceGroup -Force
     $WESchedule1 = New-AzureRmAutomationSchedule -Name 'AzureVMInventory-Scheduler-Weekly' -StartTime $WERunbookStartTime -DayInterval 7 -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup 
    $WESch1 = Register-AzureRmAutomationScheduledRunbook -RunbookName $schedulerrunbookname -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup -ScheduleName 'AzureVMInventory-Scheduler-Weekly' -Parameters $params1
    $runnow=$true
            
    }Else
    {
    " Weekly frequency found for scheduler , will not make any change" 
    $runnow=$false
    
    }




$WENumberofSchedules = 60 / $WEFrequency

$checkschdl=@(get-AzureRmAutomationScheduledRunbook -RunbookName $WERunbookName -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup)

If ([string]::IsNullOrEmpty($checkschdl)  -or  $WENumberofSchedules -ne  $checkschdl.Count)
{


    $sch=$null
    $WERBsch=Get-AzureRmAutomationSchedule -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup|where{$_.name -match $WEScheduleName}
    IF($WERBsch)
    {
	    foreach ($sch in $WERBsch)
	    {
		    Remove-AzureRmAutomationSchedule -AutomationAccountName $WEAAAccount -Name $sch.Name -ResourceGroupName $WEAAResourceGroup -Force -ea 0
		
	    }
    }




Write-Verbose " $WENumberofSchedules schedules will be created for VM inventory "

$WERunbookStartTime =;  $WEDate = $([DateTime]::Now.AddMinutes(10))
; 
$params = @{" getNICandNSG" =$getNICandNSG;" getDiskInfo" = $getDiskInfo}

$WECount = 0
While ($count -lt $WENumberofSchedules)
{
    $count ++

    Write-Verbose " Creating schedule $WEScheduleName-$WECount for $WERunbookStartTime for runbook $WERunbookName"
    $WESchedule = New-AzureRmAutomationSchedule -Name " $WEScheduleName-$WECount" -StartTime $WERunbookStartTime -HourInterval 1 -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup
   ;  $WESch = Register-AzureRmAutomationScheduledRunbook -RunbookName $WERunbookName -AutomationAccountName $WEAAAccount -ResourceGroupName $WEAAResourceGroup -ScheduleName " $WEScheduleName-$WECount" -Parameters $params
   ;  $WERunbookStartTime = $WERunbookStartTime.AddMinutes($frequency)
}

    If($runnow)
    {
        Start-AzureRmAutomationRunbook -AutomationAccountName $WEAAAccount -Name $WERunbookName -ResourceGroupName $WEAAResourceGroup -Parameters $params
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================