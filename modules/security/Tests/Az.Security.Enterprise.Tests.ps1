#Requires -Module Pester
<#
.SYNOPSIS
    Tests for Az.Security.Enterprise module
.DESCRIPTION
    Comprehensive test suite for enterprise security management functions
#>

BeforeAll {
    # Import the module
    $ModulePath = Split-Path -Parent $PSScriptRoot
    Import-Module "$ModulePath\Az.Security.Enterprise.psd1" -Force
    
    # Mock Azure cmdlets
    Mock Get-AzContext {
        [PSCustomObject]@{
            Subscription = [PSCustomObject]@{
                Id = "12345678-1234-1234-1234-123456789012"
                Name = "Test Subscription"
            }
        }
    }
    
    Mock Set-AzContext { }
    
    Mock Set-AzSecurityPricing {
        [PSCustomObject]@{
            Name = $Name
            PricingTier = $PricingTier
            SubPlan = $SubPlan
        }
    }
    
    Mock Get-AzSecurityPricing {
        @(
            [PSCustomObject]@{
                Name = "VirtualMachines"
                PricingTier = "Standard"
                SubPlan = "P2"
                Extensions = @()
            },
            [PSCustomObject]@{
                Name = "SqlServers"
                PricingTier = "Free"
                SubPlan = $null
                Extensions = @()
            }
        )
    }
    
    Mock Set-AzSecurityAutoProvisioningSetting { }
    Mock Set-AzSecurityContact { }
    Mock Set-AzSecurityWorkspaceSetting { }
    
    Mock Get-AzSecuritySecureScore {
        [PSCustomObject]@{
            Name = "ascScore"
            Score = [PSCustomObject]@{
                Current = 65
                Max = 100
                Percentage = 65
            }
            Weight = 100
            DisplayName = "ASC score"
            Properties = [PSCustomObject]@{
                LastUpdateTime = Get-Date
            }
        }
    }
    
    Mock Get-AzSecurityTask {
        @(
            [PSCustomObject]@{
                Name = "EnableMFA"
                State = "Active"
                ResourceId = "/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm1"
                SecurityTaskParameters = [PSCustomObject]@{
                    Name = "Enable MFA for admin accounts"
                    Description = "Multi-factor authentication should be enabled"
                    Severity = "High"
                    RecommendationType = "EnableMFA"
                    RemediationDescription = "Enable MFA in Azure AD"
                }
            }
        )
    }
}

