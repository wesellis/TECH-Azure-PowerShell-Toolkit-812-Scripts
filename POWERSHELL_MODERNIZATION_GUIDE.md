# PowerShell Script Modernization Guide & AI Assistant Prompt

## Project Context
- **Repository**: PowerShell Toolkit - 812 Scripts
- **Author**: Wes Ellis (wes@wesellis.com)
- **Objective**: Modernize all PowerShell scripts to meet 2024 best practices and eliminate "AI slop" characteristics

## AI Assistant Instructions

When reviewing and updating PowerShell scripts in this repository, follow this systematic approach:

### STEP 1: Initial Script Assessment
Before making any changes, check for:
1. Empty stub scripts (only comments, no implementation)
2. File creation date (use `stat` command to get actual date)
3. Presence of backticks for line continuation
4. Unicode characters that won't display properly
5. Incomplete functions or placeholder code
6. Old scripting patterns (string concatenation in params, etc.)

### STEP 2: Apply Modernization Standards

#### A. Script Structure & Metadata
```powershell
#Requires -Module Az.Resources
#Requires -Version 7.0

<#
.SYNOPSIS
    Brief description using approved verbs (Get-Verb to validate)

.DESCRIPTION
    Detailed description of functionality

.PARAMETER ParameterName
    Description for each parameter

.EXAMPLE
    .\Script-Name.ps1 -Parameter "Value"

    Description of what this example does

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0.0
    Created: [USE ACTUAL FILE CREATION DATE FROM stat COMMAND]
    LastModified: [Current update date]
#>
```

#### B. Parameter Definitions
```powershell
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[a-z0-9-]+$')]
    [string]$ResourceName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Development', 'Staging', 'Production')]
    [string]$Environment = 'Development',

    [Parameter()]
    [switch]$Force,  # Use switch instead of [bool]

    [Parameter()]
    [string]$OutputPath  # NO default with subexpressions
)

# Set dynamic defaults in script body
if (-not $OutputPath) {
    $OutputPath = ".\Output_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
}
```

#### C. Code Organization with Regions
```powershell
#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
#endregion

#region Functions
function Get-ResourceData {
    [CmdletBinding()]
    param()
    # Implementation
}
#endregion

#region Main-Execution
try {
    # Main logic
}
catch {
    Write-Error "Operation failed: $_"
    throw
}
finally {
    # Cleanup
}
#endregion
```

#### D. Replace Backticks with Modern Alternatives

**BAD - Using backticks:**
```powershell
Get-AzResource `
    -ResourceGroupName $ResourceGroup `
    -Name $ResourceName `
    -ResourceType $ResourceType
```

**GOOD - Using splatting:**
```powershell
$params = @{
    ResourceGroupName = $ResourceGroup
    Name = $ResourceName
    ResourceType = $ResourceType
}
Get-AzResource @params
```

**GOOD - Pipeline at line start:**
```powershell
Get-AzResource |
    Where-Object { $_.Location -eq 'eastus' } |
    Select-Object Name, ResourceType
```

**GOOD - Natural continuation:**
```powershell
$result = @(
    $item1,
    $item2,
    $item3
)
```

#### E. Error Handling Pattern
```powershell
function Invoke-Operation {
    [CmdletBinding()]
    param()

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        try {
            # Operation code
        }
        catch [System.OperationCanceledException] {
            Write-Warning "Operation cancelled by user"
            return
        }
        catch {
            $errorDetails = @{
                Message = $_.Exception.Message
                Category = $_.CategoryInfo.Category
                Line = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Operation failed: $($errorDetails.Message)"
            throw
        }
    }

    end {
        # Cleanup
    }
}
```

#### F. Modern Output Handling
```powershell
# BAD - Using Write-Host for data
Write-Host "Result: $result"

# GOOD - Return objects
[PSCustomObject]@{
    Status = 'Success'
    ResourceId = $resource.Id
    Timestamp = Get-Date -Format 'o'
}

# GOOD - Use appropriate streams
Write-Verbose "Processing resource: $($resource.Name)"
Write-Debug "Resource details: $($resource | ConvertTo-Json -Depth 2)"
Write-Information "Operation completed successfully" -InformationAction Continue
```

#### G. Replace Unicode with ASCII
```powershell
# BAD
$icons = @{
    Success = '✓'
    Failed = '✗'
    Warning = '⚠'
}

