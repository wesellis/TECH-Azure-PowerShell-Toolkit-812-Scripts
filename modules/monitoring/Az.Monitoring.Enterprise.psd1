@{
    # Module manifest for Az.Monitoring.Enterprise

    # Script module or binary module file associated with this manifest.
    RootModule = 'Az.Monitoring.Enterprise.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'b3c8f9a2-4d7e-46a9-9f2c-8e1b5d3a7c4f'

    # Author of this module
    Author = 'Enterprise Toolkit Team'

    # Company or vendor of this module
    CompanyName = 'Enterprise Azure Solutions'

    # Copyright statement for this module
    Copyright = '(c) 2025 Enterprise Azure Solutions. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Enterprise-grade Azure Monitoring and observability module with advanced features including Log Analytics workspace management, custom metrics, alert automation, dashboard deployment, workbook templates, and comprehensive action group management.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'Az.Monitor'; ModuleVersion = '4.0.0'}
        @{ModuleName = 'Az.OperationalInsights'; ModuleVersion = '3.0.0'}
    )

    # Functions to export from this module
    FunctionsToExport = @(
        'New-AzLogAnalyticsWorkspaceAdvanced',
        'Set-AzLogAnalyticsDataSources',
        'Enable-AzLogAnalyticsSolution',
        'New-AzCustomMetric',
        'Get-AzCustomMetricDefinition',
        'New-AzMetricAlertRuleV2Advanced',
        'New-AzLogQueryAlert',
        'Deploy-AzMonitorDashboard',
        'Deploy-AzMonitorWorkbook',
        'New-AzActionGroupAdvanced',
        'Test-AzActionGroup',
        'Export-AzMonitoringConfiguration',
        'Import-AzMonitoringConfiguration',
        'Get-AzMonitoringHealth'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Azure', 'Monitor', 'LogAnalytics', 'Enterprise', 'Observability', 'Alerts', 'Dashboards', 'Workbooks', 'Metrics')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/wesellis/azure-enterprise-toolkit'

            # A URL to an icon representing this module.
            IconUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/assets/icon.png'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 1.0.0
- Initial release of Az.Monitoring.Enterprise module
- Advanced Log Analytics workspace deployment and configuration
- Custom metric creation and management
- Complex alert rule automation with dynamic thresholds
- Dashboard deployment from templates
- Workbook template management
- Action group configuration with multiple channels
- Monitoring configuration export/import capabilities
- Health check functionality for monitoring components
'@

            # External dependent modules of this module
            ExternalModuleDependencies = @('Az.Monitor', 'Az.OperationalInsights')
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/wesellis/azure-enterprise-toolkit/wiki/Az.Monitoring.Enterprise'
}