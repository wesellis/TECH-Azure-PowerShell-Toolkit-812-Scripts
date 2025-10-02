#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Storage

<#
.SYNOPSIS
    AVD Post-Configuration Script

.DESCRIPTION
    Azure Virtual Desktop post-configuration script that joins FSLogix Azure storage account
    to Active Directory, mounts storage, sets ACL permissions, and configures GPO for AVD users.
    This script must be run on a domain controller with administrator privileges.

.PARAMETER TenantId
    Azure AD tenant ID

.PARAMETER SubscriptionId
    Azure subscription ID

.PARAMETER ServicePrincipalAppId
    Service principal application ID for authentication

.PARAMETER ServicePrincipalSecret
    Service principal secret (secure string)

.PARAMETER DomainAccountType
    Type of domain account (ComputerAccount or ServiceLogonAccount)

.PARAMETER ResourceGroupName
    Resource group containing the storage account

.PARAMETER StorageAccountName
    Name of the storage account for FSLogix profiles

.PARAMETER StorageAccountKey
    Storage account access key

.PARAMETER StorageAccountFileShareName
    Name of the file share for FSLogix profiles

.PARAMETER SamAccountName
    SAM account name for the storage account in AD

.PARAMETER DomainName
    Active Directory domain name

.PARAMETER StorageAccountOUDistinguishedName
    Distinguished name of the OU for the storage account

.PARAMETER ElevatedAdminGroup
    AD group with elevated admin permissions

.PARAMETER UserGroup
    AD group for AVD users

