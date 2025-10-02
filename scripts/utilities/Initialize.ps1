#Requires -Version 7.4

<#
.SYNOPSIS
    Initialize system with SSH and PowerShell configuration

.DESCRIPTION
    Azure automation script that initializes a system by installing Chocolatey, PowerShell Core, OpenSSH,
    and configures SSH access with the provided public key

.PARAMETER PublicSshKey
    The SSH public key to configure for administrator access

.EXAMPLE
    .\Initialize.ps1 -PublicSshKey "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC..."
    Initializes the system with the specified SSH public key

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$PublicSshKey
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

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
                    if ([string]::IsNullOrEmpty($OutFile)) {
                        $result = Invoke-WebRequest -Uri $uri -UseBasicParsing
                        return $result.Content
                    }
                    else {
                        $result = Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile $OutFile
                        return ""
                    }
                }
            }
            catch {
                Write-Output "Download of $uri failed"
                $RetryCount++
                if ($RetryCount -le $MaxRetries) {
                    Start-Sleep -Seconds $RetryWaitInSeconds
                }
            }
        }
        return ""
    }
}

# Download and install Chocolatey
[DownloadWithRetry]::DoDownloadWithRetry("https://chocolatey.org/install.ps1", 5, 10, $null, ".\chocoInstall.ps1", $false)
& .\chocoInstall.ps1

# Configure Chocolatey
choco feature enable -n allowGlobalConfirmation

# Install packages
choco install --no-progress --limit-output vim
choco install --no-progress --limit-output pwsh
choco install --no-progress --limit-output openssh -params '"/SSHServerFeature"'

# Configure SSH
Copy-Item '.\sshd_config_wopwd' 'C:\ProgramData\ssh\sshd_config'

if ($PublicSshKey) {
    $path = "c:\ProgramData\ssh\administrators_authorized_keys"
    $PublicSshKey | Out-File -Encoding utf8 -FilePath $path
    $acl = Get-Acl -Path $path
    $acl.SetSecurityDescriptorSddlForm("O:BAD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)")
    Set-Acl -Path $path -AclObject $acl
}

# Set PowerShell as default shell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force

# Configure PowerShell prompt
'function prompt { "PS [$env:COMPUTERNAME]:$($ExecutionContext.SessionState.Path.CurrentLocation)$(''> '' * ($NestedPromptLevel + 1)) " }' | Out-File -FilePath $PROFILE.AllUsersAllHosts -Encoding utf8

# Initialize and format any raw disks
Get-Disk -ErrorAction SilentlyContinue | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -UseMaximumSize -DriveLetter F | Format-Volume -FileSystem NTFS -Confirm:$false -Force

# Restart SSH service
Restart-Service sshd