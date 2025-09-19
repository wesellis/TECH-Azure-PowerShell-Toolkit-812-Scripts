#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Subscription Security Auditor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Subscription Security Auditor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputPath = " SecurityAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
)

#region Functions

Write-WELog " Starting Azure Security Audit..." " INFO"

if ($WESubscriptionId) {
    Set-AzContext -SubscriptionId $WESubscriptionId
    Write-WELog " Auditing subscription: $WESubscriptionId" " INFO"
} else {
    $WESubscriptionId = (Get-AzContext).Subscription.Id
    Write-WELog " Auditing current subscription: $WESubscriptionId" " INFO"
}

$WEAuditResults = @{
    SubscriptionInfo = @{}
    RoleAssignments = @()
    PolicyAssignments = @()
    SecurityFindings = @()
    Recommendations = @()
}

try {
    # Get subscription information
    $WESubscription = Get-AzSubscription -SubscriptionId $WESubscriptionId
    $WEAuditResults.SubscriptionInfo = @{
        Name = $WESubscription.Name
        Id = $WESubscription.Id
        TenantId = $WESubscription.TenantId
        State = $WESubscription.State
    }
    
    Write-WELog "  Subscription info collected" " INFO"
    
    # Audit role assignments
    Write-WELog "  Auditing role assignments..." " INFO"
    $WERoleAssignments = Get-AzRoleAssignment -Scope " /subscriptions/$WESubscriptionId"
    
    foreach ($WEAssignment in $WERoleAssignments) {
        $WEAuditResults.RoleAssignments += @{
            PrincipalName = $WEAssignment.DisplayName
            PrincipalType = $WEAssignment.ObjectType
            Role = $WEAssignment.RoleDefinitionName
            Scope = $WEAssignment.Scope
            PrincipalId = $WEAssignment.ObjectId
        }
    }
    
    # Check for privileged roles
    $WEPrivilegedRoles = @(" Owner" , " User Access Administrator" , " Security Administrator" )
    $WEPrivilegedAssignments = $WERoleAssignments | Where-Object { $_.RoleDefinitionName -in $WEPrivilegedRoles }
    
    if ($WEPrivilegedAssignments.Count -gt 10) {
        $WEAuditResults.SecurityFindings += " [WARN]️ High number of privileged role assignments: $($WEPrivilegedAssignments.Count)"
        $WEAuditResults.Recommendations += " Review and minimize privileged access assignments"
    }
    
    Write-WELog "  Role assignments audited: $($WERoleAssignments.Count) found" " INFO"
    
    # Audit policy assignments
    Write-WELog "  Auditing policy assignments..." " INFO"
    $WEPolicyAssignments = Get-AzPolicyAssignment -Scope " /subscriptions/$WESubscriptionId"
    
    foreach ($WEPolicy in $WEPolicyAssignments) {
        $WEAuditResults.PolicyAssignments += @{
            Name = $WEPolicy.Name
            PolicyDefinitionId = $WEPolicy.Properties.PolicyDefinitionId
            Scope = $WEPolicy.Properties.Scope
            EnforcementMode = $WEPolicy.Properties.EnforcementMode
        }
    }
    
    Write-WELog "  Policy assignments audited: $($WEPolicyAssignments.Count) found" " INFO"
    
    # Security checks
    Write-WELog "  Performing security checks..." " INFO"
    
    # Check for guest users with privileged access
    $WEGuestUsers = $WERoleAssignments | Where-Object { $_.DisplayName -like " *#EXT#*" -and $_.RoleDefinitionName -in $WEPrivilegedRoles }
    if ($WEGuestUsers.Count -gt 0) {
        $WEAuditResults.SecurityFindings += " [WARN]️ Guest users with privileged access: $($WEGuestUsers.Count)"
        $WEAuditResults.Recommendations += " Review guest user access and implement time-limited assignments"
    }
    
    # Check for service principals with Owner role
    $WEServicePrincipalOwners = $WERoleAssignments | Where-Object { $_.ObjectType -eq " ServicePrincipal" -and $_.RoleDefinitionName -eq " Owner" }
    if ($WEServicePrincipalOwners.Count -gt 0) {
        $WEAuditResults.SecurityFindings += " [WARN]️ Service principals with Owner role: $($WEServicePrincipalOwners.Count)"
        $WEAuditResults.Recommendations += " Consider using more restrictive roles for service principals"
    }
    
    # Check for users with subscription-level Owner access
   ;  $WESubscriptionOwners = $WERoleAssignments | Where-Object { $_.Scope -eq " /subscriptions/$WESubscriptionId" -and $_.RoleDefinitionName -eq " Owner" }
    if ($WESubscriptionOwners.Count -gt 5) {
        $WEAuditResults.SecurityFindings += " [WARN]️ Many subscription owners: $($WESubscriptionOwners.Count)"
        $WEAuditResults.Recommendations += " Limit subscription-level Owner assignments"
    }
    
    Write-WELog "  Security checks completed" " INFO"
    
    # Generate HTML report
   ;  $WEHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Security Audit Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background-color: #1a1a1a; color: #ffffff; margin: 20px; }
        .header { background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%); padding: 30px; text-align: center; border-radius: 8px; margin-bottom: 20px; }
        h1 { margin: 0; font-size: 2.5em; font-weight: 300; }
        .summary { background-color: #2c2c2c; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .finding { background-color: #3a2a2a; padding: 15px; margin: 10px 0; border-left: 4px solid #e74c3c; border-radius: 4px; }
        .recommendation { background-color: #2a3a2a; padding: 15px; margin: 10px 0; border-left: 4px solid #27ae60; border-radius: 4px; }
        table { width: 100%; border-collapse: collapse; background-color: #2c2c2c; border-radius: 8px; margin-bottom: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #444; }
        th { background: #34495e; font-weight: 600; }
        .footer { text-align: center; margin-top: 40px; color: #888; }
    </style>
</head>
<body>
    <div class=" header" >
        <h1>Azure Security Audit Report</h1>
        <div>Subscription: $($WEAuditResults.SubscriptionInfo.Name)</div>
        <div>Generated by Wesley Ellis | $(Get-Date -Format " MMMM dd, yyyy 'at' HH:mm" )</div>
    </div>
    
    <div class=" summary" >
        <h2>Executive Summary</h2>
        <p><strong>Subscription:</strong> $($WEAuditResults.SubscriptionInfo.Name)</p>
        <p><strong>Subscription ID:</strong> $($WEAuditResults.SubscriptionInfo.Id)</p>
        <p><strong>Role Assignments:</strong> $($WEAuditResults.RoleAssignments.Count)</p>
        <p><strong>Policy Assignments:</strong> $($WEAuditResults.PolicyAssignments.Count)</p>
        <p><strong>Security Findings:</strong> $($WEAuditResults.SecurityFindings.Count)</p>
    </div>
    
    <h2>Security Findings</h2>
" @
    
    foreach ($WEFinding in $WEAuditResults.SecurityFindings) {
        $WEHTML = $WEHTML + " <div class='finding'>$WEFinding</div>"
    }
    
    $WEHTML = $WEHTML + " <h2>Recommendations</h2>"
    
    foreach ($WERecommendation in $WEAuditResults.Recommendations) {
        $WEHTML = $WEHTML + " <div class='recommendation'> $WERecommendation</div>"
    }
    
   ;  $WEHTML = $WEHTML + @"
    
    <div class=" footer" >
        <p>Report generated by Wesley Ellis | CompuCom Systems Inc. | $(Get-Date -Format " MMMM dd, yyyy" )</p>
        <p>Azure Automation Scripts | Security Audit Tool</p>
    </div>
</body>
</html>
" @
    
    # Save report
    $WEHTML | Out-File -FilePath $WEOutputPath -Encoding UTF8
    
    Write-WELog "  Security audit completed successfully!" " INFO"
    Write-WELog "  Audit Results:" " INFO"
    Write-WELog "  Role Assignments: $($WEAuditResults.RoleAssignments.Count)" " INFO"
    Write-WELog "  Policy Assignments: $($WEAuditResults.PolicyAssignments.Count)" " INFO"
    Write-WELog "  Security Findings: $($WEAuditResults.SecurityFindings.Count)" " INFO"
    Write-WELog "  Report saved to: $WEOutputPath" " INFO"
    
} catch {
    Write-Error " Security audit failed: $($_.Exception.Message)"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
