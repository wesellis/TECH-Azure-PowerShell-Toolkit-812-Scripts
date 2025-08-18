<#
.SYNOPSIS
    14.5 New Azbastion

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
    We Enhanced 14.5 New Azbastion

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Short description
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

    Create a new Azure Bastion resource in the AzureBastionSubnet of your virtual network. It takes about 5 minutes for the Bastion resource to create and deploy.





$WELocationName = 'CanadaCentral'
$WECustomerName = 'FGCHealth'
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Createdby"         = 'Abdullah Ollivierre'
    " CustomerName"      = " $WECustomerName"
    " DateTimeCreated"   = " $datetime"
    " Environment"       = 'Production'
    " Uptime"            = '24/7'
    " Workload"          = 'Production Bastion'
    " Location"          = " $WELocationName"
    " Approved By"       = " Hamza Musaphir"
    " Approved On"       = " Friday Dec 11 2020"
    " Ticket ID"         = " 1515933"
    " CSP"               = " Canada Computing Inc."
    " Subscription Name" = " Microsoft Azure - FGC Production"
    " Subscription ID"   = " 3532a85c-c00a-4465-9b09-388248166360"
    " Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"
    " Billing Unit"      = " Per Hour"

}

; 
$newAzBastionSplat = @{
    ResourceGroupName = " FGC_Prod_Bastion_RG"
    Name              = " FGC_Prod_Bastion"
    PublicIpAddress   = $publicip
    VirtualNetwork    = $vnet
    Tag               = $WETags
}
; 
$bastion = New-AzBastion -ErrorAction Stop @newAzBastionSplat


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================