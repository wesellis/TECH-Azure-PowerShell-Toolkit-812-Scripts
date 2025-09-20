#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Enhanced Azure AD Group Management Tool
# Contact: wesellis.com
# Version: 2.0 Enhanced Edition
#              with enhanced validation, reporting, and enterprise features
[CmdletBinding()]
param (
    [Parameter(Mandatory, HelpMessage="Name for the new Azure AD group")]
    [ValidateNotNullOrEmpty()]
    [string]$GroupDisplayName,
    [Parameter(HelpMessage=" group description")]
    [string]$GroupDescription,
    [Parameter(HelpMessage="Group type: Security, Mail, or Unified")]
    [ValidateSet("Security", "Mail", "Unified")]
    [string]$GroupType = "Security",
    [Parameter(HelpMessage="Array of member email addresses to add")]
    [string[]]$MemberList = @(),
    [Parameter(HelpMessage="Owner email addresses")]
    [string[]]$OwnerList = @(),
    [Parameter(HelpMessage="Enable  logging")]
    [switch]$VerboseLogging,
    [Parameter(HelpMessage="Export group details to CSV")]
    [switch]$ExportResults,
    [Parameter(HelpMessage="Validate group name uniqueness")]
    [switch]$ValidateUniqueness
)
# Wesley Ellis Enhanced Error Handling Framework
$ErrorActionPreference = "Stop"
$LogPrefix = "[WE-AzureAD-GroupManager]"
# Enhanced logging function
[OutputType([bool])]
 {
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
    $output = "$timestamp $LogPrefix [$Level] $Message"
    Write-Host $output -ForegroundColor $colorMap[$Level]
    if ($VerboseLogging) {
        Add-Content -Path "WE-AzureAD-Operations-$(Get-Date -Format 'yyyyMMdd').log" -Value $output
    }
}
# Wesley Ellis Group Validation Function
function Test-WEGroupNameAvailability {
    param([string]$GroupName)
    Write-Host "Validating group name availability: $GroupName"
    try {
        $existingGroup = Get-AzADGroup -DisplayName $GroupName -ErrorAction SilentlyContinue
        if ($existingGroup) {
            Write-Host "Group name '$GroupName' already exists!" -ForegroundColor Red
            return $false
        }
        Write-Host "Group name is available" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error checking group availability: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
# Enhanced User Resolution Function
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
        Write-Host "Failed to resolve user: $EmailAddress - $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}
# Wesley Ellis Main Execution Block
Write-Host "Starting Enhanced Azure AD Group Creation Process"
Write-Host "Group Name: $GroupDisplayName"
Write-Host "Group Type: $GroupType"
Write-Host "Author: Wesley Ellis | wesellis.com"
try {
    # Step 1: Validate group name uniqueness if requested
    if ($ValidateUniqueness) {
        if (-not (Test-WEGroupNameAvailability -GroupName $GroupDisplayName)) {
            throw "Group name validation failed. Choose a different name."
        }
    }
    # Step 2: Build enhanced group parameters
    $GroupParameters = @{
        DisplayName = $GroupDisplayName
        Description = if ($GroupDescription) { $GroupDescription } else { "Created by Wesley Ellis Enterprise Toolkit - wesellis.com" }
        SecurityEnabled = ($GroupType -in @("Security", "Unified"))
        MailEnabled = ($GroupType -in @("Mail", "Unified"))
    }
    # Configure mail settings for mail-enabled groups
    if ($GroupType -in @("Mail", "Unified")) {
        $GroupParameters.MailNickname = ($GroupDisplayName -replace '[^a-zA-Z0-9]', '').ToLower()
        Write-Host "Mail nickname set to: $($GroupParameters.MailNickname)"
    }
    # Step 3: Create the group
    Write-Host "Creating Azure AD group..."
    $NewGroup = New-AzADGroup -ErrorAction Stop @WEGroupParameters
    Write-Host "Azure AD Group created successfully!" -ForegroundColor Green
    Write-Host "   Display Name: $($NewGroup.DisplayName)" -ForegroundColor Green
    Write-Host "   Object ID: $($NewGroup.Id)" -ForegroundColor Green
    Write-Host "   Group Type: $GroupType" -ForegroundColor Green
    # Step 4: Add owners if specified
    if ($OwnerList.Count -gt 0) {
        Write-Host "Adding group owners..."
        foreach ($ownerEmail in $OwnerList) {
            $owner = Resolve-WEUserByEmail -EmailAddress $ownerEmail
            if ($owner) {
                Add-AzADGroupOwner -GroupObject $NewGroup -OwnerObjectId $owner.Id
                Write-Host "    Owner added: $ownerEmail" -ForegroundColor Green
            } else {
                Write-Host "    Owner not found: $ownerEmail" -ForegroundColor Yellow
            }
        }
    }
    # Step 5: Add members if specified
    if ($MemberList.Count -gt 0) {
        Write-Host "Adding group members..."
        $successCount = 0
        foreach ($memberEmail in $MemberList) {
            $member = Resolve-WEUserByEmail -EmailAddress $memberEmail
            if ($member) {
                Add-AzADGroupMember -GroupObject $NewGroup -MemberObjectId $member.Id
                Write-Host "    Member added: $memberEmail" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "    Member not found: $memberEmail" -ForegroundColor Yellow
            }
        }
        Write-Host "Members added: $successCount of $($MemberList.Count)"
    }
    # Step 6: Generate enhanced output and recommendations
    $GroupSummary = [PSCustomObject]@{
        GroupName = $NewGroup.DisplayName
        ObjectId = $NewGroup.Id
        GroupType = $GroupType
        Description = $GroupParameters.Description
        MembersAdded = if ($MemberList) { $MemberList.Count } else { 0 }
        OwnersAdded = if ($OwnerList) { $OwnerList.Count } else { 0 }
        CreatedBy = "Wesley Ellis Enterprise Toolkit"
        CreatedDate = Get-Date -ErrorAction Stop
        Website = "wesellis.com"
    }
    # Display enhanced recommendations
    Write-Host "Enterprise Management Recommendations:"
    Write-Host "    Configure Conditional Access policies for this group"
    Write-Host "    Set up Azure role assignments for resource access"
    Write-Host "    Enable group-based app assignments"
    Write-Host "    Consider implementing group expiration policies"
    Write-Host "    Set up automated group membership rules if needed"
    # Export results if requested
    if ($ExportResults) {
        $exportPath = "WE-AzureAD-Group-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $GroupSummary | Export-Csv -Path $exportPath -NoTypeInformation
        Write-Host "Group details exported to: $exportPath" -ForegroundColor Green
    }
    Write-Host "Wesley Ellis Enhanced Group Creation Complete!" -ForegroundColor Green
    return $GroupSummary
} catch {
    Write-Host "Group creation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Contact: wesellis.com for support" -ForegroundColor Red
    throw
}
# Wesley Ellis Enterprise Toolkit
# More tools available at: wesellis.com

