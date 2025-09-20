<#
.SYNOPSIS
    Installssms

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iex ((new-object -ErrorAction Stop net.webclient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install sql-server-management-studio -y

