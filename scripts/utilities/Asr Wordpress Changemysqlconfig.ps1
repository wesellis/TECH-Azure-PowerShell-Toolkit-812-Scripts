#Requires -Version 7.4
#Requires -Modules Az.Compute, Az.Automation

<#
.SYNOPSIS
    ASR WordPress Change MySQL Config

.DESCRIPTION
    Azure Site Recovery automation runbook that changes WordPress configuration
    during failover by replacing wp-config.php with wp-config.php.Azure

.PARAMETER RecoveryPlanContext
    The recovery plan context object passed by Azure Site Recovery

.PARAMETER RecoveryLocation
    The Azure region to which VMs are recovering

.PARAMETER ScriptUri
    URI to the PowerShell script for changing WordPress DB configuration

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Original Author: RuturajD@microsoft.com
    Version: 1.0
    Last Modified: March 27, 2017
    Requires appropriate permissions and modules
#>

workflow ASR-Wordpress-ChangeMysqlConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [Object]$RecoveryPlanContext,

        [Parameter()]
        [string]$RecoveryLocation = "southeastasia",

        [Parameter()]
        [string]$ScriptUri = "https://raw.githubusercontent.com/ruturaj/RecoveryPlanScripts/master/ChangeWPDBHostIP.ps1"
    )

    $ErrorActionPreference = "Stop"
    $ConnectionName = "AzureRunAsConnection"

    try {
        Write-Output "Getting automation connection..."
        $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName -ErrorAction Stop

        Write-Output "Logging in to Azure..."
        $connectParams = @{
            ServicePrincipal = $true
            TenantId = $servicePrincipalConnection.TenantId
            ApplicationId = $servicePrincipalConnection.ApplicationId
            CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
        }

        Add-AzAccount @connectParams -ErrorAction Stop

        Write-Output "Setting subscription context..."
        Select-AzSubscription -SubscriptionId $servicePrincipalConnection.SubscriptionID -ErrorAction Stop
    }
    catch {
        if (!$servicePrincipalConnection) {
            $errorMessage = "Connection '$ConnectionName' not found."
            Write-Error $errorMessage
            throw $errorMessage
        }
        else {
            Write-Error "Failed to connect to Azure: $_"
            throw
        }
    }

    Write-Output "Recovery Plan Context:"
    Write-Output $RecoveryPlanContext

    # Get VM information from recovery plan
    $vmInfo = $RecoveryPlanContext.VmMap | Get-Member |
        Where-Object MemberType -eq NoteProperty |
        Select-Object -ExpandProperty Name

    Write-Output "Found VMs:"
    Write-Output $vmInfo

    $vmMap = $RecoveryPlanContext.VmMap

    foreach ($vmId in $vmInfo) {
        $vm = $vmMap.$vmId

        if ((-not ($null -eq $vm)) -and
            (-not ($null -eq $vm.ResourceGroupName)) -and
            (-not ($null -eq $vm.RoleName))) {

            Write-Output "`nProcessing VM:"
            Write-Output "  Resource Group: $($vm.ResourceGroupName)"
            Write-Output "  VM Name: $($vm.RoleName)"

            InlineScript {
                try {
                    $extensionParams = @{
                        ResourceGroupName = $Using:vm.ResourceGroupName
                        VMName = $Using:vm.RoleName
                        Name = "WordPressConfigScript"
                        FileUri = $Using:ScriptUri
                        Run = "ChangeWPDBHostIP.ps1"
                        Location = $Using:RecoveryLocation
                        TypeHandlerVersion = "1.10"
                    }

                    Write-Output "Installing custom script extension on VM: $($Using:vm.RoleName)"
                    Set-AzVMCustomScriptExtension @extensionParams -ErrorAction Stop

                    Write-Output "Successfully configured WordPress on VM: $($Using:vm.RoleName)"
                }
                catch {
                    Write-Error "Failed to configure WordPress on VM $($Using:vm.RoleName): $_"
                    throw
                }
            }
        }
        else {
            Write-Warning "Skipping VM due to missing information"
        }
    }

    Write-Output "`nWordPress configuration update completed for all VMs"
}