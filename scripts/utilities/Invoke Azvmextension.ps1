#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Invoke Azvmextension

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzVMExtension {
}
$ErrorActionPreference = "Stop";
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzVMExtension {
    #region func-Set-AzVMExtension -ErrorAction Stop
$setAzVMExtensionSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $LocationName
    VMName = $VMName
    Name = "AADLoginForWindows"
    Publisher = "Microsoft.Azure.ActiveDirectory"
    ExtensionType = "AADLoginForWindows"
    TypeHandlerVersion = " 1.0"
    # SettingString = $SettingsString
}
Set-AzVMExtension -ErrorAction Stop @setAzVMExtensionSplat
}


