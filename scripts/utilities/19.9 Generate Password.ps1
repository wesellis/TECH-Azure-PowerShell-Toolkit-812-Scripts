#Requires -Version 7.4

<#
.SYNOPSIS
    Generate password

.DESCRIPTION
    Generate secure random password

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [int]$Length
)

$ErrorActionPreference = "Stop"

function Get-RandomCharacters {
    param(
        [int]$length,
        [string]$characters
    )
    $RandomIndices = 1..$length | ForEach-Object { Get-Random -Maximum $characters.Length }
    return -join $characters[$RandomIndices]
}

function Scramble-String {
    param([string]$InputString)
    $CharacterArray = $InputString.ToCharArray()
    $ScrambledArray = $CharacterArray | Get-Random -Count $CharacterArray.Length
    return (-join $ScrambledArray).Replace(" ", "")
}

$CharSets = @(
    "abcdefghiklmnoprstuvwxyz",
    "ABCDEFGHKLMNOPRSTUVWXYZ",
    "1234567890",
    '`~!@#$%^&*()_+-={}|[]\:";<>?,.'
)

$LengthPerSet = [Math]::Floor($Length / 4)
$PasswordParts = foreach ($CharSet in $CharSets) {
    Get-RandomCharacters -length $LengthPerSet -characters $CharSet
}

$password = Scramble-String (-join $PasswordParts)

if ($password.Length -lt $Length) {
    $AllChars = -join $CharSets
    $password += Get-RandomCharacters -length ($Length - $password.Length) -characters $AllChars
}

Write-Output $password.Substring(0, $Length)