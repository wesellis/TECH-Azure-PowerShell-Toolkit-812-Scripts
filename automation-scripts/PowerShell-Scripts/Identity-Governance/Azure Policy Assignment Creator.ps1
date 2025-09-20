#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Policy Assignment Creator

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PolicyDefinitionId,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$AssignmentName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Scope,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Description,
    [Parameter()]
    [hashtable]$Parameters = @{},
    [Parameter()]
    [string]$EnforcementMode = "Default"
)
Write-Host "Creating Policy Assignment: $AssignmentName"
$AssignmentParams = @{
    Name = $AssignmentName
    PolicyDefinition = Get-AzPolicyDefinition -Id $PolicyDefinitionId
    Scope = $Scope
    EnforcementMode = $EnforcementMode
}
if ($Description) {
    $AssignmentParams.Description = $Description
}\n    Author: Wes Ellis (wes@wesellis.com)\n#>
if ($Parameters.Count -gt 0) {
    $AssignmentParams.PolicyParameterObject = $Parameters
}
$Assignment = New-AzPolicyAssignment -ErrorAction Stop @AssignmentParams
Write-Host "Policy Assignment created successfully:"
Write-Host "Name: $($Assignment.Name)"
Write-Host "Policy: $($Assignment.Properties.PolicyDefinitionId.Split('/')[-1])"
Write-Host "Scope: $Scope"
Write-Host "Enforcement Mode: $($Assignment.Properties.EnforcementMode)"
if ($Description) {
    Write-Host "Description: $Description"
}
if ($Parameters.Count -gt 0) {
    Write-Host " `nPolicy Parameters:"
    foreach ($Param in $Parameters.GetEnumerator()) {
        Write-Host "  $($Param.Key): $($Param.Value)"
    }
}
Write-Host " `nPolicy Assignment Benefits:"
Write-Host "Automated compliance enforcement"
Write-Host "Consistent governance across resources"
Write-Host "Audit and reporting capabilities"
Write-Host "Cost and security optimization"
Write-Host " `nCommon Policy Types:"
Write-Host "Resource tagging requirements"
Write-Host "Location restrictions"
Write-Host "SKU limitations"
Write-Host "Security configurations"
Write-Host "Naming conventions"
Write-Host " `nNext Steps:"
Write-Host " 1. Monitor compliance status"
Write-Host " 2. Review policy effects"
Write-Host " 3. Adjust parameters if needed"
Write-Host " 4. Create exemptions if required"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

