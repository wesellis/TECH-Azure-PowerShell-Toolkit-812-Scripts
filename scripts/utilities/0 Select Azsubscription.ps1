#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Select Azsubscription

.DESCRIPTION
    Select Azsubscription operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    Name                                     Account                  SubscriptionName        Environment             TenantId
----                                     -------                  ----------------        -----------             --------
Microsoft Azure - FGC Production (353... Admin-CCI@fgchealth.com  Microsoft Azure - FG... AzureCloud              e09d9473-1a06-4717-9...
    General notes
    Changes the current and default Azure subscriptions.
Get-AzSubscription -ErrorAction Stop
Select-AzSubscription '3532a85c-c00a-4465-9b09-388248166360'

