@{
    # Module manifest for Az.KeyVault.Enterprise

    # Script module or binary module file associated with this manifest.
    RootModule = 'Az.KeyVault.Enterprise.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'a8f7d4e2-9c3b-4f2a-8e7d-1b9c3f5e8a2d'

    # Author of this module
    Author = 'Enterprise Toolkit Team'

    # Company or vendor of this module
    CompanyName = 'Enterprise Azure Solutions'

    # Copyright statement for this module
    Copyright = '(c) 2025 Enterprise Azure Solutions. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Enterprise-grade Azure Key Vault management module with advanced features including automated secret rotation, certificate lifecycle management, access policy automation, comprehensive monitoring, and compliance reporting.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'Az.KeyVault'; ModuleVersion = '4.0.0'}
        @{ModuleName = 'Az.Monitor'; ModuleVersion = '2.0.0'}
    )

    # Functions to export from this module
    FunctionsToExport = @(
        'Start-AzKeyVaultSecretRotation',
        'New-AzKeyVaultRotationPolicy',
        'Start-AzKeyVaultCertificateLifecycle',
        'Get-AzKeyVaultCertificateReport',
        'Set-AzKeyVaultAccessPolicyBulk',
        'New-AzKeyVaultAccessPolicyTemplate',
        'Enable-AzKeyVaultMonitoring',
        'New-AzKeyVaultAlertRules',
        'Get-AzKeyVaultComplianceReport',
        'Start-AzKeyVaultAccessReview'
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
            Tags = @('Azure', 'KeyVault', 'Enterprise', 'Security', 'Compliance', 'Automation', 'SecretRotation', 'CertificateManagement')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/wesellis/azure-enterprise-toolkit'

            # A URL to an icon representing this module.
            IconUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/assets/icon.png'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 1.0.0
- Initial release of Az.KeyVault.Enterprise module
- Automated secret rotation with configurable policies
- Certificate lifecycle management and renewal automation
- Bulk access policy management with template support
- Comprehensive monitoring and alerting integration
- Compliance reporting and access reviews
- Support for rollback and notification features
'@

            # External dependent modules of this module
            ExternalModuleDependencies = @('Az.KeyVault', 'Az.Monitor')
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/wesellis/azure-enterprise-toolkit/wiki/Az.KeyVault.Enterprise'
}