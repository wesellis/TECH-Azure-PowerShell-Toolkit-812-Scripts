#Requires -Version 7.4

<#
.SYNOPSIS
    Export visual map of Azure Resource Groups.

.DESCRIPTION
    This PowerShell script creates a visual map of multiple Azure resource groups.
    It generates a visual representation of the resources in one or more Azure resource groups,
    including their dependencies and relationships using the AzViz module.

.PARAMETER ResourceGroups
    Specifies one or more Azure resource groups to visualize. You can specify multiple
    resource groups by separating them with a comma.

.PARAMETER LabelVerbosity
    Specifies the verbosity level for resource labels (0-2). Default is 1.

.PARAMETER CategoryDepth
    Specifies the depth of resource categorization. Default is 1.

.PARAMETER Theme
    Specifies the visual theme for the output. Options: light, dark. Default is light.

.PARAMETER OutputFormat
    Specifies the output format. Options: png, svg, pdf. Default is png.

.PARAMETER Show
    Switch to automatically open the generated visualization.

.PARAMETER OutputPath
    Specifies the output directory for the generated files. Default is current directory.

.EXAMPLE
    .\Export-Azresourcegroupvisualmap.ps1 -ResourceGroups "myresourcegroup1,myresourcegroup2"

.EXAMPLE
    .\Export-Azresourcegroupvisualmap.ps1 -ResourceGroups "demo-rg" -Theme dark -OutputFormat svg -Show

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
    GitHub Repository: Azure Visualizations/Azure_Resource_Groups_Visualizer.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ResourceGroups,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 2)]
    [int]$LabelVerbosity = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3)]
    [int]$CategoryDepth = 1,

    [Parameter(Mandatory = $false)]
    [ValidateSet("light", "dark")]
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
    Write-Output "Starting Azure Resource Group visualization process..."

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

    # Validate resource groups exist
    Write-Output "Validating resource groups..."
    foreach ($rg in $ResourceGroups) {
        $rgTrimmed = $rg.Trim()
        $resourceGroup = Get-AzResourceGroup -Name $rgTrimmed -ErrorAction SilentlyContinue
        if (-not $resourceGroup) {
            throw "Resource group '$rgTrimmed' not found or you don't have access to it."
        }
        Write-Output "✓ Resource group '$rgTrimmed' found"
    }

    # Generate the visualization
    Write-Output "Generating visual map for resource groups: $($ResourceGroups -join ', ')"
    Write-Output "Configuration:"
    Write-Output "  - Label Verbosity: $LabelVerbosity"
    Write-Output "  - Category Depth: $CategoryDepth"
    Write-Output "  - Theme: $Theme"
    Write-Output "  - Output Format: $OutputFormat"
    Write-Output "  - Output Path: $OutputPath"

    $vizParams = @{
        ResourceGroup = $ResourceGroups
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
    Write-Output "Check the output directory for the generated visualization file(s)."
}
catch {
    Write-Error "Failed to generate Azure Resource Group visual map: $($_.Exception.Message)"
    throw
}