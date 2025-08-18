<#
.SYNOPSIS
    We Enhanced Qs Install

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

<# Qlik Sense Installation #>


$adminUser = $WEArgs[0]
$adminPass = $WEArgs[1]
$serviceAccountUser = $WEArgs[2]
$serviceAccountPass = $WEArgs[3]
$dbPass = $WEArgs[4]
$qlikSenseVersion = $($WEArgs[5])
$qlikSenseSerial = $($WEArgs[6])
$qlikSenseControl = $($WEArgs[7])
$qlikSenseOrganization = $($WEArgs[8])
$qlikSenseName = $($WEArgs[9])
$serviceAccountWithDomain = -join ($($env:ComputerName), '\',$($WEArgs[2]))


$json = @{
    qliksense = @(
        @{
            name= "Qlik Sense November 2017"
            url= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.24/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= " Qlik Sense September 2017 Patch 1"
            url= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.14/1/_MSI/Qlik_Sense_update.exe"
            url2= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.14/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= " Qlik Sense September 2017"
            url= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.14/0/_MSI/Qlik_Sense_setup.exe"
          },
        @{
            name= " Qlik Sense June 2017 Patch 3"
            url= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/3/_MSI/Qlik_Sense_update.exe"
            url2= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{  
            name= " Qlik Sense June 2017 Patch 2"
            url= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/2/_MSI/Qlik_Sense_update.exe"
            url2= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= " Qlik Sense June 2017 Patch 1"
            url= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/1/_MSI/Qlik_Sense_update.exe"
            url2= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= " Qlik Sense June 2017"
            url= " https://da3hntz84uekx.cloudfront.net/QlikSense/11.11/0/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= " Qlik Sense 3.2 SR5"
            url= " https://da3hntz84uekx.cloudfront.net/QlikSense/3.2.5/205/_MSI/Qlik_Sense_setup.exe"
        },
        @{
            name= " Qlik Sense 3.2 SR4"
            url= " https://da3hntz84uekx.cloudfront.net/QlikSense/3.2.4/204/_MSI/Qlik_Sense_setup.exe"
        }
    )
}

$json | ConvertTo-Json -Compress -Depth 10 | Out-File 'c:\installation\qBinaryDownload.json'


net user " $($serviceAccountUser)" " $($serviceAccountPass)" /add /fullname:" Qlik Sense Service Account" /passwordchg:NO
([ADSI]" WinNT://$($env:computername)/administrators,group").psbase.Invoke(" Add",([ADSI]" WinNT://$($env:computername)/$($serviceAccountUser)").path)


New-Item -ItemType directory -Path C:\Qlik
New-SmbShare -Name Qlik -Path C:\Qlik -FullAccess everyone


Get-PackageProvider -Name NuGet -ForceBootstrap
Install-Module -Name Qlik-CLI -Confirm:$false -Force

; 
$json = (@{
    name = $qlikSenseVersion;}) 

$json | ConvertTo-Json -Compress -Depth 10 | Out-File 'c:\installation\qsVer.json'

$qsVer = (Get-Content C:\installation\qsVer.json -raw) | ConvertFrom-Json
$qsBinaryURL = (Get-Content C:\installation\qBinaryDownload.json -raw) | ConvertFrom-Json
$binaryName = $qsBinaryURL.qliksense | where { $_.name -eq $qsVer.name}
$selVer = $qsBinaryURL.qliksense | where { $_.name -eq $qsVer.name }
$path = 'c:\installation'
$url = $selVer.url
$fileName = $url.Substring($url.LastIndexOf(" /") + 1)
$dlLoc = join-path $path $fileName
if ($selVer.name -like " *Patch*") {
    (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
    $url2 = $selVer.url2
    $fileName = $url2.Substring($url2.LastIndexOf(" /") + 1)
    $dlLoc = join-path $path $fileName
    (New-Object System.Net.WebClient).DownloadFile($url2, $dlLoc)
   }
else
   {
   (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
   }


New-NetFirewallRule -DisplayName " Qlik Sense" -Direction Inbound -LocalPort 443, 4244, 80, 4248 -Protocol TCP -Action Allow


@"
<?xml version=" 1.0"?>
<SharedPersistenceConfiguration xmlns:xsi=" http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd=" http://www.w3.org/2001/XMLSchema">
  <DbUserName>qliksenserepository</DbUserName>
  <DbUserPassword>$($dbPass)</DbUserPassword>
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
		Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\installation\Qlik_Sense_setup.exe" -ArgumentList " -s -log c:\installation\logqlik.txt dbpassword=$($dbPass) hostname=$($env:COMPUTERNAME) userwithdomain=$serviceAccountWithDomain password=$($serviceAccountPass) spc=c:\installation\spConfig.xml" -Wait -PassThru}
	}

$statusCode = 0
while ($WEStatusCode -ne 200) 
	{
		try { $statusCode = (invoke-webrequest  https://$($env:COMPUTERNAME)/qps/user -usebasicParsing).statusCode }
		Catch 
			{ 
				" Server down, waiting 20 seconds" | Add-Content c:\installation\statusLog.txt
				start-Sleep -s 20
			}
	}

If (Test-Path " c:\installation\Qlik_Sense_update.exe")
	{
		Unblock-File -Path c:\installation\Qlik_Sense_update.exe
		Invoke-Command -ScriptBlock {Start-Process -FilePath " c:\installation\Qlik_Sense_Update.exe" -ArgumentList " install" -Wait -Passthru }
		Get-Service Qlik* | where {$_.Name -ne 'QlikLoggingService'} | Start-Service
		Get-Service Qlik* | where {$_.Name -eq 'QlikSenseServiceDispatcher'} | Stop-Service
		Get-Service Qlik* | where {$_.Name -eq 'QlikSenseServiceDispatcher'} | Start-Service
	}

If (! ( $qlikSenseSerial -eq " defaultValue" ) -or $qlikSenseSerial -eq "" ) {
$statusCode = 0
    while ($WEStatusCode -ne 200) 
    {
        try { $statusCode = (invoke-webrequest  https://$($env:COMPUTERNAME)/qps/user -usebasicParsing).statusCode }
        Catch 
            { 
                start-Sleep -s 20
            }
    }
    $connectResult = Connect-Qlik $env:COMPUTERNAME -UseDefaultCredentials
   ;  $licenseResult = Set-QlikLicense -serial $qlikSenseSerial -control $qlikSenseControl -name "$($qlikSenseName)" -organization " $($qlikSenseOrganization)"
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================