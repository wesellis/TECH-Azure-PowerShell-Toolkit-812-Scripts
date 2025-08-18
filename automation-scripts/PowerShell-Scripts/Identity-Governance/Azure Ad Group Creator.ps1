<#
.SYNOPSIS
    Azure Ad Group Creator

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
    We Enhanced Azure Ad Group Creator

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
    [string]$WEGroupName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDescription,
    
    [Parameter(Mandatory=$false)]
    [string]$WEGroupType = " Security" ,
    
    [Parameter(Mandatory=$false)]
    [array]$WEMemberEmails = @()
)

Write-WELog " Creating Azure AD Group: $WEGroupName" " INFO"

try {
    # Create the group
    $WEGroupParams = @{
        DisplayName = $WEGroupName
        SecurityEnabled = ($WEGroupType -eq " Security" )
        MailEnabled = ($WEGroupType -eq " Mail" )
    }
    
    if ($WEDescription) {
        $WEGroupParams.Description = $WEDescription
    }
    
    if ($WEGroupType -eq " Mail" ) {
        $WEGroupParams.MailNickname = ($WEGroupName -replace '\s', '').ToLower()
    }
    
   ;  $WEGroup = New-AzADGroup @GroupParams
    
    Write-WELog " ✅ Azure AD Group created successfully:" " INFO"
    Write-WELog "  Group Name: $($WEGroup.DisplayName)" " INFO"
    Write-WELog "  Object ID: $($WEGroup.Id)" " INFO"
    Write-WELog "  Group Type: $WEGroupType" " INFO"
    
    if ($WEDescription) {
        Write-WELog "  Description: $WEDescription" " INFO"
    }
    
    # Add members if provided
    if ($WEMemberEmails.Count -gt 0) {
        Write-WELog " `nAdding members to group..." " INFO"
        
        foreach ($WEEmail in $WEMemberEmails) {
            try {
               ;  $WEUser = Get-AzADUser -UserPrincipalName $WEEmail
                if ($WEUser) {
                    Add-AzADGroupMember -GroupObject $WEGroup -MemberObjectId $WEUser.Id
                    Write-WELog "  ✅ Added: $WEEmail" " INFO"
                } else {
                    Write-WELog "  ❌ User not found: $WEEmail" " INFO"
                }
            } catch {
                Write-WELog "  ❌ Failed to add $WEEmail : $($_.Exception.Message)" " INFO"
            }
        }
    }
    
    Write-WELog " `nGroup Management:" " INFO"
    Write-WELog " • Use this group for role assignments" " INFO"
    Write-WELog " • Assign Azure resource permissions" " INFO"
    Write-WELog " • Manage application access" " INFO"
    Write-WELog " • Control subscription access" " INFO"
    
    Write-WELog " `nNext Steps:" " INFO"
    Write-WELog " 1. Assign Azure roles to this group" " INFO"
    Write-WELog " 2. Add/remove members as needed" " INFO"
    Write-WELog " 3. Configure conditional access policies" " INFO"
    Write-WELog " 4. Set up group-based licensing" " INFO"
    
} catch {
    Write-Error " Failed to create Azure AD group: $($_.Exception.Message)"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================