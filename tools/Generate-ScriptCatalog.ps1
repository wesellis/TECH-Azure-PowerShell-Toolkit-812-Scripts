# Generate-ScriptCatalog.ps1
# Generates a comprehensive catalog of all PowerShell scripts in the repository
# Author: Wesley Ellis | Enhanced by AI
# Version: 2.0

param(
    [string]$RepositoryPath = (Split-Path $PSScriptRoot -Parent),
    [string]$OutputFormat = "Markdown",
    [string]$OutputPath = (Join-Path $RepositoryPath "SCRIPT-CATALOG.md"),
    [switch]$IncludeMetrics,
    [switch]$GenerateHTML
)

function Get-ScriptMetadata {
    param([string]$ScriptPath)
    
    $metadata = @{
        Name = [System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)
        Path = $ScriptPath.Replace($RepositoryPath, "").TrimStart("\", "/")
        Category = (Split-Path (Split-Path $ScriptPath -Parent) -Leaf)
        Size = (Get-Item $ScriptPath).Length
        Lines = (Get-Content $ScriptPath | Measure-Object -Line).Lines
        LastModified = (Get-Item $ScriptPath).LastWriteTime
        Parameters = @()
        Description = ""
        Author = ""
        Version = ""
        RequiredModules = @()
        Tags = @()
    }
    
    $content = Get-Content $ScriptPath -Raw
    
    # Extract metadata from comments
    if ($content -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|$)') {
        $metadata.Description = $Matches[1].Trim()
    }
    
    if ($content -match '# Author:\s*(.+)') {
        $metadata.Author = $Matches[1].Trim()
    }
    
    if ($content -match '# Version:\s*(.+)') {
        $metadata.Version = $Matches[1].Trim()
    }
    
    # Extract parameters
    $paramMatches = [regex]::Matches($content, '\[Parameter.*?\]\s*\[.*?\]\s*\$(\w+)')
    foreach ($match in $paramMatches) {
        $metadata.Parameters += $match.Groups[1].Value
    }
    
    # Extract required modules
    $moduleMatches = [regex]::Matches($content, '#Requires -Modules?\s+(.+)')
    foreach ($match in $moduleMatches) {
        $metadata.RequiredModules += $match.Groups[1].Value.Split(',').Trim()
    }
    
    # Auto-generate tags based on content
    $tagKeywords = @('Azure', 'Security', 'Compliance', 'Monitoring', 'Automation', 'DevOps', 'Cost', 'Backup', 'Network', 'Storage', 'Compute', 'Identity', 'Governance')
    foreach ($keyword in $tagKeywords) {
        if ($content -match $keyword -or $metadata.Name -match $keyword) {
            $metadata.Tags += $keyword
        }
    }
    
    return $metadata
}

function Generate-MarkdownCatalog {
    param([array]$Scripts)
    
    $markdown = @"
# Azure Enterprise Toolkit - Script Catalog
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Total Scripts: $($Scripts.Count)

## Table of Contents
"@

    $categories = $Scripts | Group-Object Category | Sort-Object Name
    foreach ($category in $categories) {
        $markdown += "`n- [$($category.Name) ($($category.Count) scripts)](#$(($category.Name.ToLower() -replace '\s', '-')))"
    }
    
    $markdown += "`n`n## Scripts by Category`n"
    
    foreach ($category in $categories) {
        $markdown += "`n### $($category.Name)`n"
        $markdown += "| Script | Description | Parameters | Tags |`n"
        $markdown += "|--------|-------------|------------|------|`n"
        
        foreach ($script in ($category.Group | Sort-Object Name)) {
            $params = if ($script.Parameters) { $script.Parameters -join ", " } else { "None" }
            $tags = if ($script.Tags) { $script.Tags | ForEach-Object { "``$_``" } | Select-Object -Unique } -join " "
            $markdown += "| [$($script.Name)]($($script.Path)) | $($script.Description) | $params | $tags |`n"
        }
    }
    
    if ($IncludeMetrics) {
        $markdown += "`n## Repository Metrics`n"
        $markdown += "- **Total Scripts**: $($Scripts.Count)`n"
        $markdown += "- **Total Lines of Code**: $(($Scripts | Measure-Object -Property Lines -Sum).Sum)`n"
        $markdown += "- **Average Script Size**: $([math]::Round(($Scripts | Measure-Object -Property Lines -Average).Average, 2)) lines`n"
        $markdown += "- **Categories**: $($categories.Count)`n"
        $markdown += "- **Most Common Tags**: $(($Scripts.Tags | Group-Object | Sort-Object Count -Descending | Select-Object -First 5).Name -join ', ')`n"
    }
    
    return $markdown
}

