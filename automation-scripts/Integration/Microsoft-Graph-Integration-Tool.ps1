<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Microsoft Graph Integration Tool
#
param(
    [Parameter(Mandatory)]
    [ValidateSet("GetUsers", "GetGroups", "CreateUser", "GetMailboxes", "GetTeams", "GetSites", "ManagePermissions")]
    [string]$Operation,
    [Parameter()]
    [string]$TenantId,
    [Parameter()]
    [string]$ClientId,
    [Parameter()]
    [string]$ClientSecret,
    [Parameter()]
    [string]$UserPrincipalName,
    [Parameter()]
    [string]$DisplayName,
    [Parameter()]
    [string]$Department,
    [Parameter()]
    [string]$JobTitle,
    [Parameter()]
    [string]$OutputFormat = "Table",
    [Parameter(HelpMessage="Path to export results")]
    [string]$ExportPath,
    [Parameter(HelpMessage="Maximum number of results to return")]
    [ValidateRange(1, 1000)]
    [int]$MaxResults = 100,
    [Parameter(HelpMessage="Include disabled users in results")]
    [switch]$IncludeDisabledUsers,
    [Parameter(HelpMessage="Include detailed output properties")]
    [switch]$DetailedOutput
)
[OutputType([PSObject])]
 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}
function Invoke-GraphOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Operation,
        [Parameter(Mandatory)]
        [string]$OperationName
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
#endregion
#region Main-Execution
try {
    Write-Host "Microsoft Graph Integration Tool" -ForegroundColor White
    Write-Host "================================" -ForegroundColor White
    Write-Host "Operation: $Operation" -ForegroundColor Gray
    Write-Host ""
    # Test Graph connection
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Validating connectivity..." -PercentComplete 10
    # Check if Microsoft.Graph module is available
    if (-not (Get-Module Microsoft.Graph -ListAvailable)) {
        Write-Log "Microsoft.Graph module not found. Please install it first." -Level ERROR
        throw "Required module Microsoft.Graph is not installed. Install with: Install-Module Microsoft.Graph"
    }
    Write-Log "Checking Microsoft Graph connection..." -Level INFO
    # Connect to Microsoft Graph
    if ($ClientId -and $ClientSecret -and $TenantId) {
        Write-Log "Connecting using service principal authentication..." -Level INFO
        $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
        $credential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential($ClientId, $secureSecret)
        Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $credential
    } else {
        Write-Log "Connecting using interactive authentication..." -Level INFO
        Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Sites.Read.All", "TeamMember.Read.All"
    }
    $context = Get-MgContext -ErrorAction Stop
    Write-Log "Connected to Microsoft Graph - Tenant: $($context.TenantId)" -Level SUCCESS
    # Execute operations based on parameter
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
                $deptFilter = "department eq '$Department'"
                $filter = if ($filter) { "$filter and $deptFilter" } else { $deptFilter }
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
            $passwordProfile = @{
                ForceChangePasswordNextSignIn = $true
                Password = "TempPassword123!"
            }
            $userParams = @{
                DisplayName = $DisplayName
                UserPrincipalName = $UserPrincipalName
                AccountEnabled = $true
                PasswordProfile = $passwordProfile
                UsageLocation = "US"
            }
            if ($Department) { $userParams.Department = $Department }
            if ($JobTitle) { $userParams.JobTitle = $JobTitle }
            $newUser = Invoke-GraphOperation -Operation {
                New-MgUser -ErrorAction Stop @userParams
            } -OperationName "Create User"
            $results = @([PSCustomObject]@{
                DisplayName = $newUser.DisplayName
                UserPrincipalName = $newUser.UserPrincipalName
                UserId = $newUser.Id
                Status = "Created Successfully"
                TempPassword = $passwordProfile.Password
            })
            Write-Log "User created successfully: $UserPrincipalName" -Level SUCCESS
        }
    }
    # Format and display results
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Processing results..." -PercentComplete 60
    if ($results.Count -gt 0) {
        Write-Host ""
        Write-Host " $Operation Results ($($results.Count) items)"
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
    # Export results if requested
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Exporting results..." -PercentComplete 75
    if ($ExportPath -and $results.Count -gt 0) {
        $exportFile = $ExportPath
        if (-not $exportFile.EndsWith('.csv')) {
            $exportFile += '.csv'
        }
        $results | Export-Csv -Path $exportFile -NoTypeInformation -Force
        Write-Log "Results exported to: $exportFile" -Level SUCCESS
    }
    # Generate summary statistics
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Generating statistics..." -PercentComplete 85
    $stats = @{
        TotalRecords = $results.Count
        Operation = $Operation
        ExecutedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TenantId = $context.TenantId
    }
    if ($Operation -eq "GetUsers" -and $results.Count -gt 0) {
        $enabledUsers = ($results | Where-Object { $_.Enabled }).Count
        $disabledUsers = $results.Count - $enabledUsers
        $stats.EnabledUsers = $enabledUsers
        $stats.DisabledUsers = $disabledUsers
        $stats.TopDepartments = ($results | Group-Object Department | Sort-Object Count -Descending | Select-Object -First 5).Name -join ", "
    }
    # Final validation and cleanup
    Write-Progress -Activity "Microsoft Graph Integration" -Status "Finalizing..." -PercentComplete 95
    # Success summary
    Write-Host ""
    Write-Host "                              MICROSOFT GRAPH OPERATION SUCCESSFUL"
    Write-Host ""
    Write-Host "Operation Summary:"
    Write-Host "    Operation: $Operation"
    Write-Host "    Records Retrieved: $($stats.TotalRecords)"
    Write-Host "    Tenant: $($stats.TenantId)"
    Write-Host "    Executed: $($stats.ExecutedAt)"
    if ($stats.ContainsKey("EnabledUsers")) {
        Write-Host ""
        Write-Host "    Enabled Users: $($stats.EnabledUsers)"
        Write-Host "    Disabled Users: $($stats.DisabledUsers)"
        if ($stats.TopDepartments) {
            Write-Host "    Top Departments: $($stats.TopDepartments)"
        }
    }
    if ($ExportPath) {
        Write-Host ""
        Write-Host "[FOLDER] Export Information:"
        Write-Host "    Export Path: $exportFile"
        Write-Host "    Format: CSV"
    }
    Write-Host ""
    Write-Host "    Review the results for compliance and security"
    Write-Host "    Set up automated reporting for regular monitoring"
    Write-Host "    Consider implementing governance policies"
    Write-Host ""
    Write-Log "Microsoft Graph operation '$Operation' completed successfully!" -Level SUCCESS
} catch {
    Write-Log "Microsoft Graph operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    Write-Host ""
    Write-Host "Troubleshooting Tips:"
    Write-Host "    Verify Microsoft.Graph PowerShell module is installed"
    Write-Host "    Check application permissions in Azure AD"
    Write-Host "    Ensure proper Graph API scopes are granted"
    Write-Host "    Validate tenant ID and credentials"
    Write-Host ""
    throw
} finally {
    # Disconnect from Microsoft Graph
    try {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Write-Log "Graph session disconnected" -Level INFO
    } catch {
        Write-Warning "Graph disconnect failed: $($_.Exception.Message)"
    }
}
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO

