<#
.SYNOPSIS
    Configure Dsc

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Set-ExecutionPolicy -ErrorAction Stop Unrestricted -Force
Install-PackageProvider -Name NuGet -Force
Install-Module -Name ComputerManagementDSC -Force
Install-Module -Name xActiveDirectory -Force
Install-Module -Name xNetworking -Force
Install-Module -Name xStorage -Force
$swapDiskSize = (get-partition -DriveLetter D).Size
Write-Verbose ("Size of partition D (containing pagefile): {0:f2} GB" -f ($swapDiskSize / 1GB))
$physicalMemory = (Get-CimInstance -class " cim_physicalmemory" | Measure-Object -Property Capacity -Sum).Sum
Write-Verbose ("Size of Physical memory                  : {0:f2} GB" -f ($physicalMemory / 1GB))
$newSwapDiskSize = [math]::min($swapDiskSize * 0.8, $physicalMemory + 10Mb)
Write-Verbose ("New swapfile for D, size                 : {0:f2} GB" -f ($newSwapDiskSize / 1GB))
$swapSizeMB = [math]::Round($newSwapDiskSize / 100Mb) * 100Mb / 1MB
Write-Verbose ("New rounded swapfile in MB for D, size   : {0:f0} MB" -f ($swapSizeMB))
Write-Verbose "Initial settings for the swapfile(s)"
wmic pagefile list /format:list
Write-Verbose "Removing swapfile settings"
wmic pagefileset delete
Write-Verbose "Converting all to manually managed"
wmic computersystem set AutomaticManagedPagefile=False
Write-Verbose "Configuring swapfile for D:"
& 'wmic' 'pagefileset' 'create' " name=`" d:\pagefile.sys`" ,InitialSize=2048,MaximumSize=$swapSizeMB"
Write-Verbose "Post settings for the swapfile(s)"
wmic pagefile list /format:list
Write-Verbose "Settings will be effective after the next reboot."
exit 0\n