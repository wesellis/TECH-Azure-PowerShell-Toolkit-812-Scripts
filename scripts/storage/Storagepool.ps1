<#
.SYNOPSIS
    Storagepool

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
#>

#Requires -Version 7.4
$ErrorActionPreference = 'Stop'

    Storagepool
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Configuration StoragePool
{
  [CmdletBinding()]
$MachineName)
  Node $MachineName
  {
	Script ConfigureStoragePool {
		SetScript = {
			$disks = Get-PhysicalDisk -ErrorAction Stop CanPool $true
			New-StoragePool -FriendlyName "DataPool" -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks $disks | New-VirtualDisk -FriendlyName "DataDisk" -UseMaximumSize -NumberOfColumns $disks.Count -ResiliencySettingName "Simple" -ProvisioningType Fixed -Interleave 65536 | Initialize-Disk -Confirm:$False -PassThru | New-Partition -DriveLetter H UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DATA" -Confirm:$false
		}
		TestScript = {
			Test-Path H:\
		}
		GetScript = { <
    PowerShell script
.DESCRIPTION
    PowerShell operation


    Author: Wes Ellis (wes@wesellis.com)
This must return a hash table
  }
`n}
