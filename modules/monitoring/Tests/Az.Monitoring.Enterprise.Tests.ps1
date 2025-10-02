#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Tests for Az.Monitoring.Enterprise module
.DESCRIPTION
\n    Author: Wes Ellis (wes@wesellis.com)\n

BeforeAll {
    $ModulePath = Split-Path -Parent $PSScriptRoot

    Mock Get-AzOperationalInsightsWorkspace {
        [PSCustomObject]@{
            Name = "TestWorkspace"
            ResourceGroupName = "TestRG"
            Location = "eastus"
            ResourceId = "/subscriptions/xxx/resourceGroups/TestRG/providers/Microsoft.OperationalInsights/workspaces/TestWorkspace"
            Sku = "PerGB2018"
            RetentionInDays = 90
            ProvisioningState = "Succeeded"
        }
    }

    Mock New-AzOperationalInsightsWorkspace {
        [PSCustomObject]@{
            Name = "TestWorkspace"
            ResourceGroupName = "TestRG"
            Location = "eastus"
            ResourceId = "/subscriptions/xxx/resourceGroups/TestRG/providers/Microsoft.OperationalInsights/workspaces/TestWorkspace"
        }
    }

    Mock Get-AzMetricDefinition {
        @(
            [PSCustomObject]@{
                Name = [PSCustomObject]@{Value = "TestMetric"; LocalizedValue = "Test Metric"}
                Namespace = "CustomMetrics"
                Unit = "Count"
                AggregationType = "Average"
                Dimensions = @()
            }
        )
    }

    Mock Add-AzMetricAlertRuleV2 {
        [PSCustomObject]@{
            Name = "TestAlert"
            Id = "/subscriptions/xxx/resourceGroups/TestRG/providers/microsoft.insights/metricAlerts/TestAlert"
            Enabled = $true
            Severity = 3
        }
    }

    Mock Get-AzResourceGroup -ErrorAction Stop {
        [PSCustomObject]@{
            ResourceGroupName = "TestRG"
            Location = "eastus"
        }
    }
}

