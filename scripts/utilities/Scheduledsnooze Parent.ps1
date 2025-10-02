#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Scheduledsnooze Parent

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
 Wrapper script for get all the VM's in all RG's or subscription level and then call the Start or Stop runbook
 Wrapper script for get all the VM's in all RG's or subscription level and then call the Start or Stop runbook
.\ScheduledSnooze_Parent.ps1 -Action "Value1" -WhatIf "False"
Version History
v1.0   - Initial Release
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true, HelpMessage = "Enter the value for Action. Values can be either stop or start" )][String]$Action,
    [Parameter(Mandatory = $false, HelpMessage = "Enter the value for WhatIf. Values can be either true or false" )][bool]$WhatIf = $false
)
function ScheduleSnoozeAction ($VMObject, [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Action) {
    Write-Output "Calling the ScheduledSnooze_Child wrapper (Action = $($Action))..."
    if ($Action.ToLower() -eq 'start') {
    $params = @{"VMName" = " $($VMObject.Name)" ; "Action" = " start" ; "ResourceGroupName" = " $($VMObject.ResourceGroupName)" }
    }
    elseif ($Action.ToLower() -eq 'stop') {
    $params = @{"VMName" = " $($VMObject.Name)" ; "Action" = " stop" ; "ResourceGroupName" = " $($VMObject.ResourceGroupName)" }
    }
    Write-Output "Performing the schedule $($Action) for the VM : $($VMObject.Name)"
    $runbook = Start-AzureRmAutomationRunbook -automationAccountName $AutomationAccountName -Name 'ScheduledSnooze_Child' -ResourceGroupName $AroResourceGroupName Parameters $params
}
function CheckExcludeVM ($FilterVMList) {
    $AzureVM = Get-AzureRmVM -ErrorAction SilentlyContinue
    [boolean] $ISexists = $false
    [string[]] $invalidvm = @()
    $ExAzureVMList = @()
    foreach ($filtervm in $VMfilterList) {
        foreach ($vmname in $AzureVM) {
            if ($Vmname.Name.ToLower().Trim() -eq $filtervm.Tolower().Trim()) {
    $ISexists = $true
    $ExAzureVMList = $ExAzureVMList + $vmname
                break
            }
            else {
    $ISexists = $false
            }
        }
        if ($ISexists -eq $false) {
    $invalidvm = $invalidvm + $filtervm
        }
    }
    if ($null -ne $invalidvm) {
        Write-Output "Runbook Execution Stopped! Invalid VM Name(s) in the exclude list: $($invalidvm) "
        Write-Warning "Runbook Execution Stopped! Invalid VM Name(s) in the exclude list: $($invalidvm) "
        exit
    }
    else {
        Write-Output "Exclude VM's validation completed..."
    }
}
    $ConnectionName = "AzureRunAsConnection"
try {
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName
    "Logging in to Azure..."
    $params = @{
        ApplicationId = $ServicePrincipalConnection.ApplicationId
        TenantId = $ServicePrincipalConnection.TenantId
        CertificateThumbprint = $ServicePrincipalConnection.CertificateThumbprint
    }
    Add-AzureRmAccount @params
}
catch {
    if (!$ServicePrincipalConnection) {
    $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
    $SubId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'
    $ResourceGroupNames = Get-AutomationVariable -Name 'External_ResourceGroupNames'
    $ExcludeVMNames = Get-AutomationVariable -Name 'External_ExcludeVMNames'
    $AutomationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $AroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'
try {
    $Action = $Action.Trim().ToLower()
    if (!($Action -eq " start" -or $Action -eq " stop" )) {
        Write-Output " `$Action parameter value is : $($Action). Value should be either start or stop!"
        Write-Output "Completed the runbook execution..."
        exit
    }
    Write-Output "Runbook Execution Started..."
    [string[]] $VMfilterList = $ExcludeVMNames -split " ,"
    [string[]] $VMRGList = $ResourceGroupNames -split " ,"
    if ([string]::IsNullOrEmpty($ExcludeVMNames) -ne $true) {
        Write-Output "Exclude VM's added so validating the resource(s)..."
        CheckExcludeVM -FilterVMList $VMfilterList
    }
    $AzureVMListTemp = $null
    $AzureVMList = @()
    if ($null -ne $VMRGList) {
        foreach ($Resource in $VMRGList) {
            Write-Output "Validating the resource group name ($($Resource.Trim()))"
    $CheckRGname = Get-AzureRmResourceGroup -Name $Resource.Trim() -ev notPresent -ea 0
            if ($null -eq $CheckRGname) {
                Write-Warning " $($Resource) is not a valid Resource Group Name. Please Verify!"
            }
            else {
                Write-Output "Resource Group Exists..."
    $AzureVMListTemp = Get-AzureRmVM -ResourceGroupName $Resource -ErrorAction SilentlyContinue
                if ($null -ne $AzureVMListTemp) {
    $AzureVMList = $AzureVMList + $AzureVMListTemp
                }
            }
        }
    }
    else {
        Write-Output "Getting all the VM's from the subscription..."
    $AzureVMList = Get-AzureRmVM -ErrorAction SilentlyContinue
    }
    $ActualAzureVMList = @()
    if ($null -ne $VMfilterList) {
        foreach ($VM in $AzureVMList) {
            if ($VMfilterList -notcontains ($($VM.Name))) {
    $ActualAzureVMList = $ActualAzureVMList + $VM
            }
        }
    }
    else {
    $ActualAzureVMList = $AzureVMList
    }
    Write-Output "The current action is $($Action)"
    if ($WhatIf -eq $false) {
        foreach ($VM in $ActualAzureVMList) {
            ScheduleSnoozeAction -VMObject $VM -Action $Action
        }
    }
    elseif ($WhatIf -eq $true) {
        Write-Output "WhatIf parameter is set to True..."
        Write-Output "When 'WhatIf' is set to TRUE, runbook provides a list of Azure Resources (e.g. VMs), that will be impacted if you choose to deploy this runbook."
        Write-Output "No action will be taken at this time..."
        Write-Output $($ActualAzureVMList) | Select-Object Name, ResourceGroupName | Format-List
    }
    Write-Output "Runbook Execution Completed..."
}
catch {
    $ex = $_.Exception
    Write-Output $_.Exception`n}
