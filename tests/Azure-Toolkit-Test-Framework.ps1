<#
.SYNOPSIS
    Azure Toolkit Test Framework

.DESCRIPTION
    Azure PowerShell automation script

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
#>

#Requires -Version 7.0
    [string]$site = switch -Wildcard ($env:COMPUTERNAME) {
    "NYC-*" { "NewYork" }
    "CHI-*" { "Chicago" }
    "LA-*" { "LosAngeles" }
    default { "Corporate" }
}
#Requires -Modules Az.Accounts, Az.Resources, Az.Compute, Az.Storage, Az.Network, Az.KeyVault, Pester


[CmdletBinding(SupportsShouldProcess)]
param(
    [parameter()]
    [ValidateSet('All', 'Unit', 'Integration', 'Security', 'Performance', 'Compliance', 'Infrastructure')]
    [string]$TestScope='All',

    [parameter()]
    [ValidatePattern('^[a-zA-Z0-9-_\.]+$')]
    [string]$ResourceGroupName="toolkit-test-$(Get-Random -Maximum 9999)",

    [parameter()]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$SubscriptionId,

    [parameter()]
    [ValidateSet('eastus', 'eastus2', 'westus', 'westus2', 'centralus', 'northeurope', 'westeurope')]
    [string]$Location='eastus',

    [parameter()]
    [ValidateSet('Development', 'Test', 'Staging', 'Production')]
    [string]$TestEnvironment='Test',

    [parameter()]
    [switch]$IncludeDestructive,

    [parameter()]
    [switch]$MockEnabled,

    [parameter()]
    [ValidateSet('Console', 'JUnit', 'NUnit', 'HTML', 'JSON', 'AzureDevOps')]
    [string]$OutputFormat='Console',

    [parameter()]


    [ValidateNotNullOrEmpty()]


    [string] $OutputPath='./TestResults',

    [parameter()]
    [switch]$Parallel,

    [parameter()]
    [ValidateRange(1, 16)]
    [int]$MaxParallelJobs=4,

    [parameter()]
    [string[]]$Tags,

    [parameter()]
    [string[]]$ExcludeTags,

    [parameter()]
    [ValidateRange(0, 5)]
    [int]$RetryCount=2,

    [parameter()]
    [ValidateRange(5, 300)]
    [int]$TimeoutMinutes=60
)

