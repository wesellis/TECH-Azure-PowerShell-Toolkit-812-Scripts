#Requires -Version 7.4

<#
.SYNOPSIS
    Uploadcerts - Certificate upload utility for SafeKit

.DESCRIPTION
    Azure automation for uploading certificates to SafeKit nodes
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
#>

[CmdletBinding()]
param(
	[string[]] $targets,
	[string] $userpwd = $env:CA_CREDENTIALS,
	[string] $skbase = "/safekit"
)
    $ErrorActionPreference = "Stop"
    $curlcmd = "$skbase/private/bin/curl.exe"
    $safeweb = "$skbase/web"
if (Test-Path "$safeweb/conf/ca"){
	Write-Output "CA already initialized, skipping certificate generation"
}else{
    $caname = "/CN=Safekit CA"
try{
    $meta = Invoke-RestMethod -Headers @{"Metadata" = "true"} -URI "http://169.254.169.254/metadata/instance?api-version=2017-08-01" -Method get
	if($meta) {
    $caname = "/CN=SafeKit CA for Azure $($meta.compute.resourceGroupName) cluster"
	}
}catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
    $cwd = Get-Location -ErrorAction Stop
try{
	cd "$safeweb/bin"
	& ./initssl sca "$caname"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "action=swhttps" "https://localhost:9001/caserv"
}finally{
	cd $cwd
}
}
for($i=1; $i -lt $targets.Length; $i++) {
    $targetip = $($targets[$i])
	Write-Output "uploading cert to $targetip"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "file=@$safeweb/conf/cacert.crt" "-F" "action=import" "-F" "target=T_CA" "-F" "add=yes" "https://$($targetip):9001/caserv"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "file=@$safeweb/conf/cacert.crt" "-F" "action=import" "-F" "target=T_CCA" "-F" "add=yes" "https://$($targetip):9001/caserv"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "file=@$safeweb/conf/server.crt" "-F" "action=import" "-F" "target=T_SC" "-F" "add=yes" "https://$($targetip):9001/caserv"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "file=@$safeweb/conf/server.key" "-F" "action=import" "-F" "target=T_SK" "-F" "add=yes" "https://$($targetip):9001/caserv"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "file=@$safeweb/conf/admin.crt" "-F" "action=import" "-F" "target=T_CC" "-F" "add=yes" "https://$($targetip):9001/caserv"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "file=@$safeweb/conf/admin.key" "-F" "action=import" "-F" "target=T_CK" "-F" "add=yes" "https://$($targetip):9001/caserv"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "file=@$safeweb/conf/proxy.crtkey" "-F" "action=import" "-F" "target=T_PCCK" "-F" "add=yes" "https://$($targetip):9001/caserv"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "file=@$safeweb/conf/sslclient.crl" "-F" "action=import" "-F" "target=T_CRL" "-F" "add=yes" "https://$($targetip):9001/caserv"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "action=swhttps" "https://$($targetip):9001/caserv"
	& $curlcmd "-k" "-u" "$userpwd" "-X" "POST" "-F" "action=shutdown" "https://$($targetip):9001/caserv"`n}
