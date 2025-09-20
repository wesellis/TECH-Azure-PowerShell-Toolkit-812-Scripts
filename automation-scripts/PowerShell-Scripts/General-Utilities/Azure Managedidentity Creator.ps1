#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Managedidentity Creator

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$IdentityName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [string]$Role = "Reader" ,
    [Parameter()]
    [string]$Scope
)
Write-Host "Creating Managed Identity: $IdentityName"
try {
    # Create user-assigned managed identity
   $params = @{
       ResourceGroupName = $ResourceGroupName
       WELog = " 1. Assign identity to Azure resources (VM, App Service, etc.)" "INFO"Write-Host " 2. Grant necessary permissions" "INFO"Write-Host " 3. Update application code to use managed identity" "INFO"Write-Host " 4. Test secure resource access"
       Location = $Location  Write-Host "Managed Identity created successfully:" "INFO"Write-Host "Name: $($Identity.Name)" "INFO"Write-Host "Client ID: $($Identity.ClientId)" "INFO"Write-Host "Principal ID: $($Identity.PrincipalId)" "INFO"Write-Host "Resource ID: $($Identity.Id)" "INFO"Write-Host "Location: $($Identity.Location)"  # Assign role if specified if ($Role
       RoleDefinitionName = $Role
       ObjectId = $Identity.PrincipalId
       ErrorAction = "Stop"
       Seconds = "10  # Wait for identity propagation  ;  $RoleAssignment = New-AzRoleAssignment"
       Name = $IdentityName
   }
   ; @params
} catch {
    Write-Error "Failed to create managed identity: $($_.Exception.Message)"
}\n

