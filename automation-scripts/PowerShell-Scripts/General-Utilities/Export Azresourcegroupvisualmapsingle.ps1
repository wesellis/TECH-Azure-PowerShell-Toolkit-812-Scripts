#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Export Azresourcegroupvisualmapsingle

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
    We Enhanced Export Azresourcegroupvisualmapsingle

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
This PowerShell script creates a visual map of a single Azure resource group.

.DESCRIPTION
This script generates a visual representation of the resources in an Azure resource group, including their dependencies and relationships.

.NOTES
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



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
