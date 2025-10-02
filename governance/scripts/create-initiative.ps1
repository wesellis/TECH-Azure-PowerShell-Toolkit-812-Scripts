#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    create initiative
.DESCRIPTION
    create initiative operation
    Author: Wes Ellis (wes@wesellis.com)

    Creates and manages Azure Policy initiatives (policy sets)
    Supports bundling multiple policy definitions into cohesive governance packages
    with parameter mapping and metadata management.
.parameter InitiativeName
    Name of the policy initiative to create or update
.parameter DisplayName
    Display name for the initiative
.parameter Description
    Detailed description of the initiative's purpose
.parameter Category
    Metadata category for the initiative
.parameter PolicyDefinitionIds
    Array of policy definition IDs to include
.parameter ManagementGroupName
    Management group scope for the initiative
.parameter SubscriptionId
    Subscription scope for the initiative
.parameter Parameters
    JSON string or hashtable of initiative parameters
.parameter Metadata
    Additional metadata for the initiative

    .\create-initiative.ps1 -InitiativeName "SecurityBaseline" -Category "Security"

    Creates a security baseline initiative

    .\create-initiative.ps1 -InitiativeName "CostControl" -PolicyDefinitionIds @("/providers/Microsoft.Authorization/policyDefinitions/...")

    Creates initiative with specific policies

    Author: Azure PowerShell Toolkit

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$InitiativeName,

    [parameter(Mandatory = $false)]
    [string]$DisplayName,

    [parameter(Mandatory = $false)]
    [string]$Description,

    [parameter(Mandatory = $false)]
    [ValidateSet('General', 'Security', 'Compliance', 'Cost Management', 'Operations')]
    [string]$Category = 'General',

    [parameter(Mandatory = $false)]
    [string[]]$PolicyDefinitionIds,

    [parameter(Mandatory = $false)]
    [string]$ManagementGroupName,

    [parameter(Mandatory = $false)]
    [ValidatePattern('^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')]
    [string]$SubscriptionId,

    [parameter(Mandatory = $false)]
    [object]$Parameters,

    [parameter(Mandatory = $false)]
    [hashtable]$Metadata,

    [parameter()]
    [switch]$IncludeBuiltInPolicies,

    [parameter()]
    [ValidateSet('Default', 'SecurityCenter', 'Regulatory')]
    [string]$Template
)
    [string]$ErrorActionPreference = 'Stop'
    [string]$ProgressPreference = 'SilentlyContinue'

if (-not $DisplayName) {
    [string]$DisplayName = $InitiativeName
}

if (-not $Description) {
    [string]$Description = "Policy initiative for $Category governance"
}


[OutputType([bool])] 
 {
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
    param(
        [string[]]$PolicyIds,
        [string]$ManagementGroup,
        [string]$Subscription
    )
    [string]$definitions = [System.Collections.ArrayList]::new()

    foreach ($PolicyId in $PolicyIds) {
        try {
            write-Verbose "Retrieving policy definition: $PolicyId"

            if ($PolicyId -match '^/providers/Microsoft.Authorization/policyDefinitions/') {
    $policy = Get-AzPolicyDefinition -Id $PolicyId
            }
            elseif ($ManagementGroup) {
    $policy = Get-AzPolicyDefinition -Name $PolicyId -ManagementGroupName $ManagementGroup
            }
            elseif ($Subscription) {
    $policy = Get-AzPolicyDefinition -Name $PolicyId -SubscriptionId $Subscription
            }
            else {
    $policy = Get-AzPolicyDefinition -Name $PolicyId
            }

            if ($policy) {
                [void]$definitions.Add($policy)

} catch {
            write-Warning "Could not retrieve policy definition: $PolicyId - $_"
        }
    }

    return $definitions
}

function Build-InitiativeDefinition {
    param(
        [object[]]$PolicyDefinitions,
        [object]$Parameters,
        [hashtable]$Metadata
    )
    [string]$PolicyDefinitions = [System.Collections.ArrayList]::new()

    foreach ($policy in $PolicyDefinitions) {
    $PolicyRef = @{
            policyDefinitionId = $policy.PolicyDefinitionId
            policyDefinitionReferenceId = $policy.Name
        }

        if ($policy.Properties.Parameters) {
    $ParamMapping = @{}
            foreach ($param in $policy.Properties.Parameters.PSObject.Properties) {
    [string]$ParamName = $param.Name
                if ($Parameters -and $Parameters.PSObject.Properties[$ParamName]) {
    [string]$ParamMapping[$ParamName] = @{
                        value = "[parameters('$ParamName')]"
                    }
                }
            }
            if ($ParamMapping.Count -gt 0) {
    [string]$PolicyRef['parameters'] = $ParamMapping
            }
        }

        [void]$PolicyDefinitions.Add($PolicyRef)
    }
    $InitiativeDefinition = @{
        policyDefinitions = $PolicyDefinitions
        metadata = $Metadata
    }

    if ($Parameters) {
    [string]$InitiativeDefinition['parameters'] = $Parameters
    }

    return $InitiativeDefinition
}

function New-PolicyInitiative {
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
    [string]$params['ManagementGroupName'] = $ManagementGroup
    [string]$scope = "Management Group: $ManagementGroup"
        }
        elseif ($Subscription) {
    [string]$params['SubscriptionId'] = $Subscription
    [string]$scope = "Subscription: $Subscription"
        }
        else {
    [string]$scope = "Current subscription"
        }

        if ($PSCmdlet.ShouldProcess($scope, "Create/Update Policy Initiative '$Name'")) {
    [string]$initiative = New-AzPolicySetDefinition @params
            Write-Output "Policy initiative '$Name' created successfully" -InformationAction Continue
            return $initiative

} catch {
        write-Error "Failed to create policy initiative: $_"
        throw
    }
}

