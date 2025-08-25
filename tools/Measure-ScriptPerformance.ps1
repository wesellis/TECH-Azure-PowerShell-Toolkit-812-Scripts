# Measure-ScriptPerformance.ps1
# Performance benchmarking framework for PowerShell scripts
# Author: Wesley Ellis | Enhanced by AI
# Version: 2.0

param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,
    
    [int]$Iterations = 3,
    [switch]$DetailedMetrics,
    [switch]$CompareVersions,
    [string]$BaselineScript,
    [switch]$ExportReport,
    [string]$ReportPath = "./performance-report.html"
)

class PerformanceBenchmark {
    [string]$ScriptPath
    [hashtable]$Metrics = @{}
    [array]$ExecutionTimes = @()
    [array]$MemoryUsage = @()
    [array]$CPUUsage = @()
    
    PerformanceBenchmark([string]$Path) {
        $this.ScriptPath = $Path
    }
    
    [hashtable] RunBenchmark([int]$Iterations) {
        Write-Host "Starting benchmark for: $(Split-Path $this.ScriptPath -Leaf)" -ForegroundColor Cyan
        
        $results = @{
            ExecutionTimes = @()
            MemoryUsage = @()
            CPUUsage = @()
            Errors = @()
        }
        
        for ($i = 1; $i -le $Iterations; $i++) {
            Write-Progress -Activity "Running benchmark" -Status "Iteration $i of $Iterations" -PercentComplete (($i / $Iterations) * 100)
            
            $iteration = $this.MeasureSingleExecution()
            $results.ExecutionTimes += $iteration.ExecutionTime
            $results.MemoryUsage += $iteration.MemoryUsage
            $results.CPUUsage += $iteration.CPUUsage
            
            if ($iteration.Error) {
                $results.Errors += $iteration.Error
            }
            
            # Cool down between iterations
            Start-Sleep -Seconds 2
        }
        
        # Calculate statistics
        $results.Statistics = $this.CalculateStatistics($results)
        
        return $results
    }
    
    [hashtable] MeasureSingleExecution() {
        $result = @{
            ExecutionTime = 0
            MemoryUsage = 0
            CPUUsage = 0
            Error = $null
        }
        
        try {
            # Get initial memory
            [System.GC]::Collect()
            $initialMemory = (Get-Process -Id $PID).WorkingSet64
            
            # Get initial CPU
            $initialCPU = (Get-Process -Id $PID).CPU
            
            # Measure execution time
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Execute the script
            $scriptOutput = & $this.ScriptPath 2>&1
            
            $stopwatch.Stop()
            $result.ExecutionTime = $stopwatch.ElapsedMilliseconds
            
            # Get final memory
            $finalMemory = (Get-Process -Id $PID).WorkingSet64
            $result.MemoryUsage = ($finalMemory - $initialMemory) / 1MB
            
            # Get final CPU
            $finalCPU = (Get-Process -Id $PID).CPU
            $result.CPUUsage = $finalCPU - $initialCPU
            
        } catch {
            $result.Error = $_.Exception.Message
        }
        
        return $result
    }
    
    [hashtable] CalculateStatistics([hashtable]$Results) {
        $stats = @{}
        
        # Execution time statistics
        if ($Results.ExecutionTimes.Count -gt 0) {
            $stats.ExecutionTime = @{
                Min = ($Results.ExecutionTimes | Measure-Object -Minimum).Minimum
                Max = ($Results.ExecutionTimes | Measure-Object -Maximum).Maximum
                Average = ($Results.ExecutionTimes | Measure-Object -Average).Average
                Median = $this.GetMedian($Results.ExecutionTimes)
                StdDev = $this.GetStandardDeviation($Results.ExecutionTimes)
            }
        }
        
        # Memory usage statistics
        if ($Results.MemoryUsage.Count -gt 0) {
            $stats.MemoryUsage = @{
                Min = ($Results.MemoryUsage | Measure-Object -Minimum).Minimum
                Max = ($Results.MemoryUsage | Measure-Object -Maximum).Maximum
                Average = ($Results.MemoryUsage | Measure-Object -Average).Average
            }
        }
        
        # CPU usage statistics
        if ($Results.CPUUsage.Count -gt 0) {
            $stats.CPUUsage = @{
                Min = ($Results.CPUUsage | Measure-Object -Minimum).Minimum
                Max = ($Results.CPUUsage | Measure-Object -Maximum).Maximum
                Average = ($Results.CPUUsage | Measure-Object -Average).Average
            }
        }
        
        $stats.ErrorRate = ($Results.Errors.Count / $Results.ExecutionTimes.Count) * 100
        
        return $stats
    }
    
    [double] GetMedian([array]$Values) {
        $sorted = $Values | Sort-Object
        $count = $sorted.Count
        
        if ($count % 2 -eq 0) {
            return ($sorted[$count/2 - 1] + $sorted[$count/2]) / 2
        } else {
            return $sorted[[Math]::Floor($count/2)]
        }
    }
    
