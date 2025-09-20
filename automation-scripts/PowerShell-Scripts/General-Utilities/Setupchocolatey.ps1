<#
.SYNOPSIS
    Setupchocolatey

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param([Parameter(Mandatory)][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$chocoPackages)
cls
$userName = " artifactInstaller"
[Reflection.Assembly]::LoadWithPartialName("System.Web" ) | Out-Null
$password = $([System.Web.Security.Membership]::GeneratePassword(12,4))
$cn = [ADSI]"WinNT://$env:ComputerName"
$user = $cn.Create("User" , $userName)
$user.SetPassword($password)
$user.SetInfo()
$user.description = "Choco artifact installer"
$user.SetInfo()
#>
$group = [ADSI]"WinNT://$env:ComputerName/Administrators,group"
$group.add("WinNT://$env:ComputerName/$userName" )
$secPassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential(" $env:COMPUTERNAME\$($username)" , $secPassword)
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
$sb = { iex ((new-object -ErrorAction Stop net.webclient).DownloadString('https://chocolatey.org/install.ps1')) }
Invoke-Command -ScriptBlock $sb -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
$sb = { Set-ItemProperty -path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -name EnableLua -value 0 }
Invoke-Command -ScriptBlock $sb -ComputerName $env:COMPUTERNAME -Credential $credential
$chocoPackages.Split(" ;" ) | ForEach {
    $command = " cinst " + $_ + " -y -force"
    $command | Out-File $LogFile -Append
$sb = [scriptblock]::Create(" $command" )
    # Use the current user profile
    Invoke-Command -ScriptBlock $sb -ArgumentList $chocoPackages -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
}
Disable-PSRemoting -Force
$cn.Delete("User" , $userName)
gwmi win32_userprofile | where { $_.LocalPath -like " *$userName*" } | foreach { $_.Delete() }
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

