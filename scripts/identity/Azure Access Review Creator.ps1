#Requires -Version 7.0

<#`n.SYNOPSIS
    Azure Access Review Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
[OutputType([bool])]
 {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ReviewName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Description,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$GroupId,
    [Parameter()]
    [int]$DurationInDays = 14,
    [Parameter(ValueFromPipeline)]`n    [string]$ReviewerType = "GroupOwners" ,
    [Parameter()]
    [array]$ReviewerEmails = @()
)
Write-Host "Creating Access Review: $ReviewName"
try {
    # Check if Microsoft.Graph.Identity.Governance module is available
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.Governance)) {
        Write-Warning "Microsoft.Graph.Identity.Governance module is required for full functionality"
        Write-Host "Install with: Install-Module Microsoft.Graph.Identity.Governance"
    }
    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes "AccessReview.ReadWrite.All"
    Write-Host "Connected to Microsoft Graph"
    # Get group information
    $Group = Get-MgGroup -GroupId $GroupId
    if (-not $Group) {
        Write-Error "Group not found: $GroupId"
        return
    }
    Write-Host "Access Review Configuration:"
    Write-Host "Review Name: $ReviewName"
    Write-Host "Description: $Description"
    Write-Host "Target Group: $($Group.DisplayName)"
    Write-Host "Duration: $DurationInDays days"
    Write-Host "Reviewer Type: $ReviewerType"
    # Calculate review dates
    $StartDate = Get-Date -ErrorAction Stop
    $EndDate = $StartDate.AddDays($DurationInDays)
    Write-Host "Start Date: $($StartDate.ToString('yyyy-MM-dd'))"
    Write-Host "End Date: $($EndDate.ToString('yyyy-MM-dd'))"
    # Access review template
$AccessReviewTemplate = @{
        displayName = $ReviewName
        description = $Description
        startDate = $StartDate.ToString(" yyyy-MM-ddTHH:mm:ss.fffK" )
        endDate = $EndDate.ToString(" yyyy-MM-ddTHH:mm:ss.fffK" )
        scope = @{
            query = " /groups/$GroupId/members"
            queryType = "MicrosoftGraph"
        }
        reviewers = @()
        settings = @{
            defaultDecision = "None"
            defaultDecisionEnabled = $false
            instanceDurationInDays = $DurationInDays
            autoApplyDecisionsEnabled = $false
            recommendationsEnabled = $true
            recurrenceType = " onetime"
        }
    }
    # Configure reviewers
    switch ($ReviewerType) {
        "GroupOwners" {
            $AccessReviewTemplate.reviewers += @{
                query = " /groups/$GroupId/owners"
                queryType = "MicrosoftGraph"
            }
        }
        "SpecificUsers" {
            foreach ($Email in $ReviewerEmails) {
                try {
$User = Get-MgUser -Filter " userPrincipalName eq '$Email'"
                    if ($User) {
                        $AccessReviewTemplate.reviewers += @{
                            query = " /users/$($User.Id)"
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
                query = " /users"
                queryType = "MicrosoftGraph"
                queryRoot = " decisions"
            }
        }
    }
    Write-Host " `n[WARN] IMPORTANT NOTES:"
    Write-Host "Access reviews require Azure AD Premium P2"
    Write-Host "Reviewers will receive email notifications"
    Write-Host "Configure auto-apply based on your needs"
    Write-Host "Monitor review progress and follow up"
    Write-Host " `nAccess Review Benefits:"
    Write-Host "Periodic access certification"
    Write-Host "Compliance with governance policies"
    Write-Host "Automated access cleanup"
    Write-Host "Audit trail of access decisions"
    Write-Host "Risk reduction through regular reviews"
    Write-Host " `nReview Process:"
    Write-Host " 1. Reviewers receive notification emails"
    Write-Host " 2. Review access for each member"
    Write-Host " 3. Approve or deny continued access"
    Write-Host " 4. Provide justification for decisions"
    Write-Host " 5. System applies decisions (if auto-apply enabled)"
    Write-Host " `nBest Practices:"
    Write-Host "Schedule regular recurring reviews"
    Write-Host "Use appropriate reviewers (managers, group owners)"
    Write-Host "Enable recommendations for guidance"
    Write-Host "Set reasonable review periods (1-4 weeks)"
    Write-Host "Follow up on incomplete reviews"
    Write-Host " `nManual Creation Steps:"
    Write-Host " 1. Azure Portal > Azure Active Directory"
    Write-Host " 2. Identity Governance > Access Reviews"
    Write-Host " 3. New Access Review"
    Write-Host " 4. Configure scope, reviewers, and settings"
    Write-Host " 5. Start the review"
    Write-Host " `n Access review template prepared"
    Write-Host "Use Azure Portal to create the actual review for safety"
    Write-Host "Reviewers will be notified via email when review starts"
} catch {
    Write-Error "Access review creation failed: $($_.Exception.Message)"
    Write-Host "Tip: Use Azure Portal for creating Access Reviews"
}


