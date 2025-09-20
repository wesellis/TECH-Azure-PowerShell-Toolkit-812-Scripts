#Requires -Module Az.Network
#Requires -Version 5.1
<#
.SYNOPSIS
    manage nsg rules
.DESCRIPTION
    manage nsg rules operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Manages Network Security Group (NSG) rules in Azure

    Creates, modifies, and removes NSG security rules. Supports both inbound and outbound rules
    with
.PARAMETER NSGName
    Name of the Network Security Group
.PARAMETER ResourceGroupName
    Resource group containing the NSG
.PARAMETER Action
    Action to perform: Add, Remove, List, Update
.PARAMETER RuleName
    Name of the security rule
.PARAMETER Direction
    Rule direction: Inbound, Outbound
.PARAMETER Priority
    Rule priority (100-4096)
.PARAMETER Access
    Allow or Deny
.PARAMETER Protocol
    Protocol: TCP, UDP, ICMP, *
.PARAMETER SourceAddressPrefix
    Source address prefix or CIDR
.PARAMETER SourcePortRange
    Source port range (e.g., 80, 80-90, *)
.PARAMETER DestinationAddressPrefix
    Destination address prefix or CIDR
.PARAMETER DestinationPortRange
    Destination port range
.PARAMETER Description
    Rule description
.PARAMETER CsvFile
    CSV file for bulk rule operations
.PARAMETER Force
    Skip confirmation prompts

    .\manage-nsg-rules.ps1 -NSGName "NSG-Web" -ResourceGroupName "RG-Network" -Action "Add" -RuleName "Allow-HTTP" -Direction "Inbound" -Priority 1000 -Access "Allow" -Protocol "TCP" -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "80"

    Adds HTTP inbound rule to NSG

    .\manage-nsg-rules.ps1 -NSGName "NSG-Web" -ResourceGroupName "RG-Network" -Action "List"

    Lists all rules in the NSG#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$NSGName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Add', 'Remove', 'List', 'Update', 'Import')]
    [string]$Action,

    [Parameter()]
    [string]$RuleName,

    [Parameter()]
    [ValidateSet('Inbound', 'Outbound')]
    [string]$Direction,

    [Parameter()]
    [ValidateRange(100, 4096)]
    [int]$Priority,

    [Parameter()]
    [ValidateSet('Allow', 'Deny')]
    [string]$Access,

    [Parameter()]
    [ValidateSet('TCP', 'UDP', 'ICMP', '*')]
    [string]$Protocol,

    [Parameter()]
    [string]$SourceAddressPrefix = '*',

    [Parameter()]
    [string]$SourcePortRange = '*',

    [Parameter()]
    [string]$DestinationAddressPrefix = '*',

    [Parameter()]
    [string]$DestinationPortRange,

    [Parameter()]
    [string]$Description,

    [Parameter()]
    [ValidateScript({
        if (Test-Path $_) { $true }
        else { throw "CSV file not found: $_" }
    })]
    [string]$CsvFile,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Test-AzureConnection {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    return Get-AzContext
}

function Get-NetworkSecurityGroup {
    param(
        [string]$Name,
        [string]$ResourceGroup
    )

    try {
        return Get-AzNetworkSecurityGroup -Name $Name -ResourceGroupName $ResourceGroup
    }
    catch {
        Write-Error "NSG '$Name' not found in resource group '$ResourceGroup'"
        throw
    }
}

function Test-RuleParameters {
    if ($Action -in @('Add', 'Update')) {
        $required = @('RuleName', 'Direction', 'Priority', 'Access', 'Protocol', 'DestinationPortRange')

        foreach ($param in $required) {
            $value = Get-Variable -Name $param -ValueOnly -ErrorAction SilentlyContinue
            if (-not $value) {
                throw "Parameter '$param' is required for action '$Action'"
            }
        }

        # Check for priority conflicts
        if ($Action -eq 'Add') {
            $nsg = Get-NetworkSecurityGroup -Name $NSGName -ResourceGroup $ResourceGroupName
            $existingRule = $nsg.SecurityRules | Where-Object { $_.Priority -eq $Priority }
            if ($existingRule) {
                throw "Priority $Priority is already used by rule '$($existingRule.Name)'"
            }
        }
    }
}

