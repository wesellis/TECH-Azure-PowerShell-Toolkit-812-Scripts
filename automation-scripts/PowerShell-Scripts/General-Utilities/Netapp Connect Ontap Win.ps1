<#
.SYNOPSIS
    Netapp Connect Ontap Win

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
    We Enhanced Netapp Connect Ontap Win

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [String]$email,
    [Parameter(Mandatory=$true)]
    [String]$password,
    [Parameter(Mandatory=$true)]
    [String]$WEOTCpassword,
    [Parameter(Mandatory=$true)]
    [String]$ocmip,
    [Parameter(Mandatory=$true)]
    [decimal]$WECapacity
) 

function WE-Get-ONTAPClusterDetails([String]$email, [String]$password, [String]$ocmip)
{

$authbody = @{
    email = " ${email}"
    password = " ${password}"
}
$authbodyjson = $authbody | ConvertTo-Json


$uriauth = " http://$ocmip/occm/api/auth/login"
$urigetpublicid = " http://$ocmip/occm/api/azure/vsa/working-environments"
$urigetproperties = " http://$ocmip/occm/api/azure/vsa/working-environments/${publicid?fields}?fields=ontapClusterProperties"
$headers = @{" Referer" = " AzureQS1" }


Invoke-RestMethod -Method Post -Headers $headers -UseBasicParsing -Uri ${uriauth} -ContentType 'application/json' -Body $authbodyjson  -SessionVariable session


$publicidjson = Invoke-WebRequest -Method Get -UseBasicParsing -Uri ${urigetpublicid} -ContentType 'application/json' -WebSession $session | ConvertFrom-Json
$publicid = $publicidjson.publicId


Invoke-WebRequest -Method Get -UseBasicParsing -Uri ${urigetproperties} -ContentType 'application/json' -WebSession $session -OutFile C:\WindowsAzure\logs\netappotc.json


$ontapclusterproperties = Invoke-WebRequest -Method Get -UseBasicParsing -Uri ${urigetproperties} -ContentType 'application/json' -WebSession $session | convertfrom-json 
 

$WEGlobal:AdminLIF = $ontapclusterproperties.ontapclusterproperties.nodes.lifs.ip | Select-Object -index 0
$WEGlobal:iScSILIF = $ontapclusterproperties.ontapclusterproperties.nodes.lifs.ip | Select-Object -index 3
$WEGlobal:SVMName = $ontapclusterproperties.svmname


echo " Admin Lif IP is $WEAdminLIF"
echo " iSCSI Lif IP is $iScSILIF"
echo " svm Name is is $WESVMName"



}

