<#
.SYNOPSIS
    Azure Zero Trust Network Analyzer

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
    We Enhanced Azure Zero Trust Network Analyzer

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Analyzes Azure environment for Zero Trust Network compliance and provides actionable recommendations.

.DESCRIPTION
    This advanced tool performs a comprehensive Zero Trust Network assessment across your Azure environment,
    analyzing network segmentation, identity-based access, encryption, and micro-segmentation strategies.
    It generates a detailed compliance report with specific remediation steps.

.PARAMETER SubscriptionId
    The Azure Subscription ID to analyze. If not specified, uses current subscription.

.PARAMETER OutputPath
    Path to save the Zero Trust assessment report. Defaults to current directory.

.PARAMETER IncludeRemediation
    Generate automated remediation scripts for identified issues.

.PARAMETER DetailLevel
    Level of detail in the report: Summary, Detailed, or Executive.

.EXAMPLE
    .\Azure-Zero-Trust-Network-Analyzer.ps1 -DetailLevel " Detailed" -IncludeRemediation

.NOTES
    Author: Wesley Ellis
    Date: June 2024
    Version: 1.0.0
    Requires: Az.Network, Az.Security, Az.Monitor modules


[CmdletBinding(SupportsShouldProcess=$true)]
[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputPath = " .\ZeroTrust-Assessment-$(Get-Date -Format 'yyyyMMdd-HHmmss').html" ,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEIncludeRemediation,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Summary" , " Detailed" , " Executive" )]
    [string]$WEDetailLevel = " Detailed"
)


$requiredModules = @('Az.Network', 'Az.Security', 'Az.Monitor', 'Az.Resources')
foreach ($module in $requiredModules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        Write-Error " Module $module is not installed. Please install it using: Install-Module -Name $module"
        exit 1
    }
    Import-Module $module -ErrorAction Stop
}


