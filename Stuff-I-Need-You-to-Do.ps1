#Requires -Version 7.0
#Requires -Module Az.Resources
<#
.SYNOPSIS
    Stuff I Need You to Do
.DESCRIPTION
    Stuff I Need You to Do operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Displays manual tasks required for Azure Enterprise Toolkit setup and monetization

    This script presents a
    to complete the Azure Enterprise Toolkit setup, including monetization opportunities,
    repository configuration, and testing requirements.
.PARAMETER ShowPriority
    Filter tasks by priority level (High, Medium, Low, All)
.PARAMETER OutputFormat
    Output format for the task list (Console, JSON, Markdown)
.PARAMETER ExportPath
    Path to export the task list if using JSON or Markdown output format

    .\Show-RequiredTasks.ps1

    Displays all manual tasks in console format

    .\Show-RequiredTasks.ps1 -ShowPriority High

    Shows only high priority tasks

    .\Show-RequiredTasks.ps1 -OutputFormat Markdown -ExportPath "./tasks.md"

    Exports tasks to a markdown file

    Author: Wes Ellis (wes@wesellis.com)#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('High', 'Medium', 'Low', 'All')]
    [string]$ShowPriority = 'All',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Console', 'JSON', 'Markdown')]
    [string]$OutputFormat = 'Console',

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Set dynamic defaults
if (-not $ExportPath -and $OutputFormat -ne 'Console') {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $extension = if ($OutputFormat -eq 'JSON') { 'json' } else { 'md' }
    $ExportPath = "./azure_toolkit_tasks_$timestamp.$extension"
}

#endregion

#region Functions
function Write-TaskHeader {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string]$Color = 'Cyan'
    )

    $separator = '=' * 50
    Write-Host $Title -ForegroundColor $Color
    Write-Host $separator -ForegroundColor $Color
}

function Write-TaskSection {
    [CmdletBinding()]
    param(
        [string]$SectionTitle,
        [string]$Priority,
        [string]$Description
    )

    $priorityColor = switch ($Priority) {
        'High' { 'Red' }
        'Medium' { 'Yellow' }
        'Low' { 'Green' }
        default { 'White' }
    }

    Write-Host "`n[TASK] $SectionTitle" -ForegroundColor $priorityColor
    Write-Host "Priority: $Priority" -ForegroundColor $priorityColor
    Write-Host $Description
}

function Get-TaskData {
    [CmdletBinding()]
    param()

    return @(
        @{
            Title = 'MONETIZATION SETUP (DO THIS FIRST!)'
            Priority = 'High'
            Description = @'
IMMEDIATE REVENUE OPPORTUNITIES:

1. PowerShell Gallery Premium Modules:
   - Register at: https://www.powershellgallery.com
   - Publish free versions first (build reputation)
   - Create Pro versions with licensing: $99-299 each
   - Potential: $500-2000/month

2. Azure Marketplace Listing:
   - List as Managed Application
   - Pricing: $299-999/month per customer
   - Link: https://partner.microsoft.com/dashboard/marketplace-offers
   - Potential: $1000-5000/month

3. GitHub Sponsors:
   - Enable at: https://github.com/sponsors
   - Create tiers: $5, $25, $99, $299, $999
   - Potential: $100-1000/month

4. Enterprise Support Contracts:
   - Offer direct support packages
   - Pricing: $999-4999/month per client
   - Target: Companies using your toolkit
   - Potential: $2000-10000/month

5. Training & Certification:
   - Create video course: $199-499
   - Live workshops: $999 per seat
   - Certification program: $1999
   - Potential: $1000-5000/month

TOTAL POTENTIAL: $4,600 - $23,000/month!
'@
        },
        @{
            Title = 'Update GitHub Repository Settings'
            Priority = 'High'
            Description = @'
Please update the following in the GitHub repository settings:

1. Repository Description:
   "Enterprise Azure automation toolkit with 170+ PowerShell scripts, 3 enterprise modules, IaC templates, security tools & dashboards"

2. Topics/Tags:
   - azure
   - powershell
   - enterprise
   - automation
   - infrastructure-as-code
   - bicep
   - security
   - compliance
   - cost-management
   - devops

3. Website URL:
   https://wesellis.github.io/Azure-Enterprise-Toolkit/
'@
        },
        @{
            Title = 'Azure Resources for Testing'
            Priority = 'High'
            Description = @'
To fully test the enterprise modules, you'll need:

1. Azure Subscription with appropriate permissions
2. Service Principal for automation testing
3. Log Analytics Workspace for monitoring examples
4. Storage Account for backup/DR testing
5. Test Resource Groups with proper tags

Run this to create test service principal:
   $params = @{
       scopes = "/subscriptions/{subscription-id}"
       role = "Contributor"
       name = "AzureEnterpriseToolkit-Testing"
   }
   az ad sp create-for-rbac @params
'@
        },
        @{
            Title = 'PowerShell Gallery Publishing (Optional)'
            Priority = 'Medium'
            Description = @'
If you want to publish the enterprise modules to PowerShell Gallery:

1. Create API key at: https://www.powershellgallery.com/account/apikeys
2. Publish modules:

   # Publish Az.Accounts.Enterprise
   $params = @{
       NuGetApiKey = "YOUR-API-KEY"
       Repository = "PSGallery"
       Path = "./automation-scripts/modules/storage"
   }
   Publish-Module @params
'@
        },
        @{
            Title = 'GitHub Pages Documentation'
            Priority = 'Medium'
            Description = @'
Update the documentation site with new module information:

1. Add module documentation pages
2. Update navigation with module links
3. Add usage examples and best practices
4. Update the quick start guide
'@
        },
        @{
            Title = 'Update GitHub Actions Workflow'
            Priority = 'Medium'
            Description = @'
Consider adding module-specific tests to .github/workflows/powershell-ci.yml:

- Test module imports
- Validate manifest files
- Check function exports
- Run Pester tests (if created)
'@
        },
        @{
            Title = 'Security Considerations'
            Priority = 'Medium'
            Description = @'
Review and implement:

1. Secure credential storage examples
2. Key Vault integration documentation
3. Managed Identity best practices
4. Network security recommendations
5. Compliance framework mappings
'@
        },
        @{
            Title = 'Continue Development (AFTER monetization)'
            Priority = 'Low'
            Description = @'
Based on the action list, next priorities are:

1. Complete Az.KeyVault module
2. Start Az.Monitoring module
3. Begin Bicep template migration
4. Update cost management dashboards
5. Create
'@
        }
    )
}