function New-NSGRule {
    param(
        [object]$NSG,
        [hashtable]$RuleParams
    )

    $params = @{
        Name = $RuleParams.RuleName
        Direction = $RuleParams.Direction
        Priority = $RuleParams.Priority
        Access = $RuleParams.Access
        Protocol = $RuleParams.Protocol
        SourceAddressPrefix = $RuleParams.SourceAddressPrefix
        SourcePortRange = $RuleParams.SourcePortRange
        DestinationAddressPrefix = $RuleParams.DestinationAddressPrefix
        DestinationPortRange = $RuleParams.DestinationPortRange
    }

    if ($RuleParams.Description) {
        $params['Description'] = $RuleParams.Description
    }

    if ($PSCmdlet.ShouldProcess($RuleParams.RuleName, "Add NSG rule")) {
        $NSG | Add-AzNetworkSecurityRuleConfig @params | Set-AzNetworkSecurityGroup | Out-Null
        Write-Host "Added rule: $($RuleParams.RuleName)" -ForegroundColor Green
    }
}

function Remove-NSGRule {
    param(
        [object]$NSG,
        [string]$Name
    )

    $rule = $NSG.SecurityRules | Where-Object { $_.Name -eq $Name }
    if (-not $rule) {
        Write-Warning "Rule '$Name' not found in NSG"
        return
    }

    if (-not $Force) {
        $confirmation = Read-Host "Remove rule '$Name'? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            return
        }
    }

    if ($PSCmdlet.ShouldProcess($Name, "Remove NSG rule")) {
        $NSG | Remove-AzNetworkSecurityRuleConfig -Name $Name | Set-AzNetworkSecurityGroup | Out-Null
        Write-Host "Removed rule: $Name" -ForegroundColor Green
    }
}

function Update-NSGRule {
    param(
        [object]$NSG,
        [hashtable]$RuleParams
    )

    $existingRule = $NSG.SecurityRules | Where-Object { $_.Name -eq $RuleParams.RuleName }
    if (-not $existingRule) {
        Write-Warning "Rule '$($RuleParams.RuleName)' not found. Use Add action to create new rule."
        return
    }

    $params = @{
        Name = $RuleParams.RuleName
        Direction = if ($RuleParams.Direction) { $RuleParams.Direction } else { $existingRule.Direction }
        Priority = if ($RuleParams.Priority) { $RuleParams.Priority } else { $existingRule.Priority }
        Access = if ($RuleParams.Access) { $RuleParams.Access } else { $existingRule.Access }
        Protocol = if ($RuleParams.Protocol) { $RuleParams.Protocol } else { $existingRule.Protocol }
        SourceAddressPrefix = if ($RuleParams.SourceAddressPrefix) { $RuleParams.SourceAddressPrefix } else { $existingRule.SourceAddressPrefix }
        SourcePortRange = if ($RuleParams.SourcePortRange) { $RuleParams.SourcePortRange } else { $existingRule.SourcePortRange }
        DestinationAddressPrefix = if ($RuleParams.DestinationAddressPrefix) { $RuleParams.DestinationAddressPrefix } else { $existingRule.DestinationAddressPrefix }
        DestinationPortRange = if ($RuleParams.DestinationPortRange) { $RuleParams.DestinationPortRange } else { $existingRule.DestinationPortRange }
    }

    if ($RuleParams.Description) {
        $params['Description'] = $RuleParams.Description
    } elseif ($existingRule.Description) {
        $params['Description'] = $existingRule.Description
    }

    if ($PSCmdlet.ShouldProcess($RuleParams.RuleName, "Update NSG rule")) {
        $NSG | Set-AzNetworkSecurityRuleConfig @params | Set-AzNetworkSecurityGroup | Out-Null
        Write-Host "Updated rule: $($RuleParams.RuleName)" -ForegroundColor Green
    }
}