function WE-Connect-ONTAP([String]$WEAdminLIF, [String]$iScSILIF, [String]$WESVMName,[String]$WESVMPwd, [decimal]$WECapacity)
{
    $WEErrorActionPreference = 'Stop'

    try {
    
        Start-Transcript -Path C:\WindowsAzure\Logs\SQLNetApp_Connect_Storage.ps1.txt -Append
    
        Write-Output " Started @ $(Get-Date)"
        Write-Output " Admin Lif: $WEAdminLIF"
        Write-Output " iScSI Lif: $iScSiLIF"
        Write-Output " SVM Name : $WESVMName"
        Write-Output " SVM Password: $WESVMPwd"
        Write-Output " Capacity: $WECapacity"

        $WEAdminLIF= $WEAdminLIF.Substring($WEAdminLIF.IndexOf(':')+1)
        $iScSiLIF= $iScSiLIF.Substring($iScSiLIF.IndexOf(':')+1)
        $WESVMName = $WESVMName.Trim().Replace(" -" ," _" )

        Setup-VM

        $WEIqnName = " azureqsiqn"
        $WESecPasswd = ConvertTo-SecureString $WESVMPwd -AsPlainText -Force
        $WESvmCreds = New-Object System.Management.Automation.PSCredential (" admin" , $WESecPasswd)
        $WEVMIqn = (get-initiatorPort).nodeaddress
        #Pad the data Volume size by 10 percent
        $WEDataVolSize = [System.Math]::Floor($WECapacity * 1.1)
        #Log Volume will be one third of data with 10 percent padding
        $WELogVolSize = [System.Math]::Floor($WECapacity *.37 ) 

		$WEDataLunSize = $WECapacity
		$WELogLunSize =  $WECapacity *.33
        
        Import-module '${env:ProgramFiles} (x86)\NetApp\NetApp PowerShell Toolkit\Modules\DataONTAP\DataONTAP.psd1'
        
        Connect-NcController $WEAdminLIF -Credential $WESvmCreds -Vserver $WESVMName
        Create-NcGroup $WEIqnName $WEVMIqn $WESVMName
        New-IscsiTargetPortal -TargetPortalAddress $iScSiLIF
        Connect-Iscsitarget -NodeAddress (Get-IscsiTarget).NodeAddress -IsMultipathEnabled $WETrue -TargetPortalAddress $iScSiLIF
    
        Get-IscsiSession | Register-IscsiSession

        New-Ncvol -name sql_data_root -Aggregate aggr1 -JunctionPath $null -size ([string]($WEDataVolSize)+" g" ) -SpaceReserve none
        New-Ncvol -name sql_log_root -Aggregate aggr1 -JunctionPath $null -size ([string]($WELogVolSize)+" g" ) -SpaceReserve none

        New-Nclun /vol/sql_data_root/sql_data_lun ([string]$WEDataLunSize+" gb" ) -ThinProvisioningSupportEnabled -OsType " windows_2008"
        New-Nclun /vol/sql_log_root/sql_log_lun ([string]$WELogLunSize+" gb" ) -ThinProvisioningSupportEnabled -OsType " windows_2008" 

        Add-Nclunmap /vol/sql_data_root/sql_data_lun $WEIqnName
        Add-Nclunmap /vol/sql_log_root/sql_log_lun $WEIqnName

        
        Start-NcHostDiskRescan
        Wait-NcHostDisk -ControllerLunPath /vol/sql_data_root/sql_data_lun -ControllerName $WESVMName
        Wait-NcHostDisk -ControllerLunPath /vol/sql_log_root/sql_log_lun -ControllerName $WESVMName


       ;  $WEDataDisk = (Get-Nchostdisk | Where-Object {$_.ControllerPath -like " *sql_data_lun*" }).Disk
       ;  $WELogDisk = (Get-Nchostdisk | Where-Object {$_.ControllerPath -like " *sql_log_lun*" }).Disk

        Stop-Service -Name ShellHWDetection
        Set-Disk -Number $WEDataDisk -IsOffline $WEFalse
        Initialize-Disk -Number $WEDataDisk
        New-Partition -DiskNumber $WEDataDisk -UseMaximumSize -AssignDriveLetter  | ForEach-Object { Start-Sleep -s 5; $_| Format-Volume -NewFileSystemLabel " NetApp Disk 1" -Confirm:$WEFalse -Force }
    
        Set-Disk -number $WELogDisk -IsOffline $WEFalse
        Initialize-disk -Number $WELogDisk
        New-Partition -DiskNumber $WELogDisk -UseMaximumSize -AssignDriveLetter | ForEach-Object { Start-Sleep -s 5; $_| Format-Volume -NewFileSystemLabel " NetApp Disk 2" -Confirm:$WEFalse -Force}
        Start-Service -Name ShellHWDetection

        Write-Output " Completed @ $(Get-Date)"
        Stop-Transcript

    } 
    catch {
        Write-Output " $($_.exception.message)@ $(Get-Date)"
		exit 1
    }
 }

 

function WE-Create-NcGroup( [String] $WEVserverIqn, [String] $WEInisitatorIqn, [String] $WEVserver)
{
    $iGroupList = Get-ncigroup
    $iGroupSetup = $WEFalse
    $iGroupInitiatorSetup = $WEFalse

    #Find if iGroup is already setup, add if not 
    foreach($igroup in $iGroupList)
    {
        if ($igroup.Name -eq $WEVserverIqn)   
        {
            $iGroupSetup = $WETrue
            foreach($initiator in $igroup.Initiators)
            {
                if($initiator.InitiatorName.Equals($WEInisitatorIqn))
                {
                    $iGroupInitiatorSetup = $WETrue
                    Write-Output " Found $WEVserverIqn Iqn is alerady setup on SvM $WEVserver with Initiator $WEInisitatorIqn" 
                    break
                }
            }

            break
        }
    }
    if($iGroupInitiatorSetup -eq $WEFalse)
    {
        if ((get-nciscsiservice).IsAvailable -ne " True" ) { 
                Add-NcIscsiService 
        }
        if ($iGroupSetup -eq $WEFalse) {
            new-ncigroup -name $WEVserverIqn -Protocol iScSi -Type Windows    
        }
        Add-NcIgroupInitiator -name $WEVserverIqn -Initiator $WEInisitatorIqn
        Write-Output " Set up $WEVserverIqn Iqn on SvM $WEVserver"
    }

}

function WE-Set-MultiPathIO()
{
    $WEIsEnabled = (Get-WindowsOptionalFeature -FeatureName MultiPathIO -Online).State

    if ($WEIsEnabled -ne " Enabled" ) {

        Enable-WindowsOptionalFeature –Online –FeatureName MultiPathIO
     }
        
}

