<#
.SYNOPSIS
    Tests for Az.KeyVault.Enterprise module
.DESCRIPTION
#>

BeforeAll {
    # Import the module
    $ModulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModulePath\Az.KeyVault.Enterprise.psd1" -Force
    
    # Mock Azure cmdlets
    Mock Get-AzKeyVault {
        [PSCustomObject]@{
            VaultName = "TestVault"
            ResourceGroupName = "TestRG"
            Location = "eastus"
            ResourceId = "/subscriptions/xxx/resourceGroups/TestRG/providers/Microsoft.KeyVault/vaults/TestVault"
            EnableSoftDelete = $true
            EnablePurgeProtection = $true
            Sku = "Standard"
            NetworkAcls = @{ DefaultAction = "Deny" }
        }
    }
    
    Mock Get-AzKeyVaultSecret {
        [PSCustomObject]@{
            Name = "TestSecret"
            Version = "1234567890"
            Enabled = $true
            Expires = (Get-Date).AddDays(30)
            Updated = (Get-Date).AddDays(-60)
            SecretValue = ConvertTo-SecureString "OldSecretValue" -AsPlainText -Force
        }
    }
    
    Mock Set-AzKeyVaultSecret {
        [PSCustomObject]@{
            Name = "TestSecret"
            Version = "0987654321"
            Enabled = $true
            SecretValue = ConvertTo-SecureString "NewSecretValue" -AsPlainText -Force
        }
    }
}

