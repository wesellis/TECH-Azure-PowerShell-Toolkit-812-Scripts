<#
.SYNOPSIS
    Netapp Connect Ontap Win

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory)]
    [String]$email,
    [Parameter(Mandatory)]
    [String]$password,
    [Parameter(Mandatory)]
    [String]$OTCpassword,
    [Parameter(Mandatory)]
    [String]$ocmip,
    [Parameter(Mandatory)]
    [decimal]$Capacity
)
function Get-ONTAPClusterDetails([String]$email, [String]$password, [String]$ocmip)
{
$authbody = @{
    email = " ${email}"
    password = " ${password}"
}
$authbodyjson = $authbody | ConvertTo-Json
$uriauth = " http://$ocmip/occm/api/auth/login"
$urigetpublicid = " http://$ocmip/occm/api/azure/vsa/working-environments"
$urigetproperties = " http://$ocmip/occm/api/azure/vsa/working-environments/${publicid?fields}?fields=ontapClusterProperties"
$headers = @{"Referer" = "AzureQS1" }
Invoke-RestMethod -Method Post -Headers $headers -UseBasicParsing -Uri ${uriauth} -ContentType 'application/json' -Body $authbodyjson  -SessionVariable session
$publicidjson = Invoke-WebRequest -Method Get -UseBasicParsing -Uri ${urigetpublicid} -ContentType 'application/json' -WebSession $session | ConvertFrom-Json
$publicid = $publicidjson.publicId
Invoke-WebRequest -Method Get -UseBasicParsing -Uri ${urigetproperties} -ContentType 'application/json' -WebSession $session -OutFile C:\WindowsAzure\logs\netappotc.json
$ontapclusterproperties = Invoke-WebRequest -Method Get -UseBasicParsing -Uri ${urigetproperties} -ContentType 'application/json' -WebSession $session | convertfrom-json
$Global:AdminLIF = $ontapclusterproperties.ontapclusterproperties.nodes.lifs.ip | Select-Object -index 0
$Global:iScSILIF = $ontapclusterproperties.ontapclusterproperties.nodes.lifs.ip | Select-Object -index 3
$Global:SVMName = $ontapclusterproperties.svmname
echo "Admin Lif IP is $AdminLIF"
echo " iSCSI Lif IP is $iScSILIF"
echo " svm Name is is $SVMName"
}
function Connect-ONTAP([String]$AdminLIF, [String]$iScSILIF, [String]$SVMName,[String]$SVMPwd, [decimal]$Capacity)
{
    $ErrorActionPreference = 'Stop'
    try {
        Start-Transcript -Path C:\WindowsAzure\Logs\SQLNetApp_Connect_Storage.ps1.txt -Append
        Write-Output "Started @ $(Get-Date)"
        Write-Output "Admin Lif: $AdminLIF"
        Write-Output " iScSI Lif: $iScSiLIF"
        Write-Output "SVM Name : $SVMName"
        Write-Output "SVM Password: $SVMPwd"
        Write-Output "Capacity: $Capacity"
        $AdminLIF= $AdminLIF.Substring($AdminLIF.IndexOf(':')+1)
        $iScSiLIF= $iScSiLIF.Substring($iScSiLIF.IndexOf(':')+1)
        $SVMName = $SVMName.Trim().Replace(" -" ," _" )
        Setup-VM
        $IqnName = " azureqsiqn"
        $SecPasswd = ConvertTo-SecureString $SVMPwd -AsPlainText -Force
        $SvmCreds = New-Object -ErrorAction Stop System.Management.Automation.PSCredential (" admin" , $SecPasswd)
        $VMIqn = (get-initiatorPort).nodeaddress
        #Pad the data Volume size by 10 percent
        $DataVolSize = [System.Math]::Floor($Capacity * 1.1)
        #Log Volume will be one third of data with 10 percent padding
        $LogVolSize = [System.Math]::Floor($Capacity *.37 )
		$DataLunSize = $Capacity
		$LogLunSize =  $Capacity *.33
        Import-module '${env:ProgramFiles} (x86)\NetApp\NetApp PowerShell Toolkit\Modules\DataONTAP\DataONTAP.psd1'
        Connect-NcController $AdminLIF -Credential $SvmCreds -Vserver $SVMName
        Create-NcGroup $IqnName $VMIqn $SVMName
        New-IscsiTargetPortal -TargetPortalAddress $iScSiLIF
        Connect-Iscsitarget -NodeAddress (Get-IscsiTarget).NodeAddress -IsMultipathEnabled $True -TargetPortalAddress $iScSiLIF
        Get-IscsiSession -ErrorAction Stop | Register-IscsiSession
        New-Ncvol -name sql_data_root -Aggregate aggr1 -JunctionPath $null -size ([string]($DataVolSize)+" g" ) -SpaceReserve none
        New-Ncvol -name sql_log_root -Aggregate aggr1 -JunctionPath $null -size ([string]($LogVolSize)+" g" ) -SpaceReserve none
        New-Nclun -ErrorAction Stop /vol/sql_data_root/sql_data_lun ([string]$DataLunSize+" gb" ) -ThinProvisioningSupportEnabled -OsType " windows_2008"
        New-Nclun -ErrorAction Stop /vol/sql_log_root/sql_log_lun ([string]$LogLunSize+" gb" ) -ThinProvisioningSupportEnabled -OsType " windows_2008"
        Add-Nclunmap /vol/sql_data_root/sql_data_lun $IqnName
        Add-Nclunmap /vol/sql_log_root/sql_log_lun $IqnName
        Start-NcHostDiskRescan
        Wait-NcHostDisk -ControllerLunPath /vol/sql_data_root/sql_data_lun -ControllerName $SVMName
        Wait-NcHostDisk -ControllerLunPath /vol/sql_log_root/sql_log_lun -ControllerName $SVMName
$DataDisk = (Get-Nchostdisk -ErrorAction Stop | Where-Object {$_.ControllerPath -like " *sql_data_lun*" }).Disk
$LogDisk = (Get-Nchostdisk -ErrorAction Stop | Where-Object {$_.ControllerPath -like " *sql_log_lun*" }).Disk
        Stop-Service -Name ShellHWDetection
        Set-Disk -Number $DataDisk -IsOffline $False
        Initialize-Disk -Number $DataDisk
        New-Partition -DiskNumber $DataDisk -UseMaximumSize -AssignDriveLetter  | ForEach-Object { Start-Sleep -s 5; $_| Format-Volume -NewFileSystemLabel "NetApp Disk 1" -Confirm:$False -Force }
        Set-Disk -number $LogDisk -IsOffline $False
        Initialize-disk -Number $LogDisk
        New-Partition -DiskNumber $LogDisk -UseMaximumSize -AssignDriveLetter | ForEach-Object { Start-Sleep -s 5; $_| Format-Volume -NewFileSystemLabel "NetApp Disk 2" -Confirm:$False -Force}
        Start-Service -Name ShellHWDetection
        Write-Output "Completed @ $(Get-Date)"
        Stop-Transcript
    }
    catch {
        Write-Output " $($_.exception.message)@ $(Get-Date)"
		throw
    }
 }