# GOOD
$icons = @{
    Success = '[OK]'
    Failed = '[FAIL]'
    Warning = '[WARN]'
}
```

### STEP 3: Validation Checklist

Before considering a script complete, verify:

- [ ] No backticks for line continuation
- [ ] No default parameter values with subexpressions
- [ ] All functions use approved verbs (Get-Verb)
- [ ] Proper error handling with try/catch/finally
- [ ] No hardcoded credentials or secrets
- [ ] Uses splatting for commands with 3+ parameters
- [ ] Implements #region blocks for organization
- [ ] No Unicode characters (replaced with ASCII)
- [ ] Author info shows: Wes Ellis (wes@wesellis.com)
- [ ] Creation date matches actual file creation (not today)
- [ ] All functions have comment-based help
- [ ] Parameters have proper validation attributes
- [ ] Uses [switch] instead of [bool] parameters
- [ ] Supports pipeline where appropriate
- [ ] No Write-Host for data output (only for user messages)
- [ ] Returns objects, not formatted strings
- [ ] Line width <= 115 characters
- [ ] 4-space indentation (no tabs)
- [ ] PascalCase for public identifiers
- [ ] Descriptive variable names
- [ ] #Requires statements present

### STEP 4: Common Patterns to Fix

#### Empty Stub Scripts
If you find:
```powershell
# Script to audit resource compliance against specific policies
```

Replace with full implementation following the structure above.

#### Module Checking Pattern
```powershell
function Initialize-RequiredModules {
    param(
        [string[]]$RequiredModules = @('Az.Resources', 'Az.Storage')
    )

    foreach ($module in $RequiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-Warning "Module '$module' not found. Installing..."
            try {
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                Import-Module $module -Force
            }
            catch {
                throw "Failed to install required module '$module': $_"
            }
        }
        else {
            Import-Module $module -Force
        }
    }
}
```

#### Performance Optimization
```powershell
# BAD - Using += in loops
$results = @()
foreach ($item in $items) {
    $results += Process-Item $item
}

# GOOD - Using ArrayList or List
$results = [System.Collections.ArrayList]::new()
foreach ($item in $items) {
    [void]$results.Add((Process-Item $item))
}

# BETTER - Using pipeline where appropriate
$results = $items | ForEach-Object { Process-Item $_ }
```

### STEP 5: Additional Modernization Patterns

#### Classes vs Functions
When encountering PowerShell classes, evaluate if they should remain or be converted:
```powershell
# If keeping classes, ensure they follow modern patterns:
class ResourceManager {
    [string]$Name
    hidden [string]$_apiKey  # Use hidden for private properties

    ResourceManager([string]$name) {
        $this.Name = $name
    }

    [PSCustomObject] GetStatus() {
        return [PSCustomObject]@{
            Name = $this.Name
            Status = 'Active'
        }
    }
}

# Consider if a function-based approach would be simpler/more maintainable
```

#### Remove "Enhanced by AI" Attribution
Replace any instances of:
- "Enhanced by AI"
- "AI-Enhanced"
- "Generated by AI"
- Company-specific tool references

With generic descriptions or remove entirely.

#### Handle Empty Stub Files
For files with only a comment like:
```powershell
# Script to do something
```

Check file statistics to determine:
1. If recently created (likely a placeholder) - implement fully
2. If old (might be deprecated) - mark as deprecated or implement
3. Consider if the script is even needed

#### AST Parsing Patterns
When using AST (Abstract Syntax Tree) parsing:
```powershell
# Modern error handling for AST operations
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput(
    $scriptContent,
    [ref]$tokens,
    [ref]$errors
)

if ($errors.Count -gt 0) {
    $errors | ForEach-Object {
        Write-Warning "Parse error at line $($_.Extent.StartLineNumber): $($_.Message)"
    }
}
```

#### String Interpolation Best Practices
```powershell
# BAD - Complex expressions in strings
Write-Host "Result: $($data | Where-Object {$_.Status -eq 'Active'} | Select-Object -First 1)"

# GOOD - Calculate first, then interpolate
$activeItem = $data | Where-Object {$_.Status -eq 'Active'} | Select-Object -First 1
Write-Host "Result: $activeItem"
```

#### Path Handling
```powershell
# BAD - String concatenation for paths
$path = $folder + "\" + $file

# GOOD - Use Join-Path
$path = Join-Path $folder $file

# BETTER - Handle multiple segments
$path = Join-Path $folder (Join-Path 'subfolder' $file)

# BEST - For multiple segments in PS7+
$path = Join-Path $folder 'subfolder' $file -AdditionalChildPath 'deep', 'path'
```

#### Credential Management
```powershell
# NEVER do this
$password = "MyPassword123"

# Use SecureString with prompts
$credential = Get-Credential -Message "Enter credentials for operation"

