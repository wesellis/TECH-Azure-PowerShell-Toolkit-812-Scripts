#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Windows Create Shortcut

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
    We Enhanced Windows Create Shortcut

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

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
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $WEShortcutName,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $WEShortcutTargetPath,

    [Parameter(Mandatory=$false)]
    $WEShortcutArguments,

    [Parameter(Mandatory=$false)]
    $WEShortcutWorkingDirectory,

    [Parameter(Mandatory=$false)]
    $WEShortcutIcon,

    # defaults to Public Desktop if not provided
    [Parameter(Mandatory=$false)]
    $WEShortcutDestinationPath = [System.Environment]::GetFolderPath(" CommonDesktopDirectory" ),

    [Parameter(Mandatory=$false)]
    $WEEnableRunAsAdmin = $false
)

#region Functions


$newShortcutPath = $WEShortcutDestinationPath + " \" + $WEShortcutName + " .lnk"
if (-not (Test-Path -Path $WEShortcutDestinationPath))
{
    New-Item -ItemType 'directory' -Path $WEShortcutDestinationPath
}




if (-not (Test-Path -Path $newShortcutPath))
{
    # create the wshshell obhect
    $shell = New-Object -ComObject wscript.shell
        
   ;  $newShortcut = $shell.CreateShortcut($newShortcutPath)
    $newShortcut.TargetPath = $WEShortcutTargetPath

    # save the shortcut
    Write-WELog " Creating specified shortcut. Shortcut file: '$newShortcutPath'. Shortcut target path: '$($newShortcut.TargetPath)'" " INFO"
    
    if ([System.String]::IsNullOrWhiteSpace($WEShortcutArguments) -eq $false) 
    {
        Write-WELog " Using shortcut Arguments '$WEShortcutArguments'." " INFO"
        $newShortcut.Arguments = $WEShortcutArguments
    }

    if (-not ([System.String]::IsNullOrWhiteSpace($WEShortcutIcon)))
    {
        # can be " file" or " file, index" such as " notepad.exe, 0"
        $newShortcut.IconLocation = $WEShortcutIcon
    }

    if (-not ([System.String]::IsNullOrWhiteSpace($WEShortcutWorkingDirectory)))
    {
        $newShortcut.WorkingDirectory = $WEShortcutWorkingDirectory
    }

    $newShortcut.Save()

    if ($WEEnableRunAsAdmin -eq $true)
    {
        Write-WELog " Enabling $newShortcutPath to Run As Admin." " INFO"
       ;  $bytes = [System.IO.File]::ReadAllBytes($newShortcutPath)
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes($newShortcutPath, $bytes)
    }
}
else
{
    Write-Warning " Specified shortcut already exists: $newShortcutPath"
}


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
