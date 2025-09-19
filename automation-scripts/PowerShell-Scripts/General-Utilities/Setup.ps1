#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Setup

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Setup

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    $mail,
    $publicdnsname,
    $adminPwd,
    $basePath,
    $publicSshKey
)

#region Functions

$WEProgressPreference = 'SilentlyContinue' 


Get-Disk -ErrorAction Stop | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem NTFS -Confirm:$false -Force
New-Item -Path f:\le -ItemType Directory | Out-Null
New-Item -Path f:\le\acme.json | Out-Null
New-Item -Path f:\dockerdata -ItemType Directory | Out-Null
New-Item -Path f:\portainerdata -ItemType Directory | Out-Null
New-Item -Path f:\compose -ItemType Directory | Out-Null


[DownloadWithRetry]::DoDownloadWithRetry(" https://chocolatey.org/install.ps1" , 5, 10, $null, " .\chocoInstall.ps1" , $false)
& .\chocoInstall.ps1
choco feature enable -n allowGlobalConfirmation
choco install --no-progress --limit-output vim
choco install --no-progress --limit-output pwsh
choco install --no-progress --limit-output openssh -params '" /SSHServerFeature" '


Copy-Item " $basePath\sshd_config_wopwd" 'C:\ProgramData\ssh\sshd_config'; 
$path = " c:\ProgramData\ssh\administrators_authorized_keys"
" $publicSshKey" | Out-File -Encoding utf8 -FilePath $path; 
$acl = Get-Acl -Path $path
$acl.SetSecurityDescriptorSddlForm(" O:BAD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)" )
Set-Acl -Path $path -AclObject $acl
New-ItemProperty -Path " HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value " C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force
'[CmdletBinding()]
function prompt { " PS [$env:COMPUTERNAME]:$($executionContext.SessionState.Path.CurrentLocation)$(''>'' * ($nestedPromptLevel + 1)) " }' | Out-File -FilePath " $($WEPROFILE.AllUsersAllHosts)" -Encoding utf8
Restart-Service sshd


Stop-Service docker
$dockerDaemonConfig = @"
{
    `" data-root`" : `" f:\\dockerdata`"
}
" @
$dockerDaemonConfig | Out-File " c:\programdata\docker\config\daemon.json" -Encoding ascii

Remove-Item -ErrorAction Stop 'f:\dockerdata\panic.lo -Forceg -Force' -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ErrorAction Stop 'f:\dockerdata\panic.log' -ItemType File -ErrorAction SilentlyContinue | Out-Null

Add-MpPreference -ExclusionPath '${env:ProgramFiles}\docker\'
Add-MpPreference -ExclusionPath 'f:\dockerdata'
Start-Service docker


$adminPwd | Out-File -NoNewline -Encoding ascii " f:\portainerdata\passwordfile"


[DownloadWithRetry]::DoDownloadWithRetry(" https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Windows-x86_64.exe" , 5, 10, $null, " $($WEEnv:ProgramFiles)\Docker\docker-compose.exe" , $false)

$template = Get-Content -ErrorAction Stop (Join-Path $basepath 'docker-compose.yml.template') -Raw
$expanded = Invoke-Expression " @`" `r`n$template`r`n`" @"
$expanded | Out-File " f:\compose\docker-compose.yml" -Encoding ASCII

Set-Location -ErrorAction Stop " f:\compose"
Invoke-Expression " docker-compose up -d"

class DownloadWithRetry {
    static [string] DoDownloadWithRetry([string] $uri, [int] $maxRetries, [int] $retryWaitInSeconds, [string] $authToken, [string] $outFile, [bool] $metadata) {
        $retryCount = 0
        $headers = @{}
        if (-not ([string]::IsNullOrEmpty($authToken))) {
            $headers = @{
                'Authorization' = $authToken
            }
        }
        if ($metadata) {
            $headers.Add('Metadata', 'true')
        }

        while ($retryCount -le $maxRetries) {
            try {
                if ($headers.Count -ne 0) {
                    if ([string]::IsNullOrEmpty($outFile)) {
                       ;  $result = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing
                        return $result.Content
                    }
                    else {
                       ;  $result = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing -OutFile $outFile
                        return ""
                    }
                }
                else {
                    throw;
                }
            }
            catch {
                if ($headers.Count -ne 0) {
                    Write-Information " download of $uri failed"
                }
                try {
                    if ([string]::IsNullOrEmpty($outFile)) {
                        $result = Invoke-WebRequest -Uri $uri -UseBasicParsing
                        return $result.Content
                    }
                    else {
                       ;  $result = Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile $outFile
                        return ""
                    }
                }
                catch {
                    Write-Information " download of $uri failed"
                    $retryCount++;
                    if ($retryCount -le $maxRetries) {
                        Start-Sleep -Seconds $retryWaitInSeconds
                    }            
                }
            }
        }
        return ""
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