.PARAMETER SessionHostsOUDistinguishedName
    Distinguished name of the OU for session hosts

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires PowerShell 5.1 or later on domain controller
    Requires appropriate AD and Azure permissions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ServicePrincipalAppId,

    [Parameter(Mandatory = $true)]
    [securestring]$ServicePrincipalSecret,

    [Parameter(Mandatory = $false)]
    [ValidateSet("ComputerAccount", "ServiceLogonAccount")]
    [string]$DomainAccountType = "ComputerAccount",

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountKey,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountFileShareName,

    [Parameter(Mandatory = $true)]
    [string]$SamAccountName,

    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountOUDistinguishedName,

    [Parameter(Mandatory = $true)]
    [string]$ElevatedAdminGroup,

    [Parameter(Mandatory = $true)]
    [string]$UserGroup,

    [Parameter(Mandatory = $true)]
    [string]$SessionHostsOUDistinguishedName
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Starting AVD post-configuration..."

    # Connect to Azure
    Write-Output "Connecting to Azure..."
    $pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServicePrincipalAppId, $ServicePrincipalSecret
    Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $TenantId
    Select-AzSubscription -SubscriptionId $SubscriptionId

    # Join storage account to AD
    Write-Output "Checking storage account AD join status..."
    if (Get-Command -Name 'Join-AzStorageAccount' -Module 'AzFilesHybrid' -ErrorAction SilentlyContinue) {
        if (Get-AzStorageAccountADObject -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue) {
            Write-Output "Azure Storage account is already joined to Active Directory domain."
        }
        else {
            Write-Output "Joining storage account to AD..."
            $params = @{
                SamAccountName = $SamAccountName
                OrganizationalUnitDistinguishedName = $StorageAccountOUDistinguishedName
                DomainAccountType = $DomainAccountType
                ResourceGroupName = $ResourceGroupName
                StorageAccountName = $StorageAccountName
            }
            Join-AzStorageAccount @params
            Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose
        }
    }
    else {
        Write-Output "Installing AzFilesHybrid module..."
        $azFilesPath = "C:\AzFilesHybrid"
        $azFilesZip = "C:\AzFilesHybrid.zip"

        Invoke-WebRequest -Uri 'https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.3.2/AzFilesHybrid.zip' -OutFile $azFilesZip
        Expand-Archive -LiteralPath $azFilesZip -DestinationPath $azFilesPath
        Remove-Item -Path $azFilesZip -Force

        Push-Location $azFilesPath
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
        .\CopyToPSPath.ps1
        Import-Module -Name AzFilesHybrid
        Pop-Location

        Write-Output "Joining storage account to AD..."
        $params = @{
            SamAccountName = $SamAccountName
            OrganizationalUnitDistinguishedName = $StorageAccountOUDistinguishedName
            DomainAccountType = $DomainAccountType
            ResourceGroupName = $ResourceGroupName
            StorageAccountName = $StorageAccountName
        }
        Join-AzStorageAccount @params
        Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose
    }

    # Test connection to storage account
    Write-Output "Testing connection to storage account..."
    $storageEndpoint = "$StorageAccountName.file.core.windows.net"
    $ConnectTestResult = Test-NetConnection -ComputerName $storageEndpoint -Port 445

    if ($ConnectTestResult.TcpTestSucceeded) {
        Write-Output "Connection successful. Mounting storage..."

        # Add credentials and mount drive
        cmd.exe /C "cmdkey /add:`"$storageEndpoint`" /user:`"localhost\$StorageAccountName`" /pass:`"$StorageAccountKey`""
        New-PSDrive -Name Y -PSProvider FileSystem -Root "\\$storageEndpoint\$StorageAccountFileShareName" -Persist

        # Set ACL permissions
        Write-Output "Setting ACL permissions..."
        $Folder = "Y:\"
        $UserAccesses = @(
            "$DomainName\Domain Admins;FullControl;ContainerInherit,ObjectInherit",
            "$DomainName\$ElevatedAdminGroup;FullControl;ContainerInherit,ObjectInherit",
            "$DomainName\$UserGroup;Modify,Synchronize;None"
        )

        $Acl = Get-Acl -Path $Folder
        foreach ($UserAccess in $UserAccesses) {
            $SplitObject = $UserAccess.Split(";")
            $Access = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $SplitObject[0],
                $SplitObject[1],
                $SplitObject[2],
                'None',
                'Allow'
            )
            $Acl.AddAccessRule($Access)
        }
        Set-Acl -AclObject $Acl -Path $Folder
        Write-Output "ACL permissions set successfully."
    }
    else {
        throw "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
    }

    # Download and install FSLogix
    Write-Output "Downloading FSLogix..."
    $fslogixPath = "C:\FSLogix"
    $fslogixZip = "C:\FSLogix.zip"

    Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile $fslogixZip
    Expand-Archive -LiteralPath $fslogixZip -DestinationPath $fslogixPath
    Remove-Item -Path $fslogixZip -Force

    # Copy GPO templates
    Write-Output "Copying GPO templates..."
    Copy-Item "$fslogixPath\fslogix.admx" -Destination "C:\Windows\PolicyDefinitions"
    Copy-Item "$fslogixPath\fslogix.adml" -Destination "C:\Windows\PolicyDefinitions\en-US"

    # Create and configure GPO
    Write-Output "Creating and configuring AVD GPO..."
    $gpoName = "AVD-GPO"

    if (-not (Get-GPO -Name $gpoName -ErrorAction SilentlyContinue)) {
        New-GPO -Name $gpoName -Comment "AVD FSLogix Configuration GPO"
    }

    New-GPLink -Name $gpoName -Target $SessionHostsOUDistinguishedName -LinkEnabled Yes -ErrorAction SilentlyContinue

    # Configure FSLogix registry values
    $vhdLocation = "\\$storageEndpoint\$StorageAccountFileShareName"

    $registrySettings = @{
        "Enabled" = @{Value = 1; Type = "DWord"}
        "DeleteLocalProfileWhenVHDShouldApply" = @{Value = 1; Type = "DWord"}
        "FlipFlopProfileDirectoryName" = @{Value = 1; Type = "DWord"}
        "LockedRetryCount" = @{Value = 3; Type = "DWord"}
        "LockedRetryInterval" = @{Value = 15; Type = "DWord"}
        "ProfileType" = @{Value = 0; Type = "DWord"}
        "ReAttachIntervalSeconds" = @{Value = 15; Type = "DWord"}
        "ReAttachRetryCount" = @{Value = 3; Type = "DWord"}
        "SizeInMBs" = @{Value = 30000; Type = "DWord"}
        "VHDLocations" = @{Value = $vhdLocation; Type = "String"}
        "VolumeType" = @{Value = "VHDX"; Type = "String"}
    }

    foreach ($setting in $registrySettings.GetEnumerator()) {
        Set-GPRegistryValue -Name $gpoName `
            -Key "HKEY_LOCAL_MACHINE\SOFTWARE\FSLogix\Profiles" `
            -ValueName $setting.Key `
            -Value $setting.Value.Value `
            -Type $setting.Value.Type
    }

    Write-Output "AVD post-configuration completed successfully!"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}