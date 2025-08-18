<#
.SYNOPSIS
    We Enhanced Azure Dns Record Update Tool

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
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

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEZoneName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERecordSetName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERecordType,
    [int]$WETTL,
    [string]$WERecordValue
)

; 
$WERecordSet = Get-AzDnsRecordSet -ResourceGroupName $WEResourceGroupName -ZoneName $WEZoneName -Name $WERecordSetName -RecordType $WERecordType

Write-WELog " Updating DNS Record: $WERecordSetName.$WEZoneName" " INFO"
Write-WELog " Record Type: $WERecordType" " INFO"
Write-WELog " Current TTL: $($WERecordSet.Ttl)" " INFO"
Write-WELog " New TTL: $WETTL" " INFO"
Write-WELog " New Value: $WERecordValue" " INFO"


$WERecordSet.Ttl = $WETTL


switch ($WERecordType) {
    " A" { 
        $WERecordSet.Records.Clear()
        $WERecordSet.Records.Add((New-AzDnsRecordConfig -IPv4Address $WERecordValue))
    }
    " CNAME" { 
        $WERecordSet.Records.Clear()
        $WERecordSet.Records.Add((New-AzDnsRecordConfig -Cname $WERecordValue))
    }
    " TXT" { 
        $WERecordSet.Records.Clear()
        $WERecordSet.Records.Add((New-AzDnsRecordConfig -Value $WERecordValue))
    }
}


Set-AzDnsRecordSet -RecordSet $WERecordSet

Write-WELog " DNS record updated successfully" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
