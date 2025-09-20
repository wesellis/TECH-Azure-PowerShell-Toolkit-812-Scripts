#Requires -Module Az.Resources
#Requires -Version 5.1
<#
.SYNOPSIS
    deploy resource group
.DESCRIPTION
    deploy resource group operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Deploys Azure resource groups with governance policies and tags

    Creates Azure resource groups with standardized naming, tagging, and
    governance policies. Supports applying policy initiatives and
    resource locks automatically.
.PARAMETER ResourceGroupName
    Name of the resource group to create
.PARAMETER Location
    Azure region for the resource group
.PARAMETER Tags
    Hashtable of tags to apply to the resource group
.PARAMETER PolicyInitiativeId
    Policy initiative to assign to the resource group
.PARAMETER ApplyResourceLock
    Apply a CanNotDelete lock to the resource group
.PARAMETER Environment
    Environment type: Dev, Test, Staging, Production
.PARAMETER Owner
    Resource owner contact information
.PARAMETER CostCenter
    Cost center for billing allocation
.PARAMETER Force
    Overwrite existing resource group if it exists

    .\deploy-resource-group.ps1 -ResourceGroupName "RG-WebApp-Prod" -Location "East US" -Environment "Production"

    Creates production resource group with standard governance

    .\deploy-resource-group.ps1 -ResourceGroupName "RG-Dev" -Location "West US" -Tags @{Project="MyApp"} -ApplyResourceLock

    Creates dev resource group with custom tags and resource lock#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^RG-[A-Za-z0-9\-]+$')]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter()]
    [hashtable]$Tags = @{},

    [Parameter()]
    [string]$PolicyInitiativeId,

    [Parameter()]
    [switch]$ApplyResourceLock,

    [Parameter()]
    [ValidateSet('Dev', 'Test', 'Staging', 'Production')]
    [string]$Environment,

    [Parameter()]
    [string]$Owner,

    [Parameter()]
    [string]$CostCenter,

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

function New-StandardTags {
    param(
        [hashtable]$CustomTags,
        [string]$Environment,
        [string]$Owner,
        [string]$CostCenter
    )

    $standardTags = @{
        'CreatedBy' = 'PowerShell-Toolkit'
        'CreatedOn' = (Get-Date -Format 'yyyy-MM-dd')
        'ManagedBy' = 'Governance-Script'
    }

    if ($Environment) { $standardTags['Environment'] = $Environment }
    if ($Owner) { $standardTags['Owner'] = $Owner }
    if ($CostCenter) { $standardTags['CostCenter'] = $CostCenter }

    # Merge with custom tags (custom tags take precedence)
    foreach ($key in $CustomTags.Keys) {
        $standardTags[$key] = $CustomTags[$key]
    }

    return $standardTags
}

function New-ResourceGroupWithGovernance {
    param(
        [string]$Name,
        [string]$Location,
        [hashtable]$Tags,
        [string]$PolicyInitiative,
        [bool]$ApplyLock,
        [bool]$Force
    )

    # Check if resource group exists
    $existingRG = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

    if ($existingRG -and -not $Force) {
        throw "Resource group '$Name' already exists. Use -Force to update."
    }

    if ($PSCmdlet.ShouldProcess($Name, "Create/Update Resource Group")) {
        if ($existingRG) {
            Write-Host "Updating existing resource group: $Name" -ForegroundColor Yellow
            $rg = Set-AzResourceGroup -Name $Name -Tag $Tags
        } else {
            Write-Host "Creating resource group: $Name" -ForegroundColor Green
            $resourcegroupSplat = @{
    Name = $Name
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
        }

        # Apply policy initiative if specified
        if ($PolicyInitiative) {
            Write-Host "Applying policy initiative..." -ForegroundColor Yellow
            try {
                $params = @{
                    Name = "$Name-governance-$(Get-Date -Format 'yyyyMMdd')"
                    DisplayName = "Governance policies for $Name"
                    PolicySetDefinition = Get-AzPolicySetDefinition -Id $PolicyInitiative
                    Scope = $rg.ResourceId
                }
                New-AzPolicyAssignment @params | Out-Null
                Write-Host "Policy initiative applied successfully" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to apply policy initiative: $_"
            }
        }

        # Apply resource lock if requested
        if ($ApplyLock) {
            Write-Host "Applying resource lock..." -ForegroundColor Yellow
            try {
                $params = @{
                    LockName = "$Name-CanNotDelete"
                    LockLevel = 'CanNotDelete'
                    LockNotes = 'Applied by governance script'
                    ResourceGroupName = $Name
                    Force = $true
                }
                New-AzResourceLock @params | Out-Null
                Write-Host "Resource lock applied successfully" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to apply resource lock: $_"
            }
        }

        return $rg
    }
}

function Show-DeploymentSummary {
    param(
        [object]$ResourceGroup,
        [hashtable]$Tags,
        [string]$PolicyInitiative,
        [bool]$HasLock
    )

    Write-Host "`nDeployment Summary:" -ForegroundColor Cyan
    Write-Host "Resource Group: $($ResourceGroup.ResourceGroupName)"
    Write-Host "Location: $($ResourceGroup.Location)"
    Write-Host "Resource ID: $($ResourceGroup.ResourceId)"
    Write-Host "Tags Applied: $($Tags.Count)"

    if ($PolicyInitiative) {
        Write-Host "Policy Initiative: Applied"
    }

    if ($HasLock) {
        Write-Host "Resource Lock: Applied"
    }

    Write-Host "`nTags:" -ForegroundColor Cyan
    $Tags.GetEnumerator() | Sort-Object Key | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)"
    }
}

# Main execution
Write-Host "`nAzure Resource Group Deployment" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

# Build complete tag set
$allTags = New-StandardTags -CustomTags $Tags -Environment $Environment -Owner $Owner -CostCenter $CostCenter

# Validate location
$validLocations = Get-AzLocation | Select-Object -ExpandProperty Location
if ($Location -notin $validLocations) {
    throw "Invalid location: $Location. Use Get-AzLocation to see valid locations."
}

# Deploy resource group with governance
$resourceGroup = New-ResourceGroupWithGovernance -Name $ResourceGroupName -Location $Location -Tags $allTags -PolicyInitiative $PolicyInitiativeId -ApplyLock $ApplyResourceLock -Force $Force

# Show summary
Show-DeploymentSummary -ResourceGroup $resourceGroup -Tags $allTags -PolicyInitiative $PolicyInitiativeId -HasLock $ApplyResourceLock

Write-Host "`nResource group deployment completed successfully!" -ForegroundColor Green

# Return resource group object
return $resourceGroup\n

