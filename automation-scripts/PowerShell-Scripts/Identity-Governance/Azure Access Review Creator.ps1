<#
.SYNOPSIS
    Azure Access Review Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Access Review Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



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
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEReviewName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDescription,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGroupId,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDurationInDays = 14,
    
    [Parameter(Mandatory=$false)]
    [string]$WEReviewerType = " GroupOwners" ,
    
    [Parameter(Mandatory=$false)]
    [array]$WEReviewerEmails = @()
)

Write-WELog " Creating Access Review: $WEReviewName" " INFO"

try {
    # Check if Microsoft.Graph.Identity.Governance module is available
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.Governance)) {
        Write-Warning " Microsoft.Graph.Identity.Governance module is required for full functionality"
        Write-WELog " Install with: Install-Module Microsoft.Graph.Identity.Governance" " INFO"
    }
    
    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes " AccessReview.ReadWrite.All"
    
    Write-WELog " ✅ Connected to Microsoft Graph" " INFO"
    
    # Get group information
    $WEGroup = Get-MgGroup -GroupId $WEGroupId
    if (-not $WEGroup) {
        Write-Error " Group not found: $WEGroupId"
        return
    }
    
    Write-WELog " 📋 Access Review Configuration:" " INFO"
    Write-WELog "  Review Name: $WEReviewName" " INFO"
    Write-WELog "  Description: $WEDescription" " INFO"
    Write-WELog "  Target Group: $($WEGroup.DisplayName)" " INFO"
    Write-WELog "  Duration: $WEDurationInDays days" " INFO"
    Write-WELog "  Reviewer Type: $WEReviewerType" " INFO"
    
    # Calculate review dates
    $WEStartDate = Get-Date
    $WEEndDate = $WEStartDate.AddDays($WEDurationInDays)
    
    Write-WELog "  Start Date: $($WEStartDate.ToString('yyyy-MM-dd'))" " INFO"
    Write-WELog "  End Date: $($WEEndDate.ToString('yyyy-MM-dd'))" " INFO"
    
    # Access review template
   ;  $WEAccessReviewTemplate = @{
        displayName = $WEReviewName
        description = $WEDescription
        startDate = $WEStartDate.ToString(" yyyy-MM-ddTHH:mm:ss.fffK" )
        endDate = $WEEndDate.ToString(" yyyy-MM-ddTHH:mm:ss.fffK" )
        scope = @{
            query = " /groups/$WEGroupId/members"
            queryType = " MicrosoftGraph"
        }
        reviewers = @()
        settings = @{
            defaultDecision = " None"
            defaultDecisionEnabled = $false
            instanceDurationInDays = $WEDurationInDays
            autoApplyDecisionsEnabled = $false
            recommendationsEnabled = $true
            recurrenceType = " onetime"
        }
    }
    
    # Configure reviewers
    switch ($WEReviewerType) {
        " GroupOwners" {
            $WEAccessReviewTemplate.reviewers += @{
                query = " /groups/$WEGroupId/owners"
                queryType = " MicrosoftGraph"
            }
        }
        " SpecificUsers" {
            foreach ($WEEmail in $WEReviewerEmails) {
                try {
                   ;  $WEUser = Get-MgUser -Filter " userPrincipalName eq '$WEEmail'"
                    if ($WEUser) {
                        $WEAccessReviewTemplate.reviewers += @{
                            query = " /users/$($WEUser.Id)"
                            queryType = " MicrosoftGraph"
                        }
                    }
                } catch {
                    Write-Warning " Could not find user: $WEEmail"
                }
            }
        }
        " SelfReview" {
            $WEAccessReviewTemplate.reviewers += @{
                query = " /users"
                queryType = " MicrosoftGraph"
                queryRoot = " decisions"
            }
        }
    }
    
    Write-WELog " `n⚠️ IMPORTANT NOTES:" " INFO"
    Write-WELog " • Access reviews require Azure AD Premium P2" " INFO"
    Write-WELog " • Reviewers will receive email notifications" " INFO"
    Write-WELog " • Configure auto-apply based on your needs" " INFO"
    Write-WELog " • Monitor review progress and follow up" " INFO"
    
    Write-WELog " `nAccess Review Benefits:" " INFO"
    Write-WELog " • Periodic access certification" " INFO"
    Write-WELog " • Compliance with governance policies" " INFO"
    Write-WELog " • Automated access cleanup" " INFO"
    Write-WELog " • Audit trail of access decisions" " INFO"
    Write-WELog " • Risk reduction through regular reviews" " INFO"
    
    Write-WELog " `nReview Process:" " INFO"
    Write-WELog " 1. Reviewers receive notification emails" " INFO"
    Write-WELog " 2. Review access for each member" " INFO"
    Write-WELog " 3. Approve or deny continued access" " INFO"
    Write-WELog " 4. Provide justification for decisions" " INFO"
    Write-WELog " 5. System applies decisions (if auto-apply enabled)" " INFO"
    
    Write-WELog " `nBest Practices:" " INFO"
    Write-WELog " • Schedule regular recurring reviews" " INFO"
    Write-WELog " • Use appropriate reviewers (managers, group owners)" " INFO"
    Write-WELog " • Enable recommendations for guidance" " INFO"
    Write-WELog " • Set reasonable review periods (1-4 weeks)" " INFO"
    Write-WELog " • Follow up on incomplete reviews" " INFO"
    
    Write-WELog " `nManual Creation Steps:" " INFO"
    Write-WELog " 1. Azure Portal > Azure Active Directory" " INFO"
    Write-WELog " 2. Identity Governance > Access Reviews" " INFO"
    Write-WELog " 3. New Access Review" " INFO"
    Write-WELog " 4. Configure scope, reviewers, and settings" " INFO"
    Write-WELog " 5. Start the review" " INFO"
    
    Write-WELog " `n✅ Access review template prepared" " INFO"
    Write-WELog " 🚨 Use Azure Portal to create the actual review for safety" " INFO"
    Write-WELog " 📧 Reviewers will be notified via email when review starts" " INFO"
    
} catch {
    Write-Error " Access review creation failed: $($_.Exception.Message)"
    Write-WELog " 💡 Tip: Use Azure Portal for creating Access Reviews" " INFO"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================