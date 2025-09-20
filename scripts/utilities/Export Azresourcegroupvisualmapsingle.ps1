#Requires -Version 7.0

<#`n.SYNOPSIS
    Export Azresourcegroupvisualmapsingle

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
This PowerShell script creates a visual map of a single Azure resource group.
This script generates a visual representation of the resources in an Azure resource group, including their dependencies and relationships.
Author: Wes Ellis
Date: April 6, 2023
Version: 1.0
.LINK
GitHub Repository: Azure Visualizations/Azure_Visual_Map.ps1
choco install graphviz
winget install graphviz
Install-Module -Name AzViz -Scope CurrentUser -Repository PSGallery -Force
Import-Module AzViz -Verbose
Connect-AzAccount
Export-AzViz -ResourceGroup demo-2 -Theme Neon -OutputFormat png -Show
