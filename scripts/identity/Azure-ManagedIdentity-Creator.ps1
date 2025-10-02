#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$IdentityName,
    [Parameter(Mandatory)]
    [string]$Location,
    [Parameter()]
    [string]$Role = "Reader",
    [Parameter()]
    [string]$Scope
)
Write-Output "Creating Managed Identity: $IdentityName"
try {
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Information = "1. Assign identity to Azure resources (VM, App Service, etc.)"Write-Output "2. Grant necessary permissions"Write-Output "3. Update application code to use managed identity"Write-Output "4. Test secure resource access"
        Location = $Location  Write-Output "Managed Identity created successfully:" Write-Output "Name: $($Identity.Name)"Write-Output "Client ID: $($Identity.ClientId)"Write-Output "Principal ID: $($Identity.PrincipalId)"Write-Output "Resource ID: $($Identity.Id)"Write-Output "Location: $($Identity.Location)"  # Assign role if specified if ($Role
        RoleDefinitionName = $Role
        ObjectId = $Identity.PrincipalId
        ErrorAction = "Stop"
        Seconds = "10  # Wait for identity propagation  $RoleAssignment = New-AzRoleAssignment"
        Name = $IdentityName
    }
} catch {
    Write-Error "Failed to create managed identity: $($_.Exception.Message)"`n}
