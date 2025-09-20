#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Invoke Azvmextension

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
}\n

