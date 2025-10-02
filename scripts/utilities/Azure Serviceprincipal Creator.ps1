#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Serviceprincipal Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
    $DisplayName,
    [Parameter()]
    $Role = "Contributor" ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Scope,
    [Parameter()]
    [int]$PasswordValidityMonths = 12
)
Write-Output "Creating Service Principal: $DisplayName"
try {
    $params = @{
       WELog = "  Connect-AzAccount"
       DisplayName = $DisplayName
       TenantId = $((Get-AzContext).Tenant.Id)
       ApplicationId = $($ServicePrincipal.ApplicationId)
       CertificateThumbprint = "[thumbprint]'" "INFO"
       Scope = $Scope  Write-Output "Service Principal created successfully:" "INFO"Write-Output "Display Name: $($ServicePrincipal.DisplayName)" "INFO"Write-Output "Application ID: $($ServicePrincipal.ApplicationId)" "INFO"Write-Output "Object ID: $($ServicePrincipal.Id)"Write-Host "Service Principal Names: $($ServicePrincipal.ServicePrincipalNames
       ErrorAction = "Stop"
       Role = $Role
   }
   ; @params
} catch {
    Write-Error "Failed to create service principal: $($_.Exception.Message)"`n}
