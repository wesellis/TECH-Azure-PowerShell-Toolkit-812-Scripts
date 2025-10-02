#Requires -Version 7.4
#Requires -Modules Az.Automation

<#
.SYNOPSIS
    ARO Toolkit Auto Update

.DESCRIPTION
    Azure Resource Optimization Toolkit auto update module for future releases

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AutomationAccountName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$ConnectionName = "AzureRunAsConnection",

    [Parameter()]
    [string]$GithubBranch = "azure-resource-optimization-toolkit",

    [Parameter()]
    [string]$WorkerFileName = "AutoUpdateWorker.ps1"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    # Connect to Azure using Run As Connection
    $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName -ErrorAction Stop
    Write-Output "Logging in to Azure using service principal..."

    $connectParams = @{
        ApplicationId = $servicePrincipalConnection.ApplicationId
        TenantId = $servicePrincipalConnection.TenantId
        CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    }

    Connect-AzAccount -ServicePrincipal @connectParams -ErrorAction Stop
    Write-Output "Successfully connected to Azure"
}
catch {
    if (!$servicePrincipalConnection) {
        $errorMessage = "Connection '$ConnectionName' not found."
        Write-Error -Message $errorMessage
        throw $errorMessage
    } else {
        Write-Error -Message "Failed to connect to Azure: $($_.Exception.Message)"
        throw
    }
}

try {
    Write-Output "AutoUpdate Wrapper execution starts..."

    # GitHub paths
    $githubRootPath = "https://raw.githubusercontent.com/Microsoft/MSITARM"
    $scriptPath = "azure-resource-optimization-toolkit/scripts"
    $githubFullPath = "$githubRootPath/$GithubBranch/$scriptPath/$WorkerFileName"

    Write-Output "Downloading AutoUpdateWorker script from GitHub: $githubFullPath"

    # Download the script
    $tempPath = "$env:TEMP\$WorkerFileName"
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($githubFullPath, $tempPath)

    Write-Output "Downloaded script to: $tempPath"

    # Prepare runbook
    $runbookName = [System.IO.Path]::GetFileNameWithoutExtension($WorkerFileName)
    Write-Output "Creating worker runbook '$runbookName' in Automation Account..."

    # Create new runbook
    $newRunbookParams = @{
        Name = $runbookName
        AutomationAccountName = $AutomationAccountName
        ResourceGroupName = $ResourceGroupName
        Type = "PowerShell"
        Description = "Auto-update worker runbook for ARO Toolkit"
    }

    New-AzAutomationRunbook @newRunbookParams -ErrorAction Stop

    # Import runbook content
    $importParams = @{
        AutomationAccountName = $AutomationAccountName
        ResourceGroupName = $ResourceGroupName
        Path = $tempPath
        Name = $runbookName
        Force = $true
        Type = "PowerShell"
    }

    Import-AzAutomationRunbook @importParams -ErrorAction Stop

    Write-Output "Publishing runbook '$runbookName'..."
    Publish-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Name $runbookName -ErrorAction Stop

    Write-Output "Executing runbook '$runbookName'..."
    $job = Start-AzAutomationRunbook -Name $runbookName -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Wait -ErrorAction Stop

    Write-Output "Runbook execution completed. Job status: $($job.Status)"

    # Clean up
    Write-Output "Cleaning up temporary runbook..."
    Remove-AzAutomationRunbook -Name $runbookName -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Force -ErrorAction Stop

    # Clean up temp file
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force
    }

    Write-Output "AutoUpdate Wrapper execution completed successfully"
}
catch {
    Write-Error "Error occurred in AutoUpdate wrapper: $($_.Exception.Message)"
    throw
}