function WE-Start-ThisService([String]$WEServiceName)
{
    
    $WEService = Get-Service -Name $WEServiceName
    if ($WEService.Status -ne " Running" ){
        Start-Service $WEServiceName
        Write-Output " Starting $WEServiceName"
    }
    if ($WEService.StartType -ne " Automatic" ) {
        Set-Service $WEServiceName -startuptype " Automatic"
        Write-Output " Setting $WEServiceName Service Startup to Automatic"
    }
   
}

 function WE-Setup-VM ()
 {
    Set-MultiPathIO
    Start-ThisService " MSiSCSI"
 }




function WE-Load-SampleDatabase
{

$WEDataDirectory = " F:\SQL\DATA"
$WELogDirectory = " G:\SQL\Logs"
$WEBackupDirectory = " F:\SQL\BACKUPS"

function WE-Create-DirectoryStructure
{
New-Item -ItemType directory -Path $WEDataDirectory
New-Item -ItemType directory -Path $WELogDirectory
New-Item -ItemType directory -Path $WEBackupDirectory

}


function WE-Set-SQLDataLocation
{
$WEDataRegKeyPath = " HKLM:\Software\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer"
$WEDataRegKeyName = " DefaultData"
If ((Get-ItemProperty -Path $WEDataRegKeyPath -Name $WEDataRegKeyName -ErrorAction SilentlyContinue) -eq $null) {
  New-ItemProperty -Path $WEDataRegKeyPath -Name $WEDataRegKeyName -PropertyType String -Value $WEDataDirectory
} Else {
  Set-ItemProperty -Path $WEDataRegKeyPath -Name $WEDataRegKeyName -Value $WEDataDirectory
}
 
$WELogRegKeyPath = " HKLM:\Software\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer"
$WELogRegKeyName = " DefaultLog"
If ((Get-ItemProperty -Path $WELogRegKeyPath -Name $WELogRegKeyName -ErrorAction SilentlyContinue) -eq $null) {
  New-ItemProperty -Path $WELogRegKeyPath -Name $WELogRegKeyName -PropertyType String -Value $WELogDirectory
} Else {
  Set-ItemProperty -Path $WELogRegKeyPath -Name $WELogRegKeyName -Value $WELogDirectory
}
 
$WEBackupRegKeyPath = " HKLM:\Software\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer"
$WEBackupRegKeyName = " BackupDirectory"

If ((Get-ItemProperty -Path $WEBackupRegKeyPath -Name $WEBackupRegKeyName -ErrorAction SilentlyContinue) -eq $null) {
  New-ItemProperty -Path $WEBackupRegKeyPath -Name $WEBackupRegKeyName -PropertyType String -Value $WEBackupDirectory
} Else {
  Set-ItemProperty -Path $WEBackupRegKeyPath -Name $WEBackupRegKeyName -Value $WEBackupDirectory
}
}


function WE-Download-SampleDatabase
{
wget https://msftdbprodsamples.codeplex.com/downloads/get/880661 -OutFile $WEBackupDirectory\AdventureWorks2014bakzip.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem

function WE-Unzip
{
    param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$zipfile, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip $WEBackupDirectory\AdventureWorks2014bakzip.zip $WEBackupDirectory

}

Create-DirectoryStructure
Set-SQLDataLocation
Restart-Service -Force MSSQLSERVER
Download-SampleDatabase

}
function WE-Remove-Password([String]$password)
{
$azurelogfilepath = 'C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\1.8\CustomScriptHandler.log'
$scriptlogfilepath = 'C:\WindowsAzure\Logs\SQLNetApp_Connect_Storage.ps1.txt'
(get-content $azurelogfilepath) | % { $_ -replace $password, 'passwordremoved' } | set-content $azurelogfilepath
(get-content $scriptlogfilepath) | % { $_ -replace $password, 'passwordremoved' } | set-content $scriptlogfilepath
}

function WE-Install-NetAppPSToolkit
{
New-Item C:\NetApp -Type Directory; 
$WEWebClient = New-Object System.Net.WebClient
$WEWebClient.DownloadFile(" https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-workloads/netapp/netapp-ontap-sql/scripts/NetApp_PowerShell_Toolkit_4.3.0.msi" ," C:\NetApp\NetApp_PowerShell_Toolkit_4.3.0.msi" )
Invoke-Command -ScriptBlock { & cmd /c " msiexec.exe /i C:\NetApp\NetApp_PowerShell_Toolkit_4.3.0.msi" /qn ADDLOCAL=F.PSTKDOT}
}

; 
$WESVMPwd = $WEOTCpassword
Install-NetAppPSToolkit
Get-ONTAPClusterDetails $email $password $ocmip
Connect-ONTAP $WEAdminLIF $iScSILIF $WESVMName $WESVMPwd $WECapacity
Load-SampleDatabase
Remove-Password $password


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================