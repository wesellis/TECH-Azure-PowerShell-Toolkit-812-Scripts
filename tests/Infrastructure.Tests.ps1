#Requires -Version 7.0
#Requires -Module Pester

<#
.SYNOPSIS
    Pester tests for Infrastructure as Code deployments

.DESCRIPTION
    Comprehensive testing framework for validating Azure infrastructure deployed via Bicep or Terraform.
    Tests infrastructure configuration, security compliance, and operational readiness.

.NOTES
    Author: Azure PowerShell Toolkit Team
    Requires: Pester 5.0+, Azure PowerShell modules
#>

BeforeAll {
    # Import required modules
    Import-Module Az.Accounts -Force
    Import-Module Az.Resources -Force
    Import-Module Az.Storage -Force
    Import-Module Az.KeyVault -Force
    Import-Module Az.Compute -Force
    Import-Module Az.Network -Force

    # Configuration
    $script:TestResourceGroup = $env:TEST_RESOURCE_GROUP ?? "toolkit-test-rg"
    $script:TestLocation = $env:TEST_LOCATION ?? "East US"
    $script:TestEnvironment = $env:TEST_ENVIRONMENT ?? "dev"

    # Helper function to wait for resource availability
    function Wait-ForResource {
        param(
            [string]$ResourceName,
            [string]$ResourceGroupName,
            [string]$ResourceType,
            [int]$TimeoutSeconds = 300
        )

        $timeout = (Get-Date).AddSeconds($TimeoutSeconds)
        do {
            try {
                $resource = Get-AzResource -Name $ResourceName -ResourceGroupName $ResourceGroupName -ResourceType $ResourceType -ErrorAction SilentlyContinue
                if ($resource) {
                    return $resource
                }
            } catch {
                Write-Verbose "Waiting for resource: $ResourceName"
            }
            Start-Sleep -Seconds 10
        } while ((Get-Date) -lt $timeout)

        throw "Resource $ResourceName not found within timeout period"
    }
}