function Get-InitiativeSummary {
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
    [string]$Initiative.Properties.Parameters.PSObject.Properties.Count
        } else { 0 }
        CreatedOn = $Initiative.Properties.CreatedOn
        UpdatedOn = $Initiative.Properties.UpdatedOn
    }

    return $summary
}

function Export-InitiativeDefinition {
    param(
        [object]$Initiative,
        [string]$OutputPath
    )

    if (-not $OutputPath) {
    [string]$OutputPath = Join-Path $PWD "$($Initiative.Name)_$(Get-Date -Format 'yyyyMMdd').json"
    }

    try {
    $export = @{
            Name = $Initiative.Name
            Properties = $Initiative.Properties
        }
    [string]$export | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "Initiative definition exported to: $OutputPath" -InformationAction Continue
        return $OutputPath
    }
    catch {
        write-Error "Failed to export initiative definition: $_"
        throw
    }
}


try {
    Write-Output "[START] Creating Policy Initiative" -InformationAction Continue
    $context = Get-AzContext
    if (-not $context) {
        throw "No Azure context found. Please run Connect-AzAccount first."
    }

    if ($Template -and $Template -ne 'Default') {
        write-Verbose "Applying template: $Template"
    $TemplateConfig = Get-InitiativeTemplate -TemplateName $Template

        if (-not $DisplayName) { $DisplayName = $TemplateConfig.DisplayName }
        if (-not $Description) { $Description = $TemplateConfig.Description }
        if (-not $PolicyDefinitionIds -and $TemplateConfig.Policies) {
    [string]$PolicyDefinitionIds = $TemplateConfig.Policies
        }
    }

    if (-not $PolicyDefinitionIds -or $PolicyDefinitionIds.Count -eq 0) {
        throw "No policy definitions specified. Provide PolicyDefinitionIds or use a Template."
    }

    Write-Output "[RETRIEVE] Getting policy definitions..." -InformationAction Continue
    $params = @{
        PolicyIds = $PolicyDefinitionIds
        ManagementGroup = $ManagementGroupName
        Subscription = $SubscriptionId
    }
    $policies = Get-PolicyDefinitions @params

    if ($policies.Count -eq 0) {
        throw "No valid policy definitions found"
    }

    Write-Output "Found $($policies.Count) valid policy definitions" -InformationAction Continue

    if (-not $Metadata) {
    $Metadata = @{}
    }
    [string]$Metadata['category'] = $Category
    [string]$Metadata['version'] = '1.0.0'
    [string]$Metadata['createdBy'] = $context.Account.Id
    [string]$Metadata['createdOn'] = Get-Date -Format 'yyyy-MM-dd'

    Write-Output "[BUILD] Creating initiative definition..." -InformationAction Continue
    $params = @{
        PolicyDefinitions = $policies
        Parameters = $Parameters
        Metadata = $Metadata
    }
    [string]$InitiativeDefinition = Build-InitiativeDefinition @params

    Write-Output "[CREATE] Creating policy initiative: $InitiativeName" -InformationAction Continue
    $params = @{
        DisplayName = $DisplayName
        Subscription = $SubscriptionId
        Definition = $InitiativeDefinition
        Name = $InitiativeName
        Description = $Description
        ManagementGroup = $ManagementGroupName
    }
    [string]$initiative = New-PolicyInitiative @params

    if ($initiative) {
    $summary = Get-InitiativeSummary -Initiative $initiative
        Write-Output "`n[SUMMARY] Policy Initiative Created:" -InformationAction Continue
    [string]$summary | Format-List
    [string]$ExportPath = Export-InitiativeDefinition -Initiative $initiative
    }

    Write-Output "[COMPLETE] Policy initiative created successfully" -InformationAction Continue

    return $initiative
}
catch {
    $ErrorDetails = @{
        Message = $_.Exception.Message
        Category = $_.CategoryInfo.Category
        Line = $_.InvocationInfo.ScriptLineNumber
    }

    write-Error "Initiative creation failed: $($ErrorDetails.Message) at line $($ErrorDetails.Line)"
    throw
}
finally {
    [string]$ProgressPreference = 'Continue'}
