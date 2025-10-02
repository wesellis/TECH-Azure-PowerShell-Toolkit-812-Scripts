#Requires -Version 7.4

<#`n.SYNOPSIS
    Create Azgatewaysubnet

.DESCRIPTION
    Create Azgatewaysubnet operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    General notes
function Write-Log {
    function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
        [Parameter(ValueFromPipeline)]
    [string]$NewAzVirtualNetworkGatewaySubnetConfigSplat
    )
    begin {
    }
    process {
        try {
    [string]$GatewaySubnetConfig = Add-AzVirtualNetworkSubnetConfig @newAzVirtualNetworkGatewaySubnetConfigSplat
        }
        catch {
            Write-Error 'An Error happened when .. script execution will be halted'
            Write-Output "Displaying the Catch Statement ErrorCode" # Color: $2
    [string]$PSItem
            Write-Output $PSItem.ScriptStackTrace -ForegroundColor Red
    [string]$ErrorMessage_1 = $_.Exception.Message
            Write-Output $ErrorMessage_1  -ForegroundColor Red
            Write-Output "Ran into an issue: $PSItem"
            Write-Output "Ran into an issue: $PSItem"
            throw "Ran into an issue: $PSItem"
            throw "I am the catch"
            throw "Ran into an issue: $PSItem"
    [string]$PSItem | Write-Information -ForegroundColor
    [string]$PSItem | Select-Object *
    [string]$PSCmdlet.ThrowTerminatingError($PSitem)
            throw
            throw "Something went wrong"
            Write-Log $PSItem.ToString()
            Exit
        }
        finally {
        }
    }
    end {
        return $GatewaySubnetConfig
    }
`n}
