#Requires -Version 7.4
#Requires -Modules Az.Automation, Az.Resources

<#
.SYNOPSIS
    AutoUpdate Worker

.DESCRIPTION
    Azure automation runbook for automatically updating Azure Resource Optimization (ARO)
    Toolkit components including runbooks, variables, and schedules

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ConnectionName = "AzureRunAsConnection"
)

$ErrorActionPreference = 'Stop'

try {
    # Connect to Azure using Run As Connection
    $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName -ErrorAction Stop
    Write-Output "Logging in to Azure..."

    $connectParams = @{
        ServicePrincipal = $true
        ApplicationId = $servicePrincipalConnection.ApplicationId
        TenantId = $servicePrincipalConnection.TenantId
        CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    }

    Connect-AzAccount @connectParams -ErrorAction Stop
    Write-Output "Successfully connected to Azure"
}
catch {
    if (!$servicePrincipalConnection) {
        $errorMessage = "Connection '$ConnectionName' not found."
        Write-Error -Message $errorMessage
        throw $errorMessage
    } else {
        Write-Error -Message $_.Exception.Message
        throw
    }
}

try {
    Write-Output "AutoUpdate Worker execution starts..."

    # GitHub repository configuration
    $githubRootPath = "https://raw.githubusercontent.com/Microsoft/MSITARM"
    $githubBranch = "azure-resource-optimization-toolkit"
    $scriptPath = "azure-resource-optimization-toolkit/nestedtemplates"
    $fileName = "Automation.json"
    $githubFullPath = "$githubRootPath/$githubBranch/$scriptPath/$fileName"

    # Download template from GitHub
    $webClient = New-Object System.Net.WebClient
    Write-Output "Downloading the $fileName template from GitHub..."
    $localFilePath = Join-Path $PSScriptRoot $fileName
    $webClient.DownloadFile($githubFullPath, $localFilePath)

    # Parse JSON content
    $jsonContent = Get-Content -Path $localFilePath -Raw -ErrorAction Stop
    Write-Output "Deserializing the JSON..."
    $jsonData = ConvertFrom-Json -InputObject $jsonContent

    # Get Automation Account details
    Write-Output "Reading the Automation Account details..."
    $automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName' -ErrorAction Stop
    $aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName' -ErrorAction Stop

    $automationAccountDetails = Get-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $aroResourceGroupName -ErrorAction Stop
    $currentVersion = $automationAccountDetails.Tags.Values
    $updateVersion = $jsonData.variables.AROToolkitVersion

    # Check for version updates
    Write-Output "Checking the ARO Toolkit version..."
    $currentVersionCompare = New-Object System.Version($currentVersion)
    $updateVersionCompare = New-Object System.Version($updateVersion)
    $versionDiff = $updateVersionCompare.CompareTo($currentVersionCompare)

    if ($versionDiff -gt 0) {
        Write-Output "Current version is: $currentVersion"
        Write-Output "New version $updateVersion is available and performing the upgrade..."
        Write-Output "======================================"
        Write-Output "Checking for asset variable updates..."
        Write-Output "======================================"

        # Check for new variables
        $existingVariables = Get-AzAutomationVariable -AutomationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName |
            Select-Object -ExpandProperty Name |
            Sort-Object

        $newVariables = $jsonData.variables.PSObject.Properties.Name |
            Where-Object { $_ -match "Internal" -or $_ -match "External" } |
            Sort-Object

        $diffVariables = Compare-Object -ReferenceObject $newVariables -DifferenceObject $existingVariables |
            Where-Object { $_.SideIndicator -eq '<=' } |
            Select-Object -ExpandProperty InputObject

        if ($null -ne $diffVariables) {
            Write-Output "New asset variables found and creating now..."
            Write-Output $diffVariables

            $newResourceVariables = $jsonData.resources | ForEach-Object { $_.resources }

            foreach ($difv in $diffVariables) {
                foreach ($newvar in $newResourceVariables) {
                    if (($newvar.name -like "*$difv*") -and ($newvar.type -eq "variables")) {
                        [string[]]$rvarPropValArray = $newvar.properties.value.Split(",")

                        if ($rvarPropValArray.Count -gt 1 -and -not $rvarPropValArray[1].Contains('"')) {
                            [string]$rvarPropVal = $rvarPropValArray[1].Replace("'", "")
                        }
                        else {
                            $rvarPropVal = ""
                        }

                        $variableParams = @{
                            Name = $difv.Trim()
                            AutomationAccountName = $automationAccountName
                            ResourceGroupName = $aroResourceGroupName
                            Encrypted = $false
                            Value = $rvarPropVal.Trim()
                        }

                        New-AzAutomationVariable @variableParams -ErrorAction Stop
                        break
                    }
                }
            }
        }
        else {
            Write-Output "No updates needed for asset variables..."
        }

        Write-Output "================================="
        Write-Output "Checking for Runbooks updates..."
        Write-Output "================================="

        $runbooks = $jsonData.variables.runbooks.Values
        $runbookTable = [ordered]@{}

        foreach ($runb in $runbooks) {
            if ($runb.name -notlike "*Bootstrap*") {
                [string[]]$runbookScriptUri = $runb.scriptUri -split ","
                $cleanUri = $runbookScriptUri[1].Replace(")]", "").Replace("'", "")
                $runbookTable.Add($runb.name, $cleanUri)

                $currentRunbook = Get-AzAutomationRunbook -AutomationAccountName $automationAccountName `
                    -ResourceGroupName $aroResourceGroupName `
                    -Name $runb.name `
                    -ErrorAction SilentlyContinue

                if ($null -ne $currentRunbook) {
                    $currentRBversion = $currentRunbook.Tags.Values
                    $newVersion = $runb.version
                    $cvrbCompare = New-Object System.Version($currentRBversion)
                    $nvrbCompare = New-Object System.Version($newVersion)
                    $versionDiffRB = $nvrbCompare.CompareTo($cvrbCompare)

                    if ($versionDiffRB -gt 0) {
                        $runbookDownloadPath = "$githubRootPath/$githubBranch/azure-resource-optimization-toolkit$($runbookTable[$runb.name])"
                        Write-Output "Updates needed for $($runb.name)..."
                        Write-Output "Downloading the updated PowerShell script from GitHub..."

                        $webClientRB = New-Object System.Net.WebClient
                        $localRunbookPath = Join-Path $PSScriptRoot "$($runb.name).ps1"
                        $webClientRB.DownloadFile($runbookDownloadPath, $localRunbookPath)

                        Write-Output "Updating the Runbook content..."
                        $importParams = @{
                            AutomationAccountName = $automationAccountName
                            ResourceGroupName = $aroResourceGroupName
                            Path = $localRunbookPath
                            Name = $runb.name
                            Tags = @{version = $newVersion}
                            Force = $true
                            Type = "PowerShell"
                        }
                        Import-AzAutomationRunbook @importParams -ErrorAction Stop

                        Write-Output "Publishing the Runbook $($runb.name)..."
                        Publish-AzAutomationRunbook -AutomationAccountName $automationAccountName `
                            -ResourceGroupName $aroResourceGroupName `
                            -Name $runb.name `
                            -ErrorAction Stop
                    }
                }
                else {
                    $runbookDownloadPath = "$githubRootPath/$githubBranch/azure-resource-optimization-toolkit$($runbookTable[$runb.name])"
                    Write-Output "New Runbook $($runb.name) found..."
                    Write-Output "Downloading the PowerShell script from GitHub..."

                    $webClientRB = New-Object System.Net.WebClient
                    $localRunbookPath = Join-Path $PSScriptRoot "$($runb.name).ps1"
                    $webClientRB.DownloadFile($runbookDownloadPath, $localRunbookPath)

                    $newVersion = $runb.version
                    Write-Output "Creating the Runbook in the Automation Account..."

                    New-AzAutomationRunbook -Name $runb.name `
                        -AutomationAccountName $automationAccountName `
                        -ResourceGroupName $aroResourceGroupName `
                        -Type PowerShell `
                        -Description "New Runbook" `
                        -ErrorAction Stop

                    $importParams = @{
                        AutomationAccountName = $automationAccountName
                        ResourceGroupName = $aroResourceGroupName
                        Path = $localRunbookPath
                        Name = $runb.name
                        Force = $true
                        Type = "PowerShell"
                        Tags = @{version = $newVersion}
                    }
                    Import-AzAutomationRunbook @importParams -ErrorAction Stop

                    Write-Output "Publishing the new Runbook $($runb.name)..."
                    Publish-AzAutomationRunbook -AutomationAccountName $automationAccountName `
                        -ResourceGroupName $aroResourceGroupName `
                        -Name $runb.name `
                        -ErrorAction Stop
                }
            }
        }

        Write-Output "============================="
        Write-Output "Checking for new schedule..."
        Write-Output "============================="

        $bootstrapMainRunbook = "Bootstrap_Main"
        $runbookDownloadPath = "$githubRootPath/$githubBranch/demos/azure-resource-optimization-toolkit/scripts/Bootstrap_Main.ps1"
        Write-Output "Downloading the Bootstrap_Main PowerShell script from GitHub..."

        $webClientRB = New-Object System.Net.WebClient
        $localBootstrapPath = Join-Path $PSScriptRoot "$bootstrapMainRunbook.ps1"
        $webClientRB.DownloadFile($runbookDownloadPath, $localBootstrapPath)

        Write-Output "Creating the Runbook in the Automation Account..."
        New-AzAutomationRunbook -Name $bootstrapMainRunbook `
            -AutomationAccountName $automationAccountName `
            -ResourceGroupName $aroResourceGroupName `
            -Type PowerShell `
            -Description "Bootstrap Main Runbook" `
            -ErrorAction Stop

        Import-AzAutomationRunbook -AutomationAccountName $automationAccountName `
            -ResourceGroupName $aroResourceGroupName `
            -Path $localBootstrapPath `
            -Name $bootstrapMainRunbook `
            -Force `
            -Type PowerShell `
            -ErrorAction Stop

        Write-Output "Publishing the Bootstrap_Main Runbook..."
        Publish-AzAutomationRunbook -AutomationAccountName $automationAccountName `
            -ResourceGroupName $aroResourceGroupName `
            -Name $bootstrapMainRunbook `
            -ErrorAction Stop

        Start-AzAutomationRunbook -Name $bootstrapMainRunbook `
            -AutomationAccountName $automationAccountName `
            -ResourceGroupName $aroResourceGroupName `
            -Wait `
            -ErrorAction Stop

        Set-AzAutomationAccount -Name $automationAccountName `
            -ResourceGroupName $aroResourceGroupName `
            -Tags @{AROToolkitVersion = $updateVersion} `
            -ErrorAction Stop
    }
    elseif ($versionDiff -le 0) {
        Write-Output "You have the latest version of ARO Toolkit - no update needed"
    }

    Write-Output "AutoUpdate worker execution completed"
}
catch {
    Write-Error "Error occurred in the AutoUpdate worker runbook: $($_.Exception.Message)"
    throw
}