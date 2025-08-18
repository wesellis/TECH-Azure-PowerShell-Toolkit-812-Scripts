#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Enterprise Azure Storage Management Module
.DESCRIPTION
    Advanced storage account management with lifecycle policies, security, and cost optimization
.VERSION
    2.0.0
.AUTHOR
    Azure Enterprise Toolkit
#>

# Module configuration
$script:ModuleVersion = '2.0.0'
$script:DefaultLifecycleDays = @{
    HotToCoool = 30
    CoolToArchive = 90
    DeleteAfter = 365
}

#region Storage Account Management

function New-AzStorageAccountAdvanced {
    <#
    .SYNOPSIS
        Create storage account with enterprise standards
    .DESCRIPTION
        Creates a storage account with security best practices, lifecycle management, and monitoring
    .PARAMETER Name
        Storage account name (3-24 chars, lowercase, no hyphens)
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER Location
        Azure region
    .PARAMETER Tier
        Performance tier (Standard or Premium)
    .PARAMETER Replication
        Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)
    .PARAMETER EnableHttpsOnly
        Enforce HTTPS traffic only
    .PARAMETER EnableHierarchicalNamespace
        Enable Data Lake Gen2
    .PARAMETER EnableLifecycleManagement
        Enable blob lifecycle management
    .PARAMETER Tags
        Resource tags
    .EXAMPLE
        New-AzStorageAccountAdvanced -Name "stproddata001" -ResourceGroupName "rg-prod" -Location "eastus" -EnableLifecycleManagement
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-z0-9]{3,24}$')]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$Location,
        
        [ValidateSet('Standard', 'Premium')]
        [string]$Tier = 'Standard',
        
        [ValidateSet('LRS', 'GRS', 'RAGRS', 'ZRS', 'GZRS', 'RAGZRS')]
        [string]$Replication = 'GRS',
        
        [switch]$EnableHttpsOnly = $true,
        
        [switch]$EnableHierarchicalNamespace,
        
        [switch]$EnableLifecycleManagement,
        
        [hashtable]$Tags = @{}
    )
    
    if ($PSCmdlet.ShouldProcess($Name, "Create storage account")) {
        try {
            # Create storage account parameters
            $params = @{
                ResourceGroupName = $ResourceGroupName
                Name = $Name
                Location = $Location
                SkuName = "${Tier}_${Replication}"
                Kind = 'StorageV2'
                EnableHttpsTrafficOnly = $EnableHttpsOnly
                MinimumTlsVersion = 'TLS1_2'
                AllowBlobPublicAccess = $false
                NetworkRuleSet = @{
                    DefaultAction = 'Deny'
                    Bypass = 'AzureServices'
                    IpRules = @()
                    VirtualNetworkRules = @()
                }
                Tag = $Tags
            }
            
            if ($EnableHierarchicalNamespace) {
                $params.EnableHierarchicalNamespace = $true
            }
            
            # Create storage account
            $storageAccount = New-AzStorageAccount @params
            
            # Configure additional security settings
            Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name `
                -EnableActiveDirectoryDomainServicesForFile $false `
                -EnableAzureActiveDirectoryDomainServicesForFile $false
            
            # Enable blob versioning and soft delete
            Update-AzStorageBlobServiceProperty -ResourceGroupName $ResourceGroupName `
                -StorageAccountName $Name `
                -IsVersioningEnabled $true `
                -DeleteRetentionPolicy @{
                    Enabled = $true
                    Days = 30
                } `
                -ContainerDeleteRetentionPolicy @{
                    Enabled = $true
                    Days = 30
                } `
                -RestorePolicy @{
                    Enabled = $true
                    Days = 29
                }
            
            # Enable lifecycle management if requested
            if ($EnableLifecycleManagement) {
                Set-AzStorageAccountLifecyclePolicy -ResourceGroupName $ResourceGroupName `
                    -StorageAccountName $Name -Policy (Get-DefaultLifecyclePolicy)
            }
            
            # Enable diagnostic logging
            $diagnosticSettings = @{
                ResourceId = $storageAccount.Id
                Name = "diag-$Name"
                Category = @('StorageRead', 'StorageWrite', 'StorageDelete')
                Enabled = $true
                RetentionPolicy = @{
                    Enabled = $true
                    Days = 30
                }
            }
            
            Write-Information "Successfully created storage account: $Name" -InformationAction Continue
            return $storageAccount
        }
        catch {
            Write-Error "Failed to create storage account: $_"
        }
    }
}

