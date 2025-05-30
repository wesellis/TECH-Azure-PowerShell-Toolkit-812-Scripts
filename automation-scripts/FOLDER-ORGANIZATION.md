# Azure Automation Scripts - Complete Organization

**Author**: Wesley Ellis  
**Email**: wes@wesellis.com  
**Website**: wesellis.com  
**Updated**: May 23, 2025  

## 📁 **Complete Folder Organization - 78 Scripts**

All **78 professional Azure automation scripts** are organized into **6 logical folders** based on their primary function and operational purpose.

---

## 🖥️ **Compute-Management** (24 scripts)
*Virtual Machines, Containers, Kubernetes, and Compute Resources*

### Virtual Machine Management (16 scripts)
- `Azure-VM-Backup-Tool.ps1` - Automated VM backup to Recovery Services Vault
- `Azure-VM-Deletion-Tool.ps1` - Safe VM deletion with force option
- `Azure-VM-Health-Monitor.ps1` - Comprehensive VM health and status monitoring
- `Azure-VM-Provisioning-Tool.ps1` - Complete VM provisioning with configurations
- `Azure-VM-Restart-Tool.ps1` - Automated VM restart operations
- `Azure-VM-Restore-Tool.ps1` - VM restore from Recovery Services Vault
- `Azure-VM-Scaling-Tool.ps1` - VM size scaling automation
- `Azure-VM-Shutdown-Tool.ps1` - Controlled VM shutdown
- `Azure-VM-Snapshot-Creator.ps1` - Disk snapshot creation for backup
- `Azure-VM-Startup-Tool.ps1` - Automated VM startup
- `Azure-VM-Update-Tool.ps1` - VM configuration updates
- `Azure-VM-PowerState-Checker.ps1` - ⭐ **NEW** - Quick power state verification
- `Azure-VM-List-All.ps1` - ⭐ **NEW** - Lists all VMs across subscription
- `Azure-VM-Disk-List.ps1` - ⭐ **NEW** - Shows all disks attached to VM
- `Azure-VM-Network-Info.ps1` - ⭐ **NEW** - Displays VM network configuration
- `Azure-VM-Tag-Manager.ps1` - ⭐ **NEW** - Manages VM tags efficiently

### Container & Kubernetes (5 scripts)
- `Azure-AKS-Cluster-Provisioning-Tool.ps1` - AKS cluster provisioning
- `Azure-AKS-Node-Restart-Tool.ps1` - AKS node management
- `Azure-ContainerInstance-Provisioning-Tool.ps1` - Container instance setup
- `Azure-ContainerInstance-Logs.ps1` - ⭐ **NEW** - Container logs viewer
- `Azure-AKS-Credentials-Configurator.ps1` - ⭐ **NEW** - kubectl credentials setup

### Storage & Batch (3 scripts)
- `Azure-BatchAccount-Provisioning-Tool.ps1` - Batch account setup
- `Azure-Disk-Resize-Tool.ps1` - Managed disk resizing
- `Azure-Disk-Snapshot-Creator.ps1` - ⭐ **NEW** - Creates disk snapshots

---

## 🌐 **Network-Security** (13 scripts)
*Networking, Load Balancing, DNS, Security Infrastructure*

### Networking Infrastructure (9 scripts)
- `Azure-VNet-Provisioning-Tool.ps1` - Virtual network provisioning
- `Azure-LoadBalancer-Manager.ps1` - Load balancer management
- `Azure-ApplicationGateway-Provisioning-Tool.ps1` - Application Gateway setup
- `Azure-AppGateway-Update-Tool.ps1` - Application Gateway updates
- `Azure-PublicIP-Creator.ps1` - ⭐ **NEW** - Creates public IP addresses
- `Azure-NSG-Rule-Creator.ps1` - ⭐ **NEW** - Adds NSG security rules
- `Azure-VNet-Subnet-Creator.ps1` - ⭐ **NEW** - Adds subnets to VNets
- `Azure-NetworkInterface-Creator.ps1` - ⭐ **NEW** - Creates network interfaces

