<#
.SYNOPSIS
    Azure Managedidentity Creator

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
    We Enhanced Azure Managedidentity Creator

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
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEIdentityName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [string]$WERole = " Reader" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WEScope
)

Write-WELog " Creating Managed Identity: $WEIdentityName" " INFO"

try {
    # Create user-assigned managed identity
   ;  $WEIdentity = New-AzUserAssignedIdentity `
        -ResourceGroupName $WEResourceGroupName `
        -Name $WEIdentityName `
        -Location $WELocation
    
    Write-WELog " ✅ Managed Identity created successfully:" " INFO"
    Write-WELog "  Name: $($WEIdentity.Name)" " INFO"
    Write-WELog "  Client ID: $($WEIdentity.ClientId)" " INFO"
    Write-WELog "  Principal ID: $($WEIdentity.PrincipalId)" " INFO"
    Write-WELog "  Resource ID: $($WEIdentity.Id)" " INFO"
    Write-WELog "  Location: $($WEIdentity.Location)" " INFO"
    
    # Assign role if specified
    if ($WERole -and $WEScope) {
        Write-WELog " `nAssigning role to managed identity..." " INFO"
        
        Start-Sleep -Seconds 10  # Wait for identity propagation
        
       ;  $WERoleAssignment = New-AzRoleAssignment `
            -ObjectId $WEIdentity.PrincipalId `
            -RoleDefinitionName $WERole `
            -Scope $WEScope
        
        Write-WELog " ✅ Role assignment completed:" " INFO"
        Write-WELog "  Assignment ID: $($WERoleAssignment.RoleAssignmentId)" " INFO"
        Write-WELog "  Role: $WERole" " INFO"
        Write-WELog "  Scope: $WEScope" " INFO"
    }
    
    Write-WELog " `nManaged Identity Benefits:" " INFO"
    Write-WELog " • No credential management required" " INFO"
    Write-WELog " • Automatic credential rotation" " INFO"
    Write-WELog " • Azure AD authentication" " INFO"
    Write-WELog " • No secrets in code or config" " INFO"
    Write-WELog " • Built-in Azure integration" " INFO"
    
    Write-WELog " `nUsage Examples:" " INFO"
    Write-WELog " Virtual Machines:" " INFO"
    Write-WELog "  - Assign identity to VM" " INFO"
    Write-WELog "  - Access Azure resources securely" " INFO"
    Write-WELog "  - No need to store credentials" " INFO"
    
    Write-WELog " `nApp Services:" " INFO"
    Write-WELog "  - Enable managed identity" " INFO"
    Write-WELog "  - Access Key Vault secrets" " INFO"
    Write-WELog "  - Connect to databases" " INFO"
    
    Write-WELog " `nPowerShell Usage:" " INFO"
    Write-WELog "  Connect-AzAccount -Identity -AccountId $($WEIdentity.ClientId)" " INFO"
    
    Write-WELog " `nNext Steps:" " INFO"
    Write-WELog " 1. Assign identity to Azure resources (VM, App Service, etc.)" " INFO"
    Write-WELog " 2. Grant necessary permissions" " INFO"
    Write-WELog " 3. Update application code to use managed identity" " INFO"
    Write-WELog " 4. Test secure resource access" " INFO"
    
} catch {
    Write-Error " Failed to create managed identity: $($_.Exception.Message)"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================