<#
.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|$)') {
                $this.Metadata.Synopsis = $Matches[1].Trim()
            }
            
            if ($helpBlock -match '\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.|$)') {
                $this.Metadata.Description = $Matches[1].Trim()
#>
            }
            
            if ($helpBlock -match '\.NOTES\s*\n\s*(.+?)(?=\n\s*\.|$)') {
                $this.Metadata.Notes = $Matches[1].Trim()
            }
            
            # Extract examples
            $exampleMatches = [regex]::Matches($helpBlock, '\.EXAMPLE\s*\n\s*(.+?)(?=\n\s*\.|$)')
            foreach ($match in $exampleMatches) {
                $this.Metadata.Examples += $match.Groups[1].Value.Trim()
            }
        }
        
        # Extract metadata from comments
        if ($this.Content -match '# Author:\s*(.+)') {
            $this.Metadata.Author = $Matches[1].Trim()
        }
        
        if ($this.Content -match '# Version:\s*(.+)') {
            $this.Metadata.Version = $Matches[1].Trim()
        }
        
        # Extract parameters from AST
        $paramBlock = $this.AST.ParamBlock
        if ($paramBlock) {
            foreach ($param in $paramBlock.Parameters) {
                $paramInfo = @{
                    Name = $param.Name.VariablePath.UserPath
                    Type = if ($param.StaticType) { $param.StaticType.Name } else { "Object" }
                    Mandatory = $false
                    DefaultValue = $null
                    Description = ""
                    ValidateSet = @()
                }
                
                foreach ($attribute in $param.Attributes) {
                    if ($attribute.TypeName.Name -eq "Parameter") {
                        foreach ($arg in $attribute.NamedArguments) {
                            if ($arg.ArgumentName -eq "Mandatory") {
                                $paramInfo.Mandatory = $arg.Argument.Value
                            }
                        }
                    }
                    elseif ($attribute.TypeName.Name -eq "ValidateSet") {
                        $paramInfo.ValidateSet = $attribute.PositionalArguments | ForEach-Object { $_.Value }
                    }
                }
                
                if ($param.DefaultValue) {
                    $paramInfo.DefaultValue = $param.DefaultValue.Extent.Text
                }
                
                $this.Metadata.Parameters += $paramInfo
            }
        }
        
        # Extract required modules
        $moduleMatches = [regex]::Matches($this.Content, '#Requires -Module[s]?\s+(.+)')
        foreach ($match in $moduleMatches) {
            $this.Metadata.RequiredModules += $match.Groups[1].Value.Split(',') | ForEach-Object { $_.Trim() }
        }
    }
    
    [string] GenerateMarkdown() {
        $md = @"
# $($this.Metadata.Name)

$($this.Metadata.Synopsis)

## Description

$($this.Metadata.Description)

#>
## Parameters

| Parameter | Type | Mandatory | Default | Description |
|-----------|------|-----------|---------|-------------|
"@
        
        foreach ($param in $this.Metadata.Parameters) {
            $mandatory = if ($param.Mandatory) { "Yes" } else { "No" }
            $default = if ($param.DefaultValue) { "``$($param.DefaultValue)``" } else { "-" }
            $md += "`n| ``-$($param.Name)`` | $($param.Type) | $mandatory | $default | $($param.Description) |"
            
#>
            if ($param.ValidateSet.Count -gt 0) {
                $md += "`n| | Valid values: $($param.ValidateSet -join ', ') | | | |"
            }
        }
        
        if ($this.Metadata.Examples.Count -gt 0) {
            $md += "`n`n## Examples`n"
            $exampleNum = 1
            foreach ($example in $this.Metadata.Examples) {
                $md += "`n### Example $exampleNum`n"
                $md += "``````powershell`n$example`n```````n"
                $exampleNum++
            }
        }
        
        if ($this.Metadata.RequiredModules.Count -gt 0) {
            $md += "`n## Requirements`n"
            $md += "`n### Required Modules`n"
            foreach ($module in $this.Metadata.RequiredModules) {
                $md += "- $module`n"
            }
        }
        
        if ($this.Metadata.Notes) {
            $md += "`n## Notes`n"
            $md += "$($this.Metadata.Notes)`n"
        }
        
        $md += "`n## Metadata`n"
        $md += "- **Author**: $($this.Metadata.Author)`n"
        $md += "- **Version**: $($this.Metadata.Version)`n"
        $md += "- **Last Modified**: $(Get-Date -Format 'yyyy-MM-dd')`n"
        
        return $md
    }
    
    [string] GenerateHTML() {
        $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($this.Metadata.Name) - Documentation</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; line-height: 1.6; }
        h1 { color: #0078d4; border-bottom: 2px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #333; margin-top: 30px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #f0f0f0; padding: 10px; text-align: left; border: 1px solid #ddd; }
        td { padding: 10px; border: 1px solid #ddd; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: 'Consolas', 'Monaco', monospace; }
        pre { background: #f4f4f4; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .metadata { background: #e7f3ff; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .param-required { color: #d73a49; font-weight: bold; }
    </style>
</head>
<body>
    <h1>$($this.Metadata.Name)</h1>
    <p><strong>$($this.Metadata.Synopsis)</strong></p>
    
    <h2>Description</h2>
    <p>$($this.Metadata.Description)</p>
    
#>
    <h2>Parameters</h2>
    <table>
        <thead>
            <tr>
                <th>Parameter</th>
                <th>Type</th>
                <th>Required</th>
                <th>Default</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
"@
        
        foreach ($param in $this.Metadata.Parameters) {
            $required = if ($param.Mandatory) { "<span class='param-required'>Yes</span>" } else { "No" }
            $default = if ($param.DefaultValue) { "<code>$($param.DefaultValue)</code>" } else { "-" }
            $html += @"
            <tr>
                <td><code>-$($param.Name)</code></td>
                <td>$($param.Type)</td>
                <td>$required</td>
                <td>$default</td>
                <td>$($param.Description)</td>
            </tr>
#>
"@
        }
        
        $html += @"
        </tbody>
    </table>
"@
        
        if ($this.Metadata.Examples.Count -gt 0) {
            $html += "<h2>Examples</h2>"
            $exampleNum = 1
            foreach ($example in $this.Metadata.Examples) {
                $html += "<h3>Example $exampleNum</h3>"
                $html += "<pre><code>$example</code></pre>"
                $exampleNum++
            }
        }
        
        $html += @"
    <div class="metadata">
        <h2>Metadata</h2>
        <ul>
            <li><strong>Author:</strong> $($this.Metadata.Author)</li>
            <li><strong>Version:</strong> $($this.Metadata.Version)</li>
            <li><strong>Last Modified:</strong> $(Get-Date -Format 'yyyy-MM-dd')</li>
        </ul>
    </div>
</body>
</html>
"@
        
        return $html
    }
    
    [void] GenerateExamples() {
        if ($this.Metadata.Examples.Count -eq 0) {
            # Auto-generate basic examples based on parameters
            $basicExample = ".$($this.Metadata.Name)"
            
            foreach ($param in $this.Metadata.Parameters | Where-Object { $_.Mandatory }) {
                $basicExample += " -$($param.Name) <$($param.Type)>"
            }
            
            $this.Metadata.Examples += $basicExample
        }
    }
}

[OutputType([bool])]
 {
    [CmdletBinding()]
[string]$FolderPath)
    
    $scripts = Get-ChildItem -Path $FolderPath -Filter "*.ps1" -File
    $readmeContent = @"
# $(Split-Path $FolderPath -Leaf) Scripts

This folder contains $($scripts.Count) PowerShell scripts for Azure automation.

## Scripts

| Script | Description | Parameters |
|--------|-------------|------------|
"@
    
    foreach ($script in $scripts) {
        $generator = [DocumentationGenerator]::new($script.FullName)
        $params = ($generator.Metadata.Parameters | ForEach-Object { $_.Name }) -join ", "
        $readmeContent += "`n| [$($script.Name)](./$($script.Name).md) | $($generator.Metadata.Synopsis) | $params |"
        
        # Generate individual script documentation
        $scriptDoc = $generator.GenerateMarkdown()
        $scriptDocPath = Join-Path $FolderPath "$($script.BaseName).md"
        $scriptDoc | Out-File $scriptDocPath -Encoding UTF8
    }
    
    $readmePath = Join-Path $FolderPath "README.md"
    $readmeContent | Out-File $readmePath -Encoding UTF8
    
    return $readmePath
}

