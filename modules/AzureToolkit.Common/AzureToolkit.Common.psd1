@{
    RootModule = 'AzureToolkit.Common.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'Azure PowerShell Toolkit'
    CompanyName = 'Enterprise IT'
    Copyright = '(c) 2024 Azure PowerShell Toolkit. All rights reserved.'
    Description = 'Common functions and utilities for Azure PowerShell Toolkit'

    PowerShellVersion = '7.0'

    RequiredModules = @('Az.Accounts', 'Az.Profile')

    FunctionsToExport = @(
        'Get-ToolkitConfig',
        'Initialize-ToolkitLogging',
        'Write-ToolkitLog',
        'Test-AzureConnection',
        'Invoke-ToolkitCommand',
        'Get-ResourceTags'
    )

    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @('Azure', 'PowerShell', 'Enterprise', 'DevOps', 'Automation')
            LicenseUri = ''
            ProjectUri = 'https://github.com/wesellis/TECH-Azure-PowerShell-Toolkit-812-Scripts'
            ReleaseNotes = 'Initial release of Azure Toolkit Common module'
        }
    }
}