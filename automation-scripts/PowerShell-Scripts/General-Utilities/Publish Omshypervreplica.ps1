<#
.SYNOPSIS
    Publish Omshypervreplica

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
    We Enhanced Publish Omshypervreplica

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


workflow Publish-omsHyperVReplica
{
	[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
		[Parameter(Mandatory=$true)]
		[string]
		$computerName
	)

	$WEOMSConnection = Get-AutomationConnection -Name 'omsHypervReplicaOMSConnection'
	$credential    = Get-AutomationPSCredential -Name 'omsHypervReplicaRunAsAccount'
; 	$omsRunNumber  = Get-AutomationVariable -Name 'omsHypervReplicaRunNumber'

	Write-Verbose 'Getting Run Number'
; 	$omsRunNumberIncrease = $omsRunNumber + 1
	Set-AutomationVariable -Name 'omsHypervReplicaRunNumber' -Value $omsRunNumberIncrease

	Write-Verbose 'Getting Replication Statistics From Hosts'

	ForEach -Parallel -throttlelimit 5 ($computer in ($computerName -split ';'))
	{
		$vms = InlineScript {
			Invoke-Command  -ScriptBlock {
				Measure-VMReplication -ReplicationMode Primary
			} -ComputerName $WEUSING:computer -Credential $WEUSING:credential
		}

		if($vms)
		{
			ForEach -Parallel ($vm in $vms)
			{
			; 	$WEOMSDataInjection = @{
					OMSConnection     = $WEOMSConnection
					LogType           = 'hyperVReplica'
					UTCTimeStampField = 'LogTime'
					OMSDataObject     = [psCustomObject]@{
															name                      = $vm.name
															primaryServer             = $vm.primaryServerName
															replicaServer             = $vm.replicaServerName
															state                     = $vm.state
															health                    = $vm.health
															LastReplicationTime       = $vm.LastReplicationTime
															AverageReplicationSize    = $vm.AvgReplSize
															LogTime                   = [Datetime]::UtcNow
															runNumber                 = $omsRunNumber
														}
				}

				try
				{
					Write-Verbose " Uploading Data To OMS For VM $($vm.name)"
					New-OMSDataInjection -ErrorAction Stop @OMSDataInjection
				}
				catch
				{
					Write-Error $_
				}
			}
		}
		else
		{
			Write-Verbose 'No VMs are being replicated.'
		}
	}
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================