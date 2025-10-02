#Requires -Version 7.4
#Requires -Modules Hyper-V

<#
.SYNOPSIS
    Publish Hyper-V Replica Metrics to OMS

.DESCRIPTION
    Azure Automation workflow to collect Hyper-V replication metrics
    and publish them to Operations Management Suite (OMS) for monitoring
    and analysis. Processes multiple hosts in parallel.

.PARAMETER ComputerName
    Semicolon-separated list of Hyper-V host names to query

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and Hyper-V module
    Requires OMS connection and credentials configured in Automation
#>

workflow Publish-OMSHyperVReplica {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $ErrorActionPreference = "Stop"

    # Get automation assets
    $OMSConnection = Get-AutomationConnection -Name 'omsHypervReplicaOMSConnection'
    $credential = Get-AutomationPSCredential -Name 'omsHypervReplicaRunAsAccount'
    $OmsRunNumber = Get-AutomationVariable -Name 'omsHypervReplicaRunNumber'

    Write-Verbose 'Getting Run Number'
    $OmsRunNumberIncrease = $OmsRunNumber + 1
    Set-AutomationVariable -Name 'omsHypervReplicaRunNumber' -Value $OmsRunNumberIncrease

    Write-Verbose 'Getting Replication Statistics From Hosts'

    # Process each host in parallel
    ForEach -Parallel -ThrottleLimit 5 ($computer in ($ComputerName -split ';')) {

        # Get VM replication metrics from host
        $vms = InlineScript {
            Invoke-Command -ScriptBlock {
                Measure-VMReplication -ReplicationMode Primary
            } -ComputerName $USING:computer -Credential $USING:credential
        }

        if ($vms) {
            # Process each VM in parallel
            ForEach -Parallel ($vm in $vms) {

                # Prepare data for OMS injection
                $OMSDataInjection = @{
                    OMSConnection = $OMSConnection
                    LogType = 'hyperVReplica'
                    UTCTimeStampField = 'LogTime'
                    OMSDataObject = [PSCustomObject]@{
                        name = $vm.Name
                        primaryServer = $vm.PrimaryServerName
                        replicaServer = $vm.ReplicaServerName
                        state = $vm.State
                        health = $vm.Health
                        LastReplicationTime = $vm.LastReplicationTime
                        AverageReplicationSize = $vm.AvgReplSize
                        LogTime = [DateTime]::UtcNow
                        runNumber = $OmsRunNumber
                    }
                }

                try {
                    Write-Verbose "Uploading Data To OMS For VM $($vm.Name)"
                    New-OMSDataInjection @OMSDataInjection -ErrorAction Stop
                }
                catch {
                    Write-Error "Failed to upload data for VM $($vm.Name): $_"
                }
            }
        }
        else {
            Write-Verbose "No VMs are being replicated on host $computer"
        }
    }
}

# Example usage:
# Publish-OMSHyperVReplica -ComputerName "Host1;Host2;Host3"