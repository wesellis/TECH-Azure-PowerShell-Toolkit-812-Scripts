#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Get Azureresourcereport - Generate Azure Resource Reports

.DESCRIPTION
    Azure automation script that generates comprehensive HTML reports of Azure resources across all subscriptions.
    This script gathers statistics across all subscriptions and generates detailed HTML reports showing resource groups and resources.

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.EXAMPLE
    PS C:\> .\Get_Azureresourcereport.ps1
    Generates an HTML report of all Azure resources

.INPUTS
    None

.OUTPUTS
    HTML report file with Azure resource information

.NOTES
    Requires PSWriteHTML module for HTML report generation
    Must be connected to Azure with appropriate permissions
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# Install and import PSWriteHTML module if not available
if (-not (Get-Module -ListAvailable -Name PSWriteHTML)) {
    Write-Output "Installing PSWriteHTML module..."
    Install-Module -Name PSWriteHTML -Force -Scope CurrentUser
}
Import-Module PSWriteHTML

function Write-EnhancedOutput {
    <#
    .SYNOPSIS
        Enhanced output function with color coding
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"; "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

function Get-ResourceReport {
    <#
    .SYNOPSIS
        Gathers Azure resource statistics across all subscriptions
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param()

    $ReportData = @{
        Subscriptions = @()
        TotalStats = @{
            SubscriptionCount = 0
            ResourceGroupCount = 0
            ResourceCount = 0
        }
    }

    Write-EnhancedOutput "Gathering statistics across all subscriptions..." -Level "INFO"
    $subscriptions = Get-AzSubscription -ErrorAction Stop
    $ReportData.TotalStats.SubscriptionCount = $subscriptions.Count

    foreach ($sub in $subscriptions) {
        Write-EnhancedOutput "Processing subscription: $($sub.Name)" -Level "INFO"
        Set-AzContext -Subscription $sub.Id | Out-Null

        $rgs = Get-AzResourceGroup -ErrorAction Stop
        $resources = Get-AzResource -ErrorAction Stop

        $SubData = @{
            Name = $sub.Name
            Id = $sub.Id
            TenantId = $sub.TenantId
            ResourceGroups = @()
            ResourceGroupCount = $rgs.Count
            ResourceCount = $resources.Count
        }

        foreach ($rg in $rgs) {
            $RgResources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName
            $RgData = @{
                Name = $rg.ResourceGroupName
                Location = $rg.Location
                Resources = @()
                ResourceCount = $RgResources.Count
            }

            foreach ($resource in $RgResources) {
                $RgData.Resources += @{
                    Name = $resource.Name
                    Type = $resource.Type
                    Location = $resource.Location
                    Tags = ($resource.Tags | ConvertTo-Json)
                    Id = $resource.Id
                }
            }

            $SubData.ResourceGroups += $RgData
        }

        $ReportData.Subscriptions += $SubData
        $ReportData.TotalStats.ResourceGroupCount += $rgs.Count
        $ReportData.TotalStats.ResourceCount += $resources.Count
    }

    return $ReportData
}

function Export-ResourceReportToHtml {
    <#
    .SYNOPSIS
        Exports resource report data to HTML format
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$ReportData
    )

    $ReportPath = "AzureResourceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

    New-HTML -TitleText 'Azure Resources Report' -FilePath $ReportPath {
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
                        $RgTable = @()
                        foreach ($rg in $sub.ResourceGroups) {
                            $RgTable += [PSCustomObject]@{
                                'Resource Group Name' = $rg.Name
                                'Location' = $rg.Location
                                'Resource Count' = $rg.ResourceCount
                            }
                        }
                        New-HTMLTable -DataTable $RgTable -HideButtons
                    }

                    New-HTMLSection -HeaderText "Resources Details" {
                        $ResourcesTable = @()
                        foreach ($rg in $sub.ResourceGroups) {
                            foreach ($resource in $rg.Resources) {
                                $ResourcesTable += [PSCustomObject]@{
                                    'Resource Group' = $rg.Name
                                    'Resource Name' = $resource.Name
                                    'Type' = $resource.Type
                                    'Location' = $resource.Location
                                }
                            }
                        }
                        if ($ResourcesTable.Count -gt 0) {
                            New-HTMLTable -DataTable $ResourcesTable -HideButtons
                        }
                    }
                }
            }
        }
    } -Online -ShowHTML

    Write-EnhancedOutput "Report generated: $ReportPath" -Level "SUCCESS"
    Invoke-Item $ReportPath
}

# Main execution
try {
    $context = Get-AzContext -ErrorAction Stop
    if (-not $context) {
        Write-EnhancedOutput "Please connect to Azure first using Connect-AzAccount" -Level "WARN"
        Connect-AzAccount
    }

    $ReportData = Get-ResourceReport -ErrorAction Stop
    Export-ResourceReportToHtml -ReportData $ReportData
}
catch {
    Write-EnhancedOutput "An error occurred: $_" -Level "ERROR"
    Write-EnhancedOutput "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"
    throw
}