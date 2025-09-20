<#
.SYNOPSIS
    Generate password

.DESCRIPTION
    Generate secure random password
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
    $randomIndices = 1..$length | ForEach-Object { Get-Random -Maximum $characters.Length }
    return -join $characters[$randomIndices]
}

function Scramble-String {
    param([string]$inputString)
    $characterArray = $inputString.ToCharArray()
    $scrambledArray = $characterArray | Get-Random -Count $characterArray.Length
    return (-join $scrambledArray).Replace(" ", "")
}

# Character sets
$charSets = @(
    "abcdefghiklmnoprstuvwxyz",
    "ABCDEFGHKLMNOPRSTUVWXYZ",
    "1234567890",
    '`~!@#$%^&*()_+-={}|[]\:";<>?,.'
)

# Get characters from each set
$lengthPerSet = [Math]::Floor($Length / 4)
$passwordParts = foreach ($charSet in $charSets) {
    Get-RandomCharacters -length $lengthPerSet -characters $charSet
}

# Scramble and return
$password = Scramble-String (-join $passwordParts)

# Ensure exact length
if ($password.Length -lt $Length) {
    $allChars = -join $charSets
    $password += Get-RandomCharacters -length ($Length - $password.Length) -characters $allChars
}

Write-Output $password.Substring(0, $Length)

