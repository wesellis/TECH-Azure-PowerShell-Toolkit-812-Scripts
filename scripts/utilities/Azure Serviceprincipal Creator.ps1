#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Serviceprincipal Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
    [string]$DisplayName,
    [Parameter()]
    [string]$Role = "Contributor" ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Scope,
    [Parameter()]
    [int]$PasswordValidityMonths = 12
)
Write-Host "Creating Service Principal: $DisplayName"
try {
    # Create service principal with password
   $params = @{
       WELog = "  Connect-AzAccount"
       DisplayName = $DisplayName
       TenantId = $((Get-AzContext).Tenant.Id)
       ApplicationId = $($ServicePrincipal.ApplicationId)
       CertificateThumbprint = "[thumbprint]'" "INFO"
       Scope = $Scope  Write-Host "Service Principal created successfully:" "INFO"Write-Host "Display Name: $($ServicePrincipal.DisplayName)" "INFO"Write-Host "Application ID: $($ServicePrincipal.ApplicationId)" "INFO"Write-Host "Object ID: $($ServicePrincipal.Id)"Write-Host "Service Principal Names: $($ServicePrincipal.ServicePrincipalNames
       ErrorAction = "Stop"
       Role = $Role
   }
   ; @params
} catch {
    Write-Error "Failed to create service principal: $($_.Exception.Message)"
}


