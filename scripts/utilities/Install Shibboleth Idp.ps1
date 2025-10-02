#Requires -Version 7.4

<#
.SYNOPSIS
    Install Shibboleth Identity Provider

.DESCRIPTION
    Downloads and installs Shibboleth Identity Provider with Apache Tomcat and Java.
    Configures SSL certificates, firewall rules, and required services.

.PARAMETER Domain
    Domain name for the identity provider

.PARAMETER Location
    Azure location identifier for the deployment

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions and internet connectivity
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Domain,

    [Parameter(Mandatory = $true)]
    [string]$Location
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Unzip {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ZipFile,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutPath
    )

    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutPath)
}

function Get-RandomPassword {
    [CmdletBinding()]
    param(
        [int]$Length = 12,
        [string[]]$SourceData = @('A'..'Z' + 'a'..'z' + '0'..'9')
    )

    $tempPassword = ""
    for ($i = 1; $i -le $Length; $i++) {
        $tempPassword += ($SourceData | Get-Random)
    }
    return $tempPassword
}

try {
    $alphabet = @()
    for ($a = 65; $a -le 90; $a++) {
        $alphabet += [char][byte]$a
    }

    $siteName = "$Domain.$Location.cloudapp.azure.com"
    Write-Output "Site Name: $siteName"

    # Create temp directory
    if (-not (Test-Path "C:\Temp")) {
        New-Item -Path "C:\Temp" -ItemType Directory | Out-Null
    }

    # Download and install JDK 10
    Write-Output "Downloading JDK 10..."
    $source = "http://download.oracle.com/otn-pub/java/jdk/10.0.1+10/fb4372174a714e6b8c52526dc134031e/jdk-10.0.1_windows-x64_bin.exe"
    $destination = "C:\Temp\jdk-10.0.1_windows-x64_bin.exe"
    $client = New-Object System.Net.WebClient
    $cookie = "oraclelicense=accept-securebackup-cookie"
    $client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
    $client.DownloadFile($source, $destination)

    # Download Tomcat 8
    Write-Output "Downloading Tomcat 8..."
    $source = "http://apache.mirrors.ionfish.org/tomcat/tomcat-8/v8.5.31/bin/apache-tomcat-8.5.31-windows-x64.zip"
    $destination = "C:\Temp\apache-tomcat-8.5.31-windows-x64.zip"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($source, $destination)

    # Install JDK
    Write-Output "Installing JDK 10..."
    $process = Start-Process -FilePath "C:\Temp\jdk-10.0.1_windows-x64_bin.exe" -ArgumentList "/s REBOOT=ReallySuppress" -Wait -PassThru
    $process.WaitForExit()

    # Set environment variables
    Write-Output "Setting environment variables..."
    $jdkPath = "-10.0.1"
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk$jdkPath", "Machine")
    [System.Environment]::SetEnvironmentVariable("PATH", $env:Path + ";C:\Program Files\Java\jdk$jdkPath\bin", "Machine")

    # Extract Tomcat
    Write-Output "Extracting Tomcat..."
    Unzip "C:\Temp\apache-tomcat-8.5.31-windows-x64.zip" "C:\"

    # Generate SSL certificate
    Write-Output "Generating SSL certificate..."
    $sslKeyPassword = Get-RandomPassword -Length 12 -SourceData $alphabet
    Set-Location "C:\Program Files\Java\jdk$jdkPath\bin\"
    & .\keytool.exe -genkey -alias tomcat -keyalg RSA -keystore C:\Temp\server.keystore -keysize 2048 -storepass $sslKeyPassword -keypass $sslKeyPassword -dname "cn=$siteName, ou=shibbolethOU, o=shibbolethO, c=US"

    # Configure Tomcat server.xml
    $serverXmlPath = "C:\apache-tomcat-8.5.31\conf\server.xml"
    $fileData = [IO.File]::ReadAllText($serverXmlPath)
    Rename-Item $serverXmlPath "C:\apache-tomcat-8.5.31\conf\server-old.xml"

    $originalString = 'redirectPort="8443"'
    $replaceString = 'redirectPort="8443" address="0.0.0.0"'
    $fileData = $fileData.Replace($originalString, $replaceString)

    $originalString = "<!-- Define an AJP 1.3 Connector on port 8009 -->"
    $replaceWith = '<Connector port="8443" protocol="org.apache.coyote.http11.Http11Protocol" SSLEnabled="true" maxThreads="150" scheme="https" secure="true" clientAuth="false" sslProtocol="TLS" address="0.0.0.0" keystoreFile="C:\Temp\server.keystore" keystorePass="' + $sslKeyPassword + '"/>'
    $fileData = $fileData.Replace($originalString, $replaceWith)

    [IO.File]::WriteAllText($serverXmlPath, $fileData.TrimEnd())

    # Download JSTL
    Write-Output "Downloading JSTL..."
    $source = "http://central.maven.org/maven2/jstl/jstl/1.2/jstl-1.2.jar"
    $destination = "C:\apache-tomcat-8.5.31\lib\jstl-1.2.jar"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($source, $destination)

    # Download Shibboleth
    Write-Output "Downloading Shibboleth..."
    $source = "https://shibboleth.net/downloads/identity-provider/latest/shibboleth-identity-provider-3.3.2.zip"
    $destination = "C:\Temp\shibboleth-identity-provider-3.3.2.zip"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($source, $destination)

    # Extract Shibboleth
    Write-Output "Extracting Shibboleth..."
    Unzip "C:\Temp\shibboleth-identity-provider-3.3.2.zip" "C:\"

    # Generate Shibboleth configuration
    Write-Output "Generating Shibboleth configuration..."
    $newLine = [System.Environment]::NewLine
    $configContent = @(
        "idp.additionalProperties= /conf/ldap.properties, /conf/saml-nameid.properties, /conf/services.properties, /conf/idp.properties",
        "idp.sealer.storePassword= $sslKeyPassword",
        "idp.sealer.keyPassword= $sslKeyPassword",
        "idp.signing.key= %{idp.home}/credentials/idp-signing.key",
        "idp.signing.cert= %{idp.home}/credentials/idp-signing.crt",
        "idp.encryption.key= %{idp.home}/credentials/idp-encryption.key",
        "idp.encryption.cert= %{idp.home}/credentials/idp-encryption.crt",
        "idp.entityID= https://$siteName/idp/shibboleth",
        "idp.scope= $siteName",
        "idp.consent.StorageService= shibboleth.JPAStorageService",
        "idp.consent.userStorageKey= shibboleth.consent.AttributeConsentStorageKey",
        "idp.consent.userStorageKeyAttribute= %{idp.persistentId.sourceAttribute}",
        "idp.consent.allowGlobal= false",
        "idp.consent.compareValues= true",
        "idp.consent.maxStoredRecords= -1",
        "idp.ui.fallbackLanguages= en,de,fr"
    )

    $configContent -join $newLine | Out-File -FilePath "C:\shibboleth-identity-provider-3.3.2\bin\temp.properties" -Encoding UTF8
    "idp.sealer.password = $sslKeyPassword" | Out-File -FilePath "C:\shibboleth-identity-provider-3.3.2\credentials.properties" -Encoding UTF8

    # Configure and run Shibboleth installer
    Write-Output "Configuring Shibboleth installer..."
    $installBatPath = "C:\shibboleth-identity-provider-3.3.2\bin\install.bat"
    $fileData = [IO.File]::ReadAllText($installBatPath)
    Rename-Item $installBatPath "C:\shibboleth-identity-provider-3.3.2\bin\install-old.bat"

    $originalString = "setlocal"
    $replaceString = "setlocal`r`nset JAVA_HOME=C:\Program Files\Java\jdk-10.0.1"
    $fileData = $fileData.Replace($originalString, $replaceString)

    [IO.File]::WriteAllText($installBatPath, $fileData.TrimEnd())

    Write-Output "Running Shibboleth installer..."
    $installArgs = @(
        "-Didp.src.dir=C:\shibboleth-identity-provider-3.3.2",
        "-Didp.target.dir=C:\opt\shibboleth-idp\",
        "-Didp.merge.properties=C:\shibboleth-identity-provider-3.3.2\bin\temp.properties",
        "-Didp.sealer.password=$sslKeyPassword",
        "-Didp.keystore.password=$sslKeyPassword",
        "-Didp.conf.filemode=644",
        "-Didp.host.name=$siteName",
        "-Didp.scope=$siteName"
    )

    cmd.exe /C "`"$installBatPath`" $($installArgs -join ' ')"

    # Update metadata XML with port configuration
    $metadataPath = "C:\opt\shibboleth-idp\metadata\idp-metadata.xml"
    $content = [IO.File]::ReadAllText($metadataPath)
    Rename-Item $metadataPath "C:\opt\shibboleth-idp\metadata\idp-metadata-old.xml"

    $endpoints = @(
        "https://$siteName/idp/profile/Shibboleth/SSO",
        "https://$siteName/idp/profile/SAML2/POST/SSO",
        "https://$siteName/idp/profile/SAML2/POST-SimpleSign/SSO",
        "https://$siteName/idp/profile/SAML2/Redirect/SSO"
    )

    foreach ($endpoint in $endpoints) {
        $replaceString = $endpoint.Replace("https://$siteName", "https://${siteName}:8443")
        $content = $content.Replace($endpoint, $replaceString)
    }

    [IO.File]::WriteAllText($metadataPath, $content.TrimEnd())

    # Configure Tomcat application
    Write-Output "Configuring Tomcat application..."
    New-Item -Path "C:\apache-tomcat-8.5.31\conf\Catalina\localhost" -ItemType Directory -Force | Out-Null
    $appData = '<Context docBase="C:\opt\shibboleth-idp\war\idp.war" privileged="true" antiresourcelocking="false" antijarlocking="false" unpackwar="false" swallowoutput="true"/>'
    [IO.File]::WriteAllText("C:\apache-tomcat-8.5.31\conf\Catalina\localhost\idp.xml", $appData.TrimEnd())

    # Configure access control
    $accessControlPath = "C:\opt\shibboleth-idp\conf\access-control.xml"
    $content = [IO.File]::ReadAllText($accessControlPath)
    Rename-Item $accessControlPath "C:\opt\shibboleth-idp\conf\access-control-old.xml"

    $originalString = "'::1/128'"
    $replaceString = "'::1/128', '0.0.0.0/0'"
    $content = $content.Replace($originalString, $replaceString)

    [IO.File]::WriteAllText($accessControlPath, $content.TrimEnd())

    # Configure firewall
    Write-Output "Configuring firewall..."
    netsh advfirewall firewall add rule name="Allow TCP 80,8080,8443" dir=in action=allow protocol=TCP localport=80,8080,8443

    # Configure Tomcat startup and shutdown scripts
    $scriptsToUpdate = @("startup.bat", "shutdown.bat")
    foreach ($script in $scriptsToUpdate) {
        $scriptPath = "C:\apache-tomcat-8.5.31\bin\$script"
        $fileData = [IO.File]::ReadAllText($scriptPath)
        Rename-Item $scriptPath "C:\apache-tomcat-8.5.31\bin\$($script.Replace('.bat', '-old.bat'))"

        $originalString = "setlocal"
        $replaceString = "setlocal`r`nset JAVA_HOME=C:\Program Files\Java\jdk-10.0.1"
        $fileData = $fileData.Replace($originalString, $replaceString)

        [IO.File]::WriteAllText($scriptPath, $fileData.TrimEnd())
    }

    # Start Tomcat
    Write-Output "Starting Tomcat..."
    Set-Location "C:\apache-tomcat-8.5.31\bin\"
    Start-Process -FilePath ".\startup.bat" -NoNewWindow

    Write-Output "Shibboleth Identity Provider installation completed successfully"
    Write-Output "Access the IdP at: https://${siteName}:8443/idp/"
}
catch {
    $errorMsg = "Shibboleth installation failed: $($_.Exception.Message)"
    Write-Error $errorMsg
    throw
}