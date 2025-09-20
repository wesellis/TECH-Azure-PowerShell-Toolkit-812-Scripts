#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create Azure resource group

.DESCRIPTION
    Creates a new Azure resource group
.AUTHOR
    Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
[OutputType([PSObject])]
 {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        $newAzResourceGroupSplat
    )
    begin {
    }
    process {
        try {
            $ResourceGroupConfig = New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat
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


