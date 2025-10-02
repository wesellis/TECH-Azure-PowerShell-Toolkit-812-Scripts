#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Subscription Security Auditor

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter(ValueFromPipeline)]
    [string]$OutputPath = "SecurityAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
)
Write-Host "Starting Azure Security Audit..." -ForegroundColor Green
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
    Write-Host "Auditing subscription: $SubscriptionId" -ForegroundColor Green
} else {
    $SubscriptionId = (Get-AzContext).Subscription.Id
    Write-Host "Auditing current subscription: $SubscriptionId" -ForegroundColor Green
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
    Write-Host "Subscription info collected" -ForegroundColor Green
    Write-Host "Auditing role assignments..." -ForegroundColor Green
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
    Write-Host "Role assignments audited: $($RoleAssignments.Count) found" -ForegroundColor Green
    Write-Host "Auditing policy assignments..." -ForegroundColor Green
    $PolicyAssignments = Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId"
    foreach ($Policy in $PolicyAssignments) {
        $AuditResults.PolicyAssignments += @{
            Name = $Policy.Name
            PolicyDefinitionId = $Policy.Properties.PolicyDefinitionId
            Scope = $Policy.Properties.Scope
            EnforcementMode = $Policy.Properties.EnforcementMode
        }
    }
    Write-Host "Policy assignments audited: $($PolicyAssignments.Count) found" -ForegroundColor Green
    Write-Host "Performing security checks..." -ForegroundColor Green
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
    Write-Host "Security checks completed" -ForegroundColor Green
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
    <div class=" header" >
        <h1>Azure Security Audit Report</h1>
        <div>Subscription: $($AuditResults.SubscriptionInfo.Name)</div>
    </div>
    <div class=" summary" >
        <h2>Executive Summary</h2>
        <p><strong>Subscription:</strong> $($AuditResults.SubscriptionInfo.Name)</p>
        <p><strong>Subscription ID:</strong> $($AuditResults.SubscriptionInfo.Id)</p>
        <p><strong>Role Assignments:</strong> $($AuditResults.RoleAssignments.Count)</p>
        <p><strong>Policy Assignments:</strong> $($AuditResults.PolicyAssignments.Count)</p>
        <p><strong>Security Findings:</strong> $($AuditResults.SecurityFindings.Count)</p>
    </div>
    <h2>Security Findings</h2>
" @
    foreach ($Finding in $AuditResults.SecurityFindings) {
        $HTML = $HTML + "<div class='finding'>$Finding</div>"
    }
    $HTML = $HTML + "<h2>Recommendations</h2>"
    foreach ($Recommendation in $AuditResults.Recommendations) {
        $HTML = $HTML + "<div class='recommendation'>$Recommendation</div>"
    }
    [string]$HTML = $HTML + @"
    <div class=" footer" >
        <p>Azure Automation Scripts | Security Audit Tool</p>
    </div>
</body>
</html>
"@
    $HTML | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Security audit completed successfully!" -ForegroundColor Green
    Write-Host "Audit Results:" -ForegroundColor Green
    Write-Host "Role Assignments: $($AuditResults.RoleAssignments.Count)" -ForegroundColor Green
    Write-Host "Policy Assignments: $($AuditResults.PolicyAssignments.Count)" -ForegroundColor Green
    Write-Host "Security Findings: $($AuditResults.SecurityFindings.Count)" -ForegroundColor Green
    Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
} catch {
    Write-Error "Security audit failed: $($_.Exception.Message)"
}
