#Requires -Version 7.0

<#`n.SYNOPSIS
    Installnetappps

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
New-Item -ErrorAction Stop C:
etApp -Type Directory
$WebClient = New-Object -ErrorAction Stop System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-workloads/netapp/netapp-ontap-sql/scripts/NetApp_PowerShell_Toolkit_4.3.0.msi" ,"C:
etApp
etApp_PowerShell_Toolkit_4.3.0.msi" )
Invoke-Command -ScriptBlock { & cmd /c " msiexec.exe /i C:
etApp
etApp_PowerShell_Toolkit_4.3.0.msi" /qn ADDLOCAL=F.PSTKDOT}
