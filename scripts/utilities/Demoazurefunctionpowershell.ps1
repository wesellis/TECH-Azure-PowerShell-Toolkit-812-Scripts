#Requires -Version 7.4
#Requires -Modules Az.Resources, Microsoft.Graph.Users

<#
.SYNOPSIS
    Demo Azure Function PowerShell

.DESCRIPTION
    Azure automation demo script for creating Azure AD users
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER DisplayName
    Display name for the new user

.PARAMETER GivenName
    Given name for the new user

.PARAMETER SurName
    Surname for the new user

.PARAMETER UserPrincipalName
    User principal name for the new user

.PARAMETER MailNickName
    Mail nickname for the new user

.EXAMPLE
    PS C:\> .\Demoazurefunctionpowershell.ps1 -DisplayName "Test User" -GivenName "Test" -SurName "User" -UserPrincipalName "testuser@domain.com" -MailNickName "testuser"
    Creates a new Azure AD user with the specified parameters

.INPUTS
    String parameters for user creation

.OUTPUTS
    User object information

.NOTES
    This script demonstrates Azure Function PowerShell capabilities
    Requires appropriate Azure AD permissions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DisplayName = "testAzFuncPSUserDisplayName",

    [Parameter(Mandatory = $false)]
    [string]$GivenName = "testAzFuncPSUserGivenName",

    [Parameter(Mandatory = $false)]
    [string]$SurName = "testAzFuncPSUsersurname",

    [Parameter(Mandatory = $false)]
    [string]$UserPrincipalName = 'testAzFuncPSUser@canadacomputing.ca',

    [Parameter(Mandatory = $false)]
    [string]$MailNickName = 'testAzFuncPSUser'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    # Create password profile
    $PasswordProfile = @{
        Password = $env:CREDENTIAL_Password
        ForceChangePasswordNextSignIn = $false
    }

    # Create new user parameters
    $UserParams = @{
        DisplayName = $DisplayName
        GivenName = $GivenName
        Surname = $SurName
        UserPrincipalName = $UserPrincipalName
        UsageLocation = 'CA'
        MailNickname = $MailNickName
        PasswordProfile = $PasswordProfile
        AccountEnabled = $true
    }

    # Create the user using Microsoft Graph
    $NewUser = New-MgUser @UserParams
    Write-Output "Successfully created user: $($NewUser.UserPrincipalName)"
    return $NewUser
}
catch {
    Write-Error "Failed to create user: $($_.Exception.Message)"
    throw
}