begin {
    Set-StrictMode -Version Latest
    [string]$ErrorActionPreference='Stop'
    [string]$ProgressPreference='Continue'

    class AzureTestFramework {
        [string]$TestScope
        [string]$ResourceGroupName
        [string]$Location
        [string]$TestEnvironment
        [hashtable]$Configuration=@{}
        [hashtable]$AzureContext=@{}
        [System.Collections.ArrayList]$TestResults=@()
        [System.Collections.ArrayList]$ResourcesCreated=@()
        [System.Diagnostics.Stopwatch]$Timer
        [bool]$MockMode

        AzureTestFramework() {
    [string]$this.Timer=[System.Diagnostics.Stopwatch]::new()
    [string]$this.MockMode=$false
        }

        [void] Initialize() {
    [string]$this.Timer.Start()

            write-Information "Initializing Azure Test Framework" -InformationAction Continue
            write-Information "Test Environment: $($this.TestEnvironment)" -InformationAction Continue
            write-Information "Mock Mode: $($this.MockMode)" -InformationAction Continue
    [string]$pester=Get-Module -ListAvailable -Name Pester |
                Where-Object { $_.Version -ge '5.3.0' } |
         Select-Object select -First 1

            if (-not $pester) {
                throw "Pester 5.3.0+ required. Install with: Install-Module -Name Pester -MinimumVersion 5.3.0"
            }

            Import-Module Pester -Force

            if (-not $this.MockMode) {
    [string]$this.ConnectAzure()
            }

            if (-not (Test-Path $this.Configuration.OutputPath)) {
                New-Item -Path $this.Configuration.OutputPath -ItemType Directory -Force | Out-Null
            }
        }

        [void] ConnectAzure() {
            try {
    [string]$context=Get-AzContext

                if (-not $context) {
                    write-Information "Connecting to Azure..." -InformationAction Continue
                    Connect-AzAccount
    [string]$context=Get-AzContext
                }

                if ($this.Configuration.SubscriptionId) {
                    write-Information "Setting subscription: $($this.Configuration.SubscriptionId)" -InformationAction Continue
                    Set-AzContext -SubscriptionId $this.Configuration.SubscriptionId
    [string]$context=Get-AzContext
                }
    [string]$this.AzureContext=@{
                    SubscriptionId=$context.Subscription.Id
                    SubscriptionName=$context.Subscription.Name
                    TenantId=$context.Tenant.Id
                    AccountId=$context.Account.Id
                    Environment=$context.Environment.Name
                }

                write-Information "Connected to Azure" -InformationAction Continue
                write-Information "  Subscription: $($this.AzureContext.SubscriptionName)" -InformationAction Continue
                write-Information "  Account: $($this.AzureContext.AccountId)" -InformationAction Continue
            }
            catch {
                throw "Failed to connect to Azure: $_"
            }
        }

        [void] PrepareTestEnvironment() {
            if ($this.MockMode) {
                write-Information 'Skipping environment preparation (mock mode)' -InformationAction Continue
                return
            }

            write-Information "Preparing test environment..." -InformationAction Continue
    [string]$rg=Get-AzResourceGroup -Name $this.ResourceGroupName -ErrorAction SilentlyContinue

            if (-not $rg) {
                write-Information "Creating resource group: $($this.ResourceGroupName)" -InformationAction Continue
    $tags=@{
                    Environment=$this.TestEnvironment
                    Purpose='Testing'
                    Framework='AzureToolkitTestFramework'
                    CreatedBy=$this.AzureContext.AccountId
                    CreatedDate=Get-Date -Format 'yyyy-MM-dd'
                    AutoDelete='true'
                }
    [string]$rg=New-AzResourceGroup `
                    -Name $this.ResourceGroupName `
                    -Location $this.Location `
                    -Tags $tags
    [string]$this.ResourcesCreated.Add(@{
                    Type='ResourceGroup'
                    Name=$this.ResourceGroupName
                    Id=$rg.ResourceId
                })
            }
        }

        [PSObject] RunTests() {
    [string]$TestConfigs=$this.GetTestConfigurations()
    [string]$AllResults=@()

            foreach ($config in $TestConfigs) {
                write-Information "Running $($config.Name) tests..." -InformationAction Continue

                if ($this.Configuration.Parallel -and $config.CanRunParallel) {
    [string]$results=$this.RunParallelTests($config)
                }
                else {
    [string]$results=$this.RunSequentialTests($config)
                }
    [string]$AllResults += $results
    [string]$this.TestResults.Add($results)
            }

            return $this.AggregateResults($AllResults)
        }

        [array] GetTestConfigurations() {
    [string]$configs=@()
    $TestMap=@{
                Unit=@{
                    Name='Unit'
                    Path='./Unit'
                    Pattern='*Unit*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Unit')
                }
                Integration=@{
                    Name='Integration'
                    Path='./Integration'
                    Pattern='*Integration*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Integration')
                    RequiresAzure=$true
                }
                Security=@{
                    Name='Security'
                    Path='./Security'
                    Pattern='*Security*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Security', 'Compliance')
                    RequiresAzure=$true
                }
                Performance=@{
                    Name='Performance'
                    Path='./Performance'
                    Pattern='*Performance*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Performance')
                    RequiresAzure=$true
                }
                Compliance=@{
                    Name='Compliance'
                    Path='./Compliance'
                    Pattern='*Compliance*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Compliance', 'Governance')
                    RequiresAzure=$true
                }
                Infrastructure=@{
                    Name='Infrastructure'
                    Path='./Infrastructure'
                    Pattern='*Infrastructure*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Infrastructure')
                    RequiresAzure=$true
                }
            }

            if ($this.TestScope -eq 'All') {
    [string]$configs=$TestMap.Values
            }
            else {
    [string]$configs=@($TestMap[$this.TestScope])
            }

            if ($this.Configuration.Tags) {
    [string]$ConfiWhere-Objectonfigs | where {
    [string]$config=$_
    [string]$this.Where-Objectguration.Tags | where {
    [string]$config.Tags -contains $_
                    }
                }
            }

            if ($this.Configuration.ExcludeTags) {
        Where-Object   $configs=$configs | where {
    [string]$config=$_
                    -not Where-Objects.Configuration.ExcludeTags | where {
    [string]$config.Tags -contains $_
                    })
                }
            }

            return $configs
        }

        [PSObject] RunSequentialTests([hashtable]$config) {
    [string]$container=New-PesterContainer -Path $config.Path
    [string]$PesterConfig=New-PesterConfiguration
    [string]$PesterConfig.Run.Container=$container
    [string]$PesterConfig.Run.PassThru=$true
    [string]$PesterConfig.Output.Verbosity='Normal'

            if ($config.Tags) {
    [string]$PesterConfig.Filter.Tag=$config.Tags
            }

            if ($this.Configuration.OutputFormat -ne 'Console') {
    [string]$PesterConfig.TestResult.Enabled=$true
    [string]$PesterConfig.TestResult.OutputPath=Join-Path $this.Configuration.OutputPath "$($config.Name)_Results.xml"
    [string]$PesterConfig.TestResult.OutputFormat='NUnit2.5'
            }
    [string]$PesterConfig.Run.TestData=@{
                ResourceGroupName=$this.ResourceGroupName
                Location=$this.Location
                MockMode=$this.MockMode
                IncludeDestructive=$this.Configuration.IncludeDestructive
                AzureContext=$this.AzureContext
            }

            return Invoke-Pester -Configuration $PesterConfig
        }

        [PSObject] RunParallelTests([hashtable]$config) {
    [string]$TestFiles=Get-ChildItem -Path $config.Path -Filter $config.Pattern -Recurse
    [string]$jobs=@()
    [string]$results=@()
    [string]$TestFiles | ForEach-Object {
    [string]$job=Start-ThreadJob -ScriptBlock {
                    param($FilePath, $TestData, $OutputPath)

                    Import-Module Pester -Force
    [string]$container=New-PesterContainer -Path $FilePath
    [string]$config=New-PesterConfiguration
    [string]$config.Run.Container=$container
    [string]$config.Run.PassThru=$true
    [string]$config.Run.TestData=$TestData
    [string]$config.Output.Verbosity='Minimal'
    [string]$null=$OutputPath

                    Invoke-Pester -Configuration $config
} -ArgumentList $file.FullName, @{
                    ResourceGroupName=$this.ResourceGroupName
                    Location=$this.Location
                    MockMode=$this.MockMode
                }, $this.Configuration.OutputPath
    [string]$jobs += $job

                if ($jobs.Count -ge $this.Configuration.MaxParallelJobs) {
    [string]$completed=Wait-Job -Job $jobs -Any
    [string]$results += Receive-Job -Job $CoWhere-Objected
    [string]$jobs=$jobs | where { $_.Id -ne $completed.Id }
                }
            }

            if ($jobs) {
    [string]$results += $jobs | Wait-Job | Receive-Job
            }

            return $this.AggregateResults($results)
        }

        [PSObject] AggregateResults([array]$results) {
            if (-not $results) {
                return $null
            }
    [string]$aggregated=[PSCustomObject]@{
                Tests=@()
                PassedCount=0
                FailedCount=0
                SkippedCount=0
                TotalCount=0
                Duration=[TimeSpan]::Zero
                Result='Passed'
            }
    [string]$results | ForEach-Object {
    if ($result.Tests) {
    [string]$aggregated.Tests += $result.Tests
}
    [string]$aggregated.PassedCount += $result.PassedCount
    [string]$aggregated.FailedCount += $result.FailedCount
    [string]$aggregated.SkippedCount += $result.SkippedCount
    [string]$aggregated.TotalCount += $result.TotalCount
    [string]$aggregated.Duration += $result.Duration
            }

            if ($aggregated.FailedCount -gt 0) {
    [string]$aggregated.Result='Failed'
            }

            return $aggregated
        }

        [void] ValidateInfrastructure() {
            if ($this.MockMode) {
                write-Information 'Skipping infrastructure validation (mock mode)' -InformationAction Continue
                return
            }

            write-Information "Validating Azure infrastructure..." -InformationAction Continue
    [string]$ValidationTests=@(
                @{
                    Name='Resource Group Exists'
                    Test={ Get-AzResourceGroup -Name $this.ResourceGroupName -ErrorAction Stop }
                }
                @{
                    Name='Subscription Active'
                    Test={
    [string]$sub=Get-AzSubscription -SubscriptionId $this.AzureContext.SubscriptionId
                        if ($sub.State -ne 'Enabled') {
                            throw "Subscription is not enabled: $($sub.State)"
                        }
                    }
                }
                @{
                    Name='Required Providers Registered'
                    Test={
    [string]$RequiredProviders=@(
                            'Microsoft.Compute',
                            'Microsoft.Storage',
                            'Microsoft.Network',
                            'Microsoft.KeyVault'
                        )
    [string]$RequiredProviders | ForEach-Object {
    [string]$registration=Get-AzResourceProvider -ProviderNamespace $provider
                            if ($registration.RegistrationState -ne 'Registered') {
                                write-Warning "$provider is not registered. Registering..."
                                Register-AzResourceProvider -ProviderNamespace $provider
}
                        }
                    }
                }
            )

            foreach ($test in $ValidationTests) {
                try {
                    write-Information "  Validating: $($test.Name)" -InformationAction Continue
                    & $test.Test
                    write-Information "    Passed" -InformationAction Continue
                }
                catch {
                    write-Warning "  Validation failed: $($test.Name) - $_"
                }
            }
        }

        [void] RunSecurityTests() {
            write-Information "Running security validation tests..." -InformationAction Continue
    [string]$SecurityChecks=@(
                @{
                    Name='RBAC Assignments'
                    Check={
    [string]$assignments=Get-AzRoleAssignment -ResourceGroupName $this.ResourceGroupName
                        return @{
                            Count=$assignments.Count
      Select-Object                Assignments=$assignments | select DisplayName, RoleDefinitionName
                        }
                    }
                }
                @{
                    Name='Network Security Groups'
                    Check={
    [string]$nsgs=Get-AzNetworkSecurityGroup -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$issues=@()
    [string]$nsgs | ForEach-Object {
    [string]$rules=$nsg.SecurityRules + $nsg.DefaultSecuritWhere-Objects
    [string]$RiskyRules=$rules | where {
#Requires -Modules Az.Accounts, Az.Resources, Az.Compute, Az.Storage, Az.Network, Az.KeyVault, Pester


[CmdletBinding(SupportsShouldProcess)]
param(
    [parameter()]
    [ValidateSet('All', 'Unit', 'Integration', 'Security', 'Performance', 'Compliance', 'Infrastructure')]
    [string]$TestScope='All',

    [parameter()]
    [ValidatePattern('^[a-zA-Z0-9-_\.]+$')]
    [string]$ResourceGroupName="toolkit-test-$(Get-Random -Maximum 9999)",

    [parameter()]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$SubscriptionId,

    [parameter()]
    [ValidateSet('eastus', 'eastus2', 'westus', 'westus2', 'centralus', 'northeurope', 'westeurope')]
    [string]$Location='eastus',

    [parameter()]
    [ValidateSet('Development', 'Test', 'Staging', 'Production')]
    [string]$TestEnvironment='Test',

    [parameter()]
    [switch]$IncludeDestructive,

    [parameter()]
    [switch]$MockEnabled,

    [parameter()]
    [ValidateSet('Console', 'JUnit', 'NUnit', 'HTML', 'JSON', 'AzureDevOps')]
    [string]$OutputFormat='Console',

    [parameter()]


    [ValidateNotNullOrEmpty()]


    [string] $OutputPath='./TestResults',

    [parameter()]
    [switch]$Parallel,

    [parameter()]
    [ValidateRange(1, 16)]
    [int]$MaxParallelJobs=4,

    [parameter()]
    [string[]]$Tags,

    [parameter()]
    [string[]]$ExcludeTags,

    [parameter()]
    [ValidateRange(0, 5)]
    [int]$RetryCount=2,

    [parameter()]
    [ValidateRange(5, 300)]
    [int]$TimeoutMinutes=60
)

begin {
    Set-StrictMode -Version Latest
    [string]$ErrorActionPreference='Stop'
    [string]$ProgressPreference='Continue'

    class AzureTestFramework {
        [string]$TestScope
        [string]$ResourceGroupName
        [string]$Location
        [string]$TestEnvironment
        [hashtable]$Configuration=@{}
        [hashtable]$AzureContext=@{}
        [System.Collections.ArrayList]$TestResults=@()
        [System.Collections.ArrayList]$ResourcesCreated=@()
        [System.Diagnostics.Stopwatch]$Timer
        [bool]$MockMode

        AzureTestFramework() {
    [string]$this.Timer=[System.Diagnostics.Stopwatch]::new()
    [string]$this.MockMode=$false
        }

        [void] Initialize() {
    [string]$this.Timer.Start()

            write-Information "Initializing Azure Test Framework" -InformationAction Continue
            write-Information "Test Environment: $($this.TestEnvironment)" -InformationAction Continue
            write-Information "Mock Mode: $($this.MockMode)" -InformationAction Continue
    [string]$PWhere-Object=Get-Module -ListAvailable -Name PesterSelect-Object             where { $_.Version -ge '5.3.0' } |
                select -First 1

            if (-not $pester) {
                throw "Pester 5.3.0+ required. Install with: Install-Module -Name Pester -MinimumVersion 5.3.0"
            }

            Import-Module Pester -Force

            if (-not $this.MockMode) {
    [string]$this.ConnectAzure()
            }

            if (-not (Test-Path $this.Configuration.OutputPath)) {
                New-Item -Path $this.Configuration.OutputPath -ItemType Directory -Force | Out-Null
            }
        }

        [void] ConnectAzure() {
            try {
    [string]$context=Get-AzContext

                if (-not $context) {
                    write-Information "Connecting to Azure..." -InformationAction Continue
                    Connect-AzAccount
    [string]$context=Get-AzContext
                }

                if ($this.Configuration.SubscriptionId) {
                    write-Information "Setting subscription: $($this.Configuration.SubscriptionId)" -InformationAction Continue
                    Set-AzContext -SubscriptionId $this.Configuration.SubscriptionId
    [string]$context=Get-AzContext
                }
    [string]$this.AzureContext=@{
                    SubscriptionId=$context.Subscription.Id
                    SubscriptionName=$context.Subscription.Name
                    TenantId=$context.Tenant.Id
                    AccountId=$context.Account.Id
                    Environment=$context.Environment.Name
                }

                write-Information "Connected to Azure" -InformationAction Continue
                write-Information "  Subscription: $($this.AzureContext.SubscriptionName)" -InformationAction Continue
                write-Information "  Account: $($this.AzureContext.AccountId)" -InformationAction Continue
            }
            catch {
                throw "Failed to connect to Azure: $_"
            }
        }

        [void] PrepareTestEnvironment() {
            if ($this.MockMode) {
                write-Information 'Skipping environment preparation (mock mode)' -InformationAction Continue
                return
            }

            write-Information "Preparing test environment..." -InformationAction Continue
    [string]$rg=Get-AzResourceGroup -Name $this.ResourceGroupName -ErrorAction SilentlyContinue

            if (-not $rg) {
                write-Information "Creating resource group: $($this.ResourceGroupName)" -InformationAction Continue
    $tags=@{
                    Environment=$this.TestEnvironment
                    Purpose='Testing'
                    Framework='AzureToolkitTestFramework'
                    CreatedBy=$this.AzureContext.AccountId
                    CreatedDate=Get-Date -Format 'yyyy-MM-dd'
                    AutoDelete='true'
                }
    [string]$rg=New-AzResourceGroup `
                    -Name $this.ResourceGroupName `
                    -Location $this.Location `
                    -Tags $tags
    [string]$this.ResourcesCreated.Add(@{
                    Type='ResourceGroup'
                    Name=$this.ResourceGroupName
                    Id=$rg.ResourceId
                })
            }
        }

        [PSObject] RunTests() {
    [string]$TestConfigs=$this.GetTestConfigurations()
    [string]$AllResults=@()

            foreach ($config in $TestConfigs) {
                write-Information "Running $($config.Name) tests..." -InformationAction Continue

                if ($this.Configuration.Parallel -and $config.CanRunParallel) {
    [string]$results=$this.RunParallelTests($config)
                }
                else {
    [string]$results=$this.RunSequentialTests($config)
                }
    [string]$AllResults += $results
    [string]$this.TestResults.Add($results)
            }

            return $this.AggregateResults($AllResults)
        }

        [array] GetTestConfigurations() {
    [string]$configs=@()
    $TestMap=@{
                Unit=@{
                    Name='Unit'
                    Path='./Unit'
                    Pattern='*Unit*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Unit')
                }
                Integration=@{
                    Name='Integration'
                    Path='./Integration'
                    Pattern='*Integration*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Integration')
                    RequiresAzure=$true
                }
                Security=@{
                    Name='Security'
                    Path='./Security'
                    Pattern='*Security*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Security', 'Compliance')
                    RequiresAzure=$true
                }
                Performance=@{
                    Name='Performance'
                    Path='./Performance'
                    Pattern='*Performance*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Performance')
                    RequiresAzure=$true
                }
                Compliance=@{
                    Name='Compliance'
                    Path='./Compliance'
                    Pattern='*Compliance*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Compliance', 'Governance')
                    RequiresAzure=$true
                }
                Infrastructure=@{
                    Name='Infrastructure'
                    Path='./Infrastructure'
                    Pattern='*Infrastructure*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Infrastructure')
                    RequiresAzure=$true
                }
            }

            if ($this.TestScope -eq 'All') {
    [string]$configs=$TestMap.Values
            }
            else {
    [string]$configs=@($TestMap[$this.TestScope])
            }

   Where-Object    if ($this.Configuration.Tags) {
    [string]$configs=$configs | whWhere-Object
    [string]$config=$_
    [string]$this.Configuration.Tags | where {
    [string]$config.Tags -contains $_
                    }
                }
           Where-Object           if ($this.Configuration.ExcludeTags) {
    [string]$configs=$configs | wWhere-Object{
    [string]$config=$_
                    -not ($this.Configuration.ExcludeTags | where {
    [string]$config.Tags -contains $_
                    })
                }
            }

            return $configs
        }

        [PSObject] RunSequentialTests([hashtable]$config) {
    [string]$container=New-PesterContainer -Path $config.Path
    [string]$PesterConfig=New-PesterConfiguration
    [string]$PesterConfig.Run.Container=$container
    [string]$PesterConfig.Run.PassThru=$true
    [string]$PesterConfig.Output.Verbosity='Normal'

            if ($config.Tags) {
    [string]$PesterConfig.Filter.Tag=$config.Tags
            }

            if ($this.Configuration.OutputFormat -ne 'Console') {
    [string]$PesterConfig.TestResult.Enabled=$true
    [string]$PesterConfig.TestResult.OutputPath=Join-Path $this.Configuration.OutputPath "$($config.Name)_Results.xml"
    [string]$PesterConfig.TestResult.OutputFormat='NUnit2.5'
            }
    [string]$PesterConfig.Run.TestData=@{
                ResourceGroupName=$this.ResourceGroupName
                Location=$this.Location
                MockMode=$this.MockMode
                IncludeDestructive=$this.Configuration.IncludeDestructive
                AzureContext=$this.AzureContext
            }

            return Invoke-Pester -Configuration $PesterConfig
        }

        [PSObject] RunParallelTests([hashtable]$config) {
    [string]$TestFiles=Get-ChildItem -Path $config.Path -Filter $config.Pattern -Recurse
    [string]$jobs=@()
    [string]$results=@()
    [string]$TestFiles | ForEach-Object {
    [string]$job=Start-ThreadJob -ScriptBlock {
                    param($FilePath, $TestData, $OutputPath)

                    Import-Module Pester -Force
    [string]$container=New-PesterContainer -Path $FilePath
    [string]$config=New-PesterConfiguration
    [string]$config.Run.Container=$container
    [string]$config.Run.PassThru=$true
    [string]$config.Run.TestData=$TestData
    [string]$config.Output.Verbosity='Minimal'
    [string]$null=$OutputPath

                    Invoke-Pester -Configuration $config
} -ArgumentList $file.FullName, @{
                    ResourceGroupName=$this.ResourceGroupName
                    Location=$this.Location
                    MockMode=$this.MockMode
                }, $this.Configuration.OutputPath
    [string]$jobs += $job

                if ($jobs.Count -ge $this.Configuration.MaxParallelJobs) {
    [string]$completed=Wait-Job -Job Where-Object -Any
    [string]$results += Receive-Job -Job $completed
    [string]$jobs=$jobs | where { $_.Id -ne $completed.Id }
                }
            }

            if ($jobs) {
    [string]$results += $jobs | Wait-Job | Receive-Job
            }

            return $this.AggregateResults($results)
        }

        [PSObject] AggregateResults([array]$results) {
            if (-not $results) {
                return $null
            }
    [string]$aggregated=[PSCustomObject]@{
                Tests=@()
                PassedCount=0
                FailedCount=0
                SkippedCount=0
                TotalCount=0
                Duration=[TimeSpan]::Zero
                Result='Passed'
            }
    [string]$results | ForEach-Object {
    if ($result.Tests) {
    [string]$aggregated.Tests += $result.Tests
}
    [string]$aggregated.PassedCount += $result.PassedCount
    [string]$aggregated.FailedCount += $result.FailedCount
    [string]$aggregated.SkippedCount += $result.SkippedCount
    [string]$aggregated.TotalCount += $result.TotalCount
    [string]$aggregated.Duration += $result.Duration
            }

            if ($aggregated.FailedCount -gt 0) {
    [string]$aggregated.Result='Failed'
            }

            return $aggregated
        }

        [void] ValidateInfrastructure() {
            if ($this.MockMode) {
                write-Information 'Skipping infrastructure validation (mock mode)' -InformationAction Continue
                return
            }

            write-Information "Validating Azure infrastructure..." -InformationAction Continue
    [string]$ValidationTests=@(
                @{
                    Name='Resource Group Exists'
                    Test={ Get-AzResourceGroup -Name $this.ResourceGroupName -ErrorAction Stop }
                }
                @{
                    Name='Subscription Active'
                    Test={
    [string]$sub=Get-AzSubscription -SubscriptionId $this.AzureContext.SubscriptionId
                        if ($sub.State -ne 'Enabled') {
                            throw "Subscription is not enabled: $($sub.State)"
                        }
                    }
                }
                @{
                    Name='Required Providers Registered'
                    Test={
    [string]$RequiredProviders=@(
                            'Microsoft.Compute',
                            'Microsoft.Storage',
                            'Microsoft.Network',
                            'Microsoft.KeyVault'
                        )
    [string]$RequiredProviders | ForEach-Object {
    [string]$registration=Get-AzResourceProvider -ProviderNamespace $provider
                            if ($registration.RegistrationState -ne 'Registered') {
                                write-Warning "$provider is not registered. Registering..."
                                Register-AzResourceProvider -ProviderNamespace $provider
}
                        }
                    }
                }
            )

            foreach ($test in $ValidationTests) {
                try {
                    write-Information "  Validating: $($test.Name)" -InformationAction Continue
                    & $test.Test
                    write-Information "    Passed" -InformationAction Continue
                }
                catch {
                    write-Warning "  Validation failed: $($test.Name) - $_"
                }
            }
        }

        [void] RunSecurityTests() {
            write-Information "Running security validation tests..." -InformationAction Continue
    [string]$SecurityChecks=@(
                @{
                    Name='RBAC Assignments'
                    Check={
    [string]$assignments=Get-AzRoleAssignment -ResourceGroupName $this.ResourceGroupName
                        returnSelect-Object                          Count=$assignments.Count
                            Assignments=$assignments | select DisplayName, RoleDefinitionName
                        }
                    }
                }
                @{
                    Name='Network Security Groups'
                    Check={
    [string]$nsgs=Get-AzNetworkSecurityGroup -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$issues=@()

                        foreach ($nsg in $nsgs) {
            Where-Object           $rules=$nsg.SecurityRules + $nsg.DefaultSecurityRules
    [string]$RiskyRules=$rules | where {
    [string]$_.Access -eq 'Allow' -and
    [string]$_.Direction -eq 'Inbound' -and
    [string]$_.SourceAddressPrefix -eq '*'
                            }

                            if ($RiskyRules) {
    [string]$issues += "NSG $($nsg.Name) has risky inbound rules"
                            }
                        }

                        return @{
                            NSGCount=$nsgs.Count
                            Issues=$issues
                        }
                    }
                }
                @{
                    Name='Storage Account Security'
                    Check={
    [string]$StorageAccounts=Get-AzStorageAccount -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$issues=@()
    [string]$StorageAccounts | ForEach-Object {
    if ($account.EnableHttpsTrafficOnly -ne $true) {
    [string]$issues += "$($account.StorageAccountName) does not enforce HTTPS"
}
                            if ($account.AllowBlobPublicAccess -eq $true) {
    [string]$issues += "$($account.StorageAccountName) allows public blob access"
                            }
                        }

                        return @{
                            StorageAccountCount=$StorageAccounts.Count
                            Issues=$issues
                        }
                    }
                }
            )

            foreach ($check in $SecurityChecks) {
                try {
                    write-Information "  Running: $($check.Name)" -InformationAction Continue
    [string]$result=& $check.Check

                    if ($result.Issues -and $result.IssuForEach-Objectt -gt 0) {
                        write-Warning "    Security issues found:"
    [string]$result.Issues | foreach {
                            write-Warning "      $_"
                        }
                    }
                    else {
                        write-Information "    No security issues found" -InformationAction Continue
                    }
                }
                catch {
                    write-Warning "  Security check failed: $($check.Name) - $_"
                }
            }
        }

        [void] RunComplianceTests() {
            write-Information "Running compliance validation..." -InformationAction Continue
    [string]$ComplianceRules=@(
                @{
                    Name='Resource Tagging'
                    Rule={
       Where-Object            $resources=Get-AzResource -ResourceGroupName $this.ResourceGroupName
    [string]$untagged=$resources | where { -not $_.Tags -or $_.Tags.Count -eq 0 }

                        if ($untagged) {
                            return @{
                                Compliant=$false
                                Message="$($untagged.Count) resources without tags"
                                Resources=$untagged.Name
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
                @{
                    Name='Encryption at Rest'
                    Rule={
    [string]$StorageAccounts=Get-AzStorageAccount -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$unencrypted=@()
    [string]$StorageAccounts | ForEach-Object {
    if (-not $account.Encryption.Services.Blob.Enabled) {
    [string]$unencrypted += $account.StorageAccountName
}
                        }

                        if ($unencrypted) {
                            return @{
                                Compliant=$false
                                Message="Storage accounts without encryption: $($unencrypted -join ', ')"
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
                @{
                    Name='Diagnostic Settings'
                    Rule={
    [string]$resources=Get-AzResource -ResourceGroupName $this.ResourceGroupName
    [string]$WithoutDiagnostics=@()
    [string]$resources | ForEach-Object {
    [string]$diagnostics=Get-AzDiagnosticSetting -ResourceId $resource.Id -ErrorAction SilentlyContinue
                            if (-not $diagnostics) {
    [string]$WithoutDiagnostics += $resource.Name
}
                        }

                        if ($WithoutDiagnostics.Count -gt ($resources.Count * 0.5)) {
                            return @{
                                Compliant=$false
                                Message='More than 50% of resources lack diagnostic settings'
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
            )
    [string]$ComplianceScore=0
    [string]$TotalRules=$ComplianceRules.Count

            foreach ($rule in $ComplianceRules) {
                try {
                    write-Information "  Checking: $($rule.Name)" -InformationAction Continue
    [string]$result=& $rule.Rule

                    if ($result.Compliant) {
                        write-Information "    Compliant" -InformationAction Continue
    [string]$ComplianceScore++
                    }
                    else {
                        write-Warning "    Non-compliant: $($result.Message)"
                    }
                }
                catch {
                    write-Warning "  Compliance check failed: $($rule.Name) - $_"
                }
            }
    [string]$percentage=[Math]::Round(($ComplianceScore / $TotalRules) * 100, 2)
            write-Information "Overall Compliance Score: $percentage%" -InformationAction Continue
        }

        [void] Cleanup() {
            if ($this.MockMode -or -not $this.Configuration.IncludeDestructive) {
                write-Information "Skipping cleanup" -InformationAction Continue
                return
            }

            write-Information "Cleaning up test resources..." -InformationAction Continue

            foreach ($resource in $this.ResourcesCreated) {
                try {
                    switch ($resource.Type) {
                        'ResourceGroup' {
                            write-Information "  Removing resource group: $($resource.Name)" -InformationAction Continue
                            Remove-AzResourceGroup -Name $resource.Name -Force -AsJob
                        }
                        default {
                            write-Information "  Removing resource: $($resource.Name)" -InformationAction Continue
                            Remove-AzResource -ResourceId $resource.Id -Force
                        }
                    }
                }
                catch {
                    write-Warning "Failed to cleanup $($resource.Type): $($resource.Name) - $_"
                }
            }
        }

        [void] GenerateReport([PSObject]$results) {
    [string]$ReportPath=Join-Path $this.Configuration.OutputPath "AzureTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

            switch ($this.Configuration.OutputFormat) {
                'HTML' {
    [string]$this.GenerateHtmlReport($results, "$ReportPath.html")
                }
                'JSON' {
    [string]$results | ConvertTo-Json -Depth 10 | Out-File "$ReportPath.json" -Encoding UTF8
                    write-Information "JSON report saved: $ReportPath.json" -InformationAction Continue
                }
                'JUnit' {
    [string]$this.GenerateJUnitReport($results, "$ReportPath.xml")
                }
                'AzureDevOps' {
    [string]$this.GenerateAzureDevOpsReport($results, "$ReportPath.md")
                }
            }
        }

        [void] GenerateHtmlReport([PSObject]$results, [string]$path) {
    [string]$html=@"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Infrastructure Test Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .header { background:
        h1 { margin: 0; }
        .container { max-width: 1200px; margin: auto; background: white; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 20px; }
        .metric { text-align: center; padding: 15px; background:
        .metric-value { font-size: 2em; font-weight: bold; color:
        .metric-label { color:
        .passed { color:
        .failed { color:
        .skipped { color:
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background:
        td { padding: 10px; border-bottom: 1px solid
        .footer { text-align: center; padding: 20px; color:
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Azure Infrastructure Test Report</h1>
            <p>Environment: $($this.TestEnvironment) | Scope: $($this.TestScope)</p>
            <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </div>
        <div class="summary">
            <div class="metric'>
                <div class='metric-value">$($results.TotalCount)</div>
                <div class="metric-label">Total Tests</div>
            </div>
            <div class="metric'>
                <div class='metric-value passed">$($results.PassedCount)</div>
                <div class="metric-label'>Passed</div>
            </div>
            <div class='metric'>
                <div class='metric-value failed">$($results.FailedCount)</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric'>
                <div class='metric-value skipped">$($results.SkippedCount)</div>
                <div class="metric-label">Skipped</div>
            </div>
        </div>
        <div style="padding: 20px;'>
            <h2>Test Details</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Duration</th>
                        <th>Status</th>
                        <th>Message</th>
                    </tr>
                </thead>
                <tbody>
'@
            foreach ($test in $results.Tests) {
    [string]$status=if ($test.Passed) { 'Passed' } elseif ($test.Skipped) { 'Skipped' } else { 'Failed' }
    [string]$html += @"
                    <tr>
                        <td>$($test.Name)</td>
                        <td>$($test.Duration.TotalMilliseconds) ms</td>
                        <td class="$($status.ToLower())">$status</td>
                        <td>$(if ($test.ErrorRecord) { $test.ErrorRecord.Exception.Message } else { '-' })</td>
                    </tr>
"@
            }
    [string]$html += @'
                </tbody>
            </table>
        </div>
        <div class='footer">
            <p>Azure Test Framework v3.0.0 | Duration: $($this.Timer.Elapsed)</p>
        </div>
    </div>
</body>
</html>
"@
    [string]$html | Out-File -FilePath $path -Encoding UTF8
            write-Information "HTML report saved: $path" -InformationAction Continue
        }

        [void] GenerateJUnitReport([PSObject]$results, [string]$path) {
    [string]$xml=@"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Azure Infrastructure Tests" tests="$($results.TotalCount)' failures='$($results.FailedCount)" time="$($results.Duration.TotalSeconds)">
    <testsuite name="$($this.TestScope)" tests="$($results.TotalCount)' failures='$($results.FailedCount)" time="$($results.Duration.TotalSeconds)">
"@
            foreach ($test in $results.Tests) {
    [string]$xml += "        <testcase name=`"$($test.Name)`" time=`"$($test.Duration.TotalSeconds)`''
                if ($test.Passed) {
    [string]$xml += ' />`n'
                }
                elseif ($test.Skipped) {
    [string]$xml += "><skipped /></testcase>`n"
                }
                else {
    [string]$xml += "><failure>$($test.ErrorRecord.Exception.Message)</failure></testcase>`n"
                }
            }
    [string]$xml += @"
    </testsuite>
</testsuites>
"@
    [string]$xml | Out-File -FilePath $path -Encoding UTF8
            write-Information "JUnit report saved: $path" -InformationAction Continue
        }

        [void] GenerateAzureDevOpsReport([PSObject]$results, [string]$path) {
    [string]$markdown=@"

- **Total Tests**: $($results.TotalCount)
- **Passed**: $($results.PassedCount)
- **Failed**: $($results.FailedCount)
- **Skipped**: $($results.SkippedCount)
- **Duration**: $($results.Duration)
- **Pass Rate**: $([Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2))%

- **Environment**: $($this.TestEnvironment)
- **Resource Group**: $($this.ResourceGroupName)
- **Location**: $($this.Location)
- **Mock Mode**: $($this.MockMode)

| Test | Duration | Status |
|------|----------|--------|
"@
            foreach ($test in $results.Tests) {
    [string]$status=if ($test.Passed) { 'Passed' } elseif ($test.Skipped) { 'Skipped' } else { 'Failed' }
    [string]$markdown += "| $($test.Name) | $($test.Duration.TotalMilliseconds)ms | $status |`n"
            }
    [string]$markdown | Out-File -FilePath $path -Encoding UTF8
            write-Information "Azure DevOps report saved: $path" -InformationAction Continue
        }
    }

    write-Information "Azure Infrastructure Test Framework v3.0.0" -InformationAction Continue
    write-Information "==========================================" -InformationAction Continue
}

process {
    try {
    [string]$framework=[AzureTestFramework]::new()
    [string]$framework.TestScope=$TestScope
    [string]$framework.ResourceGroupName=$ResourceGroupName
    [string]$framework.Location=$Location
    [string]$framework.TestEnvironment=$TestEnvironment
    [string]$framework.MockMode=$MockEnabled
    [string]$framework.Configuration=@{
            SubscriptionId=$SubscriptionId
            OutputPath=$OutputPath
            OutputFormat=$OutputFormat
            IncludeDestructive=$IncludeDestructive
            Parallel=$Parallel
            MaxParallelJobs=$MaxParallelJobs
            Tags=$Tags
            ExcludeTags=$ExcludeTags
            RetryCount=$RetryCount
            TimeoutMinutes=$TimeoutMinutes
        }
    [string]$framework.Initialize()

        if (-not $MockEnabled) {
    [string]$framework.PrepareTestEnvironment()
    [string]$framework.ValidateInfrastructure()
        }

        if ($TestScope -in @('Security', 'All')) {
    [string]$framework.RunSecurityTests()
        }

        if ($TestScope -in @('Compliance', 'All')) {
    [string]$framework.RunComplianceTests()
        }
    [string]$results=$framework.RunTests()

        if ($OutputFormat -ne 'Console') {
    [string]$framework.GenerateReport($results)
        }

        write-Information "`nTest Execution Summary" -InformationAction Continue
        write-Information "=====================" -InformationAction Continue
        write-Information "Total: $($results.TotalCount)" -InformationAction Continue
        write-Information "Passed: $($results.PassedCount)" -InformationAction Continue
        write-Information "Failed: $($results.FailedCount)" -InformationAction Continue
        write-Information "Skipped: $($results.SkippedCount)" -InformationAction Continue
        write-Information "Duration: $($framework.Timer.Elapsed)" -InformationAction Continue
    [string]$PassRate=if ($results.TotalCount -gt 0) {
            [Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2)
        } else { 0 }

        write-Information "Pass Rate: $PassRate%" -InformationAction Continue

        if ($IncludeDestructive -and $PSCmdlet.ShouldProcess($ResourceGroupName, "Cleanup test resources")) {
    [string]$framework.Cleanup()
        }

        return $results
    }
    catch {
        write-Error "Test framework failed: $_"
        throw
    }
    finally {
        if ($framework.Timer.IsRunning) {
    [string]$framework.Timer.Stop()
        }
    }
}

end {
    write-Information "`nAzure test execution completed" -InformationAction Continue
    if (Test-Path $OutputPath) {
        write-Information "Reports saved to: $OutputPath" -InformationAction Continue
    }
}


.Access -eq 'Allow' -and
#Requires -Modules Az.Accounts, Az.Resources, Az.Compute, Az.Storage, Az.Network, Az.KeyVault, Pester


[CmdletBinding(SupportsShouldProcess)]
param(
    [parameter()]
    [ValidateSet('All', 'Unit', 'Integration', 'Security', 'Performance', 'Compliance', 'Infrastructure')]
    [string]$TestScope='All',

    [parameter()]
    [ValidatePattern('^[a-zA-Z0-9-_\.]+$')]
    [string]$ResourceGroupName="toolkit-test-$(Get-Random -Maximum 9999)",

    [parameter()]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$SubscriptionId,

    [parameter()]
    [ValidateSet('eastus', 'eastus2', 'westus', 'westus2', 'centralus', 'northeurope', 'westeurope')]
    [string]$Location='eastus',

    [parameter()]
    [ValidateSet('Development', 'Test', 'Staging', 'Production')]
    [string]$TestEnvironment='Test',

    [parameter()]
    [switch]$IncludeDestructive,

    [parameter()]
    [switch]$MockEnabled,

    [parameter()]
    [ValidateSet('Console', 'JUnit', 'NUnit', 'HTML', 'JSON', 'AzureDevOps')]
    [string]$OutputFormat='Console',

    [parameter()]


    [ValidateNotNullOrEmpty()]


    [string] $OutputPath='./TestResults',

    [parameter()]
    [switch]$Parallel,

    [parameter()]
    [ValidateRange(1, 16)]
    [int]$MaxParallelJobs=4,

    [parameter()]
    [string[]]$Tags,

    [parameter()]
    [string[]]$ExcludeTags,

    [parameter()]
    [ValidateRange(0, 5)]
    [int]$RetryCount=2,

    [parameter()]
    [ValidateRange(5, 300)]
    [int]$TimeoutMinutes=60
)

begin {
    Set-StrictMode -Version Latest
    [string]$ErrorActionPreference='Stop'
    [string]$ProgressPreference='Continue'

    class AzureTestFramework {
        [string]$TestScope
        [string]$ResourceGroupName
        [string]$Location
        [string]$TestEnvironment
        [hashtable]$Configuration=@{}
        [hashtable]$AzureContext=@{}
        [System.Collections.ArrayList]$TestResults=@()
        [System.Collections.ArrayList]$ResourcesCreated=@()
        [System.Diagnostics.Stopwatch]$Timer
        [bool]$MockMode

        AzureTestFramework() {
    [string]$this.Timer=[System.Diagnostics.Stopwatch]::new()
    [string]$this.MockMode=$false
        }

        [void] Initialize() {
    [string]$this.Timer.Start()

            write-Information "Initializing Azure Test Framework" -InformationAction Continue
            write-Information "Test Environment: $($this.TestEnvironment)" -InformationAction Continue
            write-Information "Mock Mode: $($this.MockMode)" -InformationAction Continue
    [string]$pester=Get-Module -ListAvailable -Name Pester |
                where { $_.Version -ge '5.3.0' } |
                select -First 1

            if (-not $pester) {
                throw "Pester 5.3.0+ required. Install with: Install-Module -Name Pester -MinimumVersion 5.3.0"
            }

            Import-Module Pester -Force

            if (-not $this.MockMode) {
    [string]$this.ConnectAzure()
            }

            if (-not (Test-Path $this.Configuration.OutputPath)) {
                New-Item -Path $this.Configuration.OutputPath -ItemType Directory -Force | Out-Null
            }
        }

        [void] ConnectAzure() {
            try {
    [string]$context=Get-AzContext

                if (-not $context) {
                    write-Information "Connecting to Azure..." -InformationAction Continue
                    Connect-AzAccount
    [string]$context=Get-AzContext
                }

                if ($this.Configuration.SubscriptionId) {
                    write-Information "Setting subscription: $($this.Configuration.SubscriptionId)" -InformationAction Continue
                    Set-AzContext -SubscriptionId $this.Configuration.SubscriptionId
    [string]$context=Get-AzContext
                }
    [string]$this.AzureContext=@{
                    SubscriptionId=$context.Subscription.Id
                    SubscriptionName=$context.Subscription.Name
                    TenantId=$context.Tenant.Id
                    AccountId=$context.Account.Id
                    Environment=$context.Environment.Name
                }

                write-Information "Connected to Azure" -InformationAction Continue
                write-Information "  Subscription: $($this.AzureContext.SubscriptionName)" -InformationAction Continue
                write-Information "  Account: $($this.AzureContext.AccountId)" -InformationAction Continue
            }
            catch {
                throw "Failed to connect to Azure: $_"
            }
        }

        [void] PrepareTestEnvironment() {
            if ($this.MockMode) {
                write-Information 'Skipping environment preparation (mock mode)' -InformationAction Continue
                return
            }

            write-Information "Preparing test environment..." -InformationAction Continue
    [string]$rg=Get-AzResourceGroup -Name $this.ResourceGroupName -ErrorAction SilentlyContinue

            if (-not $rg) {
                write-Information "Creating resource group: $($this.ResourceGroupName)" -InformationAction Continue
    $tags=@{
                    Environment=$this.TestEnvironment
                    Purpose='Testing'
                    Framework='AzureToolkitTestFramework'
                    CreatedBy=$this.AzureContext.AccountId
                    CreatedDate=Get-Date -Format 'yyyy-MM-dd'
                    AutoDelete='true'
                }
    [string]$rg=New-AzResourceGroup `
                    -Name $this.ResourceGroupName `
                    -Location $this.Location `
                    -Tags $tags
    [string]$this.ResourcesCreated.Add(@{
                    Type='ResourceGroup'
                    Name=$this.ResourceGroupName
                    Id=$rg.ResourceId
                })
            }
        }

        [PSObject] RunTests() {
    [string]$TestConfigs=$this.GetTestConfigurations()
    [string]$AllResults=@()

            foreach ($config in $TestConfigs) {
                write-Information "Running $($config.Name) tests..." -InformationAction Continue

                if ($this.Configuration.Parallel -and $config.CanRunParallel) {
    [string]$results=$this.RunParallelTests($config)
                }
                else {
    [string]$results=$this.RunSequentialTests($config)
                }
    [string]$AllResults += $results
    [string]$this.TestResults.Add($results)
            }

            return $this.AggregateResults($AllResults)
        }

        [array] GetTestConfigurations() {
    [string]$configs=@()
    $TestMap=@{
                Unit=@{
                    Name='Unit'
                    Path='./Unit'
                    Pattern='*Unit*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Unit')
                }
                Integration=@{
                    Name='Integration'
                    Path='./Integration'
                    Pattern='*Integration*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Integration')
                    RequiresAzure=$true
                }
                Security=@{
                    Name='Security'
                    Path='./Security'
                    Pattern='*Security*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Security', 'Compliance')
                    RequiresAzure=$true
                }
                Performance=@{
                    Name='Performance'
                    Path='./Performance'
                    Pattern='*Performance*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Performance')
                    RequiresAzure=$true
                }
                Compliance=@{
                    Name='Compliance'
                    Path='./Compliance'
                    Pattern='*Compliance*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Compliance', 'Governance')
                    RequiresAzure=$true
                }
                Infrastructure=@{
                    Name='Infrastructure'
                    Path='./Infrastructure'
                    Pattern='*Infrastructure*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Infrastructure')
                    RequiresAzure=$true
                }
            }

            if ($this.TestScope -eq 'All') {
    [string]$configs=$TestMap.Values
            }
            else {
    [string]$configs=@($TestMap[$this.TestScope])
            }

            if ($this.Configuration.Tags) {
    [string]$configs=$configs | where {
    [string]$config=$_
    [string]$this.Configuration.Tags | where {
    [string]$config.Tags -contains $_
                    }
                }
            }

            if ($this.Configuration.ExcludeTags) {
    [string]$configs=$configs | where {
    [string]$config=$_
                    -not ($this.Configuration.ExcludeTags | where {
    [string]$config.Tags -contains $_
                    })
                }
            }

            return $configs
        }

        [PSObject] RunSequentialTests([hashtable]$config) {
    [string]$container=New-PesterContainer -Path $config.Path
    [string]$PesterConfig=New-PesterConfiguration
    [string]$PesterConfig.Run.Container=$container
    [string]$PesterConfig.Run.PassThru=$true
    [string]$PesterConfig.Output.Verbosity='Normal'

            if ($config.Tags) {
    [string]$PesterConfig.Filter.Tag=$config.Tags
            }

            if ($this.Configuration.OutputFormat -ne 'Console') {
    [string]$PesterConfig.TestResult.Enabled=$true
    [string]$PesterConfig.TestResult.OutputPath=Join-Path $this.Configuration.OutputPath "$($config.Name)_Results.xml"
    [string]$PesterConfig.TestResult.OutputFormat='NUnit2.5'
            }
    [string]$PesterConfig.Run.TestData=@{
                ResourceGroupName=$this.ResourceGroupName
                Location=$this.Location
                MockMode=$this.MockMode
                IncludeDestructive=$this.Configuration.IncludeDestructive
                AzureContext=$this.AzureContext
            }

            return Invoke-Pester -Configuration $PesterConfig
        }

        [PSObject] RunParallelTests([hashtable]$config) {
    [string]$TestFiles=Get-ChildItem -Path $config.Path -Filter $config.Pattern -Recurse
    [string]$jobs=@()
    [string]$results=@()
    [string]$TestFiles | ForEach-Object {
    [string]$job=Start-ThreadJob -ScriptBlock {
                    param($FilePath, $TestData, $OutputPath)

                    Import-Module Pester -Force
    [string]$container=New-PesterContainer -Path $FilePath
    [string]$config=New-PesterConfiguration
    [string]$config.Run.Container=$container
    [string]$config.Run.PassThru=$true
    [string]$config.Run.TestData=$TestData
    [string]$config.Output.Verbosity='Minimal'
    [string]$null=$OutputPath

                    Invoke-Pester -Configuration $config
} -ArgumentList $file.FullName, @{
                    ResourceGroupName=$this.ResourceGroupName
                    Location=$this.Location
                    MockMode=$this.MockMode
                }, $this.Configuration.OutputPath
    [string]$jobs += $job

                if ($jobs.Count -ge $this.Configuration.MaxParallelJobs) {
    [string]$completed=Wait-Job -Job $jobs -Any
    [string]$results += Receive-Job -Job $completed
    [string]$jobs=$jobs | where { $_.Id -ne $completed.Id }
                }
            }

            if ($jobs) {
    [string]$results += $jobs | Wait-Job | Receive-Job
            }

            return $this.AggregateResults($results)
        }

        [PSObject] AggregateResults([array]$results) {
            if (-not $results) {
                return $null
            }
    [string]$aggregated=[PSCustomObject]@{
                Tests=@()
                PassedCount=0
                FailedCount=0
                SkippedCount=0
                TotalCount=0
                Duration=[TimeSpan]::Zero
                Result='Passed'
            }
    [string]$results | ForEach-Object {
    if ($result.Tests) {
    [string]$aggregated.Tests += $result.Tests
}
    [string]$aggregated.PassedCount += $result.PassedCount
    [string]$aggregated.FailedCount += $result.FailedCount
    [string]$aggregated.SkippedCount += $result.SkippedCount
    [string]$aggregated.TotalCount += $result.TotalCount
    [string]$aggregated.Duration += $result.Duration
            }

            if ($aggregated.FailedCount -gt 0) {
    [string]$aggregated.Result='Failed'
            }

            return $aggregated
        }

        [void] ValidateInfrastructure() {
            if ($this.MockMode) {
                write-Information 'Skipping infrastructure validation (mock mode)' -InformationAction Continue
                return
            }

            write-Information "Validating Azure infrastructure..." -InformationAction Continue
    [string]$ValidationTests=@(
                @{
                    Name='Resource Group Exists'
                    Test={ Get-AzResourceGroup -Name $this.ResourceGroupName -ErrorAction Stop }
                }
                @{
                    Name='Subscription Active'
                    Test={
    [string]$sub=Get-AzSubscription -SubscriptionId $this.AzureContext.SubscriptionId
                        if ($sub.State -ne 'Enabled') {
                            throw "Subscription is not enabled: $($sub.State)"
                        }
                    }
                }
                @{
                    Name='Required Providers Registered'
                    Test={
    [string]$RequiredProviders=@(
                            'Microsoft.Compute',
                            'Microsoft.Storage',
                            'Microsoft.Network',
                            'Microsoft.KeyVault'
                        )
    [string]$RequiredProviders | ForEach-Object {
    [string]$registration=Get-AzResourceProvider -ProviderNamespace $provider
                            if ($registration.RegistrationState -ne 'Registered') {
                                write-Warning "$provider is not registered. Registering..."
                                Register-AzResourceProvider -ProviderNamespace $provider
}
                        }
                    }
                }
            )

            foreach ($test in $ValidationTests) {
                try {
                    write-Information "  Validating: $($test.Name)" -InformationAction Continue
                    & $test.Test
                    write-Information "    Passed" -InformationAction Continue
                }
                catch {
                    write-Warning "  Validation failed: $($test.Name) - $_"
                }
            }
        }

        [void] RunSecurityTests() {
            write-Information "Running security validation tests..." -InformationAction Continue
    [string]$SecurityChecks=@(
                @{
                    Name='RBAC Assignments'
                    Check={
    [string]$assignments=Get-AzRoleAssignment -ResourceGroupName $this.ResourceGroupName
                        return @{
                            Count=$assignments.Count
                            Assignments=$assignments | select DisplayName, RoleDefinitionName
                        }
                    }
                }
                @{
                    Name='Network Security Groups'
                    Check={
    [string]$nsgs=Get-AzNetworkSecurityGroup -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$issues=@()

                        foreach ($nsg in $nsgs) {
    [string]$rules=$nsg.SecurityRules + $nsg.DefaultSecurityRules
    [string]$RiskyRules=$rules | where {
    [string]$_.Access -eq 'Allow' -and
    [string]$_.Direction -eq 'Inbound' -and
    [string]$_.SourceAddressPrefix -eq '*'
                            }

                            if ($RiskyRules) {
    [string]$issues += "NSG $($nsg.Name) has risky inbound rules"
                            }
                        }

                        return @{
                            NSGCount=$nsgs.Count
                            Issues=$issues
                        }
                    }
                }
                @{
                    Name='Storage Account Security'
                    Check={
    [string]$StorageAccounts=Get-AzStorageAccount -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$issues=@()
    [string]$StorageAccounts | ForEach-Object {
    if ($account.EnableHttpsTrafficOnly -ne $true) {
    [string]$issues += "$($account.StorageAccountName) does not enforce HTTPS"
}
                            if ($account.AllowBlobPublicAccess -eq $true) {
    [string]$issues += "$($account.StorageAccountName) allows public blob access"
                            }
                        }

                        return @{
                            StorageAccountCount=$StorageAccounts.Count
                            Issues=$issues
                        }
                    }
                }
            )

            foreach ($check in $SecurityChecks) {
                try {
                    write-Information "  Running: $($check.Name)" -InformationAction Continue
    [string]$result=& $check.Check

                    if ($result.Issues -and $result.Issues.Count -gt 0) {
                        write-Warning "    Security issues found:"
    [string]$result.Issues | foreach {
                            write-Warning "      $_"
                        }
                    }
                    else {
                        write-Information "    No security issues found" -InformationAction Continue
                    }
                }
                catch {
                    write-Warning "  Security check failed: $($check.Name) - $_"
                }
            }
        }

        [void] RunComplianceTests() {
            write-Information "Running compliance validation..." -InformationAction Continue
    [string]$ComplianceRules=@(
                @{
                    Name='Resource Tagging'
                    Rule={
    [string]$resources=Get-AzResource -ResourceGroupName $this.ResourceGroupName
    [string]$untagged=$resources | where { -not $_.Tags -or $_.Tags.Count -eq 0 }

                        if ($untagged) {
                            return @{
                                Compliant=$false
                                Message="$($untagged.Count) resources without tags"
                                Resources=$untagged.Name
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
                @{
                    Name='Encryption at Rest'
                    Rule={
    [string]$StorageAccounts=Get-AzStorageAccount -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$unencrypted=@()
    [string]$StorageAccounts | ForEach-Object {
    if (-not $account.Encryption.Services.Blob.Enabled) {
    [string]$unencrypted += $account.StorageAccountName
}
                        }

                        if ($unencrypted) {
                            return @{
                                Compliant=$false
                                Message="Storage accounts without encryption: $($unencrypted -join ', ')"
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
                @{
                    Name='Diagnostic Settings'
                    Rule={
    [string]$resources=Get-AzResource -ResourceGroupName $this.ResourceGroupName
    [string]$WithoutDiagnostics=@()
    [string]$resources | ForEach-Object {
    [string]$diagnostics=Get-AzDiagnosticSetting -ResourceId $resource.Id -ErrorAction SilentlyContinue
                            if (-not $diagnostics) {
    [string]$WithoutDiagnostics += $resource.Name
}
                        }

                        if ($WithoutDiagnostics.Count -gt ($resources.Count * 0.5)) {
                            return @{
                                Compliant=$false
                                Message='More than 50% of resources lack diagnostic settings'
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
            )
    [string]$ComplianceScore=0
    [string]$TotalRules=$ComplianceRules.Count

            foreach ($rule in $ComplianceRules) {
                try {
                    write-Information "  Checking: $($rule.Name)" -InformationAction Continue
    [string]$result=& $rule.Rule

                    if ($result.Compliant) {
                        write-Information "    Compliant" -InformationAction Continue
    [string]$ComplianceScore++
                    }
                    else {
                        write-Warning "    Non-compliant: $($result.Message)"
                    }
                }
                catch {
                    write-Warning "  Compliance check failed: $($rule.Name) - $_"
                }
            }
    [string]$percentage=[Math]::Round(($ComplianceScore / $TotalRules) * 100, 2)
            write-Information "Overall Compliance Score: $percentage%" -InformationAction Continue
        }

        [void] Cleanup() {
            if ($this.MockMode -or -not $this.Configuration.IncludeDestructive) {
                write-Information "Skipping cleanup" -InformationAction Continue
                return
            }

            write-Information "Cleaning up test resources..." -InformationAction Continue

            foreach ($resource in $this.ResourcesCreated) {
                try {
                    switch ($resource.Type) {
                        'ResourceGroup' {
                            write-Information "  Removing resource group: $($resource.Name)" -InformationAction Continue
                            Remove-AzResourceGroup -Name $resource.Name -Force -AsJob
                        }
                        default {
                            write-Information "  Removing resource: $($resource.Name)" -InformationAction Continue
                            Remove-AzResource -ResourceId $resource.Id -Force
                        }
                    }
                }
                catch {
                    write-Warning "Failed to cleanup $($resource.Type): $($resource.Name) - $_"
                }
            }
        }

        [void] GenerateReport([PSObject]$results) {
    [string]$ReportPath=Join-Path $this.Configuration.OutputPath "AzureTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

            switch ($this.Configuration.OutputFormat) {
                'HTML' {
    [string]$this.GenerateHtmlReport($results, "$ReportPath.html")
                }
                'JSON' {
    [string]$results | ConvertTo-Json -Depth 10 | Out-File "$ReportPath.json" -Encoding UTF8
                    write-Information "JSON report saved: $ReportPath.json" -InformationAction Continue
                }
                'JUnit' {
    [string]$this.GenerateJUnitReport($results, "$ReportPath.xml")
                }
                'AzureDevOps' {
    [string]$this.GenerateAzureDevOpsReport($results, "$ReportPath.md")
                }
            }
        }

        [void] GenerateHtmlReport([PSObject]$results, [string]$path) {
    [string]$html=@"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Infrastructure Test Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .header { background:
        h1 { margin: 0; }
        .container { max-width: 1200px; margin: auto; background: white; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 20px; }
        .metric { text-align: center; padding: 15px; background:
        .metric-value { font-size: 2em; font-weight: bold; color:
        .metric-label { color:
        .passed { color:
        .failed { color:
        .skipped { color:
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background:
        td { padding: 10px; border-bottom: 1px solid
        .footer { text-align: center; padding: 20px; color:
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Azure Infrastructure Test Report</h1>
            <p>Environment: $($this.TestEnvironment) | Scope: $($this.TestScope)</p>
            <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </div>
        <div class="summary">
            <div class="metric'>
                <div class='metric-value">$($results.TotalCount)</div>
                <div class="metric-label">Total Tests</div>
            </div>
            <div class="metric'>
                <div class='metric-value passed">$($results.PassedCount)</div>
                <div class="metric-label'>Passed</div>
            </div>
            <div class='metric'>
                <div class='metric-value failed">$($results.FailedCount)</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric'>
                <div class='metric-value skipped">$($results.SkippedCount)</div>
                <div class="metric-label">Skipped</div>
            </div>
        </div>
        <div style="padding: 20px;'>
            <h2>Test Details</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Duration</th>
                        <th>Status</th>
                        <th>Message</th>
                    </tr>
                </thead>
                <tbody>
'@
            foreach ($test in $results.Tests) {
    [string]$status=if ($test.Passed) { 'Passed' } elseif ($test.Skipped) { 'Skipped' } else { 'Failed' }
    [string]$html += @"
                    <tr>
                        <td>$($test.Name)</td>
                        <td>$($test.Duration.TotalMilliseconds) ms</td>
                        <td class="$($status.ToLower())">$status</td>
                        <td>$(if ($test.ErrorRecord) { $test.ErrorRecord.Exception.Message } else { '-' })</td>
                    </tr>
"@
            }
    [string]$html += @'
                </tbody>
            </table>
        </div>
        <div class='footer">
            <p>Azure Test Framework v3.0.0 | Duration: $($this.Timer.Elapsed)</p>
        </div>
    </div>
</body>
</html>
"@
    [string]$html | Out-File -FilePath $path -Encoding UTF8
            write-Information "HTML report saved: $path" -InformationAction Continue
        }

        [void] GenerateJUnitReport([PSObject]$results, [string]$path) {
    [string]$xml=@"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Azure Infrastructure Tests" tests="$($results.TotalCount)' failures='$($results.FailedCount)" time="$($results.Duration.TotalSeconds)">
    <testsuite name="$($this.TestScope)" tests="$($results.TotalCount)' failures='$($results.FailedCount)" time="$($results.Duration.TotalSeconds)">
"@
            foreach ($test in $results.Tests) {
    [string]$xml += "        <testcase name=`"$($test.Name)`" time=`"$($test.Duration.TotalSeconds)`''
                if ($test.Passed) {
    [string]$xml += ' />`n'
                }
                elseif ($test.Skipped) {
    [string]$xml += "><skipped /></testcase>`n"
                }
                else {
    [string]$xml += "><failure>$($test.ErrorRecord.Exception.Message)</failure></testcase>`n"
                }
            }
    [string]$xml += @"
    </testsuite>
</testsuites>
"@
    [string]$xml | Out-File -FilePath $path -Encoding UTF8
            write-Information "JUnit report saved: $path" -InformationAction Continue
        }

        [void] GenerateAzureDevOpsReport([PSObject]$results, [string]$path) {
    [string]$markdown=@"

- **Total Tests**: $($results.TotalCount)
- **Passed**: $($results.PassedCount)
- **Failed**: $($results.FailedCount)
- **Skipped**: $($results.SkippedCount)
- **Duration**: $($results.Duration)
- **Pass Rate**: $([Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2))%

- **Environment**: $($this.TestEnvironment)
- **Resource Group**: $($this.ResourceGroupName)
- **Location**: $($this.Location)
- **Mock Mode**: $($this.MockMode)

| Test | Duration | Status |
|------|----------|--------|
"@
            foreach ($test in $results.Tests) {
    [string]$status=if ($test.Passed) { 'Passed' } elseif ($test.Skipped) { 'Skipped' } else { 'Failed' }
    [string]$markdown += "| $($test.Name) | $($test.Duration.TotalMilliseconds)ms | $status |`n"
            }
    [string]$markdown | Out-File -FilePath $path -Encoding UTF8
            write-Information "Azure DevOps report saved: $path" -InformationAction Continue
        }
    }

    write-Information "Azure Infrastructure Test Framework v3.0.0" -InformationAction Continue
    write-Information "==========================================" -InformationAction Continue
}

process {
    try {
    [string]$framework=[AzureTestFramework]::new()
    [string]$framework.TestScope=$TestScope
    [string]$framework.ResourceGroupName=$ResourceGroupName
    [string]$framework.Location=$Location
    [string]$framework.TestEnvironment=$TestEnvironment
    [string]$framework.MockMode=$MockEnabled
    [string]$framework.Configuration=@{
            SubscriptionId=$SubscriptionId
            OutputPath=$OutputPath
            OutputFormat=$OutputFormat
            IncludeDestructive=$IncludeDestructive
            Parallel=$Parallel
            MaxParallelJobs=$MaxParallelJobs
            Tags=$Tags
            ExcludeTags=$ExcludeTags
            RetryCount=$RetryCount
            TimeoutMinutes=$TimeoutMinutes
        }
    [string]$framework.Initialize()

        if (-not $MockEnabled) {
    [string]$framework.PrepareTestEnvironment()
    [string]$framework.ValidateInfrastructure()
        }

        if ($TestScope -in @('Security', 'All')) {
    [string]$framework.RunSecurityTests()
        }

        if ($TestScope -in @('Compliance', 'All')) {
    [string]$framework.RunComplianceTests()
        }
    [string]$results=$framework.RunTests()

        if ($OutputFormat -ne 'Console') {
    [string]$framework.GenerateReport($results)
        }

        write-Information "`nTest Execution Summary" -InformationAction Continue
        write-Information "=====================" -InformationAction Continue
        write-Information "Total: $($results.TotalCount)" -InformationAction Continue
        write-Information "Passed: $($results.PassedCount)" -InformationAction Continue
        write-Information "Failed: $($results.FailedCount)" -InformationAction Continue
        write-Information "Skipped: $($results.SkippedCount)" -InformationAction Continue
        write-Information "Duration: $($framework.Timer.Elapsed)" -InformationAction Continue
    [string]$PassRate=if ($results.TotalCount -gt 0) {
            [Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2)
        } else { 0 }

        write-Information "Pass Rate: $PassRate%" -InformationAction Continue

        if ($IncludeDestructive -and $PSCmdlet.ShouldProcess($ResourceGroupName, "Cleanup test resources")) {
    [string]$framework.Cleanup()
        }

        return $results
    }
    catch {
        write-Error "Test framework failed: $_"
        throw
    }
    finally {
        if ($framework.Timer.IsRunning) {
    [string]$framework.Timer.Stop()
        }
    }
}

end {
    write-Information "`nAzure test execution completed" -InformationAction Continue
    if (Test-Path $OutputPath) {
        write-Information "Reports saved to: $OutputPath" -InformationAction Continue
    }
}


.Direction -eq 'Inbound' -and
#Requires -Modules Az.Accounts, Az.Resources, Az.Compute, Az.Storage, Az.Network, Az.KeyVault, Pester


[CmdletBinding(SupportsShouldProcess)]
param(
    [parameter()]
    [ValidateSet('All', 'Unit', 'Integration', 'Security', 'Performance', 'Compliance', 'Infrastructure')]
    [string]$TestScope='All',

    [parameter()]
    [ValidatePattern('^[a-zA-Z0-9-_\.]+$')]
    [string]$ResourceGroupName="toolkit-test-$(Get-Random -Maximum 9999)",

    [parameter()]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$SubscriptionId,

    [parameter()]
    [ValidateSet('eastus', 'eastus2', 'westus', 'westus2', 'centralus', 'northeurope', 'westeurope')]
    [string]$Location='eastus',

    [parameter()]
    [ValidateSet('Development', 'Test', 'Staging', 'Production')]
    [string]$TestEnvironment='Test',

    [parameter()]
    [switch]$IncludeDestructive,

    [parameter()]
    [switch]$MockEnabled,

    [parameter()]
    [ValidateSet('Console', 'JUnit', 'NUnit', 'HTML', 'JSON', 'AzureDevOps')]
    [string]$OutputFormat='Console',

    [parameter()]


    [ValidateNotNullOrEmpty()]


    [string] $OutputPath='./TestResults',

    [parameter()]
    [switch]$Parallel,

    [parameter()]
    [ValidateRange(1, 16)]
    [int]$MaxParallelJobs=4,

    [parameter()]
    [string[]]$Tags,

    [parameter()]
    [string[]]$ExcludeTags,

    [parameter()]
    [ValidateRange(0, 5)]
    [int]$RetryCount=2,

    [parameter()]
    [ValidateRange(5, 300)]
    [int]$TimeoutMinutes=60
)

begin {
    Set-StrictMode -Version Latest
    [string]$ErrorActionPreference='Stop'
    [string]$ProgressPreference='Continue'

    class AzureTestFramework {
        [string]$TestScope
        [string]$ResourceGroupName
        [string]$Location
        [string]$TestEnvironment
        [hashtable]$Configuration=@{}
        [hashtable]$AzureContext=@{}
        [System.Collections.ArrayList]$TestResults=@()
        [System.Collections.ArrayList]$ResourcesCreated=@()
        [System.Diagnostics.Stopwatch]$Timer
        [bool]$MockMode

        AzureTestFramework() {
    [string]$this.Timer=[System.Diagnostics.Stopwatch]::new()
    [string]$this.MockMode=$false
        }

        [void] Initialize() {
    [string]$this.Timer.Start()

            write-Information "Initializing Azure Test Framework" -InformationAction Continue
            write-Information "Test Environment: $($this.TestEnvironment)" -InformationAction Continue
            write-Information "Mock Mode: $($this.MockMode)" -InformationAction Continue
    [string]$pester=Get-Module -ListAvailable -Name Pester |
                where { $_.Version -ge '5.3.0' } |
                select -First 1

            if (-not $pester) {
                throw "Pester 5.3.0+ required. Install with: Install-Module -Name Pester -MinimumVersion 5.3.0"
            }

            Import-Module Pester -Force

            if (-not $this.MockMode) {
    [string]$this.ConnectAzure()
            }

            if (-not (Test-Path $this.Configuration.OutputPath)) {
                New-Item -Path $this.Configuration.OutputPath -ItemType Directory -Force | Out-Null
            }
        }

        [void] ConnectAzure() {
            try {
    [string]$context=Get-AzContext

                if (-not $context) {
                    write-Information "Connecting to Azure..." -InformationAction Continue
                    Connect-AzAccount
    [string]$context=Get-AzContext
                }

                if ($this.Configuration.SubscriptionId) {
                    write-Information "Setting subscription: $($this.Configuration.SubscriptionId)" -InformationAction Continue
                    Set-AzContext -SubscriptionId $this.Configuration.SubscriptionId
    [string]$context=Get-AzContext
                }
    [string]$this.AzureContext=@{
                    SubscriptionId=$context.Subscription.Id
                    SubscriptionName=$context.Subscription.Name
                    TenantId=$context.Tenant.Id
                    AccountId=$context.Account.Id
                    Environment=$context.Environment.Name
                }

                write-Information "Connected to Azure" -InformationAction Continue
                write-Information "  Subscription: $($this.AzureContext.SubscriptionName)" -InformationAction Continue
                write-Information "  Account: $($this.AzureContext.AccountId)" -InformationAction Continue
            }
            catch {
                throw "Failed to connect to Azure: $_"
            }
        }

        [void] PrepareTestEnvironment() {
            if ($this.MockMode) {
                write-Information 'Skipping environment preparation (mock mode)' -InformationAction Continue
                return
            }

            write-Information "Preparing test environment..." -InformationAction Continue
    [string]$rg=Get-AzResourceGroup -Name $this.ResourceGroupName -ErrorAction SilentlyContinue

            if (-not $rg) {
                write-Information "Creating resource group: $($this.ResourceGroupName)" -InformationAction Continue
    $tags=@{
                    Environment=$this.TestEnvironment
                    Purpose='Testing'
                    Framework='AzureToolkitTestFramework'
                    CreatedBy=$this.AzureContext.AccountId
                    CreatedDate=Get-Date -Format 'yyyy-MM-dd'
                    AutoDelete='true'
                }
    [string]$rg=New-AzResourceGroup `
                    -Name $this.ResourceGroupName `
                    -Location $this.Location `
                    -Tags $tags
    [string]$this.ResourcesCreated.Add(@{
                    Type='ResourceGroup'
                    Name=$this.ResourceGroupName
                    Id=$rg.ResourceId
                })
            }
        }

        [PSObject] RunTests() {
    [string]$TestConfigs=$this.GetTestConfigurations()
    [string]$AllResults=@()

            foreach ($config in $TestConfigs) {
                write-Information "Running $($config.Name) tests..." -InformationAction Continue

                if ($this.Configuration.Parallel -and $config.CanRunParallel) {
    [string]$results=$this.RunParallelTests($config)
                }
                else {
    [string]$results=$this.RunSequentialTests($config)
                }
    [string]$AllResults += $results
    [string]$this.TestResults.Add($results)
            }

            return $this.AggregateResults($AllResults)
        }

        [array] GetTestConfigurations() {
    [string]$configs=@()
    $TestMap=@{
                Unit=@{
                    Name='Unit'
                    Path='./Unit'
                    Pattern='*Unit*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Unit')
                }
                Integration=@{
                    Name='Integration'
                    Path='./Integration'
                    Pattern='*Integration*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Integration')
                    RequiresAzure=$true
                }
                Security=@{
                    Name='Security'
                    Path='./Security'
                    Pattern='*Security*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Security', 'Compliance')
                    RequiresAzure=$true
                }
                Performance=@{
                    Name='Performance'
                    Path='./Performance'
                    Pattern='*Performance*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Performance')
                    RequiresAzure=$true
                }
                Compliance=@{
                    Name='Compliance'
                    Path='./Compliance'
                    Pattern='*Compliance*.Tests.ps1'
                    CanRunParallel=$true
                    Tags=@('Compliance', 'Governance')
                    RequiresAzure=$true
                }
                Infrastructure=@{
                    Name='Infrastructure'
                    Path='./Infrastructure'
                    Pattern='*Infrastructure*.Tests.ps1'
                    CanRunParallel=$false
                    Tags=@('Infrastructure')
                    RequiresAzure=$true
                }
            }

            if ($this.TestScope -eq 'All') {
    [string]$configs=$TestMap.Values
            }
            else {
    [string]$configs=@($TestMap[$this.TestScope])
            }

            if ($this.Configuration.Tags) {
    [string]$configs=$configs | where {
    [string]$config=$_
    [string]$this.Configuration.Tags | where {
    [string]$config.Tags -contains $_
                    }
                }
            }

            if ($this.Configuration.ExcludeTags) {
    [string]$configs=$configs | where {
    [string]$config=$_
                    -not ($this.Configuration.ExcludeTags | where {
    [string]$config.Tags -contains $_
                    })
                }
            }

            return $configs
        }

        [PSObject] RunSequentialTests([hashtable]$config) {
    [string]$container=New-PesterContainer -Path $config.Path
    [string]$PesterConfig=New-PesterConfiguration
    [string]$PesterConfig.Run.Container=$container
    [string]$PesterConfig.Run.PassThru=$true
    [string]$PesterConfig.Output.Verbosity='Normal'

            if ($config.Tags) {
    [string]$PesterConfig.Filter.Tag=$config.Tags
            }

            if ($this.Configuration.OutputFormat -ne 'Console') {
    [string]$PesterConfig.TestResult.Enabled=$true
    [string]$PesterConfig.TestResult.OutputPath=Join-Path $this.Configuration.OutputPath "$($config.Name)_Results.xml"
    [string]$PesterConfig.TestResult.OutputFormat='NUnit2.5'
            }
    [string]$PesterConfig.Run.TestData=@{
                ResourceGroupName=$this.ResourceGroupName
                Location=$this.Location
                MockMode=$this.MockMode
                IncludeDestructive=$this.Configuration.IncludeDestructive
                AzureContext=$this.AzureContext
            }

            return Invoke-Pester -Configuration $PesterConfig
        }

        [PSObject] RunParallelTests([hashtable]$config) {
    [string]$TestFiles=Get-ChildItem -Path $config.Path -Filter $config.Pattern -Recurse
    [string]$jobs=@()
    [string]$results=@()
    [string]$TestFiles | ForEach-Object {
    [string]$job=Start-ThreadJob -ScriptBlock {
                    param($FilePath, $TestData, $OutputPath)

                    Import-Module Pester -Force
    [string]$container=New-PesterContainer -Path $FilePath
    [string]$config=New-PesterConfiguration
    [string]$config.Run.Container=$container
    [string]$config.Run.PassThru=$true
    [string]$config.Run.TestData=$TestData
    [string]$config.Output.Verbosity='Minimal'
    [string]$null=$OutputPath

                    Invoke-Pester -Configuration $config
} -ArgumentList $file.FullName, @{
                    ResourceGroupName=$this.ResourceGroupName
                    Location=$this.Location
                    MockMode=$this.MockMode
                }, $this.Configuration.OutputPath
    [string]$jobs += $job

                if ($jobs.Count -ge $this.Configuration.MaxParallelJobs) {
    [string]$completed=Wait-Job -Job $jobs -Any
    [string]$results += Receive-Job -Job $completed
    [string]$jobs=$jobs | where { $_.Id -ne $completed.Id }
                }
            }

            if ($jobs) {
    [string]$results += $jobs | Wait-Job | Receive-Job
            }

            return $this.AggregateResults($results)
        }

        [PSObject] AggregateResults([array]$results) {
            if (-not $results) {
                return $null
            }
    [string]$aggregated=[PSCustomObject]@{
                Tests=@()
                PassedCount=0
                FailedCount=0
                SkippedCount=0
                TotalCount=0
                Duration=[TimeSpan]::Zero
                Result='Passed'
            }
    [string]$results | ForEach-Object {
    if ($result.Tests) {
    [string]$aggregated.Tests += $result.Tests
}
    [string]$aggregated.PassedCount += $result.PassedCount
    [string]$aggregated.FailedCount += $result.FailedCount
    [string]$aggregated.SkippedCount += $result.SkippedCount
    [string]$aggregated.TotalCount += $result.TotalCount
    [string]$aggregated.Duration += $result.Duration
            }

            if ($aggregated.FailedCount -gt 0) {
    [string]$aggregated.Result='Failed'
            }

            return $aggregated
        }

        [void] ValidateInfrastructure() {
            if ($this.MockMode) {
                write-Information 'Skipping infrastructure validation (mock mode)' -InformationAction Continue
                return
            }

            write-Information "Validating Azure infrastructure..." -InformationAction Continue
    [string]$ValidationTests=@(
                @{
                    Name='Resource Group Exists'
                    Test={ Get-AzResourceGroup -Name $this.ResourceGroupName -ErrorAction Stop }
                }
                @{
                    Name='Subscription Active'
                    Test={
    [string]$sub=Get-AzSubscription -SubscriptionId $this.AzureContext.SubscriptionId
                        if ($sub.State -ne 'Enabled') {
                            throw "Subscription is not enabled: $($sub.State)"
                        }
                    }
                }
                @{
                    Name='Required Providers Registered'
                    Test={
    [string]$RequiredProviders=@(
                            'Microsoft.Compute',
                            'Microsoft.Storage',
                            'Microsoft.Network',
                            'Microsoft.KeyVault'
                        )
    [string]$RequiredProviders | ForEach-Object {
    [string]$registration=Get-AzResourceProvider -ProviderNamespace $provider
                            if ($registration.RegistrationState -ne 'Registered') {
                                write-Warning "$provider is not registered. Registering..."
                                Register-AzResourceProvider -ProviderNamespace $provider
}
                        }
                    }
                }
            )

            foreach ($test in $ValidationTests) {
                try {
                    write-Information "  Validating: $($test.Name)" -InformationAction Continue
                    & $test.Test
                    write-Information "    Passed" -InformationAction Continue
                }
                catch {
                    write-Warning "  Validation failed: $($test.Name) - $_"
                }
            }
        }

        [void] RunSecurityTests() {
            write-Information "Running security validation tests..." -InformationAction Continue
    [string]$SecurityChecks=@(
                @{
                    Name='RBAC Assignments'
                    Check={
    [string]$assignments=Get-AzRoleAssignment -ResourceGroupName $this.ResourceGroupName
                        return @{
                            Count=$assignments.Count
                            Assignments=$assignments | select DisplayName, RoleDefinitionName
                        }
                    }
                }
                @{
                    Name='Network Security Groups'
                    Check={
    [string]$nsgs=Get-AzNetworkSecurityGroup -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$issues=@()

                        foreach ($nsg in $nsgs) {
    [string]$rules=$nsg.SecurityRules + $nsg.DefaultSecurityRules
    [string]$RiskyRules=$rules | where {
    [string]$_.Access -eq 'Allow' -and
    [string]$_.Direction -eq 'Inbound' -and
    [string]$_.SourceAddressPrefix -eq '*'
                            }

                            if ($RiskyRules) {
    [string]$issues += "NSG $($nsg.Name) has risky inbound rules"
                            }
                        }

                        return @{
                            NSGCount=$nsgs.Count
                            Issues=$issues
                        }
                    }
                }
                @{
                    Name='Storage Account Security'
                    Check={
    [string]$StorageAccounts=Get-AzStorageAccount -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$issues=@()
    [string]$StorageAccounts | ForEach-Object {
    if ($account.EnableHttpsTrafficOnly -ne $true) {
    [string]$issues += "$($account.StorageAccountName) does not enforce HTTPS"
}
                            if ($account.AllowBlobPublicAccess -eq $true) {
    [string]$issues += "$($account.StorageAccountName) allows public blob access"
                            }
                        }

                        return @{
                            StorageAccountCount=$StorageAccounts.Count
                            Issues=$issues
                        }
                    }
                }
            )

            foreach ($check in $SecurityChecks) {
                try {
                    write-Information "  Running: $($check.Name)" -InformationAction Continue
    [string]$result=& $check.Check

                    if ($result.Issues -and $result.Issues.Count -gt 0) {
                        write-Warning "    Security issues found:"
    [string]$result.Issues | foreach {
                            write-Warning "      $_"
                        }
                    }
                    else {
                        write-Information "    No security issues found" -InformationAction Continue
                    }
                }
                catch {
                    write-Warning "  Security check failed: $($check.Name) - $_"
                }
            }
        }

        [void] RunComplianceTests() {
            write-Information "Running compliance validation..." -InformationAction Continue
    [string]$ComplianceRules=@(
                @{
                    Name='Resource Tagging'
                    Rule={
    [string]$resources=Get-AzResource -ResourceGroupName $this.ResourceGroupName
    [string]$untagged=$resources | where { -not $_.Tags -or $_.Tags.Count -eq 0 }

                        if ($untagged) {
                            return @{
                                Compliant=$false
                                Message="$($untagged.Count) resources without tags"
                                Resources=$untagged.Name
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
                @{
                    Name='Encryption at Rest'
                    Rule={
    [string]$StorageAccounts=Get-AzStorageAccount -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$unencrypted=@()
    [string]$StorageAccounts | ForEach-Object {
    if (-not $account.Encryption.Services.Blob.Enabled) {
    [string]$unencrypted += $account.StorageAccountName
}
                        }

                        if ($unencrypted) {
                            return @{
                                Compliant=$false
                                Message="Storage accounts without encryption: $($unencrypted -join ', ')"
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
                @{
                    Name='Diagnostic Settings'
                    Rule={
    [string]$resources=Get-AzResource -ResourceGroupName $this.ResourceGroupName
    [string]$WithoutDiagnostics=@()
    [string]$resources | ForEach-Object {
    [string]$diagnostics=Get-AzDiagnosticSetting -ResourceId $resource.Id -ErrorAction SilentlyContinue
                            if (-not $diagnostics) {
    [string]$WithoutDiagnostics += $resource.Name
}
                        }

                        if ($WithoutDiagnostics.Count -gt ($resources.Count * 0.5)) {
                            return @{
                                Compliant=$false
                                Message='More than 50% of resources lack diagnostic settings'
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
            )
    [string]$ComplianceScore=0
    [string]$TotalRules=$ComplianceRules.Count

            foreach ($rule in $ComplianceRules) {
                try {
                    write-Information "  Checking: $($rule.Name)" -InformationAction Continue
    [string]$result=& $rule.Rule

                    if ($result.Compliant) {
                        write-Information "    Compliant" -InformationAction Continue
    [string]$ComplianceScore++
                    }
                    else {
                        write-Warning "    Non-compliant: $($result.Message)"
                    }
                }
                catch {
                    write-Warning "  Compliance check failed: $($rule.Name) - $_"
                }
            }
    [string]$percentage=[Math]::Round(($ComplianceScore / $TotalRules) * 100, 2)
            write-Information "Overall Compliance Score: $percentage%" -InformationAction Continue
        }

        [void] Cleanup() {
            if ($this.MockMode -or -not $this.Configuration.IncludeDestructive) {
                write-Information "Skipping cleanup" -InformationAction Continue
                return
            }

            write-Information "Cleaning up test resources..." -InformationAction Continue

            foreach ($resource in $this.ResourcesCreated) {
                try {
                    switch ($resource.Type) {
                        'ResourceGroup' {
                            write-Information "  Removing resource group: $($resource.Name)" -InformationAction Continue
                            Remove-AzResourceGroup -Name $resource.Name -Force -AsJob
                        }
                        default {
                            write-Information "  Removing resource: $($resource.Name)" -InformationAction Continue
                            Remove-AzResource -ResourceId $resource.Id -Force
                        }
                    }
                }
                catch {
                    write-Warning "Failed to cleanup $($resource.Type): $($resource.Name) - $_"
                }
            }
        }

        [void] GenerateReport([PSObject]$results) {
    [string]$ReportPath=Join-Path $this.Configuration.OutputPath "AzureTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

            switch ($this.Configuration.OutputFormat) {
                'HTML' {
    [string]$this.GenerateHtmlReport($results, "$ReportPath.html")
                }
                'JSON' {
    [string]$results | ConvertTo-Json -Depth 10 | Out-File "$ReportPath.json" -Encoding UTF8
                    write-Information "JSON report saved: $ReportPath.json" -InformationAction Continue
                }
                'JUnit' {
    [string]$this.GenerateJUnitReport($results, "$ReportPath.xml")
                }
                'AzureDevOps' {
    [string]$this.GenerateAzureDevOpsReport($results, "$ReportPath.md")
                }
            }
        }

        [void] GenerateHtmlReport([PSObject]$results, [string]$path) {
    [string]$html=@"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Infrastructure Test Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .header { background:
        h1 { margin: 0; }
        .container { max-width: 1200px; margin: auto; background: white; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 20px; }
        .metric { text-align: center; padding: 15px; background:
        .metric-value { font-size: 2em; font-weight: bold; color:
        .metric-label { color:
        .passed { color:
        .failed { color:
        .skipped { color:
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background:
        td { padding: 10px; border-bottom: 1px solid
        .footer { text-align: center; padding: 20px; color:
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Azure Infrastructure Test Report</h1>
            <p>Environment: $($this.TestEnvironment) | Scope: $($this.TestScope)</p>
            <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </div>
        <div class="summary">
            <div class="metric'>
                <div class='metric-value">$($results.TotalCount)</div>
                <div class="metric-label">Total Tests</div>
            </div>
            <div class="metric'>
                <div class='metric-value passed">$($results.PassedCount)</div>
                <div class="metric-label'>Passed</div>
            </div>
            <div class='metric'>
                <div class='metric-value failed">$($results.FailedCount)</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric'>
                <div class='metric-value skipped">$($results.SkippedCount)</div>
                <div class="metric-label">Skipped</div>
            </div>
        </div>
        <div style="padding: 20px;'>
            <h2>Test Details</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Duration</th>
                        <th>Status</th>
                        <th>Message</th>
                    </tr>
                </thead>
                <tbody>
'@
            foreach ($test in $results.Tests) {
    [string]$status=if ($test.Passed) { 'Passed' } elseif ($test.Skipped) { 'Skipped' } else { 'Failed' }
    [string]$html += @"
                    <tr>
                        <td>$($test.Name)</td>
                        <td>$($test.Duration.TotalMilliseconds) ms</td>
                        <td class="$($status.ToLower())">$status</td>
                        <td>$(if ($test.ErrorRecord) { $test.ErrorRecord.Exception.Message } else { '-' })</td>
                    </tr>
"@
            }
    [string]$html += @'
                </tbody>
            </table>
        </div>
        <div class='footer">
            <p>Azure Test Framework v3.0.0 | Duration: $($this.Timer.Elapsed)</p>
        </div>
    </div>
</body>
</html>
"@
    [string]$html | Out-File -FilePath $path -Encoding UTF8
            write-Information "HTML report saved: $path" -InformationAction Continue
        }

        [void] GenerateJUnitReport([PSObject]$results, [string]$path) {
    [string]$xml=@"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Azure Infrastructure Tests" tests="$($results.TotalCount)' failures='$($results.FailedCount)" time="$($results.Duration.TotalSeconds)">
    <testsuite name="$($this.TestScope)" tests="$($results.TotalCount)' failures='$($results.FailedCount)" time="$($results.Duration.TotalSeconds)">
"@
            foreach ($test in $results.Tests) {
    [string]$xml += "        <testcase name=`"$($test.Name)`" time=`"$($test.Duration.TotalSeconds)`''
                if ($test.Passed) {
    [string]$xml += ' />`n'
                }
                elseif ($test.Skipped) {
    [string]$xml += "><skipped /></testcase>`n"
                }
                else {
    [string]$xml += "><failure>$($test.ErrorRecord.Exception.Message)</failure></testcase>`n"
                }
            }
    [string]$xml += @"
    </testsuite>
</testsuites>
"@
    [string]$xml | Out-File -FilePath $path -Encoding UTF8
            write-Information "JUnit report saved: $path" -InformationAction Continue
        }

        [void] GenerateAzureDevOpsReport([PSObject]$results, [string]$path) {
    [string]$markdown=@"

- **Total Tests**: $($results.TotalCount)
- **Passed**: $($results.PassedCount)
- **Failed**: $($results.FailedCount)
- **Skipped**: $($results.SkippedCount)
- **Duration**: $($results.Duration)
- **Pass Rate**: $([Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2))%

- **Environment**: $($this.TestEnvironment)
- **Resource Group**: $($this.ResourceGroupName)
- **Location**: $($this.Location)
- **Mock Mode**: $($this.MockMode)

| Test | Duration | Status |
|------|----------|--------|
"@
            foreach ($test in $results.Tests) {
    [string]$status=if ($test.Passed) { 'Passed' } elseif ($test.Skipped) { 'Skipped' } else { 'Failed' }
    [string]$markdown += "| $($test.Name) | $($test.Duration.TotalMilliseconds)ms | $status |`n"
            }
    [string]$markdown | Out-File -FilePath $path -Encoding UTF8
            write-Information "Azure DevOps report saved: $path" -InformationAction Continue
        }
    }

    write-Information "Azure Infrastructure Test Framework v3.0.0" -InformationAction Continue
    write-Information "==========================================" -InformationAction Continue
}

process {
    try {
    [string]$framework=[AzureTestFramework]::new()
    [string]$framework.TestScope=$TestScope
    [string]$framework.ResourceGroupName=$ResourceGroupName
    [string]$framework.Location=$Location
    [string]$framework.TestEnvironment=$TestEnvironment
    [string]$framework.MockMode=$MockEnabled
    [string]$framework.Configuration=@{
            SubscriptionId=$SubscriptionId
            OutputPath=$OutputPath
            OutputFormat=$OutputFormat
            IncludeDestructive=$IncludeDestructive
            Parallel=$Parallel
            MaxParallelJobs=$MaxParallelJobs
            Tags=$Tags
            ExcludeTags=$ExcludeTags
            RetryCount=$RetryCount
            TimeoutMinutes=$TimeoutMinutes
        }
    [string]$framework.Initialize()

        if (-not $MockEnabled) {
    [string]$framework.PrepareTestEnvironment()
    [string]$framework.ValidateInfrastructure()
        }

        if ($TestScope -in @('Security', 'All')) {
    [string]$framework.RunSecurityTests()
        }

        if ($TestScope -in @('Compliance', 'All')) {
    [string]$framework.RunComplianceTests()
        }
    [string]$results=$framework.RunTests()

        if ($OutputFormat -ne 'Console') {
    [string]$framework.GenerateReport($results)
        }

        write-Information "`nTest Execution Summary" -InformationAction Continue
        write-Information "=====================" -InformationAction Continue
        write-Information "Total: $($results.TotalCount)" -InformationAction Continue
        write-Information "Passed: $($results.PassedCount)" -InformationAction Continue
        write-Information "Failed: $($results.FailedCount)" -InformationAction Continue
        write-Information "Skipped: $($results.SkippedCount)" -InformationAction Continue
        write-Information "Duration: $($framework.Timer.Elapsed)" -InformationAction Continue
    [string]$PassRate=if ($results.TotalCount -gt 0) {
            [Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2)
        } else { 0 }

        write-Information "Pass Rate: $PassRate%" -InformationAction Continue

        if ($IncludeDestructive -and $PSCmdlet.ShouldProcess($ResourceGroupName, "Cleanup test resources")) {
    [string]$framework.Cleanup()
        }

        return $results
    }
    catch {
        write-Error "Test framework failed: $_"
        throw
    }
    finally {
        if ($framework.Timer.IsRunning) {
    [string]$framework.Timer.Stop()
        }
    }
}

end {
    write-Information "`nAzure test execution completed" -InformationAction Continue
    if (Test-Path $OutputPath) {
        write-Information "Reports saved to: $OutputPath" -InformationAction Continue
    }
}


.SourceAddressPrefix -eq '*'
}

                            if ($RiskyRules) {
    [string]$issues += "NSG $($nsg.Name) has risky inbound rules"
                            }
                        }

                        return @{
                            NSGCount=$nsgs.Count
                            Issues=$issues
                        }
                    }
                }
                @{
                    Name='Storage Account Security'
                    Check={
    [string]$StorageAccounts=Get-AzStorageAccount -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$issues=@()
    [string]$StorageAccounts | ForEach-Object {
    if ($account.EnableHttpsTrafficOnly -ne $true) {
    [string]$issues += "$($account.StorageAccountName) does not enforce HTTPS"
}
                            if ($account.AllowBlobPublicAccess -eq $true) {
    [string]$issues += "$($account.StorageAccountName) allows public blob access"
                            }
                        }

                        return @{
                            StorageAccountCount=$StorageAccounts.Count
                            Issues=$issues
                        }
                    }
                }
            )

            foreach ($check in $SecurityChecks) {
                try {
                    write-Information "  Running: $($check.Name)" -InformationAction Continue
    [string]$result=& $check.Check

                    if ($result.Issues -and $result.Issues.Count -gt 0) {
                        write-Warning "    Security issues found:"
    [string]$result.Issues | foreach {
                            write-Warning "      $_"
                        }
                    }
                    else {
                        write-Information "    No security issues found" -InformationAction Continue
                    }
                }
                catch {
                    write-Warning "  Security check failed: $($check.Name) - $_"
                }
            }
        }

        [void] RunComplianceTests() {
            write-Information "Running compliance validation..." -InformationAction Continue
    [string]$ComplianceRules=@(
                @{
                    Name='Resource Tagging'
                    Rule={
    [string]$resources=Get-AzResource -ResourceGroupName $this.ResourceGroupName
    [string]$untagged=$resources | where { -not $_.Tags -or $_.Tags.Count -eq 0 }

                        if ($untagged) {
                            return @{
                                Compliant=$false
                                Message="$($untagged.Count) resources without tags"
                                Resources=$untagged.Name
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
                @{
                    Name='Encryption at Rest'
                    Rule={
    [string]$StorageAccounts=Get-AzStorageAccount -ResourceGroupName $this.ResourceGroupName -ErrorAction SilentlyContinue
    [string]$unencrypted=@()
    [string]$StorageAccounts | ForEach-Object {
    if (-not $account.Encryption.Services.Blob.Enabled) {
    [string]$unencrypted += $account.StorageAccountName
}
                        }

                        if ($unencrypted) {
                            return @{
                                Compliant=$false
                                Message="Storage accounts without encryption: $($unencrypted -join ', ')"
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
                @{
                    Name='Diagnostic Settings'
                    Rule={
    [string]$resources=Get-AzResource -ResourceGroupName $this.ResourceGroupName
    [string]$WithoutDiagnostics=@()
    [string]$resources | ForEach-Object {
    [string]$diagnostics=Get-AzDiagnosticSetting -ResourceId $resource.Id -ErrorAction SilentlyContinue
                            if (-not $diagnostics) {
    [string]$WithoutDiagnostics += $resource.Name
}
                        }

                        if ($WithoutDiagnostics.Count -gt ($resources.Count * 0.5)) {
                            return @{
                                Compliant=$false
                                Message='More than 50% of resources lack diagnostic settings'
                            }
                        }

                        return @{ Compliant=$true }
                    }
                }
            )
    [string]$ComplianceScore=0
    [string]$TotalRules=$ComplianceRules.Count

            foreach ($rule in $ComplianceRules) {
                try {
                    write-Information "  Checking: $($rule.Name)" -InformationAction Continue
    [string]$result=& $rule.Rule

                    if ($result.Compliant) {
                        write-Information "    Compliant" -InformationAction Continue
    [string]$ComplianceScore++
                    }
                    else {
                        write-Warning "    Non-compliant: $($result.Message)"
                    }
                }
                catch {
                    write-Warning "  Compliance check failed: $($rule.Name) - $_"
                }
            }
    [string]$percentage=[Math]::Round(($ComplianceScore / $TotalRules) * 100, 2)
            write-Information "Overall Compliance Score: $percentage%" -InformationAction Continue
        }

        [void] Cleanup() {
            if ($this.MockMode -or -not $this.Configuration.IncludeDestructive) {
                write-Information "Skipping cleanup" -InformationAction Continue
                return
            }

            write-Information "Cleaning up test resources..." -InformationAction Continue

            foreach ($resource in $this.ResourcesCreated) {
                try {
                    switch ($resource.Type) {
                        'ResourceGroup' {
                            write-Information "  Removing resource group: $($resource.Name)" -InformationAction Continue
                            Remove-AzResourceGroup -Name $resource.Name -Force -AsJob
                        }
                        default {
                            write-Information "  Removing resource: $($resource.Name)" -InformationAction Continue
                            Remove-AzResource -ResourceId $resource.Id -Force
                        }
                    }
                }
                catch {
                    write-Warning "Failed to cleanup $($resource.Type): $($resource.Name) - $_"
                }
            }
        }

        [void] GenerateReport([PSObject]$results) {
    [string]$ReportPath=Join-Path $this.Configuration.OutputPath "AzureTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

            switch ($this.Configuration.OutputFormat) {
                'HTML' {
    [string]$this.GenerateHtmlReport($results, "$ReportPath.html")
                }
                'JSON' {
    [string]$results | ConvertTo-Json -Depth 10 | Out-File "$ReportPath.json" -Encoding UTF8
                    write-Information "JSON report saved: $ReportPath.json" -InformationAction Continue
                }
                'JUnit' {
    [string]$this.GenerateJUnitReport($results, "$ReportPath.xml")
                }
                'AzureDevOps' {
    [string]$this.GenerateAzureDevOpsReport($results, "$ReportPath.md")
                }
            }
        }

        [void] GenerateHtmlReport([PSObject]$results, [string]$path) {
    [string]$html=@"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Infrastructure Test Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .header { background:
        h1 { margin: 0; }
        .container { max-width: 1200px; margin: auto; background: white; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 20px; }
        .metric { text-align: center; padding: 15px; background:
        .metric-value { font-size: 2em; font-weight: bold; color:
        .metric-label { color:
        .passed { color:
        .failed { color:
        .skipped { color:
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background:
        td { padding: 10px; border-bottom: 1px solid
        .footer { text-align: center; padding: 20px; color:
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Azure Infrastructure Test Report</h1>
            <p>Environment: $($this.TestEnvironment) | Scope: $($this.TestScope)</p>
            <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </div>
        <div class="summary">
            <div class="metric'>
                <div class='metric-value">$($results.TotalCount)</div>
                <div class="metric-label">Total Tests</div>
            </div>
            <div class="metric'>
                <div class='metric-value passed">$($results.PassedCount)</div>
                <div class="metric-label'>Passed</div>
            </div>
            <div class='metric'>
                <div class='metric-value failed">$($results.FailedCount)</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric'>
                <div class='metric-value skipped">$($results.SkippedCount)</div>
                <div class="metric-label">Skipped</div>
            </div>
        </div>
        <div style="padding: 20px;'>
            <h2>Test Details</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Duration</th>
                        <th>Status</th>
                        <th>Message</th>
                    </tr>
                </thead>
                <tbody>
'@
            foreach ($test in $results.Tests) {
    [string]$status=if ($test.Passed) { 'Passed' } elseif ($test.Skipped) { 'Skipped' } else { 'Failed' }
    [string]$html += @"
                    <tr>
                        <td>$($test.Name)</td>
                        <td>$($test.Duration.TotalMilliseconds) ms</td>
                        <td class="$($status.ToLower())">$status</td>
                        <td>$(if ($test.ErrorRecord) { $test.ErrorRecord.Exception.Message } else { '-' })</td>
                    </tr>
"@
            }
    [string]$html += @'
                </tbody>
            </table>
        </div>
        <div class='footer">
            <p>Azure Test Framework v3.0.0 | Duration: $($this.Timer.Elapsed)</p>
        </div>
    </div>
</body>
</html>
"@
    [string]$html | Out-File -FilePath $path -Encoding UTF8
            write-Information "HTML report saved: $path" -InformationAction Continue
        }

        [void] GenerateJUnitReport([PSObject]$results, [string]$path) {
    [string]$xml=@"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Azure Infrastructure Tests" tests="$($results.TotalCount)' failures='$($results.FailedCount)" time="$($results.Duration.TotalSeconds)">
    <testsuite name="$($this.TestScope)" tests="$($results.TotalCount)' failures='$($results.FailedCount)" time="$($results.Duration.TotalSeconds)">
"@
            foreach ($test in $results.Tests) {
    [string]$xml += "        <testcase name=`"$($test.Name)`" time=`"$($test.Duration.TotalSeconds)`''
                if ($test.Passed) {
    [string]$xml += ' />`n'
                }
                elseif ($test.Skipped) {
    [string]$xml += "><skipped /></testcase>`n"
                }
                else {
    [string]$xml += "><failure>$($test.ErrorRecord.Exception.Message)</failure></testcase>`n"
                }
            }
    [string]$xml += @"
    </testsuite>
</testsuites>
"@
    [string]$xml | Out-File -FilePath $path -Encoding UTF8
            write-Information "JUnit report saved: $path" -InformationAction Continue
        }

        [void] GenerateAzureDevOpsReport([PSObject]$results, [string]$path) {
    [string]$markdown=@"

- **Total Tests**: $($results.TotalCount)
- **Passed**: $($results.PassedCount)
- **Failed**: $($results.FailedCount)
- **Skipped**: $($results.SkippedCount)
- **Duration**: $($results.Duration)
- **Pass Rate**: $([Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2))%

- **Environment**: $($this.TestEnvironment)
- **Resource Group**: $($this.ResourceGroupName)
- **Location**: $($this.Location)
- **Mock Mode**: $($this.MockMode)

| Test | Duration | Status |
|------|----------|--------|
"@
            foreach ($test in $results.Tests) {
    [string]$status=if ($test.Passed) { 'Passed' } elseif ($test.Skipped) { 'Skipped' } else { 'Failed' }
    [string]$markdown += "| $($test.Name) | $($test.Duration.TotalMilliseconds)ms | $status |`n"
            }
    [string]$markdown | Out-File -FilePath $path -Encoding UTF8
            write-Information "Azure DevOps report saved: $path" -InformationAction Continue
        }
    }

    write-Information "Azure Infrastructure Test Framework v3.0.0" -InformationAction Continue
    write-Information "==========================================" -InformationAction Continue
}

process {
    try {
    [string]$framework=[AzureTestFramework]::new()
    [string]$framework.TestScope=$TestScope
    [string]$framework.ResourceGroupName=$ResourceGroupName
    [string]$framework.Location=$Location
    [string]$framework.TestEnvironment=$TestEnvironment
    [string]$framework.MockMode=$MockEnabled
    [string]$framework.Configuration=@{
            SubscriptionId=$SubscriptionId
            OutputPath=$OutputPath
            OutputFormat=$OutputFormat
            IncludeDestructive=$IncludeDestructive
            Parallel=$Parallel
            MaxParallelJobs=$MaxParallelJobs
            Tags=$Tags
            ExcludeTags=$ExcludeTags
            RetryCount=$RetryCount
            TimeoutMinutes=$TimeoutMinutes
        }
    [string]$framework.Initialize()

        if (-not $MockEnabled) {
    [string]$framework.PrepareTestEnvironment()
    [string]$framework.ValidateInfrastructure()
        }

        if ($TestScope -in @('Security', 'All')) {
    [string]$framework.RunSecurityTests()
        }

        if ($TestScope -in @('Compliance', 'All')) {
    [string]$framework.RunComplianceTests()
        }
    [string]$results=$framework.RunTests()

        if ($OutputFormat -ne 'Console') {
    [string]$framework.GenerateReport($results)
        }

        write-Information "`nTest Execution Summary" -InformationAction Continue
        write-Information "=====================" -InformationAction Continue
        write-Information "Total: $($results.TotalCount)" -InformationAction Continue
        write-Information "Passed: $($results.PassedCount)" -InformationAction Continue
        write-Information "Failed: $($results.FailedCount)" -InformationAction Continue
        write-Information "Skipped: $($results.SkippedCount)" -InformationAction Continue
        write-Information "Duration: $($framework.Timer.Elapsed)" -InformationAction Continue
    [string]$PassRate=if ($results.TotalCount -gt 0) {
            [Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2)
        } else { 0 }

        write-Information "Pass Rate: $PassRate%" -InformationAction Continue

        if ($IncludeDestructive -and $PSCmdlet.ShouldProcess($ResourceGroupName, "Cleanup test resources")) {
    [string]$framework.Cleanup()
        }

        return $results
    }
    catch {
        write-Error "Test framework failed: $_"
        throw
    }
    finally {
        if ($framework.Timer.IsRunning) {
    [string]$framework.Timer.Stop()
        }
    }
}

end {
    write-Information "`nAzure test execution completed" -InformationAction Continue
    if (Test-Path $OutputPath) {
        write-Information "Reports saved to: $OutputPath" -InformationAction Continue
    }
`n}
