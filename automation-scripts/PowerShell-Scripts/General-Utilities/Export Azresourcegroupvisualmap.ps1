#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Export Azresourcegroupvisualmap

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Export Azresourcegroupvisualmap

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop" ; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
This PowerShell script creates a visual map of multiple Azure resource groups.

.DESCRIPTION
This script generates a visual representation of the resources in one or more Azure resource groups, including their dependencies and relationships.

.NOTES
Author: Wes Ellis
Date: April 6, 2023
Version: 1.0

.LINK
GitHub Repository: Azure Visualizations/Azure_Resource_Groups_Visualizer.ps1

.PARAMETER ResourceGroups
Specifies one or more Azure resource groups to visualize. You can specify multiple resource groups by separating them with a comma. For example:

.\ResourceGroupVisualMap.ps1 -ResourceGroups " myresourcegroup1, myresourcegroup2"







choco install graphviz


winget install graphviz


Install-Module -Name AzViz -Scope CurrentUser -Repository PSGallery -Force


Import-Module AzViz -Verbose


Connect-AzAccount


Export-AzViz -ResourceGroup demo-2, demo-3 -LabelVerbosity 1 -CategoryDepth 1 -Theme light -Show -OutputFormat png



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
