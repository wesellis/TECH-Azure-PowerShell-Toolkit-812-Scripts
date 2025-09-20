<#
.SYNOPSIS
    AI Assistant
.DESCRIPTION
    NOTES
    Author: Wes Ellis (wes@wesellis.com)#>
# AI-Assistant.ps1
# Natural Language AI Assistant for Azure PowerShell Scripts
# Version: 3.0

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Query,
    
    [switch]$Voice,
    [switch]$Interactive,
    [switch]$GenerateScript,
    [string]$Model = "gpt-4"
)

#region Functions

$Global:AssistantConfig = @{
    ScriptsPath = Join-Path $PSScriptRoot "automation-scripts"
    CachePath = Join-Path $env:TEMP "azure-ai-cache"
    HistoryFile = Join-Path $env:USERPROFILE ".azure-ai-history.json"
    MaxTokens = 2000
}

# Ensure cache directory exists
if (-not (Test-Path $Global:AssistantConfig.CachePath)) {
    New-Item -ItemType Directory -Path $Global:AssistantConfig.CachePath -Force | Out-Null
}

class NaturalLanguageProcessor {
    [hashtable]$IntentMap = @{
        "create" = @("create", "make", "build", "deploy", "provision", "setup", "initialize")
        "delete" = @("delete", "remove", "destroy", "terminate", "cleanup", "purge")
        "list" = @("list", "show", "display", "get", "find", "search", "query")
        "update" = @("update", "modify", "change", "configure", "set", "adjust")
        "monitor" = @("monitor", "watch", "track", "observe", "check", "inspect")
        "analyze" = @("analyze", "review", "audit", "assess", "evaluate", "examine")
        "optimize" = @("optimize", "improve", "enhance", "tune", "refine")
        "secure" = @("secure", "protect", "harden", "encrypt", "lock")
        "backup" = @("backup", "save", "archive", "snapshot", "preserve")
        "restore" = @("restore", "recover", "rollback", "revert")
    }
    
    [hashtable]$ResourceMap = @{
        "vm" = @("vm", "virtual machine", "compute", "server", "instance")
        "storage" = @("storage", "blob", "file", "disk", "container")
        "network" = @("network", "vnet", "subnet", "nsg", "firewall", "load balancer")
        "database" = @("database", "sql", "cosmos", "mysql", "postgresql")
        "webapp" = @("web app", "app service", "website", "api")
        "function" = @("function", "serverless", "lambda")
        "aks" = @("kubernetes", "aks", "k8s", "container", "cluster")
        "keyvault" = @("key vault", "secrets", "certificates", "keys")
    }
    
    [object] ParseIntent([string]$Query) {
        $query = $Query.ToLower()
        $result = @{
            Intent = "unknown"
            Resource = "unknown"
            Action = ""
            Parameters = @{}
            Confidence = 0.0
        }
        
        # Detect intent
        foreach ($intent in $this.IntentMap.Keys) {
            foreach ($keyword in $this.IntentMap[$intent]) {
                if ($query -match "\b$keyword\b") {
                    $result.Intent = $intent
                    $result.Confidence += 0.3
                    break
                }
            }
        }
        
        # Detect resource
        foreach ($resource in $this.ResourceMap.Keys) {
            foreach ($keyword in $this.ResourceMap[$resource]) {
                if ($query -match $keyword) {
                    $result.Resource = $resource
                    $result.Confidence += 0.3
                    break
                }
            }
        }
        
        # Extract parameters
        if ($query -match "in\s+([a-z\s]+)\s*(?:resource group|rg)?") {
            $result.Parameters.ResourceGroup = $Matches[1].Trim()
        }
        
        if ($query -match "(?:named?|called?)\s+([a-z0-9-]+)") {
            $result.Parameters.Name = $Matches[1]
        }
        
        if ($query -match "in\s+(east us|west us|central us|north europe|west europe)") {
            $result.Parameters.Location = $Matches[1]
        }
        
        # Build action string
        $result.Action = "$($result.Intent)_$($result.Resource)"
        
        # Adjust confidence based on completeness
        if ($result.Intent -ne "unknown" -and $result.Resource -ne "unknown") {
            $result.Confidence = [Math]::Min($result.Confidence + 0.4, 1.0)
        }
        
        return $result
    }
    
