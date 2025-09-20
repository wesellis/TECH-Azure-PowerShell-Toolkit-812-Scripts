#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Tag Manager

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
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
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VmName,
    [Parameter(Mandatory)]
    [hashtable]$Tags
)
Write-Host "Updating tags for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
$ExistingTags = $VM.Tags
if (-not $ExistingTags) {;  $ExistingTags = @{} }
foreach ($Tag in $Tags.GetEnumerator()) {
    $ExistingTags[$Tag.Key] = $Tag.Value
    Write-Host "Added/Updated tag: $($Tag.Key) = $($Tag.Value)"
}
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM -Tag $ExistingTags
Write-Host "Tags updated successfully for VM: $VmName"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


