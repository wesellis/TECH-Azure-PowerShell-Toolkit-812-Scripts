#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage Azure resources

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations and operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$GroupName,
    [Parameter()]
    [string]$Description,
    [Parameter()]
    [string]$GroupType = "Security",
    [Parameter()]
    [array]$MemberEmails = @()
)
Write-Output "Creating Azure AD Group: $GroupName"
try {
    if ($Description) {
        $GroupParams.Description = $Description
    }
    if ($GroupType -eq "Mail") {
        $GroupParams.MailNickname = ($GroupName -replace '\s', '').ToLower()
    }
    $Group = New-AzADGroup -ErrorAction Stop @GroupParams
    Write-Output "Azure AD Group created successfully:"
    Write-Output "Group Name: $($Group.DisplayName)"
    Write-Output "Object ID: $($Group.Id)"
    Write-Output "Group Type: $GroupType"
    if ($Description) {
        Write-Output "Description: $Description"
    }
    if ($MemberEmails.Count -gt 0) {
        Write-Output "`nAdding members to group..."
        foreach ($Email in $MemberEmails) {
            try {
                $User = Get-AzADUser -UserPrincipalName $Email
                if ($User) {
                    Add-AzADGroupMember -GroupObject $Group -MemberObjectId $User.Id
                    Write-Output "   Added: $Email"
                } else {
                    Write-Output "   User not found: $Email"
                }
            } catch {
                Write-Output "   Failed to add $Email : $($_.Exception.Message)"
            }
        }
    }
    Write-Output "`nGroup Management:"
    Write-Output "Use this group for role assignments"
    Write-Output "Assign Azure resource permissions"
    Write-Output "Manage application access"
    Write-Output "Control subscription access"
    Write-Output "`nNext Steps:"
    Write-Output "1. Assign Azure roles to this group"
    Write-Output "2. Add/remove members as needed"
    Write-Output "3. Configure conditional access policies"
    Write-Output "4. Set up group-based licensing"
} catch {
    Write-Error "Failed to create Azure AD group: $($_.Exception.Message)"`n}
