#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    deploy resource group
.DESCRIPTION
    deploy resource group operation
    Author: Wes Ellis (wes@wesellis.com)

    Deploys Azure resource groups with governance policies and tags

    Creates Azure resource groups with standardized naming, tagging, and
    governance policies. Supports applying policy initiatives and
    resource locks automatically.
.parameter ResourceGroupName
    Name of the resource group to create
.parameter Location
    Azure region for the resource group
.parameter Tags
    Hashtable of tags to apply to the resource group
.parameter PolicyInitiativeId
    Policy initiative to assign to the resource group
.parameter ApplyResourceLock
    Apply a CanNotDelete lock to the resource group
.parameter Environment
    Environment type: Dev, Test, Staging, Production
.parameter Owner
    Resource owner contact information
.parameter CostCenter
    Cost center for billing allocation
.parameter Force
    Overwrite existing resource group if it exists

    .\deploy-resource-group.ps1 -ResourceGroupName "RG-WebApp-Prod" -Location "East US" -Environment "Production"

    Creates production resource group with standard governance

    .\deploy-resource-group.ps1 -ResourceGroupName "RG-Dev" -Location "West US" -Tags @{Project="MyApp"} -ApplyResourceLock

    Creates dev resource group with custom tags and resource lock

[parameter(Mandatory = $true)]
    [ValidatePattern('^RG-[A-Za-z0-9\-]+$')]
    [string]$ResourceGroupName,

    [parameter(Mandatory = $true)]
    [string]$Location,

    [parameter()]
    [hashtable]$Tags = @{},

    [parameter()]
    [string]$PolicyInitiativeId,

    [parameter()]
    [switch]$ApplyResourceLock,

    [parameter()]
    [ValidateSet('Dev', 'Test', 'Staging', 'Production')]
    [string]$Environment,

    [parameter()]
    [string]$Owner,

    [parameter()]
    [string]$CostCenter,

    [parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

[OutputType([PSObject])] 
 {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    }
    return Get-AzContext
}

function New-StandardTags {
    [hashtable]$CustomTags,
        [string]$Environment,
        [string]$Owner,
        [string]$CostCenter
    )

    $StandardTags = @{
        'CreatedBy' = 'PowerShell-Toolkit'
        'CreatedOn' = (Get-Date -Format 'yyyy-MM-dd')
        'ManagedBy' = 'Governance-Script'
    }

    if ($Environment) { $StandardTags['Environment'] = $Environment }
    if ($Owner) { $StandardTags['Owner'] = $Owner }
    if ($CostCenter) { $StandardTags['CostCenter'] = $CostCenter }

    foreach ($key in $CustomTags.Keys) {
        $StandardTags[$key] = $CustomTags[$key]
    }

    return $StandardTags
}

function New-ResourceGroupWithGovernance {
    [string]$Name,
        [string]$Location,
        [hashtable]$Tags,
        [string]$PolicyInitiative,
        [bool]$ApplyLock,
        [bool]$Force
    )

    $ExistingRG = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

    if ($ExistingRG -and -not $Force) {
        throw "Resource group '$Name' already exists. Use -Force to update."
    }

    if ($PSCmdlet.ShouldProcess($Name, "Create/Update Resource Group")) {
        if ($ExistingRG) {
            Write-Host "Updating existing resource group: $Name" -ForegroundColor Green
            $rg = Set-AzResourceGroup -Name $Name -Tag $Tags
        } else {
            Write-Host "Creating resource group: $Name" -ForegroundColor Green
            $ResourcegroupSplat = @{
    Name = $Name
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
        }

        if ($PolicyInitiative) {
            Write-Host "Applying policy initiative..." -ForegroundColor Green
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
                write-Warning "Failed to apply policy initiative: $_"
            }
        }

        if ($ApplyLock) {
            Write-Host "Applying resource lock..." -ForegroundColor Green
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
                write-Warning "Failed to apply resource lock: $_"
            }
        }

        return $rg
    }
}

function Show-DeploymentSummary {
    [object]$ResourceGroup,
        [hashtable]$Tags,
        [string]$PolicyInitiative,
        [bool]$HasLock
    )

    Write-Host "`nDeployment Summary:" -ForegroundColor Green
    Write-Output "Resource Group: $($ResourceGroup.ResourceGroupName)"
    Write-Output "Location: $($ResourceGroup.Location)"
    Write-Output "Resource ID: $($ResourceGroup.ResourceId)"
    Write-Output "Tags Applied: $($Tags.Count)"

    if ($PolicyInitiative) {
        Write-Output "Policy Initiative: Applied"
    }

    if ($HasLock) {
        Write-Output "Resource Lock: Applied"
    }

    Write-Host "`nTags:" -ForegroundColor Green
    $Tags.GetEnumerator() | Sort-Object Key | ForEach-Object {
        Write-Output "  $($_.Key): $($_.Value)"
    }
}

Write-Host "`nAzure Resource Group Deployment" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

$AllTags = New-StandardTags -CustomTags $Tags -Environment $Environment -Owner $Owner -CostCenter $CostCenter

$ValidLocations = Get-AzLocation | Select-Object -ExpandProperty Location
if ($Location -notin $ValidLocations) {
    throw "Invalid location: $Location. Use Get-AzLocation to see valid locations."
}

$ResourceGroup = New-ResourceGroupWithGovernance -Name $ResourceGroupName -Location $Location -Tags $AllTags -PolicyInitiative $PolicyInitiativeId -ApplyLock $ApplyResourceLock -Force $Force

Show-DeploymentSummary -ResourceGroup $ResourceGroup -Tags $AllTags -PolicyInitiative $PolicyInitiativeId -HasLock $ApplyResourceLock

Write-Host "`nResource group deployment completed successfully!" -ForegroundColor Green

return $ResourceGroup\n



