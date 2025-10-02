#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("GetUsers", "GetGroups", "CreateUser", "GetMailboxes", "GetTeams", "GetSites", "ManagePermissions")]
    $Operation,
    [Parameter()]
    $TenantId,
    [Parameter()]
    $ClientId,
    [Parameter()]
    $ClientSecret,
    [Parameter()]
    $UserPrincipalName,
    [Parameter()]
    $DisplayName,
    [Parameter()]
    $Department,
    [Parameter()]
    $JobTitle,
    [Parameter()]
    $OutputFormat = "Table",
    [Parameter(HelpMessage="Path to export results")]
    $ExportPath,
    [Parameter(HelpMessage="Maximum number of results to return")]
    [ValidateRange(1, 1000)]
    [int]$MaxResults = 100,
    [Parameter(HelpMessage="Include disabled users in results")]
    [switch]$IncludeDisabledUsers,
    [Parameter(HelpMessage="Include detailed output properties")]
    [switch]$DetailedOutput
)
    $ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [Parameter(Mandatory)]
        $Message,
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        $Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
    }
    Write-Output "[$timestamp] [$Level] $Message" -ForegroundColor $color
}
function Invoke-GraphOperation {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Operation,
        [Parameter(Mandatory)]
        $OperationName
    )
    try {
        Write-Log "Executing: $OperationName" -Level INFO
        return & $Operation
    }
    catch {
        Write-Log "Failed: $OperationName - $($_.Exception.Message)" -Level ERROR
        throw
    }
}
try {
    Write-Output "Microsoft Graph Integration Tool" # Color: $2
    Write-Output "================================" # Color: $2
    Write-Output "Operation: $Operation" # Color: $2
    Write-Output ""
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Validating connectivity..." -PercentComplete 10
    if (-not (Get-Module Microsoft.Graph -ListAvailable)) {
        Write-Log "Microsoft.Graph module not found. Please install it first." -Level ERROR
        throw "Required module Microsoft.Graph is not installed. Install with: Install-Module Microsoft.Graph"
    }
    Write-Log "Checking Microsoft Graph connection..." -Level INFO
    if ($ClientId -and $ClientSecret -and $TenantId) {
        Write-Log "Connecting using service principal authentication..." -Level INFO
    $SecureSecret = Read-Host -Prompt "Enter secure value" -AsSecureString
    $credential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential($ClientId, $SecureSecret)
        Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $credential
    } else {
        Write-Log "Connecting using interactive authentication..." -Level INFO
        Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Sites.Read.All", "TeamMember.Read.All"
    }
    $context = Get-MgContext -ErrorAction Stop
    Write-Log "Connected to Microsoft Graph - Tenant: $($context.TenantId)" -Level SUCCESS
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Executing $Operation..." -PercentComplete 30
    $results = @()
    switch ($Operation) {
        "GetUsers" {
            Write-Log "Retrieving user information..." -Level INFO
    $filter = ""
            if (-not $IncludeDisabledUsers) {
    $filter = "accountEnabled eq true"
            }
            if ($Department) {
    $DeptFilter = "department eq '$Department'"
    $filter = if ($filter) { "$filter and $DeptFilter" } else { $DeptFilter }
            }
    $users = Invoke-GraphOperation -Operation {
    $params = @{
                    Top = $MaxResults
                }
                if ($filter) { $params.Filter = $filter }
                if ($DetailedOutput) {
    $params.Property = @("id", "displayName", "userPrincipalName", "mail", "department", "jobTitle", "accountEnabled", "createdDateTime", "lastSignInDateTime")
                }
                Get-MgUser -ErrorAction Stop @params
            } -OperationName "Get Users"
    $results = $users | ForEach-Object {
                [PSCustomObject]@{
                    DisplayName = $_.DisplayName
                    UserPrincipalName = $_.UserPrincipalName
                    Email = $_.Mail
                    Department = $_.Department
                    JobTitle = $_.JobTitle
                    Enabled = $_.AccountEnabled
                    Created = $_.CreatedDateTime
                    LastSignIn = $_.LastSignInDateTime
                }
            }
            Write-Log "Retrieved $($results.Count) users" -Level SUCCESS
        }
        "GetGroups" {
            Write-Log "Retrieving group information..." -Level INFO
    $groups = Invoke-GraphOperation -Operation {
    $params = @{
                    Top = $MaxResults
                }
                if ($DetailedOutput) {
    $params.Property = @("id", "displayName", "description", "mailEnabled", "securityEnabled", "createdDateTime", "membershipRule")
                }
                Get-MgGroup -ErrorAction Stop @params
            } -OperationName "Get Groups"
    $results = $groups | ForEach-Object {
                [PSCustomObject]@{
                    DisplayName = $_.DisplayName
                    Description = $_.Description
                    MailEnabled = $_.MailEnabled
                    SecurityEnabled = $_.SecurityEnabled
                    Created = $_.CreatedDateTime
                    GroupType = if ($_.SecurityEnabled -and $_.MailEnabled) { "Mail-enabled Security" }
                               elseif ($_.SecurityEnabled) { "Security" }
                               elseif ($_.MailEnabled) { "Distribution" }
                               else { "Other" }
                }
            }
            Write-Log "Retrieved $($results.Count) groups" -Level SUCCESS
        }
        "GetTeams" {
            Write-Log "Retrieving Teams information..." -Level INFO
    $teams = Invoke-GraphOperation -Operation {
                Get-MgTeam -Top $MaxResults
            } -OperationName "Get Teams"
    $results = $teams | ForEach-Object {
    $team = $_
    $group = Get-MgGroup -GroupId $team.Id
                [PSCustomObject]@{
                    DisplayName = $group.DisplayName
                    Description = $group.Description
                    Privacy = $team.Visibility
                    Created = $group.CreatedDateTime
                    MemberCount = (Get-MgTeamMember -TeamId $team.Id).Count
                }
            }
            Write-Log "Retrieved $($results.Count) Teams" -Level SUCCESS
        }
        "GetSites" {
            Write-Log "Retrieving SharePoint sites..." -Level INFO
    $sites = Invoke-GraphOperation -Operation {
                Get-MgSite -Top $MaxResults
            } -OperationName "Get SharePoint Sites"
    $results = $sites | ForEach-Object {
                [PSCustomObject]@{
                    DisplayName = $_.DisplayName
                    WebUrl = $_.WebUrl
                    Description = $_.Description
                    Created = $_.CreatedDateTime
                    LastModified = $_.LastModifiedDateTime
                }
            }
            Write-Log "Retrieved $($results.Count) SharePoint sites" -Level SUCCESS
        }
        "CreateUser" {
            if (-not $UserPrincipalName -or -not $DisplayName) {
                throw "UserPrincipalName and DisplayName are required for user creation"
            }
            Write-Log "Creating new user: $UserPrincipalName" -Level INFO
    $PasswordProfile = @{
                ForceChangePasswordNextSignIn = $true
                Password = $env:CREDENTIAL_Password
            }
    $UserParams = @{
                DisplayName = $DisplayName
                UserPrincipalName = $UserPrincipalName
                AccountEnabled = $true
                PasswordProfile = $PasswordProfile
                UsageLocation = "US"
            }
            if ($Department) { $UserParams.Department = $Department }
            if ($JobTitle) { $UserParams.JobTitle = $JobTitle }
    $NewUser = Invoke-GraphOperation -Operation {
                New-MgUser -ErrorAction Stop @userParams
            } -OperationName "Create User"
    $results = @([PSCustomObject]@{
                DisplayName = $NewUser.DisplayName
                UserPrincipalName = $NewUser.UserPrincipalName
                UserId = $NewUser.Id
                Status = "Created Successfully"
                TempPassword = $PasswordProfile.Password
            })
            Write-Log "User created successfully: $UserPrincipalName" -Level SUCCESS
        }
    }
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Processing results..." -PercentComplete 60
    if ($results.Count -gt 0) {
        Write-Output ""
        Write-Output " $Operation Results ($($results.Count) items)"
        switch ($OutputFormat.ToLower()) {
            "table" {
    $results | Format-Table -AutoSize
            }
            "list" {
    $results | Format-List
            }
            "json" {
    $results | ConvertTo-Json -Depth 3
            }
            "csv" {
    $results | ConvertTo-Csv -NoTypeInformation
            }
            default {
    $results | Format-Table -AutoSize
            }
        }
    }
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Exporting results..." -PercentComplete 75
    if ($ExportPath -and $results.Count -gt 0) {
    $ExportFile = $ExportPath
        if (-not $ExportFile.EndsWith('.csv')) {
    $ExportFile += '.csv'
        }
    $results | Export-Csv -Path $ExportFile -NoTypeInformation -Force
        Write-Log "Results exported to: $ExportFile" -Level SUCCESS
    }
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Generating statistics..." -PercentComplete 85
    $stats = @{
        TotalRecords = $results.Count
        Operation = $Operation
        ExecutedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TenantId = $context.TenantId
    }
    if ($Operation -eq "GetUsers" -and $results.Count -gt 0) {
    $EnabledUsers = ($results | Where-Object { $_.Enabled }).Count
    $DisabledUsers = $results.Count - $EnabledUsers
    $stats.EnabledUsers = $EnabledUsers
    $stats.DisabledUsers = $DisabledUsers
    $stats.TopDepartments = ($results | Group-Object Department | Sort-Object Count -Descending | Select-Object -First 5).Name -join ", "
    }
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Finalizing..." -PercentComplete 95
    Write-Output ""
    Write-Output "                              MICROSOFT GRAPH OPERATION SUCCESSFUL"
    Write-Output ""
    Write-Output "Operation Summary:"
    Write-Output "    Operation: $Operation"
    Write-Output "    Records Retrieved: $($stats.TotalRecords)"
    Write-Output "    Tenant: $($stats.TenantId)"
    Write-Output "    Executed: $($stats.ExecutedAt)"
    if ($stats.ContainsKey("EnabledUsers")) {
        Write-Output ""
        Write-Output "    Enabled Users: $($stats.EnabledUsers)"
        Write-Output "    Disabled Users: $($stats.DisabledUsers)"
        if ($stats.TopDepartments) {
            Write-Output "    Top Departments: $($stats.TopDepartments)"
        }
    }
    if ($ExportPath) {
        Write-Output ""
        Write-Output "[FOLDER] Export Information:"
        Write-Output "    Export Path: $ExportFile"
        Write-Output "    Format: CSV"
    }
    Write-Output ""
    Write-Output "    Review the results for compliance and security"
    Write-Output "    Set up automated reporting for regular monitoring"
    Write-Output "    Consider implementing governance policies"
    Write-Output ""
    Write-Log "Microsoft Graph operation '$Operation' completed successfully!" -Level SUCCESS
} catch {
    Write-Log "Microsoft Graph operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    Write-Output ""
    Write-Output "Troubleshooting Tips:"
    Write-Output "    Verify Microsoft.Graph PowerShell module is installed"
    Write-Output "    Check application permissions in Azure AD"
    Write-Output "    Ensure proper Graph API scopes are granted"
    Write-Output "    Validate tenant ID and credentials"
    Write-Output ""
    throw
} finally {
    try {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Write-Log "Graph session disconnected" -Level INFO
    } catch {
        Write-Warning "Graph disconnect failed: $($_.Exception.Message)"
    }
}
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO



