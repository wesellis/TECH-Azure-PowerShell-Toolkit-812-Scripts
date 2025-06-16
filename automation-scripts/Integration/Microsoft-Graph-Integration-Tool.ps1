# Microsoft Graph Integration Tool
# Professional Azure automation script for Microsoft 365 connectivity
# Author: Wesley Ellis | wes@wesellis.com
# Version: 2.0 | Enhanced for enterprise M365 integration

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("GetUsers", "GetGroups", "CreateUser", "GetMailboxes", "GetTeams", "GetSites", "ManagePermissions")]
    [string]$Operation,
    
    [Parameter(Mandatory=$false)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientSecret,
    
    [Parameter(Mandatory=$false)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [string]$DisplayName,
    
    [Parameter(Mandatory=$false)]
    [string]$Department,
    
    [Parameter(Mandatory=$false)]
    [string]$JobTitle,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFormat = "Table",
    
    [Parameter(Mandatory=$false)]
    [string]$ExportPath,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxResults = 100,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeDisabledUsers,
    
    [Parameter(Mandatory=$false)]
    [switch]$DetailedOutput
)

# Import common functions
Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

# Professional banner
Show-Banner -ScriptName "Microsoft Graph Integration Tool" -Version "2.0" -Description "Enterprise M365 and Azure AD automation via Graph API"

try {
    # Test Graph connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 6 -StepName "Graph Connection" -Status "Validating Microsoft Graph connectivity"
    
    # Check if Microsoft.Graph module is available
    if (-not (Get-Module Microsoft.Graph -ListAvailable)) {
        Write-Log "Installing Microsoft.Graph module..." -Level INFO
        Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser
    }
    
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Users
    Import-Module Microsoft.Graph.Groups
    Import-Module Microsoft.Graph.Sites
    Import-Module Microsoft.Graph.Teams

    # Connect to Microsoft Graph
    if ($ClientId -and $ClientSecret -and $TenantId) {
        Write-Log "Connecting using service principal authentication..." -Level INFO
        $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($ClientId, $secureSecret)
        Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $credential
    } else {
        Write-Log "Connecting using interactive authentication..." -Level INFO
        Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Sites.Read.All", "TeamMember.Read.All"
    }
    
    $context = Get-MgContext
    Write-Log "✓ Connected to Microsoft Graph - Tenant: $($context.TenantId)" -Level SUCCESS

    # Execute operations based on parameter
    Write-ProgressStep -StepNumber 2 -TotalSteps 6 -StepName "Operation Execution" -Status "Executing $Operation"
    
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
            
            $users = Invoke-AzureOperation -Operation {
                $params = @{
                    Top = $MaxResults
                }
                if ($filter) { $params.Filter = $filter }
                if ($DetailedOutput) {
                    $params.Property = @("id", "displayName", "userPrincipalName", "mail", "department", "jobTitle", "accountEnabled", "createdDateTime", "lastSignInDateTime")
                }
                
                Get-MgUser @params
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
            
            Write-Log "✓ Retrieved $($results.Count) users" -Level SUCCESS
        }
        
        "GetGroups" {
            Write-Log "Retrieving group information..." -Level INFO
            
            $groups = Invoke-AzureOperation -Operation {
                $params = @{
                    Top = $MaxResults
                }
                if ($DetailedOutput) {
                    $params.Property = @("id", "displayName", "description", "mailEnabled", "securityEnabled", "createdDateTime", "membershipRule")
                }
                
                Get-MgGroup @params
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
            
            Write-Log "✓ Retrieved $($results.Count) groups" -Level SUCCESS
        }
        
        "GetTeams" {
            Write-Log "Retrieving Teams information..." -Level INFO
            
            $teams = Invoke-AzureOperation -Operation {
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
            
            Write-Log "✓ Retrieved $($results.Count) Teams" -Level SUCCESS
        }
        
        "GetSites" {
            Write-Log "Retrieving SharePoint sites..." -Level INFO
            
            $sites = Invoke-AzureOperation -Operation {
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
            
            Write-Log "✓ Retrieved $($results.Count) SharePoint sites" -Level SUCCESS
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
            
            $newUser = Invoke-AzureOperation -Operation {
                New-MgUser @userParams
            } -OperationName "Create User"
            
            $results = @([PSCustomObject]@{
                DisplayName = $newUser.DisplayName
                UserPrincipalName = $newUser.UserPrincipalName
                UserId = $newUser.Id
                Status = "Created Successfully"
                TempPassword = $passwordProfile.Password
            })
            
            Write-Log "✓ User created successfully: $UserPrincipalName" -Level SUCCESS
        }
    }

    # Format and display results
    Write-ProgressStep -StepNumber 3 -TotalSteps 6 -StepName "Data Processing" -Status "Formatting results"
    
    if ($results.Count -gt 0) {
        Write-Host ""
        Write-Host "📊 $Operation Results ($($results.Count) items)" -ForegroundColor Cyan
        Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        
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
    Write-ProgressStep -StepNumber 4 -TotalSteps 6 -StepName "Data Export" -Status "Exporting results"
    
    if ($ExportPath -and $results.Count -gt 0) {
        $exportFile = $ExportPath
        if (-not $exportFile.EndsWith('.csv')) {
            $exportFile += '.csv'
        }
        
        $results | Export-Csv -Path $exportFile -NoTypeInformation -Force
        Write-Log "✓ Results exported to: $exportFile" -Level SUCCESS
    }

    # Generate summary statistics
    Write-ProgressStep -StepNumber 5 -TotalSteps 6 -StepName "Analytics" -Status "Generating summary statistics"
    
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
    Write-ProgressStep -StepNumber 6 -TotalSteps 6 -StepName "Cleanup" -Status "Finalizing operation"
    
    # Success summary
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                              MICROSOFT GRAPH OPERATION SUCCESSFUL" -ForegroundColor Green  
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "📈 Operation Summary:" -ForegroundColor Cyan
    Write-Host "   • Operation: $Operation" -ForegroundColor White
    Write-Host "   • Records Retrieved: $($stats.TotalRecords)" -ForegroundColor White
    Write-Host "   • Tenant: $($stats.TenantId)" -ForegroundColor White
    Write-Host "   • Executed: $($stats.ExecutedAt)" -ForegroundColor White
    
    if ($stats.ContainsKey("EnabledUsers")) {
        Write-Host ""
        Write-Host "👥 User Statistics:" -ForegroundColor Cyan
        Write-Host "   • Enabled Users: $($stats.EnabledUsers)" -ForegroundColor Green
        Write-Host "   • Disabled Users: $($stats.DisabledUsers)" -ForegroundColor Yellow
        if ($stats.TopDepartments) {
            Write-Host "   • Top Departments: $($stats.TopDepartments)" -ForegroundColor White
        }
    }
    
    if ($ExportPath) {
        Write-Host ""
        Write-Host "📁 Export Information:" -ForegroundColor Cyan
        Write-Host "   • Export Path: $exportFile" -ForegroundColor White
        Write-Host "   • Format: CSV" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "💡 Next Steps:" -ForegroundColor Cyan
    Write-Host "   • Review the results for compliance and security" -ForegroundColor White
    Write-Host "   • Set up automated reporting for regular monitoring" -ForegroundColor White
    Write-Host "   • Consider implementing governance policies" -ForegroundColor White
    Write-Host ""

    Write-Log "✅ Microsoft Graph operation '$Operation' completed successfully!" -Level SUCCESS

} catch {
    Write-Log "❌ Microsoft Graph operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Host ""
    Write-Host "🔧 Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "   • Verify Microsoft.Graph PowerShell module is installed" -ForegroundColor White
    Write-Host "   • Check application permissions in Azure AD" -ForegroundColor White
    Write-Host "   • Ensure proper Graph API scopes are granted" -ForegroundColor White
    Write-Host "   • Validate tenant ID and credentials" -ForegroundColor White
    Write-Host ""
    
    exit 1
} finally {
    # Disconnect from Microsoft Graph
    try {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Write-Log "Graph session disconnected" -Level INFO
    } catch {
        Write-Warning "Graph disconnect failed: $($_.Exception.Message)"
    }
}

Write-Progress -Activity "Microsoft Graph Integration" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
