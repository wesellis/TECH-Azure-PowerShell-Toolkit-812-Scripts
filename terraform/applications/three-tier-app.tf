# Three-Tier Web Application Infrastructure
# Web Tier (Load Balancer + VMs) -> App Tier (VMs) -> Data Tier (SQL Database)

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "app_name" {
  description = "Application name prefix"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]{2,10}$", var.app_name))
    error_message = "App name must be 2-10 alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "admin_username" {
  description = "VM administrator username"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "VM administrator password"
  type        = string
  sensitive   = true
}

variable "db_admin_username" {
  description = "Database administrator username"
  type        = string
  default     = "dbadmin"
}

variable "db_admin_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "web_tier_vm_count" {
  description = "Number of web tier VMs"
  type        = number
  default     = 2
}

variable "app_tier_vm_count" {
  description = "Number of app tier VMs"
  type        = number
  default     = 2
}

# Local values
locals {
  resource_prefix = "${var.app_name}-${var.environment}"
  is_prod        = var.environment == "prod"

  common_tags = {
    Environment = var.environment
    Application = var.app_name
    ManagedBy   = "Terraform"
  }
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.resource_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# Networking Module
module "networking" {
  source = "../modules/networking"

  vnet_name           = "${local.resource_prefix}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]

  subnets = {
    web = {
      address_prefixes = ["10.0.1.0/24"]
      purpose         = "web"
      create_nsg      = true
    }
    app = {
      address_prefixes = ["10.0.2.0/24"]
      purpose         = "app"
      create_nsg      = true
    }
    data = {
      address_prefixes = ["10.0.3.0/24"]
      purpose         = "data"
      create_nsg      = true
    }
    management = {
      address_prefixes = ["10.0.4.0/24"]
      purpose         = "general"
      create_nsg      = true
    }
  }

  enable_nat_gateway = true
  tags              = local.common_tags
}

# Load Balancer for Web Tier
resource "azurerm_public_ip" "web_lb_pip" {
  name                = "${local.resource_prefix}-web-lb-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = local.is_prod ? ["1", "2", "3"] : null
  domain_name_label   = "${local.resource_prefix}-${random_string.suffix.result}"
  tags                = local.common_tags
}

resource "azurerm_lb" "web_lb" {
  name                = "${local.resource_prefix}-web-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  tags                = local.common_tags

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.web_lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_lb_pool" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "web-servers"
}

resource "azurerm_lb_rule" "web_lb_rule" {
  loadbalancer_id                = azurerm_lb.web_lb.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_lb_pool.id]
  probe_id                       = azurerm_lb_probe.web_lb_probe.id
}

resource "azurerm_lb_probe" "web_lb_probe" {
  loadbalancer_id = azurerm_lb.web_lb.id
  name            = "http-probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/health"
}

