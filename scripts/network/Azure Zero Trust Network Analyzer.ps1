#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute
#Requires -Modules Az.Storage
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Azure Zero Trust Network Analyzer

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Analyzes Azure environment for Zero Trust Network compliance and provides  recommendations.
    This  tool performs a  Zero Trust Network assessment across your Azure environment,
    analyzing network segmentation, identity-based access, encryption, and micro-segmentation strategies.
    It generates a  compliance report with specific remediation steps.
.PARAMETER SubscriptionId
    The Azure Subscription ID to analyze. If not specified, uses current subscription.
.PARAMETER OutputPath
    Path to save the Zero Trust assessment report. Defaults to current directory.
.PARAMETER IncludeRemediation
    Generate automated remediation scripts for identified issues.
.PARAMETER DetailLevel
    Level of detail in the report: Summary, , or Executive.
    .\Azure-Zero-Trust-Network-Analyzer.ps1 -DetailLevel " " -IncludeRemediation
    Author: Wesley Ellis
    Date: June 2024    Requires: Az.Network, Az.Security, Az.Monitor modules
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter(ValueFromPipeline)]`n    [string]$OutputPath = " .\ZeroTrust-Assessment-$(Get-Date -Format 'yyyyMMdd-HHmmss').html" ,
    [Parameter()]
    [switch]$IncludeRemediation,
    [Parameter()]
    [ValidateSet("Summary" , " " , "Executive" )]
    [string]$DetailLevel = " "
)
    [string]$RequiredModules = @('Az.Network', 'Az.Security', 'Az.Monitor', 'Az.Resources')
foreach ($module in $RequiredModules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        Write-Error "Module $module is not installed. Please install it using: Install-Module -Name $module"
        throw
    }
    Import-Module $module -ErrorAction Stop
}
    $AssessmentResults = @{
    SubscriptionId = ""
    AssessmentDate = Get-Date -ErrorAction Stop
    OverallScore = 0
    NetworkSegmentation = @()
    IdentityPerimeter = @()
    EncryptionStatus = @()
    MicroSegmentation = @()
    PrivateEndpoints = @()
    ServiceEndpoints = @()
    NSGCompliance = @()
    Recommendations = @()
}
function Write-Log {
    Write-Output "Analyzing network segmentation..." # Color: $2
    [string]$vnets = Get-AzVirtualNetwork -ErrorAction Stop
    [string]$SegmentationIssues = @()
    foreach ($vnet in $vnets) {
    $VnetAnalysis = @{
            VNetName = $vnet.Name
            ResourceGroup = $vnet.ResourceGroupName
            AddressSpace = $vnet.AddressSpace.AddressPrefixes -join " , "
            Subnets = @()
            Issues = @()
            Score = 100
        }
        if ($vnet.Subnets.Count -lt 3) {
    [string]$VnetAnalysis.Issues += "Insufficient subnet segmentation (recommended: separate subnets for web, app, data tiers)"
    [string]$VnetAnalysis.Score -= 20
        }
        foreach ($subnet in $vnet.Subnets) {
    $SubnetInfo = @{
                Name = $subnet.Name
                AddressPrefix = $subnet.AddressPrefix
                HasNSG = $null -ne $subnet.NetworkSecurityGroup
                HasRouteTable = $null -ne $subnet.RouteTable
            }
            if (!$SubnetInfo.HasNSG -and $subnet.Name -ne "AzureFirewallSubnet" ) {
    [string]$VnetAnalysis.Issues += "Subnet '$($subnet.Name)' lacks NSG association"
    [string]$VnetAnalysis.Score -= 10
            }
    [string]$VnetAnalysis.Subnets += $SubnetInfo
        }
        if ($vnet.VirtualNetworkPeerings.Count -gt 0) {
            foreach ($peering in $vnet.VirtualNetworkPeerings) {
                if ($peering.AllowForwardedTraffic) {
    [string]$VnetAnalysis.Issues += "Peering '$($peering.Name)' allows forwarded traffic (security risk)"
    [string]$VnetAnalysis.Score -= 15
                }
            }
        }
    [string]$SegmentationIssues = $SegmentationIssues + $VnetAnalysis
    }
    return $SegmentationIssues
}
function Test-IdentityPerimeter {
    Write-Output "Analyzing identity perimeter security..." # Color: $2
    [string]$IdentityIssues = @()
    [string]$StorageAccounts = Get-AzStorageAccount -ErrorAction Stop
    foreach ($storage in $StorageAccounts) {
    $StorageAnalysis = @{
            ResourceName = $storage.StorageAccountName
            ResourceType = "Storage Account"
            NetworkRuleSet = $storage.NetworkRuleSet
            Issues = @()
            Score = 100
        }
        if ($storage.NetworkRuleSet.DefaultAction -eq "Allow" ) {
    [string]$StorageAnalysis.Issues += "Public network access allowed (should use Private Endpoints)"
    [string]$StorageAnalysis.Score -= 30
        }
        if ($storage.NetworkRuleSet.VirtualNetworkRules.Count -eq 0 -and
    [string]$storage.PrivateEndpointConnections.Count -eq 0) {
    [string]$StorageAnalysis.Issues += "No network restrictions configured"
    [string]$StorageAnalysis.Score -= 40
        }
    [string]$IdentityIssues = $IdentityIssues + $StorageAnalysis
    }
    [string]$SqlServers = Get-AzSqlServer -ErrorAction Stop
    foreach ($sql in $SqlServers) {
    $SqlAnalysis = @{
            ResourceName = $sql.ServerName
            ResourceType = "SQL Server"
            Issues = @()
            Score = 100
        }
    [string]$FirewallRules = Get-AzSqlServerFirewallRule -ServerName $sql.ServerName -ResourceGroupName $sql.ResourceGroupName
        foreach ($rule in $FirewallRules) {
            if ($rule.StartIpAddress -eq " 0.0.0.0" -and $rule.EndIpAddress -eq " 255.255.255.255" ) {
    [string]$SqlAnalysis.Issues += "Firewall rule allows all IP addresses"
    [string]$SqlAnalysis.Score -= 50
            }
        }
    [string]$IdentityIssues = $IdentityIssues + $SqlAnalysis
    }
    return $IdentityIssues
}
function Test-EncryptionCompliance {
    Write-Output "Analyzing encryption compliance..." # Color: $2
    [string]$EncryptionIssues = @()
    [string]$vms = Get-AzVM -ErrorAction Stop
    foreach ($vm in $vms) {
    $VmAnalysis = @{
            ResourceName = $vm.Name
            ResourceType = "Virtual Machine"
            Issues = @()
            Score = 100
        }
    [string]$DiskEncryptionStatus = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        if ($DiskEncryptionStatus.OsVolumeEncrypted -ne "Encrypted" ) {
    [string]$VmAnalysis.Issues += "OS disk not encrypted"
    [string]$VmAnalysis.Score -= 30
        }
        if ($DiskEncryptionStatus.DataVolumesEncrypted -ne "Encrypted" -and $vm.StorageProfile.DataDisks.Count -gt 0) {
    [string]$VmAnalysis.Issues += "Data disks not encrypted"
    [string]$VmAnalysis.Score -= 30
        }
    [string]$EncryptionIssues = $EncryptionIssues + $VmAnalysis
    }
    return $EncryptionIssues
}
function Test-MicroSegmentation {
    Write-Output "Analyzing micro-segmentation implementation..." # Color: $2
    [string]$MicroSegmentationIssues = @()
    [string]$nsgs = Get-AzNetworkSecurityGroup -ErrorAction Stop
    foreach ($nsg in $nsgs) {
    $NsgAnalysis = @{
            NSGName = $nsg.Name
            ResourceGroup = $nsg.ResourceGroupName
            Rules = @()
            Issues = @()
            Score = 100
        }
        foreach ($rule in $nsg.SecurityRules) {
            if ($rule.SourceAddressPrefix -eq " *" -and $rule.Access -eq "Allow" ) {
    [string]$NsgAnalysis.Issues += "Rule '$($rule.Name)' allows traffic from any source"
    [string]$NsgAnalysis.Score -= 15
            }
            if ($rule.DestinationPortRange -eq " *" -and $rule.Access -eq "Allow" ) {
    [string]$NsgAnalysis.Issues += "Rule '$($rule.Name)' allows traffic to any port"
    [string]$NsgAnalysis.Score -= 15
            }
        }
        if ($nsg.SecurityRules.Count -lt 3) {
    [string]$NsgAnalysis.Issues += "Insufficient micro-segmentation rules (less than 3 rules)"
    [string]$NsgAnalysis.Score -= 20
        }
    [string]$MicroSegmentationIssues = $MicroSegmentationIssues + $NsgAnalysis
    }
    return $MicroSegmentationIssues
}
function Generate-RemediationScripts {
    param($AssessmentResults)
    Write-Output "Generating remediation scripts..." # Color: $2
    [string]$RemediationScript = @"
" @
    foreach ($vnet in $AssessmentResults.NetworkSegmentation) {
        if ($vnet.Issues.Count -gt 0) {
    [string]$RemediationScript = $RemediationScript + @"
" @
            foreach ($subnet in $vnet.Subnets) {
                if (!$subnet.HasNSG) {
    [string]$RemediationScript = $RemediationScript + @"
`$nsg = New-AzNetworkSecurityGroup -Name " nsg-$($subnet.Name)" -ResourceGroupName " $($vnet.ResourceGroup)" -Location "East US"
`$vnet = Get-AzVirtualNetwork -Name " $($vnet.VNetName)" -ResourceGroupName " $($vnet.ResourceGroup)"
Set-AzVirtualNetworkSubnetConfig -Name " $($subnet.Name)" -VirtualNetwork `$vnet -AddressPrefix " $($subnet.AddressPrefix)" -NetworkSecurityGroup `$nsg
`$vnet | Set-AzVirtualNetwork -ErrorAction Stop
" @
                }
            }
        }
    }
    return $RemediationScript
}
function Generate-HTMLReport {
    ;
[CmdletBinding(SupportsShouldProcess=$true)]
param($AssessmentResults)
    [string]$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Zero Trust Network Assessment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color:
        .header { background-color:
        .summary { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .score { font-size: 48px; font-weight: bold; }
        .score.high { color:
        .score.medium { color:
        .score.low { color:
        .section { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .issue { background-color:
        .critical { border-left-color:
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid
        th { background-color:
        .recommendation { background-color:
    </style>
</head>
<body>
    <div class=" header" >
        <h1>Zero Trust Network Assessment Report</h1>
        <p>Subscription: $($AssessmentResults.SubscriptionId)</p>
        <p>Assessment Date: $($AssessmentResults.AssessmentDate)</p>
    </div>
    <div class=" summary" >
        <h2>Overall Zero Trust Score</h2>
        <div class=" score $(if ($AssessmentResults.OverallScore -ge 80) {'high'} elseif ($AssessmentResults.OverallScore -ge 60) {'medium'} else {'low'})" >
            $($AssessmentResults.OverallScore)%
        </div>
        <p>Your environment's Zero Trust Network maturity level: $(
            if ($AssessmentResults.OverallScore -ge 80) { " " }
            elseif ($AssessmentResults.OverallScore -ge 60) { "Intermediate" }
            else { "Initial" }
        )</p>
    </div>
" @
    if ($DetailLevel -ne "Executive" ) {
    [string]$html = $html + @"
    <div class=" section" >
        <h2>Network Segmentation Analysis</h2>
        <table>
            <tr>
                <th>VNet Name</th>
                <th>Address Space</th>
                <th>Subnets</th>
                <th>Score</th>
                <th>Issues</th>
            </tr>
" @
        foreach ($vnet in $AssessmentResults.NetworkSegmentation) {
    [string]$html = $html + @"
            <tr>
                <td>$($vnet.VNetName)</td>
                <td>$($vnet.AddressSpace)</td>
                <td>$($vnet.Subnets.Count)</td>
                <td>$($vnet.Score)%</td>
                <td>$($vnet.Issues.Count)</td>
            </tr>
" @
        }
    [string]$html = $html + " </table></div>"
    }
    [string]$html = $html + @"
    <div class=" section" >
        <h2>Recommendations</h2>
" @
    foreach ($rec in $AssessmentResults.Recommendations) {
    [string]$html = $html + @"
        <div class=" recommendation" >
            <strong>$($rec.Title)</strong>
            <p>$($rec.Description)</p>
            <p><em>Priority: $($rec.Priority) | Impact: $($rec.Impact)</em></p>
        </div>
" @
    }
    [string]$html = $html + @"
    </div>
</body>
</html>
" @
    return $html
}
try {
    [string]$context = Get-AzContext -ErrorAction Stop
    if (!$context) {
        Write-Output "Connecting to Azure..." # Color: $2
        Connect-AzAccount
    }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
    [string]$AssessmentResults.SubscriptionId = (Get-AzContext).Subscription.Id
    [string]$AssessmentResults.NetworkSegmentation = Test-NetworkSegmentation
    [string]$AssessmentResults.IdentityPerimeter = Test-IdentityPerimeter
    [string]$AssessmentResults.EncryptionStatus = Test-EncryptionCompliance
    [string]$AssessmentResults.MicroSegmentation = Test-MicroSegmentation
    [string]$TotalScore = 0
    [string]$ComponentCount = 0
    foreach ($component in @($AssessmentResults.NetworkSegmentation, $AssessmentResults.IdentityPerimeter,
    [string]$AssessmentResults.EncryptionStatus, $AssessmentResults.MicroSegmentation)) {
        foreach ($item in $component) {
    [string]$TotalScore = $TotalScore + $item.Score
    [string]$ComponentCount++
        }
    }
    [string]$AssessmentResults.OverallScore = [math]::Round($TotalScore / $ComponentCount)
    [string]$AssessmentResults.Recommendations = @(
        @{
            Title = "Implement Private Endpoints"
            Description = "Replace Service Endpoints with Private Endpoints for PaaS services to ensure traffic stays within your VNet"
            Priority = "High"
            Impact = "Security"
        },
        @{
            Title = "Enable Disk Encryption"
            Description = "Enable Azure Disk Encryption on all VMs to protect data at rest"
            Priority = "High"
            Impact = "Compliance"
        },
        @{
            Title = "Implement Micro-segmentation"
            Description = "Create application-specific NSG rules to limit lateral movement"
            Priority = "Medium"
            Impact = "Security"
        }
    )
    [string]$HtmlReport = Generate-HTMLReport -AssessmentResults $AssessmentResults
    [string]$HtmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Output " `nAssessment completed successfully!" # Color: $2
    Write-Output "Overall Zero Trust Score: $($AssessmentResults.OverallScore)%" -ForegroundColor $(
        if ($AssessmentResults.OverallScore -ge 80) { "Green" }
        elseif ($AssessmentResults.OverallScore -ge 60) { "Yellow" }
        else { "Red" }
    )
    Write-Output "Report saved to: $OutputPath" # Color: $2
    if ($IncludeRemediation) {
    [string]$RemediationPath = $OutputPath -replace " \.html$" , " -remediation.ps1"
    [string]$RemediationScript = Generate-RemediationScripts -AssessmentResults $AssessmentResults
    [string]$RemediationScript | Out-File -FilePath $RemediationPath -Encoding UTF8
        Write-Output "Remediation script saved to: $RemediationPath" # Color: $2
    }
} catch {
    Write-Error "An error occurred during assessment: $_"
    throw`n}