    [string] GenerateScript([object]$Intent) {
        $scriptTemplates = @{
            "create_vm" = @'
# Create Virtual Machine
$vmName = "{Name}"
$resourceGroup = "{ResourceGroup}"
$location = "{Location}"

# Create VM configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_B2s"
$vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential (Get-Credential)
$vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest"

# Create the VM
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig
'@
            
            "list_vm" = @'
# List Virtual Machines
Get-AzVM {ResourceGroup} | Select-Object Name, ResourceGroupName, Location, @{N="Status";E={(Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Status).Statuses[1].DisplayStatus}}
'@
            
            "delete_vm" = @'
# Delete Virtual Machine
Remove-AzVM -ResourceGroupName "{ResourceGroup}" -Name "{Name}" -Force
'@
            
            "create_storage" = @'
# Create Storage Account
$storageAccountName = "{Name}".ToLower() -replace '[^a-z0-9]', ''
New-AzStorageAccount -ResourceGroupName "{ResourceGroup}" -Name $storageAccountName -Location "{Location}" -SkuName Standard_LRS -Kind StorageV2
'@
            
            "secure_storage" = @'
# Secure Storage Account
$storage = Get-AzStorageAccount -ResourceGroupName "{ResourceGroup}" -Name "{Name}"
Set-AzStorageAccount -ResourceGroupName "{ResourceGroup}" -Name "{Name}" -EnableHttpsTrafficOnly $true -MinimumTlsVersion TLS1_2
'@
        }
        
        $templateKey = $Intent.Action
        if (-not $scriptTemplates.ContainsKey($templateKey)) {
            return "# Unable to generate script for: $templateKey`n# Please provide more specific requirements"
        }
        
        $script = $scriptTemplates[$templateKey]
        
        # Replace placeholders
        foreach ($param in $Intent.Parameters.Keys) {
            $script = $script -replace "{$param}", $Intent.Parameters[$param]
        }
        
        # Handle optional ResourceGroup parameter
        if ($Intent.Parameters.ResourceGroup) {
            $script = $script -replace "{ResourceGroup}", "-ResourceGroupName '$($Intent.Parameters.ResourceGroup)'"
        } else {
            $script = $script -replace "{ResourceGroup}", ""
        }
        
        # Set defaults for missing parameters
        $script = $script -replace "{Location}", "eastus"
        $script = $script -replace "{Name}", "resource-$(Get-Random -Maximum 9999)"
        
        return $script
    }
}

class ScriptRecommendationEngine {
    [array]$Scripts = @()
    [hashtable]$Index = @{}
    
    ScriptRecommendationEngine() {
        $this.BuildIndex()
    }
    
    [void] BuildIndex() {
        Write-Host "Building script index..." -ForegroundColor Cyan
        
        $scriptFiles = Get-ChildItem -Path $Global:AssistantConfig.ScriptsPath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
        
        foreach ($script in $scriptFiles) {
            $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
            $metadata = @{
                Path = $script.FullName
                Name = $script.BaseName
                Category = Split-Path (Split-Path $script.FullName -Parent) -Leaf
                Keywords = @()
                Description = ""
                Relevance = 0
            }
            
            # Extract description
            if ($content -match '\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|$)') {
                $metadata.Description = $Matches[1].Trim()
            }
            
            # Extract keywords from name and content
            $words = ($script.BaseName -split '-|_') + ($metadata.Description -split '\s+')
            $metadata.Keywords = $words | Where-Object { $_.Length -gt 3 } | Select-Object -Unique
            
            $this.Scripts += $metadata
            
            # Build inverted index
            foreach ($keyword in $metadata.Keywords) {
                $keyword = $keyword.ToLower()
                if (-not $this.Index.ContainsKey($keyword)) {
                    $this.Index[$keyword] = @()
                }
                $this.Index[$keyword] += $metadata
            }
        }
        
        Write-Host "Indexed $($this.Scripts.Count) scripts" -ForegroundColor Green
    }
    