function Generate-HTMLCatalog {
    param([array]$Scripts)
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure Enterprise Toolkit - Script Catalog</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; background: #f5f5f5; }
        h1 { color: #0078d4; }
        .category { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; }
        th { background: #0078d4; color: white; padding: 10px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #eee; }
        .tag { display: inline-block; padding: 2px 8px; background: #e1f5fe; color: #01579b; border-radius: 12px; font-size: 12px; margin: 2px; }
        .search { padding: 10px; width: 100%; font-size: 16px; border: 1px solid #ddd; border-radius: 4px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Azure Enterprise Toolkit - Script Catalog</h1>
    <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Total Scripts: $($Scripts.Count)</p>
    <input type="text" class="search" placeholder="Search scripts..." onkeyup="filterScripts(this.value)">
"@

    $categories = $Scripts | Group-Object Category | Sort-Object Name
    foreach ($category in $categories) {
        $html += @"
    <div class="category">
        <h2>$($category.Name) ($($category.Count) scripts)</h2>
        <table>
            <thead>
                <tr>
                    <th>Script</th>
                    <th>Description</th>
                    <th>Parameters</th>
                    <th>Tags</th>
                </tr>
            </thead>
            <tbody>
"@
        foreach ($script in ($category.Group | Sort-Object Name)) {
            $params = if ($script.Parameters) { $script.Parameters -join ", " } else { "None" }
            $tags = if ($script.Tags) { ($script.Tags | ForEach-Object { "<span class='tag'>$_</span>" }) -join " " } else { "" }
            $html += @"
                <tr class="script-row">
                    <td><a href="$($script.Path)">$($script.Name)</a></td>
                    <td>$($script.Description)</td>
                    <td>$params</td>
                    <td>$tags</td>
                </tr>
"@
        }
        $html += @"
            </tbody>
        </table>
    </div>
"@
    }
    
    $html += @"
    <script>
        function filterScripts(searchTerm) {
            const rows = document.querySelectorAll('.script-row');
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(searchTerm.toLowerCase()) ? '' : 'none';
            });
        }
    </script>
</body>
</html>
"@
    
    return $html
}

# Main execution
Write-Host "Scanning repository for PowerShell scripts..." -ForegroundColor Cyan
$scripts = Get-ChildItem -Path $RepositoryPath -Filter "*.ps1" -Recurse | Where-Object { $_.FullName -notmatch "\\(\.git|node_modules|packages)\\" }

Write-Host "Found $($scripts.Count) scripts. Extracting metadata..." -ForegroundColor Yellow

$scriptMetadata = @()
$progress = 0
foreach ($script in $scripts) {
    $progress++
    Write-Progress -Activity "Processing scripts" -Status "$progress of $($scripts.Count)" -PercentComplete (($progress / $scripts.Count) * 100)
    $scriptMetadata += Get-ScriptMetadata -ScriptPath $script.FullName
}

Write-Host "Generating catalog..." -ForegroundColor Green

if ($OutputFormat -eq "Markdown" -or $GenerateHTML) {
    $markdownContent = Generate-MarkdownCatalog -Scripts $scriptMetadata
    $markdownContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Markdown catalog saved to: $OutputPath" -ForegroundColor Green
}

if ($GenerateHTML) {
    $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, ".html")
    $htmlContent = Generate-HTMLCatalog -Scripts $scriptMetadata
    $htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
    Write-Host "HTML catalog saved to: $htmlPath" -ForegroundColor Green
}

Write-Host "`nCatalog generation complete!" -ForegroundColor Cyan
Write-Host "Total scripts cataloged: $($scriptMetadata.Count)" -ForegroundColor Yellow