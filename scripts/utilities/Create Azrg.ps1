#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create Azure resource group

.DESCRIPTION
    Creates a new Azure resource group

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter()]
    [hashtable]$Tags
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function New-ResourceGroup {
    param(
        [Parameter(ValueFromPipeline)]
        [hashtable]$NewAzResourceGroupSplat
    )
    begin {
    }
    process {
        try {
            $ResourceGroupConfig = New-AzResourceGroup -ErrorAction Stop @NewAzResourceGroupSplat
        }
        catch {
            Write-Error "Failed to create resource group: $_"
            throw
        }
        finally {
        }
    }
    end {
        return $ResourceGroupConfig
    }
}

$params = @{
    Name = $ResourceGroupName
    Location = $Location
}

if ($Tags) {
    $params['Tag'] = $Tags
}

New-ResourceGroup -NewAzResourceGroupSplat $params