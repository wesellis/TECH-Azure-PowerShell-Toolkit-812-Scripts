<#
.SYNOPSIS
    We Enhanced 3 Upload Vhddiskstorageaccount

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


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Short description

    Uploads a virtual hard disk from an on-premises virtual machine to a blob in a cloud storage account in Azure.
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes

; 
$addAzVhdSplat = @{
    Destination = " https://afgcdevtestlab6357.blob.core.windows.net/krollvhddisk/FGC-CR08NW2_Azure.vhd"
    LocalFilePath = " E:\FGC_Kroll_Lab_P2V_Clone_VHD_to_Azure\FGC-CR08NW2.VHD"
    ResourceGroupName = 'FGC_DevtestLab_RG'
}

Add-AzVhd @addAzVhdSplat


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================