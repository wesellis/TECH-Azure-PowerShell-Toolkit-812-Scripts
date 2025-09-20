#Requires -Version 7.0

<#`n.SYNOPSIS
    Windows Create Shortcut

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ShortcutName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ShortcutTargetPath,
    [Parameter()]
    $ShortcutArguments,
    [Parameter()]
    $ShortcutWorkingDirectory,
    [Parameter()]
    $ShortcutIcon,
    # defaults to Public Desktop if not provided
    [Parameter()]
    $ShortcutDestinationPath = [System.Environment]::GetFolderPath("CommonDesktopDirectory" ),
    [Parameter()]
    $EnableRunAsAdmin = $false
)
$newShortcutPath = $ShortcutDestinationPath + " \" + $ShortcutName + " .lnk"
if (-not (Test-Path -Path $ShortcutDestinationPath))
{
    New-Item -ItemType 'directory' -Path $ShortcutDestinationPath
}
if (-not (Test-Path -Path $newShortcutPath))
{
    # create the wshshell obhect
    $shell = New-Object -ComObject wscript.shell
$newShortcut = $shell.CreateShortcut($newShortcutPath)
    $newShortcut.TargetPath = $ShortcutTargetPath
    # save the shortcut
    Write-Host "Creating specified shortcut. Shortcut file: '$newShortcutPath'. Shortcut target path: '$($newShortcut.TargetPath)'"
    if ([System.String]::IsNullOrWhiteSpace($ShortcutArguments) -eq $false)
    {
        Write-Host "Using shortcut Arguments '$ShortcutArguments'."
        $newShortcut.Arguments = $ShortcutArguments
    }
    if (-not ([System.String]::IsNullOrWhiteSpace($ShortcutIcon)))
    {
        # can be " file" or " file, index" such as " notepad.exe, 0"
        $newShortcut.IconLocation = $ShortcutIcon
    }
    if (-not ([System.String]::IsNullOrWhiteSpace($ShortcutWorkingDirectory)))
    {
        $newShortcut.WorkingDirectory = $ShortcutWorkingDirectory
    }
    $newShortcut.Save()
    if ($EnableRunAsAdmin -eq $true)
    {
        Write-Host "Enabling $newShortcutPath to Run As Admin."
$bytes = [System.IO.File]::ReadAllBytes($newShortcutPath)
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes($newShortcutPath, $bytes)
    }
}
else
{
    Write-Warning "Specified shortcut already exists: $newShortcutPath"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
