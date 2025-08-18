<#
.SYNOPSIS
    We Enhanced 1 Create Azrg

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

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



function WE-Invoke-CreateAZRG {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
    

function Write-WELog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

param(
        # [Parameter(ValueFromPipelineByPropertyName)]
        # $newAzResourceGroupSplat
        [Parameter(ValueFromPipeline)]
        $newAzResourceGroupSplat
        
    )
    
    begin {
        
    }
    
    process {


     
    
        try {

            
            $WEResourceGroupConfig = New-AzResourceGroup @newAzResourceGroupSplat
         
        }
     
        catch {
                
            Write-Error 'An Error happened when .. script execution will be halted'
         
            #Region CatchAll
         
            Write-WELog " A Terminating Error (Exception) happened" " INFO" -ForegroundColor Magenta
            Write-WELog " Displaying the Catch Statement ErrorCode" " INFO" -ForegroundColor Yellow
            $WEPSItem
            Write-Host $WEPSItem.ScriptStackTrace -ForegroundColor Red
            
            
           ;  $WEErrorMessage_1 = $_.Exception.Message
            write-host $WEErrorMessage_1  -ForegroundColor Red
            Write-Output " Ran into an issue: $WEPSItem"
            Write-host " Ran into an issue: $WEPSItem" -ForegroundColor Red
            throw " Ran into an issue: $WEPSItem"
            throw " I am the catch"
            throw " Ran into an issue: $WEPSItem"
            $WEPSItem | Write-host -ForegroundColor
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

        return $WEResourceGroupConfig
        
    }
}





# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================