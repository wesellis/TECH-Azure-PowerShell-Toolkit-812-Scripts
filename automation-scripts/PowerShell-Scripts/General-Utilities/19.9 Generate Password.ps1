<#
.SYNOPSIS
    We Enhanced 19.9 Generate Password

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

function WE-Generate-Password {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-Generate-Password {
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
        [Parameter(Mandatory = $true, Position = 0)]
        [int] $length
        # [Parameter(Mandatory = $false, Position = 1)]
        # [string] $WEOrgName
    )
    
    begin {

        $WEO365Password = @()
        $lengthdivided = $length/4
        function WE-Get-RandomCharacters($length, $characters) {
            $randomrange = 1..$length 
            $random = foreach ($singlerandomrange in $randomrange) {
                Get-Random -Maximum $characters.length
            }
            $private:ofs = ""
            return [String]$characters[$random]
            # return $characters[$random]
        }
         
        function WE-Scramble-String([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$inputString) {     
            $characterArray = $inputString.ToCharArray()   
            $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
            # $outputString = -join $scrambledStringArray
            $outputString = (-join $scrambledStringArray).Replace(" " , "" )
            return $outputString
        }
         
        $password = @()
       ;  $WEMulticharacterlist = @(
            "abcdefghiklmnoprstuvwxyz" ,
            "ABCDEFGHKLMNOPRSTUVWXYZ" ,
            "1234567890"
            '`~!@#$%^&*()_+-={}|[]\:" ;<>?,.'
        )

        $WEMultiPasswordrandom = foreach ($WESingleCharacterlist in $WEMulticharacterlist) {
            Get-RandomCharacters -length $lengthdivided -characters $WESingleCharacterlist
        }

        $password = Scramble-String $WEMultiPasswordrandom
        
    }
    
    process {

        try {
            # Write-Host $password -ForegroundColor Green
           ;  $length = $password.length
            # Write-WELog "Generating an O365 Password of length" " INFO" $length -ForegroundColor Green
            $WEScript:O365Password = $password
            # $password | Out-File -FilePath " C:\1.txt"
            # $password
        }
        catch {

            Write-WELog " A Terminating Error (Exception) happened" " INFO" -ForegroundColor Magenta
            Write-WELog " Displaying the Catch Statement ErrorCode" " INFO" -ForegroundColor Yellow
            Write-host $WEPSItem -ForegroundColor Red
            $WEPSItem
            Write-host $WEPSItem.ScriptStackTrace -ForegroundColor Red
            
        }
        finally {

            # Write-WELog " Displaying the Final Statement" " INFO" -ForegroundColor Green
            
        }
        
    }
    
    end {

        return $password

      
        
    }
}





# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================