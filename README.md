# Azure PowerShell Toolkit

A collection of PowerShell scripts for Azure infrastructure management and automation.

[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-5391FE?style=flat-square&logo=powershell&logoColor=white)](https://github.com/PowerShell/PowerShell)
[![Azure](https://img.shields.io/badge/Azure-Ready-0078D4?style=flat-square&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/wesellis/Azure-PowerShell-Toolkit?style=flat-square)](https://github.com/wesellis/Azure-PowerShell-Toolkit/stargazers)
[![Last Commit](https://img.shields.io/github/last-commit/wesellis/Azure-PowerShell-Toolkit?style=flat-square)](https://github.com/wesellis/Azure-PowerShell-Toolkit/commits)

## Overview

This repository contains PowerShell scripts organized by Azure service categories. Scripts include proper error handling, parameter validation, and follow PowerShell best practices.

## Features

- **Organized by Service**: Scripts categorized by Azure service (Compute, Storage, Network, etc.)
- **PowerShell 7.0+ Compatible**: Modern PowerShell syntax and features
- **Proper Error Handling**: Comprehensive error handling and logging
- **Parameter Validation**: Input validation and help documentation
- **Security Focus**: Secure credential handling and compliance features

## Repository Structure

```
├── scripts/          # PowerShell scripts organized by Azure service
│   ├── compute/      # Virtual machines and containers
│   ├── storage/      # Storage accounts and databases
│   ├── network/      # Networking and security
│   ├── identity/     # Azure AD and RBAC
│   ├── cost/         # Cost management and optimization
│   ├── monitoring/   # Monitoring and alerting
│   └── utilities/    # General utilities
├── bicep/            # Azure Bicep templates
│   ├── compute/      # VM and compute resources
│   ├── storage/      # Storage account templates
│   └── network/      # Networking templates
├── terraform/        # Terraform configurations
│   ├── compute/      # VM infrastructure
│   ├── storage/      # Storage resources
│   └── network/      # Network infrastructure
├── docs/             # Documentation
├── modules/          # PowerShell modules
└── tests/            # Test scripts
```

## Quick Start

### Prerequisites

```powershell
# Install required modules
Install-Module -Name Az -Scope CurrentUser
Install-Module -Name AzureAD -Scope CurrentUser

# Verify PowerShell 7.0+
$PSVersionTable.PSVersion
```

### Basic Usage

```powershell
# Clone the repository
git clone https://github.com/wesellis/Azure-PowerShell-Toolkit.git
cd Azure-PowerShell-Toolkit

# Connect to Azure
Connect-AzAccount

# Run a script
.\scripts\compute\Azure-VM-List-All.ps1
```

## Content

### PowerShell Scripts
- **Compute**: VM management, containers, app services
- **Storage**: Storage accounts, databases, backup
- **Network**: Virtual networks, security groups, load balancers
- **Identity**: Azure AD, RBAC, security policies
- **Cost**: Cost analysis, optimization, budgets
- **Monitoring**: Alerts, diagnostics, logging
- **Utilities**: Helper functions and tools

### Infrastructure as Code
- **Bicep**: Azure-native declarative templates
- **Terraform**: Multi-cloud infrastructure provisioning

## Contributing

See [Contributing Guidelines](docs/contributing/CONTRIBUTING.md) for development setup and standards.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
---

## Project Status & Roadmap

**Completion: ~85% - Quality Improvement Phase**

### What Works
- ✅ 772 PowerShell scripts for Azure management
- ✅ Comprehensive Azure service coverage
- ✅ Script catalog and documentation
- ✅ GitHub Actions CI/CD with PSScriptAnalyzer
- ✅ Security scanning (CodeQL, Gitleaks)
- ✅ IAC validation for Bicep and Terraform
- ✅ Organized by Azure services
- ✅ Usage examples and README files

### Quality Status (Updated: 2025-10-02)

**Comprehensive Quality Review Completed** - See [QUALITY_REVIEW.md](QUALITY_REVIEW.md) for full details

📊 **Quality Metrics:**
- Scripts Reviewed: 42 representative samples from 772 total
- High Quality: ~30% (6 scripts confirmed excellent)
- Issues Found: ~65-70% have quality issues
- Critical Issues: ~30% (incorrect type casting, hardcoded values, syntax errors)

⚠️ **Known Issues Being Addressed:**
- **CRITICAL**: Incorrect `[string]` type casting on object variables (~30% of scripts)
- **HIGH**: Malformed help documentation (missing `#>` tags, syntax errors)
- **HIGH**: Hardcoded customer/subscription values (security risk)
- **HIGH**: Broken syntax in several scripts
- **MEDIUM**: Missing or incorrectly placed `[CmdletBinding()]` attributes
- **MEDIUM**: Missing parameter validation in older scripts

### Current Remediation Plan

**Phase 1 (In Progress):** Critical Issue Resolution
- Fix all incorrect `[string]` type casts
- Remove hardcoded sensitive values
- Repair malformed help blocks and syntax errors
- Assigned to 3-person team (see QUALITY_REVIEW.md for assignments)

**Phase 2 (Week 2):** Standard Compliance
- Standardize `[CmdletBinding()]` placement
- Add comprehensive parameter validation
- Improve error handling consistency

**Phase 3 (Week 3):** Quality Assurance
- Add automated testing
- Comprehensive documentation review
- Security audit and compliance verification

### Team Assignments

Scripts divided into 3 equal groups for parallel remediation:
- **Team Member 1:** Scripts 1-258 (compute, devops, identity, integration, iot, migration)
- **Team Member 2:** Scripts 259-516 (monitoring, network, security, storage start)
- **Team Member 3:** Scripts 517-772 (storage end, utilities)

See [QUALITY_REVIEW.md](QUALITY_REVIEW.md) for detailed script assignments and quality checklist.

### Current Status

This is a **large collection** of 772 PowerShell scripts covering extensive Azure automation scenarios. A comprehensive quality review revealed that while scripts are functional, approximately 65-70% need quality improvements before production deployment.

**Immediate Priority:** Addressing critical issues (type casting, hardcoded values, syntax errors) to ensure scripts are production-ready and secure.

**Note**: Quality improvement in progress - see QUALITY_REVIEW.md for detailed status and team assignments.
