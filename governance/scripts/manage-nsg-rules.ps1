#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    manage nsg rules
.DESCRIPTION
    manage nsg rules operation
    Author: Wes Ellis (wes@wesellis.com)

    Manages Network Security Group (NSG) rules in Azure

    Creates, modifies, and removes NSG security rules. Supports both inbound and outbound rules
    with
.parameter NSGName
    Name of the Network Security Group
.parameter ResourceGroupName
    Resource group containing the NSG
.parameter Action
    Action to perform: Add, Remove, List, Update
.parameter RuleName
    Name of the security rule
.parameter Direction
    Rule direction: Inbound, Outbound
.parameter Priority
    Rule priority (100-4096)
.parameter Access
    Allow or Deny
.parameter Protocol
    Protocol: TCP, UDP, ICMP, *
.parameter SourceAddressPrefix
    Source address prefix or CIDR
.parameter SourcePortRange
    Source port range (e.g., 80, 80-90, *)
.parameter DestinationAddressPrefix
    Destination address prefix or CIDR
.parameter DestinationPortRange
    Destination port range
.parameter Description
    Rule description
.parameter CsvFile
    CSV file for bulk rule operations
.parameter Force
    Skip confirmation prompts

    .\manage-nsg-rules.ps1 -NSGName "NSG-Web" -ResourceGroupName "RG-Network" -Action "Add" -RuleName "Allow-HTTP" -Direction "Inbound" -Priority 1000 -Access "Allow" -Protocol "TCP" -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "80"

    Adds HTTP inbound rule to NSG

    .\manage-nsg-rules.ps1 -NSGName "NSG-Web" -ResourceGroupName "RG-Network" -Action "List"

    Lists all rules in the NSG

[parameter(Mandatory = $true)]
    [string]$NSGName,

    [parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [parameter(Mandatory = $true)]
    [ValidateSet('Add', 'Remove', 'List', 'Update', 'Import')]
    [string]$Action,

    [parameter()]
    [string]$RuleName,

    [parameter()]
    [ValidateSet('Inbound', 'Outbound')]
    [string]$Direction,

    [parameter()]
    [ValidateRange(100, 4096)]
    [int]$Priority,

    [parameter()]
    [ValidateSet('Allow', 'Deny')]
    [string]$Access,

    [parameter()]
    [ValidateSet('TCP', 'UDP', 'ICMP', '*')]
    [string]$Protocol,

    [parameter()]
    [string]$SourceAddressPrefix = '*',

    [parameter()]
    [string]$SourcePortRange = '*',

    [parameter()]
    [string]$DestinationAddressPrefix = '*',

    [parameter()]
    [string]$DestinationPortRange,

    [parameter()]
    [string]$Description,

    [parameter()]
    [ValidateScript({
        if (Test-Path $_) { $true }
        else { throw "CSV file not found: $_" }
    })]
    [string]$CsvFile,

    [parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    return Get-AzContext
}

function Get-NetworkSecurityGroup {
    [string]$Name,
        [string]$ResourceGroup
    )

    try {
        return Get-AzNetworkSecurityGroup -Name $Name -ResourceGroupName $ResourceGroup
    }
    catch {
        write-Error "NSG '$Name' not found in resource group '$ResourceGroup'"
        throw
    }
}

function Test-RuleParameters {
    if ($Action -in @('Add', 'Update')) {
        $required = @('RuleName', 'Direction', 'Priority', 'Access', 'Protocol', 'DestinationPortRange')

        foreach ($param in $required) {
            $value = Get-Variable -Name $param -ValueOnly -ErrorAction SilentlyContinue
            if (-not $value) {
                throw "parameter '$param' is required for action '$Action'"
            }
        }

        if ($Action -eq 'Add') {
            $nsg = Get-NetworkSecurityGroup -Name $NSGName -ResourceGroup $ResourceGroupName
            $ExistingRule = $nsg.SecurityRules | Where-Object { $_.Priority -eq $Priority }
            if ($ExistingRule) {
                throw "Priority $Priority is already used by rule '$($ExistingRule.Name)'"
            }
        }
    }
}

function New-NSGRule {
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
    [object]$NSG,
        [string]$Name
    )

    $rule = $NSG.SecurityRules | Where-Object { $_.Name -eq $Name }
    if (-not $rule) {
        write-Warning "Rule '$Name' not found in NSG"
        return
    }

    if (-not $Force) {
        $confirmation = Read-Host "Remove rule '$Name'? (y/N)"
        if ($confirmation -ne 'y') {
            Write-Host "Operation cancelled" -ForegroundColor Green
            return
        }
    }

    if ($PSCmdlet.ShouldProcess($Name, "Remove NSG rule")) {
        $NSG | Remove-AzNetworkSecurityRuleConfig -Name $Name | Set-AzNetworkSecurityGroup | Out-Null
        Write-Host "Removed rule: $Name" -ForegroundColor Green
    }
}

