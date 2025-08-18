<#
.SYNOPSIS
    0 Select Azsubscription

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
    We Enhanced 0  Select Azsubscription

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


$WEErrorActionPreference = "Stop" ; 
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

    Name                                     Account                  SubscriptionName        Environment             TenantId
----                                     -------                  ----------------        -----------             --------
Microsoft Azure - FGC Production (353... Admin-CCI@fgchealth.com  Microsoft Azure - FG... AzureCloud              e09d9473-1a06-4717-9... 
.NOTES
    General notes


    Changes the current and default Azure subscriptions.


Get-AzSubscription

Select-AzSubscription '3532a85c-c00a-4465-9b09-388248166360'


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================