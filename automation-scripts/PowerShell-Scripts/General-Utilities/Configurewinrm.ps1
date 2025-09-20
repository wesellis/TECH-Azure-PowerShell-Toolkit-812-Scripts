<#
.SYNOPSIS
    Configurewinrm

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)]
    [string] $HostName
)
[OutputType([PSObject])]

{
    try
    {
        $config = Winrm enumerate winrm/config/listener
        foreach($conf in $config)
        {
            if($conf.Contains("HTTPS" ))
            {
                Write-Verbose "HTTPS is already configured. Deleting the exisiting configuration."
                winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
                break
            }

} catch
    {
        Write-Verbose -Verbose "Exception while deleting the listener: " + $_.Exception.Message
    }
}
function Create-Certificate
{
    [CmdletBinding()]
param(
        [string]$hostname
    )
    # makecert ocassionally produces negative serial numbers
	# which golang tls/crypto <1.6.1 cannot handle
	# https://github.com/golang/go/issues/8265
    $serial = Get-Random -ErrorAction Stop
    # Dynamically generate the end date for the certificate
    	# validity period to be a year from the date the
	# script is run
    $endDate = (Get-Date).AddYears(1).ToString("MM/dd/yyyy" )
    .\makecert -r -pe -n CN=$hostname -b 01/01/2012 -e $endDate -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localmachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 -# $serial 2>&1 | Out-Null
    $thumbprint=(Get-ChildItem -ErrorAction Stop cert:\Localmachine\my | Where-Object { $_.Subject -eq "CN=" + $hostname } | Select-Object -Last 1).Thumbprint
    if(-not $thumbprint)
    {
        throw "Failed to create the test certificate."
    }
    return $thumbprint
}
function Configure-WinRMHttpsListener
{
    [CmdletBinding()]
param([string] $HostName,
          [string] $port)
    # Delete the WinRM Https listener if it is already configured
    Delete-WinRMListener
    # Create a test certificate
    $cert = (Get-ChildItem -ErrorAction Stop cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=" + $hostname } | Select-Object -Last 1)
    $thumbprint = $cert.Thumbprint
    if(-not $thumbprint)
    {
	    $thumbprint = Create-Certificate -hostname $HostName
    }
    elseif (-not $cert.PrivateKey)
    {
        # The private key is missing - could have been sysprepped
        # Delete the certificate
        Remove-Item -ErrorAction Stop Cert:\LocalMachine\My\$thumbpri -Forcen -Forcet -Force
$thumbprint = Create-Certificate -hostname $HostName
    }
$WinrmCreate= " winrm create --% winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=`" $hostName`" ;CertificateThumbprint=`" $thumbPrint`" }"
    invoke-expression $WinrmCreate
    winrm set winrm/config/service/auth '@{Basic=" true" }'
}
function Add-FirewallException
{
    [CmdletBinding()]
param([string] $port)
    # Delete an exisitng rule
    netsh advfirewall firewall delete rule name="Windows Remote Management (HTTPS-In)" dir=in protocol=TCP localport=$port
    # Add a new firewall rule
    netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=$port
}
$winrmHttpsPort=5986
winrm set winrm/config '@{MaxEnvelopeSizekb = " 8192" }'
Configure-WinRMHttpsListener $HostName $port
Add-FirewallException -port $winrmHttpsPort\n

