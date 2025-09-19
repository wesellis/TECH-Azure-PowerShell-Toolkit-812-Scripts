#Requires -Version 7.0
#Requires -Module Az.Resources

<#
.SYNOPSIS
    5 Invoke Getazvnet

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 5 Invoke Getazvnet

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes



[CmdletBinding()]
function WE-Invoke-GETAZVNET {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
    

function Write-WELog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

param(
        # [Parameter(ValueFromPipelineByPropertyName)]
        # $newAzResourceGroupSplat
        [Parameter(ValueFromPipeline)]
        $newAzVirtualNetworkConfigSplat
        
    )
    
    begin {
        
    }
    
    process {
    
        try {

            
            # $vnet | Set-AzVirtualNetwork -ErrorAction Stop
            # $WEVnet | Invoke-DefineParam
         
           ;  $WEVNETCONFIG = Get-AzVirtualNetwork -ErrorAction Stop @newAzVirtualNetworkConfigSplat


        }
     
        catch {
                
            Write-Error 'An Error happened when .. script execution will be halted'
         
            #Region CatchAll
         
            Write-WELog " A Terminating Error (Exception) happened" " INFO" -ForegroundColor Magenta
            Write-WELog " Displaying the Catch Statement ErrorCode" " INFO" -ForegroundColor Yellow
            $WEPSItem
            Write-Information $WEPSItem.ScriptStackTrace -ForegroundColor Red
            
            
           ;  $WEErrorMessage_1 = $_.Exception.Message
            Write-Information $WEErrorMessage_1  -ForegroundColor Red
            Write-Output " Ran into an issue: $WEPSItem"
            Write-Information " Ran into an issue: $WEPSItem"
            throw " Ran into an issue: $WEPSItem"
            throw " I am the catch"
            throw " Ran into an issue: $WEPSItem"
            $WEPSItem | Write-Information -ForegroundColor
            $WEPSItem | Select-Object *
            $WEPSCmdlet.ThrowTerminatingError($WEPSitem)
            throw
            throw " Something went wrong"
            Write-Log $WEPSItem.ToString()
         
            #EndRegion CatchAll
         
            Exit
         
         
        }
    
        finally {
         
        }
        
    }
    
    end {

        return $WEVNETConfig
        
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