function Export-TasksToJson {
    [CmdletBinding()]
    param(
        [array]$Tasks,
        [string]$Path
    )

    $exportData = @{
        GeneratedDate = Get-Date -Format 'o'
        TotalTasks = $Tasks.Count
        Tasks = $Tasks
    }

    $exportData | ConvertTo-Json -Depth 3 | Out-File -FilePath $Path -Encoding UTF8
    Write-Host "Tasks exported to JSON: $Path" -InformationAction Continue
}

function Export-TasksToMarkdown {
    [CmdletBinding()]
    param(
        [array]$Tasks,
        [string]$Path
    )

    $markdown = @()
    $markdown += "# Azure Enterprise Toolkit - Required Tasks"
    $markdown += ""
    $markdown += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $markdown += "Total Tasks: $($Tasks.Count)"
    $markdown += ""

    foreach ($task in $Tasks) {
        $markdown += "## [$($task.Priority)] $($task.Title)"
        $markdown += ""
        $markdown += $task.Description
        $markdown += ""
        $markdown += "---"
        $markdown += ""
    }

    $markdown -join "`n" | Out-File -FilePath $Path -Encoding UTF8
    Write-Host "Tasks exported to Markdown: $Path" -InformationAction Continue
}

#endregion

#region Main-Execution
try {
    Write-TaskHeader "Azure Enterprise Toolkit - Manual Tasks Required"

    $allTasks = Get-TaskData

    # Filter tasks by priority if specified
    $filteredTasks = if ($ShowPriority -eq 'All') {
        $allTasks
    } else {
        $allTasks | Where-Object { $_.Priority -eq $ShowPriority }
    }

    if ($filteredTasks.Count -eq 0) {
        Write-Warning "No tasks found with priority: $ShowPriority"
        return
    }

    # Process output based on format
    switch ($OutputFormat) {
        'Console' {
            foreach ($task in $filteredTasks) {
                Write-TaskSection -SectionTitle $task.Title -Priority $task.Priority -Description $task.Description
            }

            Write-Host "`n$('=' * 50)" -ForegroundColor Cyan
            Write-Host "Total tasks shown: $($filteredTasks.Count)" -ForegroundColor Green
            Write-Host "Run this script later to see pending human tasks" -ForegroundColor Yellow
            Write-Host "Some tasks are optional but recommended for production use" -ForegroundColor Yellow
        }

        'JSON' {
            Export-TasksToJson -Tasks $filteredTasks -Path $ExportPath
        }

        'Markdown' {
            Export-TasksToMarkdown -Tasks $filteredTasks -Path $ExportPath
        }
    
} catch {
    Write-Error "Failed to display tasks: $_"
    throw
}

#endregion\n