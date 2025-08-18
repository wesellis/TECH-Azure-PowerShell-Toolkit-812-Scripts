@{
    # Module manifest for Az.Storage.Enterprise

    # Script module or binary module file associated with this manifest.
    RootModule = 'Az.Storage.Enterprise.psm1'

    # Version number of this module.
    ModuleVersion = '2.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Core', 'Desktop')

    # ID used to uniquely identify this module
    GUID = 'c9f5e6d4-0e13-5f7c-b8fa-3456789012cd'

    # Author of this module
    Author = 'Azure Enterprise Toolkit Team'

    # Company or vendor of this module
    CompanyName = 'Enterprise Azure Solutions'

    # Copyright statement for this module
    Copyright = '(c) 2025 Azure Enterprise Toolkit. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Enterprise storage management with lifecycle policies, security hardening, compliance monitoring, and cost optimization'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'Az.Storage'; ModuleVersion = '5.5.0'},
        @{ModuleName = 'Az.Security'; ModuleVersion = '1.5.0'}
    )

    # Functions to export from this module
    FunctionsToExport = @(
        'New-AzStorageAccountAdvanced',
        'Test-AzStorageAccountSecurity',
        'Get-DefaultLifecyclePolicy',
        'Set-AzStorageLifecyclePolicy',
        'Enable-AzStorageAdvancedThreatProtection',
        'Get-AzStorageComplianceReport',
        'Start-AzStorageDataArchival',
        'Get-AzStorageCostAnalysis',
        'Enable-AzStorageBackup',
        'Start-AzStorageReplication'
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
            Tags = @('Azure', 'Enterprise', 'Storage', 'Security', 'Compliance', 'Lifecycle', 'Backup')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/wesellis/azure-enterprise-toolkit'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 2.0.0
- Advanced storage account creation with security defaults
- Comprehensive security validation and remediation
- Blob lifecycle management automation
- Advanced Threat Protection integration
- Storage compliance reporting
- Data archival based on access patterns
- Cost analysis and optimization recommendations
- Backup and disaster recovery configuration
- Cross-region replication setup
'@
        }
    }
}