    [double] GetStandardDeviation([array]$Values) {
        if ($Values.Count -le 1) { return 0 }
        
        $avg = ($Values | Measure-Object -Average).Average
        $squaredDiffs = $Values | ForEach-Object { [Math]::Pow($_ - $avg, 2) }
        $variance = ($squaredDiffs | Measure-Object -Average).Average
        
        return [Math]::Sqrt($variance)
    }
    
    [string] GenerateHTMLReport([hashtable]$Results) {
        $scriptName = Split-Path $this.ScriptPath -Leaf
        $stats = $Results.Statistics
        
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Performance Report - $scriptName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        h1 { color: #0078d4; }
        .metric-card { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric-title { font-size: 18px; font-weight: bold; color: #333; margin-bottom: 10px; }
        .metric-value { font-size: 24px; color: #0078d4; }
        .metric-unit { font-size: 14px; color: #666; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #0078d4; color: white; padding: 10px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        .chart { margin: 20px 0; }
        .success { color: #4CAF50; }
        .warning { color: #FF9800; }
        .error { color: #F44336; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Performance Report: $scriptName</h1>
    <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Iterations: $($Results.ExecutionTimes.Count)</p>
    
    <div class="metric-card">
        <div class="metric-title">Execution Time</div>
        <div class="metric-value">$([Math]::Round($stats.ExecutionTime.Average, 2)) <span class="metric-unit">ms</span></div>
        <table>
            <tr><td>Minimum</td><td>$([Math]::Round($stats.ExecutionTime.Min, 2)) ms</td></tr>
            <tr><td>Maximum</td><td>$([Math]::Round($stats.ExecutionTime.Max, 2)) ms</td></tr>
            <tr><td>Median</td><td>$([Math]::Round($stats.ExecutionTime.Median, 2)) ms</td></tr>
            <tr><td>Std Dev</td><td>$([Math]::Round($stats.ExecutionTime.StdDev, 2)) ms</td></tr>
        </table>
    </div>
    
    <div class="metric-card">
        <div class="metric-title">Memory Usage</div>
        <div class="metric-value">$([Math]::Round($stats.MemoryUsage.Average, 2)) <span class="metric-unit">MB</span></div>
        <table>
            <tr><td>Minimum</td><td>$([Math]::Round($stats.MemoryUsage.Min, 2)) MB</td></tr>
            <tr><td>Maximum</td><td>$([Math]::Round($stats.MemoryUsage.Max, 2)) MB</td></tr>
        </table>
    </div>
    
    <div class="metric-card">
        <div class="metric-title">CPU Usage</div>
        <div class="metric-value">$([Math]::Round($stats.CPUUsage.Average, 2)) <span class="metric-unit">seconds</span></div>
    </div>
    
    <div class="metric-card">
        <div class="metric-title">Reliability</div>
        <div class="metric-value class="$(if ($stats.ErrorRate -eq 0) { 'success' } elseif ($stats.ErrorRate -lt 10) { 'warning' } else { 'error' })">
            $([Math]::Round(100 - $stats.ErrorRate, 1))% <span class="metric-unit">success rate</span>
        </div>
    </div>
    
    <div class="metric-card">
        <div class="metric-title">Execution Time Trend</div>
        <canvas id="timeChart" width="400" height="200"></canvas>
    </div>
    
    <script>
        var ctx = document.getElementById('timeChart').getContext('2d');
        var chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [$([string]::Join(',', (1..$Results.ExecutionTimes.Count)))],
                datasets: [{
                    label: 'Execution Time (ms)',
                    data: [$([string]::Join(',', $Results.ExecutionTimes))],
                    borderColor: '#0078d4',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
        
        return $html
    }
}

class PerformanceOptimizer {
    [hashtable] AnalyzeScript([string]$ScriptPath) {
        $suggestions = @{
            Performance = @()
            Memory = @()
            BestPractices = @()
        }
        
        $content = Get-Content $ScriptPath -Raw
        
        # Check for common performance issues
        if ($content -match 'Get-ChildItem.*-Recurse.*\|.*Where-Object') {
            $suggestions.Performance += "Consider using -Filter parameter instead of piping to Where-Object"
        }
        
        if ($content -match '\+=') {
            $suggestions.Performance += "Array concatenation with += is inefficient. Use ArrayList or List<T>"
        }
        
        if ($content -match 'Write-Host.*-ForegroundColor' -and $content -notmatch '\$VerbosePreference') {
            $suggestions.Performance += "Consider using Write-Verbose instead of Write-Host for optional output"
        }
        
        # Memory optimization suggestions
        if ($content -match 'Get-Content.*-Raw' -and $content.Length -gt 50000) {
            $suggestions.Memory += "Large file read into memory. Consider streaming for large files"
        }
        
        if ($content -notmatch '\[System\.GC\]::Collect\(\)' -and $content -match 'New-Object.*\[\]') {
            $suggestions.Memory += "Consider explicit garbage collection for large array operations"
        }
        
        # Best practices
        if ($content -notmatch '#Requires') {
            $suggestions.BestPractices += "Add #Requires statement for version and module dependencies"
        }
        
        if ($content -notmatch '\[CmdletBinding\(\)\]') {
            $suggestions.BestPractices += "Add [CmdletBinding()] for advanced function features"
        }
        
        if ($content -match 'catch\s*{[^}]*}' -and $content -notmatch 'Write-Error') {
            $suggestions.BestPractices += "Empty or incomplete error handling detected"
        }
        
        return $suggestions
    }
}

# Main execution
Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║           PowerShell Script Performance Analyzer            ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script not found: $ScriptPath"
    return
}

$benchmark = [PerformanceBenchmark]::new($ScriptPath)
$results = $benchmark.RunBenchmark($Iterations)

Write-Host "`n📊 Performance Results:" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Gray

Write-Host "`n⏱️  Execution Time:" -ForegroundColor Yellow
Write-Host "   Average: $([Math]::Round($results.Statistics.ExecutionTime.Average, 2)) ms" -ForegroundColor White
Write-Host "   Min: $([Math]::Round($results.Statistics.ExecutionTime.Min, 2)) ms | Max: $([Math]::Round($results.Statistics.ExecutionTime.Max, 2)) ms" -ForegroundColor Gray
Write-Host "   Std Dev: $([Math]::Round($results.Statistics.ExecutionTime.StdDev, 2)) ms" -ForegroundColor Gray

Write-Host "`n💾 Memory Usage:" -ForegroundColor Yellow
Write-Host "   Average: $([Math]::Round($results.Statistics.MemoryUsage.Average, 2)) MB" -ForegroundColor White
Write-Host "   Min: $([Math]::Round($results.Statistics.MemoryUsage.Min, 2)) MB | Max: $([Math]::Round($results.Statistics.MemoryUsage.Max, 2)) MB" -ForegroundColor Gray

Write-Host "`n⚡ CPU Usage:" -ForegroundColor Yellow
Write-Host "   Average: $([Math]::Round($results.Statistics.CPUUsage.Average, 3)) seconds" -ForegroundColor White

Write-Host "`n✅ Reliability:" -ForegroundColor Yellow
$successRate = 100 - $results.Statistics.ErrorRate
$color = if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 90) { "Yellow" } else { "Red" }
Write-Host "   Success Rate: $([Math]::Round($successRate, 1))%" -ForegroundColor $color

if ($DetailedMetrics) {
    Write-Host "`n📈 Detailed Metrics:" -ForegroundColor Cyan
    Write-Host "Iteration | Time (ms) | Memory (MB) | CPU (s)" -ForegroundColor Gray
    Write-Host "----------|-----------|-------------|--------" -ForegroundColor Gray
    
    for ($i = 0; $i -lt $results.ExecutionTimes.Count; $i++) {
        $time = [Math]::Round($results.ExecutionTimes[$i], 2)
        $memory = [Math]::Round($results.MemoryUsage[$i], 2)
        $cpu = [Math]::Round($results.CPUUsage[$i], 3)
        Write-Host ("    {0,-5} | {1,9} | {2,11} | {3,7}" -f ($i+1), $time, $memory, $cpu)
    }
}

if ($CompareVersions -and $BaselineScript) {
    if (Test-Path $BaselineScript) {
        Write-Host "`n🔄 Comparing with baseline..." -ForegroundColor Cyan
        $baselineBenchmark = [PerformanceBenchmark]::new($BaselineScript)
        $baselineResults = $baselineBenchmark.RunBenchmark($Iterations)
        
        $improvement = (($baselineResults.Statistics.ExecutionTime.Average - $results.Statistics.ExecutionTime.Average) / $baselineResults.Statistics.ExecutionTime.Average) * 100
        
        if ($improvement -gt 0) {
            Write-Host "   Performance improved by $([Math]::Round($improvement, 1))%" -ForegroundColor Green
        } else {
            Write-Host "   Performance decreased by $([Math]::Round([Math]::Abs($improvement), 1))%" -ForegroundColor Red
        }
    }
}

# Performance optimization suggestions
Write-Host "`n💡 Optimization Suggestions:" -ForegroundColor Cyan
$optimizer = [PerformanceOptimizer]::new()
$suggestions = $optimizer.AnalyzeScript($ScriptPath)

foreach ($category in $suggestions.Keys) {
    if ($suggestions[$category].Count -gt 0) {
        Write-Host "`n$category:" -ForegroundColor Yellow
        foreach ($suggestion in $suggestions[$category]) {
            Write-Host "  • $suggestion" -ForegroundColor Gray
        }
    }
}

if ($ExportReport) {
    $htmlReport = $benchmark.GenerateHTMLReport($results)
    $htmlReport | Out-File $ReportPath -Encoding UTF8
    Write-Host "`n📄 Report exported to: $ReportPath" -ForegroundColor Green
}

Write-Host "`n═══════════════════════════════════════════" -ForegroundColor Gray