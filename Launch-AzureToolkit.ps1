#Requires -Version 7.0
<#
.SYNOPSIS
    Launch AzureToolkit
.DESCRIPTION
    NOTES
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding(SupportsShouldProcess)]

    [switch]$GUI,
    [switch]$ListOnly,
    [string]$SearchTerm,
    [string]$Category,
    [switch]$Favorites
)


$Global:ToolkitPath = $PSScriptRoot
$Global:ConfigPath = Join-Path $env:USERPROFILE ".azure-toolkit"
$Global:FavoritesFile = Join-Path $Global:ConfigPath "favorites.json"
$Global:HistoryFile = Join-Path $Global:ConfigPath "history.json"

if (-not (Test-Path $Global:ConfigPath)) {
    New-Item -ItemType Directory -Path $Global:ConfigPath -Force | Out-Null
}

class ScriptLauncher {
    [array]$Scripts = @()
    [hashtable]$Categories = @{}
    [array]$Favorites = @()
    [array]$History = @()

    ScriptLauncher() {
        $this.LoadScripts()
        $this.LoadFavorites()
        $this.LoadHistory()
    }

    [void] LoadScripts() {
        Write-Host "Loading scripts..." -ForegroundColor Green
        $ScriptFiles = Get-ChildItem -Path (Join-Path $Global:ToolkitPath "automation-scripts") -Filter "*.ps1" -Recurse

        foreach ($script in $ScriptFiles) {
            $category = Split-Path (Split-Path $script.FullName -Parent) -Leaf
            $ScriptInfo = @{
                Name = $script.BaseName
                Path = $script.FullName
                Category = $category
                Description = $this.ExtractDescription($script.FullName)
                Parameters = $this.ExtractParameters($script.FullName)
                LastUsed = $null
                UsageCount = 0
            }

            $this.Scripts += $ScriptInfo

            if (-not $this.Categories.ContainsKey($category)) {
                $this.Categories[$category] = @()
            }
            $this.Categories[$category] += $ScriptInfo
        }
    }

