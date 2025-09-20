<#
.SYNOPSIS
    Azure Vm Provisioning Tool Enhanced

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9\-]{1,62}[a-zA-Z0-9]$')][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9\-]{1,62}[a-zA-Z0-9]$')][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VmName,
    [ValidateSet("East US" , "West US" , "Central US" , "East US 2" , "West US 2" )][string]$Location = "East US" ,
    [ValidateSet("Standard_B1s" , "Standard_B2s" , "Standard_D2s_v3" , "Standard_D4s_v3" )][string]$VmSize = "Standard_B2s" ,
    [string]$AdminUsername = " azureadmin" ,
    [securestring]$AdminPassword,
    [hashtable]$Tags = @{},
    [switch]$EnableBootDiagnostics,
    [switch]$WhatIf,
    [switch]$Force
)
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath " .." -AdditionalChildPath " modules" , "AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
Write-Host "Azure Script Started" -ForegroundColor GreenName "Azure VM Provisioning Tool" -Description "Enterprise VM deployment with enhanced features"
try {
    # Progress stepNumber 1 -TotalSteps 6 -StepName "Validation" -Status "Checking Azure connection..."
    if (-not (Get-AzContext)) { Connect-AzAccount }
    # Progress stepNumber 2 -TotalSteps 6 -StepName "Resource Group" -Status "Validating resource group..."
    $rg = Invoke-AzureOperation -Operation { Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop } -OperationName "Get Resource Group"

    # Progress stepNumber 3 -TotalSteps 6 -StepName "Network Setup" -Status "Configuring network..."
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $vnet -and -not $WhatIf) {
        $vnet = Invoke-AzureOperation -Operation {
            New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name " $ResourceGroupName-vnet" -Location $Location -AddressPrefix " 10.0.0.0/16"
        } -OperationName "Create Virtual Network"
    }
    # Progress stepNumber 4 -TotalSteps 6 -StepName "Security" -Status "Setting up security..."
    if (-not $AdminPassword) { $AdminPassword = Read-Host "Enter admin password" -AsSecureString }
$credential = [PSCredential]::new($AdminUsername, $AdminPassword)
    # Progress stepNumber 5 -TotalSteps 6 -StepName "VM Creation" -Status "Creating virtual machine..."
    if ($WhatIf) {

    } else {
$defaultTags = @{ CreatedBy = "Azure-Automation-Scripts" ; CreatedOn = (Get-Date).ToString(" yyyy-MM-dd" ); Script = "Enhanced-VM-Tool" }
        foreach ($tag in $Tags.GetEnumerator()) { $defaultTags[$tag.Key] = $tag.Value }
        if (-not $Force) {
            $confirm = Read-Host "Create VM '$VmName'? (y/N)"
            if ($confirm -notmatch '^[Yy]') {
        }
        $vmParams = @{
            ResourceGroupName = $ResourceGroupName
            Name = $VmName
            Location = $Location
            Size = $VmSize
            Credential = $credential
            Image = "Win2022Datacenter"
            Tag = $defaultTags
        }
$vm = Invoke-AzureOperation -Operation { New-AzVM -ErrorAction Stop @vmParams } -OperationName "Create VM" -MaxRetries 2

    }
    # Progress stepNumber 6 -TotalSteps 6 -StepName "Complete" -Status "Finalizing..."
    } catch {
        throw
}\n