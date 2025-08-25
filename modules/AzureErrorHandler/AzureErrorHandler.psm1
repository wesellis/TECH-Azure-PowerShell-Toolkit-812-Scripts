# AzureErrorHandler.psm1
# Comprehensive error handling module for Azure PowerShell scripts
# Author: Wesley Ellis | Enhanced by AI
# Version: 2.0

$ErrorActionPreference = 'Stop'

# Error tracking
$Global:AzureErrorLog = @()
$Global:ErrorMetrics = @{
    TotalErrors = 0
    ErrorsByType = @{}
    ErrorsByScript = @{}
    LastError = $null
}

function Initialize-ErrorHandling {
    param(
        [string]$LogPath = "$env:TEMP\azure-errors.log",
        [switch]$EnableTelemetry,
        [switch]$EnableAutoRetry
    )
    
    $Global:ErrorHandlingConfig = @{
        LogPath = $LogPath
        EnableTelemetry = $EnableTelemetry
        EnableAutoRetry = $EnableAutoRetry
        RetryCount = 3
        RetryDelay = 5
    }
    
    # Set up error trap
    $Global:ErrorActionPreference = 'Stop'
    
    Write-Verbose "Error handling initialized with configuration:"
    Write-Verbose ($Global:ErrorHandlingConfig | ConvertTo-Json)
}

function Invoke-AzureOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$Operation,
        
        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Azure Operation",
        
        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$RetryDelaySeconds = 5,
        
        [Parameter(Mandatory=$false)]
        [ScriptBlock]$ErrorHandler,
        
        [Parameter(Mandatory=$false)]
        [ScriptBlock]$FinallyBlock,
        
        [switch]$ContinueOnError
    )
    
    $attempt = 0
    $success = $false
    $lastError = $null
    
    while ($attempt -lt $MaxRetries -and -not $success) {
        $attempt++
        
        try {
            Write-Verbose "Executing $OperationName (Attempt $attempt of $MaxRetries)"
            
            $result = & $Operation
            $success = $true
            
            Write-Verbose "$OperationName completed successfully"
            return $result
            
        } catch {
            $lastError = $_
            $errorDetails = Get-DetailedError -ErrorRecord $_
            
            # Log the error
            Add-ErrorLog -ErrorDetails $errorDetails -OperationName $OperationName
            
            # Check if error is retryable
            if (Test-RetryableError -ErrorRecord $_) {
                if ($attempt -lt $MaxRetries) {
                    Write-Warning "$OperationName failed (Attempt $attempt). Retrying in $RetryDelaySeconds seconds..."
                    Write-Warning "Error: $($_.Exception.Message)"
                    Start-Sleep -Seconds $RetryDelaySeconds
                    
                    # Exponential backoff
                    $RetryDelaySeconds = $RetryDelaySeconds * 2
                } else {
                    Write-Error "$OperationName failed after $MaxRetries attempts"
                }
            } else {
                # Non-retryable error
                Write-Verbose "Non-retryable error encountered"
                break
            }
        }
    }
    
    # Handle final failure
    if (-not $success) {
        if ($ErrorHandler) {
            Write-Verbose "Executing custom error handler"
            & $ErrorHandler -ErrorRecord $lastError
        }
        
        if ($FinallyBlock) {
            Write-Verbose "Executing finally block"
            & $FinallyBlock
        }
        
        if (-not $ContinueOnError) {
            throw $lastError
        } else {
            Write-Warning "$OperationName failed but continuing due to -ContinueOnError flag"
            return $null
        }
    }
}

function Get-DetailedError {
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    $details = @{
        Message = $ErrorRecord.Exception.Message
        Type = $ErrorRecord.Exception.GetType().FullName
        ScriptName = $ErrorRecord.InvocationInfo.ScriptName
        LineNumber = $ErrorRecord.InvocationInfo.ScriptLineNumber
        Command = $ErrorRecord.InvocationInfo.Line
        Category = $ErrorRecord.CategoryInfo.Category
        ErrorId = $ErrorRecord.FullyQualifiedErrorId
        Timestamp = Get-Date
        StackTrace = $ErrorRecord.ScriptStackTrace
    }
    
    # Extract Azure-specific error details if available
    if ($ErrorRecord.Exception.Response) {
        $response = $ErrorRecord.Exception.Response
        $details.StatusCode = $response.StatusCode
        $details.ReasonPhrase = $response.ReasonPhrase
        
        if ($response.Content) {
            $stream = $response.Content.ReadAsStreamAsync().Result
            $reader = New-Object System.IO.StreamReader($stream)
            $details.ResponseContent = $reader.ReadToEnd()
        }
    }
    
    # Check for request ID (Azure specific)
    if ($ErrorRecord.Exception.RequestId) {
        $details.RequestId = $ErrorRecord.Exception.RequestId
    }
    
    return $details
}

function Test-RetryableError {
    param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    $retryableErrors = @(
        "TooManyRequests",
        "RequestTimeout",
        "ServiceUnavailable",
        "GatewayTimeout",
        "NetworkError",
        "TemporaryFailure",
        "Throttled"
    )
    
    $errorMessage = $ErrorRecord.Exception.Message
    $errorType = $ErrorRecord.Exception.GetType().Name
    
    # Check status code for HTTP errors
    if ($ErrorRecord.Exception.Response) {
        $statusCode = [int]$ErrorRecord.Exception.Response.StatusCode
        if ($statusCode -in @(429, 500, 502, 503, 504)) {
            return $true
        }
    }
    
    # Check error message for retryable patterns
    foreach ($pattern in $retryableErrors) {
        if ($errorMessage -match $pattern -or $errorType -match $pattern) {
            return $true
        }
    }
    
    return $false
}

