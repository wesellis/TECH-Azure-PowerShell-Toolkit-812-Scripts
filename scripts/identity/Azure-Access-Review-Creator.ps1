#Requires -Version 7.4
#Requires -Modules Microsoft.Graph.Identity.Governance

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ReviewName,
    [Parameter(Mandatory)]
    [string]$Description,
    [Parameter(Mandatory)]
    [string]$GroupId,
    [Parameter()]
    [int]$DurationInDays = 14,
    [Parameter()]
    [string]$ReviewerType = "GroupOwners",
    [Parameter()]
    [array]$ReviewerEmails = @()
)
Write-Output "Creating Access Review: $ReviewName"
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.Governance)) {
        Write-Warning "Microsoft.Graph.Identity.Governance module is required for full functionality"
        Write-Output "Install with: Install-Module Microsoft.Graph.Identity.Governance"
    }
    Connect-MgGraph -Scopes "AccessReview.ReadWrite.All"
    Write-Output "Connected to Microsoft Graph"
    $Group = Get-MgGroup -GroupId $GroupId
    if (-not $Group) {
        Write-Error "Group not found: $GroupId"
        return
    }
    Write-Output "Review Name: $ReviewName"
    Write-Output "Description: $Description"
    Write-Output "Target Group: $($Group.DisplayName)"
    Write-Output "Duration: $DurationInDays days"
    Write-Output "Reviewer Type: $ReviewerType"
    $StartDate = Get-Date -ErrorAction Stop
    $EndDate = $StartDate.AddDays($DurationInDays)
    Write-Output "Start Date: $($StartDate.ToString('yyyy-MM-dd'))"
    Write-Output "End Date: $($EndDate.ToString('yyyy-MM-dd'))"
    $AccessReviewTemplate = @{
        displayName = $ReviewName
        description = $Description
        startDate = $StartDate.ToString("yyyy-MM-ddTHH:mm:ss.fffK")
        endDate = $EndDate.ToString("yyyy-MM-ddTHH:mm:ss.fffK")
        scope = @{
            query = "/groups/$GroupId/members"
            queryType = "MicrosoftGraph"
        }
        reviewers = @()
        settings = @{
            defaultDecision = "None"
            defaultDecisionEnabled = $false
            instanceDurationInDays = $DurationInDays
            autoApplyDecisionsEnabled = $false
            recommendationsEnabled = $true
            recurrenceType = "onetime"
        }
    }
    switch ($ReviewerType) {
        "GroupOwners" {
            $AccessReviewTemplate.reviewers += @{
                query = "/groups/$GroupId/owners"
                queryType = "MicrosoftGraph"
            }
        }
        "SpecificUsers" {
            foreach ($Email in $ReviewerEmails) {
                try {
                    $User = Get-MgUser -Filter "userPrincipalName eq '$Email'"
                    if ($User) {
                        $AccessReviewTemplate.reviewers += @{
                            query = "/users/$($User.Id)"
                            queryType = "MicrosoftGraph"
                        }
                    }
                } catch {
                    Write-Warning "Could not find user: $Email"
                }
            }
        }
        "SelfReview" {
            $AccessReviewTemplate.reviewers += @{
                query = "/users"
                queryType = "MicrosoftGraph"
                queryRoot = "decisions"
            }
        }
    }
    Write-Output "`n[WARN] IMPORTANT NOTES:"
    Write-Output "Access reviews require Azure AD Premium P2"
    Write-Output "Reviewers will receive email notifications"
    Write-Output "Configure auto-apply based on your needs"
    Write-Output "Monitor review progress and follow up"
    Write-Output "`nAccess Review Benefits:"
    Write-Output "Periodic access certification"
    Write-Output "Compliance with governance policies"
    Write-Output "Automated access cleanup"
    Write-Output "Audit trail of access decisions"
    Write-Output "Risk reduction through regular reviews"
    Write-Output "`nReview Process:"
    Write-Output "1. Reviewers receive notification emails"
    Write-Output "2. Review access for each member"
    Write-Output "3. Approve or deny continued access"
    Write-Output "4. Provide justification for decisions"
    Write-Output "5. System applies decisions (if auto-apply enabled)"
    Write-Output "`nBest Practices:"
    Write-Output "Schedule regular recurring reviews"
    Write-Output "Use appropriate reviewers (managers, group owners)"
    Write-Output "Enable recommendations for guidance"
    Write-Output "Set reasonable review periods (1-4 weeks)"
    Write-Output "Follow up on incomplete reviews"
    Write-Output "`nManual Creation Steps:"
    Write-Output "1. Azure Portal > Azure Active Directory"
    Write-Output "2. Identity Governance > Access Reviews"
    Write-Output "3. New Access Review"
    Write-Output "4. Configure scope, reviewers, and settings"
    Write-Output "5. Start the review"
    Write-Output "`n Access review template prepared"
} catch {
    Write-Error "Access review creation failed: $($_.Exception.Message)"`n}