function Update-NSGRule {
    [object]$NSG,
        [hashtable]$RuleParams
    )

    $ExistingRule = $NSG.SecurityRules | Where-Object { $_.Name -eq $RuleParams.RuleName }
    if (-not $ExistingRule) {
        write-Warning "Rule '$($RuleParams.RuleName)' not found. Use Add action to create new rule."
        return
    }

    $params = @{
        Name = $RuleParams.RuleName
        Direction = if ($RuleParams.Direction) { $RuleParams.Direction } else { $ExistingRule.Direction }
        Priority = if ($RuleParams.Priority) { $RuleParams.Priority } else { $ExistingRule.Priority }
        Access = if ($RuleParams.Access) { $RuleParams.Access } else { $ExistingRule.Access }
        Protocol = if ($RuleParams.Protocol) { $RuleParams.Protocol } else { $ExistingRule.Protocol }
        SourceAddressPrefix = if ($RuleParams.SourceAddressPrefix) { $RuleParams.SourceAddressPrefix } else { $ExistingRule.SourceAddressPrefix }
        SourcePortRange = if ($RuleParams.SourcePortRange) { $RuleParams.SourcePortRange } else { $ExistingRule.SourcePortRange }
        DestinationAddressPrefix = if ($RuleParams.DestinationAddressPrefix) { $RuleParams.DestinationAddressPrefix } else { $ExistingRule.DestinationAddressPrefix }
        DestinationPortRange = if ($RuleParams.DestinationPortRange) { $RuleParams.DestinationPortRange } else { $ExistingRule.DestinationPortRange }
    }

    if ($RuleParams.Description) {
        $params['Description'] = $RuleParams.Description
    } elseif ($ExistingRule.Description) {
        $params['Description'] = $ExistingRule.Description
    }

    if ($PSCmdlet.ShouldProcess($RuleParams.RuleName, "Update NSG rule")) {
        $NSG | Set-AzNetworkSecurityRuleConfig @params | Set-AzNetworkSecurityGroup | Out-Null
        Write-Host "Updated rule: $($RuleParams.RuleName)" -ForegroundColor Green
    }
}

function Show-NSGRules {
    [object]$NSG)

    if ($NSG.SecurityRules.Count -eq 0) {
        Write-Host "No custom security rules found" -ForegroundColor Green
        return
    }

    Write-Host "`nSecurity Rules for NSG: $($NSG.Name)" -ForegroundColor Green

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

    Write-Host "`nSummary:" -ForegroundColor Green
    Write-Output "Total Rules: $($rules.Count)"
    Write-Output "Inbound: $(($rules | Where-Object Direction -eq 'Inbound').Count)"
    Write-Output "Outbound: $(($rules | Where-Object Direction -eq 'Outbound').Count)"
    Write-Output "Allow: $(($rules | Where-Object Access -eq 'Allow').Count)"
    Write-Output "Deny: $(($rules | Where-Object Access -eq 'Deny').Count)"
}

function Import-RulesFromCsv {
    [object]$NSG,
        [string]$FilePath
    )

    try {
        $CsvRules = Import-Csv -Path $FilePath
        $SuccessCount = 0
        $ErrorCount = 0

        foreach ($CsvRule in $CsvRules) {
            try {
                $RuleParams = @{
                    RuleName = $CsvRule.Name
                    Direction = $CsvRule.Direction
                    Priority = [int]$CsvRule.Priority
                    Access = $CsvRule.Access
                    Protocol = $CsvRule.Protocol
                    SourceAddressPrefix = $CsvRule.SourceAddressPrefix
                    SourcePortRange = $CsvRule.SourcePortRange
                    DestinationAddressPrefix = $CsvRule.DestinationAddressPrefix
                    DestinationPortRange = $CsvRule.DestinationPortRange
                    Description = $CsvRule.Description
                }

                New-NSGRule -NSG $NSG -RuleParams $RuleParams
                $SuccessCount++
            }
            catch {
                write-Warning "Failed to create rule '$($CsvRule.Name)': $_"
                $ErrorCount++
            }
        }

        Write-Host "`nImport Summary:" -ForegroundColor Green
        Write-Output "Successful: $SuccessCount"
        Write-Output "Failed: $ErrorCount"
    }
    catch {
        write-Error "Failed to import CSV file: $_"
    }
}

Write-Host "`nNSG Rule Management" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

$nsg = Get-NetworkSecurityGroup -Name $NSGName -ResourceGroup $ResourceGroupName
Write-Host "Working with NSG: $($nsg.Name)" -ForegroundColor Green

switch ($Action) {
    'Add' {
        Test-RuleParameters
        $RuleParams = @{
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
        New-NSGRule -NSG $nsg -RuleParams $RuleParams
    }

    'Remove' {
        if (-not $RuleName) {
            throw "RuleName parameter is required for Remove action"
        }
        Remove-NSGRule -NSG $nsg -Name $RuleName
    }

    'Update' {
        Test-RuleParameters
        $RuleParams = @{
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
        Update-NSGRule -NSG $nsg -RuleParams $RuleParams
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



