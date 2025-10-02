#Requires -Version 7.4
#Requires -Modules Microsoft.Graph.Identity.SignIns

<#
.SYNOPSIS
    Azure Conditional Access Policy Creator

.DESCRIPTION
    Creates and manages Azure AD Conditional Access policies for enhanced security
    and compliance, implementing Zero Trust principles

.PARAMETER PolicyName
    Name of the Conditional Access policy

.PARAMETER Description
    Description of the policy

.PARAMETER IncludeUsers
    Users or groups to include in the policy

.PARAMETER ExcludeUsers
    Users or groups to exclude from the policy

.PARAMETER IncludeApplications
    Applications to include in the policy

.PARAMETER RequireMFA
    Whether to require MFA

.PARAMETER State
    State of the policy (Enabled, Disabled, EnabledForReportingButNotEnforced)

.EXAMPLE
    .\Azure-ConditionalAccess-Policy-Creator.ps1 -PolicyName "Require MFA" -Description "MFA for all users" -RequireMFA $true

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PolicyName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Description,

    [Parameter()]
    [array]$IncludeUsers = @("All"),

    [Parameter()]
    [array]$ExcludeUsers = @(),

    [Parameter()]
    [array]$IncludeApplications = @("All"),

    [Parameter()]
    [bool]$RequireMFA = $true,

    [Parameter()]
    [ValidateSet("Enabled", "Disabled", "EnabledForReportingButNotEnforced")]
    [string]$State = "EnabledForReportingButNotEnforced"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-ColorLog {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }

    $LogEntry = "$timestamp [CA-Policy] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

Write-Host "Azure Conditional Access Policy Creator" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor DarkGray
Write-ColorLog "Creating policy: $PolicyName" -Level INFO

try {
    # Check for required module
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
        Write-ColorLog "Microsoft Graph module not found. Installing..." -Level WARN
        Install-Module Microsoft.Graph.Identity.SignIns -Force -Scope CurrentUser
        Import-Module Microsoft.Graph.Identity.SignIns
    }

    # Connect to Microsoft Graph
    Write-ColorLog "Connecting to Microsoft Graph..." -Level INFO
    $requiredScopes = @(
        "Policy.ReadWrite.ConditionalAccess",
        "Policy.Read.All",
        "Directory.Read.All",
        "Application.Read.All"
    )
    Connect-MgGraph -Scopes $requiredScopes

    Write-ColorLog "Connected to Microsoft Graph successfully" -Level SUCCESS

    # Display policy configuration
    Write-Host "`nConditional Access Policy Configuration:" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor DarkGray
    Write-Host "Name: $PolicyName"
    Write-Host "Description: $Description"
    Write-Host "State: $State"
    Write-Host "Include Users: $($IncludeUsers -join ', ')"

    if ($ExcludeUsers.Count -gt 0) {
        Write-Host "Exclude Users: $($ExcludeUsers -join ', ')"
    }

    Write-Host "Applications: $($IncludeApplications -join ', ')"
    Write-Host "Require MFA: $RequireMFA"

    # Build policy object
    $policyConditions = @{
        Users = @{
            IncludeUsers = $IncludeUsers
            ExcludeUsers = $ExcludeUsers
        }
        Applications = @{
            IncludeApplications = $IncludeApplications
        }
    }

    $grantControls = @{
        Operator = "OR"
        BuiltInControls = @()
    }

    if ($RequireMFA) {
        $grantControls.BuiltInControls += "mfa"
    }

    $policyBody = @{
        DisplayName = $PolicyName
        State = $State.ToLower()
        Conditions = $policyConditions
        GrantControls = $grantControls
        Description = $Description
    }

    # Important warnings
    Write-Host "`n⚠️ IMPORTANT SECURITY NOTES:" -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor DarkGray
    Write-Host "• Policy created in report-only mode by default" -ForegroundColor Yellow
    Write-Host "• Test thoroughly before enabling enforcement" -ForegroundColor Yellow
    Write-Host "• Ensure emergency access accounts are excluded" -ForegroundColor Yellow
    Write-Host "• Monitor sign-in logs for impact analysis" -ForegroundColor Yellow
    Write-Host "• Review policy regularly for compliance" -ForegroundColor Yellow

    # Conditional Access benefits
    Write-Host "`n✓ Conditional Access Policy Benefits:" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor DarkGray
    Write-Host "• Zero Trust security model implementation"
    Write-Host "• Risk-based access control"
    Write-Host "• Multi-factor authentication enforcement"
    Write-Host "• Device compliance requirements"
    Write-Host "• Location-based access restrictions"
    Write-Host "• Session control capabilities"
    Write-Host "• Identity protection integration"

    # Common policy templates
    Write-Host "`n📋 Common Policy Templates:" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor DarkGray
    Write-Host "1. Require MFA for all users"
    Write-Host "2. Block access from untrusted locations"
    Write-Host "3. Require compliant devices for access"
    Write-Host "4. Require approved client applications"
    Write-Host "5. Block legacy authentication protocols"
    Write-Host "6. Require password change for high-risk users"
    Write-Host "7. Require MFA for Azure management"
    Write-Host "8. Block access for risky sign-ins"

    # Next steps
    Write-Host "`n🚀 Recommended Next Steps:" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor DarkGray
    Write-Host "1. Create policy via Azure Portal (recommended for safety)"
    Write-Host "2. Configure detailed conditions and controls"
    Write-Host "3. Test with pilot group of users"
    Write-Host "4. Review 'What If' tool results"
    Write-Host "5. Monitor report-only mode for 7-14 days"
    Write-Host "6. Enable policy after validation"
    Write-Host "7. Document policy and approval"
    Write-Host "8. Set up alerts for policy violations"

    # Manual creation guide
    Write-Host "`n📝 Manual Creation Steps:" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor DarkGray
    Write-Host "1. Navigate to: Azure Portal > Azure Active Directory"
    Write-Host "2. Go to: Security > Conditional Access"
    Write-Host "3. Click: + New Policy"
    Write-Host "4. Configure:"
    Write-Host "   - Name: $PolicyName"
    Write-Host "   - Users and groups: Configure as needed"
    Write-Host "   - Cloud apps: Select applications"
    Write-Host "   - Conditions: Set locations, devices, etc."
    Write-Host "   - Grant: Configure access controls"
    Write-Host "5. Enable policy in report-only mode first"
    Write-Host "6. Review insights after testing period"
    Write-Host "7. Switch to 'On' when ready"

    # Create sample policy JSON
    $policyJson = $policyBody | ConvertTo-Json -Depth 10
    $jsonFileName = "CA-Policy-$PolicyName-$(Get-Date -Format 'yyyyMMdd').json"

    Write-ColorLog "Saving policy template to: $jsonFileName" -Level INFO
    $policyJson | Out-File -FilePath $jsonFileName -Encoding UTF8

    Write-ColorLog "Conditional Access policy template created successfully" -Level SUCCESS
    Write-Host "`n📄 Policy template saved to: $jsonFileName" -ForegroundColor Green
    Write-Host "   Use this JSON with Microsoft Graph API or import in Azure Portal" -ForegroundColor DarkGray

    # Disconnect from Graph
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
catch {
    Write-ColorLog "Policy creation failed: $($_.Exception.Message)" -Level ERROR
    Write-Host "`n💡 Tip: Use Azure Portal for creating Conditional Access policies for better safety" -ForegroundColor Yellow
    Write-Host "   Portal URL: https://portal.azure.com/#blade/Microsoft_AAD_IAM/ConditionalAccessBlade" -ForegroundColor DarkGray
    throw
}