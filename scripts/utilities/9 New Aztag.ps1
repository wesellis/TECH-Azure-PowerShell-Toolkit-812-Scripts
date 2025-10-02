#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create or update Azure resource tags

.DESCRIPTION
    Create or update Azure resource tags operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceId,

    [Parameter(Mandatory = $true)]
    [hashtable]$Tags,

    [Parameter()]
    [ValidateSet('Replace', 'Merge', 'Delete')]
    [string]$Operation = 'Replace'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

switch ($Operation) {
    'Replace' {
        New-AzTag -ResourceId $ResourceId -Tag $Tags -ErrorAction Stop
    }
    'Merge' {
        Update-AzTag -ResourceId $ResourceId -Tag $Tags -Operation Merge -ErrorAction Stop
    }
    'Delete' {
        Update-AzTag -ResourceId $ResourceId -Tag $Tags -Operation Delete -ErrorAction Stop
    }
}