#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Resourcegroup Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $Location,
    [Parameter()]
    [hashtable]$Tags = @{}
)
Write-Output "Creating Resource Group: $ResourceGroupName"
if ($Tags.Count -gt 0) {
    $ResourcegroupSplat = @{
    Name = $ResourceGroupName
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
    Write-Output "Tags applied:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Output "  $($Tag.Key): $($Tag.Value)"
    }
} else {
    $ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}
Write-Output "Resource Group created successfully:"
Write-Output "Name: $($ResourceGroup.ResourceGroupName)"
Write-Output "Location: $($ResourceGroup.Location)"
Write-Output "Provisioning State: $($ResourceGroup.ProvisioningState)"
Write-Output "Resource ID: $($ResourceGroup.ResourceId)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
