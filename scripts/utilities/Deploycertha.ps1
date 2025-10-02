#Requires -Version 7.4
#Requires -Modules RemoteDesktop

<#
.SYNOPSIS
    Deploy Certificate High Availability

.DESCRIPTION
    Azure automation script for deploying certificate high availability in RDS environments
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER AdminUser
    Administrative user account

.PARAMETER Passwd
    Password for the administrative user

.PARAMETER MainConnectionBroker
    Main connection broker server name

.PARAMETER BrokerFqdn
    Fully qualified domain name for the broker

.PARAMETER WebGatewayFqdn
    Fully qualified domain name for the web gateway

.PARAMETER AzureSQLFQDN
    Azure SQL server FQDN

.PARAMETER AzureSQLDBName
    Azure SQL database name

.PARAMETER WebAccessServerName
    Web access server name prefix

.PARAMETER WebAccessServerCount
    Number of web access servers

.PARAMETER SessionHostName
    Session host name prefix

.PARAMETER SessionHostCount
    Number of session hosts

.PARAMETER LicenseServerName
    License server name prefix

.PARAMETER LicenseServerCount
    Number of license servers

.PARAMETER EnableDebug
    Enable debug logging

.EXAMPLE
    .\Deploycertha.ps1 -AdminUser "admin" -Passwd "password" -MainConnectionBroker "broker01" -BrokerFqdn "broker.domain.com" -WebGatewayFqdn "gateway.domain.com" -AzureSQLFQDN "sqlserver.database.windows.net" -AzureSQLDBName "rdsdb" -WebAccessServerName "web" -WebAccessServerCount 2 -SessionHostName "sh" -SessionHostCount 2 -LicenseServerName "ls" -LicenseServerCount 1

.NOTES
    Deploys RDS certificate high availability configuration
    Integrates with Azure SQL Database for HA
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUser,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Passwd,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$MainConnectionBroker,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$BrokerFqdn,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$WebGatewayFqdn,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$AzureSQLFQDN,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$AzureSQLDBName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$WebAccessServerName,

    [Parameter(Mandatory)]
    [int]$WebAccessServerCount,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SessionHostName,

    [Parameter(Mandatory)]
    [int]$SessionHostCount,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$LicenseServerName,

    [Parameter(Mandatory)]
    [int]$LicenseServerCount,

    [bool]$EnableDebug = $false
)

$ErrorActionPreference = "Stop"

