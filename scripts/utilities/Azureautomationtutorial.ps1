#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Automation Tutorial Runbook

.DESCRIPTION
    An example runbook which gets all the Azure resources using the Run As Account (Service Principal)
    and displays them grouped by resource group

.PARAMETER ConnectionName
    Name of the Azure Run As Connection

.PARAMETER ResourceGroupFilter
    Optional filter for resource group names (supports wildcards)

.PARAMETER ResourceTypeFilter
    Optional filter for resource types

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Original Author: Azure Automation Team
    Version: 1.0
    Last Modified: Mar 14, 2016
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ConnectionName = "AzureRunAsConnection",

    [Parameter()]
    [string]$ResourceGroupFilter = "*",

    [Parameter()]
    [string[]]$ResourceTypeFilter = @()
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    # Connect to Azure using Run As Connection
    Write-Output "Connecting to Azure using Run As Connection '$ConnectionName'..."
    $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName -ErrorAction Stop

    $connectParams = @{
        ApplicationId = $servicePrincipalConnection.ApplicationId
        TenantId = $servicePrincipalConnection.TenantId
        CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    }

    Connect-AzAccount -ServicePrincipal @connectParams -ErrorAction Stop
    Write-Output "Successfully connected to Azure"

    # Get subscription information
    $context = Get-AzContext
    Write-Output "`nSubscription Information:"
    Write-Output "========================="
    Write-Output "Subscription Name: $($context.Subscription.Name)"
    Write-Output "Subscription ID: $($context.Subscription.Id)"
    Write-Output "Tenant ID: $($context.Tenant.Id)"
}
catch {
    if (!$servicePrincipalConnection) {
        $errorMessage = "Connection '$ConnectionName' not found. Please ensure the Run As Account is configured."
        Write-Error -Message $errorMessage
        throw $errorMessage
    } else {
        Write-Error -Message "Failed to connect to Azure: $($_.Exception.Message)"
        throw
    }
}

try {
    # Get resource groups
    Write-Output "`nRetrieving resource groups..."
    $resourceGroups = Get-AzResourceGroup -ErrorAction Stop

    # Apply resource group filter if specified
    if ($ResourceGroupFilter -ne "*") {
        $resourceGroups = $resourceGroups | Where-Object { $_.ResourceGroupName -like $ResourceGroupFilter }
        Write-Output "Applied resource group filter: $ResourceGroupFilter"
    }

    Write-Output "Found $($resourceGroups.Count) resource group(s)"

    # Initialize counters
    $totalResourceCount = 0
    $resourceTypeSummary = @{}

    # Process each resource group
    foreach ($resourceGroup in $resourceGroups) {
        Write-Output "`n================================="
        Write-Output "Resource Group: $($resourceGroup.ResourceGroupName)"
        Write-Output "Location: $($resourceGroup.Location)"
        Write-Output "Tags: $(if ($resourceGroup.Tags.Count -gt 0) { ($resourceGroup.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ' } else { 'None' })"
        Write-Output "---------------------------------"

        # Get resources in the resource group
        $resources = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName -ErrorAction SilentlyContinue

        # Apply resource type filter if specified
        if ($ResourceTypeFilter.Count -gt 0) {
            $resources = $resources | Where-Object { $ResourceTypeFilter -contains $_.ResourceType }
        }

        if ($resources.Count -gt 0) {
            Write-Output "Resources ($($resources.Count)):"

            foreach ($resource in $resources) {
                Write-Output "  • $($resource.Name)"
                Write-Output "    Type: $($resource.ResourceType)"
                Write-Output "    Location: $($resource.Location)"

                if ($resource.Tags.Count -gt 0) {
                    $tagString = ($resource.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
                    Write-Output "    Tags: $tagString"
                }

                # Update summary counters
                $totalResourceCount++
                if ($resourceTypeSummary.ContainsKey($resource.ResourceType)) {
                    $resourceTypeSummary[$resource.ResourceType]++
                } else {
                    $resourceTypeSummary[$resource.ResourceType] = 1
                }
            }
        } else {
            Write-Output "  No resources found in this resource group"
        }
    }

    # Display summary
    Write-Output "`n================================="
    Write-Output "SUMMARY"
    Write-Output "================================="
    Write-Output "Total Resource Groups: $($resourceGroups.Count)"
    Write-Output "Total Resources: $totalResourceCount"

    if ($resourceTypeSummary.Count -gt 0) {
        Write-Output "`nResources by Type:"
        $resourceTypeSummary.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
            Write-Output "  $($_.Key): $($_.Value)"
        }
    }

    Write-Output "`nRunbook execution completed successfully"
}
catch {
    Write-Error "Error occurred while retrieving resources: $($_.Exception.Message)"
    throw
}