# Az.Resources Enterprise Module

Enterprise-grade Azure resource management with advanced tagging, compliance, and governance features.

## Features

- **Resource Group Management**: Create and manage resource groups with enterprise standards
- **Tag Management**: Enforce tagging standards with inheritance and bulk operations
- **Naming Conventions**: Validate and enforce resource naming standards
- **Bulk Operations**: Perform operations on multiple resources in parallel
- **Dependency Mapping**: Visualize resource dependencies
- **Cost Tracking**: Analyze costs by tags and resource groups

## Requirements

- PowerShell 7.0 or higher
- Az.Resources module 6.5.0 or higher
- ThreadJob module 2.0.3 or higher

## Installation

```powershell
# Import the module
Import-Module ./Az.Resources.Enterprise.psd1
```

## Tagging Standards

The module enforces the following tagging standards:

**Required Tags:**
- Environment (Dev, Test, Prod)
- CostCenter
- Owner
- Project

**Optional Tags:**
- Department
- ExpirationDate
- Compliance
- DataClassification

## Usage Examples

### Resource Group Management

```powershell
# Create resource group with enterprise standards
$tags = @{
    Environment = "Production"
    CostCenter = "IT001"
    Owner = "admin@contoso.com"
    Project = "WebApp"
}
New-AzResourceGroupAdvanced -Name "rg-prod-webapp" -Location "eastus" -Tags $tags -ApplyLock

# Safely remove resource group with validation
Remove-AzResourceGroupSafely -Name "rg-dev-test" -ExportResources
```

### Tag Management

```powershell
# Apply tags with inheritance from resource group
Get-AzResource -ResourceGroupName "rg-prod" | 
    Set-AzResourceTags -Tags @{Compliance="SOC2"} -InheritFromResourceGroup -Merge

# Test and fix tag compliance
$compliance = Test-AzResourceCompliance -ResourceGroupName "rg-prod" -FixNonCompliant
$compliance.Summary
```

### Naming Convention Validation

```powershell
# Validate resource name
Test-AzResourceNamingConvention -ResourceName "vm-prod-web01" -ResourceType "Microsoft.Compute/virtualMachines"

# Bulk rename resources
$mappings = @{
    "oldvm1" = "vm-prod-web01"
    "oldvm2" = "vm-prod-app01"
}
Rename-AzResourceBatch -ResourceMappings $mappings
```

### Bulk Operations

```powershell
# Stop all VMs in a resource group
Get-AzVM -ResourceGroupName "rg-dev" | 
    Start-AzResourceBulkOperation -Operation Stop -ThrottleLimit 5

# Start VMs with specific tag
Get-AzResource -Tag @{Environment="Dev"} -ResourceType "Microsoft.Compute/virtualMachines" |
    Start-AzResourceBulkOperation -Operation Start
```

### Resource Dependencies

```powershell
# Map dependencies in a resource group
$dependencies = Get-AzResourceDependencies -ResourceGroupName "rg-prod" -ExportPath ".\dependencies.json"

# View dependency visualization
$dependencies.Visualization
```

### Cost Analysis

```powershell
# Analyze costs by tags
$costs = Get-AzResourceCostByTag -TagKeys @('CostCenter', 'Environment')
$costs | Format-Table TagCombination, ResourceCount, EstimatedMonthlyCost

# Export cost report
$costs | Export-Csv -Path ".\cost-report.csv" -NoTypeInformation
```

## Best Practices

1. Always use the required tags when creating resources
2. Run compliance tests regularly to ensure tagging standards
3. Use bulk operations with appropriate throttle limits
4. Export resource information before deletion
5. Validate naming conventions before resource creation
6. Use dependency mapping before making architectural changes

## Naming Convention Examples

| Resource Type | Pattern | Example |
|--------------|---------|---------|
| Virtual Machine | vm-{env}-{app}{number} | vm-prod-web01 |
| Storage Account | st{purpose}{uniqueid} | stbackup001 |
| Virtual Network | vnet-{env}-{purpose} | vnet-prod-core |
| Network Security Group | nsg-{env}-{purpose} | nsg-prod-web |
| SQL Server | sql-{env}-{app} | sql-prod-erp |
| Web App | app-{env}-{app} | app-prod-api |
| Key Vault | kv-{env}-{purpose} | kv-prod-secrets |