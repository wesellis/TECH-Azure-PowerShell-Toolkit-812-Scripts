#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Containerregistry Creator

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
    [string]$RegistryName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [string]$Sku = "Basic"
)
Write-Host "Creating Container Registry: $RegistryName"
$params = @{
    ErrorAction = "Stop"
    Sku = $Sku
    ResourceGroupName = $ResourceGroupName
    Name = $RegistryName
    Location = $Location
}
$Registry @params
Write-Host "Container Registry created successfully:"
Write-Host "Name: $($Registry.Name)"
Write-Host "Login Server: $($Registry.LoginServer)"
Write-Host "Location: $($Registry.Location)"
Write-Host "SKU: $($Registry.Sku.Name)"
Write-Host "Admin Enabled: $($Registry.AdminUserEnabled)"
$Creds = Get-AzContainerRegistryCredential -ResourceGroupName $ResourceGroupName -Name $RegistryName
Write-Host " `nAdmin Credentials:"
Write-Host "Username: $($Creds.Username)"
Write-Host "Password: $($Creds.Password)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


