@{
    # Module manifest for Az.Monitoring.Enterprise
    RootModule = 'Az.Monitoring.Enterprise.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'e8f4a2c1-7b9d-4e3a-9f2c-8d6e5a4b3c90'
    Author = 'Wesley Ellis'
    CompanyName = 'WesEllis'
    Copyright = '(c) 2024 Wesley Ellis. All rights reserved.'
    Description = 'Enterprise monitoring module for Azure with advanced alerting, dashboards, and cost optimization features. Part of the Azure Enterprise Toolkit.'
    PowerShellVersion = '5.1'
    
    # Modules required for this module to work
    RequiredModules = @(
        'Az.Monitor',
        'Az.OperationalInsights',
        'Az.ApplicationInsights'
    )
    
    # Functions to export
    FunctionsToExport = @(
        'New-AzEnterpriseAlertRule',
        'Get-AzEnterpriseMetrics',
        'New-AzEnterpriseDashboard',
        'Export-AzEnterpriseMonitoringReport',
        'Set-AzEnterpriseAlertThreshold',
        'Get-AzEnterpriseCostAnomaly',
        'New-AzEnterpriseLogQuery',
        'Invoke-AzEnterpriseHealthCheck',
        'New-AzEnterpriseActionGroup',
        'Get-AzEnterprisePerformanceBaseline',
        'Set-AzEnterpriseMonitoringPolicy',
        'Export-AzEnterpriseAlertHistory'
    )
    
    # Variables to export
    VariablesToExport = '*'
    
    # Aliases to export
    AliasesToExport = @(
        'New-EAlert',
        'Get-EMetrics',
        'New-EDashboard',
        'Export-EReport'
    )
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Azure', 'Monitoring', 'Enterprise', 'Alerts', 'Dashboard', 'Automation')
            LicenseUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/LICENSE'
            ProjectUri = 'https://github.com/wesellis/azure-enterprise-toolkit'
            IconUri = 'https://raw.githubusercontent.com/wesellis/azure-enterprise-toolkit/main/icon.png'
            ReleaseNotes = 'Initial release of Az.Monitoring.Enterprise module with comprehensive monitoring capabilities.'
            PreRelease = ''
            RequireLicenseAcceptance = $false
            ExternalModuleDependencies = @()
        }
    }
    
    # Help Info URI
    HelpInfoURI = 'https://github.com/wesellis/azure-enterprise-toolkit/wiki/Az.Monitoring.Enterprise'
}