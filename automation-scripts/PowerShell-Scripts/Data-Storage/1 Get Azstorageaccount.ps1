<#
.SYNOPSIS
    Get storageaccount

.DESCRIPTION
    Get storageaccount operation
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
    StorageAccountName  ResourceGroupName          PrimaryLocation SkuName      Kind      AccessTier CreationTime           ProvisioningState EnableH
                                                                                                                                          ttpsTra
                                                                                                                                          fficOnl
                                                                                                                                          y
------------------  -----------------          --------------- -------      ----      ---------- ------------           ----------------- -------
cs210032000462b65d6 cloud-shell-storage-eastus eastus          Standard_LRS StorageV2 Hot        2020-12-10 5:54:20 PM  Succeeded         True
csg10032000c90d3e66 FGC_DevtestLab_RG          centralindia    Standard_LRS StorageV2 Hot        2020-09-24 3:27:25 AM  Succeeded         True
afgcdevtestlab6357  FGC_DevtestLab_RG          canadacentral   Standard_LRS StorageV2 Hot        2020-09-18 1:29:30 AM  Succeeded         True
veeamdiag215        VEEAM                      canadacentral   Standard_LRS Storage              2020-11-20 11:37:04 PM Succeeded         True
StorageAccountName       ResourceGroupName       PrimaryLocation SkuName      Kind    AccessTier CreationTime          ProvisioningState EnableHt
                                                                                                                                         tpsTraff
                                                                                                                                         icOnly
------------------       -----------------       --------------- -------      ----    ---------- ------------          ----------------- --------
microfgcheaprod121322330 FGCHealth_Prod-Nifi1_RG canadacentral   Standard_GRS Storage            2020-12-14 4:33:32 AM Succeeded         False
    General notes
Get-AzStorageAccount -ErrorAction Stop

