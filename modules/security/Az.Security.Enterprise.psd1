@{
    # Module manifest for Az.Security.Enterprise

    # Script module or binary module file associated with this manifest.
    RootModule = 'Az.Security.Enterprise.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'c5d7e8f3-6a2b-4c9e-8f3a-7b4c9e2d5f8a'

    # Author of this module
    Author = 'Enterprise Toolkit Team'

    # Company or vendor of this module
    CompanyName = 'Enterprise Azure Solutions'

    # Copyright statement for this module
    Copyright = '(c) 2025 Enterprise Azure Solutions. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Enterprise-grade Azure Security management module providing Security Center automation, Defender for Cloud integration, security policy enforcement, vulnerability assessment automation, compliance score tracking, and security recommendation processing.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'Az.Security'; ModuleVersion = '1.5.0'}
        @{ModuleName = 'Az.PolicyInsights'; ModuleVersion = '1.6.0'}
    )

    # Functions to export from this module
    FunctionsToExport = @(
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
            Tags = @('Azure', 'Security', 'Defender', 'Compliance', 'Enterprise', 'SecurityCenter', 'Vulnerability', 'Policy', 'SecureScore')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/wesellis/azure-enterprise-toolkit'

            # A URL to an icon representing this module.
            IconUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/assets/icon.png'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 1.0.0
- Initial release of Az.Security.Enterprise module
- Advanced Security Center/Defender for Cloud configuration
- Comprehensive Defender plan management
- Security policy enforcement based on compliance frameworks
- Automated vulnerability assessment and reporting
- Security score tracking and target management
- Prioritized recommendation processing with auto-remediation
- Integration with multiple compliance standards (CIS, NIST, ISO27001)
'@

            # External dependent modules of this module
            ExternalModuleDependencies = @('Az.Security', 'Az.PolicyInsights')
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/wesellis/azure-enterprise-toolkit/wiki/Az.Security.Enterprise'
}