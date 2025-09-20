#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Get Azureresourcereport

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
if (-not (Get-Module -ListAvailable -Name PSWriteHTML)) {
    Write-Host "Installing PSWriteHTML module..." -ForegroundColor Yellow
    Install-Module -Name PSWriteHTML -Force -Scope CurrentUser
}
Import-Module PSWriteHTML
[CmdletBinding()]
[OutputType([PSObject])]
 -ErrorAction Stop {
    $reportData = @{
        Subscriptions = @()
        TotalStats = @{
            SubscriptionCount = 0
            ResourceGroupCount = 0
            ResourceCount = 0
        }
    }
    Write-Host "Gathering  statistics across all subscriptions..." -ForegroundColor Yellow
    # Get all subscriptions
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    $reportData.TotalStats.SubscriptionCount = $subscriptions.Count
    foreach ($sub in $subscriptions) {
        Write-Host "Processing subscription: $($sub.Name)" -ForegroundColor Cyan
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
function Export-ResourceReportToHtml {
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
        [Parameter(Mandatory)]
        [object]$ReportData
    )
    $reportPath = "AzureResourceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    New-HTML -TitleText 'Azure Resources Report' -FilePath $reportPath {
        New-HTMLTab -Name 'Overview' {
            New-HTMLSection -HeaderText 'Summary Statistics' {
                New-HTMLTable -DataTable @(
                    [PSCustomObject]@{
                        'Metric' = 'Total Subscriptions'
                        'Count' = $ReportData.TotalStats.SubscriptionCount
                    }
                    [PSCustomObject]@{
                        'Metric' = 'Total Resource Groups'
                        'Count' = $ReportData.TotalStats.ResourceGroupCount
                    }
                    [PSCustomObject]@{
                        'Metric' = 'Total Resources'
                        'Count' = $ReportData.TotalStats.ResourceCount
                    }
                ) -HideButtons
            }
        }
        foreach ($sub in $ReportData.Subscriptions) {
            New-HTMLTab -Name $sub.Name {
                New-HTMLSection -HeaderText "Subscription Details" {
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
                    New-HTMLSection -HeaderText "Resource Groups" {
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
                    New-HTMLSection -HeaderText "Resources Details" {
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
    Write-Host "Report generated: $reportPath" -ForegroundColor Green
    # Open the report in default browser
    Invoke-Item $reportPath
}
try {
    # Check if already connected to Azure
$context = Get-AzContext -ErrorAction Stop
    if (-not $context) {
        Write-Host "Please connect to Azure first using Connect-AzAccount" -ForegroundColor Yellow
        Connect-AzAccount
    }
    # Get  report data
$reportData = Get-ResourceReport -ErrorAction Stop
    # Generate HTML report
    Export-ResourceReportToHtml -ReportData $reportData
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}