### DNS Management (2 scripts)
- `Azure-DNS-Zone-Provisioning-Tool.ps1` - DNS zone setup
- `Azure-DNS-Record-Update-Tool.ps1` - DNS record management

### Security (4 scripts)
- `Azure-KeyVault-Provisioning-Tool.ps1` - Key Vault provisioning
- `Azure-KeyVault-Secret-Creator.ps1` - ⭐ **NEW** - Adds secrets to Key Vault
- `Azure-KeyVault-Secret-Retriever.ps1` - ⭐ **NEW** - Retrieves Key Vault secrets

---

## 💾 **Data-Storage** (11 scripts)
*Databases, Storage Accounts, Data Analytics, Caching*

### Storage Services (6 scripts)
- `Azure-StorageAccount-Provisioning-Tool.ps1` - Storage account provisioning
- `Azure-Storage-Blob-Cleanup-Tool.ps1` - Blob container cleanup automation
- `Azure-Storage-Container-Creator.ps1` - ⭐ **NEW** - Creates blob containers
- `Azure-Storage-Keys-Retriever.ps1` - ⭐ **NEW** - Gets storage account keys
- `Azure-Blob-File-Uploader.ps1` - ⭐ **NEW** - Uploads files to blob storage

### Database Services (3 scripts)
- `Azure-SQL-Database-Provisioning-Tool.ps1` - SQL Database provisioning
- `Azure-CosmosDB-Provisioning-Tool.ps1` - Cosmos DB account provisioning
- `Azure-SQL-Connection-Tester.ps1` - ⭐ **NEW** - Tests SQL connectivity

### Data & Analytics (3 scripts)
- `Azure-DataFactory-Provisioning-Tool.ps1` - Data Factory setup
- `Azure-RedisCache-Provisioning-Tool.ps1` - Redis Cache provisioning
- `Azure-ML-Workspace-Provisioning-Tool.ps1` - ML workspace provisioning

---

## 🚀 **App-Development** (11 scripts)
*Web Apps, Function Apps, Logic Apps, Messaging Services*

### Web Applications (4 scripts)
- `Azure-AppService-Provisioning-Tool.ps1` - App Service provisioning
- `Azure-AppService-Scaling-Tool.ps1` - App Service scaling automation
- `Azure-WebApp-Restart-Tool.ps1` - Web application restart
- `Azure-AppService-Config-Viewer.ps1` - ⭐ **NEW** - Views app configuration

### Serverless & Functions (4 scripts)
- `Azure-FunctionApp-Provisioning-Tool.ps1` - Function App provisioning
- `Azure-FunctionApp-Update-Tool.ps1` - Function App configuration updates
- `Azure-LogicApp-Provisioning-Tool.ps1` - Logic App provisioning
- `Azure-FunctionApp-Setting-Manager.ps1` - ⭐ **NEW** - Manages function settings

### Messaging & Events (3 scripts)
- `Azure-ServiceBus-Provisioning-Tool.ps1` - Service Bus setup
- `Azure-EventGrid-Topic-Provisioning-Tool.ps1` - Event Grid provisioning
- `Azure-ServiceBus-Queue-Creator.ps1` - ⭐ **NEW** - Creates Service Bus queues

---

## 📊 **Monitoring-Operations** (17 scripts)
*Monitoring, Performance, Health Checks, Automation Management*