# Internal Load Balancer for App Tier
resource "azurerm_lb" "app_lb" {
  name                = "${local.resource_prefix}-app-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  tags                = local.common_tags

  frontend_ip_configuration {
    name                          = "InternalIP"
    subnet_id                     = module.networking.subnet_ids["app"]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "app_lb_pool" {
  loadbalancer_id = azurerm_lb.app_lb.id
  name            = "app-servers"
}

resource "azurerm_lb_rule" "app_lb_rule" {
  loadbalancer_id                = azurerm_lb.app_lb.id
  name                           = "AppTier"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "InternalIP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_lb_pool.id]
  probe_id                       = azurerm_lb_probe.app_lb_probe.id
}

resource "azurerm_lb_probe" "app_lb_probe" {
  loadbalancer_id = azurerm_lb.app_lb.id
  name            = "app-probe"
  port            = 8080
  protocol        = "Http"
  request_path    = "/health"
}

# Web Tier VMs
module "web_tier" {
  source = "../modules/compute"

  vm_name             = "${local.resource_prefix}-web"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  instance_count      = var.web_tier_vm_count
  vm_size             = local.is_prod ? "Standard_D2s_v3" : "Standard_B2s"
  os_type             = "Linux"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  subnet_id                    = module.networking.subnet_ids["web"]
  network_security_group_id    = module.networking.nsg_ids["web"]
  create_public_ip            = false
  availability_zones          = local.is_prod ? ["1", "2"] : []
  enable_availability_set     = !local.is_prod

  # Custom data to install web server
  custom_data = base64encode(templatefile("${path.module}/scripts/web-tier-init.sh", {
    app_lb_ip = azurerm_lb.app_lb.frontend_ip_configuration[0].private_ip_address
  }))

  tags = local.common_tags
}

# Web Tier Load Balancer Association
resource "azurerm_network_interface_backend_address_pool_association" "web_lb_association" {
  count = var.web_tier_vm_count

  network_interface_id    = module.web_tier.network_interface_ids[count.index]
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web_lb_pool.id
}

# App Tier VMs
module "app_tier" {
  source = "../modules/compute"

  vm_name             = "${local.resource_prefix}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  instance_count      = var.app_tier_vm_count
  vm_size             = local.is_prod ? "Standard_D4s_v3" : "Standard_B2s"
  os_type             = "Linux"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  subnet_id                    = module.networking.subnet_ids["app"]
  network_security_group_id    = module.networking.nsg_ids["app"]
  create_public_ip            = false
  availability_zones          = local.is_prod ? ["1", "2"] : []
  enable_availability_set     = !local.is_prod

  # Custom data to install app server
  custom_data = base64encode(templatefile("${path.module}/scripts/app-tier-init.sh", {
    db_server = azurerm_mssql_server.main.fully_qualified_domain_name
    db_name   = azurerm_mssql_database.main.name
  }))

  tags = local.common_tags
}

# App Tier Load Balancer Association
resource "azurerm_network_interface_backend_address_pool_association" "app_lb_association" {
  count = var.app_tier_vm_count

  network_interface_id    = module.app_tier.network_interface_ids[count.index]
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_lb_pool.id
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "${local.resource_prefix}-sql-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.db_admin_username
  administrator_login_password = var.db_admin_password
  minimum_tls_version          = "1.2"
  public_network_access_enabled = !local.is_prod
  tags                         = local.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = "${var.app_name}db"
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = local.is_prod ? "GP_Gen5_2" : "S1"
  zone_redundant = local.is_prod
  tags           = local.common_tags

  short_term_retention_policy {
    retention_days = local.is_prod ? 35 : 7
  }

  long_term_retention_policy {
    weekly_retention  = local.is_prod ? "P12W" : null
    monthly_retention = local.is_prod ? "P12M" : null
    yearly_retention  = local.is_prod ? "P5Y" : null
    week_of_year      = local.is_prod ? 1 : null
  }
}

# SQL Firewall Rule for Azure Services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Private Endpoint for SQL Server (Production only)
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  count = local.is_prod ? 1 : 0

  name                = "${local.resource_prefix}-sql-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.subnet_ids["data"]
  tags                = local.common_tags

  private_service_connection {
    name                           = "${local.resource_prefix}-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

# Application Gateway (Production only)
resource "azurerm_public_ip" "app_gateway_pip" {
  count = local.is_prod ? 1 : 0

  name                = "${local.resource_prefix}-agw-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.common_tags
}

resource "azurerm_application_gateway" "main" {
  count = local.is_prod ? 1 : 0

  name                = "${local.resource_prefix}-agw"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = module.networking.subnet_ids["management"]
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_port {
    name = "frontend-port-443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.app_gateway_pip[0].id
  }

  backend_address_pool {
    name         = "web-tier-pool"
    ip_addresses = module.web_tier.private_ip_addresses
  }

  backend_http_settings {
    name                  = "web-tier-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "web-tier-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "web-tier-rule"
    rule_type                  = "Basic"
    http_listener_name         = "web-tier-listener"
    backend_address_pool_name  = "web-tier-pool"
    backend_http_settings_name = "web-tier-settings"
    priority                   = 1
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}

# Outputs
output "application_url" {
  description = "Application URL"
  value = local.is_prod ? (
    length(azurerm_application_gateway.main) > 0 ?
      "http://${azurerm_public_ip.app_gateway_pip[0].ip_address}" :
      "http://${azurerm_public_ip.web_lb_pip.ip_address}"
  ) : "http://${azurerm_public_ip.web_lb_pip.ip_address}"
}

output "database_fqdn" {
  description = "SQL Server FQDN"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "web_tier_ips" {
  description = "Web tier private IP addresses"
  value       = module.web_tier.private_ip_addresses
}

output "app_tier_ips" {
  description = "App tier private IP addresses"
  value       = module.app_tier.private_ip_addresses
}

output "load_balancer_ip" {
  description = "Web load balancer public IP"
  value       = azurerm_public_ip.web_lb_pip.ip_address
}