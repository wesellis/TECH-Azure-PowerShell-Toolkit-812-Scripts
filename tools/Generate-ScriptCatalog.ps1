#Requires -Version 7.0
<#
.SYNOPSIS
    Generate ScriptCatalog
.DESCRIPTION
    NOTES
    Author: Wes Ellis (wes@wesellis.com)
[string]$RepositoryPath = (Split-Path $PSScriptRoot -Parent),
    [string]$OutputFormat = "Markdown",
    [string]$OutputPath = (Join-Path $RepositoryPath "SCRIPT-CATALOG.md"),
    [switch]$IncludeMetrics,
    [switch]$GenerateHTML
)


function Write-Log {
    [string]$ScriptPath)

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

    if ($content -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|$)') {
        $metadata.Description = $Matches[1].Trim()
    }

    if ($content -match '# Author:\s*(.+)') {
        $metadata.Author = $Matches[1].Trim()
    }

    if ($content -match '# Version:\s*(.+)') {
        $metadata.Version = $Matches[1].Trim()
    }

    $ParamMatches = [regex]::Matches($content, '\[Parameter.*?\]\s*\[.*?\]\s*\$(\w+)')
    foreach ($match in $ParamMatches) {
        $metadata.Parameters += $match.Groups[1].Value
    }

    $ModuleMatches = [regex]::Matches($content, '#Requires -Modules?\s+(.+)')
    foreach ($match in $ModuleMatches) {
        $metadata.RequiredModules += $match.Groups[1].Value.Split(',').Trim()
    }

    $TagKeywords = @('Azure', 'Security', 'Compliance', 'Monitoring', 'Automation', 'DevOps', 'Cost', 'Backup', 'Network', 'Storage', 'Compute', 'Identity', 'Governance')
    foreach ($keyword in $TagKeywords) {
        if ($content -match $keyword -or $metadata.Name -match $keyword) {
            $metadata.Tags += $keyword
        }
    }

    return $metadata
}

function Generate-MarkdownCatalog {
    [array]$Scripts)

    $markdown = @"
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Total Scripts: $($Scripts.Count)

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
            $params = if ($script.Parameters) { $script.Parameters -join ", "} else { "None" }
            $tags = if ($script.Tags) { ($script.Tags | ForEach-Object { "``$_``" } | Select-Object -Unique) -join " " } else { "" }
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
    [array]$Scripts)

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure Enterprise Toolkit - Script Catalog</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; background: #f5f5f5; }
        h1 { color:
        .category { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; }
        th { background:
        td { padding: 10px; border-bottom: 1px solid
        .tag { display: inline-block; padding: 2px 8px; background:
        .search { padding: 10px; width: 100%; font-size: 16px; border: 1px solid
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
            $params = if ($script.Parameters) { $script.Parameters -join ", "} else { "None" }
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

Write-Output "Scanning repository for PowerShell scripts..." # Color: $2
$scripts = Get-ChildItem -Path $RepositoryPath -Filter "*.ps1" -Recurse | Where-Object { $_.FullName -notmatch "\\(\.git|node_modules|packages)\\" }

Write-Output "Found $($scripts.Count) scripts. Extracting metadata..." # Color: $2

$ScriptMetadata = @()
$progress = 0
foreach ($script in $scripts) {
    $progress++
    Write-Progress -Activity "Processing scripts" -Status "$progress of $($scripts.Count)" -PercentComplete (($progress / $scripts.Count) * 100)
    $ScriptMetadata += Get-ScriptMetadata -ScriptPath $script.FullName
}

Write-Output "Generating catalog..." # Color: $2

if ($OutputFormat -eq "Markdown" -or $GenerateHTML) {
    $MarkdownContent = Generate-MarkdownCatalog -Scripts $ScriptMetadata
    $MarkdownContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Output "Markdown catalog saved to: $OutputPath" # Color: $2
}

if ($GenerateHTML) {
    $HtmlPath = [System.IO.Path]::ChangeExtension($OutputPath, ".html")
    $HtmlContent = Generate-HTMLCatalog -Scripts $ScriptMetadata
    $HtmlContent | Out-File -FilePath $HtmlPath -Encoding UTF8
    Write-Output "HTML catalog saved to: $HtmlPath" # Color: $2
}

Write-Output "`nCatalog generation complete!" # Color: $2
Write-Output "Total scripts cataloged: $($ScriptMetadata.Count)" # Color: $2



