#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter()]
    [string]$SubscriptionId,
    [Parameter()]
    [string]$OutputPath = "SecurityAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
)
Write-Output "Starting Azure Security Audit..."
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
    Write-Output "Auditing subscription: $SubscriptionId"
} else {
    $SubscriptionId = (Get-AzContext).Subscription.Id
    Write-Output "Auditing current subscription: $SubscriptionId"
}
$AuditResults = @{
    SubscriptionInfo = @{}
    RoleAssignments = @()
    PolicyAssignments = @()
    SecurityFindings = @()
    Recommendations = @()
}
try {
    $Subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
    $AuditResults.SubscriptionInfo = @{
        Name = $Subscription.Name
        Id = $Subscription.Id
        TenantId = $Subscription.TenantId
        State = $Subscription.State
    }
    Write-Output "Subscription info collected"
    Write-Output "Auditing role assignments..."
    $RoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId"
    foreach ($Assignment in $RoleAssignments) {
        $AuditResults.RoleAssignments += @{
            PrincipalName = $Assignment.DisplayName
            PrincipalType = $Assignment.ObjectType
            Role = $Assignment.RoleDefinitionName
            Scope = $Assignment.Scope
            PrincipalId = $Assignment.ObjectId
        }
    }
    $PrivilegedRoles = @("Owner", "User Access Administrator", "Security Administrator")
    $PrivilegedAssignments = $RoleAssignments | Where-Object { $_.RoleDefinitionName -in $PrivilegedRoles }
    if ($PrivilegedAssignments.Count -gt 10) {
        $AuditResults.SecurityFindings += "[WARN] High number of privileged role assignments: $($PrivilegedAssignments.Count)"
        $AuditResults.Recommendations += "Review and minimize privileged access assignments"
    }
    Write-Output "Role assignments audited: $($RoleAssignments.Count) found"
    Write-Output "Auditing policy assignments..."
    $PolicyAssignments = Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId"
    foreach ($Policy in $PolicyAssignments) {
        $AuditResults.PolicyAssignments += @{
            Name = $Policy.Name
            PolicyDefinitionId = $Policy.Properties.PolicyDefinitionId
            Scope = $Policy.Properties.Scope
            EnforcementMode = $Policy.Properties.EnforcementMode
        }
    }
    Write-Output "Policy assignments audited: $($PolicyAssignments.Count) found"
    Write-Output "Performing security checks..."
    $GuestUsers = $RoleAssignments | Where-Object { $_.DisplayName -like "*#EXT#*" -and $_.RoleDefinitionName -in $PrivilegedRoles }
    if ($GuestUsers.Count -gt 0) {
        $AuditResults.SecurityFindings += "[WARN] Guest users with privileged access: $($GuestUsers.Count)"
        $AuditResults.Recommendations += "Review guest user access and implement time-limited assignments"
    }
    $ServicePrincipalOwners = $RoleAssignments | Where-Object { $_.ObjectType -eq "ServicePrincipal" -and $_.RoleDefinitionName -eq "Owner" }
    if ($ServicePrincipalOwners.Count -gt 0) {
        $AuditResults.SecurityFindings += "[WARN] Service principals with Owner role: $($ServicePrincipalOwners.Count)"
        $AuditResults.Recommendations += "Consider using more restrictive roles for service principals"
    }
    $SubscriptionOwners = $RoleAssignments | Where-Object { $_.Scope -eq "/subscriptions/$SubscriptionId" -and $_.RoleDefinitionName -eq "Owner" }
    if ($SubscriptionOwners.Count -gt 5) {
        $AuditResults.SecurityFindings += "[WARN] Many subscription owners: $($SubscriptionOwners.Count)"
        $AuditResults.Recommendations += "Limit subscription-level Owner assignments"
    }
    Write-Output "Security checks completed"
    $HTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Security Audit Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background-color: #1a1a1a; color: #ffffff; margin: 20px; }
        .header { background: linear-gradient(135deg,
        h1 { margin: 0; font-size: 2.5em; font-weight: 300; }
        .summary { background-color:
        .finding { background-color:
        .recommendation { background-color:
        table { width: 100%; border-collapse: collapse; background-color:
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid
        th { background:
        .footer { text-align: center; margin-top: 40px; color:
    </style>
</head>
<body>
    <div class="header">
        <h1>Azure Security Audit Report</h1>
        <div>Subscription: $($AuditResults.SubscriptionInfo.Name)</div>
    </div>
    <div class="summary">
        <h2>Executive Summary</h2>
        <p><strong>Subscription:</strong> $($AuditResults.SubscriptionInfo.Name)</p>
        <p><strong>Subscription ID:</strong> $($AuditResults.SubscriptionInfo.Id)</p>
        <p><strong>Role Assignments:</strong> $($AuditResults.RoleAssignments.Count)</p>
        <p><strong>Policy Assignments:</strong> $($AuditResults.PolicyAssignments.Count)</p>
        <p><strong>Security Findings:</strong> $($AuditResults.SecurityFindings.Count)</p>
    </div>
    <h2>Security Findings</h2>
"@
    foreach ($Finding in $AuditResults.SecurityFindings) {
        $HTML += "<div class='finding'>$Finding</div>"
    }
    $HTML += "<h2>Recommendations</h2>"
    foreach ($Recommendation in $AuditResults.Recommendations) {
        $HTML += "<div class='recommendation'> $Recommendation</div>"
    }
    $HTML += @"
    <div class="footer">
        <p>PowerShell scripts | Security Audit Tool</p>
    </div>
</body>
</html>
"@
    $HTML | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Output "Security audit completed successfully!"
    Write-Output "Audit Results:"
    Write-Output "Role Assignments: $($AuditResults.RoleAssignments.Count)"
    Write-Output "Policy Assignments: $($AuditResults.PolicyAssignments.Count)"
    Write-Output "Security Findings: $($AuditResults.SecurityFindings.Count)"
    Write-Output "Report saved to: $OutputPath"
} catch {
    Write-Error "Security audit failed: $($_.Exception.Message)"`n}
