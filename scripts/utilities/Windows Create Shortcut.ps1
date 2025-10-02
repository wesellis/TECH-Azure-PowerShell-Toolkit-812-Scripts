#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Create Shortcut

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
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
    [Parameter()]
    $ShortcutDestinationPath = [System.Environment]::GetFolderPath("CommonDesktopDirectory" ),
    [Parameter()]
    $EnableRunAsAdmin = $false
)
    $NewShortcutPath = $ShortcutDestinationPath + " \" + $ShortcutName + " .lnk"
if (-not (Test-Path -Path $ShortcutDestinationPath))
{
    New-Item -ItemType 'directory' -Path $ShortcutDestinationPath
}
if (-not (Test-Path -Path $NewShortcutPath))
{
    $shell = New-Object -ComObject wscript.shell
    $NewShortcut = $shell.CreateShortcut($NewShortcutPath)
    $NewShortcut.TargetPath = $ShortcutTargetPath
    Write-Output "Creating specified shortcut. Shortcut file: '$NewShortcutPath'. Shortcut target path: '$($NewShortcut.TargetPath)'"
    if ([System.String]::IsNullOrWhiteSpace($ShortcutArguments) -eq $false)
    {
        Write-Output "Using shortcut Arguments '$ShortcutArguments'."
    $NewShortcut.Arguments = $ShortcutArguments
    }
    if (-not ([System.String]::IsNullOrWhiteSpace($ShortcutIcon)))
    {
    $NewShortcut.IconLocation = $ShortcutIcon
    }
    if (-not ([System.String]::IsNullOrWhiteSpace($ShortcutWorkingDirectory)))
    {
    $NewShortcut.WorkingDirectory = $ShortcutWorkingDirectory
    }
    $NewShortcut.Save()
    if ($EnableRunAsAdmin -eq $true)
    {
        Write-Output "Enabling $NewShortcutPath to Run As Admin."
    $bytes = [System.IO.File]::ReadAllBytes($NewShortcutPath)
    $bytes[0x15] = $bytes[0x15] -bor 0x20
        [System.IO.File]::WriteAllBytes($NewShortcutPath, $bytes)
    }
}
else
{
    Write-Warning "Specified shortcut already exists: $NewShortcutPath"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