function Create-NcGroup( [String] $VserverIqn, [String] $InisitatorIqn, [String] $Vserver)
{
    $iGroupList = Get-ncigroup -ErrorAction Stop
    $iGroupSetup = $False
    $iGroupInitiatorSetup = $False
    #Find if iGroup is already setup, add if not
    foreach($igroup in $iGroupList)
    {
        if ($igroup.Name -eq $VserverIqn)
        {
            $iGroupSetup = $True
            foreach($initiator in $igroup.Initiators)
            {
                if($initiator.InitiatorName.Equals($InisitatorIqn))
                {
                    $iGroupInitiatorSetup = $True
                    Write-Output "Found $VserverIqn Iqn is alerady setup on SvM $Vserver with Initiator $InisitatorIqn"
                    break
                }
            }
            break
        }
    }
    if($iGroupInitiatorSetup -eq $False)
    {
        if ((get-nciscsiservice).IsAvailable -ne "True" ) {
                Add-NcIscsiService
        }
        if ($iGroupSetup -eq $False) {
            new-ncigroup -name $VserverIqn -Protocol iScSi -Type Windows
        }
        Add-NcIgroupInitiator -name $VserverIqn -Initiator $InisitatorIqn
        Write-Output "Set up $VserverIqn Iqn on SvM $Vserver"
    }
}
function Set-MultiPathIO()
{
    $IsEnabled = (Get-WindowsOptionalFeature -FeatureName MultiPathIO -Online).State
    if ($IsEnabled -ne "Enabled" ) {
        Enable-WindowsOptionalFeature Online FeatureName MultiPathIO
     }
}
function Start-ThisService([String]$ServiceName)
{
    $Service = Get-Service -Name $ServiceName
    if ($Service.Status -ne "Running" ){
        Start-Service $ServiceName
        Write-Output "Starting $ServiceName"
    }
    if ($Service.StartType -ne "Automatic" ) {
        Set-Service -ErrorAction Stop $ServiceName -startuptype "Automatic"
        Write-Output "Setting $ServiceName Service Startup to Automatic"
    }
}
 function Setup-VM ()
 {
    Set-MultiPathIO -ErrorAction Stop
    Start-ThisService "MSiSCSI"
 }
