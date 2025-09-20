#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    14.5.1 Get bastion
.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
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
IpConfigurations     : {IpConf}
DnsName              : bst-a403b33e-b182-43e5-960c-38820da0cfe3.bastion.azure.com
ProvisioningState    : Succeeded
IpConfigurationsText : [
                         {
                           "Subnet" : {
                             "Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGCProdcuction/providers/Microsoft
                       .Network/virtualNetworks/ProductionVNET/subnets/AzureBastionSubnet"
                           },
                           "PublicIpAddress" : {
                             "Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGC_Prod_Bastion_RG/providers/Micr
                       osoft.Network/publicIPAddresses/FGC_Prod_Bastion_PublicIP"
                           },
                           "ProvisioningState" : "Succeeded" ,
                           "PrivateIpAllocationMethod" : "Dynamic" ,
                           "Name" : "IpConf" ,
                           "Etag" : "W/\" acaaca63-d235-4519-8151-28ccd7461cd4\"" ,
                           "Id" : " /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGC_Prod_Bastion_RG/providers/Micros
                       oft.Network/bastionHosts/FGC_Prod_Bastion/bastionHostIpConfigurations/IpConf"
                         }
                       ]
ResourceGroupName    : FGC_Prod_Bastion_RG
Location             : canadacentral
ResourceGuid         :
Type                 : Microsoft.Network/bastionHosts
Tag                  : {Uptime, Environment, CSP, Subscription Name...}
TagsTable            :
                       Name               Value
                       =================  ====================================
                       Uptime             24/7
                       Environment        Production
                       CSP                Canada Computing Inc.
                       Subscription Name  Microsoft Azure - FGC Production
                       Ticket ID          1515933
                       Tenant ID          e09d9473-1a06-4717-98c1-528067eab3a4
                       Workload           Production Bastion
                       Subscription ID    3532a85c-c00a-4465-9b09-388248166360
                       DateTimeCreated    2020_12_13_21_03_01
                       Billing Unit       Per Hour
                       Approved On        Friday Dec 11 2020
                       Approved By        Hamza Musaphir
                       Createdby          Abdullah Ollivierre
                       Location           CanadaCentral
                       CustomerName       FGCHealth
Name                 : FGC_Prod_Bastion
Etag                 : W/" acaaca63-d235-4519-8151-28ccd7461cd4"
Id                   : /subscriptions/3532a85c-c00a-4465-9b09-388248166360/resourceGroups/FGC_Prod_Bastion_RG/providers/Microsoft.Network
                       /bastionHosts/FGC_Prod_Bastion
    General notes
Get-AzBastion -ErrorAction Stop | Format-Table\n

