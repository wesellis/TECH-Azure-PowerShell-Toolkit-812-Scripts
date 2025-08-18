<#
.SYNOPSIS
    Installmodule

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Installmodule

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$safekitcmd,
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEMName,
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
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
			if($WEMName -and ($($WEMName.Length) -gt 0)) {
			; 	$modulename=$WEMName
			}else{
			; 	$modulename = $($_.name.Replace(" .safe" ,"" ))
			}
            
            & $safekitcmd module install -m $modulename $_.fullname
			if($modulecfgscript -and (Test-Path  " ./$modulecfgscript" )){
				& ./$modulecfgscript
			}
            & $safekitcmd -H " *" -E $modulename
        }
	}
} 



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
