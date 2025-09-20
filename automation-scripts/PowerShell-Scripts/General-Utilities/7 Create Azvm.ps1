<#
.SYNOPSIS
    Create Azvm

.DESCRIPTION
    Create Azvm operation
#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
$location = 'Canada Central'
$imageName = 'FGC_Kroll_Image'
$rgName = 'FGC_Kroll_Image_RG'
$Image = Get-AzImage -ResourceGroupName $rgName -ImageName $imageName
$Tag = @{
    Autoshutown     = 'OFF'
    Createdby       = 'Abdullah Ollivierre'
    CustomerName    = 'FGC Health'
    DateTimeCreated = " $datetime"
    Environment     = 'Lab'
    Application     = 'Kroll'
    Purpose         = 'Dev & Test'
    Uptime          = '240 hrs/month'
    Workload        = 'Kroll Lab'
    VMGenenetation  = 'Gen2'
    RebootCaution   = 'Reboot If needed'
    VMSize          = 'B2MS'
}
$newAzVmSplat = @{
    ResourceGroupName   = $rgName
    Name                = "FGC-CR08NW2"
    Image               = $image.Id
    Location            = $location
    VirtualNetworkName  = "FGC_FGC-CR08NW2_VNET"
    SubnetName          = "FGC_FGC-CR08NW2_Subnet"
    SecurityGroupName   = "FGC_FGC-CR08NW2_NSG"
    PublicIpAddressName = "FGC_FGC-CR08NW2_PIP"
    OpenPorts           = 3389
    # Tag                 = $Tag #causing an error maybe need to be added later
}
New-AzVm -ErrorAction Stop @newAzVmSplat

