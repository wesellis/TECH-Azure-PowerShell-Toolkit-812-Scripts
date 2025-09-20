# Azure Governance Toolkit

[![PowerShell Gallery](https://img.shields.io/badge/PowerShell%20Gallery-Available-blue.svg)](https://www.powershellgallery.com/)
[![Linting](https://github.com/wesellis/Azure-Governance-Toolkit/actions/workflows/powershell-lint.yml/badge.svg)](https://github.com/wesellis/Azure-Governance-Toolkit/actions/workflows/powershell-lint.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Azure](https://img.shields.io/badge/Azure-Compatible-0078d4.svg)](https://azure.microsoft.com/)

> **Comprehensive collection of PowerShell scripts and ARM templates for implementing robust Azure governance, compliance, and security management.**

Streamline your Azure governance strategy with battle-tested scripts for policy deployment, compliance monitoring, resource management, and security automation. Perfect for enterprise environments requiring strict compliance and governance controls.

## Key Features

- **Policy Management** - Deploy, assign, and monitor Azure policies at scale
- **Compliance Monitoring** - Automated compliance scanning and reporting
- **Resource Governance** - Tagging, locking, and lifecycle management
- **Cost Control** - Budget alerts and spending monitoring
- **Security Automation** - Security Center enablement and configuration
- **Blueprint Deployment** - Standardized environment provisioning
- **Audit & Remediation** - Resource auditing and automated compliance fixes
- **RBAC Management** - Role assignments and access control

## Quick Start

### Prerequisites

- **Azure PowerShell** 5.0 or later
- **Azure CLI** (optional, for some scripts)
- **Contributor** or **Owner** permissions on target subscriptions
- **PowerShell** 5.1 or **PowerShell Core** 6.0+

### Installation

```powershell
# Clone the repository
git clone https://github.com/wesellis/Azure-Governance-Toolkit.git
cd Azure-Governance-Toolkit

# Install required modules
Install-Module -Name Az -Force -AllowClobber
Install-Module -Name Az.PolicyInsights -Force
Install-Module -Name Az.Security -Force

# Connect to Azure
Connect-AzAccount
```

### Basic Usage

```powershell
# Deploy governance policies to a subscription
.\scripts\deploy-governance-policies.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"

# Audit resource compliance
.\scripts\audit-resource-compliance.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"

# Generate compliance report
.\scripts\generate-report.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -OutputPath "./reports"
```

## Project Structure

```
Azure-Governance-Toolkit/
├── scripts/              # PowerShell automation scripts
│   ├── Policy Management
│   ├── Compliance & Auditing  
│   ├── Resource Management
│   ├── Cost Management
│   └── Security & Backup
├── templates/            # ARM & Bicep templates
│   ├── Policy definitions
│   ├── Initiative templates
│   └── Blueprint specifications
├── docs/                # Documentation & guides
├── examples/             # Usage examples
└── tests/               # PowerShell Pester tests
```

## Available Scripts

### Policy & Compliance Management

| Script | Description | Parameters |
|--------|-------------|------------|
| `deploy-governance-policies.ps1` | Deploy core governance policies | `-SubscriptionId`, `-PolicyPath` |
| `assign-policy.ps1` | Assign policies to scopes | `-PolicyId`, `-Scope`, `-Parameters` |
| `create-initiative.ps1` | Create policy initiatives | `-InitiativeName`, `-Policies` |
| `audit-resource-compliance.ps1` | Audit compliance status | `-SubscriptionId`, `-PolicyName` |
| `enable-policy-compliance-scans.ps1` | Enable periodic scans | `-SubscriptionId`, `-Frequency` |
| `remediate-compliance.ps1` | Auto-remediate non-compliant resources | `-SubscriptionId`, `-PolicyAssignmentId` |

### Monitoring & Reporting

| Script | Description | Parameters |
|--------|-------------|------------|
| `generate-report.ps1` | Generate compliance reports | `-SubscriptionId`, `-OutputPath`, `-Format` |
| `audit-resources.ps1` | Comprehensive resource audit | `-SubscriptionId`, `-ResourceGroup` |
| `monitor-activity-logs.ps1` | Monitor and alert on activities | `-SubscriptionId`, `-AlertEmail` |

### Resource Management

| Script | Description | Parameters |
|--------|-------------|------------|
| `tag-resources.ps1` | Apply tags across resources | `-SubscriptionId`, `-TagName`, `-TagValue` |
| `configure-resource-locks.ps1` | Configure resource locks | `-SubscriptionId`, `-LockType`, `-Scope` |
| `deploy-resource-group.ps1` | Deploy standardized RGs | `-ResourceGroupName`, `-Location`, `-Tags` |

### Cost Management

| Script | Description | Parameters |
|--------|-------------|------------|
| `create-budget-alerts.ps1` | Create budget monitoring | `-SubscriptionId`, `-BudgetAmount`, `-AlertEmail` |

### Security & Backup

| Script | Description | Parameters |
|--------|-------------|------------|
| `enable-security-center.ps1` | Enable Azure Security Center | `-SubscriptionId`, `-Tier` |
| `configure-backup-policies.ps1` | Configure VM/SQL backups | `-SubscriptionId`, `-PolicyName` |
| `configure-diagnostic-settings.ps1` | Enable diagnostic logging | `-ResourceId`, `-WorkspaceId` |
| `manage-nsg-rules.ps1` | Manage NSG security rules | `-NetworkSecurityGroupName`, `-Rules` |

### Identity & Access

| Script | Description | Parameters |
|--------|-------------|------------|
| `manage-role-assignments.ps1` | Manage RBAC assignments | `-SubscriptionId`, `-PrincipalId`, `-RoleDefinition` |
| `apply-blueprint.ps1` | Apply Azure Blueprints | `-BlueprintId`, `-SubscriptionId`, `-Parameters` |

## ARM Templates

### Policy Templates
- **`policy-assignment.json`** - Assign policies to management groups or subscriptions
- **`initiative-definition.json`** - Create comprehensive policy initiatives
- **`custom-policy-definition.json`** - Define custom organizational policies

### Governance Templates
- **`resource-group-template.json`** - Standardized resource group deployment
- **`tagging-policy-template.json`** - Enforce consistent resource tagging
- **`security-baseline-template.json`** - Apply security baseline configurations

## Documentation

- **[Getting Started Guide](docs/getting-started.md)** - Step-by-step setup instructions
- **[Script Reference](docs/script-reference.md)** - Detailed parameter documentation
- **[Architecture Guide](docs/architecture.md)** - Governance framework design
- **[Best Practices](docs/best-practices.md)** - Azure governance recommendations
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## Use Cases

### Enterprise Governance
- Multi-subscription policy enforcement
- Compliance monitoring and reporting
- Standardized resource deployment
- Cost management and optimization

### Security & Compliance
- Security baseline implementation
- Regulatory compliance automation
- Resource vulnerability scanning
- Access control management

### Operational Excellence
- Resource lifecycle management
- Automated remediation workflows
- Monitoring and alerting setup
- Backup and disaster recovery

## Contributing

We welcome contributions from the Azure community! Whether you're fixing bugs, adding new scripts, or improving documentation, your help makes this toolkit better for everyone.

**[Contributing Guidelines →](CONTRIBUTING.md)**

### Quick Contribution Steps
1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-script`)
3. **Commit** your changes (`git commit -m 'Add amazing governance script'`)
4. **Push** to the branch (`git push origin feature/amazing-script`)
5. **Create** a Pull Request

### Areas We Need Help With
- **New Scripts** - Additional governance automation
- **Testing** - PowerShell Pester test coverage
- **Documentation** - Usage examples and guides
- **Bug Fixes** - Issue resolution and improvements
- **Code Review** - Security and best practice validation

## Project Stats

- **19** PowerShell governance scripts
- **3** ARM template examples
- **Automated testing** with Pester
- **PowerShell linting** validation
- **Comprehensive documentation**
- **Community-driven** development

## Security

This toolkit handles sensitive Azure resources and permissions. Please:

- **Review scripts** before execution in production
- **Use least-privilege** access principles
- **Test in dev/staging** environments first
- **Report security issues** via private disclosure

## License

This project is licensed under the [MIT License](LICENSE) - see the file for details.

## Support

- **Bug Reports** - [Create an issue](https://github.com/wesellis/Azure-Governance-Toolkit/issues/new?template=bug_report.md)
- **Feature Requests** - [Suggest improvements](https://github.com/wesellis/Azure-Governance-Toolkit/issues/new?template=feature_request.md)
- **Questions** - [Start a discussion](https://github.com/wesellis/Azure-Governance-Toolkit/discussions)
- **Documentation** - Check our [docs folder](docs/) for guides

## Acknowledgments

- **Microsoft Azure** team for comprehensive governance APIs
- **PowerShell community** for excellent tooling and best practices
- **Contributors** who help maintain and improve this toolkit
- **Azure governance community** for sharing knowledge and use cases

---

**Azure Governance Toolkit**

Made for Azure administrators and cloud architects

[Get Started](docs/getting-started.md) • [Documentation](docs/) • [Contribute](CONTRIBUTING.md) • [Discussions](https://github.com/wesellis/Azure-Governance-Toolkit/discussions)