### Infrastructure Monitoring (8 scripts)
- `Azure-AKS-Status-Monitor.ps1` - AKS cluster monitoring
- `Azure-ApplicationGateway-Health-Monitor.ps1` - Application Gateway monitoring
- `Azure-AppService-Health-Monitor.ps1` - App Service health monitoring
- `Azure-ContainerInstance-Status-Monitor.ps1` - Container instance monitoring
- `Azure-DNS-Zone-Health-Monitor.ps1` - DNS zone health monitoring
- `Azure-ResourceGroup-Cost-Calculator.ps1` - ⭐ **NEW** - Estimates RG costs
- `Azure-Activity-Log-Checker.ps1` - ⭐ **NEW** - Views activity logs
- `Azure-Resource-Health-Checker.ps1` - ⭐ **NEW** - Checks resource health

### Data & Analytics Monitoring (3 scripts)
- `Azure-DataFactory-Pipeline-Monitor.ps1` - Data Factory monitoring
- `Azure-SQL-Database-Monitor.ps1` - SQL Database performance monitoring
- `Azure-Storage-Usage-Monitor.ps1` - Storage account usage monitoring

### Application Monitoring (3 scripts)
- `Azure-FunctionApp-Performance-Monitor.ps1` - Function App monitoring
- `Azure-LogicApp-Workflow-Monitor.ps1` - Logic App workflow monitoring
- `Azure-EventGrid-Performance-Monitor.ps1` - Event Grid monitoring

### Security & Operations (3 scripts)
- `Azure-KeyVault-Security-Monitor.ps1` - Key Vault security monitoring
- `Azure-BatchAccount-Performance-Monitor.ps1` - Batch account monitoring
- `Azure-Automation-Account-Manager.ps1` - Automation account management

---

## 👥 **Identity-Governance** (2 scripts)
*User Management, Security, Compliance*

- `Azure-Bulk-User-Offboarding-Tool.ps1` - Automated user offboarding
- `Azure-ResourceGroup-Creator.ps1` - ⭐ **NEW** - Creates resource groups with tags

---

## 📈 **Final Statistics**

| **Folder** | **Original** | **New Added** | **Total** | **% of Collection** |
|------------|--------------|---------------|-----------|---------------------|
| **🖥️ Compute-Management** | 16 | **+8** | **24** | **31%** |
| **📊 Monitoring-Operations** | 14 | **+3** | **17** | **22%** |
| **🌐 Network-Security** | 7 | **+6** | **13** | **17%** |
| **💾 Data-Storage** | 7 | **+4** | **11** | **14%** |
| **🚀 App-Development** | 8 | **+3** | **11** | **14%** |
| **👥 Identity-Governance** | 1 | **+1** | **2** | **2%** |
| **TOTAL** | **53** | **+25** | **78** | **100%** |

---

## 🎯 **Quick Navigation by Use Case**

### **🔨 Infrastructure Deployment**
```
Compute-Management/     → VMs, containers, Kubernetes
Network-Security/       → VNets, load balancers, DNS
Data-Storage/          → Storage, databases, analytics
```

### **🚀 Application Development**
```
App-Development/       → Web apps, functions, messaging
Network-Security/      → Security, Key Vault
Data-Storage/         → Storage, caching, databases
```

### **📊 Operations & Monitoring**
```
Monitoring-Operations/ → All monitoring and health checks
Identity-Governance/   → Resource groups, user management
```

### **🔧 Daily Operations**
```
Compute-Management/    → VM power states, disk management
Network-Security/      → IP addresses, NSG rules
Data-Storage/         → Storage keys, blob uploads
```

---

## 🌟 **Most Popular New Scripts**

### **Essential Daily Tools:**
1. `Azure-VM-PowerState-Checker.ps1` - Quick VM status
2. `Azure-Resource-Health-Checker.ps1` - Infrastructure health
3. `Azure-PublicIP-Creator.ps1` - Network IP management
4. `Azure-Storage-Container-Creator.ps1` - Blob storage setup
5. `Azure-KeyVault-Secret-Creator.ps1` - Security management

