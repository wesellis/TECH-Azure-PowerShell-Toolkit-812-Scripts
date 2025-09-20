#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Get available VM sizes

.DESCRIPTION
    List available VM sizes in a specified Azure location
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER Location
    Azure location to query for available VM sizes

.PARAMETER OutputFormat
    Output format for the results (Table, List, CSV, JSON)

.PARAMETER FilterByFamily
    Filter results by VM family (e.g., Standard_D, Standard_F)

.PARAMETER SortBy
    Sort results by property (Name, NumberOfCores, MemoryInMB, MaxDataDiskCount)

.PARAMETER ExportPath
    Path to export results to a file (optional)

.EXAMPLE
    .\Get-VMSizes.ps1 -Location 'CanadaCentral'
    
.EXAMPLE
    .\Get-VMSizes.ps1 -Location 'EastUS' -OutputFormat 'List'
    
.EXAMPLE
    .\Get-VMSizes.ps1 -Location 'WestUS2' -FilterByFamily 'Standard_D' -SortBy 'NumberOfCores'
    
.EXAMPLE
    .\Get-VMSizes.ps1 -Location 'EastUS' -OutputFormat 'CSV' -ExportPath 'C:\temp\vm-sizes.csv'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    
    [Parameter()]
    [ValidateSet("Table", "List", "CSV", "JSON")]
    [string]$OutputFormat = "Table",
    
    [Parameter()]
    [string]$FilterByFamily,
    
    [Parameter()]
    [ValidateSet("Name", "NumberOfCores", "MemoryInMB", "MaxDataDiskCount", "OSDiskSizeInMB", "ResourceDiskSizeInMB")]
    [string]$SortBy = "Name",
    
    [Parameter()]
    [string]$ExportPath
)

# Set error handling preference
$ErrorActionPreference = "Stop"

# Custom logging function
function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    
    $logEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

try {
    Write-LogMessage "Starting VM sizes query for location: $Location" -Level "INFO"
    
    # Validate Azure context
    $context = Get-AzContext
    if (-not $context) {
        throw "No Azure context found. Please run Connect-AzAccount first."
    }
    
    Write-LogMessage "Using Azure subscription: $($context.Subscription.Name)" -Level "INFO"
    
    # Get available VM sizes
    Write-LogMessage "Retrieving available VM sizes..." -Level "INFO"
    $vmSizes = Get-AzVMSize -Location $Location -ErrorAction Stop
    
    if (-not $vmSizes) {
        throw "No VM sizes found for location '$Location'. Please verify the location name."
    }
    
    Write-LogMessage "Found $($vmSizes.Count) VM sizes in $Location" -Level "SUCCESS"
    
    # Apply filtering if specified
    if ($FilterByFamily) {
        Write-LogMessage "Filtering by VM family: $FilterByFamily" -Level "INFO"
        $vmSizes = $vmSizes | Where-Object { $_.Name -like "*$FilterByFamily*" }
        Write-LogMessage "After filtering: $($vmSizes.Count) VM sizes match the criteria" -Level "INFO"
    }
    
    # Sort the results
    Write-LogMessage "Sorting results by: $SortBy" -Level "INFO"
    $vmSizes = $vmSizes | Sort-Object $SortBy
    
    # Display results based on output format
    switch ($OutputFormat) {
        "Table" {
            Write-LogMessage "Displaying results in table format:" -Level "INFO"
            Write-Host ""
            $vmSizes | Format-Table -Property Name, NumberOfCores, MemoryInMB, MaxDataDiskCount, OSDiskSizeInMB, ResourceDiskSizeInMB -AutoSize
        }
        "List" {
            Write-LogMessage "Displaying results in list format:" -Level "INFO"
            Write-Host ""
            $vmSizes | Format-List -Property Name, NumberOfCores, MemoryInMB, MaxDataDiskCount, OSDiskSizeInMB, ResourceDiskSizeInMB
        }
        "CSV" {
            Write-LogMessage "Displaying results in CSV format:" -Level "INFO"
            Write-Host ""
            $vmSizes | ConvertTo-Csv -NoTypeInformation | Write-Host
        }
        "JSON" {
            Write-LogMessage "Displaying results in JSON format:" -Level "INFO"
            Write-Host ""
            $vmSizes | ConvertTo-Json -Depth 2 | Write-Host
        }
    }
    
    # Export to file if specified
    if ($ExportPath) {
        Write-LogMessage "Exporting results to: $ExportPath" -Level "INFO"
        
        $exportDir = Split-Path -Path $ExportPath -Parent
        if ($exportDir -and -not (Test-Path -Path $exportDir)) {
            New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
        }
        
        switch ($OutputFormat) {
            "CSV" {
                $vmSizes | Export-Csv -Path $ExportPath -NoTypeInformation -Force
            }
            "JSON" {
                $vmSizes | ConvertTo-Json -Depth 2 | Out-File -FilePath $ExportPath -Force
            }
            default {
                # For Table and List formats, export as CSV
                $vmSizes | Export-Csv -Path $ExportPath -NoTypeInformation -Force
            }
        }
        
        Write-LogMessage "Results exported successfully to $ExportPath" -Level "SUCCESS"
    }
    
    # Summary information
    Write-Host ""
    Write-LogMessage "Summary:" -Level "INFO"
    Write-LogMessage "  Location: $Location" -Level "INFO"
    Write-LogMessage "  Total VM sizes: $($vmSizes.Count)" -Level "INFO"
    
    if ($FilterByFamily) {
        Write-LogMessage "  Filter applied: $FilterByFamily" -Level "INFO"
    }
    
    Write-LogMessage "  Sorted by: $SortBy" -Level "INFO"
    Write-LogMessage "  Output format: $OutputFormat" -Level "INFO"
    
    if ($ExportPath) {
        Write-LogMessage "  Exported to: $ExportPath" -Level "INFO"
    }
    
    # Display some statistics
    $coreStats = $vmSizes | Measure-Object -Property NumberOfCores -Minimum -Maximum -Average
    $memoryStats = $vmSizes | Measure-Object -Property MemoryInMB -Minimum -Maximum -Average
    
    Write-Host ""
    Write-LogMessage "Statistics:" -Level "INFO"
    Write-LogMessage "  CPU Cores - Min: $($coreStats.Minimum), Max: $($coreStats.Maximum), Avg: $([math]::Round($coreStats.Average, 1))" -Level "INFO"
    Write-LogMessage "  Memory (MB) - Min: $($memoryStats.Minimum), Max: $($memoryStats.Maximum), Avg: $([math]::Round($memoryStats.Average, 0))" -Level "INFO"
    
    Write-LogMessage "`nVM sizes query completed successfully!" -Level "SUCCESS"

} catch {
    Write-LogMessage "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    throw
}