$assessmentResults = @{
    SubscriptionId = ""
    AssessmentDate = Get-Date
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

function WE-Test-NetworkSegmentation {
    Write-WELog " Analyzing network segmentation..." " INFO" -ForegroundColor Yellow
    
    $vnets = Get-AzVirtualNetwork
    $segmentationIssues = @()
    
    foreach ($vnet in $vnets) {
        $vnetAnalysis = @{
            VNetName = $vnet.Name
            ResourceGroup = $vnet.ResourceGroupName
            AddressSpace = $vnet.AddressSpace.AddressPrefixes -join " , "
            Subnets = @()
            Issues = @()
            Score = 100
        }
        
        # Check for proper subnet segmentation
        if ($vnet.Subnets.Count -lt 3) {
            $vnetAnalysis.Issues += " Insufficient subnet segmentation (recommended: separate subnets for web, app, data tiers)"
            $vnetAnalysis.Score -= 20
        }
        
        # Check for subnet NSG associations
        foreach ($subnet in $vnet.Subnets) {
            $subnetInfo = @{
                Name = $subnet.Name
                AddressPrefix = $subnet.AddressPrefix
                HasNSG = $null -ne $subnet.NetworkSecurityGroup
                HasRouteTable = $null -ne $subnet.RouteTable
            }
            
            if (!$subnetInfo.HasNSG -and $subnet.Name -ne " AzureFirewallSubnet" ) {
                $vnetAnalysis.Issues += " Subnet '$($subnet.Name)' lacks NSG association"
                $vnetAnalysis.Score -= 10
            }
            
            $vnetAnalysis.Subnets += $subnetInfo
        }
        
        # Check for VNet peering security
        if ($vnet.VirtualNetworkPeerings.Count -gt 0) {
            foreach ($peering in $vnet.VirtualNetworkPeerings) {
                if ($peering.AllowForwardedTraffic) {
                    $vnetAnalysis.Issues += " Peering '$($peering.Name)' allows forwarded traffic (security risk)"
                    $vnetAnalysis.Score -= 15
                }
            }
        }
        
        $segmentationIssues = $segmentationIssues + $vnetAnalysis
    }
    
    return $segmentationIssues
}

function WE-Test-IdentityPerimeter {
    Write-WELog " Analyzing identity perimeter security..." " INFO" -ForegroundColor Yellow
    
    $identityIssues = @()
    
    # Check for Service Endpoints vs Private Endpoints usage
    $storageAccounts = Get-AzStorageAccount
    foreach ($storage in $storageAccounts) {
        $storageAnalysis = @{
            ResourceName = $storage.StorageAccountName
            ResourceType = " Storage Account"
            NetworkRuleSet = $storage.NetworkRuleSet
            Issues = @()
            Score = 100
        }
        
        if ($storage.NetworkRuleSet.DefaultAction -eq " Allow" ) {
            $storageAnalysis.Issues += " Public network access allowed (should use Private Endpoints)"
            $storageAnalysis.Score -= 30
        }
        
        if ($storage.NetworkRuleSet.VirtualNetworkRules.Count -eq 0 -and 
            $storage.PrivateEndpointConnections.Count -eq 0) {
            $storageAnalysis.Issues += " No network restrictions configured"
            $storageAnalysis.Score -= 40
        }
        
        $identityIssues = $identityIssues + $storageAnalysis
    }
    
    # Check SQL Servers
    $sqlServers = Get-AzSqlServer
    foreach ($sql in $sqlServers) {
        $sqlAnalysis = @{
            ResourceName = $sql.ServerName
            ResourceType = " SQL Server"
            Issues = @()
            Score = 100
        }
        
        $firewallRules = Get-AzSqlServerFirewallRule -ServerName $sql.ServerName -ResourceGroupName $sql.ResourceGroupName
        
        foreach ($rule in $firewallRules) {
            if ($rule.StartIpAddress -eq " 0.0.0.0" -and $rule.EndIpAddress -eq " 255.255.255.255" ) {
                $sqlAnalysis.Issues += " Firewall rule allows all IP addresses"
                $sqlAnalysis.Score -= 50
            }
        }
        
        $identityIssues = $identityIssues + $sqlAnalysis
    }
    
    return $identityIssues
}

function WE-Test-EncryptionCompliance {
    Write-WELog " Analyzing encryption compliance..." " INFO" -ForegroundColor Yellow
    
    $encryptionIssues = @()
    
    # Check VM disk encryption
    $vms = Get-AzVM
    foreach ($vm in $vms) {
        $vmAnalysis = @{
            ResourceName = $vm.Name
            ResourceType = " Virtual Machine"
            Issues = @()
            Score = 100
        }
        
        $diskEncryptionStatus = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name
        
        if ($diskEncryptionStatus.OsVolumeEncrypted -ne " Encrypted" ) {
            $vmAnalysis.Issues += " OS disk not encrypted"
            $vmAnalysis.Score -= 30
        }
        
        if ($diskEncryptionStatus.DataVolumesEncrypted -ne " Encrypted" -and $vm.StorageProfile.DataDisks.Count -gt 0) {
            $vmAnalysis.Issues += " Data disks not encrypted"
            $vmAnalysis.Score -= 30
        }
        
        $encryptionIssues = $encryptionIssues + $vmAnalysis
    }
    
    return $encryptionIssues
}

function WE-Test-MicroSegmentation {
    Write-WELog " Analyzing micro-segmentation implementation..." " INFO" -ForegroundColor Yellow
    
    $microSegmentationIssues = @()
    $nsgs = Get-AzNetworkSecurityGroup
    
    foreach ($nsg in $nsgs) {
        $nsgAnalysis = @{
            NSGName = $nsg.Name
            ResourceGroup = $nsg.ResourceGroupName
            Rules = @()
            Issues = @()
            Score = 100
        }
        
        # Check for overly permissive rules
        foreach ($rule in $nsg.SecurityRules) {
            if ($rule.SourceAddressPrefix -eq " *" -and $rule.Access -eq " Allow" ) {
                $nsgAnalysis.Issues += " Rule '$($rule.Name)' allows traffic from any source"
                $nsgAnalysis.Score -= 15
            }
            
            if ($rule.DestinationPortRange -eq " *" -and $rule.Access -eq " Allow" ) {
                $nsgAnalysis.Issues += " Rule '$($rule.Name)' allows traffic to any port"
                $nsgAnalysis.Score -= 15
            }
        }
        
        # Check for application-specific segmentation
        if ($nsg.SecurityRules.Count -lt 3) {
            $nsgAnalysis.Issues += " Insufficient micro-segmentation rules (less than 3 rules)"
            $nsgAnalysis.Score -= 20
        }
        
        $microSegmentationIssues = $microSegmentationIssues + $nsgAnalysis
    }
    
    return $microSegmentationIssues
}

function WE-Generate-RemediationScripts {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param($WEAssessmentResults)
    
    Write-WELog " Generating remediation scripts..." " INFO" -ForegroundColor Green
    
    $remediationScript = @"



" @

    foreach ($vnet in $WEAssessmentResults.NetworkSegmentation) {
        if ($vnet.Issues.Count -gt 0) {
            $remediationScript = $remediationScript + @"


" @
            
            foreach ($subnet in $vnet.Subnets) {
                if (!$subnet.HasNSG) {
                    $remediationScript = $remediationScript + @"


`$nsg = New-AzNetworkSecurityGroup -Name " nsg-$($subnet.Name)" -ResourceGroupName " $($vnet.ResourceGroup)" -Location " East US"
`$vnet = Get-AzVirtualNetwork -Name " $($vnet.VNetName)" -ResourceGroupName " $($vnet.ResourceGroup)"
Set-AzVirtualNetworkSubnetConfig -Name " $($subnet.Name)" -VirtualNetwork `$vnet -AddressPrefix " $($subnet.AddressPrefix)" -NetworkSecurityGroup `$nsg
`$vnet | Set-AzVirtualNetwork
" @
                }
            }
        }
    }
    
    # Add more remediation sections...
    
    return $remediationScript
}

function WE-Generate-HTMLReport {
    [CmdletBinding()]; 
$ErrorActionPreference = " Stop"
param($WEAssessmentResults)
    
   ;  $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Zero Trust Network Assessment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background-color: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .summary { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .score { font-size: 48px; font-weight: bold; }
        .score.high { color: #107c10; }
        .score.medium { color: #ff8c00; }
        .score.low { color: #d83b01; }
        .section { background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .issue { background-color: #fff4ce; padding: 10px; margin: 5px 0; border-left: 4px solid #ff8c00; }
        .critical { border-left-color: #d83b01; background-color: #fde7e9; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f0f0f0; }
        .recommendation { background-color: #e7f3ff; padding: 10px; margin: 5px 0; border-left: 4px solid #0078d4; }
    </style>
</head>
<body>
    <div class=" header" >
        <h1>Zero Trust Network Assessment Report</h1>
        <p>Subscription: $($WEAssessmentResults.SubscriptionId)</p>
        <p>Assessment Date: $($WEAssessmentResults.AssessmentDate)</p>
    </div>
    
    <div class=" summary" >
        <h2>Overall Zero Trust Score</h2>
        <div class=" score $(if ($WEAssessmentResults.OverallScore -ge 80) {'high'} elseif ($WEAssessmentResults.OverallScore -ge 60) {'medium'} else {'low'})" >
            $($WEAssessmentResults.OverallScore)%
        </div>
        <p>Your environment's Zero Trust Network maturity level: $(
            if ($WEAssessmentResults.OverallScore -ge 80) { " Advanced" }
            elseif ($WEAssessmentResults.OverallScore -ge 60) { " Intermediate" }
            else { " Initial" }
        )</p>
    </div>
" @
    
    # Add detailed sections
    if ($WEDetailLevel -ne " Executive" ) {
        # Network Segmentation Section
        $html = $html + @"
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
        foreach ($vnet in $WEAssessmentResults.NetworkSegmentation) {
            $html = $html + @"
            <tr>
                <td>$($vnet.VNetName)</td>
                <td>$($vnet.AddressSpace)</td>
                <td>$($vnet.Subnets.Count)</td>
                <td>$($vnet.Score)%</td>
                <td>$($vnet.Issues.Count)</td>
            </tr>
" @
        }
        $html = $html + " </table></div>"
    }
    
    $html = $html + @"
    <div class=" section" >
        <h2>Recommendations</h2>
" @
    
    foreach ($rec in $WEAssessmentResults.Recommendations) {
        $html = $html + @"
        <div class=" recommendation" >
            <strong>$($rec.Title)</strong>
            <p>$($rec.Description)</p>
            <p><em>Priority: $($rec.Priority) | Impact: $($rec.Impact)</em></p>
        </div>
" @
    }
    
    $html = $html + @"
    </div>
</body>
</html>
" @
    
    return $html
}


try {
    # Connect to Azure if needed
    $context = Get-AzContext
    if (!$context) {
        Write-WELog " Connecting to Azure..." " INFO" -ForegroundColor Yellow
        Connect-AzAccount
    }
    
    if ($WESubscriptionId) {
        Set-AzContext -SubscriptionId $WESubscriptionId
    }
    
    $assessmentResults.SubscriptionId = (Get-AzContext).Subscription.Id
    
    # Run assessments
    $assessmentResults.NetworkSegmentation = Test-NetworkSegmentation
    $assessmentResults.IdentityPerimeter = Test-IdentityPerimeter
    $assessmentResults.EncryptionStatus = Test-EncryptionCompliance
    $assessmentResults.MicroSegmentation = Test-MicroSegmentation
    
    # Calculate overall score
    $totalScore = 0
    $componentCount = 0
    
    foreach ($component in @($assessmentResults.NetworkSegmentation, $assessmentResults.IdentityPerimeter, 
                            $assessmentResults.EncryptionStatus, $assessmentResults.MicroSegmentation)) {
        foreach ($item in $component) {
            $totalScore = $totalScore + $item.Score
            $componentCount++
        }
    }
    
    $assessmentResults.OverallScore = [math]::Round($totalScore / $componentCount)
    
    # Generate recommendations
    $assessmentResults.Recommendations = @(
        @{
            Title = " Implement Private Endpoints"
            Description = " Replace Service Endpoints with Private Endpoints for PaaS services to ensure traffic stays within your VNet"
            Priority = " High"
            Impact = " Security"
        },
        @{
            Title = " Enable Disk Encryption"
            Description = " Enable Azure Disk Encryption on all VMs to protect data at rest"
            Priority = " High"
            Impact = " Compliance"
        },
        @{
            Title = " Implement Micro-segmentation"
            Description = " Create application-specific NSG rules to limit lateral movement"
            Priority = " Medium"
            Impact = " Security"
        }
    )
    
    # Generate report
    $htmlReport = Generate-HTMLReport -AssessmentResults $assessmentResults
    $htmlReport | Out-File -FilePath $WEOutputPath -Encoding UTF8
    
    Write-WELog " `nAssessment completed successfully!" " INFO" -ForegroundColor Green
    Write-WELog " Overall Zero Trust Score: $($assessmentResults.OverallScore)%" " INFO" -ForegroundColor $(
        if ($assessmentResults.OverallScore -ge 80) { " Green" }
        elseif ($assessmentResults.OverallScore -ge 60) { " Yellow" }
        else { " Red" }
    )
    Write-WELog " Report saved to: $WEOutputPath" " INFO" -ForegroundColor Cyan
    
    # Generate remediation scripts if requested
    if ($WEIncludeRemediation) {
       ;  $remediationPath = $WEOutputPath -replace " \.html$" , " -remediation.ps1"
       ;  $remediationScript = Generate-RemediationScripts -AssessmentResults $assessmentResults
        $remediationScript | Out-File -FilePath $remediationPath -Encoding UTF8
        Write-WELog " Remediation script saved to: $remediationPath" " INFO" -ForegroundColor Cyan
    }
    
} catch {
    Write-Error " An error occurred during assessment: $_"
    exit 1
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================