    [array] FindRelevantScripts([string]$Query, [int]$TopK = 5) {
        $query = $Query.ToLower()
        $queryWords = $query -split '\s+' | Where-Object { $_.Length -gt 2 }
        
        $scores = @{}
        
        foreach ($word in $queryWords) {
            if ($this.Index.ContainsKey($word)) {
                foreach ($script in $this.Index[$word]) {
                    if (-not $scores.ContainsKey($script.Path)) {
                        $scores[$script.Path] = 0
                    }
                    $scores[$script.Path]++
                }
            }
        }
        
        # Sort by relevance and return top K
        $ranked = $scores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $TopK
        
        $results = @()
        foreach ($item in $ranked) {
            $script = $this.Scripts | Where-Object { $_.Path -eq $item.Key } | Select-Object -First 1
            if ($script) {
                $script.Relevance = $item.Value
                $results += $script
            }
        }
        
        return $results
    }
}

class ConversationContext {
    [array]$History = @()
    [hashtable]$Variables = @{}
    [string]$LastAction = ""
    
    [void] AddMessage([string]$Role, [string]$Content) {
        $this.History += @{
            Role = $Role
            Content = $Content
            Timestamp = Get-Date
        }
        
        # Keep only last 10 messages for context
        if ($this.History.Count -gt 10) {
            $this.History = $this.History | Select-Object -Last 10
        }
    }
    
    [string] GetContext() {
        $context = "Previous conversation:`n"
        foreach ($msg in $this.History) {
            $context += "$($msg.Role): $($msg.Content)`n"
        }
        return $context
    }
    
    [void] SaveHistory() {
        $this.History | ConvertTo-Json | Out-File $Global:AssistantConfig.HistoryFile -Encoding UTF8
    }
    
    [void] LoadHistory() {
        if (Test-Path $Global:AssistantConfig.HistoryFile) {
            $this.History = Get-Content $Global:AssistantConfig.HistoryFile | ConvertFrom-Json
        }
    }
}

function Invoke-AIAssistant {
    param([string]$Query)
    
    $nlp = [NaturalLanguageProcessor]::new()
    $recommender = [ScriptRecommendationEngine]::new()
    $context = [ConversationContext]::new()
    
    Write-Host "`n� AI Assistant Processing..." -ForegroundColor Cyan
    
    # Parse intent
    $intent = $nlp.ParseIntent($Query)
    
    Write-Host "`n Analysis Results:" -ForegroundColor Yellow
    Write-Host "Intent: $($intent.Intent)" -ForegroundColor White
    Write-Host "Resource: $($intent.Resource)" -ForegroundColor White
    Write-Host "Confidence: $([Math]::Round($intent.Confidence * 100))%" -ForegroundColor White
    
    if ($intent.Parameters.Count -gt 0) {
        Write-Host "Parameters:" -ForegroundColor White
        foreach ($param in $intent.Parameters.Keys) {
            Write-Host "  $param : $($intent.Parameters[$param])" -ForegroundColor Gray
        }
    }
    
    # Find relevant scripts
    Write-Host "`n Relevant Scripts:" -ForegroundColor Yellow
    $scripts = $recommender.FindRelevantScripts($Query)
    
    if ($scripts.Count -gt 0) {
        foreach ($script in $scripts) {
            Write-Host "[FILE] $($script.Name)" -ForegroundColor Green
            Write-Host "   $($script.Description)" -ForegroundColor Gray
            Write-Host "   Category: $($script.Category) | Relevance: $($script.Relevance)" -ForegroundColor DarkGray
        }
        
        Write-Host "`n�� Suggested Command:" -ForegroundColor Cyan
        $suggestedScript = $scripts[0]
        Write-Host "& '$($suggestedScript.Path)'" -ForegroundColor White
    }
    
    # Generate script if requested
    if ($GenerateScript -or $intent.Confidence -gt 0.7) {
        Write-Host "`n Generated Script:" -ForegroundColor Yellow
        $generatedScript = $nlp.GenerateScript($intent)
        Write-Host $generatedScript -ForegroundColor White
        
        # Save to file if high confidence
        if ($intent.Confidence -gt 0.8) {
            $scriptPath = Join-Path $Global:AssistantConfig.CachePath "generated_$($intent.Action)_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
            $generatedScript | Out-File $scriptPath -Encoding UTF8
            Write-Host "`n Script saved to: $scriptPath" -ForegroundColor Green
        }
    }
    
    # Provide recommendations
    Write-Host "`n Recommendations:" -ForegroundColor Cyan
    switch ($intent.Intent) {
        "create" {
            Write-Host "Ensure resource group exists before creating resources" -ForegroundColor White
            Write-Host "Apply appropriate tags for cost tracking" -ForegroundColor White
            Write-Host "Consider using ARM templates for repeatability" -ForegroundColor White
        }
        "delete" {
            Write-Host " [WARN] Verify resource dependencies before deletion" -ForegroundColor Yellow
            Write-Host "Consider backing up data first" -ForegroundColor White
            Write-Host "Use -WhatIf parameter to preview changes" -ForegroundColor White
        }
        "secure" {
            Write-Host "Enable encryption at rest and in transit" -ForegroundColor White
            Write-Host "Configure network security groups" -ForegroundColor White
            Write-Host "Implement Azure Key Vault for secrets" -ForegroundColor White
        }
        default {
            Write-Host "Review Azure best practices documentation" -ForegroundColor White
            Write-Host "Test in non-production environment first" -ForegroundColor White
        }
    }
    
    # Save context
    $context.AddMessage("User", $Query)
    $context.AddMessage("Assistant", "Processed intent: $($intent.Intent) for $($intent.Resource)")
    $context.SaveHistory()
}

