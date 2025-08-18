<#
.SYNOPSIS
    Tombstonedscnodes

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
    We Enhanced Tombstonedscnodes

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#PSScriptInfo

.VERSION 1.0.0

.GUID 4e07bb61-3d86-4150-8436-73d420d34457

.AUTHOR Michael Greene

.COMPANYNAME Microsoft Corporation

.COPYRIGHT 2019

.TAGS DSC AzureAutomation Runbook VMSS ScaleSet

.LICENSEURI https://github.com/mgreenegit/tombstonedscnodes/license

.PROJECTURI https://github.com/mgreenegit/tombstonedscnodes

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
https://github.com/mgreenegit/tombstonedscnodes/readme.md

.PRIVATEDATA 





<# 

.DESCRIPTION 
 This script provides an example for how to use a Runbook in Azure Automation to tombstone stale DSC nodes from State Configuration. 


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$WEAutomationAccountName
)

$WETombstoneAction = $false
$WETombstoneDays = 1
$WEUnregisterAction = $false
$WEUnregisterDays = 3


$WEServicePrincipalConnection = Get-AutomationConnection -Name " AzureRunAsConnection"
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $WEServicePrincipalConnection.TenantId `
    -ApplicationId $WEServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $WEServicePrincipalConnection.CertificateThumbprint | Write-Verbose
$WEContext = Set-AzureRmContext -SubscriptionId $WEServicePrincipalConnection.SubscriptionID | Write-Verbose

; 
$WESetTombstonedNodes = Get-AzureRMAutomationDscNode -ResourceGroupName $WEResourceGroupName -AutomationAccountName $WEAutomationAccountName | Where-Object {$_.Status -eq 'Unresponsive' -AND $_.LastSeen -lt (get-date).AddDays(-$WETombstoneDays) -AND $_.NodeConfigurationName -notlike " Tombstoned.*" }
Write-Output " Nodes to be tombstoned:"
if ($null -eq $WESetTombstonedNodes) {Write-Output " 0 nodes" }
else {
    $WESetTombstonedNodes | % Name | Write-Output
}

Write-Output ""
; 
$WEUnregisterNodes = Get-AzureRMAutomationDscNode -ResourceGroupName $WEResourceGroupName -AutomationAccountName $WEAutomationAccountName | Where-Object {$_.Status -eq 'Unresponsive' -AND $_.LastSeen -lt (get-date).AddDays(-$WEUnregisterDays) -AND $_.NodeConfigurationName -like " Tombstoned.*" }
Write-Output " Nodes to be unregistered:"
if ($null -eq $WEUnregisterNodes) {Write-Output " 0 nodes" }
else {
    $WEUnregisterNodes | % Name | Write-Output
}

Write-Output ""



if ($true -eq $WETombstoneAction) {
    Write-Output " Taking action: Tombstone nodes"
    if ($null -eq $WESetTombstonedNodes) {Write-Output " 0 nodes" }
    else {
        foreach ($WESetTombstonedNode in $WESetTombstonedNodes) {
            Write-Output " Setting node configuration to " Tombstoned.$($WESetTombstonedNode.NodeConfigurationName)" for node $($WESetTombstonedNode.Name) with Id $($WESetTombstonedNode.Id) from account $($WESetTombstonedNode.AutomationAccountName)"
            $WESetTombstonedNode | Set-AzureRmAutomationDscNode -NodeConfigurationName " Tombstoned.$($WESetTombstonedNode.NodeConfigurationName)" -Force
        }
    }
}

Write-Output ""

if ($true -eq $WEUnregisterAction) {
    Write-Output " Taking action: Unregister nodes"
    if ($null -eq $WEUnregisterNodes) {Write-Output " 0 nodes" }
    else {
        foreach ($WEUnregisterNode in $WEUnregisterNodes) {
            Write-Output " Unregistering node $($WEUnregisterNode.Name) with Id $($WEUnregisterNode.Id) from account $($WEUnregisterNode.AutomationAccountName)"
            $WEUnregisterNode | Unregister-AzureRMAutomationDscNode -Force
        }
    }
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
