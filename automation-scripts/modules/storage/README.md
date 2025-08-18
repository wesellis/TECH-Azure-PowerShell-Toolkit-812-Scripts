# Az.Storage Enterprise Module

Enterprise-grade Azure Storage management with advanced security, lifecycle policies, and cost optimization.

## Features

- **Secure Storage Creation**: Deploy storage accounts with enterprise security defaults
- **Security Validation**: Test and remediate storage security configurations
- **Lifecycle Management**: Automate blob tiering and deletion policies
- **Threat Protection**: Enable and configure Advanced Threat Protection
- **Compliance Reporting**: Generate detailed compliance reports
- **Cost Optimization**: Analyze costs and identify savings opportunities
- **Data Archival**: Automate data archival based on access patterns
- **Backup & DR**: Configure backup and cross-region replication

## Requirements

- PowerShell 7.0 or higher
- Az.Storage module 5.5.0 or higher
- Az.Security module 1.5.0 or higher

## Installation

```powershell
# Import the module
Import-Module ./Az.Storage.Enterprise.psd1
```

## Usage Examples

### Create Secure Storage Account

```powershell
# Create storage account with enterprise defaults
New-AzStorageAccountAdvanced `
    -Name "stproddata001" `
    -ResourceGroupName "rg-prod" `
    -Location "eastus" `
    -Tier "Standard" `
    -Replication "GRS" `
    -EnableLifecycleManagement `
    -Tags @{
        Environment = "Production"
        CostCenter = "IT001"
        Owner = "admin@contoso.com"
    }
```

### Security Validation and Remediation

```powershell
# Test storage security
$security = Test-AzStorageAccountSecurity `
    -StorageAccountName "stproddata001" `
    -ResourceGroupName "rg-prod" `
    -RemediateSecurity

# Enable Advanced Threat Protection
Enable-AzStorageAdvancedThreatProtection `
    -StorageAccountName "stproddata001" `
    -ResourceGroupName "rg-prod" `
    -AlertEmailAddresses @("security@contoso.com")
```

### Lifecycle Management

```powershell
# Apply default lifecycle policy
Set-AzStorageLifecyclePolicy `
    -StorageAccountName "stproddata001" `
    -ResourceGroupName "rg-prod" `
    -UseDefault

# Custom lifecycle rules
$rules = @(
    @{
        Enabled = $true
        Name = 'ArchiveOldLogs'
        Type = 'Lifecycle'
        Definition = @{
            Actions = @{
                BaseBlob = @{
                    TierToArchive = @{
                        DaysAfterModificationGreaterThan = 90
                    }
                }
            }
            Filters = @{
                BlobTypes = @('blockBlob')
                PrefixMatch = @('logs/')
            }
        }
    }
)
Set-AzStorageLifecyclePolicy `
    -StorageAccountName "stproddata001" `
    -ResourceGroupName "rg-prod" `
    -PolicyRules $rules
```

### Compliance Reporting

```powershell
# Generate compliance report for all storage accounts
$compliance = Get-AzStorageComplianceReport -ExportPath ".\storage-compliance.csv"

# View summary
$compliance.Summary

# View non-compliant accounts
$compliance.Details | Where-Object { $_.ComplianceScore -lt 80 }
```

### Cost Analysis and Optimization

```powershell
# Analyze storage costs
$costs = Get-AzStorageCostAnalysis `
    -StorageAccountName "stproddata001" `
    -ResourceGroupName "rg-prod" `
    -IncludeRecommendations

# View recommendations
$costs.Recommendations

# Archive old data
Start-AzStorageDataArchival `
    -StorageAccountName "stproddata001" `
    -ResourceGroupName "rg-prod" `
    -DaysOld 180 `
    -WhatIf
```

### Backup and Disaster Recovery

```powershell
# Enable backup with point-in-time restore
Enable-AzStorageBackup `
    -StorageAccountName "stproddata001" `
    -ResourceGroupName "rg-prod" `
    -RetentionDays 30

# Configure cross-region replication
Start-AzStorageReplication `
    -SourceStorageAccount "stprodeast" `
    -SourceResourceGroup "rg-prod-east" `
    -TargetStorageAccount "stprodwest" `
    -TargetResourceGroup "rg-prod-west"
```

## Security Best Practices

The module enforces the following security defaults:

1. **HTTPS-only traffic** - Enforces encrypted connections
2. **TLS 1.2 minimum** - Ensures modern encryption protocols
3. **No public blob access** - Prevents anonymous access
4. **Network restrictions** - Default deny with explicit allows
5. **Blob versioning** - Enables recovery from modifications
6. **Soft delete** - Protects against accidental deletion
7. **Advanced Threat Protection** - Detects anomalous activities

## Lifecycle Policy Templates

### Default Policy
- **Hot to Cool**: 30 days after last modification
- **Cool to Archive**: 90 days after last modification
- **Delete**: 365 days for temporary data
- **Snapshot cleanup**: 90 days

### Custom Policies
Create custom policies based on:
- Blob prefix patterns
- Access patterns
- Business requirements
- Compliance needs

## Compliance Scoring

Compliance score calculation (100 points total):
- HTTPS enforcement: 10 points
- TLS 1.2: 10 points
- Public access disabled: 15 points
- Network restrictions: 15 points
- Blob versioning: 10 points
- Soft delete: 10 points
- ATP enabled: 10 points
- Encryption: 10 points
- Proper tagging: 10 points

## Cost Optimization Tips

1. **Use lifecycle policies** to automatically tier data
2. **Archive old data** that's rarely accessed
3. **Delete empty containers** to reduce management overhead
4. **Use appropriate replication** based on DR requirements
5. **Monitor large blobs** for compression opportunities
6. **Review access patterns** to optimize storage tiers

## Troubleshooting

### Common Issues

1. **Permission errors**: Ensure you have Storage Account Contributor role
2. **ATP activation fails**: Check if Defender for Storage is enabled in subscription
3. **Lifecycle policy not applying**: Verify blob index tags and prefixes
4. **Replication setup fails**: Check network connectivity between regions