function Load-SampleDatabase
{
$DataDirectory = "F:\SQL\DATA"
$LogDirectory = "G:\SQL\Logs"
$BackupDirectory = "F:\SQL\BACKUPS"
function Create-DirectoryStructure
{
New-Item -ItemType directory -Path $DataDirectory
New-Item -ItemType directory -Path $LogDirectory
New-Item -ItemType directory -Path $BackupDirectory
}
function Set-SQLDataLocation -ErrorAction Stop
{
$DataRegKeyPath = "HKLM:\Software\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer"
$DataRegKeyName = "DefaultData"
If ((Get-ItemProperty -Path $DataRegKeyPath -Name $DataRegKeyName -ErrorAction SilentlyContinue) -eq $null) {
  New-ItemProperty -Path $DataRegKeyPath -Name $DataRegKeyName -PropertyType String -Value $DataDirectory
} Else {
  Set-ItemProperty -Path $DataRegKeyPath -Name $DataRegKeyName -Value $DataDirectory
}
$LogRegKeyPath = "HKLM:\Software\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer"
$LogRegKeyName = "DefaultLog"
If ((Get-ItemProperty -Path $LogRegKeyPath -Name $LogRegKeyName -ErrorAction SilentlyContinue) -eq $null) {
  New-ItemProperty -Path $LogRegKeyPath -Name $LogRegKeyName -PropertyType String -Value $LogDirectory
} Else {
  Set-ItemProperty -Path $LogRegKeyPath -Name $LogRegKeyName -Value $LogDirectory
}
$BackupRegKeyPath = "HKLM:\Software\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer"
$BackupRegKeyName = "BackupDirectory"
If ((Get-ItemProperty -Path $BackupRegKeyPath -Name $BackupRegKeyName -ErrorAction SilentlyContinue) -eq $null) {
  New-ItemProperty -Path $BackupRegKeyPath -Name $BackupRegKeyName -PropertyType String -Value $BackupDirectory
} Else {
  Set-ItemProperty -Path $BackupRegKeyPath -Name $BackupRegKeyName -Value $BackupDirectory
}
}
function Download-SampleDatabase
{
wget https://msftdbprodsamples.codeplex.com/downloads/get/880661 -OutFile $BackupDirectory\AdventureWorks2014bakzip.zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$zipfile, [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
Unzip $BackupDirectory\AdventureWorks2014bakzip.zip $BackupDirectory
}
Create-DirectoryStructure
Set-SQLDataLocation -ErrorAction Stop
Restart-Service -Force MSSQLSERVER
Download-SampleDatabase
}
function Remove-Password([String]$password)
{
$azurelogfilepath = 'C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\1.8\CustomScriptHandler.log'
$scriptlogfilepath = 'C:\WindowsAzure\Logs\SQLNetApp_Connect_Storage.ps1.txt'
(get-content -ErrorAction Stop $azurelogfilepath) | % { $_ -replace $password, 'passwordremoved' } | set-content -ErrorAction Stop $azurelogfilepath
(get-content -ErrorAction Stop $scriptlogfilepath) | % { $_ -replace $password, 'passwordremoved' } | set-content -ErrorAction Stop $scriptlogfilepath
}
function Install-NetAppPSToolkit
{
New-Item -ErrorAction Stop C:\NetApp -Type Directory;
$WebClient = New-Object -ErrorAction Stop System.Net.WebClient
$WebClient.DownloadFile(" https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-workloads/netapp/netapp-ontap-sql/scripts/NetApp_PowerShell_Toolkit_4.3.0.msi" ,"C:\NetApp\NetApp_PowerShell_Toolkit_4.3.0.msi" )
Invoke-Command -ScriptBlock { & cmd /c " msiexec.exe /i C:\NetApp\NetApp_PowerShell_Toolkit_4.3.0.msi" /qn ADDLOCAL=F.PSTKDOT}
}
$SVMPwd = $OTCpassword
Install-NetAppPSToolkit
Get-ONTAPClusterDetails -ErrorAction Stop $email $password $ocmip
Connect-ONTAP $AdminLIF $iScSILIF $SVMName $SVMPwd $Capacity
Load-SampleDatabase
Remove-Password -ErrorAction Stop $password

