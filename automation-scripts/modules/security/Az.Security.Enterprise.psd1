@{
    # Module manifest for Az.Security.Enterprise
    RootModule = 'Az.Security.Enterprise.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'f9e5d4c3-8a7b-4e2d-9c1f-7e6d5b4a3f89'
    Author = 'Wesley Ellis'
    CompanyName = 'WesEllis'
    Copyright = '(c) 2024 Wesley Ellis. All rights reserved.'
    Description = 'Enterprise security module for Azure with compliance automation, threat detection, and security posture management. Part of the Azure Enterprise Toolkit.'
    PowerShellVersion = '5.1'
    
    # Modules required for this module to work
    RequiredModules = @(
        'Az.Security',
        'Az.KeyVault',
        'Az.PolicyInsights'
    )
    
    # Functions to export
    FunctionsToExport = @(
        'Invoke-AzEnterpriseSecurityAudit',
        'Get-AzEnterpriseComplianceReport',
        'Set-AzEnterpriseSecurityBaseline',
        'New-AzEnterpriseSecurityPolicy',
        'Get-AzEnterpriseThreatAssessment',
        'Enable-AzEnterpriseDefender',
        'Export-AzEnterpriseSecurityScore',
        'Set-AzEnterpriseRBAC',
        'New-AzEnterpriseSecurityGroup',
        'Invoke-AzEnterpriseIncidentResponse',
        'Get-AzEnterpriseVulnerabilities',
        'Set-AzEnterpriseEncryption'
    )
    
    # Variables to export
    VariablesToExport = '*'
    
    # Aliases to export
    AliasesToExport = @(
        'Invoke-ESecAudit',
        'Get-ECompliance',
        'Set-ESecBaseline',
        'Get-EThreat'
    )
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Azure', 'Security', 'Enterprise', 'Compliance', 'Defender', 'RBAC')
            LicenseUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/LICENSE'
            ProjectUri = 'https://github.com/wesellis/azure-enterprise-toolkit'
            IconUri = 'https://raw.githubusercontent.com/wesellis/azure-enterprise-toolkit/main/icon.png'
            ReleaseNotes = 'Initial release of Az.Security.Enterprise module with comprehensive security capabilities.'
            PreRelease = ''
            RequireLicenseAcceptance = $false
            ExternalModuleDependencies = @()
        }
    }
    
    # Help Info URI
    HelpInfoURI = 'https://github.com/wesellis/azure-enterprise-toolkit/wiki/Az.Security.Enterprise'
}