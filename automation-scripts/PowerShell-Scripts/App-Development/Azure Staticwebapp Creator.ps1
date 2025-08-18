<#
.SYNOPSIS
    Azure Staticwebapp Creator

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
    We Enhanced Azure Staticwebapp Creator

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
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
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
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERepositoryUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$WEBranch = " main" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WEAppLocation = " /" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputLocation = " dist"
)

Write-WELog " Creating Static Web App: $WEName" " INFO"

; 
$WEStaticWebApp = New-AzStaticWebApp -ErrorAction Stop `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEName `
    -Location $WELocation

Write-WELog " ✅ Static Web App created successfully:" " INFO"
Write-WELog "  Name: $($WEStaticWebApp.Name)" " INFO"
Write-WELog "  Location: $($WEStaticWebApp.Location)" " INFO"
Write-WELog "  Default Hostname: $($WEStaticWebApp.DefaultHostname)" " INFO"
Write-WELog "  Resource ID: $($WEStaticWebApp.Id)" " INFO"

if ($WERepositoryUrl) {
    Write-WELog "  Repository: $WERepositoryUrl" " INFO"
    Write-WELog "  Branch: $WEBranch" " INFO"
    Write-WELog "  App Location: $WEAppLocation" " INFO"
    Write-WELog "  Output Location: $WEOutputLocation" " INFO"
}

Write-WELog " `nStatic Web App Features:" " INFO"
Write-WELog " • Global CDN distribution" " INFO"
Write-WELog " • Automatic HTTPS" " INFO"
Write-WELog " • Custom domains" " INFO"
Write-WELog " • Staging environments" " INFO"
Write-WELog " • GitHub/Azure DevOps integration" " INFO"
Write-WELog " • Built-in authentication" " INFO"
Write-WELog " • Serverless API support" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Connect to Git repository" " INFO"
Write-WELog " 2. Configure build and deployment" " INFO"
Write-WELog " 3. Set up custom domain" " INFO"
Write-WELog " 4. Configure authentication providers" " INFO"
Write-WELog " 5. Add API functions if needed" " INFO"

Write-WELog " `nAccess your app at: https://$($WEStaticWebApp.DefaultHostname)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
