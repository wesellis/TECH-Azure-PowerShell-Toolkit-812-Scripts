#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Policy Assignment Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
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
Write-Output "Creating Policy Assignment: $AssignmentName"
    $AssignmentParams = @{
    Name = $AssignmentName
    PolicyDefinition = Get-AzPolicyDefinition -Id $PolicyDefinitionId
    Scope = $Scope
    EnforcementMode = $EnforcementMode
}
if ($Description) {
    [string]$AssignmentParams.Description = $Description
}


    Author: Wes Ellis (wes@wesellis.com)
if ($Parameters.Count -gt 0) {
    [string]$AssignmentParams.PolicyParameterObject = $Parameters
}
    [string]$Assignment = New-AzPolicyAssignment -ErrorAction Stop @AssignmentParams
Write-Output "Policy Assignment created successfully:"
Write-Output "Name: $($Assignment.Name)"
Write-Output "Policy: $($Assignment.Properties.PolicyDefinitionId.Split('/')[-1])"
Write-Output "Scope: $Scope"
Write-Output "Enforcement Mode: $($Assignment.Properties.EnforcementMode)"
if ($Description) {
    Write-Output "Description: $Description"
}
if ($Parameters.Count -gt 0) {
    Write-Output " `nPolicy Parameters:"
    foreach ($Param in $Parameters.GetEnumerator()) {
        Write-Output "  $($Param.Key): $($Param.Value)"
    }
}
Write-Output " `nPolicy Assignment Benefits:"
Write-Output "Automated compliance enforcement"
Write-Output "Consistent governance across resources"
Write-Output "Audit and reporting capabilities"
Write-Output "Cost and security optimization"
Write-Output " `nCommon Policy Types:"
Write-Output "Resource tagging requirements"
Write-Output "Location restrictions"
Write-Output "SKU limitations"
Write-Output "Security configurations"
Write-Output "Naming conventions"
Write-Output " `nNext Steps:"
Write-Output " 1. Monitor compliance status"
Write-Output " 2. Review policy effects"
Write-Output " 3. Adjust parameters if needed"
Write-Output " 4. Create exemptions if required"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
