#Requires -Version 7.4
$ErrorActionPreference = 'Stop'

    Qs Install
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
<#`n.SYNOPSIS
    PowerShell script
.DESCRIPTION
    PowerShell operation


    Author: Wes Ellis (wes@wesellis.com)
Qlik Sense Installation
$AdminUser = $Args[0]
$AdminPass = $Args[1]
$ServiceAccountUser = $Args[2]
$ServiceAccountPass = $Args[3]
$DbPass = $Args[4]
$QlikSenseVersion = $($Args[5])
$QlikSenseSerial = $($Args[6])
$QlikSenseControl = $($Args[7])
$QlikSenseOrganization = $($Args[8])
$QlikSenseName = $($Args[9])
$ServiceAccountWithDomain = -join ($($env:ComputerName), '\',$($Args[2]))
$json = @{
    qliksense = @(
        @{
            name= "Qlik Sense November 2017"
            url= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.24/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= "Qlik Sense September 2017 Patch 1"
            url= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.14/1/_MSI/Qlik_Sense_update.exe"
            url2= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.14/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= "Qlik Sense September 2017"
            url= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.14/0/_MSI/Qlik_Sense_setup.exe"
          },
        @{
            name= "Qlik Sense June 2017 Patch 3"
            url= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/3/_MSI/Qlik_Sense_update.exe"
            url2= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= "Qlik Sense June 2017 Patch 2"
            url= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/2/_MSI/Qlik_Sense_update.exe"
            url2= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= "Qlik Sense June 2017 Patch 1"
            url= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/1/_MSI/Qlik_Sense_update.exe"
            url2= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= "Qlik Sense June 2017"
            url= "https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= "Qlik Sense 3.2 SR5"
            url= "https://da3hntz84uekx.cloudfront.net/QlikSense/3.2.5/205/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= "Qlik Sense 3.2 SR4"
            url= "https://da3hntz84uekx.cloudfront.net/QlikSense/3.2.4/204/_MSI/Qlik_Sense_setup.exe"
        }
    )
}
$json | ConvertTo-Json -Compress -Depth 10 | Out-File 'c:\installation\qBinaryDownload.json'
net user " $($ServiceAccountUser)" " $($ServiceAccountPass)"/add /fullname:"Qlik Sense Service Account"/passwordchg:NO
([ADSI]"WinNT://$($env:computername)/administrators,group" ).psbase.Invoke("Add" ,([ADSI]"WinNT://$($env:computername)/$($ServiceAccountUser)" ).path)
New-Item -ItemType directory -Path C:\Qlik
New-SmbShare -Name Qlik -Path C:\Qlik -FullAccess everyone
Get-PackageProvider -Name NuGet -ForceBootstrap
Install-Module -Name Qlik-CLI -Confirm:$false -Force
$json = (@{
    name = $QlikSenseVersion;})
$json | ConvertTo-Json -Compress -Depth 10 | Out-File 'c:\installation\qsVer.json'
$QsVer = (Get-Content -ErrorAction Stop C:\installation\qsVer.json -raw) | ConvertFrom-Json
$QsBinaryURL = (Get-Content -ErrorAction Stop C:\installation\qBinaryDownload.json -raw) | ConvertFrom-Json
$BinaryName = $QsBinaryURL.qliksense | where { $_.name -eq $QsVer.name}
$SelVer = $QsBinaryURL.qliksense | where { $_.name -eq $QsVer.name }
$path = 'c:\installation'
$url = $SelVer.url
$FileName = $url.Substring($url.LastIndexOf("/" ) + 1)
$DlLoc = join-path $path $FileName
if ($SelVer.name -like " *Patch*" ) {
    (New-Object -ErrorAction Stop System.Net.WebClient).DownloadFile($url, $DlLoc)
    $url2 = $SelVer.url2
    $FileName = $url2.Substring($url2.LastIndexOf("/" ) + 1)
    $DlLoc = join-path $path $FileName
    (New-Object -ErrorAction Stop System.Net.WebClient).DownloadFile($url2, $DlLoc)
   }
else
   {
   (New-Object -ErrorAction Stop System.Net.WebClient).DownloadFile($url, $DlLoc)
   }
New-NetFirewallRule -DisplayName "Qlik Sense" -Direction Inbound -LocalPort 443, 4244, 80, 4248 -Protocol TCP -Action Allow
@"
<?xml version=" 1.0" ?>
<SharedPersistenceConfiguration xmlns:xsi=" http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd=" http://www.w3.org/2001/XMLSchema" >
  <DbUserName>qliksenserepository</DbUserName>
  <DbUserPassword>$($DbPass)</DbUserPassword>
  <DbHost>$env:COMPUTERNAME</DbHost>
  <DbPort>4432</DbPort>
  <RootDir>\\$env:COMPUTERNAME\Qlik</RootDir>
  <StaticContentRootDir>\\$env:COMPUTERNAME\Qlik\StaticContent</StaticContentRootDir>
  <CustomDataRootDir>\\$env:COMPUTERNAME\Qlik\CustomData</CustomDataRootDir>
  <ArchivedLogsDir>\\$env:COMPUTERNAME\Qlik\ArchivedLogs</ArchivedLogsDir>
  <AppsDir>\\$env:COMPUTERNAME\Qlik\Apps</AppsDir>
  <CreateCluster>true</CreateCluster>
  <InstallLocalDb>true</InstallLocalDb>
  <ConfigureDbListener>true</ConfigureDbListener>
  <ListenAddresses>*</ListenAddresses>
  <IpRange>0.0.0.0/0</IpRange>
  <!--<JoinCluster>true</JoinCluster>-->
</SharedPersistenceConfiguration>
" @ | Out-File C:\installation\spConfig.xml
If (Test-Path "C:\installation\Qlik_Sense_setup.exe" )
	{
		Unblock-File -Path C:\installation\Qlik_Sense_setup.exe
		Invoke-Command -ScriptBlock {Start-Process -FilePath " c:\installation\Qlik_Sense_setup.exe" -ArgumentList " -s -log c:\installation\logqlik.txt dbpassword=$($DbPass) hostname=$($env:COMPUTERNAME) userwithdomain=$ServiceAccountWithDomain password=$($ServiceAccountPass) spc=c:\installation\spConfig.xml" -Wait -PassThru}
	}
$StatusCode = 0
while ($StatusCode -ne 200)
	{
		try { $StatusCode = (invoke-webrequest  https://$($env:COMPUTERNAME)/qps/user -usebasicParsing).statusCode }
		Catch
			{
				"Server down, waiting 20 seconds" | Add-Content c:\installation\statusLog.txt
				start-Sleep -s 20
			}
	}
If (Test-Path " c:\installation\Qlik_Sense_update.exe" )
	{
		Unblock-File -Path c:\installation\Qlik_Sense_update.exe
		Invoke-Command -ScriptBlock {Start-Process -FilePath " c:\installation\Qlik_Sense_Update.exe" -ArgumentList " install" -Wait -Passthru }
		Get-Service -ErrorAction Stop Qlik* | where {$_.Name -ne 'QlikLoggingService'} | Start-Service
		Get-Service -ErrorAction Stop Qlik* | where {$_.Name -eq 'QlikSenseServiceDispatcher'} | Stop-Service
		Get-Service -ErrorAction Stop Qlik* | where {$_.Name -eq 'QlikSenseServiceDispatcher'} | Start-Service
	}
If (! ( $QlikSenseSerial -eq " defaultValue" ) -or $QlikSenseSerial -eq "" ) {
$StatusCode = 0
    while ($StatusCode -ne 200)
    {
        try { $StatusCode = (invoke-webrequest  https://$($env:COMPUTERNAME)/qps/user -usebasicParsing).statusCode }
        Catch
            {
                start-Sleep -s 20
            }
    }
$ConnectResult = Connect-Qlik $env:COMPUTERNAME -UseDefaultCredentials
$LicenseResult = Set-QlikLicense -serial $QlikSenseSerial -control $QlikSenseControl -name " $($QlikSenseName)" -organization " $($QlikSenseOrganization)"`n}
