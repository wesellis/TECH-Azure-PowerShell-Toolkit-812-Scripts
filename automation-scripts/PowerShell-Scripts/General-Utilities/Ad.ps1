<#
.SYNOPSIS
    Ad

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter()]
    $userName,
    [Parameter()]
    $password,
    [Parameter()]
    $authType,
    [Parameter()]
    $adouPath,
    [Parameter()]
    $ip,
    [Parameter()]
    $port,
    [Parameter()]
    $domainFqdn,
    [Parameter()]
    $ifdeleteadou,
    [Parameter()]
    $deploymentUserName,
    [Parameter()]
    $deploymentUserPassword
)
$script:ErrorActionPreference = 'Stop';
$count = 0
for ($count = 0; $count -lt 6; $count++) {
    try {
        $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
        $domainShort = $domainFqdn.Split(" ." )[0]
        $cred = New-Object -ErrorAction Stop System.Management.Automation.PSCredential -ArgumentList " $domainShort\$username" ,
    [Parameter()]
    $secpasswd
        if ($authType -eq "CredSSP" ) {
            try {
                Enable-WSManCredSSP -Role Client -DelegateComputer $ip -Force
            }
            catch {
                echo "Enable-WSManCredSSP failed"
            }
        }
        $session = New-PSSession -ComputerName $ip -Port $port -Authentication $authType -Credential $cred
        if ($ifdeleteadou) {
            Invoke-Command -Session $session -ScriptBlock {
                $OUPrefixList = @("OU=Computers," , "OU=Users," , "" )
                foreach ($prefix in $OUPrefixList) {
                    $ouname = " $prefix$Using:adouPath"
                    echo " try to get OU: $ouname"
                    Try {
                        $ou = Get-ADOrganizationalUnit -Identity $ouname
                    }
                    Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                        $ou = $null
                    }
                    if ($ou) {
                        Set-ADOrganizationalUnit -Identity $ouname -ProtectedFromAccidentalDeletion $false
                        $ou | Remove-ADOrganizationalUnit -Recursive -Confirm:$False
                        echo "Deleted adou: $ouname"
                    }
                }
            }
        }
$deploymentSecPasswd = ConvertTo-SecureString $deploymentUserPassword -AsPlainText -Force
$lcmCred = New-Object -ErrorAction Stop System.Management.Automation.PSCredential -ArgumentList $deploymentUserName,
    [Parameter()]
    $deploymentSecPasswd
        Invoke-Command -Session $session -ScriptBlock {
            echo "Install Nuget Provider"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
            echo "Install AsHciADArtifactsPreCreationTool"
            Install-Module AsHciADArtifactsPreCreationTool -Repository PSGallery -Force -Confirm:$false
            echo "Add KdsRootKey"
            Add-KdsRootKey -EffectiveTime ((Get-Date).addhours(-10))
            echo "New HciAdObjectsPreCreation"
            New-HciAdObjectsPreCreation -AzureStackLCMUserCredential $Using:lcmCred -AsHciOUName $Using:adouPath
        }
        break
    }
    catch {
        echo "Error in retry ${count}:`n$_"
        sleep 600
    }
    finally {
        if ($session) {
            Remove-PSSession -Session $session
        }
    }
}
if ($count -ge 6) {
    throw "Failed to provision AD after 6 retries."
}\n

