#Requires -Version 7.4

<#`n.SYNOPSIS
    Setupcertificate

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ContactEMailForLetsEncrypt = "$env:ContactEMailForLetsEncrypt"
$CertificatePfxPassword = $env:CREDENTIAL_Password
$CertificatePfxUrl = " $env:certificatePfxUrl"
$CertificatePfxFile = ""
if (" $CertificatePfxUrl" -ne "" -and " $CertificatePfxPassword" -ne "" ) {
    $CertificatePfxFile = Join-Path $MyPath " certificate.pfx"
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    (New-Object -ErrorAction Stop System.Net.WebClient).DownloadFile($CertificatePfxUrl, $CertificatePfxFile)
    $cert = New-Object -ErrorAction Stop System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePfxFile, $CertificatePfxPassword)
    $CertificateThumbprint = $cert.Thumbprint
    Write-Output "Certificate File Thumbprint $CertificateThumbprint"
    if (!(Get-Item -ErrorAction Stop Cert:\LocalMachine\my\$CertificateThumbprint -ErrorAction SilentlyContinue)) {
        Write-Output "Importing Certificate to LocalMachine\my"
        Import-PfxCertificate -FilePath $CertificatePfxFile -CertStoreLocation cert:\localMachine\my -Password (Read-Host -Prompt "Enter secure value" -AsSecureString) | Out-Null
    }
    $dnsidentity = $cert.GetNameInfo("SimpleName" ,$false)
    if ($dnsidentity.StartsWith("*" )) {
        $dnsidentity = $dnsidentity.Substring($dnsidentity.IndexOf(" ." )+1)
    }
    Write-Output "DNS identity $dnsidentity"
} elseif (" $ContactEMailForLetsEncrypt" -ne "" ) {
    try {
        Write-Output "Stopping Web Sites"
        Get-Website -ErrorAction Stop | Stop-Website
        Write-Output "Using LetsEncrypt to create SSL Certificate"
        $NuGetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if ((-not $NuGetProvider) -or ([Version]$NuGetProvider.Version -lt [Version]" 2.8.5.201" )) {
            Write-Output "Installing NuGet Package Provider"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        }
        $AcmePSModule = Get-InstalledModule -Name ACME-PS -ErrorAction SilentlyContinue
        if ((-not $AcmePSModule) -or ([Version]$AcmePSModule.Version -lt [Version]" 1.5.0" )) {
            Write-Output "Installing ACME-PS PowerShell Module"
            Install-Module -Name ACME-PS -RequiredVersion " 1.5.0" -Force
        }
        Write-Output "Importing ACME-PS module"
        Import-Module ACME-PS
        $CertificatePfxFile = Join-Path $MyPath " certificate.pfx"
        $StateDir = Join-Path $MyPath 'acmeState'
        Write-Output "Initializing ACME State"
        New-ACMEState -Path $StateDir
        Write-Output "Registring Contact EMail address and accept Terms Of Service"
        Get-ACMEServiceDirectory -State $StateDir -ServiceName "LetsEncrypt" -PassThru | Out-Null
        Write-Output "Creating New Nonce"
        New-ACMENonce -State $StateDir | Out-Null
        Write-Output "Creating New AccountKey"
        New-ACMEAccountKey -state $StateDir -PassThru | Out-Null
        Write-Output "Creating New Account"
        New-ACMEAccount -state $StateDir -EmailAddresses $ContactEMailForLetsEncrypt -AcceptTOS | Out-Null
        Write-Output "Creating new dns Identifier"
        $identifier = New-ACMEIdentifier -ErrorAction Stop $PublicDnsName
        Write-Output "Creating ACME Order"
$order = New-ACMEOrder -state $StateDir -Identifiers $identifier
        Write-Output "Getting ACME Authorization"
$authorizations = @(Get-ACMEAuthorization -State $StateDir -Order $order);
        Write-Output "Creating Challenge WebSite"
        $ChallengeLocalPath = 'c:\inetpub\wwwroot\challenge'
        New-Item -ErrorAction Stop $ChallengeLocalPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        New-Website -Name challenge -Port 80 -PhysicalPath $ChallengeLocalPath | Out-Null
'<configuration>
  <location path=" ." >
    <system.webServer>
      <httpProtocol>
        <customHeaders>
          <add name="X-Content-Type-Options" value=" nosniff"/>
        </customHeaders>
        </httpProtocol>
        <staticContent>
          <mimeMap fileExtension=" .*" mimeType=" application/octet-stream"/>
          <mimeMap fileExtension=" ." mimeType=" text/plain"/>
        </staticContent>
      <directoryBrowse enabled=" true"/>
    </system.webServer>
  </location>
</configuration>
' | Set-Content -ErrorAction Stop (Join-Path $ChallengeLocalPath 'web.config')
        Write-Output "Starting Challenge WebSite"
        Start-Website -Name challenge
        foreach($authz in $authorizations) {
            Write-Output "Getting ACME Challenge"
$challenge = Get-ACMEChallenge -State $StateDir -Authorization $AuthZ -Type " http-01" ;
            $FileName = Join-Path $ChallengeLocalPath $challenge.Data.RelativeUrl
            Write-Output $filename
$ChallengePath = [System.IO.Path]::GetDirectoryName($filename);
            if(-not (Test-Path $ChallengePath)) {
                New-Item -Path $ChallengePath -ItemType Directory | Out-Null
            }
            Set-Content -Path $FileName -Value $challenge.Data.Content -NoNewLine
            Write-Output "Checking Challenge at http://$($challenge.Data.AbsoluteUrl)"
            1..10 | % {
                $cnt = $_
                try {
                    Invoke-WebRequest -Uri " http://$($challenge.Data.AbsoluteUrl)" -UseBasicParsing | out-null
                }
                catch {
                    $secs = [int]$cnt*2
                    Write-Output "Error - waiting $secs seconds"
                    Start-Sleep -Seconds $secs
                }
            }
            Write-Output "Completing ACME Challenge"
            $challenge | Complete-ACMEChallenge $StateDir | Out-Null
        }
        while($order.Status -notin (" ready" ," invalid" )) {
            Start-Sleep -Seconds 10
            $order | Update-ACMEOrder -state $StateDir -PassThru | Out-Null
        }
        $CertKeyFile = " $StateDir\$PublicDnsName-$(get-date -format yyyy-MM-dd-HH-mm-ss).key.xml"
        $CertKey = New-ACMECertificateKey -path $CertKeyFile
        Write-Output "Completing ACME Order"
        Complete-ACMEOrder -state $StateDir -Order $order -CertificateKey $CertKey | Out-Null
        while(-not $order.CertificateUrl) {
            Start-Sleep -Seconds 15
            $order | Update-Order -state $StateDir -PassThru | Out-Null
        }
        Write-Output "Exporting certificate to $CertificatePfxFile"
        Export-ACMECertificate -state $StateDir -Order $order -CertificateKey $CertKey -Path $CertificatePfxFile -Password (Read-Host -Prompt "Enter secure value" -AsSecureString)
        $cert = New-Object -ErrorAction Stop System.Security.Cryptography.X509Certificates.X509Certificate2($CertificatePfxFile, $CertificatePfxPassword)
        $CertificateThumbprint = $cert.Thumbprint
        Write-Output "Importing Certificate to LocalMachine\my"
        Import-PfxCertificate -FilePath $CertificatePfxFile -CertStoreLocation cert:\localMachine\my -Password (Read-Host -Prompt "Enter secure value" -AsSecureString) | Out-Null
$dnsidentity = $cert.GetNameInfo("SimpleName" ,$false)
        if ($dnsidentity.StartsWith("*" )) {
$dnsidentity = $dnsidentity.Substring($dnsidentity.IndexOf(" ." )+1)
        }
        Write-Output "DNS identity $dnsidentity"
    }
    catch {
        Write-Output "Error creating letsEncrypt certificate, reverting to self-signed"
        Write-Output "Error was: $($_.Exception.Message)"
        . (Join-Path $RunPath $MyInvocation.MyCommand.Name)
    }
    Write-Output "Removing Challenge WebSite"
    Get-Website -ErrorAction Stop | Where-Object { $_.Name -eq 'challenge' } | % {
        Stop-Website -Name $_.Name
        Remove-Website -Name $_.Name
    }
    Write-Output "Starting Web Sites"
    Get-Website -ErrorAction Stop | Where-Object { $_.Name -ne 'challenge' } | Start-Website
} else {
    . (Join-Path $RunPath $MyInvocation.MyCommand.Name)`n}
