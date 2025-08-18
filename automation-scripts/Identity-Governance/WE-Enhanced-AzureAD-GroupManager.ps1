# ============================================================================
# Enhanced Azure AD Group Management Tool
# Author: Wesley Ellis
# Contact: wesellis.com
# Version: 2.0 Enhanced Edition
# Date: August 2025
# Description: Advanced Azure Active Directory group creation and management
#              with enhanced validation, reporting, and enterprise features
# ============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Name for the new Azure AD group")]
    [ValidateNotNullOrEmpty()]
    [string]$WEGroupDisplayName,
    
    [Parameter(Mandatory=$false, HelpMessage="Detailed group description")]
    [string]$WEGroupDescription,
    
    [Parameter(Mandatory=$false, HelpMessage="Group type: Security, Mail, or Unified")]
    [ValidateSet("Security", "Mail", "Unified")]
    [string]$WEGroupType = "Security",
    
    [Parameter(Mandatory=$false, HelpMessage="Array of member email addresses to add")]
    [string[]]$WEMemberList = @(),
    
    [Parameter(Mandatory=$false, HelpMessage="Owner email addresses")]
    [string[]]$WEOwnerList = @(),
    
    [Parameter(Mandatory=$false, HelpMessage="Enable detailed logging")]
    [switch]$WEVerboseLogging,
    
    [Parameter(Mandatory=$false, HelpMessage="Export group details to CSV")]
    [switch]$WEExportResults,
    
    [Parameter(Mandatory=$false, HelpMessage="Validate group name uniqueness")]
    [switch]$WEValidateUniqueness
)

# Wesley Ellis Enhanced Error Handling Framework
$ErrorActionPreference = "Stop"
$WELogPrefix = "[WE-AzureAD-GroupManager]"

# Enhanced logging function
[CmdletBinding()]
function Write-WELog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "White"
        "WARN" = "Yellow" 
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    
    $output = "$timestamp $WELogPrefix [$Level] $Message"
    Write-Information $output -ForegroundColor $colorMap[$Level]
    
    if ($WEVerboseLogging) {
        Add-Content -Path "WE-AzureAD-Operations-$(Get-Date -Format 'yyyyMMdd').log" -Value $output
    }
}

