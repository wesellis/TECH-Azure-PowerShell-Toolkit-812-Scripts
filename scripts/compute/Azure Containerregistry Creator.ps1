#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Containerregistry Creator

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
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
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
Write-Output "Creating Container Registry: $RegistryName"
    $params = @{
    ErrorAction = "Stop"
    Sku = $Sku
    ResourceGroupName = $ResourceGroupName
    Name = $RegistryName
    Location = $Location
}
    [string]$Registry @params
Write-Output "Container Registry created successfully:"
Write-Output "Name: $($Registry.Name)"
Write-Output "Login Server: $($Registry.LoginServer)"
Write-Output "Location: $($Registry.Location)"
Write-Output "SKU: $($Registry.Sku.Name)"
Write-Output "Admin Enabled: $($Registry.AdminUserEnabled)"
    $Creds = Get-AzContainerRegistryCredential -ResourceGroupName $ResourceGroupName -Name $RegistryName
Write-Output " `nAdmin Credentials:"
Write-Output "Username: $($Creds.Username)"
Write-Output "Password: $($Creds.Password)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
