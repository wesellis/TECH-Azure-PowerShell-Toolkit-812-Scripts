@{
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'Wesley Ellis'
    CompanyName = 'wesellis.com'
    Copyright = '(c) 2025 Wesley Ellis. All rights reserved.'
    Description = 'Common functions and utilities for Azure Automation Scripts'
    PowerShellVersion = '7.0'
    RequiredModules = @('Az.Accounts', 'Az.Resources')
    FunctionsToExport = @('Write-Log', 'Test-AzureConnection', 'Invoke-AzureOperation', 'Show-Banner', 'Write-ProgressStep')
    PrivateData = @{
        PSData = @{
            Tags = @('Azure', 'Automation', 'PowerShell', 'Cloud')
            ProjectUri = 'https://github.com/wesellis/Azure-Automation-Scripts'
            LicenseUri = 'https://github.com/wesellis/Azure-Automation-Scripts/blob/main/LICENSE'
        }
    }
}
