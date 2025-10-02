#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure AI Assistant - Natural language interface for Azure operations

.DESCRIPTION
    Provides natural language processing for Azure resource management tasks

.PARAMETER Query
    Natural language query for Azure operations

.PARAMETER Voice
    Enable voice interface mode

.PARAMETER Interactive
    Start interactive mode

.PARAMETER GenerateScript
    Generate PowerShell script for the query

.PARAMETER Model
    AI model to use (default: gpt-4)

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
#>
param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Query,

    [switch]$Voice,
    [switch]$Interactive,
    [switch]$GenerateScript,
    [string]$Model = "gpt-4"
)

$Global:AssistantConfig = @{
    ScriptsPath = Join-Path $PSScriptRoot "automation-scripts"
    CachePath = Join-Path $env:TEMP "azure-ai-cache"
    HistoryFile = Join-Path $env:USERPROFILE ".azure-ai-history.json"
    MaxTokens = 2000
}

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

        foreach ($intent in $this.IntentMap.Keys) {
            foreach ($keyword in $this.IntentMap[$intent]) {
                if ($query -match "\b$keyword\b") {
                    $result.Intent = $intent
                    $result.Confidence += 0.3
                    break
                }
            }
        }

        foreach ($resource in $this.ResourceMap.Keys) {
            foreach ($keyword in $this.ResourceMap[$resource]) {
                if ($query -match $keyword) {
                    $result.Resource = $resource
                    $result.Confidence += 0.3
                    break
                }
            }
        }

        if ($query -match "in\s+([a-z\s]+)\s*(?:resource group|rg)?") {
            $result.Parameters.ResourceGroup = $Matches[1].Trim()
        }

        if ($query -match "(?:named?|called?)\s+([a-z0-9-]+)") {
            $result.Parameters.Name = $Matches[1]
        }

        if ($query -match "in\s+(east us|west us|central us|north europe|west europe)") {
            $result.Parameters.Location = $Matches[1]
        }

        $result.Action = "$($result.Intent)_$($result.Resource)"

        if ($result.Intent -ne "unknown" -and $result.Resource -ne "unknown") {
            $result.Confidence = [Math]::Min($result.Confidence + 0.4, 1.0)
        }

        return $result
    }

    [string] GenerateScript([object]$Intent) {
        $ScriptTemplates = @{
            "create_vm" = @'
$VmName = "{Name}"
$ResourceGroup = "{ResourceGroup}"
$location = "{Location}"

$VmConfig = New-AzVMConfig -VMName $VmName -VMSize "Standard_B2s"
$VmConfig = Set-AzVMOperatingSystem -VM $VmConfig -Windows -ComputerName $VmName -Credential (Get-Credential)
$VmsourceimageSplat = @{
    VM = $VmConfig
    PublisherName = "MicrosoftWindowsServer"
    Offer = "WindowsServer"
    Skus = "2019-Datacenter"
    Version = "latest"
}
$VmConfig = Set-AzVMSourceImage @VmsourceimageSplat

$VmSplat = @{
    ResourceGroupName = $ResourceGroup
    Location = $location
    VM = $VmConfig
}
New-AzVM @VmSplat
'@

            "list_vm" = @'
Get-AzVM {ResourceGroup} | Select-Object Name, ResourceGroupName, Location, @{N="Status";E={(Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Status).Statuses[1].DisplayStatus}}
'@

            "delete_vm" = @'
Remove-AzVM -ResourceGroupName "{ResourceGroup}" -Name "{Name}" -Force
'@

            "create_storage" = @'
$StorageAccountName = "{Name}".ToLower() -replace '[^a-z0-9]', ''
$StorageaccountSplat = @{
    ResourceGroupName = "{ResourceGroup}"
    Name = $StorageAccountName
    Location = "{Location}"
    SkuName = "Standard_LRS"
    Kind = "StorageV2"
}
New-AzStorageAccount @StorageaccountSplat
'@

            "secure_storage" = @'
$storage = Get-AzStorageAccount -ResourceGroupName "{ResourceGroup}" -Name "{Name}"
Set-AzStorageAccount -ResourceGroupName "{ResourceGroup}" -Name "{Name}" -EnableHttpsTrafficOnly $true -MinimumTlsVersion TLS1_2
'@
        }

        $TemplateKey = $Intent.Action
        if (-not $ScriptTemplates.ContainsKey($TemplateKey)) {
            return "Write-Warning 'Unable to generate script for: $TemplateKey'"
        }

        $script = $ScriptTemplates[$TemplateKey]

        foreach ($param in $Intent.Parameters.Keys) {
            $script = $script -replace "{$param}", $Intent.Parameters[$param]
        }

        if ($Intent.Parameters.ResourceGroup) {
            $script = $script -replace "{ResourceGroup}", "-ResourceGroupName '$($Intent.Parameters.ResourceGroup)'"
        } else {
            $script = $script -replace "{ResourceGroup}", ""
        }

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
        Write-Host "Building script index..." -ForegroundColor Yellow

        $ScriptFiles = Get-ChildItem -Path $Global:AssistantConfig.ScriptsPath -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue

        foreach ($script in $ScriptFiles) {
            $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
            $metadata = @{
                Path = $script.FullName
                Name = $script.BaseName
                Category = Split-Path (Split-Path $script.FullName -Parent) -Leaf
                Keywords = @()
                Description = ""
                Relevance = 0
            }

            if ($content -match '\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|$)') {
                $metadata.Description = $Matches[1].Trim()
            }

            $words = ($script.BaseName -split '-|_') + ($metadata.Description -split '\s+')
            $metadata.Keywords = $words | Where-Object { $_.Length -gt 3 } | Select-Object -Unique

            $this.Scripts += $metadata

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
        $QueryWords = $query -split '\s+' | Where-Object { $_.Length -gt 2 }

        $scores = @{}

        foreach ($word in $QueryWords) {
            if ($this.Index.ContainsKey($word)) {
                foreach ($script in $this.Index[$word]) {
                    if (-not $scores.ContainsKey($script.Path)) {
                        $scores[$script.Path] = 0
                    }
                    $scores[$script.Path]++
                }
            }
        }

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
    param(
        [string]$Query
    )

    $nlp = [NaturalLanguageProcessor]::new()
    $recommender = [ScriptRecommendationEngine]::new()
    $context = [ConversationContext]::new()

    Write-Host "`nAI Assistant Processing..." -ForegroundColor Cyan

    $intent = $nlp.ParseIntent($Query)

    Write-Host "`nAnalysis Results:" -ForegroundColor Yellow
    Write-Host "Intent: $($intent.Intent)" -ForegroundColor White
    Write-Host "Resource: $($intent.Resource)" -ForegroundColor White
    Write-Host "Confidence: $([Math]::Round($intent.Confidence * 100))%" -ForegroundColor White

    if ($intent.Parameters.Count -gt 0) {
        Write-Host "Parameters:" -ForegroundColor Yellow
        foreach ($param in $intent.Parameters.Keys) {
            Write-Host "  $param : $($intent.Parameters[$param])" -ForegroundColor Gray
        }
    }

    Write-Host "`nRelevant Scripts:" -ForegroundColor Yellow
    $scripts = $recommender.FindRelevantScripts($Query)

    if ($scripts.Count -gt 0) {
        foreach ($script in $scripts) {
            Write-Host "[FILE] $($script.Name)" -ForegroundColor Cyan
            Write-Host "   $($script.Description)" -ForegroundColor Gray
            Write-Host "   Category: $($script.Category) | Relevance: $($script.Relevance)" -ForegroundColor DarkGray
        }

        Write-Host "`nSuggested Command:" -ForegroundColor Yellow
        $SuggestedScript = $scripts[0]
        Write-Host "& '$($SuggestedScript.Path)'" -ForegroundColor White
    }

    if ($GenerateScript -or $intent.Confidence -gt 0.7) {
        Write-Host "`nGenerated Script:" -ForegroundColor Yellow
        $GeneratedScript = $nlp.GenerateScript($intent)
        Write-Host $GeneratedScript -ForegroundColor White

        if ($intent.Confidence -gt 0.8) {
            $ScriptPath = Join-Path $Global:AssistantConfig.CachePath "generated_$($intent.Action)_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
            $GeneratedScript | Out-File $ScriptPath -Encoding UTF8
            Write-Host "`nScript saved to: $ScriptPath" -ForegroundColor Green
        }
    }

    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    switch ($intent.Intent) {
        "create" {
            Write-Host "- Ensure resource group exists before creating resources" -ForegroundColor Gray
            Write-Host "- Apply appropriate tags for cost tracking" -ForegroundColor Gray
            Write-Host "- Consider using ARM templates for repeatability" -ForegroundColor Gray
        }
        "delete" {
            Write-Host "[WARN] Verify resource dependencies before deletion" -ForegroundColor Red
            Write-Host "- Consider backing up data first" -ForegroundColor Gray
            Write-Host "- Use -WhatIf parameter to preview changes" -ForegroundColor Gray
        }
        "secure" {
            Write-Host "- Enable encryption at rest and in transit" -ForegroundColor Gray
            Write-Host "- Configure network security groups" -ForegroundColor Gray
            Write-Host "- Implement Azure Key Vault for secrets" -ForegroundColor Gray
        }
        default {
            Write-Host "- Review Azure best practices documentation" -ForegroundColor Gray
            Write-Host "- Test in non-production environment first" -ForegroundColor Gray
        }
    }

    $context.AddMessage("User", $Query)
    $context.AddMessage("Assistant", "Processed intent: $($intent.Intent) for $($intent.Resource)")
    $context.SaveHistory()
}

function Start-InteractiveAssistant {
    Write-Host @"

===============================================
    Azure AI Assistant - Natural Language Mode
             Powered by NLP Engine
===============================================

"@ -ForegroundColor Cyan

    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "   'Create a virtual machine in production resource group'" -ForegroundColor Gray
    Write-Host "   'List all storage accounts'" -ForegroundColor Gray
    Write-Host "   'Secure my web app named myapp'" -ForegroundColor Gray
    Write-Host "   'Optimize costs for development environment'" -ForegroundColor Gray
    Write-Host "`nType 'exit' to quit`n" -ForegroundColor DarkGray

    $context = [ConversationContext]::new()
    $context.LoadHistory()

    while ($true) {
        Write-Host "`n> " -NoNewline -ForegroundColor Cyan
        $UserInput = Read-Host "How can I help you with Azure"

        if ($UserInput -eq 'exit' -or $UserInput -eq 'quit') {
            Write-Host "`nGoodbye!" -ForegroundColor Green
            break
        }

        if ($UserInput -eq 'history') {
            Write-Host "`nConversation History:" -ForegroundColor Yellow
            $context.History | ForEach-Object {
                Write-Host "$($_.Role): $($_.Content)" -ForegroundColor Gray
            }
            continue
        }

        if ($UserInput -eq 'clear') {
            Clear-Host
            continue
        }

        Invoke-AIAssistant -Query $UserInput
    }
}

function Start-VoiceInterface {
    if ($PSVersionTable.Platform -ne 'Win32NT') {
        Write-Host "Voice interface is only available on Windows" -ForegroundColor Red
        return
    }

    Add-Type -AssemblyName System.Speech
    $speech = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    $speech.SetInputToDefaultAudioDevice()

    $grammar = New-Object System.Speech.Recognition.GrammarBuilder
    $grammar.Append("Azure")
    $grammar.AppendWildcard()

    $SpeechGrammar = New-Object System.Speech.Recognition.Grammar($grammar)
    $speech.LoadGrammar($SpeechGrammar)

    Write-Host "Voice interface active. Say 'Azure' followed by your command..." -ForegroundColor Cyan

    Register-ObjectEvent -InputObject $speech -EventName SpeechRecognized -Action {
        $result = $event.SourceEventArgs.Result.Text
        Write-Host "`nHeard: $result" -ForegroundColor Yellow
        Invoke-AIAssistant -Query $result
    }

    $speech.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)

    Write-Host "Press any key to stop listening..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $speech.RecognizeAsyncStop()
}

if ($Interactive) {
    Start-InteractiveAssistant
} elseif ($Voice) {
    Start-VoiceInterface
} elseif ($Query) {
    $QueryString = $Query -join ' '
    Invoke-AIAssistant -Query $QueryString
} else {
    Start-InteractiveAssistant
}