function Start-InteractiveAssistant {
    Write-Host @"

�         Azure AI Assistant - Natural Language Mode          �
�                    Powered by NLP                  �

"@ -ForegroundColor Cyan
    
    Write-Host "`nExamples:" -ForegroundColor Yellow
    Write-Host "   'Create a virtual machine in production resource group'" -ForegroundColor Gray
    Write-Host "   'List all storage accounts'" -ForegroundColor Gray
    Write-Host "   'Secure my web app named myapp'" -ForegroundColor Gray
    Write-Host "   'Optimize costs for development environment'" -ForegroundColor Gray
    Write-Host "`nType 'exit' to quit`n" -ForegroundColor DarkGray
    
    $context = [ConversationContext]::new()
    $context.LoadHistory()
    
    while ($true) {
        Write-Host "`n�� " -NoNewline -ForegroundColor Cyan
        $userInput = Read-Host "How can I help you with Azure"
        
        if ($userInput -eq 'exit' -or $userInput -eq 'quit') {
            Write-Host "`n�� Goodbye!" -ForegroundColor Green
            break
        }
        
        if ($userInput -eq 'history') {
            Write-Host "`n�� Conversation History:" -ForegroundColor Yellow
            $context.History | ForEach-Object {
                Write-Host "$($_.Role): $($_.Content)" -ForegroundColor Gray
            }
            continue
        }
        
        if ($userInput -eq 'clear') {
            Clear-Host
            continue
        }
        
        Invoke-AIAssistant -Query $userInput
    }
}

# Voice interface (Windows only)
function Start-VoiceInterface {
    if ($PSVersionTable.Platform -ne 'Win32NT') {
        Write-Host "Voice interface is only available on Windows" -ForegroundColor Yellow
        return
    }
    
    Add-Type -AssemblyName System.Speech
    $speech = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    $speech.SetInputToDefaultAudioDevice()
    
    $grammar = New-Object System.Speech.Recognition.GrammarBuilder
    $grammar.Append("Azure")
    $grammar.AppendWildcard()
    
    $speechGrammar = New-Object System.Speech.Recognition.Grammar($grammar)
    $speech.LoadGrammar($speechGrammar)
    
    Write-Host "�� Voice interface active. Say 'Azure' followed by your command..." -ForegroundColor Cyan
    
    Register-ObjectEvent -InputObject $speech -EventName SpeechRecognized -Action {
        $result = $event.SourceEventArgs.Result.Text
        Write-Host "`n�� Heard: $result" -ForegroundColor Yellow
        Invoke-AIAssistant -Query $result
    }
    
    $speech.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)
    
    Write-Host "Press any key to stop listening..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $speech.RecognizeAsyncStop()
}

# Main execution
if ($Interactive) {
    Start-InteractiveAssistant
} elseif ($Voice) {
    Start-VoiceInterface
} elseif ($Query) {
    $queryString = $Query -join ' '
    Invoke-AIAssistant -Query $queryString
} else {
    # Default to interactive mode
    Start-InteractiveAssistant
}

#endregion

