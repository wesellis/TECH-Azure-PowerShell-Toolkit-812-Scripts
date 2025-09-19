#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Managedidentity Creator

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
    We Enhanced Azure Managedidentity Creator

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

#region Functions

Write-WELog " Creating Managed Identity: $WEIdentityName" " INFO"

try {
    # Create user-assigned managed identity
   $params = @{
       ResourceGroupName = $WEResourceGroupName
       WELog = " 1. Assign identity to Azure resources (VM, App Service, etc.)" " INFO" Write-WELog " 2. Grant necessary permissions" " INFO" Write-WELog " 3. Update application code to use managed identity" " INFO" Write-WELog " 4. Test secure resource access" " INFO"
       Location = $WELocation  Write-WELog "  Managed Identity created successfully:" " INFO" Write-WELog "  Name: $($WEIdentity.Name)" " INFO" Write-WELog "  Client ID: $($WEIdentity.ClientId)" " INFO" Write-WELog "  Principal ID: $($WEIdentity.PrincipalId)" " INFO" Write-WELog "  Resource ID: $($WEIdentity.Id)" " INFO" Write-WELog "  Location: $($WEIdentity.Location)" " INFO"  # Assign role if specified if ($WERole
       RoleDefinitionName = $WERole
       ObjectId = $WEIdentity.PrincipalId
       ErrorAction = "Stop"
       Seconds = "10  # Wait for identity propagation  ;  $WERoleAssignment = New-AzRoleAssignment"
       Name = $WEIdentityName
   }
   ; @params
} catch {
    Write-Error " Failed to create managed identity: $($_.Exception.Message)"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
