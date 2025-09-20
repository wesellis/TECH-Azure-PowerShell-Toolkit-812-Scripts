<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations\n    Author: Wes Ellis (wes@wesellis.com)\n#>
# Enhanced Azure VM Provisioning Tool with enterprise features
param (
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9\-]{1,62}[a-zA-Z0-9]$')][string]$ResourceGroupName,
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9\-]{1,62}[a-zA-Z0-9]$')][string]$VmName,
    [ValidateSet("East US", "West US", "Central US", "East US 2", "West US 2")][string]$Location = "East US",
    [ValidateSet("Standard_B1s", "Standard_B2s", "Standard_D2s_v3", "Standard_D4s_v3")][string]$VmSize = "Standard_B2s",
    [string]$AdminUsername = "azureadmin",
    [securestring]$AdminPassword,
    [hashtable]$Tags = @{},
    [switch]$EnableBootDiagnostics,
    [switch]$WhatIf,
    [switch]$Force
)
# Import enhanced functions
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath "modules", "AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
riptName "Azure VM Provisioning Tool" -Description "Enterprise VM deployment with enhanced features"
try {
    Write-HostNumber 1 -TotalSteps 6 -StepName "Validation" -Status "Checking Azure connection..."
    if (-not ((Get-AzContext))) { throw "Azure connection validation failed" }
    Write-HostNumber 2 -TotalSteps 6 -StepName "Resource Group" -Status "Validating resource group..."
    $rg = Invoke-AzureOperation -Operation { Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop } -OperationName "Get Resource Group"
    
    Write-HostNumber 3 -TotalSteps 6 -StepName "Network Setup" -Status "Configuring network..."
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $vnet -and -not $WhatIf) {
        $vnet = Invoke-AzureOperation -Operation {
            $virtualnetworkSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    AddressPrefix = "10.0.0.0/16"
}
New-AzVirtualNetwork @virtualnetworkSplat
        } -OperationName "Create Virtual Network"
    }
    Write-HostNumber 4 -TotalSteps 6 -StepName "Security" -Status "Setting up security..."
    if (-not $AdminPassword) { $AdminPassword = Read-Host "Enter admin password" -AsSecureString }
    $credential = [PSCredential]::new($AdminUsername, $AdminPassword)
    Write-HostNumber 5 -TotalSteps 6 -StepName "VM Creation" -Status "Creating virtual machine..."
    if ($WhatIf) {
        
    } else {
        $defaultTags = @{ CreatedBy = "Azure-Automation-Scripts"; CreatedOn = (Get-Date).ToString("yyyy-MM-dd"); Script = "Enhanced-VM-Tool" }
        foreach ($tag in $Tags.GetEnumerator()) { $defaultTags[$tag.Key] = $tag.Value }
        if (-not $Force) {
            $confirm = Read-Host "Create VM '$VmName'? (y/N)"
            if ($confirm -notmatch '^[Yy]') { 
        }
        $vm = Invoke-AzureOperation -Operation { New-AzVM -ErrorAction Stop @vmParams } -OperationName "Create VM" -MaxRetries 2
        
    }
    Write-HostNumber 6 -TotalSteps 6 -StepName "Complete" -Status "Finalizing..."
    } catch {
        throw
}\n

