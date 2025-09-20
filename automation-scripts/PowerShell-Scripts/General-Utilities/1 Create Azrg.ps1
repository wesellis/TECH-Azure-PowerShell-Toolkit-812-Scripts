<#
.SYNOPSIS
    Create Azure resource group

.DESCRIPTION
    Creates a new Azure resource group
.AUTHOR
    Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Invoke-CreateAZRG {
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
}\n