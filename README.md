# Azure Enterprise Toolkit

[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://microsoft.com/PowerShell)
[![Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Enterprise Ready](https://img.shields.io/badge/Enterprise-Ready-brightgreen?style=for-the-badge)](https://github.com/wesellis/Azure-Enterprise-Toolkit)

> **The ultimate enterprise-grade Azure automation toolkit featuring 124+ PowerShell scripts, cost management dashboards, DevOps templates, governance policies, and essential administrative resources.**

**Author**: Wesley Ellis | **Email**: wes@wesellis.com | **Website**: wesellis.com

---

## 🎯 **What Makes This Special**

This comprehensive toolkit consolidates five specialized Azure repositories into one enterprise-grade solution:

- 🔥 **124+ Production-Ready Scripts** - Complete Azure infrastructure automation
- 💰 **Cost Management Suite** - Dashboards, analytics, and optimization tools  
- 🚀 **DevOps Templates** - Enterprise CI/CD pipeline templates
- 🛡️ **Governance Toolkit** - Policies, compliance, and security automation
- 🔖 **Essential Resources** - Curated bookmarks and quick-access tools
- 📚 **Unified Documentation** - Comprehensive guides and best practices
- 🔧 **Utility Tools** - Administrative helpers and management scripts

---

## 📁 **Repository Structure**

```
Azure-Enterprise-Toolkit/
├── 🤖 automation-scripts/     # 124+ PowerShell automation scripts
│   ├── Compute-Management/    # VM, AKS, Container scripts (31 scripts)
│   ├── Network-Security/      # VNet, NSG, Key Vault scripts (19 scripts)
│   ├── Data-Storage/          # SQL, Storage, Cosmos scripts (15 scripts)
│   ├── Identity-Governance/   # RBAC, Policy, Compliance scripts (12 scripts)
│   ├── Monitoring-Operations/ # Monitoring, Alerts, Cost scripts (21 scripts)
│   ├── App-Development/       # App Service, Function scripts (14 scripts)
│   ├── General-Utilities/     # Cross-service utilities (8 scripts)
│   └── modules/               # Shared PowerShell modules
├── 💰 cost-management/        # Cost analysis and optimization
│   ├── dashboards/            # Power BI and web dashboards
│   ├── scripts/               # Cost automation scripts
│   └── docs/                  # Cost management documentation
├── 🚀 devops-templates/       # CI/CD pipeline templates
│   ├── templates/             # YAML pipeline templates
│   ├── examples/              # Real-world usage examples
│   └── docs/                  # DevOps documentation
├── 🛡️ governance/             # Policies and compliance
│   ├── scripts/               # Governance automation scripts
│   ├── templates/             # ARM & Bicep templates
│   └── docs/                  # Governance guides
├── 🔖 bookmarks/              # Essential Azure resources
│   ├── Azure-Bookmarks-Import.html  # Browser import file
│   └── index.html             # Interactive web interface
├── 📚 docs/                   # Unified documentation
├── 🔧 tools/                  # Utility scripts
└── 📄 README.md               # This file
```

---

## 🚀 **Quick Start**

### **Prerequisites**
- **PowerShell 7.0+** (Windows/Linux/macOS compatible)
- **Azure PowerShell Module** (`Install-Module Az`)
- **Azure Account** with appropriate permissions
- **Git** (for repository management)

### **Installation**

```powershell
# 1. Clone the repository
git clone https://github.com/wesellis/Azure-Enterprise-Toolkit.git
cd Azure-Enterprise-Toolkit

# 2. Install Azure PowerShell (if not already installed)
Install-Module Az -Force -AllowClobber

# 3. Connect to Azure
Connect-AzAccount

# 4. Run your first automation script
.\automation-scripts\Compute-Management\Azure-VM-Provisioning-Tool-Enhanced.ps1
```

---

## 💡 **Featured Capabilities**

### **🤖 Automation Scripts (124+ Scripts)**

**Enterprise VM Management**
```powershell
# Enhanced VM provisioning with enterprise features
.\automation-scripts\Compute-Management\Azure-VM-Provisioning-Tool-Enhanced.ps1 `
    -ResourceGroupName "prod-rg" `
    -VmName "web-vm-01" `
    -VmSize "Standard_D2s_v3" `
    -EnableBootDiagnostics
```

**AKS Cluster Automation**
```powershell
# Deploy production-ready Kubernetes cluster
.\automation-scripts\Compute-Management\Azure-AKS-Cluster-Provisioning-Tool.ps1 `
    -ClusterName "prod-aks" `
    -NodeCount 3 `
    -EnableMonitoring
```

**Network Security Automation**
```powershell
# Complete VNet with security groups
.\automation-scripts\Network-Security\Azure-VNet-Provisioning-Tool.ps1 `
    -VNetName "prod-vnet" `
    -AddressPrefix "10.0.0.0/16"
```

### **💰 Cost Management**

- **Interactive Dashboards** - Real-time cost visualization with Power BI
- **Automated Reporting** - Scheduled cost analysis and alerts
- **Budget Monitoring** - Proactive spending control and notifications
- **Optimization Tools** - AI-powered cost reduction recommendations

### **🚀 DevOps Templates**

**Multi-Technology Support**
- ✅ .NET Core/Framework applications
- ✅ Node.js and Python projects  
- ✅ Docker containerization
- ✅ Kubernetes deployments
- ✅ Terraform infrastructure
- ✅ ARM template deployments

**Enterprise Features**
- ✅ Multi-environment deployments
- ✅ Security scanning integration
- ✅ Automated testing pipelines
- ✅ Rollback strategies

### **🛡️ Governance & Compliance**

- **Policy Management** - Enterprise-grade Azure Policy deployment
- **Compliance Monitoring** - Automated scanning and reporting
- **RBAC Automation** - Role-based access control management
- **Security Baseline** - Industry-standard security configurations

---

## 🎯 **Use Cases**

### **Enterprise Infrastructure**
- **Large-scale VM deployments** with standardized configurations
- **Multi-subscription management** with centralized governance
- **Cost optimization** across enterprise Azure environments
- **Compliance automation** for regulated industries

### **DevOps Excellence**
- **Standardized CI/CD pipelines** across development teams
- **Infrastructure as Code** with Terraform and ARM templates
- **Automated testing** and security scanning integration
- **Multi-environment deployment** strategies

### **Cloud Governance**
- **Policy enforcement** at scale across subscriptions
- **Cost control** with automated budgets and alerts
- **Security baseline** implementation and monitoring
- **Compliance reporting** for audits and regulations

### **Operational Efficiency**
- **Automated routine tasks** for Azure administration
- **Standardized procedures** for common operations
- **Self-service capabilities** for development teams
- **Monitoring and alerting** for proactive management

---

## 📊 **Enterprise Features**

### **✨ Professional User Experience**
- 🎨 **Interactive Banners** - Beautiful ASCII art headers with script info
- 📊 **Progress Indicators** - Step-by-step progress with percentage completion
- 🎯 **Colored Output** - Success (Green), Warnings (Yellow), Errors (Red)
- 🔄 **Retry Logic** - Automatic retry with exponential backoff

### **🛡️ Enterprise Security**
- 🔐 **RBAC Validation** - Automatic permission checking
- 📋 **Audit Logging** - Comprehensive logging with timestamps
- 🔒 **Secure Credentials** - SecureString and Key Vault integration
- ✅ **Input Validation** - Extensive parameter validation

### **📈 Production Reliability**
- 🔄 **Error Handling** - Try-catch blocks with meaningful messages
- 📊 **Operation Tracking** - Detailed logging of all operations
- 🎯 **Validation Checks** - Pre-flight dependency verification
- 🔧 **Cleanup on Failure** - Automatic rollback capabilities

---

## 🏗️ **Architecture Highlights**

### **Modular Design**
- **Shared Modules** - Common functions across all scripts
- **Category Organization** - Logical grouping by Azure service
- **Template Reuse** - Standardized patterns and approaches
- **Documentation Standards** - Consistent help and examples

### **Cross-Platform Support**
- **Windows 10/11** - Full native support
- **Linux** - Complete compatibility with PowerShell Core
- **macOS** - Cross-platform Azure management
- **Azure Cloud Shell** - Browser-based execution

### **Integration Ready**
- **CI/CD Pipelines** - Templates for automated deployments
- **Monitoring Integration** - Built-in Azure Monitor support
- **Security Integration** - Azure Security Center enablement
- **Cost Integration** - Automated cost tracking and alerts

---

## 📚 **Documentation**

### **Component Documentation**
- **[Automation Scripts Guide](automation-scripts/README.md)** - Complete script reference
- **[Cost Management Guide](cost-management/README.md)** - Dashboard and optimization tools
- **[DevOps Templates Guide](devops-templates/README.md)** - CI/CD implementation
- **[Governance Guide](governance/README.md)** - Policy and compliance automation
- **[Bookmarks Guide](bookmarks/README.md)** - Essential resource collection

### **Getting Started Guides**
- **[Installation Guide](docs/installation.md)** - Step-by-step setup
- **[Configuration Guide](docs/configuration.md)** - Authentication and settings
- **[Best Practices](docs/best-practices.md)** - Enterprise recommendations
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

---

## 🤝 **Contributing**

We welcome contributions from the Azure community! This toolkit is built by practitioners for practitioners.

### **Ways to Contribute**
- 🐛 **Bug Reports** - Help us improve reliability
- 💡 **Feature Requests** - Suggest new automation scenarios
- 📖 **Documentation** - Help other administrators get started
- 🧪 **Testing** - Validate scripts in different environments
- 🚀 **New Scripts** - Add automation for additional scenarios

### **Contributing Guidelines**
1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-automation`)
3. **Commit** your changes (`git commit -m 'Add amazing Azure automation'`)
4. **Push** to the branch (`git push origin feature/amazing-automation`)
5. **Create** a Pull Request

**[Detailed Contributing Guidelines →](CONTRIBUTING.md)**

---

## 📊 **Project Statistics**

- **124+** Production-ready PowerShell scripts
- **7** Major component categories
- **5** Consolidated repositories
- **3** Enterprise dashboard types
- **Multiple** CI/CD template technologies
- **Comprehensive** governance and compliance coverage
- **Cross-platform** compatibility
- **Enterprise-grade** security and reliability

---

## 🏆 **Recognition & Usage**

- **Enterprise Environments** - Used in managing 8,200+ devices globally
- **Production Proven** - Battle-tested automation in real-world scenarios
- **Community Driven** - Built with feedback from Azure administrators
- **Continuously Updated** - Regular updates with new Azure features
- **Comprehensive Coverage** - End-to-end Azure lifecycle management

---

## 📞 **Support & Contact**

**Wesley Ellis** - System Engineer III @ CompuCom Systems Inc.  
📧 **Email**: wes@wesellis.com  
🌐 **Website**: [wesellis.com](https://wesellis.com)  
💼 **LinkedIn**: [Wesley Ellis](https://linkedin.com/in/wesleyellis)  
🐙 **GitHub**: [@wesellis](https://github.com/wesellis)

### **Getting Help**
- 📚 **Documentation** - Check the comprehensive guides in `/docs`
- 🐛 **Issues** - Report bugs and request features via GitHub Issues
- 💬 **Discussions** - Join community discussions for Q&A
- 📧 **Direct Support** - Email for enterprise consulting and custom automation

---

## 📄 **License**

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**Free for personal and commercial use** - Build amazing Azure automation!

---

## 🙏 **Acknowledgments**

- **Microsoft Azure Team** - For comprehensive APIs and excellent documentation
- **PowerShell Community** - For outstanding tools and best practices
- **Azure Administrators** - For real-world feedback and testing
- **DevOps Community** - For CI/CD patterns and deployment strategies
- **Contributors** - For making this toolkit better with every release

---

<div align="center">

### 🌟 **Star this repository if it helps you automate Azure!** 🌟

**Enterprise Azure automation made simple and reliable**  
*124+ scripts • 7 components • 100% production ready*

[![GitHub stars](https://img.shields.io/github/stars/wesellis/Azure-Enterprise-Toolkit?style=for-the-badge&logo=github)](https://github.com/wesellis/Azure-Enterprise-Toolkit/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/wesellis/Azure-Enterprise-Toolkit?style=for-the-badge&logo=github)](https://github.com/wesellis/Azure-Enterprise-Toolkit/network)

</div>

---

**Azure Enterprise Toolkit** - *Transforming Azure administration from complex to simple*