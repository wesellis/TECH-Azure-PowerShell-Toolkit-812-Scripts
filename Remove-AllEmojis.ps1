#Requires -Version 7.0

<#
.SYNOPSIS
    Remove all emojis and superlative language from repository files

.DESCRIPTION
    Systematically removes emoji characters and superlative language from all markdown files
    in the repository to maintain professional appearance.

.PARAMETER Path
    Root path to search for files

.EXAMPLE
    .\Remove-AllEmojis.ps1 -Path "."
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$Path
)

# Define emoji patterns to remove
$emojiPatterns = @(
    '✅', '❌', '🚀', '⭐', '💡', '📝', '🛠', '💼', '🎯', '📋',
    '📊', '📈', '🔍', '🚨', '📁', '📞', '🔄', '📚', '⚠️', '🔒',
    '🔧', '💻', '🌟', '⚡', '🔥', '👍', '👎', '🎉', '🏆', '📌',
    '🎵', '🎶', '🎤', '🎸', '🥇', '🥈', '🥉', '🏅', '🎊', '🎈',
    '💰', '👥', '🏢', '📖', '🐛', '🏥', '💎', '📧', '🌐', '📄',
    '🎨', '🧪', '📱', '💾', '🔐', '🤖', '🛠️'
)

# Define superlative language patterns to replace
$superlativeReplacements = @{
    'best practices' = 'practices'
    'best' = 'recommended'
    'amazing' = 'effective'
    'awesome' = 'comprehensive'
    'fantastic' = 'useful'
    'incredible' = 'notable'
    'outstanding' = 'significant'
    'excellent' = 'good'
    'perfect' = 'complete'
    'ultimate' = 'comprehensive'
    'supreme' = 'advanced'
    'superior' = 'enhanced'
    'optimal' = 'recommended'
    'cutting-edge' = 'current'
    'state-of-the-art' = 'modern'
    'revolutionary' = 'significant'
    'game-changing' = 'important'
    'industry-leading' = 'professional'
    'world-class' = 'professional'
    'enterprise-grade' = 'enterprise'
    'mission-critical' = 'important'
    'seamless' = 'integrated'
    'robust' = 'reliable'
    'powerful' = 'capable'
    'advanced' = 'comprehensive'
    'sophisticated' = 'detailed'
    'innovative' = 'current'
    'breakthrough' = 'significant'
    'next-generation' = 'current'
    'premium' = 'professional'
    'elite' = 'professional'
    'masterful' = 'skilled'
    'exceptional' = 'notable'
    'remarkable' = 'notable'
    'extraordinary' = 'significant'
    'unparalleled' = 'unique'
    'unmatched' = 'distinctive'
    'legendary' = 'established'
    'epic' = 'comprehensive'
    'stellar' = 'good'
    'top-tier' = 'professional'
    'first-class' = 'professional'
    'world-renowned' = 'established'
    'acclaimed' = 'recognized'
    'celebrated' = 'recognized'
    'prestigious' = 'recognized'
}

function Remove-EmojisFromFile {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $originalContent = $content
        $changes = @()

        # Remove emojis
        foreach ($emoji in $emojiPatterns) {
            if ($content -match [regex]::Escape($emoji)) {
                $content = $content -replace [regex]::Escape($emoji), ''
                $changes += "Removed emoji: $emoji"
            }
        }

        # Remove superlative language
        foreach ($phrase in $superlativeReplacements.Keys) {
            $replacement = $superlativeReplacements[$phrase]
            if ($content -match [regex]::Escape($phrase)) {
                $content = $content -replace [regex]::Escape($phrase), $replacement
                $changes += "Replaced '$phrase' with '$replacement'"
            }
        }

        # Clean up multiple spaces and empty lines
        $content = $content -replace '\s+', ' '
        $content = $content -replace '\n\s*\n\s*\n', "`n`n"

        # Only write if changes were made
        if ($content -ne $originalContent) {
            if ($PSCmdlet.ShouldProcess($FilePath, "Remove emojis and superlatives")) {
                Set-Content -Path $FilePath -Value $content -NoNewline
                Write-Host "Cleaned: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
                if ($changes.Count -gt 0) {
                    Write-Host "  Changes: $($changes.Count) modifications" -ForegroundColor Gray
                }
                return $true
            }
        }
        return $false

    } catch {
        Write-Warning "Failed to process $FilePath`: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
Write-Host "Starting emoji and superlative removal..." -ForegroundColor Cyan

$markdownFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse
$htmlFiles = Get-ChildItem -Path $Path -Filter "*.html" -Recurse
$yamlFiles = Get-ChildItem -Path $Path -Filter "*.yml" -Recurse

$allFiles = $markdownFiles + $htmlFiles + $yamlFiles
$totalFiles = $allFiles.Count
$processedFiles = 0
$modifiedFiles = 0

Write-Host "Found $totalFiles files to process" -ForegroundColor Yellow

foreach ($file in $allFiles) {
    $processedFiles++
    Write-Progress -Activity "Cleaning Files" -Status "File $processedFiles of $totalFiles" -PercentComplete (($processedFiles / $totalFiles) * 100)

    if (Remove-EmojisFromFile -FilePath $file.FullName) {
        $modifiedFiles++
    }
}

Write-Progress -Activity "Cleaning Files" -Completed

Write-Host "`nEmoji and Superlative Removal Complete!" -ForegroundColor Green
Write-Host "Processed: $processedFiles files" -ForegroundColor White
Write-Host "Modified: $modifiedFiles files" -ForegroundColor Green
Write-Host "Unchanged: $($processedFiles - $modifiedFiles) files" -ForegroundColor Gray