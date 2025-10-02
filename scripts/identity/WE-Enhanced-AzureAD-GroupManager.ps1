#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
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
    [string]$ErrorActionPreference = "Stop"
    [string]$LogPrefix = "[WE-AzureAD-GroupManager]"
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    [string]$output = "$timestamp $LogPrefix [$Level] $Message"
    Write-Output $output -ForegroundColor $ColorMap[$Level]
    if ($VerboseLogging) {
        Add-Content -Path "WE-AzureAD-Operations-$(Get-Date -Format 'yyyyMMdd').log" -Value $output
    }
}
function Test-WEGroupNameAvailability {
    param([string]$GroupName)
    Write-Output "Validating group name availability: $GroupName"
    try {
    [string]$ExistingGroup = Get-AzADGroup -DisplayName $GroupName -ErrorAction SilentlyContinue
        if ($ExistingGroup) {
            Write-Output "Group name '$GroupName' already exists!" # Color: $2
            return $false
        }
        Write-Output "Group name is available" # Color: $2
        return $true
    } catch {
        Write-Output "Error checking group availability: $($_.Exception.Message)" # Color: $2
        return $false
    }
}
function Resolve-WEUserByEmail {
    param([string]$EmailAddress)
    try {
    [string]$user = Get-AzADUser -UserPrincipalName $EmailAddress -ErrorAction SilentlyContinue
        if (-not $user) {
    [string]$user = Get-AzADUser -Filter "mail eq '$EmailAddress'" -ErrorAction SilentlyContinue
        }
        return $user
    } catch {
        Write-Output "Failed to resolve user: $EmailAddress - $($_.Exception.Message)" # Color: $2
        return $null
    }
}
Write-Output "Starting Enhanced Azure AD Group Creation Process"
Write-Output "Group Name: $GroupDisplayName"
Write-Output "Group Type: $GroupType"
Write-Output "Author: Wesley Ellis | wesellis.com"
try {
    if ($ValidateUniqueness) {
        if (-not (Test-WEGroupNameAvailability -GroupName $GroupDisplayName)) {
            throw "Group name validation failed. Choose a different name."
        }
    }
    $GroupParameters = @{
        DisplayName = $GroupDisplayName
        Description = if ($GroupDescription) { $GroupDescription } else { "Created by Wesley Ellis Enterprise Toolkit - wesellis.com" }
        SecurityEnabled = ($GroupType -in @("Security", "Unified"))
        MailEnabled = ($GroupType -in @("Mail", "Unified"))
    }
    if ($GroupType -in @("Mail", "Unified")) {
    [string]$GroupParameters.MailNickname = ($GroupDisplayName -replace '[^a-zA-Z0-9]', '').ToLower()
        Write-Output "Mail nickname set to: $($GroupParameters.MailNickname)"
    }
    Write-Output "Creating Azure AD group..."
    [string]$NewGroup = New-AzADGroup -ErrorAction Stop @WEGroupParameters
    Write-Output "Azure AD Group created successfully!" # Color: $2
    Write-Output "   Display Name: $($NewGroup.DisplayName)" # Color: $2
    Write-Output "   Object ID: $($NewGroup.Id)" # Color: $2
    Write-Output "   Group Type: $GroupType" # Color: $2
    if ($OwnerList.Count -gt 0) {
        Write-Output "Adding group owners..."
        foreach ($OwnerEmail in $OwnerList) {
    [string]$owner = Resolve-WEUserByEmail -EmailAddress $OwnerEmail
            if ($owner) {
                Add-AzADGroupOwner -GroupObject $NewGroup -OwnerObjectId $owner.Id
                Write-Output "    Owner added: $OwnerEmail" # Color: $2
            } else {
                Write-Output "    Owner not found: $OwnerEmail" # Color: $2
            }
        }
    }
    if ($MemberList.Count -gt 0) {
        Write-Output "Adding group members..."
    [string]$SuccessCount = 0
        foreach ($MemberEmail in $MemberList) {
    [string]$member = Resolve-WEUserByEmail -EmailAddress $MemberEmail
            if ($member) {
                Add-AzADGroupMember -GroupObject $NewGroup -MemberObjectId $member.Id
                Write-Output "    Member added: $MemberEmail" # Color: $2
    [string]$SuccessCount++
            } else {
                Write-Output "    Member not found: $MemberEmail" # Color: $2
            }
        }
        Write-Output "Members added: $SuccessCount of $($MemberList.Count)"
    }
    [string]$GroupSummary = [PSCustomObject]@{
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
    Write-Output "Enterprise Management Recommendations:"
    Write-Output "    Configure Conditional Access policies for this group"
    Write-Output "    Set up Azure role assignments for resource access"
    Write-Output "    Enable group-based app assignments"
    Write-Output "    Consider implementing group expiration policies"
    Write-Output "    Set up automated group membership rules if needed"
    if ($ExportResults) {
    [string]$ExportPath = "WE-AzureAD-Group-Export-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    [string]$GroupSummary | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Output "Group details exported to: $ExportPath" # Color: $2
    }
    Write-Output "Wesley Ellis Enhanced Group Creation Complete!" # Color: $2
    return $GroupSummary
} catch {
    Write-Output "Group creation failed: $($_.Exception.Message)" # Color: $2
    Write-Output "Contact: wesellis.com for support" # Color: $2
    throw`n}
