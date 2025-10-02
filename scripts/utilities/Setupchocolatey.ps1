#Requires -Version 7.4

<#`n.SYNOPSIS
    Setupchocolatey

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param([Parameter(Mandatory)][Parameter()]
    [ValidateNotNullOrEmpty()]
    $ChocoPackages)
cls
    $UserName = " artifactInstaller"
[Reflection.Assembly]::LoadWithPartialName("System.Web" ) | Out-Null
    $password = $([System.Web.Security.Membership]::GeneratePassword(12,4))
    $cn = [ADSI]"WinNT://$env:ComputerName"
    $user = $cn.Create("User" , $UserName)
    $user.SetPassword($password)
    $user.SetInfo()
    $user.description = "Choco artifact installer"
    $user.SetInfo()


    Author: Wes Ellis (wes@wesellis.com)
    $group = [ADSI]"WinNT://$env:ComputerName/Administrators,group"
    $group.add("WinNT://$env:ComputerName/$UserName" )
    $SecPassword = Read-Host -Prompt "Enter secure value" -AsSecureString
    $credential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential(" $env:COMPUTERNAME\$($username)" , $SecPassword)
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    $sb = { iex ((new-object -ErrorAction Stop net.webclient).DownloadString('https://chocolatey.org/install.ps1')) }
Invoke-Command -ScriptBlock $sb -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
    $sb = { Set-ItemProperty -path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -name EnableLua -value 0 }
Invoke-Command -ScriptBlock $sb -ComputerName $env:COMPUTERNAME -Credential $credential
    $ChocoPackages.Split(" ;" ) | ForEach {
    $command = " cinst " + $_ + " -y -force"
    $command | Out-File $LogFile -Append
    $sb = [scriptblock]::Create(" $command" )
    Invoke-Command -ScriptBlock $sb -ArgumentList $ChocoPackages -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
}
Disable-PSRemoting -Force
    $cn.Delete("User" , $UserName)
gwmi win32_userprofile | where { $_.LocalPath -like " *$UserName*" } | foreach { $_.Delete() }
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