# Or use environment variables/key vault
$securePassword = $env:SERVICE_PASSWORD | ConvertTo-SecureString -AsPlainText -Force
$credential = [PSCredential]::new($env:SERVICE_USERNAME, $securePassword)
```

#### Default Parameter Value Patterns
```powershell
# BAD - Dynamic values in param block
param(
    [string]$LogFile = ".\log_$(Get-Date -Format 'yyyyMMdd').txt"
)

# GOOD - Set in begin block or script body
param(
    [string]$LogFile
)

begin {
    if (-not $LogFile) {
        $LogFile = ".\log_$(Get-Date -Format 'yyyyMMdd').txt"
    }
}
```

#### Avoid PowerShell 7-Only Features (Unless Explicitly Required)
```powershell
# BAD - Null coalescing operator only works in PS7+
$value = $param1 ?? $param2

# GOOD - Compatible with PS5.1+
$value = if ($param1) { $param1 } else { $param2 }

# Or use ternary-like pattern
$value = $(if ($param1) { $param1 } else { $param2 })
```

### STEP 6: Testing Requirements

Each modernized script should:
1. Run without syntax errors
2. Handle missing modules gracefully
3. Provide meaningful error messages
4. Support -WhatIf for destructive operations
5. Return structured objects (not strings)
6. Work with pipeline input where applicable
7. Not expose sensitive information in verbose/debug output

## Priority Order for Modernization

1. **Critical**: Scripts with empty implementations
2. **High**: Scripts using backticks extensively
3. **Medium**: Scripts with poor error handling
4. **Low**: Scripts needing minor formatting updates

## Reporting Progress

When updating scripts, report:
- Script name and path
- Issues found (be specific)
- Changes made
- Any remaining concerns

## Example Transformation

### Before:
```powershell
# Script to manage role assignments in a subscription
```

### After:
```powershell
#Requires -Module Az.Resources
#Requires -Version 7.0

<#
.SYNOPSIS
    Manages role assignments within a subscription or resource group

.DESCRIPTION
    Comprehensive role assignment management tool that can add, remove, or audit
    role assignments at various scopes including subscription, resource group,
    and individual resource levels.

.PARAMETER Action
    The action to perform: Add, Remove, or Audit

.PARAMETER PrincipalId
    The Object ID of the user, group, or service principal

.PARAMETER RoleDefinitionName
    The name of the role to assign (e.g., 'Contributor', 'Reader')

.PARAMETER Scope
    The scope at which to apply the role assignment

.EXAMPLE
    .\Manage-RoleAssignments.ps1 -Action Add -PrincipalId "xxxx-xxxx" -RoleDefinitionName "Contributor"

    Adds Contributor role to the specified principal at subscription scope

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0.0
    Created: 2024-11-15
    LastModified: 2024-01-19
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Add', 'Remove', 'Audit')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')]
    [string]$PrincipalId,

    [Parameter(Mandatory = $false)]
    [string]$RoleDefinitionName,

    [Parameter(Mandatory = $false)]
    [string]$Scope
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Set default scope if not provided
if (-not $Scope) {
    $context = Get-AzContext
    if (-not $context) {
        throw "No context found. Please authenticate first."
    }
    $Scope = "/subscriptions/$($context.Subscription.Id)"
}
#endregion

#region Functions
function Add-RoleAssignment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$PrincipalId,
        [string]$RoleDefinitionName,
        [string]$Scope
    )

    try {
        $params = @{
            ObjectId = $PrincipalId
            RoleDefinitionName = $RoleDefinitionName
            Scope = $Scope
        }

        if ($PSCmdlet.ShouldProcess("$PrincipalId", "Add $RoleDefinitionName role")) {
            New-AzRoleAssignment @params
        }
    }
    catch {
        Write-Error "Failed to add role assignment: $_"
        throw
    }
}
#endregion

#region Main-Execution
try {
    switch ($Action) {
        'Add' {
            if (-not $PrincipalId -or -not $RoleDefinitionName) {
                throw "PrincipalId and RoleDefinitionName are required for Add action"
            }
            Add-RoleAssignment -PrincipalId $PrincipalId -RoleDefinitionName $RoleDefinitionName -Scope $Scope
        }
        'Remove' {
            # Implementation for Remove
        }
        'Audit' {
            # Implementation for Audit
        }
    }
}
catch {
    Write-Error "Operation failed: $_"
    throw
}
#endregion
```

## Final Notes

- Each script should be production-ready, not a stub or template
- Prioritize readability and maintainability over cleverness
- Follow PowerShell community best practices from PoshCode
- Test each script after modernization
- Document any breaking changes from the original version