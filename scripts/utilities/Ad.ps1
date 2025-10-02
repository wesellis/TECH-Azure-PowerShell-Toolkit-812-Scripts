#Requires -Version 7.4
#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Active Directory automation for Azure Stack HCI

.DESCRIPTION
    Azure Stack HCI Active Directory automation script

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserName,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Basic', 'Negotiate', 'Kerberos', 'CredSSP')]
    [string]$AuthType,

    [Parameter(Mandatory = $true)]
    [string]$AdouPath,

    [Parameter(Mandatory = $true)]
    [string]$IP,

    [Parameter()]
    [int]$Port = 5985,

    [Parameter(Mandatory = $true)]
    [string]$DomainFqdn,

    [Parameter()]
    [switch]$DeleteAdou,

    [Parameter(Mandatory = $true)]
    [string]$DeploymentUserName,

    [Parameter(Mandatory = $true)]
    [string]$DeploymentUserPassword
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$retryCount = 0
$maxRetries = 6

for ($retryCount = 0; $retryCount -lt $maxRetries; $retryCount++) {
    try {
        $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $domainShort = $DomainFqdn.Split('.')[0]
        $credential = New-Object System.Management.Automation.PSCredential("$domainShort\$UserName", $securePassword)

        if ($AuthType -eq "CredSSP") {
            try {
                Enable-WSManCredSSP -Role Client -DelegateComputer $IP -Force
            }
            catch {
                Write-Warning "Enable-WSManCredSSP failed: $($_.Exception.Message)"
            }
        }

        $session = New-PSSession -ComputerName $IP -Port $Port -Authentication $AuthType -Credential $credential

        if ($DeleteAdou) {
            Invoke-Command -Session $session -ScriptBlock {
                $ouPrefixList = @("OU=Computers,", "OU=Users,", "")
                foreach ($prefix in $ouPrefixList) {
                    $ouName = "$prefix$Using:AdouPath"
                    Write-Output "Attempting to get OU: $ouName"
                    try {
                        $ou = Get-ADOrganizationalUnit -Identity $ouName
                    }
                    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                        $ou = $null
                    }
                    if ($ou) {
                        Set-ADOrganizationalUnit -Identity $ouName -ProtectedFromAccidentalDeletion $false
                        $ou | Remove-ADOrganizationalUnit -Recursive -Confirm:$false
                        Write-Output "Deleted OU: $ouName"
                    }
                }
            }
        }

        $deploymentSecurePassword = ConvertTo-SecureString $DeploymentUserPassword -AsPlainText -Force
        $lcmCredential = New-Object System.Management.Automation.PSCredential($DeploymentUserName, $deploymentSecurePassword)

        Invoke-Command -Session $session -ScriptBlock {
            Write-Output "Installing NuGet Provider"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false

            Write-Output "Installing AsHciADArtifactsPreCreationTool"
            Install-Module AsHciADArtifactsPreCreationTool -Repository PSGallery -Force -Confirm:$false

            Write-Output "Adding KdsRootKey"
            Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))

            Write-Output "Creating HCI AD Objects"
            New-HciAdObjectsPreCreation -AzureStackLCMUserCredential $Using:lcmCredential -AsHciOUName $Using:AdouPath
        }
        break
    }
    catch {
        Write-Warning "Error in retry $retryCount : $($_.Exception.Message)"
        Start-Sleep 600
    }
    finally {
        if ($session) {
            Remove-PSSession -Session $session
        }
    }
}

if ($retryCount -ge $maxRetries) {
    throw "Failed to provision AD after $maxRetries retries."
}