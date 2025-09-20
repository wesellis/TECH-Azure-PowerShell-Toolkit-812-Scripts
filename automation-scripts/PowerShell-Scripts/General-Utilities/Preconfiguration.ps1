<#
.SYNOPSIS
    Preconfiguration

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Script will create Active directory parent OU and child OUs for Azure virtual desktop as a prerequisite.
    You can leverage on existing OUs if need be.
    Run this as a prerequisite and first step before deploying AVD resources.
    This script needs to be ran inside your onpremise domain controller as an administratrator.
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    # Define parameters
    #$OUDistinguishedName = "DC=contoso,DC=com"
    [string] [Parameter(Mandatory)] $DomainDistinguishedName,
    #$ParentOrganizationUnitName = "AzureVirtualDesktop"
    [string] [Parameter(Mandatory)] $ParentOrganizationUnitName,
    #$StorageAccountOrganizationUnitName = "StorageAccounts"
    [string] [Parameter(Mandatory)] $StorageAccountOrganizationUnitName,
    #$AVDOrganizationUnitName = "AVD-Objects"
    [string] [Parameter(Mandatory)] $AVDOrganizationUnitName,
    #$AVDChildOrganizationUnitNames = @("Groups" , "SessionHosts" , "Users" )
    [stringp[]] [Parameter(Mandatory)] $AVDChildOrganizationUnitNames
)
[CmdletBinding()]
Function Set-DomainOrganizationUnits -ErrorAction Stop {
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
        [string] [Parameter(Mandatory)] $OUDistinguishedName,
        [string] [Parameter(Mandatory)] $ParentOU,
        [string] [Parameter(Mandatory)] $StorageAccountOUName,
        [string] [Parameter(Mandatory)] $AVDOUName,
        [stringp[]] [Parameter(Mandatory)] $AVDChildOUNames
    )
    $GetExistingOU = Get-ADOrganizationalUnit -Filter 'Name -like "*" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $ParentOU}
    $AVDOU = Get-ADOrganizationalUnit -Filter 'Name -like "*" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $AVDOUName}
    $StorageAccountOU = Get-ADOrganizationalUnit -Filter 'Name -like "*" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $StorageAccountOUName}
    if( $GetExistingOU ){
        Write-Host "Organization Unit $($ParentOu) already exist"
        if( ! ($AVDOU) ){
            New-ADOrganizationalUnit -Name $AVDOUName -Path $GetExistingOU.DistinguishedName -ProtectedFromAccidentalDeletion $false
            $AVDOUDistinguishedName = (Get-ADOrganizationalUnit -Filter 'Name -like "*" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $AVDOUName}).DistinguishedName
        }
        else{
            $AVDOUDistinguishedName = $AVDOU.DistinguishedName
        }
        if( ! ($StorageAccountOU) ){
            New-ADOrganizationalUnit -Name $StorageAccountOUName -Path $GetExistingOU.DistinguishedName -ProtectedFromAccidentalDeletion $false
        }
    }
    else {
        New-ADOrganizationalUnit -Name $ParentOU -Path $OUDistinguishedName -ProtectedFromAccidentalDeletion $false
$ParentOODistinguishedName = (Get-ADOrganizationalUnit -Filter 'Name -like "*" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $ParentOU}).DistinguishedName
        New-ADOrganizationalUnit -Name $AVDOUName -Path $ParentOODistinguishedName -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name $StorageAccountOUName -Path $ParentOODistinguishedName -ProtectedFromAccidentalDeletion $false
$AVDOUDistinguishedName = (Get-ADOrganizationalUnit -Filter 'Name -like "*" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $AVDOUName}).DistinguishedName
        ForEach($AVDChildOUName in $AVDChildOUNames){
            New-ADOrganizationalUnit -Name $AVDChildOUName -Path $AVDOUDistinguishedName -ProtectedFromAccidentalDeletion $false
        }
    }
    #Write-Output $AVDOUDistinguishedName
    #Write-Output $StorageAccountOUDistinguishedName
    #
    #$DeploymentScriptOutputs = @{}
    #$DeploymentScriptOutputs['AVDOUDistinguishedName'] = $AVDOUDistinguishedName
    #$DeploymentScriptOutputs['StorageAccountOUDistinguishedName'] = $StorageAccountOUDistinguishedName
}
$params = @{
    StorageAccountOUName = $StorageAccountOrganizationUnitName
    ParentOU = $ParentOrganizationUnitName
    AVDChildOUNames = $AVDChildOrganizationUnitNames
    AVDOUName = $AVDOrganizationUnitName
    ErrorAction = "Stop"
    OUDistinguishedName = $DomainDistinguishedName
}
Set-DomainOrganizationUnits @params
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n