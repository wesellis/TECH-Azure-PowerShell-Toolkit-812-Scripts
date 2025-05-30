# ============================================================================
# Script Name: Azure AD Group Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Active Directory groups for access management
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$GroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [string]$GroupType = "Security",
    
    [Parameter(Mandatory=$false)]
    [array]$MemberEmails = @()
)

Write-Host "Creating Azure AD Group: $GroupName"

try {
    # Create the group
    $GroupParams = @{
        DisplayName = $GroupName
        SecurityEnabled = ($GroupType -eq "Security")
        MailEnabled = ($GroupType -eq "Mail")
    }
    
    if ($Description) {
        $GroupParams.Description = $Description
    }
    
    if ($GroupType -eq "Mail") {
        $GroupParams.MailNickname = ($GroupName -replace '\s', '').ToLower()
    }
    
    $Group = New-AzADGroup @GroupParams
    
    Write-Host "✅ Azure AD Group created successfully:"
    Write-Host "  Group Name: $($Group.DisplayName)"
    Write-Host "  Object ID: $($Group.Id)"
    Write-Host "  Group Type: $GroupType"
    
    if ($Description) {
        Write-Host "  Description: $Description"
    }
    
    # Add members if provided
    if ($MemberEmails.Count -gt 0) {
        Write-Host "`nAdding members to group..."
        
        foreach ($Email in $MemberEmails) {
            try {
                $User = Get-AzADUser -UserPrincipalName $Email
                if ($User) {
                    Add-AzADGroupMember -GroupObject $Group -MemberObjectId $User.Id
                    Write-Host "  ✅ Added: $Email"
                } else {
                    Write-Host "  ❌ User not found: $Email"
                }
            } catch {
                Write-Host "  ❌ Failed to add $Email : $($_.Exception.Message)"
            }
        }
    }
    
    Write-Host "`nGroup Management:"
    Write-Host "• Use this group for role assignments"
    Write-Host "• Assign Azure resource permissions"
    Write-Host "• Manage application access"
    Write-Host "• Control subscription access"
    
    Write-Host "`nNext Steps:"
    Write-Host "1. Assign Azure roles to this group"
    Write-Host "2. Add/remove members as needed"
    Write-Host "3. Configure conditional access policies"
    Write-Host "4. Set up group-based licensing"
    
} catch {
    Write-Error "Failed to create Azure AD group: $($_.Exception.Message)"
}
