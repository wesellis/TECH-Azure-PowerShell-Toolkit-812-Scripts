#Requires -Version 7.4

<#
.SYNOPSIS
    Configure SafeKit Cluster

.DESCRIPTION
    Configures SafeKit cluster with public and private IP addresses for VMs

.PARAMETER publicipfmt
    Public IP format string

.PARAMETER privateiplist
    List of private IP addresses

.PARAMETER vmlist
    List of VM names

.PARAMETER lblist
    List of load balancers

.PARAMETER Passwd
    Password for CA admin

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [string]$publicipfmt,
    [string]$privateiplist,
    [string]$vmlist,
    [string]$lblist,
    [string]$Passwd
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$safekitcmd = $env:SAFEKITCMD
$safevar = $env:SAFEVAR
$safewebconf = $env:SAFEWEBCONF
$logdir = $pwd

function Write-Log {
    param(
        [string]$Message
    )
    $Stamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    Add-Content "$logdir/installsk.log" "$stamp [configCluster.ps1] $Message"
}

try {
    Write-Log $vmlist
    Write-Log $publicipfmt
    Write-Log $privateiplist
    Write-Log $lblist

    if ($vmlist) {
        $vmargs = @()
        $lbargs = @()
        $privateipargs = @()
        $targets = @()

        "[" | Out-File -Encoding ASCII -FilePath "$safewebconf/ipnames.json"
        "[" | Out-File -Encoding ASCII -FilePath "$safewebconf/ipv4.json"

        $vmargs = $vmargs + ([regex]::Replace($vmlist, '[\[\]]', '') -split ',')
        $privateipargs = $privateipargs + ([regex]::Replace($privateiplist, '[\[\]]', '') -split ',')

        if ($lblist) {
            $lbargs = $lbargs + ($lblist -split ',')
        }

        Write-Log "configuring cluster.xml and certificates input files"
        $str = "<cluster><lans>"

        if ($publicipfmt) {
            $str = $str + "<lan name='External' console='on' command='off' framework='off'>"
            for ($i = 0; $i -lt $vmargs.Length; $i++) {
                $dnsname = $($publicipfmt).Replace('%VM%', $($vmargs[$i])).ToLower()
                $str = $str + "<node name='$($vmargs[$i])' addr='$dnsname'/>"
                "`"$dnsname`"," | Out-File -Append -Encoding ASCII -FilePath "$safewebconf/ipnames.json"
            }
            $str = $str + "</lan>"
        }

        for ($i = 0; $i -lt $lbargs.Length; $i++) {
            $dnsname = $($lbargs[$i])
            if ($dnsname.Length) {
                "`"$dnsname`"," | Out-File -Append -Encoding ASCII -FilePath "$safewebconf/ipnames.json"
            }
        }

        "null]" | Out-File -Append -Encoding ASCII -FilePath "$safewebconf/ipnames.json"

        $str = $str + "<lan name='default' console='on' command='on' framework='on' >"
        for ($i = 0; $i -lt $vmargs.Length; $i++) {
            $str = $str + "<node name='$($vmargs[$i])' addr='$($privateipargs[$i])'/>"
            "`"$($privateipargs[$i])`"," | Out-File -Append -Encoding ASCII -FilePath "$safewebconf/ipv4.json"
            $targets = $targets + $($privateipargs[$i])
        }

        "null]" | Out-File -Append -Encoding ASCII -FilePath "$safewebconf/ipv4.json"

        $str = $str + "</lan></lans></cluster>"
        $str | Out-File -Encoding utf8 "$safevar\cluster\cluster.xml"

        & $safekitcmd cluster config 2>&1
        $res = & $safekitcmd -H "[http],*" -G 2>&1
        Write-Log "result = $res"

        if (Test-Path "./uploadcerts.ps1") {
            & ./uploadcerts.ps1 -skbase "$env:SAFEBASE" -targets $targets -userpwd "CA_admin:$Passwd"
        }
    }

    Write-Log "end of script"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}