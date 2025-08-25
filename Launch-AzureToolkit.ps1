# Launch-AzureToolkit.ps1
# Interactive CLI launcher for Azure Enterprise Toolkit scripts
# Author: Wesley Ellis | Enhanced by AI
# Version: 2.0

param(
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

# Ensure config directory exists
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
        Write-Host "Loading scripts..." -ForegroundColor Cyan
        $scriptFiles = Get-ChildItem -Path (Join-Path $Global:ToolkitPath "automation-scripts") -Filter "*.ps1" -Recurse
        
        foreach ($script in $scriptFiles) {
            $category = Split-Path (Split-Path $script.FullName -Parent) -Leaf
            $scriptInfo = @{
                Name = $script.BaseName
                Path = $script.FullName
                Category = $category
                Description = $this.ExtractDescription($script.FullName)
                Parameters = $this.ExtractParameters($script.FullName)
                LastUsed = $null
                UsageCount = 0
            }
            
            $this.Scripts += $scriptInfo
            
            if (-not $this.Categories.ContainsKey($category)) {
                $this.Categories[$category] = @()
            }
            $this.Categories[$category] += $scriptInfo
        }
    }
    
    [string] ExtractDescription([string]$ScriptPath) {
        $content = Get-Content $ScriptPath -Raw -ErrorAction SilentlyContinue
        if ($content -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|$)') {
            return $Matches[1].Trim()
        }
        if ($content -match '# Description:\s*(.+)') {
            return $Matches[1].Trim()
        }
        return "No description available"
    }
    
    [array] ExtractParameters([string]$ScriptPath) {
        $params = @()
        $content = Get-Content $ScriptPath -Raw -ErrorAction SilentlyContinue
        $paramMatches = [regex]::Matches($content, '\[Parameter.*?\]\s*\[.*?\]\s*\$(\w+)')
        foreach ($match in $paramMatches) {
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
        # Keep only last 100 entries
        if ($this.History.Count -gt 100) {
            $this.History = $this.History | Select-Object -Last 100
        }
        $this.History | ConvertTo-Json | Out-File $Global:HistoryFile -Encoding UTF8
    }
    
    [void] ShowInteractiveMenu() {
        Clear-Host
        Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║         Azure Enterprise Toolkit - Script Launcher          ║
║                    Version 2.0 Enhanced                     ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
        
        $continue = $true
        while ($continue) {
            Write-Host "`nMain Menu:" -ForegroundColor Yellow
            Write-Host "1. Browse by Category" -ForegroundColor White
            Write-Host "2. Search Scripts" -ForegroundColor White
            Write-Host "3. View Favorites" -ForegroundColor White
            Write-Host "4. Recent History" -ForegroundColor White
            Write-Host "5. Quick Launch (by ID)" -ForegroundColor White
            Write-Host "6. Script Statistics" -ForegroundColor White
            Write-Host "7. Configuration" -ForegroundColor White
            Write-Host "Q. Quit" -ForegroundColor White
            
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
                default { Write-Host "Invalid option" -ForegroundColor Red }
            }
        }
    }
    
    [void] BrowseByCategory() {
        Clear-Host
        Write-Host "Categories:" -ForegroundColor Cyan
        $i = 1
        $categoryList = $this.Categories.Keys | Sort-Object
        foreach ($cat in $categoryList) {
            Write-Host "$i. $cat ($($this.Categories[$cat].Count) scripts)" -ForegroundColor Yellow
            $i++
        }
        
        $selection = Read-Host "`nSelect category (number) or B to go back"
        if ($selection -eq "B") { return }
        
        $selectedCategory = $categoryList[$([int]$selection - 1)]
        if ($selectedCategory) {
            $this.ShowScriptsInCategory($selectedCategory)
        }
    }
    
    [void] ShowScriptsInCategory([string]$Category) {
        Clear-Host
        Write-Host "Scripts in $Category:" -ForegroundColor Cyan
        $scripts = $this.Categories[$Category] | Sort-Object Name
        
        for ($i = 0; $i -lt $scripts.Count; $i++) {
            $script = $scripts[$i]
            $star = if ($script.Path -in $this.Favorites) { "⭐" } else { "  " }
            Write-Host "$star $($i + 1). $($script.Name)" -ForegroundColor White
            Write-Host "     $($script.Description)" -ForegroundColor Gray
        }
        
        Write-Host "`nOptions: [number] to run, [F+number] to favorite, [I+number] for info, [B] back" -ForegroundColor Yellow
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
        $searchTerm = Read-Host "Enter search term"
        $results = $this.Scripts | Where-Object {
            $_.Name -like "*$searchTerm*" -or
            $_.Description -like "*$searchTerm*" -or
            $_.Category -like "*$searchTerm*"
        }
        
        if ($results.Count -eq 0) {
            Write-Host "No scripts found matching '$searchTerm'" -ForegroundColor Yellow
            return
        }
        
        Clear-Host
        Write-Host "Search Results for '$searchTerm':" -ForegroundColor Cyan
        for ($i = 0; $i -lt $results.Count; $i++) {
            $script = $results[$i]
            Write-Host "$($i + 1). [$($script.Category)] $($script.Name)" -ForegroundColor White
            Write-Host "    $($script.Description)" -ForegroundColor Gray
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
        Clear-Host
        Write-Host "Launching: $($Script.Name)" -ForegroundColor Cyan
        Write-Host "Description: $($Script.Description)" -ForegroundColor Gray
        
        # Show parameters if any
        if ($Script.Parameters.Count -gt 0) {
            Write-Host "`nParameters:" -ForegroundColor Yellow
            $paramValues = @{}
            foreach ($param in $Script.Parameters) {
                $value = Read-Host "  -$param"
                if ($value) {
                    $paramValues[$param] = $value
                }
            }
        }
        
        # Add to history
        $historyEntry = @{
            ScriptPath = $Script.Path
            ScriptName = $Script.Name
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Parameters = $paramValues
        }
        $this.History += $historyEntry
        $this.SaveHistory()
        
        Write-Host "`nExecuting script..." -ForegroundColor Green
        
        try {
            if ($paramValues -and $paramValues.Count -gt 0) {
                & $Script.Path @paramValues
            } else {
                & $Script.Path
            }
            Write-Host "`nScript completed successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Error executing script: $_" -ForegroundColor Red
        }
        
        Read-Host "`nPress Enter to continue"
    }
    
    [void] ToggleFavorite([string]$ScriptPath) {
        if ($ScriptPath -in $this.Favorites) {
            $this.Favorites = $this.Favorites | Where-Object { $_ -ne $ScriptPath }
            Write-Host "Removed from favorites" -ForegroundColor Yellow
        } else {
            $this.Favorites += $ScriptPath
            Write-Host "Added to favorites" -ForegroundColor Green
        }
        $this.SaveFavorites()
    }
    
    [void] ViewFavorites() {
        if ($this.Favorites.Count -eq 0) {
            Write-Host "No favorites yet. Add favorites by pressing F+number when browsing scripts." -ForegroundColor Yellow
            Read-Host "Press Enter to continue"
            return
        }
        
        Clear-Host
        Write-Host "Favorite Scripts:" -ForegroundColor Cyan
        $favScripts = $this.Scripts | Where-Object { $_.Path -in $this.Favorites }
        
        for ($i = 0; $i -lt $favScripts.Count; $i++) {
            $script = $favScripts[$i]
            Write-Host "$($i + 1). [$($script.Category)] $($script.Name)" -ForegroundColor Yellow
            Write-Host "    $($script.Description)" -ForegroundColor Gray
        }
        
        $selection = Read-Host "`nSelect script number to run or B to go back"
        if ($selection -ne "B" -and $selection -match "^\d+$") {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $favScripts.Count) {
                $this.LaunchScript($favScripts[$index])
            }
        }
    }
    
    [void] ShowHistory() {
        if ($this.History.Count -eq 0) {
            Write-Host "No history yet." -ForegroundColor Yellow
            Read-Host "Press Enter to continue"
            return
        }
        
        Clear-Host
        Write-Host "Recent Script Executions:" -ForegroundColor Cyan
        $recent = $this.History | Select-Object -Last 10
        
        for ($i = 0; $i -lt $recent.Count; $i++) {
            $entry = $recent[$i]
            Write-Host "$($i + 1). $($entry.ScriptName) - $($entry.Timestamp)" -ForegroundColor White
        }
        
        Read-Host "`nPress Enter to continue"
    }
    
    [void] ShowStatistics() {
        Clear-Host
        Write-Host "Repository Statistics:" -ForegroundColor Cyan
        Write-Host "Total Scripts: $($this.Scripts.Count)" -ForegroundColor White
        Write-Host "Categories: $($this.Categories.Count)" -ForegroundColor White
        Write-Host "Favorites: $($this.Favorites.Count)" -ForegroundColor White
        Write-Host "History Entries: $($this.History.Count)" -ForegroundColor White
        
        Write-Host "`nTop Categories:" -ForegroundColor Yellow
        $topCategories = $this.Categories.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 5
        foreach ($cat in $topCategories) {
            Write-Host "  $($cat.Key): $($cat.Value.Count) scripts" -ForegroundColor Gray
        }
        
        Read-Host "`nPress Enter to continue"
    }
    
    [void] ShowScriptInfo([hashtable]$Script) {
        Clear-Host
        Write-Host "Script Information:" -ForegroundColor Cyan
        Write-Host "Name: $($Script.Name)" -ForegroundColor White
        Write-Host "Category: $($Script.Category)" -ForegroundColor White
        Write-Host "Path: $($Script.Path)" -ForegroundColor Gray
        Write-Host "Description: $($Script.Description)" -ForegroundColor White
        
        if ($Script.Parameters.Count -gt 0) {
            Write-Host "`nParameters:" -ForegroundColor Yellow
            foreach ($param in $Script.Parameters) {
                Write-Host "  -$param" -ForegroundColor Gray
            }
        }
        
        Read-Host "`nPress Enter to continue"
    }
    
    [void] QuickLaunch() {
        $scriptName = Read-Host "Enter script name (partial match supported)"
        $matches = $this.Scripts | Where-Object { $_.Name -like "*$scriptName*" }
        
        if ($matches.Count -eq 0) {
            Write-Host "No scripts found" -ForegroundColor Red
        } elseif ($matches.Count -eq 1) {
            $this.LaunchScript($matches[0])
        } else {
            Write-Host "Multiple matches found:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $matches.Count; $i++) {
                Write-Host "$($i + 1). $($matches[$i].Name)" -ForegroundColor White
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
        Clear-Host
        Write-Host "Configuration:" -ForegroundColor Cyan
        Write-Host "1. Clear History" -ForegroundColor White
        Write-Host "2. Clear Favorites" -ForegroundColor White
        Write-Host "3. Export Configuration" -ForegroundColor White
        Write-Host "4. Import Configuration" -ForegroundColor White
        Write-Host "B. Back" -ForegroundColor White
        
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
                $exportPath = Read-Host "Enter export path"
                @{
                    Favorites = $this.Favorites
                    History = $this.History
                } | ConvertTo-Json | Out-File $exportPath -Encoding UTF8
                Write-Host "Configuration exported" -ForegroundColor Green
            }
            "4" {
                $importPath = Read-Host "Enter import path"
                if (Test-Path $importPath) {
                    $config = Get-Content $importPath | ConvertFrom-Json
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

# Main execution
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
        Write-Host "Category not found: $Category" -ForegroundColor Red
    }
} elseif ($Favorites) {
    $favScripts = $launcher.Scripts | Where-Object { $_.Path -in $launcher.Favorites }
    $favScripts | Format-Table Name, Category, Description -AutoSize
} else {
    $launcher.ShowInteractiveMenu()
}

Write-Host "`nThank you for using Azure Enterprise Toolkit!" -ForegroundColor Cyan