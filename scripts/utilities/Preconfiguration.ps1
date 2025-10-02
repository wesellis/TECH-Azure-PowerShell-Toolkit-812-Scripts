#Requires -Version 7.4
#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    AVD Pre-Configuration Script

.DESCRIPTION
    Azure Virtual Desktop pre-configuration script that creates Active Directory
    organizational units (OUs) for AVD resources. This includes parent OU and
    child OUs for storage accounts and AVD session hosts.
    Must be run on a domain controller with administrator privileges.

.PARAMETER DomainDistinguishedName
    Distinguished name of the domain (e.g., "DC=contoso,DC=com")

.PARAMETER ParentOrganizationUnitName
    Name of the parent OU for AVD resources

.PARAMETER StorageAccountOrganizationUnitName
    Name of the OU for storage accounts

.PARAMETER AVDOrganizationUnitName
    Name of the OU for AVD resources

.PARAMETER AVDChildOrganizationUnitNames
    Array of child OU names under the AVD OU

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires Active Directory module
    Must be run on domain controller with admin privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainDistinguishedName,

    [Parameter(Mandatory = $true)]
    [string]$ParentOrganizationUnitName,

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountOrganizationUnitName,

    [Parameter(Mandatory = $true)]
    [string]$AVDOrganizationUnitName,

    [Parameter(Mandatory = $true)]
    [string[]]$AVDChildOrganizationUnitNames
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }

    $LogEntry = "$timestamp [AVD-PreConfig] [$Level] $Message"

    switch ($Level) {
        "ERROR" { Write-Host $LogEntry -ForegroundColor $ColorMap[$Level] }
        "WARN" { Write-Warning $LogEntry }
        "SUCCESS" { Write-Host $LogEntry -ForegroundColor $ColorMap[$Level] }
        default { Write-Information $LogEntry -InformationAction Continue }
    }
}

function Set-DomainOrganizationUnits {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OUDistinguishedName,

        [Parameter(Mandatory = $true)]
        [string]$ParentOU,

        [Parameter(Mandatory = $true)]
        [string]$StorageAccountOUName,

        [Parameter(Mandatory = $true)]
        [string]$AVDOUName,

        [Parameter(Mandatory = $true)]
        [string[]]$AVDChildOUNames
    )

    try {
        Write-Log "Starting OU creation process..." -Level INFO

        # Check if parent OU exists
        $GetExistingOU = Get-ADOrganizationalUnit -Filter "Name -eq '$ParentOU'" -ErrorAction SilentlyContinue

        if ($GetExistingOU) {
            Write-Log "Organization Unit '$ParentOU' already exists" -Level INFO
            $ParentOUDistinguishedName = $GetExistingOU.DistinguishedName
        }
        else {
            Write-Log "Creating parent OU: $ParentOU" -Level INFO
            New-ADOrganizationalUnit -Name $ParentOU -Path $OUDistinguishedName -ProtectedFromAccidentalDeletion $false
            $ParentOUDistinguishedName = (Get-ADOrganizationalUnit -Filter "Name -eq '$ParentOU'").DistinguishedName
            Write-Log "Parent OU created successfully" -Level SUCCESS
        }

        # Check/Create AVD OU
        $AVDOU = Get-ADOrganizationalUnit -Filter "Name -eq '$AVDOUName'" -ErrorAction SilentlyContinue

        if (-not $AVDOU) {
            Write-Log "Creating AVD OU: $AVDOUName" -Level INFO
            New-ADOrganizationalUnit -Name $AVDOUName -Path $ParentOUDistinguishedName -ProtectedFromAccidentalDeletion $false
            $AVDOUDistinguishedName = (Get-ADOrganizationalUnit -Filter "Name -eq '$AVDOUName'").DistinguishedName
            Write-Log "AVD OU created successfully" -Level SUCCESS
        }
        else {
            Write-Log "AVD OU '$AVDOUName' already exists" -Level INFO
            $AVDOUDistinguishedName = $AVDOU.DistinguishedName
        }

        # Check/Create Storage Account OU
        $StorageAccountOU = Get-ADOrganizationalUnit -Filter "Name -eq '$StorageAccountOUName'" -ErrorAction SilentlyContinue

        if (-not $StorageAccountOU) {
            Write-Log "Creating Storage Account OU: $StorageAccountOUName" -Level INFO
            New-ADOrganizationalUnit -Name $StorageAccountOUName -Path $ParentOUDistinguishedName -ProtectedFromAccidentalDeletion $false
            Write-Log "Storage Account OU created successfully" -Level SUCCESS
        }
        else {
            Write-Log "Storage Account OU '$StorageAccountOUName' already exists" -Level INFO
        }

        # Create AVD child OUs
        foreach ($AVDChildOUName in $AVDChildOUNames) {
            $ChildOU = Get-ADOrganizationalUnit -Filter "Name -eq '$AVDChildOUName'" -SearchBase $AVDOUDistinguishedName -ErrorAction SilentlyContinue

            if (-not $ChildOU) {
                Write-Log "Creating AVD child OU: $AVDChildOUName" -Level INFO
                New-ADOrganizationalUnit -Name $AVDChildOUName -Path $AVDOUDistinguishedName -ProtectedFromAccidentalDeletion $false
                Write-Log "AVD child OU '$AVDChildOUName' created successfully" -Level SUCCESS
            }
            else {
                Write-Log "AVD child OU '$AVDChildOUName' already exists" -Level INFO
            }
        }

        Write-Log "OU structure creation completed successfully!" -Level SUCCESS
    }
    catch {
        Write-Log "Failed to create OU structure: $($_.Exception.Message)" -Level ERROR
        throw
    }
}

try {
    Write-Log "Starting AVD pre-configuration..." -Level INFO
    Write-Log "Domain: $DomainDistinguishedName" -Level INFO
    Write-Log "Parent OU: $ParentOrganizationUnitName" -Level INFO
    Write-Log "AVD OU: $AVDOrganizationUnitName" -Level INFO
    Write-Log "Storage OU: $StorageAccountOrganizationUnitName" -Level INFO
    Write-Log "Child OUs: $($AVDChildOrganizationUnitNames -join ', ')" -Level INFO

    # Verify Active Directory module is available
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        throw "Active Directory PowerShell module is not installed"
    }

    Import-Module ActiveDirectory -ErrorAction Stop

    # Create OU structure
    $params = @{
        OUDistinguishedName = $DomainDistinguishedName
        ParentOU = $ParentOrganizationUnitName
        StorageAccountOUName = $StorageAccountOrganizationUnitName
        AVDOUName = $AVDOrganizationUnitName
        AVDChildOUNames = $AVDChildOrganizationUnitNames
    }

    Set-DomainOrganizationUnits @params

    Write-Log "AVD pre-configuration completed successfully!" -Level SUCCESS
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level ERROR
    throw
}