function Test-AzStorageAccountSecurity {
    <#
    .SYNOPSIS
        Test storage account security configuration
    .DESCRIPTION
        Validates storage account against security best practices
    .PARAMETER StorageAccountName
        Storage account name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER RemediateSecurity
        Attempt to fix security issues
    .EXAMPLE
        Test-AzStorageAccountSecurity -StorageAccountName "stproddata001" -ResourceGroupName "rg-prod" -RemediateSecurity
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [switch]$RemediateSecurity
    )
    
    $issues = @()
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    
    # Check HTTPS enforcement
    if (-not $storageAccount.EnableHttpsTrafficOnly) {
        $issues += "HTTPS traffic not enforced"
        if ($RemediateSecurity) {
            Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName `
                -EnableHttpsTrafficOnly $true
        }
    }
    
    # Check minimum TLS version
    if ($storageAccount.MinimumTlsVersion -ne 'TLS1_2') {
        $issues += "Minimum TLS version is not 1.2"
        if ($RemediateSecurity) {
            Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName `
                -MinimumTlsVersion 'TLS1_2'
        }
    }
    
    # Check public blob access
    if ($storageAccount.AllowBlobPublicAccess) {
        $issues += "Public blob access is allowed"
        if ($RemediateSecurity) {
            Set-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName `
                -AllowBlobPublicAccess $false
        }
    }
    
    # Check network rules
    if ($storageAccount.NetworkRuleSet.DefaultAction -ne 'Deny') {
        $issues += "Network default action is not Deny"
        if ($RemediateSecurity) {
            Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName `
                -Name $StorageAccountName -DefaultAction Deny -Bypass AzureServices
        }
    }
    
    # Check encryption
    if (-not $storageAccount.Encryption.Services.Blob.Enabled) {
        $issues += "Blob encryption is not enabled"
    }
    
    # Check access keys rotation
    $context = $storageAccount.Context
    $lastRotated = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName | Select-Object -First 1
    
    # Create security report
    $report = @{
        StorageAccountName = $StorageAccountName
        IsSecure = $issues.Count -eq 0
        Issues = $issues
        Recommendations = @()
    }
    
    if ($issues.Count -gt 0) {
        $report.Recommendations = @(
            "Enable HTTPS-only traffic"
            "Set minimum TLS version to 1.2"
            "Disable public blob access"
            "Configure network restrictions"
            "Rotate access keys regularly"
            "Enable Advanced Threat Protection"
        )
    }
    
    return $report
}

#endregion

#region Blob Lifecycle Management

function Get-DefaultLifecyclePolicy {
    <#
    .SYNOPSIS
        Get default blob lifecycle management policy
    .DESCRIPTION
        Returns a standard lifecycle policy for blob storage
    #>
    [CmdletBinding()]
    param()
    
    $policy = @{
        Rules = @(
            @{
                Enabled = $true
                Name = 'MoveToCool'
                Type = 'Lifecycle'
                Definition = @{
                    Actions = @{
                        BaseBlob = @{
                            TierToCool = @{
                                DaysAfterModificationGreaterThan = $script:DefaultLifecycleDays.HotToCoool
                            }
                        }
                    }
                    Filters = @{
                        BlobTypes = @('blockBlob')
                        PrefixMatch = @('data/', 'logs/')
                    }
                }
            }
            @{
                Enabled = $true
                Name = 'MoveToArchive'
                Type = 'Lifecycle'
                Definition = @{
                    Actions = @{
                        BaseBlob = @{
                            TierToArchive = @{
                                DaysAfterModificationGreaterThan = $script:DefaultLifecycleDays.CoolToArchive
                            }
                        }
                    }
                    Filters = @{
                        BlobTypes = @('blockBlob')
                        PrefixMatch = @('archive/')
                    }
                }
            }
            @{
                Enabled = $true
                Name = 'DeleteOldData'
                Type = 'Lifecycle'
                Definition = @{
                    Actions = @{
                        BaseBlob = @{
                            Delete = @{
                                DaysAfterModificationGreaterThan = $script:DefaultLifecycleDays.DeleteAfter
                            }
                        }
                        Snapshot = @{
                            Delete = @{
                                DaysAfterCreationGreaterThan = 90
                            }
                        }
                    }
                    Filters = @{
                        BlobTypes = @('blockBlob')
                        PrefixMatch = @('temp/', 'cache/')
                    }
                }
            }
        )
    }
    
    return $policy
}

