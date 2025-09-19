#Requires -Version 7.0
#Requires -Module Az.Resources

<#
.SYNOPSIS
    Invoke Azvmextension

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
    We Enhanced Invoke Azvmextension

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
function WE-Invoke-AzVMExtension {
}


$WEErrorActionPreference = "Stop"; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Invoke-AzVMExtension {
    
    #Region func Set-AzVMExtension -ErrorAction Stop 
; 
$setAzVMExtensionSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Location = $WELocationName
    VMName = $WEVMName
    Name = " AADLoginForWindows"
    Publisher = " Microsoft.Azure.ActiveDirectory"
    ExtensionType = " AADLoginForWindows"
    TypeHandlerVersion = " 1.0"
    # SettingString = $WESettingsString
}
Set-AzVMExtension -ErrorAction Stop @setAzVMExtensionSplat


    
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

