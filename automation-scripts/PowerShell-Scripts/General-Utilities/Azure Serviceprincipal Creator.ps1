<#
.SYNOPSIS
    Azure Serviceprincipal Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



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
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
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

Write-WELog " Creating Service Principal: $WEDisplayName" " INFO"

try {
    # Create service principal with password
   ;  $WEServicePrincipal = New-AzADServicePrincipal `
        -DisplayName $WEDisplayName `
        -Role $WERole `
        -Scope $WEScope
    
    Write-WELog " ✅ Service Principal created successfully:" " INFO"
    Write-WELog "  Display Name: $($WEServicePrincipal.DisplayName)" " INFO"
    Write-WELog "  Application ID: $($WEServicePrincipal.ApplicationId)" " INFO"
    Write-WELog "  Object ID: $($WEServicePrincipal.Id)" " INFO"
    Write-WELog "  Service Principal Names: $($WEServicePrincipal.ServicePrincipalNames -join ', ')" " INFO"
    
    # Get the secret
   ;  $WESecret = $WEServicePrincipal.Secret
    if ($WESecret) {
        Write-WELog " `n🔑 Credentials (SAVE THESE SECURELY):" " INFO"
        Write-WELog "  Application (Client) ID: $($WEServicePrincipal.ApplicationId)" " INFO"
        Write-WELog "  Client Secret: $($WESecret)" " INFO"
        Write-WELog "  Tenant ID: $((Get-AzContext).Tenant.Id)" " INFO"
    }
    
    Write-WELog " `nRole Assignment:" " INFO"
    Write-WELog "  Role: $WERole" " INFO"
    if ($WEScope) {
        Write-WELog "  Scope: $WEScope" " INFO"
    } else {
        Write-WELog "  Scope: Subscription level" " INFO"
    }
    
    Write-WELog " `n⚠️ SECURITY NOTES:" " INFO"
    Write-WELog " • Store credentials securely (Key Vault recommended)" " INFO"
    Write-WELog " • Use certificate authentication for production" " INFO"
    Write-WELog " • Implement credential rotation" " INFO"
    Write-WELog " • Follow principle of least privilege" " INFO"
    
    Write-WELog " `nUsage in scripts:" " INFO"
    Write-WELog "  Connect-AzAccount -ServicePrincipal -ApplicationId '$($WEServicePrincipal.ApplicationId)' -TenantId '$((Get-AzContext).Tenant.Id)' -CertificateThumbprint '[thumbprint]'" " INFO"
    
} catch {
    Write-Error " Failed to create service principal: $($_.Exception.Message)"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================