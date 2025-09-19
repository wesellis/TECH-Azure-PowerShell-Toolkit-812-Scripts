#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Storagepool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Storagepool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Configuration StoragePool
{
  param ($WEMachineName)

  Node $WEMachineName
  {
	Script ConfigureStoragePool { 
		SetScript = { 
			$disks = Get-PhysicalDisk -ErrorAction Stop –CanPool $true
			New-StoragePool -FriendlyName "DataPool" -StorageSubsystemFriendlyName " Windows Storage*" -PhysicalDisks $disks | New-VirtualDisk -FriendlyName " DataDisk" -UseMaximumSize -NumberOfColumns $disks.Count -ResiliencySettingName " Simple" -ProvisioningType Fixed -Interleave 65536 | Initialize-Disk -Confirm:$WEFalse -PassThru | New-Partition -DriveLetter H –UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel " DATA" -Confirm:$false			
		} 

		TestScript = { 
			Test-Path H:\ 
		} 
		GetScript = { <# This must return a hash table #> }          }   
  }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
