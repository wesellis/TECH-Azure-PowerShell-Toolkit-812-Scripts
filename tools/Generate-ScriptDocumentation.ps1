#Requires -Version 7.0
<#
.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|$)') {
                $this.Metadata.Synopsis = $Matches[1].Trim()
            }

            if ($HelpBlock -match '\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.|$)') {

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
                $this.Metadata.Description = $Matches[1].Trim()
            }

            if ($HelpBlock -match '\.NOTES\s*\n\s*(.+?)(?=\n\s*\.|$)') {
                $this.Metadata.Notes = $Matches[1].Trim()
            }

            $ExampleMatches = [regex]::Matches($HelpBlock, '\.EXAMPLE\s*\n\s*(.+?)(?=\n\s*\.|$)')
            foreach ($match in $ExampleMatches) {
                $this.Metadata.Examples += $match.Groups[1].Value.Trim()
            }
        }

        if ($this.Content -match '# Author:\s*(.+)') {
            $this.Metadata.Author = $Matches[1].Trim()
        }

        if ($this.Content -match '# Version:\s*(.+)') {
            $this.Metadata.Version = $Matches[1].Trim()
        }

        $ParamBlock = $this.AST.ParamBlock
        if ($ParamBlock) {
            foreach ($param in $ParamBlock.Parameters) {
                $ParamInfo = @{
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
                                $ParamInfo.Mandatory = $arg.Argument.Value
                            }
                        }
                    }
                    elseif ($attribute.TypeName.Name -eq "ValidateSet") {
                        $ParamInfo.ValidateSet = $attribute.PositionalArguments | ForEach-Object { $_.Value }
                    }
                }

                if ($param.DefaultValue) {
                    $ParamInfo.DefaultValue = $param.DefaultValue.Extent.Text
                }

                $this.Metadata.Parameters += $ParamInfo
            }
        }

        $ModuleMatches = [regex]::Matches($this.Content, '#Requires -Module[s]?\s+(.+)')
        foreach ($match in $ModuleMatches) {
            $this.Metadata.RequiredModules += $match.Groups[1].Value.Split(',') | ForEach-Object { $_.Trim() }
        }
    }

    [string] GenerateMarkdown() {
        $md = @"

$($this.Metadata.Synopsis)


$($this.Metadata.Description)


| Parameter | Type | Mandatory | Default | Description |
|-----------|------|-----------|---------|-------------|
"@

        foreach ($param in $this.Metadata.Parameters) {
            $mandatory = if ($param.Mandatory) { "Yes" } else { "No" }
            $default = if ($param.DefaultValue) { "``$($param.DefaultValue)``" } else { "-" }
            $md += "`n| ``-$($param.Name)`` | $($param.Type) | $mandatory | $default | $($param.Description) |"

            if ($param.ValidateSet.Count -gt 0) {
                $md += "`n| | Valid values: $($param.ValidateSet -join ', ') | | | |"
            }
        }

        if ($this.Metadata.Examples.Count -gt 0) {
            $md += "`n`n## Examples`n"
            $ExampleNum = 1
            foreach ($example in $this.Metadata.Examples) {
                $md += "`n### Example $ExampleNum`n"
                $md += "``````powershell`n$example`n```````n"
                $ExampleNum++
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
        h1 { color:
        h2 { color:
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background:
        td { padding: 10px; border: 1px solid
        code { background:
        pre { background:
        .metadata { background:
        .param-required { color:
    </style>
</head>
<body>
    <h1>$($this.Metadata.Name)</h1>
    <p><strong>$($this.Metadata.Synopsis)</strong></p>

    <h2>Description</h2>
    <p>$($this.Metadata.Description)</p>

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
"@
        }

        $html += @"
        </tbody>
    </table>
"@

        if ($this.Metadata.Examples.Count -gt 0) {
            $html += "<h2>Examples</h2>"
            $ExampleNum = 1
            foreach ($example in $this.Metadata.Examples) {
                $html += "<h3>Example $ExampleNum</h3>"
                $html += "<pre><code>$example</code></pre>"
                $ExampleNum++
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
            $BasicExample = ".$($this.Metadata.Name)"

            foreach ($param in $this.Metadata.Parameters | Where-Object { $_.Mandatory }) {
                $BasicExample += " -$($param.Name) <$($param.Type)>"
            }

            $this.Metadata.Examples += $BasicExample
        }
    }
}

function Write-Log {
    [CmdletBinding()]
[string]$FolderPath)

    $scripts = Get-ChildItem -Path $FolderPath -Filter "*.ps1" -File
    $ReadmeContent = @"

This folder contains $($scripts.Count) PowerShell scripts for Azure automation.


| Script | Description | Parameters |
|--------|-------------|------------|
"@

    foreach ($script in $scripts) {
        $generator = [DocumentationGenerator]::new($script.FullName)
        $params = ($generator.Metadata.Parameters | ForEach-Object { $_.Name }) -join ", "
        $ReadmeContent += "`n| [$($script.Name)](./$($script.Name).md) | $($generator.Metadata.Synopsis) | $params |"

        $ScriptDoc = $generator.GenerateMarkdown()
        $ScriptDocPath = Join-Path $FolderPath "$($script.BaseName).md"
        $ScriptDoc | Out-File $ScriptDocPath -Encoding UTF8
    }

    $ReadmePath = Join-Path $FolderPath "README.md"
    $ReadmeContent | Out-File $ReadmePath -Encoding UTF8

    return $ReadmePath
}

if ($ScriptPath) {
    if (Test-Path $ScriptPath -PathType Container) {
        Write-Output "Generating documentation for folder: $ScriptPath" # Color: $2
        $ReadmePath = Generate-FolderDocumentation -FolderPath $ScriptPath
        Write-Output "Folder documentation generated: $ReadmePath" # Color: $2
    } else {
        Write-Output "Generating documentation for script: $ScriptPath" # Color: $2
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
                Write-Output "Markdown documentation generated: $OutputPath" # Color: $2
            }
            "HTML" {
                $doc = $generator.GenerateHTML()
                $HtmlPath = [System.IO.Path]::ChangeExtension($OutputPath, ".html")
                $doc | Out-File $HtmlPath -Encoding UTF8
                Write-Output "HTML documentation generated: $HtmlPath" # Color: $2
            }
            "All" {
                $MdDoc = $generator.GenerateMarkdown()
                $MdDoc | Out-File $OutputPath -Encoding UTF8
                Write-Output "Markdown documentation generated: $OutputPath" # Color: $2

                $HtmlDoc = $generator.GenerateHTML()
                $HtmlPath = [System.IO.Path]::ChangeExtension($OutputPath, ".html")
                $HtmlDoc | Out-File $HtmlPath -Encoding UTF8
                Write-Output "HTML documentation generated: $HtmlPath" # Color: $2
            }
        }
    }
} else {
    Write-Output "Generating documentation for entire repository..." # Color: $2
    $RepoPath = Split-Path $PSScriptRoot -Parent
    $ScriptsPath = Join-Path $RepoPath "automation-scripts"

    $folders = Get-ChildItem -Path $ScriptsPath -Directory
    foreach ($folder in $folders) {
        Write-Output "Processing $($folder.Name)..." # Color: $2
        Generate-FolderDocumentation -FolderPath $folder.FullName
    }

    Write-Output "Repository documentation complete!" # Color: $2`n}
