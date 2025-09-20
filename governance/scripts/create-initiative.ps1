#Requires -Module Az.Resources, Az.PolicyInsights
#Requires -Version 5.1
<#
.SYNOPSIS
    create initiative
.DESCRIPTION
    create initiative operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Creates and manages Azure Policy initiatives (policy sets)
    Supports bundling multiple policy definitions into cohesive governance packages
    with parameter mapping and metadata management.
.PARAMETER InitiativeName
    Name of the policy initiative to create or update
.PARAMETER DisplayName
    Display name for the initiative
.PARAMETER Description
    Detailed description of the initiative's purpose
.PARAMETER Category
    Metadata category for the initiative
.PARAMETER PolicyDefinitionIds
    Array of policy definition IDs to include
.PARAMETER ManagementGroupName
    Management group scope for the initiative
.PARAMETER SubscriptionId
    Subscription scope for the initiative
.PARAMETER Parameters
    JSON string or hashtable of initiative parameters
.PARAMETER Metadata
    Additional metadata for the initiative

    .\create-initiative.ps1 -InitiativeName "SecurityBaseline" -Category "Security"

    Creates a security baseline initiative

    .\create-initiative.ps1 -InitiativeName "CostControl" -PolicyDefinitionIds @("/providers/Microsoft.Authorization/policyDefinitions/...")

    Creates initiative with specific policies

    Author: Azure PowerShell Toolkit#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$InitiativeName,

    [Parameter(Mandatory = $false)]
    [string]$DisplayName,

    [Parameter(Mandatory = $false)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [ValidateSet('General', 'Security', 'Compliance', 'Cost Management', 'Operations')]
    [string]$Category = 'General',

    [Parameter(Mandatory = $false)]
    [string[]]$PolicyDefinitionIds,

    [Parameter(Mandatory = $false)]
    [string]$ManagementGroupName,

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [object]$Parameters,

    [Parameter(Mandatory = $false)]
    [hashtable]$Metadata,

    [Parameter()]
    [switch]$IncludeBuiltInPolicies,

    [Parameter()]
    [ValidateSet('Default', 'SecurityCenter', 'Regulatory')]
    [string]$Template
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $DisplayName) {
    $DisplayName = $InitiativeName
}

if (-not $Description) {
    $Description = "Policy initiative for $Category governance"
}

#endregion

#region Functions
function Get-InitiativeTemplate {
    [CmdletBinding()]
    param(
        [string]$TemplateName
    )

    $templates = @{
        'SecurityCenter' = @{
            DisplayName = 'Azure Security Center Recommendations'
            Description = 'Initiative containing Azure Security Center policy recommendations'
            Policies = @(
                '/providers/Microsoft.Authorization/policyDefinitions/34c877ad-507e-4c82-993e-3452a6e0ad3c', # Storage encryption
                '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9', # Secure transfer
                '/providers/Microsoft.Authorization/policyDefinitions/1a5b4dca-0b6f-4cf5-907c-56316bc1bf3d', # Key Vault purge protection
                '/providers/Microsoft.Authorization/policyDefinitions/0961003e-5a0a-4549-abde-af6a37f2724d'  # VM backup
            )
        }
        'Regulatory' = @{
            DisplayName = 'Regulatory Compliance Baseline'
            Description = 'Initiative for regulatory compliance requirements'
            Policies = @(
                '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c', # Allowed locations
                '/providers/Microsoft.Authorization/policyDefinitions/a451c1ef-c6ca-483d-87ed-f49761e3ffb5', # Audit diagnostic settings
                '/providers/Microsoft.Authorization/policyDefinitions/b7ddfbdc-1260-477d-91fd-98bd9be789a6'  # Audit admin accounts
            )
        }
        'Default' = @{
            DisplayName = 'Custom Governance Initiative'
            Description = 'Custom initiative for organizational governance'
            Policies = @()
        }
    }

    return $templates[$TemplateName]
}

