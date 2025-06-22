# Az.Accounts Enterprise Module

Enterprise-grade Azure account management PowerShell module with advanced authentication features.

## Features

- **Multi-Tenant Authentication**: Connect and manage multiple Azure AD tenants simultaneously
- **Service Principal Automation**: Create and manage service principals with certificate or secret authentication
- **Managed Identity Integration**: Test and validate managed identity configurations
- **Certificate-Based Authentication**: Generate and manage certificates for Azure authentication
- **Cross-Subscription Management**: Execute commands across multiple subscriptions in parallel

## Requirements

- PowerShell 7.0 or higher
- Az.Accounts module 2.12.1 or higher

## Installation

```powershell
# Import the module
Import-Module ./Az.Accounts.Enterprise.psd1
```

## Usage Examples

### Multi-Tenant Authentication

```powershell
# Connect to multiple tenants
$tenants = @('tenant1-guid', 'tenant2-guid')
$connections = Connect-AzMultiTenant -TenantIds $tenants

# Switch between tenants
Switch-AzTenant -TenantId 'tenant1-guid'
```

### Service Principal Management

```powershell
# Create service principal with certificate
$sp = New-AzServicePrincipalAdvanced -DisplayName "MyApp" -UseCertificate -ValidYears 2 -Role "Contributor" -Scope "/subscriptions/sub-id"

# Clean up expired service principals
Remove-ExpiredServicePrincipals -WhatIf
```

### Managed Identity

```powershell
# Test managed identity configuration
$miResourceId = "/subscriptions/sub-id/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-name"
Test-AzManagedIdentity -ResourceId $miResourceId
```

### Cross-Subscription Operations

```powershell
# Get all VMs across multiple subscriptions
$subscriptions = @('sub1-id', 'sub2-id', 'sub3-id')
$vms = Invoke-AzCrossSubscriptionCommand -SubscriptionIds $subscriptions -ScriptBlock {
    Get-AzVM | Select-Object Name, ResourceGroupName, Location
}
```

### Certificate Authentication

```powershell
# Create authentication certificate
$cert = New-AzAuthenticationCertificate -Subject "CN=AzureServicePrincipal" -ExportPath "C:\Certs" -ValidYears 2

# Use certificate for authentication
Connect-AzAccount -ServicePrincipal -TenantId $tenantId -ApplicationId $appId -CertificateThumbprint $cert.Thumbprint
```

## Module Information

```powershell
# Get module information
Get-AzAccountsEnterpriseInfo
```

## Error Handling

All functions include comprehensive error handling and support for `-Verbose` and `-WhatIf` parameters where applicable.

## Best Practices

1. Use certificate-based authentication for production service principals
2. Regularly review and remove expired service principals
3. Implement least-privilege access for all identities
4. Use managed identities where possible to eliminate credential management
5. Enable verbose logging for troubleshooting multi-tenant operations