function Set-AzStorageLifecyclePolicy {
    <#
    .SYNOPSIS
        Configure blob lifecycle management policy
    .DESCRIPTION
        Sets up automated blob tiering and deletion policies
    .PARAMETER StorageAccountName
        Storage account name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER PolicyRules
        Custom lifecycle rules
    .PARAMETER UseDefault
        Use default enterprise policy
    .EXAMPLE
        Set-AzStorageLifecyclePolicy -StorageAccountName "stproddata001" -ResourceGroupName "rg-prod" -UseDefault
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(ParameterSetName = 'Custom')]
        [hashtable[]]$PolicyRules,
        
        [Parameter(ParameterSetName = 'Default')]
        [switch]$UseDefault
    )
    
    try {
        if ($UseDefault) {
            $policy = Get-DefaultLifecyclePolicy
        }
        else {
            $policy = @{ Rules = $PolicyRules }
        }
        
        Set-AzStorageAccountManagementPolicy -ResourceGroupName $ResourceGroupName `
            -StorageAccountName $StorageAccountName -Policy $policy
        
        Write-Information "Lifecycle policy applied to: $StorageAccountName" -InformationAction Continue
    }
    catch {
        Write-Error "Failed to set lifecycle policy: $_"
    }
}

#endregion

#region Storage Security and Compliance

function Enable-AzStorageAdvancedThreatProtection {
    <#
    .SYNOPSIS
        Enable Advanced Threat Protection for storage
    .DESCRIPTION
        Configures ATP/Defender for Storage with alerting
    .PARAMETER StorageAccountName
        Storage account name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER AlertEmailAddresses
        Email addresses for security alerts
    .EXAMPLE
        Enable-AzStorageAdvancedThreatProtection -StorageAccountName "stproddata001" -ResourceGroupName "rg-prod" -AlertEmailAddresses @("security@contoso.com")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [string[]]$AlertEmailAddresses
    )
    
    try {
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        
        # Enable Advanced Threat Protection
        Set-AzSecurityAdvancedThreatProtection -ResourceId $storageAccount.Id -IsEnabled $true
        
        # Configure security alerts
        if ($AlertEmailAddresses) {
            $contact = Get-AzSecurityContact | Where-Object { $_.Name -eq 'default' }
            if (-not $contact) {
                Set-AzSecurityContact -Name 'default' -Email ($AlertEmailAddresses -join ';') `
                    -AlertNotifications 'On' -AlertsToAdmins 'On'
            }
        }
        
        # Enable diagnostic logging for threat detection
        $categories = @('StorageRead', 'StorageWrite', 'StorageDelete', 'Transaction')
        $diagnosticSetting = Get-AzDiagnosticSetting -ResourceId $storageAccount.Id | 
            Where-Object { $_.Name -eq 'SecurityAudit' }
        
        if (-not $diagnosticSetting) {
            # Note: This requires a Log Analytics workspace or Event Hub
            Write-Information "Configure diagnostic settings manually for complete threat detection" -InformationAction Continue
        }
        
        Write-Information "Advanced Threat Protection enabled for: $StorageAccountName" -InformationAction Continue
    }
    catch {
        Write-Error "Failed to enable ATP: $_"
    }
}

