<#
.SYNOPSIS
    Setupcertificate

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
    We Enhanced Setupcertificate

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEContactEMailForLetsEncrypt = "$env:ContactEMailForLetsEncrypt"
$WECertificatePfxPassword = " $env:CertificatePfxPassword"
$certificatePfxUrl = " $env:certificatePfxUrl"
$certificatePfxFile = ""

if (" $certificatePfxUrl" -ne "" -and " $WECertificatePfxPassword" -ne "" ) {

    $certificatePfxFile = Join-Path $myPath " certificate.pfx"
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    (New-Object -ErrorAction Stop System.Net.WebClient).DownloadFile($certificatePfxUrl, $certificatePfxFile)
    $cert = New-Object -ErrorAction Stop System.Security.Cryptography.X509Certificates.X509Certificate2($certificatePfxFile, $certificatePfxPassword)
    $certificateThumbprint = $cert.Thumbprint
    Write-WELog " Certificate File Thumbprint $certificateThumbprint" " INFO"
    if (!(Get-Item -ErrorAction Stop Cert:\LocalMachine\my\$certificateThumbprint -ErrorAction SilentlyContinue)) {
        Write-WELog " Importing Certificate to LocalMachine\my" " INFO"
        Import-PfxCertificate -FilePath $certificatePfxFile -CertStoreLocation cert:\localMachine\my -Password (ConvertTo-SecureString -String $certificatePfxPassword -AsPlainText -Force) | Out-Null
    }
    $dnsidentity = $cert.GetNameInfo(" SimpleName" ,$false)
    if ($dnsidentity.StartsWith(" *" )) {
        $dnsidentity = $dnsidentity.Substring($dnsidentity.IndexOf(" ." )+1)
    }
    Write-WELog " DNS identity $dnsidentity" " INFO"

} elseif (" $WEContactEMailForLetsEncrypt" -ne "" ) {

    try {
        Write-WELog " Stopping Web Sites" " INFO"
        Get-Website -ErrorAction Stop | Stop-Website
 
        Write-WELog " Using LetsEncrypt to create SSL Certificate" " INFO"

        $nuGetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if ((-not $nuGetProvider) -or ([Version]$nuGetProvider.Version -lt [Version]" 2.8.5.201" )) {
            Write-WELog " Installing NuGet Package Provider" " INFO"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        }
        $acmePSModule = Get-InstalledModule -Name ACME-PS -ErrorAction SilentlyContinue
        if ((-not $acmePSModule) -or ([Version]$acmePSModule.Version -lt [Version]" 1.5.0" )) {
            Write-WELog " Installing ACME-PS PowerShell Module" " INFO"
            Install-Module -Name ACME-PS -RequiredVersion " 1.5.0" -Force
        }

        Write-WELog " Importing ACME-PS module" " INFO"
        Import-Module ACME-PS

        $certificatePfxFile = Join-Path $myPath " certificate.pfx"
        $stateDir = Join-Path $myPath 'acmeState'

        Write-WELog " Initializing ACME State" " INFO"
        New-ACMEState -Path $stateDir

        Write-WELog " Registring Contact EMail address and accept Terms Of Service" " INFO"
        Get-ACMEServiceDirectory -State $stateDir -ServiceName " LetsEncrypt" -PassThru | Out-Null

        Write-WELog " Creating New Nonce" " INFO"
        New-ACMENonce -State $stateDir | Out-Null

        Write-WELog " Creating New AccountKey" " INFO"
        New-ACMEAccountKey -state $stateDir -PassThru | Out-Null

        Write-WELog " Creating New Account" " INFO"
        New-ACMEAccount -state $stateDir -EmailAddresses $WEContactEMailForLetsEncrypt -AcceptTOS | Out-Null

        Write-WELog " Creating new dns Identifier" " INFO"
        $identifier = New-ACMEIdentifier -ErrorAction Stop $publicDnsName
    
        Write-WELog " Creating ACME Order" " INFO"
       ;  $order = New-ACMEOrder -state $stateDir -Identifiers $identifier
    
        Write-WELog " Getting ACME Authorization" " INFO"
       ;  $authorizations = @(Get-ACMEAuthorization -State $stateDir -Order $order);

        Write-WELog " Creating Challenge WebSite" " INFO"
        $challengeLocalPath = 'c:\inetpub\wwwroot\challenge'
        New-Item -ErrorAction Stop $challengeLocalPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        New-Website -Name challenge -Port 80 -PhysicalPath $challengeLocalPath | Out-Null

'<configuration>
  <location path=" ." >
    <system.webServer>
      <httpProtocol>
        <customHeaders>
          <add name=" X-Content-Type-Options" value=" nosniff" />
        </customHeaders>
        </httpProtocol>
        <staticContent>
          <mimeMap fileExtension=" .*" mimeType=" application/octet-stream" />
          <mimeMap fileExtension=" ." mimeType=" text/plain" />
        </staticContent>
      <directoryBrowse enabled=" true" />
    </system.webServer>
  </location>
</configuration>
' | Set-Content -ErrorAction Stop (Join-Path $challengeLocalPath 'web.config')

        Write-WELog " Starting Challenge WebSite" " INFO"
        Start-Website -Name challenge

        foreach($authz in $authorizations) {
            # Select a challenge to fullfill
            Write-WELog " Getting ACME Challenge" " INFO"
           ;  $challenge = Get-ACMEChallenge -State $stateDir -Authorization $authZ -Type " http-01" ;
    
            # Create the file requested by the challenge
            $fileName = Join-Path $challengeLocalPath $challenge.Data.RelativeUrl
            Write-Information $filename
           ;  $challengePath = [System.IO.Path]::GetDirectoryName($filename);

            if(-not (Test-Path $challengePath)) {
                New-Item -Path $challengePath -ItemType Directory | Out-Null
            }
    
            Set-Content -Path $fileName -Value $challenge.Data.Content -NoNewLine
    
            # Check if the challenge is readable
            Write-WELog " Checking Challenge at http://$($challenge.Data.AbsoluteUrl)" " INFO"
            1..10 | % {
                $cnt = $_
                try {
                    Invoke-WebRequest -Uri " http://$($challenge.Data.AbsoluteUrl)" -UseBasicParsing | out-null
                }
                catch {
                    $secs = [int]$cnt*2
                    Write-WELog " Error - waiting $secs seconds" " INFO"
                    Start-Sleep -Seconds $secs
                }
            }
    
            Write-WELog " Completing ACME Challenge" " INFO"
            # Signal the ACME server that the challenge is ready
            $challenge | Complete-ACMEChallenge $stateDir | Out-Null
        }
    
        # Wait a little bit and update the order, until we see the states
        while($order.Status -notin (" ready" ," invalid" )) {
            Start-Sleep -Seconds 10
            $order | Update-ACMEOrder -state $stateDir -PassThru | Out-Null
        }
    
        $certKeyFile = " $stateDir\$publicDnsName-$(get-date -format yyyy-MM-dd-HH-mm-ss).key.xml"
        $certKey = New-ACMECertificateKey -path $certKeyFile
    
        Write-WELog " Completing ACME Order" " INFO"
        Complete-ACMEOrder -state $stateDir -Order $order -CertificateKey $certKey | Out-Null
    
        # Now we wait until the ACME service provides the certificate url
        while(-not $order.CertificateUrl) {
            Start-Sleep -Seconds 15
            $order | Update-Order -state $stateDir -PassThru | Out-Null
        }
    
        # As soon as the url shows up we can create the PFX
        Write-WELog " Exporting certificate to $certificatePfxFile" " INFO"
        Export-ACMECertificate -state $stateDir -Order $order -CertificateKey $certKey -Path $certificatePfxFile -Password (ConvertTo-SecureString -String $certificatePfxPassword -AsPlainText -Force)
    
        $cert = New-Object -ErrorAction Stop System.Security.Cryptography.X509Certificates.X509Certificate2($certificatePfxFile, $certificatePfxPassword)
        $certificateThumbprint = $cert.Thumbprint
        
        Write-WELog " Importing Certificate to LocalMachine\my" " INFO"
        Import-PfxCertificate -FilePath $certificatePfxFile -CertStoreLocation cert:\localMachine\my -Password (ConvertTo-SecureString -String $certificatePfxPassword -AsPlainText -Force) | Out-Null
        
       ;  $dnsidentity = $cert.GetNameInfo(" SimpleName" ,$false)
        if ($dnsidentity.StartsWith(" *" )) {
           ;  $dnsidentity = $dnsidentity.Substring($dnsidentity.IndexOf(" ." )+1)
        }
        Write-WELog " DNS identity $dnsidentity" " INFO"
    }
    catch {
        # If Any error occurs (f.ex. rate-limits), setup self signed certificate
        Write-WELog " Error creating letsEncrypt certificate, reverting to self-signed" " INFO"
        Write-WELog " Error was: $($_.Exception.Message)" " INFO"
        . (Join-Path $runPath $WEMyInvocation.MyCommand.Name)
    }

    Write-WELog " Removing Challenge WebSite" " INFO"
    Get-Website -ErrorAction Stop | Where-Object { $_.Name -eq 'challenge' } | % {
        Stop-Website -Name $_.Name
        Remove-Website -Name $_.Name
    }

    Write-WELog " Starting Web Sites" " INFO"
    Get-Website -ErrorAction Stop | Where-Object { $_.Name -ne 'challenge' } | Start-Website

} else {
    . (Join-Path $runPath $WEMyInvocation.MyCommand.Name)
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================