Describe "Az.KeyVault.Enterprise Module Tests" {
    
    Context "Module Loading" {
        It "Should have exported functions" {
            $module = Get-Module -ErrorAction Stop Az.KeyVault.Enterprise
            $module.ExportedFunctions.Count | Should -BeGreaterThan 0
        }
        
        It "Should export expected functions" {
            $expectedFunctions = @(
                'Start-AzKeyVaultSecretRotation',
                'New-AzKeyVaultRotationPolicy',
                'Start-AzKeyVaultCertificateLifecycle',
                'Get-AzKeyVaultCertificateReport',
                'Set-AzKeyVaultAccessPolicyBulk',
                'New-AzKeyVaultAccessPolicyTemplate',
                'Enable-AzKeyVaultMonitoring',
                'Get-AzKeyVaultComplianceReport',
                'Start-AzKeyVaultAccessReview'
            )
            
            $module = Get-Module -ErrorAction Stop Az.KeyVault.Enterprise
            foreach ($function in $expectedFunctions) {
                $module.ExportedFunctions.Keys | Should -Contain $function
            }
        }
    }
    
    Context "Start-AzKeyVaultSecretRotation" {
        
        BeforeEach {
            Mock Send-SecretRotationNotification { }
        }
        
        It "Should rotate secrets older than threshold" {
            $result = Start-AzKeyVaultSecretRotation -VaultName "TestVault" -SecretName "TestSecret" -RotationDays 30
            
            Should -Invoke Set-AzKeyVaultSecret -Times 1
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should not rotate secrets newer than threshold" {
            Mock Get-AzKeyVaultSecret {
                [PSCustomObject]@{
                    Name = "TestSecret"
                    Updated = (Get-Date).AddDays(-10)
                    SecretValue = ConvertTo-SecureString "CurrentSecret" -AsPlainText -Force
                }
            }
            
            Start-AzKeyVaultSecretRotation -VaultName "TestVault" -SecretName "TestSecret" -RotationDays 30
            Should -Invoke Set-AzKeyVaultSecret -Times 0
        }
        
        It "Should send notification when email provided" {
            Start-AzKeyVaultSecretRotation -VaultName "TestVault" -SecretName "TestSecret" -RotationDays 30 -NotificationEmail "test@example.com"
            
            Should -Invoke Send-SecretRotationNotification -Times 1
        }
        
        It "Should create backup when rollback enabled" {
            Start-AzKeyVaultSecretRotation -VaultName "TestVault" -SecretName "TestSecret" -RotationDays 30 -EnableRollback
            
            Should -Invoke Set-AzKeyVaultSecret -Times 2 # Once for backup, once for new secret
        }
    }
    
    Context "New-AzKeyVaultRotationPolicy" {
        
        It "Should create rotation policy with required parameters" {
            $policy = New-AzKeyVaultRotationPolicy -VaultName "TestVault" -PolicyName "TestPolicy"
            
            $policy.PolicyName | Should -Be "TestPolicy"
            $policy.VaultName | Should -Be "TestVault"
            $policy.RotationDays | Should -Be 90
            $policy.IsEnabled | Should -Be $true
        }
        
        It "Should store policy in Key Vault" {
            New-AzKeyVaultRotationPolicy -VaultName "TestVault" -PolicyName "TestPolicy" -RotationDays 60
            
            Should -Invoke Set-AzKeyVaultSecret -Times 1 -ParameterFilter { $Name -eq "RotationPolicy-TestPolicy" }
        }
    }
    
    Context "Get-AzKeyVaultCertificateReport" {
        
        BeforeEach {
            Mock Get-AzKeyVaultCertificate -ErrorAction Stop {
                @(
                    [PSCustomObject]@{
                        Name = "Cert1"
                        Created = (Get-Date).AddDays(-30)
                        Enabled = $true
                        Version = "abc123"
                    },
                    [PSCustomObject]@{
                        Name = "Cert2"
                        Created = (Get-Date).AddDays(-300)
                        Enabled = $true
                        Version = "def456"
                    }
                )
            }
            
            Mock Get-AzKeyVaultCertificate -ParameterFilter { $Name -and $Version } {
                $cert = New-Object -ErrorAction Stop System.Security.Cryptography.X509Certificates.X509Certificate2
                [PSCustomObject]@{
                    Certificate = [PSCustomObject]@{
                        Subject = "CN=TestCert"
                        Issuer = "CN=TestCA"
                        Thumbprint = "1234567890ABCDEF"
                        NotAfter = if ($Name -eq "Cert1") { (Get-Date).AddDays(60) } else { (Get-Date).AddDays(-10) }
                    }
                    KeyProperties = @{
                        KeyType = "RSA"
                        KeySize = 2048
                    }
                }
            }
        }
        
        It "Should generate certificate report" {
            $report = Get-AzKeyVaultCertificateReport -VaultName "TestVault"
            
            $report.Count | Should -Be 2
            $report[0].Status | Should -BeIn @('Valid', 'Warning', 'Critical', 'Expired')
        }
        
        It "Should identify expired certificates" {
            $report = Get-AzKeyVaultCertificateReport -VaultName "TestVault"
            
            $expiredCert = $report | Where-Object { $_.CertificateName -eq "Cert2" }
            $expiredCert.Status | Should -Be "Expired"
            $expiredCert.DaysUntilExpiry | Should -BeLessThan 0
        }
        
        It "Should export report when path provided" {
            Mock Export-Csv { }
            
            Get-AzKeyVaultCertificateReport -VaultName "TestVault" -OutputPath ".\test-report.csv"
            
            Should -Invoke Export-Csv -Times 1
        }
    }
    
    Context "Set-AzKeyVaultAccessPolicyBulk" {
        
        BeforeEach {
            Mock Set-AzKeyVaultAccessPolicy -ErrorAction Stop { }
            Mock Remove-AzKeyVaultAccessPolicy -ErrorAction Stop { }
        }
        
        It "Should apply policies to multiple vaults" {
            $vaults = @("Vault1", "Vault2")
            $objectIds = @("user1", "user2")
            
            Set-AzKeyVaultAccessPolicyBulk -VaultNames $vaults -ObjectIds $objectIds -PermissionsToSecrets @('Get', 'List')
            
            Should -Invoke Set-AzKeyVaultAccessPolicy -Times 4 # 2 vaults x 2 users
        }
        
        It "Should remove existing policies when specified" {
            Set-AzKeyVaultAccessPolicyBulk -VaultNames @("TestVault") -ObjectIds @("user1") -RemoveExisting -PermissionsToSecrets @('Get')
            
            Should -Invoke Remove-AzKeyVaultAccessPolicy -Times 1
        }
    }
    
    Context "Get-AzKeyVaultComplianceReport" {
        
        BeforeEach {
            Mock Get-AzKeyVaultAccessPolicy -ErrorAction Stop {
                @(
                    [PSCustomObject]@{
                        ObjectId = "user1"
                        DisplayName = "Test User"
                        PermissionsToSecrets = @('Get', 'List', 'Set', 'Delete')
                    }
                )
            }
            
            Mock Get-AzKeyVaultSecret {
                @(
                    [PSCustomObject]@{
                        Name = "Secret1"
                        Expires = (Get-Date).AddDays(-5)
                    }
                )
            }
            
            Mock Get-AzKeyVaultCertificate -ErrorAction Stop { @() }
        }
        
        It "Should generate compliance report" {
            $report = Get-AzKeyVaultComplianceReport -VaultNames @("TestVault")
            
            $report.VaultCount | Should -Be 1
            $report.ComplianceScore | Should -BeGreaterThan 0
            $report.VaultDetails | Should -Not -BeNullOrEmpty
        }
        
        It "Should identify compliance issues" {
            Mock Get-AzKeyVault {
                [PSCustomObject]@{
                    VaultName = "TestVault"
                    EnableSoftDelete = $false
                    EnablePurgeProtection = $false
                    NetworkAcls = @{ DefaultAction = "Allow" }
                }
            }
            
            $report = Get-AzKeyVaultComplianceReport -VaultNames @("TestVault")
            $vaultDetails = $report.VaultDetails[0]
            
            $vaultDetails.ComplianceIssues | Should -Contain "Soft delete not enabled"
            $vaultDetails.ComplianceIssues | Should -Contain "Purge protection not enabled"
            $vaultDetails.ComplianceIssues | Should -Contain "Network restrictions not configured"
            $vaultDetails.Score | Should -BeLessThan 50
        }
    }
    
    Context "Enable-AzKeyVaultMonitoring" {
        
        BeforeEach {
            Mock New-AzDiagnosticSetting -ErrorAction Stop { }
            Mock New-AzDiagnosticSettingLogSettingsObject -ErrorAction Stop { [PSCustomObject]@{} }
            Mock New-AzDiagnosticSettingMetricSettingsObject -ErrorAction Stop { [PSCustomObject]@{} }
            Mock New-AzKeyVaultAlertRules -ErrorAction Stop { }
        }
        
        It "Should configure diagnostic settings" {
            Enable-AzKeyVaultMonitoring -VaultName "TestVault" -WorkspaceId "/subscriptions/xxx/workspace"
            
            Should -Invoke New-AzDiagnosticSetting -Times 1
            Should -Invoke New-AzKeyVaultAlertRules -Times 1
        }
        
        It "Should configure specified log categories" {
            Enable-AzKeyVaultMonitoring -VaultName "TestVault" -WorkspaceId "workspace" -LogCategories @('AuditEvent')
            
            Should -Invoke New-AzDiagnosticSettingLogSettingsObject -Times 1 -ParameterFilter { $Category -eq 'AuditEvent' }
        }
    }
}

Describe "Helper Function Tests" {
    
    Context "New-SecurePassword" {
        
        It "Should generate password of specified length" {
            $password = New-SecurePassword -Length 16
            $plaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
            )
            
            $plaintext.Length | Should -Be 16
        }
        
        It "Should exclude special characters when specified" {
            $password = New-SecurePassword -Length 20 -ExcludeSpecialCharacters
            $plaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
            )
            
            $plaintext | Should -Match '^[a-zA-Z0-9]+$'
        }
    }
}

#endregion

