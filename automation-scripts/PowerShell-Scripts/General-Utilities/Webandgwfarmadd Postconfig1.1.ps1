<#
.SYNOPSIS
    We Enhanced Webandgwfarmadd Postconfig1.1

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

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
     [String]$WEWebGwServer,
     [String]$WEBrokerServer,
     [String]$WEWebURL,
     [String]$WEDomainname,
     [String]$WEDomainNetbios,
     [String]$username,
     [String]$password,
     [string]$WEServerName = "gateway" ,
     [int]$numberofwebServers,
     $validationKey64,
     $decryptionKey24
    
    ) 

$localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
$username = $WEDomainNetbios + "\" + $WEUsername
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList @($username,(ConvertTo-SecureString -String $password -AsPlainText -Force))

configuration RDWebAccessdeployment
{

    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [String]$domainName,

        [Parameter(Mandatory)]
        [PSCredential]$adminCreds,

        # Connection Broker Node name
        [String]$connectionBroker,
        
        # Web Access Node name
        [String]$webAccessServer,

        # Gateway external FQDN
        [String]$externalFqdn
        
      ) 


    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xRemoteDesktopSessionHost
   
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
    
    if (-not $connectionBroker)   { $connectionBroker = $localhost }
    if (-not $webAccessServer)    { $webAccessServer  = $localhost }

    if (-not $collectionName)         { $collectionName = " Desktop Collection" }
    if (-not $collectionDescription)  { $collectionDescription = " A sample RD Session collection up in cloud." }

    Node localhost
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = " ApplyOnly"
        }

        xRDServer AddWebAccessServer
        {
            Role    = 'RDS-Web-Access'
            Server  = $webAccessServer
            GatewayExternalFqdn = $externalFqdn
            ConnectionBroker = $WEBrokerServer

            PsDscRunAsCredential = $adminCreds
        }
    
    }



}#End of Configuration RDWebAccessdeployment 

$WEConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
} # End of Config Data


RDWebAccessdeployment -adminCreds $cred -connectionBroker $WEBrokerServer -webAccessServer $localhost -externalFqdn $WEWebURL -domainName $WEDomainname -ConfigurationData $WEConfigData -Verbose
Start-DscConfiguration -Wait -Force -Path .\RDWebAccessdeployment -Verbose


configuration RDGatewaydeployment
{

    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory)]
        [String]$domainName,

        [Parameter(Mandatory)]
        [PSCredential]$adminCreds,

        # Connection Broker Node name
        [String]$connectionBroker,
        
        # Web Access Node name
        [String]$webAccessServer,

        # Gateway external FQDN
        [String]$externalFqdn,
        
        # RD Session Host count and naming prefix
        [Int]$numberOfRdshInstances = 1,
        [String]$sessionHostNamingPrefix = " SessionHost-",

        # Collection Name
        [String]$collectionName,

        # Connection Description
        [String]$collectionDescription

      ) 


    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement, xRemoteDesktopSessionHost
   
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
 
    if (-not $connectionBroker)   { $connectionBroker = $localhost }
    if (-not $webAccessServer)    { $webAccessServer  = $localhost }

    if (-not $collectionName)         { $collectionName = " Desktop Collection" }
    if (-not $collectionDescription)  { $collectionDescription = " A sample RD Session collection up in cloud." }

    Node localhost
    {

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = " ApplyOnly"
        }

        xRDServer AddGatewayServer
        {
            Role    = 'RDS-Gateway'
            Server  = $webAccessServer
            GatewayExternalFqdn = $externalFqdn
            ConnectionBroker = $WEBrokerServer

            PsDscRunAsCredential = $adminCreds
        }
    
    }



}#End of Configuration RDGatewaydeployment 

$WEConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
        }
    )
} # End of Config Data

RDGatewaydeployment -adminCreds $cred -connectionBroker $WEBrokerServer -webAccessServer $localhost -externalFqdn $WEWebURL -domainName $WEDomainname -ConfigurationData $WEConfigData -Verbose
Start-DscConfiguration -Wait -Force -Path .\RDGatewaydeployment -Verbose




