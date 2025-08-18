@{
    # Module manifest for Az.Resources.Enterprise

    # Script module or binary module file associated with this manifest.
    RootModule = 'Az.Resources.Enterprise.psm1'

    # Version number of this module.
    ModuleVersion = '2.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Core', 'Desktop')

    # ID used to uniquely identify this module
    GUID = 'b8f4e5c3-9d02-4e6b-a7f9-2345678901bc'

    # Author of this module
    Author = 'Azure Enterprise Toolkit Team'

    # Company or vendor of this module
    CompanyName = 'Enterprise Azure Solutions'

    # Copyright statement for this module
    Copyright = '(c) 2025 Azure Enterprise Toolkit. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Enterprise resource management with advanced tagging, naming conventions, bulk operations, and compliance monitoring'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'Az.Resources'; ModuleVersion = '6.5.0'},
        @{ModuleName = 'ThreadJob'; ModuleVersion = '2.0.3'}
    )

    # Functions to export from this module
    FunctionsToExport = @(
        'New-AzResourceGroupAdvanced',
        'Remove-AzResourceGroupSafely',
        'Set-AzResourceTags',
        'Test-AzResourceCompliance',
        'Test-AzResourceNamingConvention',
        'Rename-AzResourceBatch',
        'Start-AzResourceBulkOperation',
        'Get-AzResourceDependencies',
        'Get-AzResourceCostByTag'
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
            Tags = @('Azure', 'Enterprise', 'Resources', 'Tagging', 'Compliance', 'Governance')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/wesellis/azure-enterprise-toolkit/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/wesellis/azure-enterprise-toolkit'

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 2.0.0
- Advanced resource group management with enterprise standards
- Comprehensive tag management and enforcement
- Resource naming convention validation
- Bulk operations with parallel processing
- Resource dependency mapping
- Cost allocation by tags
- Compliance testing and remediation
'@
        }
    }
}