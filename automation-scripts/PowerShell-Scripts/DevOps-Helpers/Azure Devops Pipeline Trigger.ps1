<#
.SYNOPSIS
    Azure Devops Pipeline Trigger

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
    We Enhanced Azure Devops Pipeline Trigger

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

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOrganization,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEProject,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPipelineId,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPersonalAccessToken,
    
    [Parameter(Mandatory=$false)]
    [string]$WESourceBranch = " main"
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1" ) -Force
Show-Banner -ScriptName " Azure DevOps Pipeline Trigger" -Version " 1.0" -Description " Trigger DevOps pipelines remotely"

try {
    $base64Token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(" :$WEPersonalAccessToken" ))
    $headers = @{ Authorization = " Basic $base64Token" }
    
    $uri = " https://dev.azure.com/$WEOrganization/$WEProject/_apis/pipelines/$WEPipelineId/runs?api-version=6.0"
    
   ;  $body = @{
        stagesToSkip = @()
        resources = @{
            repositories = @{
                self = @{
                    refName = " refs/heads/$WESourceBranch"
                }
            }
        }
    } | ConvertTo-Json -Depth 3

   ;  $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType " application/json"
    
    Write-WELog " ✅ Pipeline triggered successfully!" " INFO" -ForegroundColor Green
    Write-WELog " Run ID: $($response.id)" " INFO" -ForegroundColor Cyan
    Write-WELog " URL: $($response._links.web.href)" " INFO" -ForegroundColor Yellow

} catch {
    Write-Log " ❌ Pipeline trigger failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================