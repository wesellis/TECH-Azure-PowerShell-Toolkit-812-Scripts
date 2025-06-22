@{
    # Module manifest for Az.Accounts.Enterprise

    # Script module or binary module file associated with this manifest.
    RootModule = 'Az.Accounts.Enterprise.psm1'

    # Version number of this module.
    ModuleVersion = '2.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Core', 'Desktop')

    # ID used to uniquely identify this module
    GUID = 'a7f3e4b2-8c91-4d5a-b6e8-1234567890ab'

    # Author of this module
    Author = 'Azure Enterprise Toolkit Team'

    # Company or vendor of this module
    CompanyName = 'Enterprise Azure Solutions'

    # Copyright statement for this module
    Copyright = '(c) 2025 Azure Enterprise Toolkit. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Enterprise-grade Azure account management with multi-tenant support, service principal automation, and advanced authentication features'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'Az.Accounts'; ModuleVersion = '2.12.1'}
    )

    # Functions to export from this module
    FunctionsToExport = @(
        'Connect-AzMultiTenant',
        'Switch-AzTenant',
        'New-AzServicePrincipalAdvanced',
        'Remove-ExpiredServicePrincipals',
        'Test-AzManagedIdentity',
        'Get-AzAllSubscriptions',
        'Invoke-AzCrossSubscriptionCommand',
        'New-AzAuthenticationCertificate',
        'Get-AzAccountsEnterpriseInfo'
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
            Tags = @('Azure', 'Enterprise', 'Authentication', 'MultiTenant', 'ServicePrincipal', 'ManagedIdentity')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/wesellis/azure-enterprise-toolkit'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 2.0.0
- Multi-tenant authentication support
- Advanced service principal management
- Managed identity integration
- Certificate-based authentication
- Cross-subscription command execution
- Enhanced error handling and logging
'@
        }
    }
}