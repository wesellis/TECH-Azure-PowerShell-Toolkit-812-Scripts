<#
.SYNOPSIS
    Tests for Az.Security.Enterprise module
.DESCRIPTION
\n    Author: Wes Ellis (wes@wesellis.com)\n#>

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
    
    Mock Set-AzSecurityAutoProvisioningSetting -ErrorAction Stop { }
    Mock Set-AzSecurityContact -ErrorAction Stop { }
    Mock Set-AzSecurityWorkspaceSetting -ErrorAction Stop { }
    
    Mock Get-AzSecuritySecureScore -ErrorAction Stop {
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
                LastUpdateTime = Get-Date -ErrorAction Stop
            }
        }
    }
    
    Mock Get-AzSecurityTask -ErrorAction Stop {
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
            $module = Get-Module -ErrorAction Stop Az.Security.Enterprise
            $module.ExportedFunctions.Count | Should -BeGreaterThan 0
        }
        
        It "Should export expected functions" {
            $expectedFunctions = @(
                'Enable-AzSecurityCenter',
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
            
            $module = Get-Module -ErrorAction Stop Az.Security.Enterprise
            foreach ($function in $expectedFunctions) {
                $module.ExportedFunctions.Keys | Should -Contain $function
            }
        }
    }
    
    Context "Enable-AzSecurityCenter" {
        
        It "Should configure Security Center with standard tier" {
            Enable-AzSecurityCenter-SubscriptionId "12345678-1234-1234-1234-123456789012" -Tier "Standard"
            
            Should -Invoke Set-AzSecurityPricing -Times 12 # Number of resource types
        }
        
        It "Should enable auto-provisioning when specified" {
            Enable-AzSecurityCenter-SubscriptionId "12345678-1234-1234-1234-123456789012" -EnableAutoProvisioning
            
            Should -Invoke Set-AzSecurityAutoProvisioningSetting -Times 1 -ParameterFilter { $EnableAutoProvision -eq $true }
        }
        
        It "Should configure security contacts" {
            $params = @{
                SecurityContactEmails = "@("test@example.com")"
                TargetScore = "85  Should"
                ParameterFilter = "{ $EnforcementMode"
                RecommendationId = "NonExistent" } | Should"
                and = $PricingTier
                BeGreaterOrEqual = "85 }  It "Should save target configuration" { Set-AzSecurityScoreTarget"
                eq = "DoNotEnforce" } } }  Context "Start-AzVulnerabilityAssessment" {  BeforeEach { Mock Get-AzResource"
                Be = "EnableMFA" }  It "Should fail if recommendation not found" { Mock Get-AzSecurityTask"
                ResourceGroupName = "TestRG"  $result.Status | Should"
                Framework = "NIST"
                IncludeRecommendations = "Should"
                IncludeControls = $score.Controls | Should
                SubscriptionId = "12345678-1234-1234-1234-123456789012"
                TestMode = $result.Status | Should
                PlanName = "VirtualMachines"
                Times = "1 }  It "Should filter by severity" { $recommendations = Get-AzSecurityRecommendations"
                EnforcementMode = "DoNotEnforce"  Should"
                ResourceType = "SqlDatabases"
                Enable = "Should"
                ScanType = "Quick"  $result.ScanType | Should"
                ErrorAction = "Stop { $null }  { Invoke-AzSecurityRecommendation"
                SecurityContactPhone = "+1234567890"  Should"
                ManagementGroupId = "TestMG"  Should"
                HaveCount = "1 $recommendations[0].Severity | Should"
                Throw = "} }"
                BeGreaterThan = "0 } }  Context "Invoke-AzSecurityRecommendation" {  BeforeEach { Mock Get-AzSecurityTask"
                Invoke = "Get-AzSecurityTask"
                WorkspaceSettings = $workspaceSettings  Should
                PolicySetName = "Test"
                Severity = "High"  $recommendations | Should"
                SubPlan = "P2"  Should"
                TargetDate = $targetDate  $target.Milestones | Should
                BeNullOrEmpty = "Should"
            }
            Enable-AzSecurityCenter@params
}

Describe "Helper Function Tests" {
    
    Context "Get-AzResourceCount" {
        
        BeforeEach {
            Mock Get-AzResource -ErrorAction Stop {
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

#endregion\n