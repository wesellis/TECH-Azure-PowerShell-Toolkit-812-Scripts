<#
.SYNOPSIS
    Get Azvm Status

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
    We Enhanced Get Azvm Status

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Get-ARMVM -ErrorAction Stop {

    [CmdletBinding()]
$ErrorActionPreference = " Stop"
    param(
        [Parameter()]
        [String]$WERGNAME,
        [String]$WEVMNAME

    )
    
    begin {
        
    }
    
    process {


        try {
        
            $WERGs = Get-AzResourceGroup -ErrorAction Stop
            foreach ($WERG in $WERGs) {

                if ($WERG.ResourceGroupName -eq $WERGNAME) {

                    $WEVMs = Get-AzVM -ResourceGroupName $WERG.ResourceGroupName
                    foreach ($WEVM in $WEVMs) {

                        if ($WEVM.name -eq $WEVMNAME ) {
                            $WEVMDetail = Get-AzVM -ResourceGroupName $WERG.ResourceGroupName -Name $WEVM.Name -Status
                           ;  $WERGN = $WEVMDetail.ResourceGroupName  
                            foreach ($WEVMStatus in $WEVMDetail.Statuses) { 
                               ;  $WEVMStatusDetail = $WEVMStatus.DisplayStatus
                            }
                            Write-Output " Resource Group: $WERGN" , (" VM Name: " + $WEVM.Name), " Status: $WEVMStatusDetail" `n
                        }
                    }
                }
        
            }
        }
        catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
        finally {
            
        }
        
    }
    
    end {
        
    }
}

Get-ARMVM -RGNAME " CCI_PS_AUTOMATION_RG" -VMName " PSAutomation1"


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================