#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Get Principal Object ID

.DESCRIPTION
    Gets the principal object ID for Azure automation operations

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER PrincipalName
    Name of the principal to get object ID for

.PARAMETER PrincipalType
    Type of principal (User, Group, ServicePrincipal)

.EXAMPLE
    .\Getprincipalobjectid.ps1 -PrincipalName "myuser@domain.com" -PrincipalType "User"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PrincipalName,

    [Parameter(Mandatory = $false)]
    [ValidateSet("User", "Group", "ServicePrincipal")]
    [string]$PrincipalType = "User"
)

$ErrorActionPreference = 'Stop'

try {
    switch ($PrincipalType) {
        "User" {
            $principal = Get-AzADUser -UserPrincipalName $PrincipalName
        }
        "Group" {
            $principal = Get-AzADGroup -DisplayName $PrincipalName
        }
        "ServicePrincipal" {
            $principal = Get-AzADServicePrincipal -DisplayName $PrincipalName
        }
    }

    if ($principal) {
        Write-Output "Principal Object ID: $($principal.Id)"
        return $principal.Id
    } else {
        Write-Error "Principal '$PrincipalName' of type '$PrincipalType' not found"
    }
} catch {
    Write-Error "Failed to get principal object ID: $($_.Exception.Message)"
    throw
}