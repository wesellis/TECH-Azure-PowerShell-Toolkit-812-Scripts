<#
.SYNOPSIS
    We Enhanced Autosnooze Createalert Child

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

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        $WEVMObject,
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAlertAction,
        [string]$WEWebhookUri
    )



function WE-Generate-AlertName 
{
    param ([string] $WEOldAlertName , 
     [string] $WEVMName)
         
    [string[]] $WEAlertSplit = $WEOldAlertName -split "-"
    [int] $WENumber =$WEAlertSplit[$WEAlertSplit.Length-1]
    $WENumber++
    $WENewalertname = " Alert-$($WEVMName)-$WENumber"
    return $WENewalertname
}


$connectionName = " AzureRunAsConnection"
try
{
    # Get the connection " AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    " Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$servicePrincipalConnection)
    {
        $WEErrorMessage = " Connection $connectionName not found."
        throw $WEErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}


$WESubId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'


$threshold = Get-AutomationVariable -Name 'External_AutoSnooze_Threshold'
$metricName = Get-AutomationVariable -Name 'External_AutoSnooze_MetricName'
$timeWindow = Get-AutomationVariable -Name 'External_AutoSnooze_TimeWindow'
$condition = Get-AutomationVariable -Name 'External_AutoSnooze_Condition' # Other valid values are LessThanOrEqual, GreaterThan, GreaterThanOrEqual
$description = Get-AutomationVariable -Name 'External_AutoSnooze_Description'
$timeAggregationOperator = Get-AutomationVariable -Name 'External_AutoSnooze_TimeAggregationOperator'
$webhookUri = Get-AutomationVariable -Name 'Internal_AutoSnooze_WebhookUri'


try
{

    $WEResourceGroupName =$WEVMObject.ResourceGroupName
    $WELocation = $WEVMObject.Location
    $WEVMState = (Get-AzureRmVM -ResourceGroupName $WEVMObject.ResourceGroupName -Name $WEVMObject.Name -Status -ErrorAction SilentlyContinue).Statuses.Code[1] 
    Write-Output " Processing VM ($($WEVMObject.Name))"
    Write-Output " Current VM state is ($($WEVMState))"
    $actionWebhook = New-AzureRmAlertRuleWebhook -ServiceUri $WEWebhookUri
    $resourceId = " /subscriptions/$($WESubId)/resourceGroups/$WEResourceGroupName/providers/Microsoft.Compute/virtualMachines/$($WEVMObject.Name.Trim())"
    $WENewAlertName =" Alert-$($WEVMObject.Name)-1"
                                                 
    if($WEAlertAction -eq " Disable")
    {
        $WEExVMAlerts = Get-AzureRmAlertRule -ResourceGroup $WEVMObject.ResourceGroupName -DetailedOutput -ErrorAction SilentlyContinue
                 if($WEExVMAlerts -ne $null)
                    {
                        Write-Output " Checking for any previous alert(s)..." 
                        #Alerts exists so disable alert
                        foreach($WEAlert in $WEExVMAlerts)
                        {
                                                
                            if($WEAlert.Name.ToLower().Contains($($WEVMObject.Name.ToLower().Trim())))
                            {
                                Write-Output " Previous alert ($($WEAlert.Name)) found and disabling now..." 
                                 Add-AzureRmMetricAlertRule  -Name  $WEAlert.Name `
                                        -Location  $WEAlert.Location `
                                        -ResourceGroup $WEResourceGroupName `
                                        -TargetResourceId $resourceId `
                                        -MetricName $metricName `
                                        -Operator  $condition `
                                        -Threshold $threshold `
                                        -WindowSize  $timeWindow `
                                        -TimeAggregationOperator $timeAggregationOperator `
                                        -Actions $actionWebhook `
                                        -Description $description -DisableRule 

                                        Write-Output " Alert ($($WEAlert.Name)) Disabled for VM $($WEVMObject.Name)"
                                    
                            }
                        }
                           
                    }
    }
    elseif($WEAlertAction -eq " Create")
    {
        #Getting ResourcegroupName and Location based on VM  
                    
                        if ($WEVMState -eq 'PowerState/running') 
                        {                     
                            try
                            {
                                $WEVMAlerts = Get-AzureRmAlertRule -ResourceGroup $WEResourceGroupName -DetailedOutput -ErrorAction SilentlyContinue

                                #Check if alerts exists and take action
                                if($WEVMAlerts -ne $null)
                                {
                                    Write-Output " Checking for any previous alert(s)..." 
                                    #Alerts exists so delete and re-create the new alert
                                    foreach($WEAlert in $WEVMAlerts)
                                    {
                                                
                                        if($WEAlert.Name.ToLower().Contains($($WEVMObject.Name.ToLower().Trim())))
                                        {
                                            Write-Output " Previous alert ($($WEAlert.Name)) found and deleting now..." 
                                            #Remove the old alert
                                            Remove-AzureRmAlertRule -Name $WEAlert.Name -ResourceGroup $WEResourceGroupName
                                   
                                            #Wait for few seconds to make sure it processed 
                                            Do
                                            {
                                               #Start-Sleep 10    
                                               $WEGetAlert=Get-AzureRmAlertRule -ResourceGroup $WEResourceGroupName -Name $WEAlert.Name -DetailedOutput -ErrorAction SilentlyContinue                                       
                                                        
                                            }
                                            while($WEGetAlert -ne $null)
                                   
                                            Write-Output " Generating a new alert with unique name..."
                                            #Now generate new unique alert name
                                           ;  $WENewAlertName = Generate-AlertName -OldAlertName $WEAlert.Name -VMName $WEVMObject.Name               
                                    
                                        }
                                     }
                           
                                }
                                 #Alert does not exist, so create new alert
                                 Write-Output $WENewAlertName                
                                 
                                 Write-Output " Adding a new alert to the VM..."
                                 
                                 Add-AzureRmMetricAlertRule  -Name  $WENewAlertName `
                                        -Location  $location `
                                        -ResourceGroup $WEResourceGroupName `
                                        -TargetResourceId $resourceId `
                                        -MetricName $metricName `
                                        -Operator  $condition `
                                        -Threshold $threshold `
                                        -WindowSize  $timeWindow `
                                        -TimeAggregationOperator $timeAggregationOperator `
                                        -Actions $actionWebhook `
                                        -Description $description               
                               
                                           
                               Write-Output  " Alert Created for VM $($WEVMObject.Name.Trim())"    
                            }
                            catch
                            {
                             Write-Output " Error Occurred"   
                             Write-Output $_.Exception
                            }
                    
                         }
                         else
                         {
                            Write-Output " $($WEVM.Name) is De-allocated"
                         }
    }
  }
  catch
  {
    Write-Output " Error Occurred"   
    Write-Output $_.Exception
  }  



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================