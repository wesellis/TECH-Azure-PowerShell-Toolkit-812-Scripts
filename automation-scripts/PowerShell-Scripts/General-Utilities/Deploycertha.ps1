<#
.SYNOPSIS
    Deploycertha

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
    We Enhanced Deploycertha

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAdminUser,

    [Parameter(Mandatory)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPasswd,    

    [Parameter(Mandatory)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEMainConnectionBroker,

    [Parameter(Mandatory)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEBrokerFqdn,

    [Parameter(Mandatory)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEWebGatewayFqdn,

    [Parameter(Mandatory)]    
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAzureSQLFQDN,

    [Parameter(Mandatory)]    
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAzureSQLDBName,

    [Parameter(Mandatory)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEWebAccessServerName,

    [Parameter(Mandatory)]
    [int]$WEWebAccessServerCount,

    [Parameter(Mandatory)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESessionHostName,

    [Parameter(Mandatory)]
    [int]$WESessionHostCount,

    [Parameter(Mandatory)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELicenseServerName,

    [Parameter(Mandatory)]
    [int]$WELicenseServerCount,

    [bool]$WEEnableDebug = $WEFalse
)

If (-Not (Test-Path " C:\temp" )) {
    New-Item -ItemType Directory -Path " C:\temp" -Force
}

If ($WEEnableDebug) { Start-Transcript -Path " C:\temp\DeployCertHA.log" }

$WEServerObj = Get-CimInstance -Namespace " root\cimv2" -Class " Win32_ComputerSystem"
$WEServerName = $WEServerObj.DNSHostName
$WEDomainName = $WEServerObj.Domain
$WEServerFQDN = $WEServerName + " ." + $WEDomainName
$WECertPasswd = ConvertTo-SecureString -String $WEPasswd -Force -AsPlainText
$WEAzureSQLUserID = $WEAdminUser; 
$WEAzureSQLPasswd = $WEPasswd
[System.Management.Automation.PSCredential]$WEDomainCreds = New-Object System.Management.Automation.PSCredential (" ${DomainName}\$($WEAdminUser)" , $WECertPasswd)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name Posh-ACME -Scope AllUsers -Force
Import-Module Posh-ACME
Import-Module RemoteDesktop
; 
$WEWebGatewayServers = @()
For($WEI=1;$WEI -le $WEWebAccessServerCount;$WEI++){
    $WEWebGatewayServers = $WEWebGatewayServers + $($WEWebAccessServerName + $WEI + " ." + $WEDomainName)
}
; 
$WESessionHosts = @()
For($WEI=1;$WEI -le $WESessionHostCount;$WEI++){
    $WESessionHosts = $WESessionHosts + $($WESessionHostName + $WEI + " ." + $WEDomainName)
}
; 
$WELicenseServers = @()
For($WEI=1;$WEI -le $WELicenseServerCount;$WEI++){
    $WELicenseServers = $WELicenseServers + $($WELicenseServerName + $WEI + " ." + $WEDomainName)
}

Function RequestCert([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEFqdn) {
    $WECertMaxRetries = 30

    Set-PAServer LE_PROD
    New-PAAccount -AcceptTOS -Contact " $($WEAdminUser)@$($WEFqdn)" -Force
    New-PAOrder $WEFqdn
    $auth = Get-PAOrder | Get-PAAuthorizations | Where-Object { $_.HTTP01Status -eq " Pending" }
    $WEAcmeBody = Get-KeyAuthorization $auth.HTTP01Token (Get-PAAccount)

    Invoke-Command -ComputerName $WEWebGatewayServers -Credential $WEDomainCreds -ScriptBlock {
        Param($auth, $WEAcmeBody, $WEBrokerName, $WEDomainName)
        $WEAcmePath = " C:\Inetpub\wwwroot\.well-known\acme-challenge"
        New-Item -ItemType Directory -Path $WEAcmePath -Force
        New-Item -Path $WEAcmePath -Name $auth.HTTP01Token -ItemType File -Value $WEAcmeBody
        If (-Not (Get-LocalGroupMember -Group " Administrators" | Where-Object {$_.Name -match " $($WEBrokerName)" } -ErrorAction SilentlyContinue)) {
            Add-LocalGroupMember -Group " Administrators" -Member " $($WEDomainName)\$($WEBrokerName)$"
        }
    } -ArgumentList $auth, $WEAcmeBody, $WEServerName, $WEDomainName

    $auth.HTTP01Url | Send-ChallengeAck

    $WERetries = 1
    Do {
        Write-WELog " Waiting for validation. Sleeping 30 seconds..." " INFO"
        Start-Sleep -Seconds 30
        $WERetries++
    } While (((Get-PAOrder | Get-PAAuthorizations).HTTP01Status -ne " valid" ) -And ($WERetries -ne $WECertMaxRetries))

    If ((Get-PAOrder | Get-PAAuthorizations).HTTP01Status -ne " valid" ){
        Write-Error " Certificate for $($WEFqdn) not ready in 15 minutes. Exiting..."
        [Environment]::Exit(-1)
    }

    New-PACertificate $WEFqdn -Install
    $WEThumbprint = (Get-PACertificate $WEFqdn).Thumbprint
    
    $WECertFullPath = (Join-path " C:\temp" $($WEFqdn + " .pfx" ))
    Export-PfxCertificate -Cert Cert:\LocalMachine\My\$WEThumbprint -FilePath $WECertFullPath -Password $WECertPasswd -Force
}

Function InstallSQLClient() {
    $WEVCRedist = " C:\Temp\vc_redist.x64.exe"
    $WEODBCmsi = " C:\Temp\msodbcsql.msi"
    
    If (-Not (Test-Path -Path $WEVCRedist)) {
        Invoke-WebRequest -Uri " https://aka.ms/vs/15/release/vc_redist.x64.exe" -OutFile $WEVCRedist
    }
    
    If (-Not (Test-Path -Path $WEODBCmsi)) {
        Invoke-WebRequest -Uri " https://go.microsoft.com/fwlink/?linkid=2120137" -OutFile $WEODBCmsi
    }
    
    If (Test-Path -Path $WEVCRedist) {
        Unblock-File -Path $WEVCRedist
    
        $params = @()
        $params = $params + '/install'
        $params = $params + '/quiet'
        $params = $params + '/norestart'
        $params = $params + '/log'
        $params = $params + 'C:\Temp\vcredistinstall.log'
            
        Try {
            $WEProcessInfo = New-Object System.Diagnostics.ProcessStartInfo 
            $WEProcessInfo.FileName = $WEVCRedist
            $WEProcessInfo.RedirectStandardError = $true
            $WEProcessInfo.RedirectStandardOutput = $true
            $WEProcessInfo.UseShellExecute = $false
            $WEProcessInfo.Arguments = $params
            $WEProcess = New-Object System.Diagnostics.Process
            $WEProcess.StartInfo = $WEProcessInfo
            $WEProcess.Start() | Out-Null
            $WEProcess.WaitForExit()
            $WEReturnMSG = $WEProcess.StandardOutput.ReadToEnd()
            $WEReturnMSG
        }
        Catch { }
    }
    
    If (Test-Path -Path $WEODBCmsi) {
        Unblock-File -Path $WEODBCmsi
    
        $params = @()
        $params = $params + '/i'
        $params = $params + $WEODBCmsi
        $params = $params + '/norestart'
        $params = $params + '/quiet'
        $params = $params + '/log'
        $params = $params + 'C:\Temp\obdcdriverinstall.log'
        $params = $params + 'IACCEPTMSODBCSQLLICENSETERMS=YES'
            
        Try {
            $WEProcessInfo = New-Object System.Diagnostics.ProcessStartInfo 
            $WEProcessInfo.FileName = " $($WEEnv:SystemRoot)\System32\msiexec.exe"
            $WEProcessInfo.RedirectStandardError = $true
            $WEProcessInfo.RedirectStandardOutput = $true
            $WEProcessInfo.UseShellExecute = $false
            $WEProcessInfo.Arguments = $params
            $WEProcess = New-Object System.Diagnostics.Process
            $WEProcess.StartInfo = $WEProcessInfo
            $WEProcess.Start() | Out-Null
            $WEProcess.WaitForExit()
            $WEReturnMSG = $WEProcess.StandardOutput.ReadToEnd()
            $WEReturnMSG
        }
        Catch { }
    }
}

If ($WEServerName -eq $WEMainConnectionBroker) {
    #Add remaining servers
    ForEach($WENewServer In $WEWebGatewayServers) {
        Invoke-Command -ComputerName $WENewServer -Credential $WEDomainCreds -ScriptBlock {
            Param($WEDomainName,$WEBrokerName)
            If (-Not (Get-LocalGroupMember -Group " Administrators" | Where-Object {$_.Name -match " $($WEBrokerName)" } -ErrorAction SilentlyContinue)) {
                Add-LocalGroupMember -Group " Administrators" -Member " $($WEDomainName)\$($WEBrokerName)$" -ErrorAction SilentlyContinue
            }
        } -ArgumentList $WEDomainName, $WEServerName

        If (-Not (Get-RDServer -Role " RDS-WEB-ACCESS" -ConnectionBroker $WEServerFQDN | Where-Object {$_.Server -match $WENewServer})) {
            Add-RDServer -Role " RDS-WEB-ACCESS" -ConnectionBroker $WEServerFQDN -Server $WENewServer
        }
    }

    ForEach($WENewServer In $WEWebGatewayServers) {
        Invoke-Command -ComputerName $WENewServer -Credential $WEDomainCreds -ScriptBlock {
            Param($WEDomainName,$WEBrokerName)
            If (-Not (Get-LocalGroupMember -Group " Administrators" | Where-Object {$_.Name -match " $($WEBrokerName)" } -ErrorAction SilentlyContinue)) {
                Add-LocalGroupMember -Group " Administrators" -Member " $($WEDomainName)\$($WEBrokerName)$" -ErrorAction SilentlyContinue
            }
        } -ArgumentList $WEDomainName, $WEServerName

        If (-Not (Get-RDServer -Role " RDS-GATEWAY" -ConnectionBroker $WEServerFQDN | Where-Object {$_.Server -match $WENewServer})) {
            Add-RDServer -Role " RDS-GATEWAY" -ConnectionBroker $WEServerFQDN -Server $WENewServer -GatewayExternalFqdn $WEWebGatewayFqdn
        }
    }

    ForEach($WENewServer In $WESessionHosts) {
        Invoke-Command -ComputerName $WENewServer -Credential $WEDomainCreds -ScriptBlock {
            Param($WEDomainName,$WEBrokerName)
            If (-Not (Get-LocalGroupMember -Group " Administrators" | Where-Object {$_.Name -match " $($WEBrokerName)" } -ErrorAction SilentlyContinue)) {
                Add-LocalGroupMember -Group " Administrators" -Member " $($WEDomainName)\$($WEBrokerName)$" -ErrorAction SilentlyContinue
            }
        } -ArgumentList $WEDomainName, $WEServerName

        If (-Not (Get-RDServer -Role " RDS-RD-SERVER" -ConnectionBroker $WEServerFQDN | Where-Object {$_.Server -match $WENewServer})) {
            Add-RDServer -Role " RDS-RD-SERVER" -ConnectionBroker $WEServerFQDN -Server $WENewServer
        }
    }
    
    ForEach($WENewServer In $WELicenseServers) {
        Invoke-Command -ComputerName $WENewServer -Credential $WEDomainCreds -ScriptBlock {
            Param($WEDomainName,$WEBrokerName)
            If (-Not (Get-LocalGroupMember -Group " Administrators" | Where-Object {$_.Name -match " $($WEBrokerName)" } -ErrorAction SilentlyContinue)) {
                Add-LocalGroupMember -Group " Administrators" -Member " $($WEDomainName)\$($WEBrokerName)$" -ErrorAction SilentlyContinue
            }
        } -ArgumentList $WEDomainName, $WEServerName

        If (-Not (Get-RDServer -Role " RDS-LICENSING" -ConnectionBroker $WEServerFQDN | Where-Object {$_.Server -match $WENewServer})) {
            Add-RDServer -Role " RDS-LICENSING" -ConnectionBroker $WEServerFQDN -Server $WENewServer
        }
    }
    #End of add remaining servers

    #Request Certs for web access, gateway, broker and publishing    
    $WECertWebGatewayPath = (Join-path " C:\temp" $($WEWebGatewayFqdn + " .pfx" ))
   ;  $WECertBrokerPath = (Join-path " C:\temp" $($WEBrokerFqdn + " .pfx" ))

    If (-Not (Get-RDCertificate -Role RDGateway).IssuedTo) {
        RequestCert $WEWebGatewayFqdn
        RequestCert $WEBrokerFqdn
        Set-RDCertificate -Role RDWebAccess -ImportPath $WECertWebGatewayPath -Password $WECertPasswd -ConnectionBroker $WEServerFQDN -Force
        Set-RDCertificate -Role RDGateway -ImportPath $WECertWebGatewayPath -Password $WECertPasswd -ConnectionBroker $WEServerFQDN -Force
        Set-RDCertificate -Role RDRedirector -ImportPath $WECertBrokerPath -Password $WECertPasswd -ConnectionBroker $WEServerFQDN -Force
        Set-RDCertificate -Role RDPublishing -ImportPath $WECertBrokerPath -Password $WECertPasswd -ConnectionBroker $WEServerFQDN -Force
    }
    #End of cert request

    #Redirects to HTTPS
   ;  $WERedirectPage = " https://$($WEWebGatewayFqdn)/RDWeb"

    Invoke-Command -ComputerName $WEWebGatewayServers -Credential $WEDomainCreds -ScriptBlock {
        Param($WERedirectPage)
        Import-Module WebAdministration
        Set-WebConfiguration System.WebServer/HttpRedirect " IIS:\sites\Default Web Site" -Value @{Enabled=" True" ;Destination=" $WERedirectPage" ;ExactDestination=" True" ;HttpResponseStatus=" Found" }
    } -ArgumentList $WERedirectPage
    #End of https redirect

    #Configure broker in HA
    InstallSQLClient
    If ($?) {
        $WEDBConnectionString = " Driver={ODBC Driver 17 for SQL Server};Server=tcp:$($WEAzureSQLFQDN),1433;Database=$($WEAzureSQLDBName);Uid=$($WEAzureSQLUserID);Pwd=$($WEAzureSQLPasswd);Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    
        If (-Not (Get-RDConnectionBrokerHighAvailability).ActiveManagementServer) {
            Set-RDConnectionBrokerHighAvailability -ConnectionBroker $WEConnectionBroker `
                -DatabaseConnectionString $WEDBConnectionString `
                -ClientAccessName $WEBrokerFQDN
        }
    }
    #End of configure broker in HA
}
Else {
    #If not the first broker, just install SQL OBDC driver and join the farm
    InstallSQLClient
    If ($?) {
        $WEWaitHAMaxRetries = 60
        $WEMainBrokerFQDN = $($WEMainConnectionBroker + " ." + $WEDomainName)

        #As we're executing via SYSTEM, make sure the broker is able to manage servers
        Invoke-Command -ComputerName $WEMainConnectionBroker -Credential $WEDomainCreds -ScriptBlock {
            Param($WEDomainName,$WEBrokerName)
            If (-Not (Get-LocalGroupMember -Group " Administrators" | Where-Object {$_.Name -match " $($WEBrokerName)" } -ErrorAction SilentlyContinue)) {
                Add-LocalGroupMember -Group " Administrators" -Member " $($WEDomainName)\$($WEBrokerName)$"
            }
        } -ArgumentList $WEDomainName, $WEServerName

        #First broker HA deployment might be still running in parallel, wait for HA.
        $WERetries = 1
        Do {
            Write-WELog " Waiting 30 seconds for RDS Deployment..." " INFO"
            Start-Sleep -Seconds 30
            $WERetries++
        } While(-Not (Get-RDConnectionBrokerHighAvailability -ConnectionBroker $WEMainBrokerFQDN) -And ($WERetries -ne $WEWaitHAMaxRetries))

        If (-Not (Get-RDConnectionBrokerHighAvailability -ConnectionBroker $WEMainBrokerFQDN)) {
            Write-Error " RDS Deployment not ready in 30 minutes. Exiting..."
            [Environment]::Exit(-1)            
        }

        Get-RDServer -ConnectionBroker $WEMainBrokerFQDN | ForEach-Object {
            Invoke-Command -ComputerName $_.Server -Credential $WEDomainCreds -ScriptBlock {
                Param($WEDomainName,$WEBrokerName)
                If (-Not (Get-LocalGroupMember -Group " Administrators" | Where-Object {$_.Name -match " $($WEBrokerName)" } -ErrorAction SilentlyContinue)) {
                    Add-LocalGroupMember -Group " Administrators" -Member " $($WEDomainName)\$($WEBrokerName)$" -ErrorAction SilentlyContinue
                }
            } -ArgumentList $WEDomainName, $WEServerName
        }

        #RDS HA Deployment is available, adding to RDS Broker farm.
        Add-RDServer -Role " RDS-CONNECTION-BROKER" -ConnectionBroker $WEMainBrokerFQDN -Server $WEServerFQDN
        
        #Since we've added another broker, we have to import the cert again
       ;  $WECertRemotePath = (Join-path " \\$WEMainConnectionBroker\C$\temp" " *.pfx" )
       ;  $WECertBrokerPath = (Join-path " C:\temp" $($WEBrokerFqdn + " .pfx" ))

        #Copy the certs locally from first broker
        Copy-Item -Path $WECertRemotePath -Destination " C:\Temp"

        Set-RDCertificate -Role RDRedirector -ImportPath $WECertBrokerPath -Password $WECertPasswd -ConnectionBroker $WEMainBrokerFQDN -Force
        Set-RDCertificate -Role RDPublishing -ImportPath $WECertBrokerPath -Password $WECertPasswd -ConnectionBroker $WEMainBrokerFQDN -Force        
    }
}

If ($WEEnableDebug) { Stop-Transcript }



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
