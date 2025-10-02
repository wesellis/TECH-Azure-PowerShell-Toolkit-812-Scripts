#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Get Azvm Status

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Get-ARMVM -ErrorAction Stop {
    param(
        [Parameter(ValueFromPipeline)]`n    [String]$RGNAME,
        [String]$VMNAME
    )
    begin {
    }
    process {
        try {
$RGs = Get-AzResourceGroup -ErrorAction Stop
            foreach ($RG in $RGs) {
                if ($RG.ResourceGroupName -eq $RGNAME) {
$VMs = Get-AzVM -ResourceGroupName $RG.ResourceGroupName
                    foreach ($VM in $VMs) {
                        if ($VM.name -eq $VMNAME ) {
$VMDetail = Get-AzVM -ResourceGroupName $RG.ResourceGroupName -Name $VM.Name -Status
    [string]$RGN = $VMDetail.ResourceGroupName
                            foreach ($VMStatus in $VMDetail.Statuses) {
    [string]$VMStatusDetail = $VMStatus.DisplayStatus
                            }
                            Write-Output "Resource Group: $RGN" , ("VM Name: " + $VM.Name), "Status: $VMStatusDetail" `n
                        }
                    }
                }

} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
        finally {
        }
    }
    end {
    }
}
Get-ARMVM -RGNAME "CCI_PS_AUTOMATION_RG" -VMName "PSAutomation1"



