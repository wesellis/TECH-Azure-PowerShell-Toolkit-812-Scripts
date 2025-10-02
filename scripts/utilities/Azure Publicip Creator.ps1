#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Publicip Creator

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
;
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $PublicIpName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $Location,
    [Parameter()]
    $AllocationMethod = "Static" ,
    [Parameter()]
    $Sku = "Standard"
)
Write-Output "Creating Public IP: $PublicIpName"
    $params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = $Sku
    Location = $Location
    AllocationMethod = $AllocationMethod
    ErrorAction = "Stop"
    Name = $PublicIpName
}
    $PublicIp @params
Write-Output "Public IP created successfully:"
Write-Output "Name: $($PublicIp.Name)"
Write-Output "IP Address: $($PublicIp.IpAddress)"
Write-Output "Allocation: $($PublicIp.PublicIpAllocationMethod)"
Write-Output "SKU: $($PublicIp.Sku.Name)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