Write-WELog " Username : $($username),   Password: $($password)" " INFO"
; 
$webServernameArray = New-Object System.Collections.ArrayList

for ($i = 0; $i -le $numberofwebServers; $i++)
{ 
    if ($i -eq 0)
    {
        $webServername = " Gateway"
        #Write-WELog " For i = 0, srvername = $($webServername)" " INFO"
    }
    else{
    $servercount = $i - 1
    $webServername = " gateway" + $servercount.ToString()
    #Write-WELog " For $($i), servername = $($webServername)" " INFO"
        }
    $webServernameArray.Add($webServername) | Out-Null
}

Write-WELog " web server Array value $($webServernameArray)" " INFO"


[int]$keylen = 64
       $buff = new-object " System.Byte[]" $keylen
       $rnd = new-object System.Security.Cryptography.RNGCryptoServiceProvider
       $rnd.GetBytes($buff)
      ;  $result =""
       for($i=0; $i -lt $keylen; $i++)  {
             $result = $result + [System.String]::Format(" {0:X2}",$buff[$i])
       }
       $validationkey64 = $result
       # Write-Host $validationkey64
       # end of Validation Key code

       $keylen = 24
       $buff1 = new-object " System.Byte[]" $keylen
       $rnd1 = new-object System.Security.Cryptography.RNGCryptoServiceProvider
       $rnd1.GetBytes($buff1)
      ;  $result =""
       for($i=0; $i -lt $keylen; $i++)  {
             $result = $result + [System.String]::Format(" {0:X2}",$buff[$i])
       }
       $decryptionKey24 = $result
       # Write-Host $decryptionKey24



foreach ($item in $webServernameArray)
{
    $WEWebServer = $item + " ." + $WEDomainName
    Write-WELog " Starting working on webserver name : $($WEWebServer)" " INFO"
    try{
    $session = New-PSSession -ComputerName $WEWebServer -Credential $cred 
    }
    catch{
    Write-Host $WEError
    }


Invoke-Command -session $session -ScriptBlock {[CmdletBinding()]
$ErrorActionPreference = "Stop"
param($validationkey64,$decryptionKey24)


function WE-ValidateWindowsFeature
{
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
    $WERdsWindowsFeature = Get-WindowsFeature -ComputerName $localhost -Name RDS-Web-Access     
    if ($WERdsWindowsFeature.InstallState -eq " Installed")
    {
        Return $true
    }
    else
    {
        Return $false
    }

}
$WEValidationheck = $WEFalse
$WEValidationheck = ValidateWindowsFeature
$localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
if($WEValidationheck -eq $true)
{
    Write-WELog " Windows feature RDS-Web_access present on $($localhost)" " INFO"
    $machineConfig = " C:\Windows\Web\RDWeb\Web.config"
       if (Test-Path $machineConfig) 
       {
        Write-WELog " editing machine config file : $($machineConfig) on server $($localhost) " " INFO"
        
        try{
        $xml = [xml](get-content $machineConfig)
        $xml.Save($machineConfig + " _")
        
        $root = $xml.get_DocumentElement()
        $system_web = $root." system.web"
        if ($system_web.machineKey -eq $null) 
             { 
             $machineKey = $xml.CreateElement(" machineKey") 
             $a = $system_web.AppendChild($machineKey)
             }
        $system_web.SelectSingleNode(" machineKey").SetAttribute(" validationKey"," $validationKey64")
        $system_web.SelectSingleNode(" machineKey").SetAttribute(" decryptionKey"," $decryptionKey24")
       ;  $a = $xml.Save($machineConfig)
        
        }
        Catch{
        Write-Host $WEError
        }
        
        } # end of If test-path

} # End of If($WEValidationCheck -eq $WETrue)
else
{
    Write-WELog " Windows feature RDS-Web_access is not present on $($localhost)" " INFO"
}

               
      
} -ArgumentList $validationKey64,$decryptionKey24 # end of Script Block 

Remove-PSSession -Session $session



} # end of foreach $item in $webServername










# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================