# Main execution
if ($ScriptPath) {
    if (Test-Path $ScriptPath -PathType Container) {
        Write-Host "Generating documentation for folder: $ScriptPath" -ForegroundColor Cyan
        $readmePath = Generate-FolderDocumentation -FolderPath $ScriptPath
        Write-Host "Folder documentation generated: $readmePath" -ForegroundColor Green
    } else {
        Write-Host "Generating documentation for script: $ScriptPath" -ForegroundColor Cyan
        $generator = [DocumentationGenerator]::new($ScriptPath)
        
        if ($IncludeExamples) {
            $generator.GenerateExamples()
        }
        
        if (-not $OutputPath) {
            $OutputPath = [System.IO.Path]::ChangeExtension($ScriptPath, ".md")
        }
        
        switch ($Format) {
            "Markdown" {
                $doc = $generator.GenerateMarkdown()
                $doc | Out-File $OutputPath -Encoding UTF8
                Write-Host "Markdown documentation generated: $OutputPath" -ForegroundColor Green
            }
            "HTML" {
                $doc = $generator.GenerateHTML()
                $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, ".html")
                $doc | Out-File $htmlPath -Encoding UTF8
                Write-Host "HTML documentation generated: $htmlPath" -ForegroundColor Green
            }
            "All" {
                $mdDoc = $generator.GenerateMarkdown()
                $mdDoc | Out-File $OutputPath -Encoding UTF8
                Write-Host "Markdown documentation generated: $OutputPath" -ForegroundColor Green
                
                $htmlDoc = $generator.GenerateHTML()
                $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, ".html")
                $htmlDoc | Out-File $htmlPath -Encoding UTF8
                Write-Host "HTML documentation generated: $htmlPath" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "Generating documentation for entire repository..." -ForegroundColor Cyan
    $repoPath = Split-Path $PSScriptRoot -Parent
    $scriptsPath = Join-Path $repoPath "automation-scripts"
    
    $folders = Get-ChildItem -Path $scriptsPath -Directory
    foreach ($folder in $folders) {
        Write-Host "Processing $($folder.Name)..." -ForegroundColor Yellow
        Generate-FolderDocumentation -FolderPath $folder.FullName
    }
    
    Write-Host "Repository documentation complete!" -ForegroundColor Green
}

#endregion

