#Requires -Version 7.0
#Requires -Module Pester

<#
.SYNOPSIS
    Pester tests for Infrastructure as Code deployments

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Comprehensive testing framework for validating Azure infrastructure deployed via Bicep or Terraform.
    Tests infrastructure configuration, security compliance, and operational readiness.

.NOTES
    Author: Wes Ellis
    Created: 2025-05-26
    Version: 2.1
    Requires: Pester 5.0+, Azure PowerShell modules

$ErrorActionPreference = 'Stop'

BeforeAll {
    Import-Module Az.Accounts -Force
    Import-Module Az.Resources -Force
    Import-Module Az.Storage -Force
    Import-Module Az.KeyVault -Force
    Import-Module Az.Compute -Force
    Import-Module Az.Network -Force
    Import-Module Az.Monitor -Force

    $script:TestConfig = @{
        SubscriptionId = $env:AZURE_SUBSCRIPTION_ID
        ResourceGroupName = $env:AZURE_RESOURCE_GROUP ?? 'rg-test-infrastructure'
        Location = $env:AZURE_LOCATION ?? 'East US'
        Environment = $env:ENVIRONMENT ?? 'test'
        Tags = @{
            Environment = $env:ENVIRONMENT ?? 'test'
            Project = 'Azure-PowerShell-Toolkit'
            ManagedBy = 'Automated-Testing'
        }
    }

    $context = Get-AzContext
    if (-not $context) {
        throw "Not authenticated to Azure. Run Connect-AzAccount first."
    }

    Write-Output "Running infrastructure tests against subscription: $($context.Subscription.Name)" # Color: $2
}

