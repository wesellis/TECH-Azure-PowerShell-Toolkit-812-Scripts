#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Policy Assignment Creator

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
    We Enhanced Azure Policy Assignment Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
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

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPolicyDefinitionId,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAssignmentName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEScope,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDescription,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$WEParameters = @{},
    
    [Parameter(Mandatory=$false)]
    [string]$WEEnforcementMode = " Default"
)

#region Functions

Write-WELog " Creating Policy Assignment: $WEAssignmentName" " INFO"

; 
$WEAssignmentParams = @{
    Name = $WEAssignmentName
    PolicyDefinition = Get-AzPolicyDefinition -Id $WEPolicyDefinitionId
    Scope = $WEScope
    EnforcementMode = $WEEnforcementMode
}

if ($WEDescription) {
    $WEAssignmentParams.Description = $WEDescription
}

if ($WEParameters.Count -gt 0) {
    $WEAssignmentParams.PolicyParameterObject = $WEParameters
}

; 
$WEAssignment = New-AzPolicyAssignment -ErrorAction Stop @AssignmentParams

Write-WELog "  Policy Assignment created successfully:" " INFO"
Write-WELog "  Name: $($WEAssignment.Name)" " INFO"
Write-WELog "  Policy: $($WEAssignment.Properties.PolicyDefinitionId.Split('/')[-1])" " INFO"
Write-WELog "  Scope: $WEScope" " INFO"
Write-WELog "  Enforcement Mode: $($WEAssignment.Properties.EnforcementMode)" " INFO"

if ($WEDescription) {
    Write-WELog "  Description: $WEDescription" " INFO"
}

if ($WEParameters.Count -gt 0) {
    Write-WELog " `nPolicy Parameters:" " INFO"
    foreach ($WEParam in $WEParameters.GetEnumerator()) {
        Write-WELog "  $($WEParam.Key): $($WEParam.Value)" " INFO"
    }
}

Write-WELog " `nPolicy Assignment Benefits:" " INFO"
Write-WELog " • Automated compliance enforcement" " INFO"
Write-WELog " • Consistent governance across resources" " INFO"
Write-WELog " • Audit and reporting capabilities" " INFO"
Write-WELog " • Cost and security optimization" " INFO"

Write-WELog " `nCommon Policy Types:" " INFO"
Write-WELog " • Resource tagging requirements" " INFO"
Write-WELog " • Location restrictions" " INFO"
Write-WELog " • SKU limitations" " INFO"
Write-WELog " • Security configurations" " INFO"
Write-WELog " • Naming conventions" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Monitor compliance status" " INFO"
Write-WELog " 2. Review policy effects" " INFO"
Write-WELog " 3. Adjust parameters if needed" " INFO"
Write-WELog " 4. Create exemptions if required" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