try {
    if (-Not (Test-Path "C:\temp")) {
        New-Item -ItemType Directory -Path "C:\temp" -Force
    }

    if ($EnableDebug) {
        Start-Transcript -Path "C:\temp\DeployCertHA.log"
    }

    $ServerObj = Get-CimInstance -Namespace "root\cimv2" -Class "Win32_ComputerSystem"
    $ServerName = $ServerObj.DNSHostName
    $DomainName = $ServerObj.Domain
    $ServerFQDN = $ServerName + "." + $DomainName
    $CertPasswd = Read-Host -AsSecureString -Prompt "Enter secure value"
    $AzureSQLUserID = $AdminUser
    $AzureSQLPasswd = $Passwd

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ("${DomainName}\$($AdminUser)", $CertPasswd)

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name Posh-ACME -Scope AllUsers -Force
    Import-Module Posh-ACME
    Import-Module RemoteDesktop

    $WebGatewayServers = @()
    for ($I = 1; $I -le $WebAccessServerCount; $I++) {
        $WebGatewayServers = $WebGatewayServers + $($WebAccessServerName + $I + "." + $DomainName)
    }

    $SessionHosts = @()
    for ($I = 1; $I -le $SessionHostCount; $I++) {
        $SessionHosts = $SessionHosts + $($SessionHostName + $I + "." + $DomainName)
    }

    $LicenseServers = @()
    for ($I = 1; $I -le $LicenseServerCount; $I++) {
        $LicenseServers = $LicenseServers + $($LicenseServerName + $I + "." + $DomainName)
    }

    function Request-Certificate {
        param(
            [Parameter()]
            [ValidateNotNullOrEmpty()]
            [string]$Fqdn
        )

        $CertMaxRetries = 30
        Set-PAServer -ErrorAction Stop LE_PROD
        New-PAAccount -AcceptTOS -Contact "$($AdminUser)@$($Fqdn)" -Force
        New-PAOrder -ErrorAction Stop $Fqdn
        $auth = Get-PAOrder -ErrorAction Stop | Get-PAAuthorizations -ErrorAction Stop | Where-Object { $_.HTTP01Status -eq "Pending" }
        $AcmeBody = Get-KeyAuthorization -ErrorAction Stop $auth.HTTP01Token (Get-PAAccount)

        Invoke-Command -ComputerName $WebGatewayServers -Credential $DomainCreds -ScriptBlock {
            Param($auth, $AcmeBody, $BrokerName, $DomainName)
            $AcmePath = "C:\Inetpub\wwwroot\.well-known\acme-challenge"
            New-Item -ItemType Directory -Path $AcmePath -Force
            New-Item -Path $AcmePath -Name $auth.HTTP01Token -ItemType File -Value $AcmeBody
            if (-Not (Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.Name -match "$($BrokerName)"} -ErrorAction SilentlyContinue)) {
                Add-LocalGroupMember -Group "Administrators" -Member "$($DomainName)\$($BrokerName)$"
            }
        } -ArgumentList $auth, $AcmeBody, $ServerName, $DomainName

        $auth.HTTP01Url | Send-ChallengeAck
        $Retries = 1
        do {
            Write-Output "Waiting for validation. Sleeping 30 seconds..."
            Start-Sleep -Seconds 30
            $Retries++
        } while (((Get-PAOrder -ErrorAction Stop | Get-PAAuthorizations).HTTP01Status -ne "valid") -And ($Retries -ne $CertMaxRetries))

        if ((Get-PAOrder -ErrorAction Stop | Get-PAAuthorizations).HTTP01Status -ne "valid") {
            Write-Error "Certificate for $($Fqdn) not ready in 15 minutes. Exiting..."
            [Environment]::Exit(-1)
        }

        New-PACertificate -ErrorAction Stop $Fqdn -Install
        $Thumbprint = (Get-PACertificate -ErrorAction Stop $Fqdn).Thumbprint
        $CertFullPath = (Join-path "C:\temp" $($Fqdn + ".pfx"))
        Export-PfxCertificate -Cert Cert:\LocalMachine\My\$Thumbprint -FilePath $CertFullPath -Password $CertPasswd -Force
    }

    function Install-SQLClient {
        $VCRedist = "C:\Temp\vc_redist.x64.exe"
        $ODBCmsi = "C:\Temp\msodbcsql.msi"

        if (-Not (Test-Path -Path $VCRedist)) {
            Invoke-WebRequest -Uri "https://aka.ms/vs/15/release/vc_redist.x64.exe" -OutFile $VCRedist
        }
        if (-Not (Test-Path -Path $ODBCmsi)) {
            Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2120137" -OutFile $ODBCmsi
        }

        if (Test-Path -Path $VCRedist) {
            Unblock-File -Path $VCRedist
            $params = @('/install', '/quiet', '/norestart', '/log', 'C:\Temp\vcredistinstall.log')
            try {
                $ProcessInfo = New-Object -ErrorAction Stop System.Diagnostics.ProcessStartInfo
                $ProcessInfo.FileName = $VCRedist
                $ProcessInfo.RedirectStandardError = $true
                $ProcessInfo.RedirectStandardOutput = $true
                $ProcessInfo.UseShellExecute = $false
                $ProcessInfo.Arguments = $params
                $Process = New-Object -ErrorAction Stop System.Diagnostics.Process
                $Process.StartInfo = $ProcessInfo
                $Process.Start() | Out-Null
                $Process.WaitForExit()
                $ReturnMSG = $Process.StandardOutput.ReadToEnd()
                $ReturnMSG
            }
            catch {
                Write-Error "An error occurred: $($_.Exception.Message)"
                throw
            }
        }

        if (Test-Path -Path $ODBCmsi) {
            Unblock-File -Path $ODBCmsi
            $params = @('/i', $ODBCmsi, '/norestart', '/quiet', '/log', 'C:\Temp\obdcdriverinstall.log', 'IACCEPTMSODBCSQLLICENSETERMS=YES')
            try {
                $ProcessInfo = New-Object -ErrorAction Stop System.Diagnostics.ProcessStartInfo
                $ProcessInfo.FileName = "$($Env:SystemRoot)\System32\msiexec.exe"
                $ProcessInfo.RedirectStandardError = $true
                $ProcessInfo.RedirectStandardOutput = $true
                $ProcessInfo.UseShellExecute = $false
                $ProcessInfo.Arguments = $params
                $Process = New-Object -ErrorAction Stop System.Diagnostics.Process
                $Process.StartInfo = $ProcessInfo
                $Process.Start() | Out-Null
                $Process.WaitForExit()
                $ReturnMSG = $Process.StandardOutput.ReadToEnd()
                $ReturnMSG
            }
            catch {
                Write-Error "An error occurred: $($_.Exception.Message)"
                throw
            }
        }
    }

    if ($ServerName -eq $MainConnectionBroker) {
        foreach ($NewServer in $WebGatewayServers) {
            Invoke-Command -ComputerName $NewServer -Credential $DomainCreds -ScriptBlock {
                Param($DomainName, $BrokerName)
                if (-Not (Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.Name -match "$($BrokerName)"} -ErrorAction SilentlyContinue)) {
                    Add-LocalGroupMember -Group "Administrators" -Member "$($DomainName)\$($BrokerName)$" -ErrorAction SilentlyContinue
                }
            } -ArgumentList $DomainName, $ServerName

            if (-Not (Get-RDServer -Role "RDS-WEB-ACCESS" -ConnectionBroker $ServerFQDN | Where-Object {$_.Server -match $NewServer})) {
                Add-RDServer -Role "RDS-WEB-ACCESS" -ConnectionBroker $ServerFQDN -Server $NewServer
            }
        }

        foreach ($NewServer in $WebGatewayServers) {
            Invoke-Command -ComputerName $NewServer -Credential $DomainCreds -ScriptBlock {
                Param($DomainName, $BrokerName)
                if (-Not (Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.Name -match "$($BrokerName)"} -ErrorAction SilentlyContinue)) {
                    Add-LocalGroupMember -Group "Administrators" -Member "$($DomainName)\$($BrokerName)$" -ErrorAction SilentlyContinue
                }
            } -ArgumentList $DomainName, $ServerName

            if (-Not (Get-RDServer -Role "RDS-GATEWAY" -ConnectionBroker $ServerFQDN | Where-Object {$_.Server -match $NewServer})) {
                Add-RDServer -Role "RDS-GATEWAY" -ConnectionBroker $ServerFQDN -Server $NewServer -GatewayExternalFqdn $WebGatewayFqdn
            }
        }

        foreach ($NewServer in $SessionHosts) {
            Invoke-Command -ComputerName $NewServer -Credential $DomainCreds -ScriptBlock {
                Param($DomainName, $BrokerName)
                if (-Not (Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.Name -match "$($BrokerName)"} -ErrorAction SilentlyContinue)) {
                    Add-LocalGroupMember -Group "Administrators" -Member "$($DomainName)\$($BrokerName)$" -ErrorAction SilentlyContinue
                }
            } -ArgumentList $DomainName, $ServerName

            if (-Not (Get-RDServer -Role "RDS-RD-SERVER" -ConnectionBroker $ServerFQDN | Where-Object {$_.Server -match $NewServer})) {
                Add-RDServer -Role "RDS-RD-SERVER" -ConnectionBroker $ServerFQDN -Server $NewServer
            }
        }

        foreach ($NewServer in $LicenseServers) {
            Invoke-Command -ComputerName $NewServer -Credential $DomainCreds -ScriptBlock {
                Param($DomainName, $BrokerName)
                if (-Not (Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.Name -match "$($BrokerName)"} -ErrorAction SilentlyContinue)) {
                    Add-LocalGroupMember -Group "Administrators" -Member "$($DomainName)\$($BrokerName)$" -ErrorAction SilentlyContinue
                }
            } -ArgumentList $DomainName, $ServerName

            if (-Not (Get-RDServer -Role "RDS-LICENSING" -ConnectionBroker $ServerFQDN | Where-Object {$_.Server -match $NewServer})) {
                Add-RDServer -Role "RDS-LICENSING" -ConnectionBroker $ServerFQDN -Server $NewServer
            }
        }

        $CertWebGatewayPath = (Join-path "C:\temp" $($WebGatewayFqdn + ".pfx"))
        $CertBrokerPath = (Join-path "C:\temp" $($BrokerFqdn + ".pfx"))

        if (-Not (Get-RDCertificate -Role RDGateway).IssuedTo) {
            Request-Certificate $WebGatewayFqdn
            Request-Certificate $BrokerFqdn
            Set-RDCertificate -Role RDWebAccess -ImportPath $CertWebGatewayPath -Password $CertPasswd -ConnectionBroker $ServerFQDN -Force
            Set-RDCertificate -Role RDGateway -ImportPath $CertWebGatewayPath -Password $CertPasswd -ConnectionBroker $ServerFQDN -Force
            Set-RDCertificate -Role RDRedirector -ImportPath $CertBrokerPath -Password $CertPasswd -ConnectionBroker $ServerFQDN -Force
            Set-RDCertificate -Role RDPublishing -ImportPath $CertBrokerPath -Password $CertPasswd -ConnectionBroker $ServerFQDN -Force
        }

        $RedirectPage = "https://$($WebGatewayFqdn)/RDWeb"
        Invoke-Command -ComputerName $WebGatewayServers -Credential $DomainCreds -ScriptBlock {
            Param($RedirectPage)
            Import-Module WebAdministration
            Set-WebConfiguration -ErrorAction Stop System.WebServer/HttpRedirect "IIS:\sites\Default Web Site" -Value @{Enabled="True"; Destination="$RedirectPage"; ExactDestination="True"; HttpResponseStatus="Found"}
        } -ArgumentList $RedirectPage

        Install-SQLClient

        if ($?) {
            $DBConnectionString = "Driver={ODBC Driver 17 for SQL Server};Server=tcp:$($AzureSQLFQDN),1433;Database=$($AzureSQLDBName);Uid=$($AzureSQLUserID);Pwd=$($AzureSQLPasswd);Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
            if (-Not (Get-RDConnectionBrokerHighAvailability).ActiveManagementServer) {
                $params = @{
                    DatabaseConnectionString = $DBConnectionString
                    ClientAccessName = $BrokerFQDN
                    ConnectionBroker = $ServerFQDN
                }
                Set-RDConnectionBrokerHighAvailability @params
            }
        }
    }
    else {
        Install-SQLClient

        if ($?) {
            $WaitHAMaxRetries = 60
            $MainBrokerFQDN = $($MainConnectionBroker + "." + $DomainName)

            Invoke-Command -ComputerName $MainConnectionBroker -Credential $DomainCreds -ScriptBlock {
                Param($DomainName, $BrokerName)
                if (-Not (Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.Name -match "$($BrokerName)"} -ErrorAction SilentlyContinue)) {
                    Add-LocalGroupMember -Group "Administrators" -Member "$($DomainName)\$($BrokerName)$"
                }
            } -ArgumentList $DomainName, $ServerName

            $Retries = 1
            do {
                Write-Output "Waiting 30 seconds for RDS Deployment..."
                Start-Sleep -Seconds 30
                $Retries++
            } while (-Not (Get-RDConnectionBrokerHighAvailability -ConnectionBroker $MainBrokerFQDN) -And ($Retries -ne $WaitHAMaxRetries))

            if (-Not (Get-RDConnectionBrokerHighAvailability -ConnectionBroker $MainBrokerFQDN)) {
                Write-Error "RDS Deployment not ready in 30 minutes. Exiting..."
                [Environment]::Exit(-1)
            }

            Get-RDServer -ConnectionBroker $MainBrokerFQDN | ForEach-Object {
                Invoke-Command -ComputerName $_.Server -Credential $DomainCreds -ScriptBlock {
                    Param($DomainName, $BrokerName)
                    if (-Not (Get-LocalGroupMember -Group "Administrators" | Where-Object {$_.Name -match "$($BrokerName)"} -ErrorAction SilentlyContinue)) {
                        Add-LocalGroupMember -Group "Administrators" -Member "$($DomainName)\$($BrokerName)$" -ErrorAction SilentlyContinue
                    }
                } -ArgumentList $DomainName, $ServerName
            }

            Add-RDServer -Role "RDS-CONNECTION-BROKER" -ConnectionBroker $MainBrokerFQDN -Server $ServerFQDN
            $CertRemotePath = (Join-path "\\$MainConnectionBroker\C$\temp" "*.pfx")
            $CertBrokerPath = (Join-path "C:\temp" $($BrokerFqdn + ".pfx"))
            Copy-Item -Path $CertRemotePath -Destination "C:\Temp"
            Set-RDCertificate -Role RDRedirector -ImportPath $CertBrokerPath -Password $CertPasswd -ConnectionBroker $MainBrokerFQDN -Force
            Set-RDCertificate -Role RDPublishing -ImportPath $CertBrokerPath -Password $CertPasswd -ConnectionBroker $MainBrokerFQDN -Force
        }
    }

    if ($EnableDebug) {
        Stop-Transcript
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}