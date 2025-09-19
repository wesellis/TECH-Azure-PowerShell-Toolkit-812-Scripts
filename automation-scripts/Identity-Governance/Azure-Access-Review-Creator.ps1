#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ReviewName,
    
    [Parameter(Mandatory=$true)]
    [string]$Description,
    
    [Parameter(Mandatory=$true)]
    [string]$GroupId,
    
    [Parameter(Mandatory=$false)]
    [int]$DurationInDays = 14,
    
    [Parameter(Mandatory=$false)]
    [string]$ReviewerType = "GroupOwners",
    
    [Parameter(Mandatory=$false)]
    [array]$ReviewerEmails = @()
)

#region Functions

Write-Information "Creating Access Review: $ReviewName"

try {
    # Check if Microsoft.Graph.Identity.Governance module is available
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.Governance)) {
        Write-Warning "Microsoft.Graph.Identity.Governance module is required for full functionality"
        Write-Information "Install with: Install-Module Microsoft.Graph.Identity.Governance"
    }
    
    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes "AccessReview.ReadWrite.All"
    
    Write-Information " Connected to Microsoft Graph"
    
    # Get group information
    $Group = Get-MgGroup -GroupId $GroupId
    if (-not $Group) {
        Write-Error "Group not found: $GroupId"
        return
    }
    
    Write-Information "� Access Review Configuration:"
    Write-Information "  Review Name: $ReviewName"
    Write-Information "  Description: $Description"
    Write-Information "  Target Group: $($Group.DisplayName)"
    Write-Information "  Duration: $DurationInDays days"
    Write-Information "  Reviewer Type: $ReviewerType"
    
    # Calculate review dates
    $StartDate = Get-Date -ErrorAction Stop
    $EndDate = $StartDate.AddDays($DurationInDays)
    
    Write-Information "  Start Date: $($StartDate.ToString('yyyy-MM-dd'))"
    Write-Information "  End Date: $($EndDate.ToString('yyyy-MM-dd'))"
    
    # Access review template
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
    
    # Configure reviewers
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
    
    Write-Information "`n[WARN] IMPORTANT NOTES:"
    Write-Information "• Access reviews require Azure AD Premium P2"
    Write-Information "• Reviewers will receive email notifications"
    Write-Information "• Configure auto-apply based on your needs"
    Write-Information "• Monitor review progress and follow up"
    
    Write-Information "`nAccess Review Benefits:"
    Write-Information "• Periodic access certification"
    Write-Information "• Compliance with governance policies"
    Write-Information "• Automated access cleanup"
    Write-Information "• Audit trail of access decisions"
    Write-Information "• Risk reduction through regular reviews"
    
    Write-Information "`nReview Process:"
    Write-Information "1. Reviewers receive notification emails"
    Write-Information "2. Review access for each member"
    Write-Information "3. Approve or deny continued access"
    Write-Information "4. Provide justification for decisions"
    Write-Information "5. System applies decisions (if auto-apply enabled)"
    
    Write-Information "`nBest Practices:"
    Write-Information "• Schedule regular recurring reviews"
    Write-Information "• Use appropriate reviewers (managers, group owners)"
    Write-Information "• Enable recommendations for guidance"
    Write-Information "• Set reasonable review periods (1-4 weeks)"
    Write-Information "• Follow up on incomplete reviews"
    
    Write-Information "`nManual Creation Steps:"
    Write-Information "1. Azure Portal > Azure Active Directory"
    Write-Information "2. Identity Governance > Access Reviews"
    Write-Information "3. New Access Review"
    Write-Information "4. Configure scope, reviewers, and settings"
    Write-Information "5. Start the review"
    
    Write-Information "`n Access review template prepared"
    Write-Information "� Use Azure Portal to create the actual review for safety"
    Write-Information "� Reviewers will be notified via email when review starts"
    
} catch {
    Write-Error "Access review creation failed: $($_.Exception.Message)"
    Write-Information "� Tip: Use Azure Portal for creating Access Reviews"
}


#endregion