Describe "Az.Security.Enterprise Module Tests" {
    
    Context "Module Loading" {
        It "Should have exported functions" {
            $module = Get-Module Az.Security.Enterprise
            $module.ExportedFunctions.Count | Should -BeGreaterThan 0
        }
        
        It "Should export expected functions" {
            $expectedFunctions = @(
                'Enable-AzSecurityCenterAdvanced',
                'Set-AzDefenderPlan',
                'Get-AzDefenderCoverage',
                'New-AzSecurityPolicySet',
                'Test-AzSecurityCompliance',
                'Start-AzVulnerabilityAssessment',
                'Get-AzVulnerabilityReport',
                'Get-AzSecurityScore',
                'Set-AzSecurityScoreTarget',
                'Get-AzSecurityRecommendations',
                'Invoke-AzSecurityRecommendation'
            )
            
            $module = Get-Module Az.Security.Enterprise
            foreach ($function in $expectedFunctions) {
                $module.ExportedFunctions.Keys | Should -Contain $function
            }
        }
    }
    
    Context "Enable-AzSecurityCenterAdvanced" {
        
        It "Should configure Security Center with standard tier" {
            Enable-AzSecurityCenterAdvanced -SubscriptionId "12345678-1234-1234-1234-123456789012" -Tier "Standard"
            
            Should -Invoke Set-AzSecurityPricing -Times 12 # Number of resource types
        }
        
        It "Should enable auto-provisioning when specified" {
            Enable-AzSecurityCenterAdvanced -SubscriptionId "12345678-1234-1234-1234-123456789012" -EnableAutoProvisioning
            
            Should -Invoke Set-AzSecurityAutoProvisioningSetting -Times 1 -ParameterFilter { $EnableAutoProvision -eq $true }
        }
        
        It "Should configure security contacts" {
            Enable-AzSecurityCenterAdvanced -SubscriptionId "12345678-1234-1234-1234-123456789012" `
                -SecurityContactEmails @("test@example.com") `
                -SecurityContactPhone "+1234567890"
            
            Should -Invoke Set-AzSecurityContact -Times 1
        }
        
        It "Should configure workspace settings when provided" {
            $workspaceSettings = @{WorkspaceId = "/subscriptions/xxx/workspace"}
            Enable-AzSecurityCenterAdvanced -SubscriptionId "12345678-1234-1234-1234-123456789012" `
                -WorkspaceSettings $workspaceSettings
            
            Should -Invoke Set-AzSecurityWorkspaceSetting -Times 1
        }
    }
    
    Context "Set-AzDefenderPlan" {
        
        It "Should enable Defender plan" {
            Set-AzDefenderPlan -PlanName "VirtualMachines" -Enable
            
            Should -Invoke Set-AzSecurityPricing -Times 1 -ParameterFilter { 
                $Name -eq "VirtualMachines" -and $PricingTier -eq "Standard" 
            }
        }
        
        It "Should disable Defender plan" {
            Set-AzDefenderPlan -PlanName "VirtualMachines" -Enable:$false
            
            Should -Invoke Set-AzSecurityPricing -Times 1 -ParameterFilter { 
                $Name -eq "VirtualMachines" -and $PricingTier -eq "Free" 
            }
        }
        
        It "Should set sub-plan when specified" {
            Set-AzDefenderPlan -PlanName "VirtualMachines" -Enable -SubPlan "P2"
            
            Should -Invoke Set-AzSecurityPricing -Times 1 -ParameterFilter { $SubPlan -eq "P2" }
        }
    }
    
    Context "Get-AzDefenderCoverage" {
        
        BeforeEach {
            Mock Get-AzResource {
                @(
                    [PSCustomObject]@{ResourceId = "/subscriptions/xxx/vm1"; ResourceType = "Microsoft.Compute/virtualMachines"},
                    [PSCustomObject]@{ResourceId = "/subscriptions/xxx/sql1"; ResourceType = "Microsoft.Sql/servers"}
                )
            }
        }
        
        It "Should calculate coverage percentage" {
            $coverage = Get-AzDefenderCoverage
            
            $coverage.CoveragePercentage | Should -Be 50 # 1 protected out of 2
            $coverage.Plans | Should -HaveCount 2
        }
        
        It "Should identify protected and unprotected resources" {
            $coverage = Get-AzDefenderCoverage
            
            $coverage.ProtectedResources | Should -HaveCount 1
            $coverage.UnprotectedResources | Should -HaveCount 1
        }
    }
    
    Context "New-AzSecurityPolicySet" {
        
        BeforeEach {
            Mock New-AzPolicySetDefinition {
                [PSCustomObject]@{
                    Name = "TestPolicySet"
                    PolicySetDefinitionId = "/providers/Microsoft.Authorization/policySetDefinitions/test"
                }
            }
            Mock New-AzPolicyAssignment {
                [PSCustomObject]@{
                    Name = "TestPolicySet-Assignment"
                    PolicyAssignmentId = "/subscriptions/xxx/providers/Microsoft.Authorization/policyAssignments/test"
                }
            }
        }
        
        It "Should create policy set for CIS framework" {
            $result = New-AzSecurityPolicySet -PolicySetName "CIS-Baseline" -Framework "CIS"
            
            Should -Invoke New-AzPolicySetDefinition -Times 1
            Should -Invoke New-AzPolicyAssignment -Times 1
            $result.PolicySetDefinition | Should -Not -BeNullOrEmpty
            $result.Assignment | Should -Not -BeNullOrEmpty
        }
        
        It "Should use management group scope when specified" {
            New-AzSecurityPolicySet -PolicySetName "Test" -Framework "CIS" -ManagementGroupId "TestMG"
            
            Should -Invoke New-AzPolicySetDefinition -Times 1 -ParameterFilter { $ManagementGroupId -eq "TestMG" }
        }
        
        It "Should apply enforcement mode" {
            New-AzSecurityPolicySet -PolicySetName "Test" -Framework "NIST" -EnforcementMode "DoNotEnforce"
            
            Should -Invoke New-AzPolicyAssignment -Times 1 -ParameterFilter { $EnforcementMode -eq "DoNotEnforce" }
        }
    }
    
    Context "Start-AzVulnerabilityAssessment" {
        
        BeforeEach {
            Mock Get-AzResource {
                @([PSCustomObject]@{ResourceId = "/subscriptions/xxx/vm1"})
            }
        }
        
        It "Should initiate vulnerability assessment" {
            $result = Start-AzVulnerabilityAssessment -ResourceType "VirtualMachines" -ResourceGroupName "TestRG"
            
            $result.Status | Should -Be "Completed"
            $result.ResourceType | Should -Be "VirtualMachines"
            $result.ScanType | Should -Be "Full"
        }
        
        It "Should use specified scan type" {
            $result = Start-AzVulnerabilityAssessment -ResourceType "SqlDatabases" -ScanType "Quick"
            
            $result.ScanType | Should -Be "Quick"
        }
    }
    
    Context "Get-AzSecurityScore" {
        
        BeforeEach {
            Mock Get-AzSecuritySecureScoreControl {
                @(
                    [PSCustomObject]@{
                        Name = "ASC_EnableMFA"
                        DisplayName = "Enable MFA"
                        Score = [PSCustomObject]@{Current = 10; Max = 20; Percentage = 50}
                        HealthyResourceCount = 5
                        UnhealthyResourceCount = 5
                        NotApplicableResourceCount = 0
                    }
                )
            }
        }
        
        It "Should retrieve basic security score" {
            $score = Get-AzSecurityScore
            
            $score.CurrentScore | Should -Be 65
            $score.MaxScore | Should -Be 100
            $score.Percentage | Should -Be 65
        }
        
        It "Should include controls when requested" {
            $score = Get-AzSecurityScore -IncludeControls
            
            $score.Controls | Should -HaveCount 1
            $score.Controls[0].DisplayName | Should -Be "Enable MFA"
        }
        
        It "Should include recommendations when requested" {
            $score = Get-AzSecurityScore -IncludeRecommendations
            
            Should -Invoke Get-AzSecurityTask -Times 1
            $score.Recommendations | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Set-AzSecurityScoreTarget" {
        
        BeforeEach {
            Mock Out-File { }
        }
        
        It "Should set security score target" {
            $target = Set-AzSecurityScoreTarget -TargetScore 85
            
            $target.TargetScore | Should -Be 85
            $target.CurrentScore | Should -Be 65
            $target.Gap | Should -Be 20
        }
        
        It "Should calculate milestones" {
            $targetDate = (Get-Date).AddMonths(4)
            $target = Set-AzSecurityScoreTarget -TargetScore 85 -TargetDate $targetDate
            
            $target.Milestones | Should -HaveCount 4
            $target.Milestones[-1].TargetScore | Should -BeGreaterOrEqual 85
        }
        
        It "Should save target configuration" {
            Set-AzSecurityScoreTarget -TargetScore 85
            
            Should -Invoke Out-File -Times 1
        }
    }
    
    Context "Get-AzSecurityRecommendations" {
        
        It "Should get all recommendations by default" {
            $recommendations = Get-AzSecurityRecommendations
            
            $recommendations | Should -Not -BeNullOrEmpty
            Should -Invoke Get-AzSecurityTask -Times 1
        }
        
        It "Should filter by severity" {
            $recommendations = Get-AzSecurityRecommendations -Severity "High"
            
            $recommendations | Should -HaveCount 1
            $recommendations[0].Severity | Should -Be "High"
        }
        
        It "Should prioritize recommendations" {
            $recommendations = Get-AzSecurityRecommendations
            
            $recommendations[0].Priority | Should -BeGreaterThan 0
        }
    }
    
    Context "Invoke-AzSecurityRecommendation" {
        
        BeforeEach {
            Mock Get-AzSecurityTask {
                [PSCustomObject]@{
                    Name = "EnableMFA"
                    SecurityTaskParameters = [PSCustomObject]@{
                        Name = "Enable MFA"
                        RecommendationType = "EnableMFA"
                    }
                }
            }
        }
        
        It "Should process recommendation in test mode" {
            $result = Invoke-AzSecurityRecommendation -RecommendationId "EnableMFA" -TestMode
            
            $result.Status | Should -Be "TestCompleted"
            $result.RecommendationId | Should -Be "EnableMFA"
        }
        
        It "Should fail if recommendation not found" {
            Mock Get-AzSecurityTask { $null }
            
            { Invoke-AzSecurityRecommendation -RecommendationId "NonExistent" } | Should -Throw
        }
    }
}

Describe "Helper Function Tests" {
    
    Context "Get-AzResourceCount" {
        
        BeforeEach {
            Mock Get-AzResource {
                @(
                    [PSCustomObject]@{ResourceId = "vm1"; ResourceType = "Microsoft.Compute/virtualMachines"},
                    [PSCustomObject]@{ResourceId = "vm2"; ResourceType = "Microsoft.Compute/virtualMachines"}
                )
            }
        }
        
        It "Should count resources by type" {
            $resources = Get-AzResourceCount -ResourceType "VirtualMachines"
            
            $resources | Should -HaveCount 2
            Should -Invoke Get-AzResource -Times 1 -ParameterFilter { $ResourceType -eq "Microsoft.Compute/virtualMachines" }
        }
        
        It "Should return empty array for unknown type" {
            $resources = Get-AzResourceCount -ResourceType "Unknown"
            
            $resources | Should -HaveCount 0
        }
    }
    
    Context "Calculate-RecommendationPriority" {
        
        It "Should calculate priority based on severity" {
            $rec1 = @{Severity="Critical"; Impact="High"; Effort="Low"}
            $rec2 = @{Severity="Low"; Impact="Low"; Effort="High"}
            
            $priority1 = Calculate-RecommendationPriority -Recommendation $rec1
            $priority2 = Calculate-RecommendationPriority -Recommendation $rec2
            
            $priority1 | Should -BeGreaterThan $priority2
        }
        
        It "Should favor low effort recommendations" {
            $rec1 = @{Severity="High"; Impact="High"; Effort="Low"}
            $rec2 = @{Severity="High"; Impact="High"; Effort="High"}
            
            $priority1 = Calculate-RecommendationPriority -Recommendation $rec1
            $priority2 = Calculate-RecommendationPriority -Recommendation $rec2
            
            $priority1 | Should -BeGreaterThan $priority2
        }
    }
}