#Requires -Version 7.4
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Creates a new Azure Application Security Group

.DESCRIPTION
    This script creates a new Azure Application Security Group in the specified
    resource group and location. Application Security Groups allow you to
    configure network security as a natural extension of an application's structure.

.PARAMETER ResourceGroupName
    The name of the resource group where the application security group will be created

.PARAMETER Name
    The name of the application security group

.PARAMETER Location
    The Azure region where the application security group will be created

.PARAMETER Tag
    Optional hashtable of tags to apply to the application security group

.EXAMPLE
    PS C:\> .\New-ApplicationSecurityGroup.ps1 -ResourceGroupName "MyResourceGroup" -Name "WebServers" -Location "West US"
    Creates a new application security group named "WebServers" in the specified resource group

.AUTHOR
    Wes Ellis (wes@wesellis.com)
#>

param(
    [Parameter(Mandatory = $true)]
    $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    $Name,

    [Parameter(Mandatory = $true)]
    $Location,

    [Parameter(Mandatory = $false)]
    [hashtable]$Tag = @{}
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# Prepare parameters for creating the application security group
$newAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Name
    Location = $Location
}

# Add tags if provided
if ($Tag.Count -gt 0) {
    $newAzApplicationSecurityGroupSplat.Tag = $Tag
}

# Create the application security group
Write-Host "Creating Application Security Group '$Name' in resource group '$ResourceGroupName'..." -ForegroundColor Green
$result = New-AzApplicationSecurityGroup @newAzApplicationSecurityGroupSplat -ErrorAction Stop

Write-Host "Application Security Group '$Name' created successfully!" -ForegroundColor Green
return $result