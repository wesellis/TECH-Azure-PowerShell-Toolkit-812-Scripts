<#
.SYNOPSIS
    Installmodule

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
	[Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$safekitcmd,
	[Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$MName,
	[Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$modulepkg,
	[string]$modulecfgscript
)
if( $modulepkg ){
    $module = $modulepkg.Split(',') | Get-ChildItem -ErrorAction Stop
}
else{
    $module = [array] (Get-ChildItem -ErrorAction Stop " *.safe" )
}
if($module.Length){
	$module[0] | %{
        if($_){
			if($MName -and ($($MName.Length) -gt 0)) {
$modulename=$MName
			}else{
$modulename = $($_.name.Replace(" .safe" ,"" ))
			}
            & $safekitcmd module install -m $modulename $_.fullname
			if($modulecfgscript -and (Test-Path  " ./$modulecfgscript" )){
				& ./$modulecfgscript
			}
            & $safekitcmd -H "*" -E $modulename
        }
	}
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n