    [string] ExtractDescription([string]$ScriptPath) {
        $content = Get-Content $ScriptPath -Raw -ErrorAction SilentlyContinue
        if ($content -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|$)') {
            return $Matches[1].Trim()
        }
        if ($content -match '# Description: (.+)') {
            return $Matches[1].Trim()
        }
        return "No description available"
    }

    [array] ExtractParameters([string]$ScriptPath) {
        $params = @()
        $content = Get-Content $ScriptPath -Raw -ErrorAction SilentlyContinue
        $ParamMatches = [regex]::Matches($content, '\[Parameter.*?\]\s*\[.*?\]\s*\$(\w+)')
        foreach ($match in $ParamMatches) {
            $params += $match.Groups[1].Value
        }
        return $params
    }

    [void] LoadFavorites() {
        if (Test-Path $Global:FavoritesFile) {
            $this.Favorites = Get-Content $Global:FavoritesFile | ConvertFrom-Json
        }
    }

    [void] SaveFavorites() {
        $this.Favorites | ConvertTo-Json | Out-File $Global:FavoritesFile -Encoding UTF8
    }

    [void] LoadHistory() {
        if (Test-Path $Global:HistoryFile) {
            $this.History = Get-Content $Global:HistoryFile | ConvertFrom-Json
        }
    }

    [void] SaveHistory() {
        if ($this.History.Count -gt 100) {
            $this.History = $this.History | Select-Object -Last 100
        }
        $this.History | ConvertTo-Json | Out-File $Global:HistoryFile -Encoding UTF8
    }

    [void] ShowInteractiveMenu() {
        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host @"

�         Azure Enterprise Toolkit - Script Launcher          �
�                    Version 2.0 Enhanced                     �

"@ -ForegroundColor Cyan

        $continue = $true
        while ($continue) {
            Write-Host "`nMain Menu:" -ForegroundColor Green
            Write-Host "1. Browse by Category" -ForegroundColor Green
            Write-Host "2. Search Scripts" -ForegroundColor Green
            Write-Host "3. View Favorites" -ForegroundColor Green
            Write-Host "4. Recent History" -ForegroundColor Green
            Write-Host "5. Quick Launch (by ID)" -ForegroundColor Green
            Write-Host "6. Script Statistics" -ForegroundColor Green
            Write-Host "7. Configuration" -ForegroundColor Green
            Write-Host "Q. Quit" -ForegroundColor Green

            $choice = Read-Host "`nSelect option"

            switch ($choice.ToUpper()) {
                "1" { $this.BrowseByCategory() }
                "2" { $this.SearchScripts() }
                "3" { $this.ViewFavorites() }
                "4" { $this.ShowHistory() }
                "5" { $this.QuickLaunch() }
                "6" { $this.ShowStatistics() }
                "7" { $this.Configuration() }
                "Q" { $continue = $false }
                default { Write-Host "Invalid option" -ForegroundColor Green }
            }
        }
    }

    [void] BrowseByCategory() {
        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host "Categories:" -ForegroundColor Green
        $i = 1
        $CategoryList = $this.Categories.Keys | Sort-Object
        foreach ($cat in $CategoryList) {
            Write-Host "$i. $cat ($($this.Categories[$cat].Count) scripts)" -ForegroundColor Green
            $i++
        }

        $selection = Read-Host "`nSelect category (number) or B to go back"
        if ($selection -eq "B") { return }

        $SelectedCategory = $CategoryList[$([int]$selection - 1)]
        if ($SelectedCategory) {
            $this.ShowScriptsInCategory($SelectedCategory)
        }
    }

    [void] ShowScriptsInCategory([string]$Category) {
        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host "Scripts in $Category:" -ForegroundColor Green
        $scripts = $this.Categories[$Category] | Sort-Object Name

        for ($i = 0; $i -lt $scripts.Count; $i++) {
            $script = $scripts[$i]
            $star = if ($script.Path -in $this.Favorites) { "[*]" } else { "  " }
            Write-Host "$star $($i + 1). $($script.Name)" -ForegroundColor Green
            Write-Host "     $($script.Description)" -ForegroundColor Green
        }

        Write-Host "`nOptions: [number] to run, [F+number] to favorite, [I+number] for info, [B] back" -ForegroundColor Green
        $selection = Read-Host "Selection"

        if ($selection -eq "B") { return }
        elseif ($selection -match "^F(\d+)$") {
            $index = [int]$Matches[1] - 1
            if ($index -ge 0 -and $index -lt $scripts.Count) {
                $this.ToggleFavorite($scripts[$index].Path)
            }
            $this.ShowScriptsInCategory($Category)
        }
        elseif ($selection -match "^I(\d+)$") {
            $index = [int]$Matches[1] - 1
            if ($index -ge 0 -and $index -lt $scripts.Count) {
                $this.ShowScriptInfo($scripts[$index])
            }
            $this.ShowScriptsInCategory($Category)
        }
        elseif ($selection -match "^\d+$") {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $scripts.Count) {
                $this.LaunchScript($scripts[$index])
            }
        }
    }

    [void] SearchScripts() {
        $SearchTerm = Read-Host "Enter search term"
        $results = $this.Scripts | Where-Object {
            $_.Name -like "*$SearchTerm*" -or
            $_.Description -like "*$SearchTerm*" -or
            $_.Category -like "*$SearchTerm*"
        }

        if ($results.Count -eq 0) {
            Write-Host "No scripts found matching '$SearchTerm'" -ForegroundColor Green
            return
        }

        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host "Search Results for '$SearchTerm':" -ForegroundColor Green
        for ($i = 0; $i -lt $results.Count; $i++) {
            $script = $results[$i]
            Write-Host "$($i + 1). [$($script.Category)] $($script.Name)" -ForegroundColor Green
            Write-Host "    $($script.Description)" -ForegroundColor Green
        }

        $selection = Read-Host "`nSelect script number to run or B to go back"
        if ($selection -ne "B" -and $selection -match "^\d+$") {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $results.Count) {
                $this.LaunchScript($results[$index])
            }
        }
    }

    [void] LaunchScript([hashtable]$Script) {
        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host "Launching: $($Script.Name)" -ForegroundColor Green
        Write-Host "Description: $($Script.Description)" -ForegroundColor Green

        if ($Script.Parameters.Count -gt 0) {
            Write-Host "`nParameters:" -ForegroundColor Green
            $ParamValues = @{}
            foreach ($param in $Script.Parameters) {
                $value = Read-Host "  -$param"
                if ($value) {
                    $ParamValues[$param] = $value
                }
            }
        }

        $HistoryEntry = @{
            ScriptPath = $Script.Path
            ScriptName = $Script.Name
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Parameters = $ParamValues
        }
        $this.History += $HistoryEntry
        $this.SaveHistory()

        Write-Host "`nExecuting script..." -ForegroundColor Green

        try {
            if ($ParamValues -and $ParamValues.Count -gt 0) {
                & $Script.Path @paramValues
            } else {
                & $Script.Path
            }
            Write-Host "`nScript completed successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Error executing script: $_" -ForegroundColor Green
        }

        Read-Host "`nPress Enter to continue"
    }

    [void] ToggleFavorite([string]$ScriptPath) {
        if ($ScriptPath -in $this.Favorites) {
            $this.Favorites = $this.Favorites | Where-Object { $_ -ne $ScriptPath }
            Write-Host "Removed from favorites" -ForegroundColor Green
        } else {
            $this.Favorites += $ScriptPath
            Write-Host "Added to favorites" -ForegroundColor Green
        }
        $this.SaveFavorites()
    }

    [void] ViewFavorites() {
        if ($this.Favorites.Count -eq 0) {
            Write-Host "No favorites yet. Add favorites by pressing F+number when browsing scripts." -ForegroundColor Green
            Read-Host "Press Enter to continue"
            return
        }

        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host "Favorite Scripts:" -ForegroundColor Green
        $FavScripts = $this.Scripts | Where-Object { $_.Path -in $this.Favorites }

        for ($i = 0; $i -lt $FavScripts.Count; $i++) {
            $script = $FavScripts[$i]
            Write-Host "$($i + 1). [$($script.Category)] $($script.Name)" -ForegroundColor Green
            Write-Host "    $($script.Description)" -ForegroundColor Green
        }

        $selection = Read-Host "`nSelect script number to run or B to go back"
        if ($selection -ne "B" -and $selection -match "^\d+$") {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $FavScripts.Count) {
                $this.LaunchScript($FavScripts[$index])
            }
        }
    }

    [void] ShowHistory() {
        if ($this.History.Count -eq 0) {
            Write-Host "No history yet." -ForegroundColor Green
            Read-Host "Press Enter to continue"
            return
        }

        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host "Recent Script Executions:" -ForegroundColor Green
        $recent = $this.History | Select-Object -Last 10

        for ($i = 0; $i -lt $recent.Count; $i++) {
            $entry = $recent[$i]
            Write-Host "$($i + 1). $($entry.ScriptName) - $($entry.Timestamp)" -ForegroundColor Green
        }

        Read-Host "`nPress Enter to continue"
    }

    [void] ShowStatistics() {
        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host "Repository Statistics:" -ForegroundColor Green
        Write-Host "Total Scripts: $($this.Scripts.Count)" -ForegroundColor Green
        Write-Host "Categories: $($this.Categories.Count)" -ForegroundColor Green
        Write-Host "Favorites: $($this.Favorites.Count)" -ForegroundColor Green
        Write-Host "History Entries: $($this.History.Count)" -ForegroundColor Green

        Write-Host "`nTop Categories:" -ForegroundColor Green
        $TopCategories = $this.Categories.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 5
        foreach ($cat in $TopCategories) {
            Write-Host "  $($cat.Key): $($cat.Value.Count) scripts" -ForegroundColor Green
        }

        Read-Host "`nPress Enter to continue"
    }

    [void] ShowScriptInfo([hashtable]$Script) {
        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host "Script Information:" -ForegroundColor Green
        Write-Host "Name: $($Script.Name)" -ForegroundColor Green
        Write-Host "Category: $($Script.Category)" -ForegroundColor Green
        Write-Host "Path: $($Script.Path)" -ForegroundColor Green
        Write-Host "Description: $($Script.Description)" -ForegroundColor Green

        if ($Script.Parameters.Count -gt 0) {
            Write-Host "`nParameters:" -ForegroundColor Green
            foreach ($param in $Script.Parameters) {
                Write-Host "  -$param" -ForegroundColor Green
            }
        }

        Read-Host "`nPress Enter to continue"
    }

    [void] QuickLaunch() {
        $ScriptName = Read-Host "Enter script name (partial match supported)"
        $matches = $this.Scripts | Where-Object { $_.Name -like "*$ScriptName*" }

        if ($matches.Count -eq 0) {
            Write-Host "No scripts found" -ForegroundColor Green
        } elseif ($matches.Count -eq 1) {
            $this.LaunchScript($matches[0])
        } else {
            Write-Host "Multiple matches found:" -ForegroundColor Green
            for ($i = 0; $i -lt $matches.Count; $i++) {
                Write-Host "$($i + 1). $($matches[$i].Name)" -ForegroundColor Green
            }
            $selection = Read-Host "Select number"
            if ($selection -match "^\d+$") {
                $index = [int]$selection - 1
                if ($index -ge 0 -and $index -lt $matches.Count) {
                    $this.LaunchScript($matches[$index])
                }
            }
        }
    }

    [void] Configuration() {
        if ($PSCmdlet.ShouldProcess("target", "operation")) {

    }
        Write-Host "Configuration:" -ForegroundColor Green
        Write-Host "1. Clear History" -ForegroundColor Green
        Write-Host "2. Clear Favorites" -ForegroundColor Green
        Write-Host "3. Export Configuration" -ForegroundColor Green
        Write-Host "4. Import Configuration" -ForegroundColor Green
        Write-Host "B. Back" -ForegroundColor Green

        $choice = Read-Host "Select option"
        switch ($choice) {
            "1" {
                $this.History = @()
                $this.SaveHistory()
                Write-Host "History cleared" -ForegroundColor Green
            }
            "2" {
                $this.Favorites = @()
                $this.SaveFavorites()
                Write-Host "Favorites cleared" -ForegroundColor Green
            }
            "3" {
                $ExportPath = Read-Host "Enter export path"
                @{
                    Favorites = $this.Favorites
                    History = $this.History
                } | ConvertTo-Json | Out-File $ExportPath -Encoding UTF8
                Write-Host "Configuration exported" -ForegroundColor Green
            }
            "4" {
                $ImportPath = Read-Host "Enter import path"
                if (Test-Path $ImportPath) {
                    $config = Get-Content $ImportPath | ConvertFrom-Json
                    $this.Favorites = $config.Favorites
                    $this.History = $config.History
                    $this.SaveFavorites()
                    $this.SaveHistory()
                    Write-Host "Configuration imported" -ForegroundColor Green
                }
            }
        }

        if ($choice -ne "B") {
            Read-Host "Press Enter to continue"
        }
    }
}

$launcher = [ScriptLauncher]::new()

if ($ListOnly) {
    $launcher.Scripts | Format-Table Name, Category, Description -AutoSize
} elseif ($SearchTerm) {
    $results = $launcher.Scripts | Where-Object {
        $_.Name -like "*$SearchTerm*" -or
        $_.Description -like "*$SearchTerm*" -or
        $_.Category -like "*$SearchTerm*"
    }
    $results | Format-Table Name, Category, Description -AutoSize
} elseif ($Category) {
    if ($launcher.Categories.ContainsKey($Category)) {
        $launcher.Categories[$Category] | Format-Table Name, Description -AutoSize
    } else {
        Write-Host "Category not found: $Category" -ForegroundColor Green
    }
} elseif ($Favorites) {
    $FavScripts = $launcher.Scripts | Where-Object { $_.Path -in $launcher.Favorites }
    $FavScripts | Format-Table Name, Category, Description -AutoSize
} else {
    $launcher.ShowInteractiveMenu()
}

Write-Host "`nThank you for using Azure Enterprise Toolkit!" -ForegroundColor Green



