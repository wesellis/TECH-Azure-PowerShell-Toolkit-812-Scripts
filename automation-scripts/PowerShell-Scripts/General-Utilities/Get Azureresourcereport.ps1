#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Get Azureresourcereport

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Get Azureresourcereport

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

if (-not (Get-Module -ListAvailable -Name PSWriteHTML)) {
    Write-WELog " Installing PSWriteHTML module..." " INFO" -ForegroundColor Yellow
    Install-Module -Name PSWriteHTML -Force -Scope CurrentUser
}

Import-Module PSWriteHTML

[CmdletBinding()]
function WE-Get-DetailedResourceReport -ErrorAction Stop {
    $reportData = @{
        Subscriptions = @()
        TotalStats = @{
            SubscriptionCount = 0
            ResourceGroupCount = 0
            ResourceCount = 0
        }
    }
    
    Write-WELog " Gathering detailed statistics across all subscriptions..." " INFO" -ForegroundColor Yellow
    
    # Get all subscriptions
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    $reportData.TotalStats.SubscriptionCount = $subscriptions.Count
    
    foreach ($sub in $subscriptions) {
        Write-WELog " Processing subscription: $($sub.Name)" " INFO" -ForegroundColor Cyan
        Set-AzContext -Subscription $sub.Id | Out-Null
        
        $rgs = Get-AzResourceGroup -ErrorAction Stop
        $resources = Get-AzResource -ErrorAction Stop
        
        $subData = @{
            Name = $sub.Name
            Id = $sub.Id
            TenantId = $sub.TenantId
            ResourceGroups = @()
            ResourceGroupCount = $rgs.Count
            ResourceCount = $resources.Count
        }
        
        foreach ($rg in $rgs) {
            $rgResources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
            $rgData = @{
                Name = $rg.ResourceGroupName
                Location = $rg.Location
                Resources = @()
                ResourceCount = $rgResources.Count
            }
            
            foreach ($resource in $rgResources) {
                $rgData.Resources += @{
                    Name = $resource.Name
                    Type = $resource.Type
                    Location = $resource.Location
                    Tags = ($resource.Tags | ConvertTo-Json)
                    Id = $resource.Id
                }
            }
            
            $subData.ResourceGroups += $rgData
        }
        
        $reportData.Subscriptions += $subData
        $reportData.TotalStats.ResourceGroupCount += $rgs.Count
        $reportData.TotalStats.ResourceCount += $resources.Count
    }
    
    return $reportData
}

[CmdletBinding()]
function WE-Export-ResourceReportToHtml {
    

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

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$true)]
        [object]$WEReportData
    )
    
    $reportPath = " AzureResourceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    
    New-HTML -TitleText 'Azure Resources Report' -FilePath $reportPath {
        New-HTMLTab -Name 'Overview' {
            New-HTMLSection -HeaderText 'Summary Statistics' {
                New-HTMLTable -DataTable @(
                    [PSCustomObject]@{
                        'Metric' = 'Total Subscriptions'
                        'Count' = $WEReportData.TotalStats.SubscriptionCount
                    }
                    [PSCustomObject]@{
                        'Metric' = 'Total Resource Groups'
                        'Count' = $WEReportData.TotalStats.ResourceGroupCount
                    }
                    [PSCustomObject]@{
                        'Metric' = 'Total Resources'
                        'Count' = $WEReportData.TotalStats.ResourceCount
                    }
                ) -HideButtons
            }
        }
        
        foreach ($sub in $WEReportData.Subscriptions) {
            New-HTMLTab -Name $sub.Name {
                New-HTMLSection -HeaderText " Subscription Details" {
                    New-HTMLTable -DataTable @(
                        [PSCustomObject]@{
                            'Property' = 'Subscription Name'
                            'Value' = $sub.Name
                        }
                        [PSCustomObject]@{
                            'Property' = 'Subscription ID'
                            'Value' = $sub.Id
                        }
                        [PSCustomObject]@{
                            'Property' = 'Resource Groups Count'
                            'Value' = $sub.ResourceGroupCount
                        }
                        [PSCustomObject]@{
                            'Property' = 'Total Resources'
                            'Value' = $sub.ResourceCount
                        }
                    ) -HideButtons
                }

                if ($sub.ResourceGroups.Count -gt 0) {
                    New-HTMLSection -HeaderText " Resource Groups" {
                        # Create a single table for all resource groups
                        $rgTable = @()
                        foreach ($rg in $sub.ResourceGroups) {
                            $rgTable = $rgTable + [PSCustomObject]@{
                                'Resource Group Name' = $rg.Name
                                'Location' = $rg.Location
                                'Resource Count' = $rg.ResourceCount
                            }
                        }
                        New-HTMLTable -DataTable $rgTable -HideButtons
                    }

                    # Create a section for resources
                    New-HTMLSection -HeaderText " Resources Details" {
                        $resourcesTable = @()
                        foreach ($rg in $sub.ResourceGroups) {
                            foreach ($resource in $rg.Resources) {
                                $resourcesTable = $resourcesTable + [PSCustomObject]@{
                                    'Resource Group' = $rg.Name
                                    'Resource Name' = $resource.Name
                                    'Type' = $resource.Type
                                    'Location' = $resource.Location
                                }
                            }
                        }
                        if ($resourcesTable.Count -gt 0) {
                            New-HTMLTable -DataTable $resourcesTable -HideButtons
                        }
                    }
                }
            }
        }
    } -Online -ShowHTML

    Write-WELog " Report generated: $reportPath" " INFO" -ForegroundColor Green
    # Open the report in default browser
    Invoke-Item $reportPath
}


try {
    # Check if already connected to Azure
   ;  $context = Get-AzContext -ErrorAction Stop
    if (-not $context) {
        Write-WELog " Please connect to Azure first using Connect-AzAccount" " INFO" -ForegroundColor Yellow
        Connect-AzAccount
    }
    
    # Get detailed report data
   ;  $reportData = Get-DetailedResourceReport -ErrorAction Stop
    
    # Generate HTML report
    Export-ResourceReportToHtml -ReportData $reportData
}
catch {
    Write-WELog " An error occurred: $_" " INFO" -ForegroundColor Red
    Write-WELog " Stack trace: $($_.ScriptStackTrace)" " INFO" -ForegroundColor Red
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
