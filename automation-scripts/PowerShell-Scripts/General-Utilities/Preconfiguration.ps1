<#
.SYNOPSIS
    Preconfiguration

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Preconfiguration

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
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
    #$WEOUDistinguishedName = " DC=contoso,DC=com"
    [string] [Parameter(Mandatory=$true)] $WEDomainDistinguishedName,
    #$WEParentOrganizationUnitName = " AzureVirtualDesktop"
    [string] [Parameter(Mandatory=$true)] $WEParentOrganizationUnitName,
    #$WEStorageAccountOrganizationUnitName = " StorageAccounts"
    [string] [Parameter(Mandatory=$true)] $WEStorageAccountOrganizationUnitName,
    #$WEAVDOrganizationUnitName = " AVD-Objects"
    [string] [Parameter(Mandatory=$true)] $WEAVDOrganizationUnitName,
    #$WEAVDChildOrganizationUnitNames = @(" Groups" , " SessionHosts" , " Users" )
    [stringp[]] [Parameter(Mandatory=$true)] $WEAVDChildOrganizationUnitNames
)

Function Set-DomainOrganizationUnits {
    

function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [string] [Parameter(Mandatory=$true)] $WEOUDistinguishedName,
        [string] [Parameter(Mandatory=$true)] $WEParentOU,
        [string] [Parameter(Mandatory=$true)] $WEStorageAccountOUName,
        [string] [Parameter(Mandatory=$true)] $WEAVDOUName,
        [stringp[]] [Parameter(Mandatory=$true)] $WEAVDChildOUNames
    )
    

    $WEGetExistingOU = Get-ADOrganizationalUnit -Filter 'Name -like " *" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $WEParentOU}
    $WEAVDOU = Get-ADOrganizationalUnit -Filter 'Name -like " *" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $WEAVDOUName}
    $WEStorageAccountOU = Get-ADOrganizationalUnit -Filter 'Name -like " *" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $WEStorageAccountOUName}
    if( $WEGetExistingOU ){
        Write-WELog " Organization Unit $($WEParentOu) already exist" " INFO"
        if( ! ($WEAVDOU) ){
            New-ADOrganizationalUnit -Name $WEAVDOUName -Path $WEGetExistingOU.DistinguishedName -ProtectedFromAccidentalDeletion $false
            $WEAVDOUDistinguishedName = (Get-ADOrganizationalUnit -Filter 'Name -like " *" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $WEAVDOUName}).DistinguishedName
        }
        else{
            $WEAVDOUDistinguishedName = $WEAVDOU.DistinguishedName
        }

        if( ! ($WEStorageAccountOU) ){
            New-ADOrganizationalUnit -Name $WEStorageAccountOUName -Path $WEGetExistingOU.DistinguishedName -ProtectedFromAccidentalDeletion $false
        }
    }
    else {
        New-ADOrganizationalUnit -Name $WEParentOU -Path $WEOUDistinguishedName -ProtectedFromAccidentalDeletion $false

       ;  $WEParentOODistinguishedName = (Get-ADOrganizationalUnit -Filter 'Name -like " *" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $WEParentOU}).DistinguishedName

        New-ADOrganizationalUnit -Name $WEAVDOUName -Path $WEParentOODistinguishedName -ProtectedFromAccidentalDeletion $false
        New-ADOrganizationalUnit -Name $WEStorageAccountOUName -Path $WEParentOODistinguishedName -ProtectedFromAccidentalDeletion $false
       ;  $WEAVDOUDistinguishedName = (Get-ADOrganizationalUnit -Filter 'Name -like " *" ' -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $WEAVDOUName}).DistinguishedName
        
        ForEach($WEAVDChildOUName in $WEAVDChildOUNames){
            New-ADOrganizationalUnit -Name $WEAVDChildOUName -Path $WEAVDOUDistinguishedName -ProtectedFromAccidentalDeletion $false
        }
    }


    #Write-Output $WEAVDOUDistinguishedName
    #Write-Output $WEStorageAccountOUDistinguishedName
    #
    #$WEDeploymentScriptOutputs = @{}
    #$WEDeploymentScriptOutputs['AVDOUDistinguishedName'] = $WEAVDOUDistinguishedName
    #$WEDeploymentScriptOutputs['StorageAccountOUDistinguishedName'] = $WEStorageAccountOUDistinguishedName
}

Set-DomainOrganizationUnits `
    -OUDistinguishedName $WEDomainDistinguishedName `
    -ParentOU $WEParentOrganizationUnitName `
    -StorageAccountOUName $WEStorageAccountOrganizationUnitName `
    -AVDOUName $WEAVDOrganizationUnitName `
    -AVDChildOUNames $WEAVDChildOrganizationUnitNames


} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
