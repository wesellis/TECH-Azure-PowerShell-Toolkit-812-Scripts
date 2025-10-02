#Requires -Version 7.4

<#
.SYNOPSIS
    Export visual map of a single Azure Resource Group.

.DESCRIPTION
    This PowerShell script creates a visual map of a single Azure resource group.
    It generates a visual representation of the resources in an Azure resource group,
    including their dependencies and relationships using the AzViz module.

.PARAMETER ResourceGroup
    Specifies the Azure resource group to visualize.

.PARAMETER LabelVerbosity
    Specifies the verbosity level for resource labels (0-2). Default is 1.

.PARAMETER CategoryDepth
    Specifies the depth of resource categorization. Default is 1.

.PARAMETER Theme
    Specifies the visual theme for the output. Options: light, dark, neon. Default is light.

.PARAMETER OutputFormat
    Specifies the output format. Options: png, svg, pdf. Default is png.

.PARAMETER Show
    Switch to automatically open the generated visualization.

.PARAMETER OutputPath
    Specifies the output directory for the generated files. Default is current directory.

.EXAMPLE
    .\Export-Azresourcegroupvisualmapsingle.ps1 -ResourceGroup "demo-rg"

.EXAMPLE
    .\Export-Azresourcegroupvisualmapsingle.ps1 -ResourceGroup "demo-2" -Theme Neon -OutputFormat png -Show

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Date: April 6, 2023
    Version: 1.0
    Requires appropriate permissions and modules

    Prerequisites:
    - Install Graphviz: choco install graphviz OR winget install graphviz
    - Install AzViz module: Install-Module -Name AzViz -Scope CurrentUser -Repository PSGallery -Force
    - Connect to Azure: Connect-AzAccount

.LINK
    GitHub Repository: Azure Visualizations/Azure_Visual_Map.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 2)]
    [int]$LabelVerbosity = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3)]
    [int]$CategoryDepth = 1,

    [Parameter(Mandatory = $false)]
    [ValidateSet("light", "dark", "neon")]
    [string]$Theme = "light",

    [Parameter(Mandatory = $false)]
    [ValidateSet("png", "svg", "pdf")]
    [string]$OutputFormat = "png",

    [Parameter(Mandatory = $false)]
    [switch]$Show,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "."
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    Write-Output "Starting Azure Resource Group visualization process for single resource group..."

    # Check if AzViz module is installed
    if (-not (Get-Module -ListAvailable -Name AzViz)) {
        Write-Warning "AzViz module is not installed. Installing now..."
        Install-Module -Name AzViz -Scope CurrentUser -Repository PSGallery -Force
    }

    # Import the AzViz module
    Write-Output "Importing AzViz module..."
    Import-Module AzViz -Verbose

    # Check if connected to Azure
    $context = Get-AzContext
    if (-not $context) {
        Write-Output "Not connected to Azure. Please connect first..."
        Connect-AzAccount
    }

    # Validate resource group exists
    Write-Output "Validating resource group '$ResourceGroup'..."
    $resourceGroupObj = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
    if (-not $resourceGroupObj) {
        throw "Resource group '$ResourceGroup' not found or you don't have access to it."
    }
    Write-Output "✓ Resource group '$ResourceGroup' found in location '$($resourceGroupObj.Location)'"

    # Generate the visualization
    Write-Output "Generating visual map for resource group: $ResourceGroup"
    Write-Output "Configuration:"
    Write-Output "  - Label Verbosity: $LabelVerbosity"
    Write-Output "  - Category Depth: $CategoryDepth"
    Write-Output "  - Theme: $Theme"
    Write-Output "  - Output Format: $OutputFormat"
    Write-Output "  - Output Path: $OutputPath"

    $vizParams = @{
        ResourceGroup = $ResourceGroup
        LabelVerbosity = $LabelVerbosity
        CategoryDepth = $CategoryDepth
        Theme = $Theme
        OutputFormat = $OutputFormat
    }

    if ($Show) {
        $vizParams.Show = $true
    }

    if ($OutputPath -ne ".") {
        $vizParams.OutputFilePath = $OutputPath
    }

    Export-AzViz @vizParams

    Write-Output "Azure Resource Group visual map generated successfully!"
    Write-Output "Resource Group: $ResourceGroup"
    Write-Output "Check the output directory for the generated visualization file(s)."
}
catch {
    Write-Error "Failed to generate Azure Resource Group visual map: $($_.Exception.Message)"
    throw
}