### **Developer Productivity:**
6. `Azure-AKS-Credentials-Configurator.ps1` - kubectl setup
7. `Azure-ContainerInstance-Logs.ps1` - Container debugging
8. `Azure-SQL-Connection-Tester.ps1` - Database connectivity
9. `Azure-AppService-Config-Viewer.ps1` - App configuration
10. `Azure-FunctionApp-Setting-Manager.ps1` - Function management

### **Operations & Monitoring:**
11. `Azure-Activity-Log-Checker.ps1` - Audit and troubleshooting
12. `Azure-ResourceGroup-Cost-Calculator.ps1` - Cost monitoring
13. `Azure-VM-List-All.ps1` - Infrastructure inventory
14. `Azure-Storage-Keys-Retriever.ps1` - Access management
15. `Azure-Blob-File-Uploader.ps1` - File operations

---

## 💡 **Workflow Examples**

### **Complete Environment Setup:**
```powershell
# 1. Foundation
.\Identity-Governance\Azure-ResourceGroup-Creator.ps1 -ResourceGroupName "Prod-RG" -Location "East US"
.\Network-Security\Azure-VNet-Provisioning-Tool.ps1 -ResourceGroupName "Prod-RG" -VnetName "Prod-VNet"

# 2. Security
.\Network-Security\Azure-KeyVault-Provisioning-Tool.ps1 -ResourceGroupName "Prod-RG" -VaultName "ProdKeyVault"
.\Network-Security\Azure-KeyVault-Secret-Creator.ps1 -VaultName "ProdKeyVault" -SecretName "DBPassword"

# 3. Compute & Storage
.\Compute-Management\Azure-VM-Provisioning-Tool.ps1 -ResourceGroupName "Prod-RG" -VmName "ProdVM01"
.\Data-Storage\Azure-StorageAccount-Provisioning-Tool.ps1 -ResourceGroupName "Prod-RG" -StorageAccountName "prodstorage"

# 4. Applications
.\App-Development\Azure-AppService-Provisioning-Tool.ps1 -ResourceGroupName "Prod-RG" -AppName "ProdWebApp"
.\App-Development\Azure-FunctionApp-Provisioning-Tool.ps1 -ResourceGroupName "Prod-RG" -AppName "ProdFunctions"

# 5. Monitoring
.\Monitoring-Operations\Azure-Resource-Health-Checker.ps1 -ResourceGroupName "Prod-RG"
.\Monitoring-Operations\Azure-ResourceGroup-Cost-Calculator.ps1 -ResourceGroupName "Prod-RG"
```

### **Daily Operations Routine:**
```powershell
# Morning health check
.\Compute-Management\Azure-VM-List-All.ps1
.\Monitoring-Operations\Azure-Resource-Health-Checker.ps1 -ResourceGroupName "Prod-RG"
.\Monitoring-Operations\Azure-Activity-Log-Checker.ps1 -ResourceGroupName "Prod-RG" -HoursBack 12

# Quick fixes
.\Compute-Management\Azure-VM-PowerState-Checker.ps1 -ResourceGroupName "Prod-RG" -VmName "ProdVM01"
.\App-Development\Azure-WebApp-Restart-Tool.ps1 -ResourceGroupName "Prod-RG" -AppName "ProdWebApp"

# Weekly cost review
.\Monitoring-Operations\Azure-ResourceGroup-Cost-Calculator.ps1 -ResourceGroupName "Prod-RG"
```

---

## 🏆 **Enterprise Benefits**

✅ **Complete Coverage** - 78 scripts cover all Azure services  
✅ **Logical Organization** - 6 folders based on operational purpose  
✅ **Professional Quality** - Every script has headers and error handling  
✅ **Operational Efficiency** - Find the right tool quickly  
✅ **Team Productivity** - Standardized automation across teams  
✅ **Enterprise Scale** - Production-ready tools  
✅ **Easy Maintenance** - Consistent structure and documentation  

---

*This complete organization structure makes all 78 Azure automation scripts easily discoverable, maintainable, and efficient for enterprise operations.*
