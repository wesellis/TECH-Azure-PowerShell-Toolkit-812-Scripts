#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Managedidentity Creator

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
    $ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $IdentityName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $Location,
    [Parameter()]
    $Role = "Reader" ,
    [Parameter()]
    $Scope
)
Write-Output "Creating Managed Identity: $IdentityName"
try {
    $params = @{
       ResourceGroupName = $ResourceGroupName
       WELog = " 1. Assign identity to Azure resources (VM, App Service, etc.)" "INFO"Write-Output " 2. Grant necessary permissions" "INFO"Write-Output " 3. Update application code to use managed identity" "INFO"Write-Output " 4. Test secure resource access"
       Location = $Location  Write-Output "Managed Identity created successfully:" "INFO"Write-Output "Name: $($Identity.Name)" "INFO"Write-Output "Client ID: $($Identity.ClientId)" "INFO"Write-Output "Principal ID: $($Identity.PrincipalId)" "INFO"Write-Output "Resource ID: $($Identity.Id)" "INFO"Write-Output "Location: $($Identity.Location)"  # Assign role if specified if ($Role
       RoleDefinitionName = $Role
       ObjectId = $Identity.PrincipalId
       ErrorAction = "Stop"
       Seconds = "10  # Wait for identity propagation  ;  $RoleAssignment = New-AzRoleAssignment"
       Name = $IdentityName
   }
   ; @params
} catch {
    Write-Error "Failed to create managed identity: $($_.Exception.Message)"`n}
