#Requires -Version 7.4

<#`n.SYNOPSIS
    Securesonarqube

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    .SYNOPSIS
        Secure SonarQube installation
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
      [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ServerName,
      [Parameter()]
    [ValidateNotNullOrEmpty()]
    $WebsiteName,
      [Parameter()]
    [ValidateNotNullOrEmpty()]
    $InstallationType,
      $ReverseProxyType
)
if($InstallationType -eq 'Secure')
{
    Invoke-Expression ((new-object -ErrorAction Stop net.webclient).DownloadString(" https://chocolatey.org/install.ps1" ))
    cinst urlrewrite -y --force
    cinst iis-arr -y --force
    $ExistingCertificate =Get-ChildItem -ErrorAction Stop cert:\LocalMachine\CA | Where-Object subject -eq 'CN=$ServerName'
    if($null -eq $ExistingCertificate)
        {
            Import-Module WebAdministration
            Set-Location -ErrorAction Stop IIS:\SslBindings
            New-WebBinding -Name $WebsiteName -IP "*" -Port 443 -Protocol https
$c = New-SelfSignedCertificate -DnsName " $ServerName" -CertStoreLocation " cert:\LocalMachine\My"
    $c | New-Item -ErrorAction Stop 0.0.0.0!443
            Get-WebBinding -Port 8080 -Name $WebsiteName | Remove-WebBinding -ErrorAction Stop
            netsh advfirewall firewall delete rule name="SonarQube (TCP-In)"
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter " system.webServer/proxy" -name " enabled" -value "True"
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter " system.webServer/proxy" -name " reverseRewriteHostInResponseHeaders" -value "False"
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter " system.webServer/rewrite/allowedServerVariables" -name " reverseRewriteHostInResponseHeaders" -value "False"
            Add-WebConfiguration  -pspath 'MACHINE/WEBROOT/APPHOST' -filter '/system.webServer/rewrite/allowedServerVariables' -atIndex 0 -value @{name="X_FORWARDED_PROTO" ;value=" https" }
            Add-WebConfiguration  -pspath 'MACHINE/WEBROOT/APPHOST' -filter '/system.webServer/rewrite/allowedServerVariables' -atIndex 0 -value @{name="ORIGINAL_URL" ;value=" {HTTP_HOST}" }
    $site = "IIS:\Sites\$WebsiteName"
    $FilterRoot = "/system.webserver/rewrite/rules/rule[@name='ReverseProxyInboundRule1']"
            Add-WebConfigurationProperty -pspath $site -filter '/system.webserver/rewrite/rules' -name " ." -value @{name='ReverseProxyInboundRule1'; patternSyntax='Regular Expresessions'; stopProcessing='True'}
            Set-WebConfigurationProperty -pspath $site -filter " $FilterRoot/match" -name " url" -value " (.*)"
            Set-WebConfigurationProperty -pspath $site -filter " $FilterRoot/action" -name " type" -value "Rewrite"
            Set-WebConfigurationProperty -pspath $site -filter " $FilterRoot/action" -name " url" -value " http://localhost:9000/{R:1}"
            Add-WebConfiguration  -pspath $site -filter " $FilterRoot/serverVariables" -atIndex 0 -value @{name="X_FORWARDED_PROTO" ;value=" https" }
            Add-WebConfiguration  -pspath $site -filter " $FilterRoot/serverVariables" -atIndex 0 -value @{name="ORIGINAL_URL" ;value=" {HTTP_HOST}" }
    $FilterRoot = "/system.webserver/rewrite/outboundRules/rule[@name='ReverseProxyOutboundRule1']"
            Add-WebConfigurationProperty -pspath $site -filter '/system.webserver/rewrite/outboundRules' -name " ." -value @{name='ReverseProxyOutboundRule1'; patternSyntax='Regular Expresessions'; stopProcessing='True'; preCondition='IsRedirection'}
            Set-WebConfigurationProperty -pspath $site -filter " $FilterRoot/match" -name " filterByTags" -value "A, Form, Img"
            Set-WebConfigurationProperty -pspath $site -filter " $FilterRoot/match" -name " serverVariable" -value "RESPONSE_LOCATION"
            Set-WebConfigurationProperty -pspath $site -filter " $FilterRoot/match" -name " pattern" -value " ^http://[^/]+/(.*)"
            Set-WebConfigurationProperty -pspath $site -filter " $FilterRoot/action" -name " type" -value "Rewrite"
            Set-WebConfigurationProperty -pspath $site -filter " $FilterRoot/action" -name " value" -value " https://$ServerName/{R:1}"
            Add-WebConfigurationProperty -pspath $site -filter '/system.webserver/rewrite/outboundRules/preConditions' -name " ." -value @{name='IsRedirection'}
            Add-WebConfigurationProperty -pspath $site -filter '/system.webserver/rewrite/outboundRules/preConditions' -name " ." -value @{name='ResponseIsHtml1'}
            Add-WebConfigurationProperty -pspath $site -filter " system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='IsRedirection']" -name " ." -value @{input='{RESPONSE_STATUS}';pattern='3\d\d'}
            Add-WebConfigurationProperty -pspath $site -filter " system.webServer/rewrite/outboundRules/preConditions/preCondition[@name='ResponseIsHtml1']" -name " ." -value @{input='{RESPONSE_CONTENT_TYPE}';pattern='^text/html'}
        }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