function Add-ErrorLog {
    param(
        [hashtable]$ErrorDetails,
        [string]$OperationName
    )
    
    $Global:AzureErrorLog += $ErrorDetails
    $Global:ErrorMetrics.TotalErrors++
    
    # Update error metrics
    $errorType = $ErrorDetails.Type
    if (-not $Global:ErrorMetrics.ErrorsByType.ContainsKey($errorType)) {
        $Global:ErrorMetrics.ErrorsByType[$errorType] = 0
    }
    $Global:ErrorMetrics.ErrorsByType[$errorType]++
    
    $scriptName = if ($ErrorDetails.ScriptName) { 
        Split-Path $ErrorDetails.ScriptName -Leaf 
    } else { 
        "Unknown" 
    }
    
    if (-not $Global:ErrorMetrics.ErrorsByScript.ContainsKey($scriptName)) {
        $Global:ErrorMetrics.ErrorsByScript[$scriptName] = 0
    }
    $Global:ErrorMetrics.ErrorsByScript[$scriptName]++
    
    $Global:ErrorMetrics.LastError = $ErrorDetails
    
    # Write to log file if configured
    if ($Global:ErrorHandlingConfig -and $Global:ErrorHandlingConfig.LogPath) {
        $logEntry = @{
            Timestamp = $ErrorDetails.Timestamp
            Operation = $OperationName
            Error = $ErrorDetails.Message
            Type = $ErrorDetails.Type
            Script = $scriptName
            Line = $ErrorDetails.LineNumber
        } | ConvertTo-Json -Compress
        
        Add-Content -Path $Global:ErrorHandlingConfig.LogPath -Value $logEntry
    }
}

function Get-ErrorReport {
    param(
        [switch]$Summary,
        [switch]$Detailed,
        [switch]$ExportHtml,
        [string]$OutputPath = ".\error-report.html"
    )
    
    if ($Summary) {
        return @{
            TotalErrors = $Global:ErrorMetrics.TotalErrors
            UniqueErrorTypes = $Global:ErrorMetrics.ErrorsByType.Count
            AffectedScripts = $Global:ErrorMetrics.ErrorsByScript.Count
            MostCommonError = ($Global:ErrorMetrics.ErrorsByType.GetEnumerator() | 
                Sort-Object Value -Descending | Select-Object -First 1).Key
            LastError = $Global:ErrorMetrics.LastError.Message
        }
    }
    
    if ($Detailed) {
        return $Global:AzureErrorLog
    }
    
    if ($ExportHtml) {
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Error Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #d73a49; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #f6f8fa; padding: 10px; text-align: left; border: 1px solid #ddd; }
        td { padding: 10px; border: 1px solid #ddd; }
        .error-type { color: #d73a49; font-weight: bold; }
        .metric { background: #f0f0f0; padding: 10px; margin: 10px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Azure Error Report</h1>
    <div class="metric">
        <h2>Summary</h2>
        <p>Total Errors: $($Global:ErrorMetrics.TotalErrors)</p>
        <p>Unique Error Types: $($Global:ErrorMetrics.ErrorsByType.Count)</p>
        <p>Affected Scripts: $($Global:ErrorMetrics.ErrorsByScript.Count)</p>
    </div>
    
    <h2>Error Details</h2>
    <table>
        <thead>
            <tr>
                <th>Timestamp</th>
                <th>Type</th>
                <th>Message</th>
                <th>Script</th>
                <th>Line</th>
            </tr>
        </thead>
        <tbody>
"@
        
        foreach ($error in $Global:AzureErrorLog) {
            $html += @"
            <tr>
                <td>$($error.Timestamp)</td>
                <td class="error-type">$($error.Type)</td>
                <td>$($error.Message)</td>
                <td>$($error.ScriptName)</td>
                <td>$($error.LineNumber)</td>
            </tr>
"@
        }
        
        $html += @"
        </tbody>
    </table>
</body>
</html>
"@
        
        $html | Out-File $OutputPath -Encoding UTF8
        Write-Host "Error report exported to: $OutputPath" -ForegroundColor Green
    }
}

function Clear-ErrorLog {
    $Global:AzureErrorLog = @()
    $Global:ErrorMetrics = @{
        TotalErrors = 0
        ErrorsByType = @{}
        ErrorsByScript = @{}
        LastError = $null
    }
    
    Write-Verbose "Error log cleared"
}

function Test-AzureConnection {
    param(
        [switch]$ThrowOnFailure
    )
    
    try {
        $context = Get-AzContext
        if (-not $context) {
            if ($ThrowOnFailure) {
                throw "Not connected to Azure. Please run Connect-AzAccount"
            }
            return $false
        }
        return $true
    } catch {
        if ($ThrowOnFailure) {
            throw $_
        }
        return $false
    }
}

function Assert-AzureResource {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceId,
        
        [Parameter(Mandatory=$false)]
        [string]$ResourceType,
        
        [switch]$CreateIfNotExists
    )
    
    try {
        $resource = Get-AzResource -ResourceId $ResourceId -ErrorAction Stop
        Write-Verbose "Resource exists: $ResourceId"
        return $resource
    } catch {
        if ($CreateIfNotExists) {
            Write-Warning "Resource not found. Creating: $ResourceId"
            # Implementation would depend on resource type
            throw "CreateIfNotExists not yet implemented for $ResourceType"
        } else {
            throw "Resource not found: $ResourceId"
        }
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-ErrorHandling',
    'Invoke-AzureOperation',
    'Get-DetailedError',
    'Test-RetryableError',
    'Add-ErrorLog',
    'Get-ErrorReport',
    'Clear-ErrorLog',
    'Test-AzureConnection',
    'Assert-AzureResource'
)