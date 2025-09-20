#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Autosnooze Createalert Child

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        $VMObject,
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AlertAction,
        [string]$WebhookUri
    )
[OutputType([PSObject])]

{
    param ([string] $OldAlertName ,
     [string] $VMName)
    [string[]] $AlertSplit = $OldAlertName -split " -"
    [int] $Number =$AlertSplit[$AlertSplit.Length-1]
    $Number++
    $Newalertname = "Alert-$($VMName)-$Number"
    return $Newalertname
}
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName
    "Logging in to Azure..."
    $params = @{
        ApplicationId = $servicePrincipalConnection.ApplicationId
        TenantId = $servicePrincipalConnection.TenantId
        CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    }
    Add-AzureRmAccount @params
}
catch
{
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
$SubId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'
$threshold = Get-AutomationVariable -Name 'External_AutoSnooze_Threshold'
$metricName = Get-AutomationVariable -Name 'External_AutoSnooze_MetricName'
$timeWindow = Get-AutomationVariable -Name 'External_AutoSnooze_TimeWindow'
$condition = Get-AutomationVariable -Name 'External_AutoSnooze_Condition' # Other valid values are LessThanOrEqual, GreaterThan, GreaterThanOrEqual
$description = Get-AutomationVariable -Name 'External_AutoSnooze_Description'
$timeAggregationOperator = Get-AutomationVariable -Name 'External_AutoSnooze_TimeAggregationOperator'
$webhookUri = Get-AutomationVariable -Name 'Internal_AutoSnooze_WebhookUri'
try
{
    $ResourceGroupName =$VMObject.ResourceGroupName
    $Location = $VMObject.Location
    $VMState = (Get-AzureRmVM -ResourceGroupName $VMObject.ResourceGroupName -Name $VMObject.Name -Status -ErrorAction SilentlyContinue).Statuses.Code[1]
    Write-Output "Processing VM ($($VMObject.Name))"
    Write-Output "Current VM state is ($($VMState))"
    $actionWebhook = New-AzureRmAlertRuleWebhook -ServiceUri $WebhookUri
    $resourceId = " /subscriptions/$($SubId)/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines/$($VMObject.Name.Trim())"
    $NewAlertName ="Alert-$($VMObject.Name)-1"
    if($AlertAction -eq "Disable" )
    {
        $ExVMAlerts = Get-AzureRmAlertRule -ResourceGroup $VMObject.ResourceGroupName -Output -ErrorAction SilentlyContinue
                 if($null -ne $ExVMAlerts)
                    {
                        Write-Output "Checking for any previous alert(s)..."
                        #Alerts exists so disable alert
                        foreach($Alert in $ExVMAlerts)
                        {
                            if($Alert.Name.ToLower().Contains($($VMObject.Name.ToLower().Trim())))
                            {
                                Write-Output "Previous alert ($($Alert.Name)) found and disabling now..."
                                 $params = @{
                                     TargetResourceId = $resourceId
                                     Description = $description
                                     Location = $Alert.Location
                                     Threshold = $threshold
                                     Actions = $actionWebhook
                                     ResourceGroup = $ResourceGroupName
                                     WindowSize = $timeWindow
                                     Operator = $condition
                                     MetricName = $metricName
                                     TimeAggregationOperator = $timeAggregationOperator
                                     Name = $Alert.Name
                                 }
                                 Add-AzureRmMetricAlertRule @params
                                        Write-Output "Alert ($($Alert.Name)) Disabled for VM $($VMObject.Name)"
                            }
                        }
                    }
    }
    elseif($AlertAction -eq Create" )
    {
        #Getting ResourcegroupName and Location based on VM
                        if ($VMState -eq 'PowerState/running')
                        {
                            try
                            {
                                $VMAlerts = Get-AzureRmAlertRule -ResourceGroup $ResourceGroupName -Output -ErrorAction SilentlyContinue
                                #Check if alerts exists and take action
                                if($null -ne $VMAlerts)
                                {
                                    Write-Output "Checking for any previous alert(s)..."
                                    #Alerts exists so delete and re-create the new alert
                                    foreach($Alert in $VMAlerts)
                                    {
                                        if($Alert.Name.ToLower().Contains($($VMObject.Name.ToLower().Trim())))
                                        {
                                            Write-Output "Previous alert ($($Alert.Name)) found and deleting now..."
                                            #Remove the old alert
                                            Remove-AzureRmAlertRule -Name $Alert.Name -ResourceGroup $ResourceGroupName
                                            #Wait for few seconds to make sure it processed
                                            Do
                                            {
                                               #Start-Sleep 10
$GetAlert=Get-AzureRmAlertRule -ResourceGroup $ResourceGroupName -Name $Alert.Name -Output -ErrorAction SilentlyContinue
                                            }
                                            while($null -ne $GetAlert)
                                            Write-Output "Generating a new alert with unique name..."
                                            #Now generate new unique alert name
$NewAlertName = Generate-AlertName -OldAlertName $Alert.Name -VMName $VMObject.Name
                                        }
                                     }
                                }
                                 #Alert does not exist, so create new alert
                                 Write-Output $NewAlertName
                                 Write-Output "Adding a new alert to the VM..."
                                 $params = @{
                                     TargetResourceId = $resourceId
                                     Description = $description   Write-Output  "Alert Created for VM $($VMObject.Name.Trim())" } catch { Write-Output "Error Occurred" Write-Output $_.Exception }  } else { Write-Output " $($VM.Name) is De-allocated" } } } catch { Write-Output "Error Occurred" Write-Output $_.Exception }
                                     Location = $location
                                     Threshold = $threshold
                                     Actions = $actionWebhook
                                     ResourceGroup = $ResourceGroupName
                                     WindowSize = $timeWindow
                                     Operator = $condition
                                     MetricName = $metricName
                                     TimeAggregationOperator = $timeAggregationOperator
                                     Name = $NewAlertName
                                 }
                                 Add-AzureRmMetricAlertRule @params


