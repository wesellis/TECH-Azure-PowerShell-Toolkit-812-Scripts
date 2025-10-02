#Requires -Version 7.4

<#`n.SYNOPSIS
    Webandgwfarmadd Postconfig1.1
.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
     [String]$WebGwServer,
     [String]$BrokerServer,
     [String]$WebURL,
     [String]$Domainname,
     [String]$DomainNetbios,
     [String]$username,
     [String]$password,
     $ServerName = " gateway" ,
     [int]$NumberofwebServers,
    $ValidationKey64,
    $DecryptionKey24
    )
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
    $username = $DomainNetbios + " \" + $Username
    $cred = New-Object -ErrorAction Stop System.Management.Automation.PSCredential -ArgumentList @($username,(Read-Host -Prompt "Enter secure value" -AsSecureString))
configuration RDWebAccessdeployment
{
    param(
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [PSCredential]$AdminCreds,
        [String]$ConnectionBroker,
        [String]$WebAccessServer,
        [String]$ExternalFqdn
      )
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xRemoteDesktopSessionHost
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
    if (-not $ConnectionBroker)   { $ConnectionBroker = $localhost }
    if (-not $WebAccessServer)    { $WebAccessServer  = $localhost }
    if (-not $CollectionName)         { $CollectionName = "Desktop Collection" }
    if (-not $CollectionDescription)  { $CollectionDescription = "A sample RD Session collection up in cloud." }
    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }
        xRDServer AddWebAccessServer
        {
            Role    = 'RDS-Web-Access'
            Server  = $WebAccessServer
            GatewayExternalFqdn = $ExternalFqdn
            ConnectionBroker = $BrokerServer
            PsDscRunAsCredential = $AdminCreds
        }
    }
}
    $ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
}
RDWebAccessdeployment -adminCreds $cred -connectionBroker $BrokerServer -webAccessServer $localhost -externalFqdn $WebURL -domainName $Domainname -ConfigurationData $ConfigData -Verbose
Start-DscConfiguration -Wait -Force -Path .\RDWebAccessdeployment -Verbose
configuration RDGatewaydeployment
{
    param(
        [Parameter(Mandatory)]
        [String]$DomainName,
        [Parameter(Mandatory)]
        [PSCredential]$AdminCreds,
        [String]$ConnectionBroker,
        [String]$WebAccessServer,
        [String]$ExternalFqdn,
        [Int]$NumberOfRdshInstances = 1,
        [String]$SessionHostNamingPrefix = "SessionHost-" ,
        [String]$CollectionName,
        [String]$CollectionDescription
      )
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xRemoteDesktopSessionHost
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
    if (-not $ConnectionBroker)   { $ConnectionBroker = $localhost }
    if (-not $WebAccessServer)    { $WebAccessServer  = $localhost }
    if (-not $CollectionName)         { $CollectionName = "Desktop Collection" }
    if (-not $CollectionDescription)  { $CollectionDescription = "A sample RD Session collection up in cloud." }
    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }
        xRDServer AddGatewayServer
        {
            Role    = 'RDS-Gateway'
            Server  = $WebAccessServer
            GatewayExternalFqdn = $ExternalFqdn
            ConnectionBroker = $BrokerServer
            PsDscRunAsCredential = $AdminCreds
        }
    }
}
    $ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
}
RDGatewaydeployment -adminCreds $cred -connectionBroker $BrokerServer -webAccessServer $localhost -externalFqdn $WebURL -domainName $Domainname -ConfigurationData $ConfigData -Verbose
Start-DscConfiguration -Wait -Force -Path .\RDGatewaydeployment -Verbose
Write-Output "Username : $($username),   Password: $($password)"
    $WebServernameArray = New-Object -ErrorAction Stop System.Collections.ArrayList
for ($i = 0; $i -le $NumberofwebServers; $i++)
{
    if ($i -eq 0)
    {
    $WebServername = "Gateway"
    }
    else{
    $servercount = $i - 1
    $WebServername = " gateway" + $servercount.ToString()
        }
    $WebServernameArray.Add($WebServername) | Out-Null
}
Write-Output " web server Array value $($WebServernameArray)"
[int]$keylen = 64
    $buff = new-object -ErrorAction Stop "System.Byte[]" $keylen
    $rnd = new-object -ErrorAction Stop System.Security.Cryptography.RNGCryptoServiceProvider
    $rnd.GetBytes($buff)
    $result =""
       for($i=0; $i -lt $keylen; $i++)  {
    $result = $result + [System.String]::Format(" {0:X2}" ,$buff[$i])
       }
    $validationkey64 = $result
    $keylen = 24
    $buff1 = new-object -ErrorAction Stop "System.Byte[]" $keylen
    $rnd1 = new-object -ErrorAction Stop System.Security.Cryptography.RNGCryptoServiceProvider
    $rnd1.GetBytes($buff1)
    $result =""
       for($i=0; $i -lt $keylen; $i++)  {
    $result = $result + [System.String]::Format(" {0:X2}" ,$buff[$i])
       }
    $DecryptionKey24 = $result
foreach ($item in $WebServernameArray)
{
    $WebServer = $item + " ." + $DomainName
    Write-Output "Starting working on webserver name : $($WebServer)"
    try{
    $session = New-PSSession -ComputerName $WebServer -Credential $cred
    }
    catch{
    Write-Output $Error
    }
Invoke-Command -session $session -ScriptBlock {param($validationkey64,$DecryptionKey24)
function ValidateWindowsFeature
{`n    param(`n        $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
    $RdsWindowsFeature = Get-WindowsFeature -ComputerName $localhost -Name RDS-Web-Access
    if ($RdsWindowsFeature.InstallState -eq "Installed" )
    {
        Return $true
    }
    else
    {
        Return $false
    }
}
    $Validationheck = $False
    $Validationheck = ValidateWindowsFeature
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
if($Validationheck -eq $true)
{
    Write-Output "Windows feature RDS-Web_access present on $($localhost)"
    $MachineConfig = "C:\Windows\Web\RDWeb\Web.config"
       if (Test-Path $MachineConfig)
       {
        Write-Output " editing machine config file : $($MachineConfig) on server $($localhost) "
        try{
    $xml = [xml](get-content -ErrorAction Stop $MachineConfig)
    $xml.Save($MachineConfig + " _" )
    $root = $xml.get_DocumentElement()
    $system_web = $root." system.web"
        if ($system_web.machineKey -eq $null)
             {
    $MachineKey = $xml.CreateElement(" machineKey" )
$a = $system_web.AppendChild($MachineKey)
             }
    $system_web.SelectSingleNode(" machineKey" ).SetAttribute(" validationKey" ," $ValidationKey64" )
    $system_web.SelectSingleNode(" machineKey" ).SetAttribute(" decryptionKey" ," $DecryptionKey24" )
$a = $xml.Save($MachineConfig)
        }
        Catch{
        Write-Output $Error
        }
        }
}
else
{
    Write-Output "Windows feature RDS-Web_access is not present on $($localhost)"
}
} -ArgumentList $ValidationKey64,$DecryptionKey24
Remove-PSSession -Session $session`n}
