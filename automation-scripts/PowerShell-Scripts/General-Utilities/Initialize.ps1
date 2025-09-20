<#
.SYNOPSIS
    Initialize

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    $publicSshKey
)
$ProgressPreference = 'SilentlyContinue'
[DownloadWithRetry]::DoDownloadWithRetry(" https://chocolatey.org/install.ps1" , 5, 10, $null, ".\chocoInstall.ps1" , $false)
& .\chocoInstall.ps1
choco feature enable -n allowGlobalConfirmation
choco install --no-progress --limit-output vim
choco install --no-progress --limit-output pwsh
choco install --no-progress --limit-output openssh -params '" /SSHServerFeature" '
Copy-Item '.\sshd_config_wopwd' 'C:\ProgramData\ssh\sshd_config';
$path = " c:\ProgramData\ssh\administrators_authorized_keys"
" $publicSshKey" | Out-File -Encoding utf8 -FilePath $path;
$acl = Get-Acl -Path $path
$acl.SetSecurityDescriptorSddlForm("O:BAD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)" )
Set-Acl -Path $path -AclObject $acl
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force
'[CmdletBinding()]
function prompt { "PS [$env:COMPUTERNAME]:$($executionContext.SessionState.Path.CurrentLocation)$(''>'' * ($nestedPromptLevel + 1)) " }' | Out-File -FilePath " $($PROFILE.AllUsersAllHosts)" -Encoding utf8
Get-Disk -ErrorAction Stop | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem NTFS -Confirm:$false -Force
Restart-Service sshd
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
$result = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing
                        return $result.Content
                    }
                    else {
$result = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing -OutFile $outFile
                        return ""
                    }
                }
                else {
                    throw;

} catch {
                if ($headers.Count -ne 0) {
                    Write-Host " download of $uri failed"
                }
                try {
                    if ([string]::IsNullOrEmpty($outFile)) {
                        $result = Invoke-WebRequest -Uri $uri -UseBasicParsing
                        return $result.Content
                    }
                    else {
$result = Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile $outFile
                        return ""

} catch {
                    Write-Host " download of $uri failed"
                    $retryCount++;
                    if ($retryCount -le $maxRetries) {
                        Start-Sleep -Seconds $retryWaitInSeconds
                    }
                }
            }
        }
        return ""
    }
}\n