# Wesley Ellis Group Validation Function
[CmdletBinding()]
function Test-WEGroupNameAvailability {
    param([string]$GroupName)
    
    Write-WELog "Validating group name availability: $GroupName" "INFO"
    
    try {
        $existingGroup = Get-AzADGroup -DisplayName $GroupName -ErrorAction SilentlyContinue
        if ($existingGroup) {
            Write-WELog "Group name '$GroupName' already exists!" "ERROR"
            return $false
        }
        Write-WELog "Group name is available" "SUCCESS"
        return $true
    } catch {
        Write-WELog "Error checking group availability: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Enhanced User Resolution Function
[CmdletBinding()]
function Resolve-WEUserByEmail {
    param([string]$EmailAddress)
    
    try {
        $user = Get-AzADUser -UserPrincipalName $EmailAddress -ErrorAction SilentlyContinue
        if (-not $user) {
            # Try alternate lookup methods
            $user = Get-AzADUser -Filter "mail eq '$EmailAddress'" -ErrorAction SilentlyContinue
        }
        return $user
    } catch {
        Write-WELog "Failed to resolve user: $EmailAddress - $($_.Exception.Message)" "WARN"
        return $null
    }
}

# Wesley Ellis Main Execution Block
Write-WELog "Starting Enhanced Azure AD Group Creation Process" "INFO"
Write-WELog "Group Name: $WEGroupDisplayName" "INFO"
Write-WELog "Group Type: $WEGroupType" "INFO"
Write-WELog "Author: Wesley Ellis | wesellis.com" "INFO"

try {
    # Step 1: Validate group name uniqueness if requested
    if ($WEValidateUniqueness) {
        if (-not (Test-WEGroupNameAvailability -GroupName $WEGroupDisplayName)) {
            throw "Group name validation failed. Choose a different name."
        }
    }
    
    # Step 2: Build enhanced group parameters
    $WEGroupParameters = @{
        DisplayName = $WEGroupDisplayName
        Description = if ($WEGroupDescription) { $WEGroupDescription } else { "Created by Wesley Ellis Enterprise Toolkit - wesellis.com" }
        SecurityEnabled = ($WEGroupType -in @("Security", "Unified"))
        MailEnabled = ($WEGroupType -in @("Mail", "Unified"))
    }
    
    # Configure mail settings for mail-enabled groups
    if ($WEGroupType -in @("Mail", "Unified")) {
        $WEGroupParameters.MailNickname = ($WEGroupDisplayName -replace '[^a-zA-Z0-9]', '').ToLower()
        Write-WELog "Mail nickname set to: $($WEGroupParameters.MailNickname)" "INFO"
    }
    
    # Step 3: Create the group
    Write-WELog "Creating Azure AD group..." "INFO"
    $WENewGroup = New-AzADGroup -ErrorAction Stop @WEGroupParameters
    
    Write-WELog "✅ Azure AD Group created successfully!" "SUCCESS"
    Write-WELog "   Display Name: $($WENewGroup.DisplayName)" "SUCCESS"
    Write-WELog "   Object ID: $($WENewGroup.Id)" "SUCCESS"
    Write-WELog "   Group Type: $WEGroupType" "SUCCESS"
    
    # Step 4: Add owners if specified
    if ($WEOwnerList.Count -gt 0) {
        Write-WELog "Adding group owners..." "INFO"
        foreach ($ownerEmail in $WEOwnerList) {
            $owner = Resolve-WEUserByEmail -EmailAddress $ownerEmail
            if ($owner) {
                Add-AzADGroupOwner -GroupObject $WENewGroup -OwnerObjectId $owner.Id
                Write-WELog "   ✅ Owner added: $ownerEmail" "SUCCESS"
            } else {
                Write-WELog "   ❌ Owner not found: $ownerEmail" "WARN"
            }
        }
    }
    
    # Step 5: Add members if specified
    if ($WEMemberList.Count -gt 0) {
        Write-WELog "Adding group members..." "INFO"
        $successCount = 0
        
        foreach ($memberEmail in $WEMemberList) {
            $member = Resolve-WEUserByEmail -EmailAddress $memberEmail
            if ($member) {
                Add-AzADGroupMember -GroupObject $WENewGroup -MemberObjectId $member.Id
                Write-WELog "   ✅ Member added: $memberEmail" "SUCCESS"
                $successCount++
            } else {
                Write-WELog "   ❌ Member not found: $memberEmail" "WARN"
            }
        }
        
        Write-WELog "Members added: $successCount of $($WEMemberList.Count)" "INFO"
    }
    
    # Step 6: Generate enhanced output and recommendations
    $WEGroupSummary = [PSCustomObject]@{
        GroupName = $WENewGroup.DisplayName
        ObjectId = $WENewGroup.Id
        GroupType = $WEGroupType
        Description = $WEGroupParameters.Description
        MembersAdded = if ($WEMemberList) { $WEMemberList.Count } else { 0 }
        OwnersAdded = if ($WEOwnerList) { $WEOwnerList.Count } else { 0 }
        CreatedBy = "Wesley Ellis Enterprise Toolkit"
        CreatedDate = Get-Date -ErrorAction Stop
        Website = "wesellis.com"
    }
    
    # Display enhanced recommendations
    Write-WELog "📋 Enterprise Management Recommendations:" "INFO"
    Write-WELog "   • Configure Conditional Access policies for this group" "INFO"
    Write-WELog "   • Set up Azure role assignments for resource access" "INFO"
    Write-WELog "   • Enable group-based app assignments" "INFO"
    Write-WELog "   • Consider implementing group expiration policies" "INFO"
    Write-WELog "   • Set up automated group membership rules if needed" "INFO"
    
    # Export results if requested
    if ($WEExportResults) {
        $exportPath = "WE-AzureAD-Group-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $WEGroupSummary | Export-Csv -Path $exportPath -NoTypeInformation
        Write-WELog "✅ Group details exported to: $exportPath" "SUCCESS"
    }
    
    Write-WELog "🎉 Wesley Ellis Enhanced Group Creation Complete!" "SUCCESS"
    return $WEGroupSummary
    
} catch {
    Write-WELog "❌ Group creation failed: $($_.Exception.Message)" "ERROR"
    Write-WELog "Contact: wesellis.com for support" "ERROR"
    throw
}

# Wesley Ellis Enterprise Toolkit
# More tools available at: wesellis.com
# ============================================================================