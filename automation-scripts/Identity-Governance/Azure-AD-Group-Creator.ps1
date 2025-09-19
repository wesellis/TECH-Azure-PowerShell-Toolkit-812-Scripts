#Requires -Version 7.0
#Requires -Module Az.Resources

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
    [string]$GroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [string]$GroupType = "Security",
    
    [Parameter(Mandatory=$false)]
    [array]$MemberEmails = @()
)

#region Functions

Write-Information "Creating Azure AD Group: $GroupName"

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
    
    $Group = New-AzADGroup -ErrorAction Stop @GroupParams
    
    Write-Information " Azure AD Group created successfully:"
    Write-Information "  Group Name: $($Group.DisplayName)"
    Write-Information "  Object ID: $($Group.Id)"
    Write-Information "  Group Type: $GroupType"
    
    if ($Description) {
        Write-Information "  Description: $Description"
    }
    
    # Add members if provided
    if ($MemberEmails.Count -gt 0) {
        Write-Information "`nAdding members to group..."
        
        foreach ($Email in $MemberEmails) {
            try {
                $User = Get-AzADUser -UserPrincipalName $Email
                if ($User) {
                    Add-AzADGroupMember -GroupObject $Group -MemberObjectId $User.Id
                    Write-Information "   Added: $Email"
                } else {
                    Write-Information "   User not found: $Email"
                }
            } catch {
                Write-Information "   Failed to add $Email : $($_.Exception.Message)"
            }
        }
    }
    
    Write-Information "`nGroup Management:"
    Write-Information "• Use this group for role assignments"
    Write-Information "• Assign Azure resource permissions"
    Write-Information "• Manage application access"
    Write-Information "• Control subscription access"
    
    Write-Information "`nNext Steps:"
    Write-Information "1. Assign Azure roles to this group"
    Write-Information "2. Add/remove members as needed"
    Write-Information "3. Configure conditional access policies"
    Write-Information "4. Set up group-based licensing"
    
} catch {
    Write-Error "Failed to create Azure AD group: $($_.Exception.Message)"
}


#endregion
