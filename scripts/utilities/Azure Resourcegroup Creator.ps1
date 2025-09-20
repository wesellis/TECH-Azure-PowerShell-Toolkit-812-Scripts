#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Resourcegroup Creator

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
    [string]$Location,
    [Parameter()]
    [hashtable]$Tags = @{}
)
Write-Host "Creating Resource Group: $ResourceGroupName"
if ($Tags.Count -gt 0) {
$resourcegroupSplat = @{
    Name = $ResourceGroupName
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
    Write-Host "Tags applied:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Host "  $($Tag.Key): $($Tag.Value)"
    }
} else {
$ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}
Write-Host "Resource Group created successfully:"
Write-Host "Name: $($ResourceGroup.ResourceGroupName)"
Write-Host "Location: $($ResourceGroup.Location)"
Write-Host "Provisioning State: $($ResourceGroup.ProvisioningState)"
Write-Host "Resource ID: $($ResourceGroup.ResourceId)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


