#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create bastion

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    General notes
    Create a new Azure Bastion resource in the AzureBastionSubnet of your virtual network. It takes about 5 minutes for the Bastion resource to create and deploy.
$LocationName = 'CanadaCentral'
$CustomerName = 'FGCHealth'
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Createdby"         = 'Abdullah Ollivierre'
    "CustomerName"      = " $CustomerName"
    "DateTimeCreated"   = " $datetime"
    "Environment"       = 'Production'
    "Uptime"            = '24/7'
    "Workload"          = 'Production Bastion'
    "Location"          = " $LocationName"
    "Approved By"       = "Hamza Musaphir"
    "Approved On"       = "Friday Dec 11 2020"
    "Ticket ID"         = " 1515933"
    "CSP"               = "Canada Computing Inc."
    "Subscription Name" = "Microsoft Azure - FGC Production"
    "Subscription ID"   = " 3532a85c-c00a-4465-9b09-388248166360"
    "Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"
    "Billing Unit"      = "Per Hour"
}
$newAzBastionSplat = @{
    ResourceGroupName = "FGC_Prod_Bastion_RG"
    Name              = "FGC_Prod_Bastion"
    PublicIpAddress   = $publicip
    VirtualNetwork    = $vnet
    Tag               = $Tags
}
$bastion = New-AzBastion -ErrorAction Stop @newAzBastionSplat\n

