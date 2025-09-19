#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Serviceprincipal Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Serviceprincipal Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDisplayName,
    
    [Parameter(Mandatory=$false)]
    [string]$WERole = " Contributor" ,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEScope,
    
    [Parameter(Mandatory=$false)]
    [int]$WEPasswordValidityMonths = 12
)

#region Functions

Write-WELog " Creating Service Principal: $WEDisplayName" " INFO"

try {
    # Create service principal with password
   $params = @{
       WELog = "  Connect-AzAccount"
       DisplayName = $WEDisplayName
       TenantId = $((Get-AzContext).Tenant.Id)
       ApplicationId = $($WEServicePrincipal.ApplicationId)
       CertificateThumbprint = "[thumbprint]'" " INFO"
       Scope = $WEScope  Write-WELog "  Service Principal created successfully:" " INFO" Write-WELog "  Display Name: $($WEServicePrincipal.DisplayName)" " INFO" Write-WELog "  Application ID: $($WEServicePrincipal.ApplicationId)" " INFO" Write-WELog "  Object ID: $($WEServicePrincipal.Id)" " INFO" Write-WELog "  Service Principal Names: $($WEServicePrincipal.ServicePrincipalNames
       ErrorAction = "Stop"
       Role = $WERole
   }
   ; @params
} catch {
    Write-Error " Failed to create service principal: $($_.Exception.Message)"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
