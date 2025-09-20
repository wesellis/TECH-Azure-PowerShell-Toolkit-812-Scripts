#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Invoke Azpublicip

.DESCRIPTION
    Invoke Azpublicip operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    General notes
[CmdletBinding()]
[OutputType([PSObject])]
 {
    [CmdletBinding()]
function Write-Host {
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
        # [Parameter(ValueFromPipelineByPropertyName)]
        # $newAzResourceGroupSplat
        [Parameter(ValueFromPipeline)]
        $newAzPublicIpAddressSplat
    )
    begin {
    }
    process {
        try {
$PublicIPConfig = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat
        }
        catch {
            Write-Error 'An Error happened when .. script execution will be halted'
            #region CatchAll-Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            $PSItem
            Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
$ErrorMessage_1 = $_.Exception.Message
            Write-Host $ErrorMessage_1  -ForegroundColor Red
            Write-Output "Ran into an issue: $PSItem"
            Write-Host "Ran into an issue: $PSItem"
            throw "Ran into an issue: $PSItem"
            throw "I am the catch"
            throw "Ran into an issue: $PSItem"
            $PSItem | Write-Information -ForegroundColor
            $PSItem | Select-Object *
            $PSCmdlet.ThrowTerminatingError($PSitem)
            throw
            throw "Something went wrong"
            Write-Log $PSItem.ToString()
            #EndRegion CatchAll
            Exit
        }
        finally {
        }
    }
    end {
        return $PublicIPConfig
    }
}

