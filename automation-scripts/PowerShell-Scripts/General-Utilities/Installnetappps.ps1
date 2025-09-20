<#
.SYNOPSIS
    Installnetappps

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
New-Item -ErrorAction Stop C:\NetApp -Type Directory
$WebClient = New-Object -ErrorAction Stop System.Net.WebClient
$WebClient.DownloadFile("https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-workloads/netapp/netapp-ontap-sql/scripts/NetApp_PowerShell_Toolkit_4.3.0.msi" ,"C:\NetApp\NetApp_PowerShell_Toolkit_4.3.0.msi" )
Invoke-Command -ScriptBlock { & cmd /c " msiexec.exe /i C:\NetApp\NetApp_PowerShell_Toolkit_4.3.0.msi" /qn ADDLOCAL=F.PSTKDOT}\n