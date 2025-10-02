#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Vm Provisioning Tool Enhanced

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
    [string]$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath " .." -AdditionalChildPath " modules" , "AzureAutomationCommon"
if (Test-Path $ModulePath) { Write-Host "Azure Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    [string]$rg = Invoke-AzureOperation -Operation { Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop } -OperationName "Get Resource Group"
$vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $vnet -and -not $WhatIf) {
    [string]$vnet = Invoke-AzureOperation -Operation {
$VirtualnetworkSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    AddressPrefix = " 10.0.0.0/16"
}
New-AzVirtualNetwork @virtualnetworkSplat
        } -OperationName "Create Virtual Network"
    }
    if (-not $AdminPassword) { $AdminPassword = Read-Host "Enter admin password" -AsSecureString }
    [string]$credential = [PSCredential]::new($AdminUsername, $AdminPassword)
    if ($WhatIf) {

    } else {
$DefaultTags = @{ CreatedBy = "Azure-Automation-Scripts" ; CreatedOn = (Get-Date).ToString(" yyyy-MM-dd" ); Script = "Enhanced-VM-Tool" }
        foreach ($tag in $Tags.GetEnumerator()) { $DefaultTags[$tag.Key] = $tag.Value }
        if (-not $Force) {
    [string]$confirm = Read-Host "Create VM '$VmName'? (y/N)"
            if ($confirm -notmatch '^[Yy]') {
        }
$VmParams = @{
            ResourceGroupName = $ResourceGroupName
            Name = $VmName
            Location = $Location
            Size = $VmSize
            Credential = $credential
            Image = "Win2022Datacenter"
            Tag = $DefaultTags
        }
    [string]$vm = Invoke-AzureOperation -Operation { New-AzVM -ErrorAction Stop @vmParams } -OperationName "Create VM" -MaxRetries 2

    }
    } catch {
        throw`n}