Describe "Infrastructure Deployment Validation" {

    Context "Resource Group Validation" {
        It "Should have the test resource group" {
            $rg = Get-AzResourceGroup -Name $script:TestResourceGroup -ErrorAction SilentlyContinue
            $rg | Should -Not -BeNullOrEmpty
            $rg.ResourceGroupName | Should -Be $script:TestResourceGroup
            $rg.Location | Should -Match $script:TestLocation.Replace(' ', '')
        }

        It "Should have appropriate tags" {
            $rg = Get-AzResourceGroup -Name $script:TestResourceGroup
            $rg.Tags | Should -Not -BeNullOrEmpty
            $rg.Tags.Keys | Should -Contain "Environment"
        }
    }

    Context "Virtual Network Validation" {
        BeforeAll {
            $script:VNet = Get-AzVirtualNetwork -ResourceGroupName $script:TestResourceGroup | Select-Object -First 1
        }

        It "Should have a virtual network deployed" {
            $script:VNet | Should -Not -BeNullOrEmpty
        }

        It "Should have correct address space" {
            $script:VNet.AddressSpace.AddressPrefixes | Should -Contain "10.0.0.0/16"
        }

        It "Should have required subnets" {
            $subnets = $script:VNet.Subnets
            $subnets | Should -Not -BeNullOrEmpty
            $subnets.Count | Should -BeGreaterThan 0

            # Check for at least one subnet
            $defaultSubnet = $subnets | Where-Object { $_.Name -eq "default" }
            $defaultSubnet | Should -Not -BeNullOrEmpty
        }

        It "Should have Network Security Groups associated" {
            $nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $script:TestResourceGroup
            $nsgs | Should -Not -BeNullOrEmpty
        }
    }

    Context "Storage Account Validation" {
        BeforeAll {
            $script:StorageAccount = Get-AzStorageAccount -ResourceGroupName $script:TestResourceGroup | Select-Object -First 1
        }

        It "Should have a storage account deployed" {
            $script:StorageAccount | Should -Not -BeNullOrEmpty
        }

        It "Should have HTTPS-only traffic enabled" {
            $script:StorageAccount.EnableHttpsTrafficOnly | Should -Be $true
        }

        It "Should have minimum TLS version set" {
            $script:StorageAccount.MinimumTlsVersion | Should -Be "TLS1_2"
        }

        It "Should have blob public access disabled" {
            $script:StorageAccount.AllowBlobPublicAccess | Should -Be $false
        }

        It "Should have required containers" {
            $ctx = $script:StorageAccount.Context
            $containers = Get-AzStorageContainer -Context $ctx

            $requiredContainers = @("scripts", "logs", "backups")
            foreach ($containerName in $requiredContainers) {
                $container = $containers | Where-Object { $_.Name -eq $containerName }
                $container | Should -Not -BeNullOrEmpty -Because "Container '$containerName' should exist"
            }
        }

        It "Should have appropriate replication based on environment" {
            if ($script:TestEnvironment -eq "prod") {
                $script:StorageAccount.Sku.Name | Should -Match "GRS"
            } else {
                $script:StorageAccount.Sku.Name | Should -Match "LRS"
            }
        }
    }

    Context "Key Vault Validation" {
        BeforeAll {
            $script:KeyVault = Get-AzKeyVault -ResourceGroupName $script:TestResourceGroup | Select-Object -First 1
        }

        It "Should have a Key Vault deployed" {
            $script:KeyVault | Should -Not -BeNullOrEmpty
        }

        It "Should have soft delete enabled" {
            $script:KeyVault.EnableSoftDelete | Should -Be $true
        }

        It "Should have appropriate purge protection for production" {
            if ($script:TestEnvironment -eq "prod") {
                $script:KeyVault.EnablePurgeProtection | Should -Be $true
            }
        }

        It "Should have template deployment enabled" {
            $script:KeyVault.EnabledForTemplateDeployment | Should -Be $true
        }

        It "Should have disk encryption enabled" {
            $script:KeyVault.EnabledForDiskEncryption | Should -Be $true
        }

        It "Should have access policies configured" {
            $script:KeyVault.AccessPolicies | Should -Not -BeNullOrEmpty
        }
    }

    Context "Virtual Machine Validation" {
        BeforeAll {
            $script:VM = Get-AzVM -ResourceGroupName $script:TestResourceGroup | Select-Object -First 1
        }

        It "Should have a virtual machine deployed" {
            $script:VM | Should -Not -BeNullOrEmpty
        }

        It "Should have appropriate VM size for environment" {
            $script:VM.HardwareProfile.VmSize | Should -Not -BeNullOrEmpty

            if ($script:TestEnvironment -eq "prod") {
                $script:VM.HardwareProfile.VmSize | Should -Match "Standard_[D|E].*s_v[3-5]"
            }
        }

        It "Should have managed disks" {
            $script:VM.StorageProfile.OsDisk.ManagedDisk | Should -Not -BeNullOrEmpty
        }

        It "Should have appropriate disk type for environment" {
            if ($script:TestEnvironment -eq "prod") {
                $script:VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType | Should -Be "Premium_LRS"
            } else {
                $script:VM.StorageProfile.OsDisk.ManagedDisk.StorageAccountType | Should -BeIn @("Standard_LRS", "Premium_LRS")
            }
        }

        It "Should have system assigned identity" {
            $script:VM.Identity.Type | Should -Be "SystemAssigned"
            $script:VM.Identity.PrincipalId | Should -Not -BeNullOrEmpty
        }

        It "Should have network interface attached" {
            $script:VM.NetworkProfile.NetworkInterfaces | Should -Not -BeNullOrEmpty
        }
    }

    Context "Security Configuration Validation" {
        It "Should have Network Security Groups with appropriate rules" {
            $nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $script:TestResourceGroup

            foreach ($nsg in $nsgs) {
                # Check for overly permissive rules
                $openRules = $nsg.SecurityRules | Where-Object {
                    $_.SourceAddressPrefix -eq "*" -and $_.Access -eq "Allow" -and $_.Direction -eq "Inbound"
                }

                # Allow HTTP/HTTPS from Internet, but not SSH/RDP
                $dangerousOpenRules = $openRules | Where-Object {
                    $_.DestinationPortRange -in @("22", "3389", "5985", "5986")
                }

                $dangerousOpenRules | Should -BeNullOrEmpty -Because "SSH, RDP, or PowerShell remoting should not be open to Internet"
            }
        }

        It "Should have appropriate firewall rules for Key Vault" {
            $keyVault = Get-AzKeyVault -ResourceGroupName $script:TestResourceGroup | Select-Object -First 1
            if ($keyVault) {
                # In production, Key Vault should have network restrictions
                if ($script:TestEnvironment -eq "prod") {
                    $keyVault.NetworkAcls.DefaultAction | Should -Be "Deny"
                }
            }
        }

        It "Should have diagnostic settings configured for Key Vault" {
            $keyVault = Get-AzKeyVault -ResourceGroupName $script:TestResourceGroup | Select-Object -First 1
            if ($keyVault) {
                $diagnostics = Get-AzDiagnosticSetting -ResourceId $keyVault.ResourceId -ErrorAction SilentlyContinue
                if ($script:TestEnvironment -eq "prod") {
                    $diagnostics | Should -Not -BeNullOrEmpty -Because "Production Key Vaults should have diagnostic settings"
                }
            }
        }
    }

    Context "Monitoring and Logging Validation" {
        It "Should have Log Analytics workspace if deployed" {
            $logWorkspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $script:TestResourceGroup -ErrorAction SilentlyContinue

            if ($logWorkspaces) {
                $logWorkspaces | Should -Not -BeNullOrEmpty
                $logWorkspaces[0].RetentionInDays | Should -BeGreaterThan 0
            }
        }

        It "Should have Application Insights if deployed" {
            $appInsights = Get-AzApplicationInsights -ResourceGroupName $script:TestResourceGroup -ErrorAction SilentlyContinue

            if ($appInsights) {
                $appInsights | Should -Not -BeNullOrEmpty
                $appInsights[0].ApplicationType | Should -Be "web"
            }
        }
    }

    Context "Advanced Resources Validation" {
        It "Should validate AKS cluster if deployed" {
            $aksClusters = Get-AzAksCluster -ResourceGroupName $script:TestResourceGroup -ErrorAction SilentlyContinue

            if ($aksClusters) {
                $cluster = $aksClusters[0]
                $cluster | Should -Not -BeNullOrEmpty
                $cluster.KubernetesVersion | Should -Not -BeNullOrEmpty
                $cluster.AgentPoolProfiles | Should -Not -BeNullOrEmpty

                # Check for system node pool
                $systemPool = $cluster.AgentPoolProfiles | Where-Object { $_.Mode -eq "System" }
                $systemPool | Should -Not -BeNullOrEmpty
            }
        }

        It "Should validate SQL resources if deployed" {
            $sqlServers = Get-AzSqlServer -ResourceGroupName $script:TestResourceGroup -ErrorAction SilentlyContinue

            if ($sqlServers) {
                $server = $sqlServers[0]
                $server | Should -Not -BeNullOrEmpty

                # Check for firewall rules
                $firewallRules = Get-AzSqlServerFirewallRule -ResourceGroupName $script:TestResourceGroup -ServerName $server.ServerName
                $firewallRules | Should -Not -BeNullOrEmpty

                # Check for databases
                $databases = Get-AzSqlDatabase -ResourceGroupName $script:TestResourceGroup -ServerName $server.ServerName
                $userDatabases = $databases | Where-Object { $_.DatabaseName -ne "master" }
                $userDatabases | Should -Not -BeNullOrEmpty
            }
        }

        It "Should validate App Service if deployed" {
            $webApps = Get-AzWebApp -ResourceGroupName $script:TestResourceGroup -ErrorAction SilentlyContinue

            if ($webApps) {
                $webApp = $webApps[0]
                $webApp | Should -Not -BeNullOrEmpty
                $webApp.HttpsOnly | Should -Be $true
                $webApp.SiteConfig | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Resource Tags Validation" {
        It "Should have consistent tagging across resources" {
            $resources = Get-AzResource -ResourceGroupName $script:TestResourceGroup

            $requiredTags = @("Environment", "Project")

            foreach ($resource in $resources) {
                foreach ($tag in $requiredTags) {
                    $resource.Tags.Keys | Should -Contain $tag -Because "Resource $($resource.Name) should have tag '$tag'"
                }
            }
        }

        It "Should have environment tag matching test environment" {
            $resources = Get-AzResource -ResourceGroupName $script:TestResourceGroup

            foreach ($resource in $resources) {
                if ($resource.Tags -and $resource.Tags.ContainsKey("Environment")) {
                    $resource.Tags["Environment"] | Should -Be $script:TestEnvironment
                }
            }
        }
    }

    Context "Cost Optimization Validation" {
        It "Should use appropriate storage tiers for non-production" {
            if ($script:TestEnvironment -ne "prod") {
                $storageAccounts = Get-AzStorageAccount -ResourceGroupName $script:TestResourceGroup

                foreach ($storage in $storageAccounts) {
                    $storage.Sku.Name | Should -Match "LRS" -Because "Non-production environments should use LRS for cost optimization"
                }
            }
        }

        It "Should use appropriate VM sizes for environment" {
            $vms = Get-AzVM -ResourceGroupName $script:TestResourceGroup

            foreach ($vm in $vms) {
                if ($script:TestEnvironment -eq "dev") {
                    $vm.HardwareProfile.VmSize | Should -Match "Standard_B.*" -Because "Development VMs should use B-series for cost optimization"
                }
            }
        }
    }
}

Describe "Operational Readiness Tests" {

    Context "Connectivity Tests" {
        It "Should be able to connect to storage account" {
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $script:TestResourceGroup | Select-Object -First 1
            if ($storageAccount) {
                $ctx = $storageAccount.Context
                { Get-AzStorageContainer -Context $ctx | Select-Object -First 1 } | Should -Not -Throw
            }
        }

        It "Should be able to access Key Vault" {
            $keyVault = Get-AzKeyVault -ResourceGroupName $script:TestResourceGroup | Select-Object -First 1
            if ($keyVault) {
                { Get-AzKeyVaultSecret -VaultName $keyVault.VaultName | Select-Object -First 1 } | Should -Not -Throw
            }
        }
    }

    Context "Performance Baseline" {
        It "Should have acceptable resource provisioning time" {
            # This would typically measure deployment time
            # For now, we'll check that resources are responsive
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $script:TestResourceGroup | Select-Object -First 1
            if ($storageAccount) {
                $startTime = Get-Date
                $containers = Get-AzStorageContainer -Context $storageAccount.Context
                $endTime = Get-Date
                $duration = ($endTime - $startTime).TotalSeconds

                $duration | Should -BeLessThan 30 -Because "Storage operations should be responsive"
            }
        }
    }

    Context "Backup and Recovery Validation" {
        It "Should have backup configuration for production VMs" {
            if ($script:TestEnvironment -eq "prod") {
                $vms = Get-AzVM -ResourceGroupName $script:TestResourceGroup

                foreach ($vm in $vms) {
                    $backupItems = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -VaultId $vm.Id -ErrorAction SilentlyContinue
                    $backupItems | Should -Not -BeNullOrEmpty -Because "Production VMs should have backup configured"
                }
            }
        }

        It "Should have appropriate retention policies" {
            $recoveryVaults = Get-AzRecoveryServicesVault -ResourceGroupName $script:TestResourceGroup -ErrorAction SilentlyContinue

            if ($recoveryVaults) {
                foreach ($vault in $recoveryVaults) {
                    Set-AzRecoveryServicesVaultContext -Vault $vault
                    $policies = Get-AzRecoveryServicesBackupProtectionPolicy
                    $policies | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}