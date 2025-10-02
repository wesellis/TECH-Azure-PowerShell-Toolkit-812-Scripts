#Requires -Version 7.4

<#`n.SYNOPSIS
    Setup

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter()]
    $mail,
    [Parameter()]
    $publicdnsname,
    [Parameter()]
    $AdminPwd,
    [Parameter()]
    $BasePath,
    [Parameter()]
    $PublicSshKey
)
    $ProgressPreference = 'SilentlyContinue'
Get-Disk -ErrorAction Stop | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem NTFS -Confirm:$false -Force
New-Item -Path f:\le -ItemType Directory | Out-Null
New-Item -Path f:\le\acme.json | Out-Null
New-Item -Path f:\dockerdata -ItemType Directory | Out-Null
New-Item -Path f:\portainerdata -ItemType Directory | Out-Null
New-Item -Path f:\compose -ItemType Directory | Out-Null
[DownloadWithRetry]::DoDownloadWithRetry(" https://chocolatey.org/install.ps1" , 5, 10,
    [Parameter()]
    $null, ".\chocoInstall.ps1" ,
    [Parameter()]
    $false)
& .\chocoInstall.ps1
choco feature enable -n allowGlobalConfirmation
choco install --no-progress --limit-output vim
choco install --no-progress --limit-output pwsh
choco install --no-progress --limit-output openssh -params '"/SSHServerFeature" '
Copy-Item " $BasePath\sshd_config_wopwd" 'C:\ProgramData\ssh\sshd_config';
    $path = " c:\ProgramData\ssh\administrators_authorized_keys"
" $PublicSshKey" | Out-File -Encoding utf8 -FilePath $path;
    $acl = Get-Acl -Path $path
    $acl.SetSecurityDescriptorSddlForm("O:BAD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)" )
Set-Acl -Path $path -AclObject $acl
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force
'function prompt { "PS [$env:COMPUTERNAME]:$($ExecutionContext.SessionState.Path.CurrentLocation)$(''>'' * ($NestedPromptLevel + 1)) " }' | Out-File -FilePath " $($PROFILE.AllUsersAllHosts)" -Encoding utf8
Restart-Service sshd
Stop-Service docker
    $DockerDaemonConfig = @"
{
    `" data-root`" : `" f:\\dockerdata`"
}
" @
    $DockerDaemonConfig | Out-File " c:\programdata\docker\config\daemon.json" -Encoding ascii
Remove-Item -ErrorAction Stop 'f:\dockerdata\panic.lo -Forceg -Force' -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ErrorAction Stop 'f:\dockerdata\panic.log' -ItemType File -ErrorAction SilentlyContinue | Out-Null
Add-MpPreference -ExclusionPath '${env:ProgramFiles}\docker\'
Add-MpPreference -ExclusionPath 'f:\dockerdata'
Start-Service docker
    $AdminPwd | Out-File -NoNewline -Encoding ascii " f:\portainerdata\passwordfile"
[DownloadWithRetry]::DoDownloadWithRetry(" https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Windows-x86_64.exe" , 5, 10,
    [Parameter()]
    $null, "$($Env:ProgramFiles)\Docker\docker-compose.exe" ,
    [Parameter()]
    $false)
    $template = Get-Content -ErrorAction Stop (Join-Path $basepath 'docker-compose.yml.template') -Raw
    $expanded = Invoke-Expression " @`" `r`n$template`r`n`" @"
    $expanded | Out-File " f:\compose\docker-compose.yml" -Encoding ASCII
Set-Location -ErrorAction Stop " f:\compose"
Invoke-Expression " docker-compose up -d"
class DownloadWithRetry {
    static [string] DoDownloadWithRetry([string] $uri, [int] $MaxRetries, [int] $RetryWaitInSeconds, [string] $AuthToken, [string] $OutFile, [bool] $metadata) {
    $RetryCount = 0
    $headers = @{}
        if (-not ([string]::IsNullOrEmpty($AuthToken))) {
    $headers = @{
                'Authorization' = $AuthToken
            }
        }
        if ($metadata) {
    $headers.Add('Metadata', 'true')
        }
        while ($RetryCount -le $MaxRetries) {
            try {
                if ($headers.Count -ne 0) {
                    if ([string]::IsNullOrEmpty($OutFile)) {
    $result = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing
                        return $result.Content
                    }
                    else {
    $result = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing -OutFile $OutFile
                        return ""
                    }
                }
                else {
                    throw;

} catch {
                if ($headers.Count -ne 0) {
                    Write-Output " download of $uri failed"
                }
                try {
                    if ([string]::IsNullOrEmpty($OutFile)) {
    $result = Invoke-WebRequest -Uri $uri -UseBasicParsing
                        return $result.Content
                    }
                    else {
    $result = Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile $OutFile
                        return ""

} catch {
                    Write-Output " download of $uri failed"
    $RetryCount++;
                    if ($RetryCount -le $MaxRetries) {
                        Start-Sleep -Seconds $RetryWaitInSeconds
                    }
                }
            }
        }
        return ""
    }
`n}