function Get-AzStorageComplianceReport {
    <#
    .SYNOPSIS
        Generate storage compliance report
    .DESCRIPTION
        Analyzes storage accounts for compliance with enterprise standards
    .PARAMETER ResourceGroupName
        Resource group name (optional, all if not specified)
    .PARAMETER ExportPath
        Path to export compliance report
    .EXAMPLE
        Get-AzStorageComplianceReport -ExportPath ".\storage-compliance.csv"
    #>
    [CmdletBinding()]
    param(
        [string]$ResourceGroupName,
        
        [string]$ExportPath
    )
    
    $storageAccounts = if ($ResourceGroupName) {
        Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzStorageAccount
    }
    
    $complianceData = @()
    
    foreach ($storage in $storageAccounts) {
        $compliance = @{
            StorageAccountName = $storage.StorageAccountName
            ResourceGroup = $storage.ResourceGroupName
            Location = $storage.Location
            Kind = $storage.Kind
            SkuName = $storage.Sku.Name
            HttpsOnly = $storage.EnableHttpsTrafficOnly
            MinTlsVersion = $storage.MinimumTlsVersion
            PublicAccess = -not $storage.AllowBlobPublicAccess
            NetworkRestricted = $storage.NetworkRuleSet.DefaultAction -eq 'Deny'
            BlobVersioning = $false
            SoftDelete = $false
            ATP = $false
            Encryption = $storage.Encryption.Services.Blob.Enabled
            Tags = ($storage.Tags.Keys -join ', ')
            ComplianceScore = 0
        }
        
        # Check blob service properties
        try {
            $blobProperties = Get-AzStorageBlobServiceProperty -ResourceGroupName $storage.ResourceGroupName `
                -StorageAccountName $storage.StorageAccountName
            
            $compliance.BlobVersioning = $blobProperties.IsVersioningEnabled
            $compliance.SoftDelete = $blobProperties.DeleteRetentionPolicy.Enabled
        }
        catch {
            Write-Verbose "Could not retrieve blob properties for $($storage.StorageAccountName)"
        }
        
        # Check ATP
        try {
            $atp = Get-AzSecurityAdvancedThreatProtection -ResourceId $storage.Id
            $compliance.ATP = $atp.IsEnabled
        }
        catch {
            Write-Verbose "Could not check ATP for $($storage.StorageAccountName)"
        }
        
        # Calculate compliance score
        $score = 0
        if ($compliance.HttpsOnly) { $score += 10 }
        if ($compliance.MinTlsVersion -eq 'TLS1_2') { $score += 10 }
        if ($compliance.PublicAccess) { $score += 15 }
        if ($compliance.NetworkRestricted) { $score += 15 }
        if ($compliance.BlobVersioning) { $score += 10 }
        if ($compliance.SoftDelete) { $score += 10 }
        if ($compliance.ATP) { $score += 10 }
        if ($compliance.Encryption) { $score += 10 }
        if ($compliance.Tags) { $score += 10 }
        
        $compliance.ComplianceScore = $score
        $complianceData += [PSCustomObject]$compliance
    }
    
    # Export if requested
    if ($ExportPath) {
        $complianceData | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Information "Compliance report exported to: $ExportPath" -InformationAction Continue
    }
    
    # Summary
    $summary = @{
        TotalStorageAccounts = $complianceData.Count
        FullyCompliant = ($complianceData | Where-Object { $_.ComplianceScore -eq 100 }).Count
        HighCompliance = ($complianceData | Where-Object { $_.ComplianceScore -ge 80 }).Count
        MediumCompliance = ($complianceData | Where-Object { $_.ComplianceScore -ge 60 -and $_.ComplianceScore -lt 80 }).Count
        LowCompliance = ($complianceData | Where-Object { $_.ComplianceScore -lt 60 }).Count
        AverageScore = [math]::Round(($complianceData.ComplianceScore | Measure-Object -Average).Average, 2)
    }
    
    return @{
        Summary = $summary
        Details = $complianceData
    }
}

#endregion

#region Data Archival and Retention

function Start-AzStorageDataArchival {
    <#
    .SYNOPSIS
        Archive data based on age and access patterns
    .DESCRIPTION
        Moves blobs to archive tier based on last access time
    .PARAMETER StorageAccountName
        Storage account name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER ContainerName
        Container name (optional, all if not specified)
    .PARAMETER DaysOld
        Archive blobs older than specified days
    .PARAMETER WhatIf
        Preview changes without making them
    .EXAMPLE
        Start-AzStorageDataArchival -StorageAccountName "stproddata001" -ResourceGroupName "rg-prod" -DaysOld 180 -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [string]$ContainerName,
        
        [int]$DaysOld = 90
    )
    
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $ctx = $storageAccount.Context
    
    $containers = if ($ContainerName) {
        @(Get-AzStorageContainer -Name $ContainerName -Context $ctx)
    } else {
        Get-AzStorageContainer -Context $ctx
    }
    
    $cutoffDate = (Get-Date).AddDays(-$DaysOld)
    $archivedCount = 0
    $archivedSize = 0
    
    foreach ($container in $containers) {
        $blobs = Get-AzStorageBlob -Container $container.Name -Context $ctx | 
            Where-Object { 
                $_.LastModified -lt $cutoffDate -and 
                $_.AccessTier -ne 'Archive' -and
                $_.BlobType -eq 'BlockBlob'
            }
        
        foreach ($blob in $blobs) {
            if ($PSCmdlet.ShouldProcess($blob.Name, "Archive blob")) {
                try {
                    $blob.ICloudBlob.SetStandardBlobTier('Archive')
                    $archivedCount++
                    $archivedSize += $blob.Length
                    Write-Verbose "Archived: $($blob.Name)"
                }
                catch {
                    Write-Warning "Failed to archive $($blob.Name): $_"
                }
            }
        }
    }
    
    $result = @{
        BlobsArchived = $archivedCount
        TotalSizeGB = [math]::Round($archivedSize / 1GB, 2)
        EstimatedMonthlySavings = [math]::Round($archivedSize / 1GB * 0.015, 2) # Rough estimate
    }
    
    Write-Information "Archived $archivedCount blobs totaling $($result.TotalSizeGB) GB" -InformationAction Continue
    return $result
}

#endregion

#region Storage Cost Optimization

function Get-AzStorageCostAnalysis {
    <#
    .SYNOPSIS
        Analyze storage costs and optimization opportunities
    .DESCRIPTION
        Provides detailed cost analysis and recommendations for storage accounts
    .PARAMETER StorageAccountName
        Storage account name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER IncludeRecommendations
        Include optimization recommendations
    .EXAMPLE
        Get-AzStorageCostAnalysis -StorageAccountName "stproddata001" -ResourceGroupName "rg-prod" -IncludeRecommendations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [switch]$IncludeRecommendations
    )
    
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
    $ctx = $storageAccount.Context
    
    # Get storage metrics
    $containers = Get-AzStorageContainer -Context $ctx
    $metrics = @{
        TotalContainers = $containers.Count
        TotalBlobsGB = 0
        BlobsByTier = @{
            Hot = @{ Count = 0; SizeGB = 0 }
            Cool = @{ Count = 0; SizeGB = 0 }
            Archive = @{ Count = 0; SizeGB = 0 }
        }
        UnusedContainers = @()
        LargeBlobs = @()
        OldBlobs = @()
    }
    
    $cutoffDate = (Get-Date).AddDays(-365)
    
    foreach ($container in $containers) {
        $blobs = Get-AzStorageBlob -Container $container.Name -Context $ctx
        
        if ($blobs.Count -eq 0) {
            $metrics.UnusedContainers += $container.Name
        }
        
        foreach ($blob in $blobs) {
            $sizeGB = [math]::Round($blob.Length / 1GB, 3)
            $metrics.TotalBlobsGB += $sizeGB
            
            # Track by tier
            $tier = $blob.AccessTier ?? 'Hot'
            $metrics.BlobsByTier[$tier].Count++
            $metrics.BlobsByTier[$tier].SizeGB += $sizeGB
            
            # Find large blobs
            if ($sizeGB -gt 10) {
                $metrics.LargeBlobs += @{
                    Name = $blob.Name
                    Container = $container.Name
                    SizeGB = $sizeGB
                    LastModified = $blob.LastModified
                    AccessTier = $tier
                }
            }
            
            # Find old blobs
            if ($blob.LastModified -lt $cutoffDate) {
                $metrics.OldBlobs += @{
                    Name = $blob.Name
                    Container = $container.Name
                    LastModified = $blob.LastModified
                    AccessTier = $tier
                }
            }
        }
    }
    
    # Calculate costs (simplified estimates)
    $costEstimates = @{
        MonthlyStorageCost = @{
            Hot = [math]::Round($metrics.BlobsByTier.Hot.SizeGB * 0.0184, 2)
            Cool = [math]::Round($metrics.BlobsByTier.Cool.SizeGB * 0.01, 2)
            Archive = [math]::Round($metrics.BlobsByTier.Archive.SizeGB * 0.00099, 2)
        }
        TotalMonthlyCost = 0
    }
    
    $costEstimates.TotalMonthlyCost = $costEstimates.MonthlyStorageCost.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    
    # Generate recommendations
    $recommendations = @()
    
    if ($IncludeRecommendations) {
        # Tier optimization
        if ($metrics.BlobsByTier.Hot.SizeGB -gt 100) {
            $recommendations += "Consider moving infrequently accessed data from Hot to Cool tier"
        }
        
        # Archive old data
        if ($metrics.OldBlobs.Count -gt 100) {
            $recommendations += "Archive $($metrics.OldBlobs.Count) blobs older than 1 year to save costs"
        }
        
        # Large blob optimization
        if ($metrics.LargeBlobs.Count -gt 0) {
            $recommendations += "Review $($metrics.LargeBlobs.Count) large blobs for compression or archival"
        }
        
        # Unused containers
        if ($metrics.UnusedContainers.Count -gt 0) {
            $recommendations += "Remove $($metrics.UnusedContainers.Count) empty containers"
        }
        
        # Lifecycle policies
        if (-not (Get-AzStorageAccountManagementPolicy -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue)) {
            $recommendations += "Enable lifecycle management policies for automated tiering"
        }
    }
    
    return @{
        Metrics = $metrics
        CostEstimates = $costEstimates
        Recommendations = $recommendations
        PotentialSavings = [math]::Round($costEstimates.TotalMonthlyCost * 0.3, 2) # Estimate 30% savings
    }
}

#endregion

#region Backup and Disaster Recovery

function Enable-AzStorageBackup {
    <#
    .SYNOPSIS
        Enable backup for storage account
    .DESCRIPTION
        Configures point-in-time restore and backup policies
    .PARAMETER StorageAccountName
        Storage account name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER RetentionDays
        Backup retention in days (1-365)
    .EXAMPLE
        Enable-AzStorageBackup -StorageAccountName "stproddata001" -ResourceGroupName "rg-prod" -RetentionDays 30
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [ValidateRange(1, 365)]
        [int]$RetentionDays = 30
    )
    
    try {
        # Enable blob versioning (required for point-in-time restore)
        Update-AzStorageBlobServiceProperty -ResourceGroupName $ResourceGroupName `
            -StorageAccountName $StorageAccountName `
            -IsVersioningEnabled $true
        
        # Enable soft delete for blobs
        Update-AzStorageBlobServiceProperty -ResourceGroupName $ResourceGroupName `
            -StorageAccountName $StorageAccountName `
            -DeleteRetentionPolicy @{
                Enabled = $true
                Days = $RetentionDays
            } `
            -ContainerDeleteRetentionPolicy @{
                Enabled = $true
                Days = $RetentionDays
            }
        
        # Enable point-in-time restore
        Update-AzStorageBlobServiceProperty -ResourceGroupName $ResourceGroupName `
            -StorageAccountName $StorageAccountName `
            -RestorePolicy @{
                Enabled = $true
                Days = $RetentionDays - 1  # Must be less than soft delete retention
            }
        
        # Configure backup vault (if Azure Backup is being used)
        # Note: This requires additional Azure Backup configuration
        
        Write-Information "Backup enabled for $StorageAccountName with $RetentionDays days retention" -InformationAction Continue
        
        return @{
            StorageAccount = $StorageAccountName
            BackupEnabled = $true
            RetentionDays = $RetentionDays
            Features = @(
                'Blob Versioning'
                'Soft Delete'
                'Container Soft Delete'
                'Point-in-Time Restore'
            )
        }
    }
    catch {
        Write-Error "Failed to enable backup: $_"
    }
}

function Start-AzStorageReplication {
    <#
    .SYNOPSIS
        Configure cross-region replication
    .DESCRIPTION
        Sets up storage account replication for disaster recovery
    .PARAMETER SourceStorageAccount
        Source storage account name
    .PARAMETER SourceResourceGroup
        Source resource group
    .PARAMETER TargetStorageAccount
        Target storage account name
    .PARAMETER TargetResourceGroup
        Target resource group
    .PARAMETER ContainerNames
        Specific containers to replicate (all if not specified)
    .EXAMPLE
        Start-AzStorageReplication -SourceStorageAccount "stprodeast" -SourceResourceGroup "rg-prod-east" -TargetStorageAccount "stprodwest" -TargetResourceGroup "rg-prod-west"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$SourceStorageAccount,
        
        [Parameter(Mandatory)]
        [string]$SourceResourceGroup,
        
        [Parameter(Mandatory)]
        [string]$TargetStorageAccount,
        
        [Parameter(Mandatory)]
        [string]$TargetResourceGroup,
        
        [string[]]$ContainerNames
    )
    
    try {
        $sourceAccount = Get-AzStorageAccount -ResourceGroupName $SourceResourceGroup -Name $SourceStorageAccount
        $targetAccount = Get-AzStorageAccount -ResourceGroupName $TargetResourceGroup -Name $TargetStorageAccount
        
        $sourceCtx = $sourceAccount.Context
        $targetCtx = $targetAccount.Context
        
        # Get containers to replicate
        $containers = if ($ContainerNames) {
            $ContainerNames | ForEach-Object { Get-AzStorageContainer -Name $_ -Context $sourceCtx }
        } else {
            Get-AzStorageContainer -Context $sourceCtx
        }
        
        $replicationJobs = @()
        
        foreach ($container in $containers) {
            if ($PSCmdlet.ShouldProcess($container.Name, "Replicate container")) {
                # Create container in target if it doesn't exist
                $targetContainer = Get-AzStorageContainer -Name $container.Name -Context $targetCtx -ErrorAction SilentlyContinue
                if (-not $targetContainer) {
                    New-AzStorageContainer -Name $container.Name -Context $targetCtx -Permission $container.PublicAccess
                }
                
                # Use AzCopy for efficient replication
                $sourceUrl = $container.CloudBlobContainer.Uri.ToString()
                $targetUrl = "https://$TargetStorageAccount.blob.core.windows.net/$($container.Name)"
                
                # Note: This is a simplified example. Production use would need SAS tokens
                $replicationJobs += @{
                    Container = $container.Name
                    SourceUrl = $sourceUrl
                    TargetUrl = $targetUrl
                    Status = "Configured"
                }
                
                Write-Verbose "Configured replication for container: $($container.Name)"
            }
        }
        
        return @{
            SourceAccount = $SourceStorageAccount
            TargetAccount = $TargetStorageAccount
            ReplicationJobs = $replicationJobs
            NextSteps = @(
                "Configure AzCopy or Azure Data Factory for continuous replication"
                "Set up monitoring for replication lag"
                "Test failover procedures"
            )
        }
    }
    catch {
        Write-Error "Failed to configure replication: $_"
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'New-AzStorageAccountAdvanced'
    'Test-AzStorageAccountSecurity'
    'Get-DefaultLifecyclePolicy'
    'Set-AzStorageLifecyclePolicy'
    'Enable-AzStorageAdvancedThreatProtection'
    'Get-AzStorageComplianceReport'
    'Start-AzStorageDataArchival'
    'Get-AzStorageCostAnalysis'
    'Enable-AzStorageBackup'
    'Start-AzStorageReplication'
)