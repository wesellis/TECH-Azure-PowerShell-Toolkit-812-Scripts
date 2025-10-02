#Requires -Version 7.4
#Requires -Modules Az.Automation, Az.Monitor

<#
.SYNOPSIS
    AutoSnooze Create Alert Parent

.DESCRIPTION
    Azure automation parent runbook for creating AutoSnooze alerts for Azure VMs based on CPU usage

.PARAMETER WhatIf
    When set to $true, shows what would be done without making changes

.PARAMETER AutomationAccountName
    Name of the automation account containing the child runbooks

.PARAMETER ResourceGroupName
    Resource group containing the automation account

.PARAMETER VMResourceGroupNames
    Comma-separated list of resource group names to include

.PARAMETER ExcludeVMNames
    Comma-separated list of VM names to exclude from alerts

.PARAMETER WebhookUri
    Webhook URI for alert notifications

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [bool]$WhatIf = $false,

    [Parameter(Mandatory = $true)]
    [string]$AutomationAccountName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$VMResourceGroupNames,

    [Parameter()]
    [string]$ExcludeVMNames,

    [Parameter()]
    [string]$WebhookUri,

    [Parameter()]
    [string]$ConnectionName = "AzureRunAsConnection"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Test-ExcludeVM {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$FilterVMList
    )

    $allVMs = Get-AzVM -ErrorAction SilentlyContinue
    $excludedVMs = @()
    $invalidVMs = @()

    foreach ($filterVM in $FilterVMList) {
        $found = $false
        foreach ($vm in $allVMs) {
            if ($vm.Name.ToLower().Trim() -eq $filterVM.ToLower().Trim()) {
                $excludedVMs += $vm
                $found = $true
                break
            }
        }
        if (-not $found) {
            $invalidVMs += $filterVM
        }
    }

    if ($invalidVMs.Count -gt 0) {
        Write-Warning "Invalid VM name(s) in exclude list: $($invalidVMs -join ', ')"
        throw "Invalid VM name(s) in exclude list: $($invalidVMs -join ', ')"
    }

    return $excludedVMs
}

try {
    # Connect to Azure using Run As Connection
    $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName -ErrorAction Stop
    Write-Output "Logging in to Azure using service principal..."

    $connectParams = @{
        ApplicationId = $servicePrincipalConnection.ApplicationId
        TenantId = $servicePrincipalConnection.TenantId
        CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    }

    Connect-AzAccount -ServicePrincipal @connectParams -ErrorAction Stop
    Write-Output "Successfully connected to Azure"
}
catch {
    if (!$servicePrincipalConnection) {
        $errorMessage = "Connection '$ConnectionName' not found."
        Write-Error -Message $errorMessage
        throw $errorMessage
    } else {
        Write-Error -Message "Failed to connect to Azure: $($_.Exception.Message)"
        throw
    }
}

try {
    Write-Output "Runbook execution started..."

    # Process exclude VM list
    $excludedVMList = @()
    if (![string]::IsNullOrEmpty($ExcludeVMNames)) {
        $vmFilterList = $ExcludeVMNames -split ","
        Write-Output "Validating excluded VMs..."
        $excludedVMList = Test-ExcludeVM -FilterVMList $vmFilterList

        if ($excludedVMList.Count -gt 0 -and !$WhatIf) {
            foreach ($vm in $excludedVMList) {
                try {
                    Write-Output "Disabling alert rules for excluded VM: $($vm.Name)"
                    $params = @{
                        "VMObject" = $vm
                        "AlertAction" = "Disable"
                        "WebhookUri" = $WebhookUri
                    }
                    Start-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name 'AutoSnooze_CreateAlert_Child' -ResourceGroupName $ResourceGroupName -Parameters $params
                }
                catch {
                    Write-Warning "Failed to disable alert for VM '$($vm.Name)': $($_.Exception.Message)"
                }
            }
        }
        elseif ($excludedVMList.Count -gt 0 -and $WhatIf) {
            Write-Output "WhatIf: Would disable alerts for excluded VMs:"
            $excludedVMList | ForEach-Object { Write-Output "  - $($_.Name)" }
        }
    }

    # Get VMs from specified resource groups or entire subscription
    $azureVMList = @()
    if (![string]::IsNullOrEmpty($VMResourceGroupNames)) {
        $vmRGList = $VMResourceGroupNames -split ","
        foreach ($rgName in $vmRGList) {
            $trimmedRG = $rgName.Trim()
            Write-Output "Processing resource group: $trimmedRG"

            try {
                $rg = Get-AzResourceGroup -Name $trimmedRG -ErrorAction Stop
                $vms = Get-AzVM -ResourceGroupName $trimmedRG -ErrorAction SilentlyContinue
                if ($vms) {
                    $azureVMList += $vms
                }
            }
            catch {
                Write-Warning "Resource group '$trimmedRG' not found or inaccessible"
            }
        }
    }
    else {
        Write-Output "Getting all VMs from subscription..."
        $azureVMList = Get-AzVM -ErrorAction SilentlyContinue
    }

    # Filter out excluded VMs
    $actualAzureVMList = @()
    if ($excludedVMList.Count -gt 0) {
        $excludedNames = $excludedVMList | ForEach-Object { $_.Name }
        foreach ($vm in $azureVMList) {
            if ($excludedNames -notcontains $vm.Name) {
                $actualAzureVMList += $vm
            }
        }
    }
    else {
        $actualAzureVMList = $azureVMList
    }

    Write-Output "Found $($actualAzureVMList.Count) VMs to process for AutoSnooze alerts"

    if (!$WhatIf) {
        foreach ($vm in $actualAzureVMList) {
            Write-Output "Creating alert rules for VM: $($vm.Name)"
            $params = @{
                "VMObject" = $vm
                "AlertAction" = "Create"
                "WebhookUri" = $WebhookUri
            }
            Start-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name 'AutoSnooze_CreateAlert_Child' -ResourceGroupName $ResourceGroupName -Parameters $params
        }
        Write-Output "Note: All alert rule creation jobs are processed in parallel. Check the child runbook (AutoSnooze_CreateAlert_Child) job status for details."
    }
    else {
        Write-Output "WhatIf mode: No changes will be made"
        Write-Output "Would create alerts for the following VMs:"
        $actualAzureVMList | Select-Object Name, ResourceGroupName | Format-Table
    }

    Write-Output "Runbook execution completed"
}
catch {
    Write-Error "Error in AutoSnooze Create Alert Parent: $($_.Exception.Message)"
    throw
}