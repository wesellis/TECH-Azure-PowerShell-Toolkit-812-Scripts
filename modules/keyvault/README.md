# Az.KeyVault.Enterprise Module

Enterprise-grade Azure Key Vault management module with advanced automation capabilities.

## Features

### 🔐 Secret Rotation Automation
- Automated secret rotation with configurable policies
- Support for custom rotation scripts
- Rollback capabilities for failed rotations
- Email notifications for rotation events
- Rotation history tracking

### 📜 Certificate Lifecycle Management
- Automated certificate renewal before expiration
- Support for self-signed and CA-issued certificates
- Comprehensive certificate reporting
- Expiration notifications and alerts
- Bulk certificate operations

### 👥 Access Policy Automation
- Bulk access policy management across multiple vaults
- Reusable policy templates for standard roles
- Least-privilege access reviews
- Policy compliance checking
- Service principal management

### 📊 Monitoring and Alerting
- Automated diagnostic settings configuration
- Log Analytics integration
- Custom alert rules for security events
- Performance metrics tracking
- Audit log analysis

### ✅ Compliance and Reporting
- Comprehensive compliance reports
- Access review automation
- Security posture assessment
- Expired item detection
- Actionable recommendations

## Installation

```powershell
# Install from PowerShell Gallery (when published)
Install-Module -Name Az.KeyVault.Enterprise -Scope CurrentUser

# Or install from source
Import-Module .\Az.KeyVault.Enterprise.psd1
```

## Quick Start

### Secret Rotation

```powershell
# Basic secret rotation
Start-AzKeyVaultSecretRotation -VaultName "MyVault" -SecretName "DatabasePassword" -RotationDays 90

# Advanced rotation with custom script and notifications
$rotationScript = {
    # Generate new password
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()'
    $password = -join ((1..32) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    ConvertTo-SecureString $password -AsPlainText -Force
}

Start-AzKeyVaultSecretRotation -VaultName "MyVault" `
    -SecretName "APIKey" `
    -RotationDays 30 `
    -RotationScript $rotationScript `
    -NotificationEmail "admin@company.com" `
    -EnableRollback
```

### Certificate Management

```powershell
# Monitor and auto-renew certificates
Start-AzKeyVaultCertificateLifecycle -VaultName "MyVault" `
    -CertificateName "WebSSL" `
    -RenewalThresholdDays 30 `
    -AutoRenew

# Generate certificate report
$report = Get-AzKeyVaultCertificateReport -VaultName "MyVault" `
    -ExpiryWarningDays 60 `
    -OutputPath ".\CertificateReport.csv"
```

### Access Policy Management

```powershell
# Apply policies to multiple vaults
Set-AzKeyVaultAccessPolicyBulk -VaultNames @("Vault1", "Vault2", "Vault3") `
    -ObjectIds @("user1-guid", "user2-guid") `
    -PermissionsToSecrets @('Get', 'List') `
    -PermissionsToKeys @('Get', 'List', 'Decrypt')

# Create and apply policy template
New-AzKeyVaultAccessPolicyTemplate -TemplateName "DeveloperAccess" `
    -Role "Contributor" `
    -Description "Standard developer access policy"
```

### Monitoring Setup

```powershell
# Enable comprehensive monitoring
Enable-AzKeyVaultMonitoring -VaultName "MyVault" `
    -WorkspaceId "/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/myworkspace" `
    -EnableAllLogs `
    -RetentionDays 90

# Create default alert rules
New-AzKeyVaultAlertRules -VaultName "MyVault" `
    -ResourceGroupName "MyResourceGroup" `
    -CreateDefaultAlerts
```

### Compliance Reporting

```powershell
# Generate compliance report for all vaults
$vaults = @("ProdVault", "DevVault", "TestVault")
$complianceReport = Get-AzKeyVaultComplianceReport -VaultNames $vaults `
    -ReportLevel "Detailed" `
    -IncludeRecommendations `
    -OutputPath ".\ComplianceReport.json"

# Perform access review
$accessReview = Start-AzKeyVaultAccessReview -VaultName "ProdVault" `
    -IncludeServicePrincipals `
    -CheckLastAccess `
    -ExportPath ".\AccessReview.json"
```

## Rotation Policies

Create automated rotation policies for different secret types:

```powershell
# Database password rotation policy
New-AzKeyVaultRotationPolicy -VaultName "MyVault" `
    -PolicyName "DatabasePasswordPolicy" `
    -SecretNamePattern @("*-db-password", "*-sql-*") `
    -RotationDays 60 `
    -RotationType "Automatic" `
    -NotificationEmails @("dba@company.com", "security@company.com")

# API key rotation policy
New-AzKeyVaultRotationPolicy -VaultName "MyVault" `
    -PolicyName "APIKeyPolicy" `
    -SecretNamePattern @("*-api-key", "*-client-secret") `
    -RotationDays 90 `
    -RotationType "Approval" `
    -NotificationEmails @("api-team@company.com")
```

## Best Practices

1. **Enable Soft Delete and Purge Protection** on all production vaults
2. **Implement Regular Secret Rotation** - at least every 90 days
3. **Use Managed Identities** where possible instead of service principals
4. **Enable Monitoring** on all vaults with appropriate retention
5. **Regular Access Reviews** - monthly for production vaults
6. **Certificate Auto-Renewal** - set threshold to 30 days before expiry
7. **Use Policy Templates** for consistent access control
8. **Implement Network Restrictions** - use private endpoints where possible

## Troubleshooting

### Common Issues

1. **Rotation Fails**
   - Check if the secret exists and is enabled
   - Verify you have appropriate permissions
   - Check if rollback is enabled and review backup secrets

2. **Certificate Renewal Fails**
   - Verify certificate policy allows renewal
   - Check issuer configuration
   - Ensure sufficient permissions for certificate operations

3. **Monitoring Not Working**
   - Verify Log Analytics workspace exists and is accessible
   - Check diagnostic settings are applied
   - Ensure proper RBAC permissions on workspace

## Support

For issues, feature requests, or contributions:
- GitHub: [azure-enterprise-toolkit](https://github.com/wesellis/azure-enterprise-toolkit)
- Email: support@enterprise-azure.com

## License

This module is part of the Azure Enterprise Toolkit and is licensed under the MIT License.