Describe "Az.Monitoring.Enterprise Module Tests" {

    Context "Module Loading" {
        It "Should have exported functions" {
            $module = Get-Module -ErrorAction Stop Az.Monitoring.Enterprise
            $module.ExportedFunctions.Count | Should -BeGreaterThan 0
        }

        It "Should export expected functions" {
            $ExpectedFunctions = @(
                'New-AzLogAnalyticsWorkspace',
                'Set-AzLogAnalyticsDataSources',
                'Enable-AzLogAnalyticsSolution',
                'New-AzCustomMetric',
                'Get-AzCustomMetricDefinition',
                'New-AzMetricAlertRuleV2',
                'New-AzLogQueryAlert',
                'Deploy-AzMonitorDashboard',
                'Deploy-AzMonitorWorkbook',
                'New-AzActionGroup',
                'Test-AzActionGroup',
                'Export-AzMonitoringConfiguration',
                'Import-AzMonitoringConfiguration',
                'Get-AzMonitoringHealth'
            )

            $module = Get-Module -ErrorAction Stop Az.Monitoring.Enterprise
            foreach ($function in $ExpectedFunctions) {
                $module.ExportedFunctions.Keys | Should -Contain $function
            }
        }
    }

    Context "New-AzLogAnalyticsWorkspace" {

        BeforeEach {
            Mock Set-AzOperationalInsightsIntelligencePack -ErrorAction Stop { }
            Mock New-AzOperationalInsightsWindowsPerformanceCounterDataSource -ErrorAction Stop { }
            Mock New-AzOperationalInsightsWindowsEventDataSource -ErrorAction Stop { }
            Mock New-AzOperationalInsightsLinuxPerformanceCounterDataSource -ErrorAction Stop { }
        }

        It "Should create workspace with default settings" {
            $result = New-AzLogAnalyticsWorkspace-WorkspaceName "TestWorkspace" -ResourceGroupName "TestRG" -Location "eastus"

            Should -Invoke New-AzOperationalInsightsWorkspace -Times 1
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should create workspace with capacity reservation" {
            New-AzLogAnalyticsWorkspace-WorkspaceName "TestWorkspace" -ResourceGroupName "TestRG" -Location "eastus" -CapacityReservationLevel 500

            Should -Invoke New-AzOperationalInsightsWorkspace -Times 1 -ParameterFilter { $CapacityReservationLevel -eq 500 }
        }

        It "Should enable specified solutions" {
            New-AzLogAnalyticsWorkspace-WorkspaceName "TestWorkspace" -ResourceGroupName "TestRG" -Location "eastus" -Solutions @('Security', 'Updates')

            Should -Invoke Set-AzOperationalInsightsIntelligencePack -Times 2
        }
    }

    Context "Set-AzLogAnalyticsDataSources" {

        BeforeEach {
            Mock New-AzOperationalInsightsWindowsPerformanceCounterDataSource -ErrorAction Stop { }
            Mock New-AzOperationalInsightsWindowsEventDataSource -ErrorAction Stop { }
            Mock New-AzOperationalInsightsLinuxPerformanceCounterDataSource -ErrorAction Stop { }
        }

        It "Should configure Windows performance counters" {
            Set-AzLogAnalyticsDataSources -WorkspaceName "TestWorkspace" -ResourceGroupName "TestRG"

            Should -Invoke New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Times 5
        }

        It "Should configure Windows event logs" {
            Set-AzLogAnalyticsDataSources -WorkspaceName "TestWorkspace" -ResourceGroupName "TestRG"

            Should -Invoke New-AzOperationalInsightsWindowsEventDataSource -Times 3
        }

        It "Should configure Linux performance counters" {
            Set-AzLogAnalyticsDataSources -WorkspaceName "TestWorkspace" -ResourceGroupName "TestRG"

            Should -Invoke New-AzOperationalInsightsLinuxPerformanceCounterDataSource -Times 4
        }
    }

    Context "New-AzCustomMetric" {

        It "Should create custom metric with basic parameters" {
            $metric = New-AzCustomMetric -ResourceId "/subscriptions/xxx/resource" -MetricName "TestMetric" -Value 100

            $metric | Should -Not -BeNullOrEmpty
            $metric.data.baseData.metric | Should -Be "TestMetric"
            $metric.data.baseData.series[0].sum | Should -Be 100
        }

        It "Should include dimensions when provided" {
            $dimensions = @{Region="EastUS"; Tier="Premium"}
            $metric = New-AzCustomMetric -ResourceId "/subscriptions/xxx/resource" -MetricName "TestMetric" -Value 100 -Dimensions $dimensions

            $metric.data.baseData.dimNames | Should -Contain "Region"
            $metric.data.baseData.dimNames | Should -Contain "Tier"
        }

        It "Should use correct timestamp" {
            $TestTime = Get-Date -ErrorAction Stop
            $metric = New-AzCustomMetric -ResourceId "/subscriptions/xxx/resource" -MetricName "TestMetric" -Value 100 -Timestamp $TestTime

            $ExpectedTime = $TestTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $metric.time | Should -Be $ExpectedTime
        }
    }

    Context "New-AzMetricAlertRuleV2" {

        BeforeEach {
            Mock New-AzMetricAlertRuleV2Criteria -ErrorAction Stop {
                [PSCustomObject]@{
                    MetricName = "Percentage CPU"
                    TimeAggregation = "Average"
                    Operator = "GreaterThan"
                    Threshold = 80
                }
            }
        }

        It "Should create alert with default CPU criteria" {
            $alert = New-AzMetricAlertRuleV2-AlertName "TestAlert" -ResourceGroupName "TestRG" -TargetResourceId "/subscriptions/xxx/vm"

            Should -Invoke Add-AzMetricAlertRuleV2 -Times 1
            Should -Invoke New-AzMetricAlertRuleV2Criteria -Times 1
        }

        It "Should create alert with custom criteria" {
            $criteria = @(
                @{MetricName="CPU"; Threshold=90; Operator="GreaterThan"},
                @{MetricName="Memory"; Threshold=80; Operator="GreaterThan"}
            )

            New-AzMetricAlertRuleV2-AlertName "TestAlert" -ResourceGroupName "TestRG" -TargetResourceId "/subscriptions/xxx/vm" -Criteria $criteria

            Should -Invoke New-AzMetricAlertRuleV2Criteria -Times 2
        }

        It "Should set correct severity" {
            New-AzMetricAlertRuleV2-AlertName "TestAlert" -ResourceGroupName "TestRG" -TargetResourceId "/subscriptions/xxx/vm" -Severity 1

            Should -Invoke Add-AzMetricAlertRuleV2 -Times 1 -ParameterFilter { $Severity -eq 1 }
        }
    }

    Context "Deploy-AzMonitorDashboard" {

        BeforeEach {
            Mock New-AzResourceGroupDeployment -ErrorAction Stop { }
            Mock Test-Path { $true }
            Mock Get-Content -ErrorAction Stop { '{"lenses": {}, "metadata": {}}' }
            Mock Out-File { }
            Mock Remove-Item -ErrorAction Stop { }
        }

        It "Should deploy dashboard from template file" {
            Deploy-AzMonitorDashboard -DashboardName "TestDashboard" -ResourceGroupName "TestRG" -TemplateFile "dashboard.json"

            Should -Invoke New-AzResourceGroupDeployment -Times 1
        }

        It "Should use default template when no file provided" {
            Deploy-AzMonitorDashboard -DashboardName "TestDashboard" -ResourceGroupName "TestRG"

            Should -Invoke New-AzResourceGroupDeployment -Times 1
        }

        It "Should apply tags when provided" {
            $tags = @{Environment="Test"; Purpose="Monitoring"}
            Deploy-AzMonitorDashboard -DashboardName "TestDashboard" -ResourceGroupName "TestRG" -Tags $tags

            Should -Invoke Out-File -Times 1
        }
    }

    Context "New-AzActionGroup" {

        BeforeEach {
            Mock New-AzActionGroupReceiver -ErrorAction Stop {
                [CmdletBinding(SupportsShouldProcess)]
$Name, [switch]$EmailReceiver, [switch]$SmsReceiver, [switch]$WebhookReceiver, $EmailAddress, $CountryCode, $PhoneNumber, $ServiceUri)
                [PSCustomObject]@{
                    Name = $Name
                    Type = if ($EmailReceiver) { "Email" } elseif ($SmsReceiver) { "SMS" } else { "Webhook" }
                }
            }
            Mock Set-AzActionGroup -ErrorAction Stop {
                [PSCustomObject]@{
                    Name = "TestActionGroup"
                    Id = "/subscriptions/xxx/resourceGroups/TestRG/providers/microsoft.insights/actionGroups/TestActionGroup"
                }
            }
        }

        It "Should create action group with email receivers" {
            $EmailReceivers = @(
                @{Name="Admin"; EmailAddress="admin@test.com"},
                @{Name="Ops"; EmailAddress="ops@test.com"}
            )

            New-AzActionGroup-ActionGroupName "TestAG" -ResourceGroupName "TestRG" -EmailReceivers $EmailReceivers

            Should -Invoke New-AzActionGroupReceiver -Times 2 -ParameterFilter { $EmailReceiver -eq $true }
            Should -Invoke Set-AzActionGroup -Times 1
        }

        It "Should create action group with SMS receivers" {
            $SmsReceivers = @(
                @{Name="OnCall"; CountryCode="1"; PhoneNumber="5551234567"}
            )

            New-AzActionGroup-ActionGroupName "TestAG" -ResourceGroupName "TestRG" -SmsReceivers $SmsReceivers

            Should -Invoke New-AzActionGroupReceiver -Times 1 -ParameterFilter { $SmsReceiver -eq $true }
        }

        It "Should generate short name if not provided" {
            New-AzActionGroup-ActionGroupName "VeryLongActionGroupName" -ResourceGroupName "TestRG"

            Should -Invoke Set-AzActionGroup -Times 1 -ParameterFilter { $ShortName.Length -le 12 }
        }
    }

    Context "Export-AzMonitoringConfiguration" {

        BeforeEach {
            Mock Get-AzMetricAlertRuleV2 -ErrorAction Stop {
                @([PSCustomObject]@{Name="Alert1"; Severity=3})
            }
            Mock Get-AzScheduledQueryRule -ErrorAction Stop {
                @([PSCustomObject]@{Name="QueryAlert1"})
            }
            Mock Get-AzActionGroup -ErrorAction Stop {
                @([PSCustomObject]@{Name="AG1"; EmailReceivers=@()})
            }
            Mock Get-AzResource -ErrorAction Stop {
                @([PSCustomObject]@{Name="Dashboard1"; ResourceId="/subscriptions/xxx/dashboard1"})
            }
            Mock Out-File { }
        }

        It "Should export all components when IncludeAll specified" {
            Export-AzMonitoringConfiguration -ResourceGroupName "TestRG" -OutputPath ".\export.json" -IncludeAll

            Should -Invoke Get-AzMetricAlertRuleV2 -Times 1
            Should -Invoke Get-AzScheduledQueryRule -Times 1
            Should -Invoke Get-AzActionGroup -Times 1
            Should -Invoke Get-AzResource -Times 2
        }

        It "Should export only alerts when specified" {
            Export-AzMonitoringConfiguration -ResourceGroupName "TestRG" -OutputPath ".\export.json" -IncludeAlerts

            Should -Invoke Get-AzMetricAlertRuleV2 -Times 1
            Should -Invoke Get-AzScheduledQueryRule -Times 1
            Should -Invoke Get-AzActionGroup -Times 0
        }

        It "Should save to specified file" {
            Export-AzMonitoringConfiguration -ResourceGroupName "TestRG" -OutputPath ".\test-export.json" -IncludeAll

            Should -Invoke Out-File -Times 1 -ParameterFilter { $FilePath -eq ".\test-export.json" }
        }
    }

    Context "Get-AzMonitoringHealth" {

        BeforeEach {
            Mock Get-AzMetricAlertRuleV2 -ErrorAction Stop {
                @(
                    [PSCustomObject]@{Name="Alert1"; Enabled=$true},
                    [PSCustomObject]@{Name="Alert2"; Enabled=$false}
                )
            }
            Mock Get-AzActionGroup -ErrorAction Stop {
                @([PSCustomObject]@{
                    Name="AG1"
                    EmailReceivers=@([PSCustomObject]@{Name="Email1"})
                    SmsReceivers=@([PSCustomObject]@{Name="SMS1"})
                })
            }
        }

        It "Should check workspace health" {
            $health = Get-AzMonitoringHealth -ResourceGroupName "TestRG" -WorkspaceNames @("TestWorkspace")

            $health.Components | Where-Object { $_.Type -eq "LogAnalyticsWorkspace" } | Should -Not -BeNullOrEmpty
            Should -Invoke Get-AzOperationalInsightsWorkspace -Times 1
        }

        It "Should report healthy status when all components are good" {
            $health = Get-AzMonitoringHealth -ResourceGroupName "TestRG" -WorkspaceNames @("TestWorkspace")

            $health.OverallHealth | Should -Be "Healthy"
            $health.Issues | Should -BeNullOrEmpty
        }

        It "Should calculate alert statistics" {
            $health = Get-AzMonitoringHealth -ResourceGroupName "TestRG"

            $AlertComponent = $health.Components | Where-Object { $_.Type -eq "AlertRules" }
            $AlertComponent.Details.TotalAlerts | Should -Be 2
            $AlertComponent.Details.EnabledAlerts | Should -Be 1
        }

        It "Should count total receivers" {
            $health = Get-AzMonitoringHealth -ResourceGroupName "TestRG"

            $AgComponent = $health.Components | Where-Object { $_.Type -eq "ActionGroups" }
            $AgComponent.Details.TotalReceivers | Should -Be 2
        }
    }
}

Describe "Helper Function Tests" {

    Context "Get-DefaultDashboardTemplate" {

        It "Should return valid dashboard template" {
            $template = Get-DefaultDashboardTemplate -ErrorAction Stop

            $template | Should -Not -BeNullOrEmpty
            $template.lenses | Should -Not -BeNullOrEmpty
            $template.metadata | Should -Not -BeNullOrEmpty
        }

        It "Should include markdown tile" {
            $template = Get-DefaultDashboardTemplate -ErrorAction Stop

            $FirstPart = $template.lenses."0".parts."0"
            $FirstPart.metadata.type | Should -Match "MarkdownPart"
        }
    }

    Context "Get-DefaultWorkbookTemplate" {

        It "Should return performance template" {
            $template = Get-DefaultWorkbookTemplate -Type "Performance"
            $parsed = $template | ConvertFrom-Json

            $parsed.version | Should -Be "Notebook/1.0"
            $parsed.items | Should -Not -BeNullOrEmpty
        }

        It "Should return availability template" {
            $template = Get-DefaultWorkbookTemplate -Type "Availability"
            $parsed = $template | ConvertFrom-Json

            $parsed.items[1].content.query | Should -Match "Heartbeat"
        }
    }
`n}