function Show-NSGRules {
    param([object]$NSG)

    if ($NSG.SecurityRules.Count -eq 0) {
        Write-Host "No custom security rules found" -ForegroundColor Yellow
        return
    }

    Write-Host "`nSecurity Rules for NSG: $($NSG.Name)" -ForegroundColor Cyan

    $rules = $NSG.SecurityRules | Sort-Object Priority | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Priority = $_.Priority
            Direction = $_.Direction
            Access = $_.Access
            Protocol = $_.Protocol
            Source = "$($_.SourceAddressPrefix):$($_.SourcePortRange)"
            Destination = "$($_.DestinationAddressPrefix):$($_.DestinationPortRange)"
            Description = $_.Description
        }
    }

    $rules | Format-Table -AutoSize

    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "Total Rules: $($rules.Count)"
    Write-Host "Inbound: $(($rules | Where-Object Direction -eq 'Inbound').Count)"
    Write-Host "Outbound: $(($rules | Where-Object Direction -eq 'Outbound').Count)"
    Write-Host "Allow: $(($rules | Where-Object Access -eq 'Allow').Count)"
    Write-Host "Deny: $(($rules | Where-Object Access -eq 'Deny').Count)"
}

function Import-RulesFromCsv {
    param(
        [object]$NSG,
        [string]$FilePath
    )

    try {
        $csvRules = Import-Csv -Path $FilePath
        $successCount = 0
        $errorCount = 0

        foreach ($csvRule in $csvRules) {
            try {
                $ruleParams = @{
                    RuleName = $csvRule.Name
                    Direction = $csvRule.Direction
                    Priority = [int]$csvRule.Priority
                    Access = $csvRule.Access
                    Protocol = $csvRule.Protocol
                    SourceAddressPrefix = $csvRule.SourceAddressPrefix
                    SourcePortRange = $csvRule.SourcePortRange
                    DestinationAddressPrefix = $csvRule.DestinationAddressPrefix
                    DestinationPortRange = $csvRule.DestinationPortRange
                    Description = $csvRule.Description
                }

                New-NSGRule -NSG $NSG -RuleParams $ruleParams
                $successCount++
            }
            catch {
                Write-Warning "Failed to create rule '$($csvRule.Name)': $_"
                $errorCount++
            }
        }

        Write-Host "`nImport Summary:" -ForegroundColor Cyan
        Write-Host "Successful: $successCount"
        Write-Host "Failed: $errorCount"
    }
    catch {
        Write-Error "Failed to import CSV file: $_"
    }
}

# Main execution
Write-Host "`nNSG Rule Management" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

$nsg = Get-NetworkSecurityGroup -Name $NSGName -ResourceGroup $ResourceGroupName
Write-Host "Working with NSG: $($nsg.Name)" -ForegroundColor Green

switch ($Action) {
    'Add' {
        Test-RuleParameters
        $ruleParams = @{
            RuleName = $RuleName
            Direction = $Direction
            Priority = $Priority
            Access = $Access
            Protocol = $Protocol
            SourceAddressPrefix = $SourceAddressPrefix
            SourcePortRange = $SourcePortRange
            DestinationAddressPrefix = $DestinationAddressPrefix
            DestinationPortRange = $DestinationPortRange
            Description = $Description
        }
        New-NSGRule -NSG $nsg -RuleParams $ruleParams
    }

    'Remove' {
        if (-not $RuleName) {
            throw "RuleName parameter is required for Remove action"
        }
        Remove-NSGRule -NSG $nsg -Name $RuleName
    }

    'Update' {
        Test-RuleParameters
        $ruleParams = @{
            RuleName = $RuleName
            Direction = $Direction
            Priority = $Priority
            Access = $Access
            Protocol = $Protocol
            SourceAddressPrefix = $SourceAddressPrefix
            SourcePortRange = $SourcePortRange
            DestinationAddressPrefix = $DestinationAddressPrefix
            DestinationPortRange = $DestinationPortRange
            Description = $Description
        }
        Update-NSGRule -NSG $nsg -RuleParams $ruleParams
    }

    'List' {
        Show-NSGRules -NSG $nsg
    }

    'Import' {
        if (-not $CsvFile) {
            throw "CsvFile parameter is required for Import action"
        }
        Import-RulesFromCsv -NSG $nsg -FilePath $CsvFile
    }
}

Write-Host "`nOperation completed!" -ForegroundColor Green\n