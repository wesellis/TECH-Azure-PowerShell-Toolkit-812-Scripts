#Requires -Version 7.4

<#`n.SYNOPSIS
    Scheduledsnooze Child

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
 Wrapper script for start & stop AzureRM VM's
 Wrapper script for start & stop AzureRM VM's
.\ScheduledSnooze_Child.ps1 -VMName "Value1" -Action "Value2" -ResourceGroupName "Value3"
Version History
v1.0   - Initial Release
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
$VMName = $(throw "Value for VMName is missing" ),
[String]$Action = $(throw "Value for Action is missing" ),
[String]$ResourceGroupName = $(throw "Value for ResourceGroupName is missing" )
)
    $ConnectionName = "AzureRunAsConnection"
try
{
    $ServicePrincipalConnection=Get-AutomationConnection -Name $ConnectionName
    "Logging in to Azure..."
    $params = @{
        ApplicationId = $ServicePrincipalConnection.ApplicationId
        TenantId = $ServicePrincipalConnection.TenantId
        CertificateThumbprint = $ServicePrincipalConnection.CertificateThumbprint
    }
    Add-AzureRmAccount @params
}
catch
{
    if (!$ServicePrincipalConnection)
    {
    $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
try
{
    Write-Output "VM action is : $($Action)"
    if ($Action.Trim().ToLower() -eq " stop" )
    {
        Write-Output "Stopping the VM : $($VMName)"
    $Status = Stop-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName -Force
        if($null -eq $Status)
        {
            Write-Output "Error occured while stopping the Virtual Machine."
        }
        else
        {
           Write-Output "Successfully stopped the VM $VMName"
        }
    }
    elseif($Action.Trim().ToLower() -eq " start" )
    {
        Write-Output "Starting the VM : $($VMName)"
    $Status = Start-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName
        if($null -eq $Status)
        {
            Write-Output "Error occured while starting the Virtual Machine $($VMName)"
        }
        else
        {
            Write-Output "Successfully started the VM $($VMName)"
        }

} catch
{
    Write-Output "Error Occurred..."
    Write-Output $_.Exception`n}