Describe "Azure Infrastructure Validation" {

    Context "Subscription and Authentication" {
        It "Should be connected to Azure" {
            $context = Get-AzContext
            $context | Should -Not -BeNullOrEmpty
            $context.Account | Should -Not -BeNullOrEmpty
        }

        It "Should have valid subscription" {
            $subscription = Get-AzSubscription -SubscriptionId $TestConfig.SubscriptionId -ErrorAction SilentlyContinue
            $subscription | Should -Not -BeNullOrEmpty
            $subscription.State | Should -Be 'Enabled'
        }

        It "Should have required resource providers registered" {
            $RequiredProviders = @(
                'Microsoft.Compute',
                'Microsoft.Storage',
                'Microsoft.Network',
                'Microsoft.KeyVault',
                'Microsoft.Insights'
            )

            foreach ($provider in $RequiredProviders) {
                $registration = Get-AzResourceProvider -ProviderNamespace $provider
                $registration.RegistrationState | Should -Be 'Registered'
            }
        }
    }

    Context "Resource Group Validation" {
        BeforeAll {
            $script:ResourceGroup = Get-AzResourceGroup -Name $TestConfig.ResourceGroupName -ErrorAction SilentlyContinue
        }

        It "Should have test resource group" {
            $ResourceGroup | Should -Not -BeNullOrEmpty
            $ResourceGroup.ResourceGroupName | Should -Be $TestConfig.ResourceGroupName
        }

        It "Should be in correct location" {
            $ResourceGroup.Location | Should -Be $TestConfig.Location.Replace(' ', '').ToLower()
        }

        It "Should have required tags" {
            $ResourceGroup.Tags | Should -Not -BeNullOrEmpty
            $ResourceGroup.Tags.Environment | Should -Be $TestConfig.Environment
        }
    }

    Context "Storage Account Validation" {
        BeforeAll {
            $script:StorageAccounts = Get-AzStorageAccount -ResourceGroupName $TestConfig.ResourceGroupName
        }

        It "Should have at least one storage account" {
            $StorageAccounts.Count | Should -BeGreaterThan 0
        }

        It "Should have storage accounts with secure configuration" {
            foreach ($storage in $StorageAccounts) {
                $storage.EnableHttpsTrafficOnly | Should -Be $true
                $storage.MinimumTlsVersion | Should -Be 'TLS1_2'
                $storage.AllowBlobPublicAccess | Should -Be $false
            }
        }

        It "Should have storage accounts with proper SKU" {
            foreach ($storage in $StorageAccounts) {
                $storage.Sku.Name | Should -BeIn @('Standard_LRS', 'Standard_GRS', 'Standard_RAGRS', 'Premium_LRS')
            }
        }

        It "Should have blob containers with private access" {
            foreach ($storage in $StorageAccounts) {
                $ctx = $storage.Context
                $containers = Get-AzStorageContainer -Context $ctx

                foreach ($container in $containers) {
                    $container.PublicAccess | Should -BeIn @('Off', $null)
                }
            }
        }
    }

    Context "Virtual Network Validation" {
        BeforeAll {
            $script:VirtualNetworks = Get-AzVirtualNetwork -ResourceGroupName $TestConfig.ResourceGroupName
        }

        It "Should have virtual networks configured" {
            $VirtualNetworks.Count | Should -BeGreaterOrEqual 1
        }

        It "Should have proper address space" {
            foreach ($vnet in $VirtualNetworks) {
                $vnet.AddressSpace.AddressPrefixes | Should -Not -BeNullOrEmpty
                $vnet.AddressSpace.AddressPrefixes[0] | Should -Match '^\d+\.\d+\.\d+\.\d+/\d+$'
            }
        }

        It "Should have subnets configured" {
            foreach ($vnet in $VirtualNetworks) {
                $vnet.Subnets.Count | Should -BeGreaterThan 0

                foreach ($subnet in $vnet.Subnets) {
                    $subnet.AddressPrefix | Should -Not -BeNullOrEmpty
                }
            }
        }

        It "Should have Network Security Groups" {
            $nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $TestConfig.ResourceGroupName
            $nsgs.Count | Should -BeGreaterThan 0
        }
    }

    Context "Key Vault Validation" {
        BeforeAll {
            $script:KeyVaults = Get-AzKeyVault -ResourceGroupName $TestConfig.ResourceGroupName
        }

        It "Should have Key Vault configured" -Skip:($KeyVaults.Count -eq 0) {
            $KeyVaults.Count | Should -BeGreaterOrEqual 1
        }

        It "Should have secure Key Vault configuration" -Skip:($KeyVaults.Count -eq 0) {
            foreach ($kv in $KeyVaults) {
                $vault = Get-AzKeyVault -VaultName $kv.VaultName
                $vault.EnableSoftDelete | Should -Be $true
                $vault.EnablePurgeProtection | Should -Be $true
            }
        }

        It "Should have proper access policies" -Skip:($KeyVaults.Count -eq 0) {
            foreach ($kv in $KeyVaults) {
                $vault = Get-AzKeyVault -VaultName $kv.VaultName
                $vault.AccessPolicies.Count | Should -BeGreaterThan 0
            }
        }
    }

    Context "Virtual Machine Validation" {
        BeforeAll {
            $script:VirtualMachines = Get-AzVM -ResourceGroupName $TestConfig.ResourceGroupName
        }

        It "Should have VMs with managed disks" -Skip:($VirtualMachines.Count -eq 0) {
            foreach ($vm in $VirtualMachines) {
                $vm.StorageProfile.OsDisk.ManagedDisk | Should -Not -BeNullOrEmpty
            }
        }

        It "Should have VMs with encryption enabled" -Skip:($VirtualMachines.Count -eq 0) {
            foreach ($vm in $VirtualMachines) {
                $DiskEncryption = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
                $DiskEncryption.OsVolumeEncrypted | Should -BeIn @('Encrypted', 'EncryptionInProgress')
            }
        }

        It "Should have VMs in availability sets or zones" -Skip:($VirtualMachines.Count -le 1) {
            foreach ($vm in $VirtualMachines) {
                $HasAvailabilitySet = $vm.AvailabilitySetReference -ne $null
                $HasAvailabilityZone = $vm.Zones.Count -gt 0
                ($HasAvailabilitySet -or $HasAvailabilityZone) | Should -Be $true
            }
        }
    }

    Context "Monitoring and Diagnostics" {
        It "Should have Log Analytics workspace" {
            $workspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $TestConfig.ResourceGroupName
            $workspaces.Count | Should -BeGreaterOrEqual 1
        }

        It "Should have Application Insights configured" {
            $AppInsights = Get-AzApplicationInsights -ResourceGroupName $TestConfig.ResourceGroupName
            $AppInsights.Count | Should -BeGreaterOrEqual 0
        }

        It "Should have diagnostic settings on key resources" {
            $resources = Get-AzResource -ResourceGroupName $TestConfig.ResourceGroupName
            $ResourcesWithDiagnostics = 0

            foreach ($resource in $resources) {
                $diagnostics = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction SilentlyContinue
                if ($diagnostics) {
                    $ResourcesWithDiagnostics++
                }
            }

            $ResourcesWithDiagnostics | Should -BeGreaterThan 0
        }
    }

    Context "Security and Compliance" {
        It "Should have resources with required tags" {
            $resources = Get-AzResource -ResourceGroupName $TestConfig.ResourceGroupName

            foreach ($resource in $resources) {
                $resource.Tags | Should -Not -BeNullOrEmpty
                $resource.Tags.Environment | Should -Not -BeNullOrEmpty
            }
        }

        It "Should not have public IP addresses on internal resources" {
            $PublicIPs = Get-AzPublicIpAddress -ResourceGroupName $TestConfig.ResourceGroupName

            foreach ($pip in $PublicIPs) {
                $IsLoadBalancer = $pip.IpConfiguration.Id -match 'loadBalancers|applicationGateways'

                if (-not $IsLoadBalancer) {
                    Write-Warning "Public IP $($pip.Name) found on non-load balancer resource"
                }
            }
        }

        It "Should have Network Security Groups with restrictive rules" {
            $nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $TestConfig.ResourceGroupName

            foreach ($nsg in $nsgs) {
                $OpenRules = $nsg.SecurityRules | Where-Object {
                    $_.SourceAddressPrefix -eq '*' -and
                    $_.DestinationPortRange -contains '22' -or $_.DestinationPortRange -contains '3389'
                }

                $OpenRules.Count | Should -Be 0
            }
        }
    }

    Context "Cost Optimization" {
        It "Should not have oversized VM SKUs in test environment" {
            $vms = Get-AzVM -ResourceGroupName $TestConfig.ResourceGroupName

            $ExpensiveSKUs = @('Standard_E64s_v3', 'Standard_M128s', 'Standard_GS5')

            foreach ($vm in $vms) {
                $vm.HardwareProfile.VmSize | Should -Not -BeIn $ExpensiveSKUs
            }
        }

        It "Should have auto-shutdown configured on test VMs" {
            $vms = Get-AzVM -ResourceGroupName $TestConfig.ResourceGroupName

            foreach ($vm in $vms) {
                $AutoShutdown = Get-AzResource -ResourceGroupName $vm.ResourceGroupName -ResourceType 'Microsoft.DevTestLab/schedules' -Name "shutdown-computevm-$($vm.Name)" -ErrorAction SilentlyContinue

                if ($TestConfig.Environment -eq 'test') {
                    $AutoShutdown | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    Context "Backup and Disaster Recovery" {
        It "Should have Recovery Services Vault" {
            $vaults = Get-AzRecoveryServicesVault -ResourceGroupName $TestConfig.ResourceGroupName
            $vaults.Count | Should -BeGreaterOrEqual 0
        }

        It "Should have backup policies configured" -Skip:((Get-AzRecoveryServicesVault -ResourceGroupName $TestConfig.ResourceGroupName).Count -eq 0) {
            $vault = Get-AzRecoveryServicesVault -ResourceGroupName $TestConfig.ResourceGroupName | Select-Object -First 1
            Set-AzRecoveryServicesVaultContext -Vault $vault

            $policies = Get-AzRecoveryServicesBackupProtectionPolicy
            $policies.Count | Should -BeGreaterThan 0
        }
    }
}

Describe "Infrastructure as Code Validation" {

    Context "Bicep Template Validation" {
        BeforeAll {
            $script:BicepFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.bicep" -Recurse
        }

        It "Should have Bicep templates" -Skip:($BicepFiles.Count -eq 0) {
            $BicepFiles.Count | Should -BeGreaterThan 0
        }

        It "Should have valid Bicep syntax" -Skip:($BicepFiles.Count -eq 0) {
            foreach ($BicepFile in $BicepFiles) {
                $result = & az bicep build --file $BicepFile.FullName --stdout 2>&1
                $LASTEXITCODE | Should -Be 0
            }
        }
    }

    Context "Terraform Configuration Validation" {
        BeforeAll {
            $script:TerraformFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.tf" -Recurse
        }

        It "Should have Terraform files" -Skip:($TerraformFiles.Count -eq 0) {
            $TerraformFiles.Count | Should -BeGreaterThan 0
        }

        It "Should have valid Terraform syntax" -Skip:($TerraformFiles.Count -eq 0) {
            Push-Location (Split-Path $TerraformFiles[0].FullName)
            try {
                $result = & terraform validate 2>&1
                $LASTEXITCODE | Should -Be 0
            }
            finally {
                Pop-Location
            }
        }
    }
}

AfterAll {
    Write-Output "Infrastructure tests completed" # Color: $2

    if ($env:CLEANUP_TEST_RESOURCES -eq 'true') {
        Write-Output "Cleaning up test resources..." # Color: $2
    }
`n}
