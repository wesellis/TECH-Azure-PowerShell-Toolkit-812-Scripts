#Requires -Version 7.0
#Requires -Module Az.Resources
    Tombstonedscnodes
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
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
#>
 This script provides an example for how to use a Runbook in Azure Automation to tombstone stale DSC nodes from State Configuration.
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]$AutomationAccountName
)
$TombstoneAction = $false
$TombstoneDays = 1
$UnregisterAction = $false
$UnregisterDays = 3
$ServicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
$params = @{
    ApplicationId = $ServicePrincipalConnection.ApplicationId
    TenantId = $ServicePrincipalConnection.TenantId
    CertificateThumbprint = $ServicePrincipalConnection.CertificateThumbprint | Write-Verbose
}
Add-AzureRmAccount @params
$Context = Set-AzureRmContext -SubscriptionId $ServicePrincipalConnection.SubscriptionID | Write-Verbose
$SetTombstonedNodes = Get-AzureRMAutomationDscNode -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | Where-Object {$_.Status -eq 'Unresponsive' -AND $_.LastSeen -lt (get-date).AddDays(-$TombstoneDays) -AND $_.NodeConfigurationName -notlike "Tombstoned.*" }
Write-Output "Nodes to be tombstoned:"
if ($null -eq $SetTombstonedNodes) {Write-Output " 0 nodes" }
else {
    $SetTombstonedNodes | % Name | Write-Output
}
Write-Output ""
$UnregisterNodes = Get-AzureRMAutomationDscNode -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | Where-Object {$_.Status -eq 'Unresponsive' -AND $_.LastSeen -lt (get-date).AddDays(-$UnregisterDays) -AND $_.NodeConfigurationName -like "Tombstoned.*" }
Write-Output "Nodes to be unregistered:"
if ($null -eq $UnregisterNodes) {Write-Output " 0 nodes" }
else {
    $UnregisterNodes | % Name | Write-Output
}
Write-Output ""
if ($true -eq $TombstoneAction) {
    Write-Output "Taking action: Tombstone nodes"
    if ($null -eq $SetTombstonedNodes) {Write-Output " 0 nodes" }
    else {
        foreach ($SetTombstonedNode in $SetTombstonedNodes) {
            Write-Output "Setting node configuration to " Tombstoned.$($SetTombstonedNode.NodeConfigurationName)" for node $($SetTombstonedNode.Name) with Id $($SetTombstonedNode.Id) from account $($SetTombstonedNode.AutomationAccountName)"
            $SetTombstonedNode | Set-AzureRmAutomationDscNode -NodeConfigurationName "Tombstoned.$($SetTombstonedNode.NodeConfigurationName)" -Force
        }
    }
}
Write-Output ""
if ($true -eq $UnregisterAction) {
    Write-Output "Taking action: Unregister nodes"
    if ($null -eq $UnregisterNodes) {Write-Output " 0 nodes" }
    else {
        foreach ($UnregisterNode in $UnregisterNodes) {
            Write-Output "Unregistering node $($UnregisterNode.Name) with Id $($UnregisterNode.Id) from account $($UnregisterNode.AutomationAccountName)"
            $UnregisterNode | Unregister-AzureRMAutomationDscNode -Force
        }
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