function Get-PolicyDefinitions {
    [CmdletBinding()]
    param(
        [string[]]$PolicyIds,
        [string]$ManagementGroup,
        [string]$Subscription
    )

    $definitions = [System.Collections.ArrayList]::new()

    foreach ($policyId in $PolicyIds) {
        try {
            Write-Verbose "Retrieving policy definition: $policyId"

            if ($policyId -match '^/providers/Microsoft.Authorization/policyDefinitions/') {
                # Built-in policy
                $policy = Get-AzPolicyDefinition -Id $policyId
            }
            elseif ($ManagementGroup) {
                # Custom policy at management group scope
                $policy = Get-AzPolicyDefinition -Name $policyId -ManagementGroupName $ManagementGroup
            }
            elseif ($Subscription) {
                # Custom policy at subscription scope
                $policy = Get-AzPolicyDefinition -Name $policyId -SubscriptionId $Subscription
            }
            else {
                # Try current scope
                $policy = Get-AzPolicyDefinition -Name $policyId
            }

            if ($policy) {
                [void]$definitions.Add($policy)
            
} catch {
            Write-Warning "Could not retrieve policy definition: $policyId - $_"
        }
    }

    return $definitions
}

function Build-InitiativeDefinition {
    [CmdletBinding()]
    param(
        [object[]]$PolicyDefinitions,
        [object]$Parameters,
        [hashtable]$Metadata
    )

    $policyDefinitions = [System.Collections.ArrayList]::new()

    foreach ($policy in $PolicyDefinitions) {
        $policyRef = @{
            policyDefinitionId = $policy.PolicyDefinitionId
            policyDefinitionReferenceId = $policy.Name
        }

        # Map parameters if they exist
        if ($policy.Properties.Parameters) {
            $paramMapping = @{}
            foreach ($param in $policy.Properties.Parameters.PSObject.Properties) {
                $paramName = $param.Name
                # Check if initiative has this parameter
                if ($Parameters -and $Parameters.PSObject.Properties[$paramName]) {
                    $paramMapping[$paramName] = @{
                        value = "[parameters('$paramName')]"
                    }
                }
            }
            if ($paramMapping.Count -gt 0) {
                $policyRef['parameters'] = $paramMapping
            }
        }

        [void]$policyDefinitions.Add($policyRef)
    }

    $initiativeDefinition = @{
        policyDefinitions = $policyDefinitions
        metadata = $Metadata
    }

    if ($Parameters) {
        $initiativeDefinition['parameters'] = $Parameters
    }

    return $initiativeDefinition
}

function New-PolicyInitiative {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Name,
        [string]$DisplayName,
        [string]$Description,
        [object]$Definition,
        [string]$ManagementGroup,
        [string]$Subscription
    )

    try {
        $params = @{
            Name = $Name
            DisplayName = $DisplayName
            Description = $Description
            PolicyDefinition = ($Definition | ConvertTo-Json -Depth 10)
        }

        if ($ManagementGroup) {
            $params['ManagementGroupName'] = $ManagementGroup
            $scope = "Management Group: $ManagementGroup"
        }
        elseif ($Subscription) {
            $params['SubscriptionId'] = $Subscription
            $scope = "Subscription: $Subscription"
        }
        else {
            $scope = "Current subscription"
        }

        if ($PSCmdlet.ShouldProcess($scope, "Create/Update Policy Initiative '$Name'")) {
            $initiative = New-AzPolicySetDefinition @params
            Write-Host "Policy initiative '$Name' created successfully" -InformationAction Continue
            return $initiative
        
} catch {
        Write-Error "Failed to create policy initiative: $_"
        throw
    }
}

function Get-InitiativeSummary {
    [CmdletBinding()]
    param(
        [object]$Initiative
    )

    $summary = [PSCustomObject]@{
        Name = $Initiative.Name
        DisplayName = $Initiative.Properties.DisplayName
        Description = $Initiative.Properties.Description
        PolicyCount = $Initiative.Properties.PolicyDefinitions.Count
        Metadata = $Initiative.Properties.Metadata
        Parameters = if ($Initiative.Properties.Parameters) {
            $Initiative.Properties.Parameters.PSObject.Properties.Count
        } else { 0 }
        CreatedOn = $Initiative.Properties.CreatedOn
        UpdatedOn = $Initiative.Properties.UpdatedOn
    }

    return $summary
}

function Export-InitiativeDefinition {
    [CmdletBinding()]
    param(
        [object]$Initiative,
        [string]$OutputPath
    )

    if (-not $OutputPath) {
        $OutputPath = Join-Path $PWD "$($Initiative.Name)_$(Get-Date -Format 'yyyyMMdd').json"
    }

    try {
        $export = @{
            Name = $Initiative.Name
            Properties = $Initiative.Properties
        }

        $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "Initiative definition exported to: $OutputPath" -InformationAction Continue
        return $OutputPath
    }
    catch {
        Write-Error "Failed to export initiative definition: $_"
        throw
    }
}

#endregion

#region Main-Execution
try {
    Write-Host "[START] Creating Policy Initiative" -InformationAction Continue

    # Get context
    $context = Get-AzContext
    if (-not $context) {
        throw "No Azure context found. Please run Connect-AzAccount first."
    }

    # Apply template if specified
    if ($Template -and $Template -ne 'Default') {
        Write-Verbose "Applying template: $Template"
        $templateConfig = Get-InitiativeTemplate -TemplateName $Template

        if (-not $DisplayName) { $DisplayName = $templateConfig.DisplayName }
        if (-not $Description) { $Description = $templateConfig.Description }
        if (-not $PolicyDefinitionIds -and $templateConfig.Policies) {
            $PolicyDefinitionIds = $templateConfig.Policies
        }
    }

    # Validate policy definitions
    if (-not $PolicyDefinitionIds -or $PolicyDefinitionIds.Count -eq 0) {
        throw "No policy definitions specified. Provide PolicyDefinitionIds or use a Template."
    }

    Write-Host "[RETRIEVE] Getting policy definitions..." -InformationAction Continue
    $params = @{
        PolicyIds = $PolicyDefinitionIds
        ManagementGroup = $ManagementGroupName
        Subscription = $SubscriptionId
    }
    $policies = Get-PolicyDefinitions @params

    if ($policies.Count -eq 0) {
        throw "No valid policy definitions found"
    }

    Write-Host "Found $($policies.Count) valid policy definitions" -InformationAction Continue

    # Set metadata
    if (-not $Metadata) {
        $Metadata = @{}
    }
    $Metadata['category'] = $Category
    $Metadata['version'] = '1.0.0'
    $Metadata['createdBy'] = $context.Account.Id
    $Metadata['createdOn'] = Get-Date -Format 'yyyy-MM-dd'

    # Build initiative definition
    Write-Host "[BUILD] Creating initiative definition..." -InformationAction Continue
    $params = @{
        PolicyDefinitions = $policies
        Parameters = $Parameters
        Metadata = $Metadata
    }
    $initiativeDefinition = Build-InitiativeDefinition @params

    # Create the initiative
    Write-Host "[CREATE] Creating policy initiative: $InitiativeName" -InformationAction Continue
    $params = @{
        DisplayName = $DisplayName
        Subscription = $SubscriptionId
        Definition = $initiativeDefinition
        Name = $InitiativeName
        Description = $Description
        ManagementGroup = $ManagementGroupName
    }
    $initiative = New-PolicyInitiative @params

    # Display summary
    if ($initiative) {
        $summary = Get-InitiativeSummary -Initiative $initiative
        Write-Host "`n[SUMMARY] Policy Initiative Created:" -InformationAction Continue
        $summary | Format-List

        # Export definition
        $exportPath = Export-InitiativeDefinition -Initiative $initiative
    }

    Write-Host "[COMPLETE] Policy initiative created successfully" -InformationAction Continue

    # Return the initiative
    return $initiative
}
catch {
    $errorDetails = @{
        Message = $_.Exception.Message
        Category = $_.CategoryInfo.Category
        Line = $_.InvocationInfo.ScriptLineNumber
    }

    Write-Error "Initiative creation failed: $($errorDetails.Message) at line $($errorDetails.Line)"
    throw
}
finally {
    # Cleanup
    $ProgressPreference = 'Continue'
}

#endregion\n