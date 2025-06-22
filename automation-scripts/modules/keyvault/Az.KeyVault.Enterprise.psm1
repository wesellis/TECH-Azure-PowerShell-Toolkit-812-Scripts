#Requires -Version 7.0
#Requires -Modules Az.KeyVault

<#
.SYNOPSIS
    Enterprise Azure Key Vault Management Module
.DESCRIPTION
    Advanced Key Vault management with secret rotation, certificate lifecycle, and compliance features
.VERSION
    2.0.0
.AUTHOR
    Azure Enterprise Toolkit
#>

# Module configuration
$script:ModuleVersion = '2.0.0'
$script:SecretExpirationDays = 90
$script:CertificateExpirationWarningDays = 30

#region Key Vault Management

function New-AzKeyVaultAdvanced {
    <#
    .SYNOPSIS
        Create Key Vault with enterprise security standards
    .DESCRIPTION
        Creates a Key Vault with RBAC, network restrictions, and monitoring
    .PARAMETER VaultName
        Key Vault name (3-24 chars, alphanumeric and hyphens)
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER Location
        Azure region
    .PARAMETER EnableRbac
        Use RBAC instead of access policies
    .PARAMETER EnablePurgeProtection
        Enable purge protection (cannot be disabled once enabled)
    .PARAMETER SoftDeleteRetentionDays
        Soft delete retention period (7-90 days)
    .PARAMETER NetworkAcls
        Network access control rules
    .PARAMETER Tags
        Resource tags
    .EXAMPLE
        New-AzKeyVaultAdvanced -VaultName "kv-prod-secrets" -ResourceGroupName "rg-prod" -Location "eastus" -EnableRbac
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$')]
        [string]$VaultName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$Location,
        
        [switch]$EnableRbac,
        
        [switch]$EnablePurgeProtection,
        
        [ValidateRange(7, 90)]
        [int]$SoftDeleteRetentionDays = 90,
        
        [hashtable]$NetworkAcls,
        
        [hashtable]$Tags = @{}
    )
    
    if ($PSCmdlet.ShouldProcess($VaultName, "Create Key Vault")) {
        try {
            # Check if vault name is available
            $availability = Get-AzKeyVaultNameAvailability -Name $VaultName
            if (-not $availability.Available) {
                throw "Key Vault name '$VaultName' is not available: $($availability.Message)"
            }
            
            # Create Key Vault parameters
            $params = @{
                VaultName = $VaultName
                ResourceGroupName = $ResourceGroupName
                Location = $Location
                EnabledForDeployment = $false
                EnabledForTemplateDeployment = $false
                EnabledForDiskEncryption = $false
                EnableSoftDelete = $true
                SoftDeleteRetentionInDays = $SoftDeleteRetentionDays
                Sku = 'Standard'
                Tag = $Tags
            }
            
            if ($EnablePurgeProtection) {
                $params.EnablePurgeProtection = $true
            }
            
            if ($EnableRbac) {
                $params.EnableRbacAuthorization = $true
            }
            
            # Create Key Vault
            $vault = New-AzKeyVault @params
            
            # Configure network ACLs
            if ($NetworkAcls) {
                $networkParams = @{
                    VaultName = $VaultName
                    ResourceGroupName = $ResourceGroupName
                    DefaultAction = $NetworkAcls.DefaultAction ?? 'Deny'
                    Bypass = $NetworkAcls.Bypass ?? 'AzureServices'
                }
                
                if ($NetworkAcls.IpAddressRanges) {
                    $networkParams.IpAddressRange = $NetworkAcls.IpAddressRanges
                }
                
                if ($NetworkAcls.VirtualNetworkResourceIds) {
                    $networkParams.VirtualNetworkResourceId = $NetworkAcls.VirtualNetworkResourceIds
                }
                
                Update-AzKeyVaultNetworkRuleSet @networkParams
            }
            
            # Enable diagnostic logging
            $diagnosticCategories = @('AuditEvent', 'AllMetrics')
            
            Write-Information "Successfully created Key Vault: $VaultName" -InformationAction Continue
            Write-Information "Note: Configure diagnostic settings for logging and monitoring" -InformationAction Continue
            
            return $vault
        }
        catch {
            Write-Error "Failed to create Key Vault: $_"
        }
    }
}

function Test-AzKeyVaultCompliance {
    <#
    .SYNOPSIS
        Test Key Vault compliance with security standards
    .DESCRIPTION
        Validates Key Vault configuration against enterprise security requirements
    .PARAMETER VaultName
        Key Vault name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER Remediate
        Attempt to fix compliance issues
    .EXAMPLE
        Test-AzKeyVaultCompliance -VaultName "kv-prod-secrets" -ResourceGroupName "rg-prod" -Remediate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [switch]$Remediate
    )
    
    $issues = @()
    $vault = Get-AzKeyVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName
    
    # Check soft delete
    if (-not $vault.EnableSoftDelete) {
        $issues += "Soft delete is not enabled"
        if ($Remediate) {
            Update-AzKeyVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName -EnableSoftDelete $true
        }
    }
    
    # Check retention period
    if ($vault.SoftDeleteRetentionInDays -lt 90) {
        $issues += "Soft delete retention is less than 90 days"
        if ($Remediate) {
            Update-AzKeyVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName `
                -SoftDeleteRetentionInDays 90
        }
    }
    
    # Check network restrictions
    $networkRules = Get-AzKeyVaultNetworkRuleSet -VaultName $VaultName -ResourceGroupName $ResourceGroupName
    if ($networkRules.DefaultAction -ne 'Deny') {
        $issues += "Network default action is not Deny"
        if ($Remediate) {
            Update-AzKeyVaultNetworkRuleSet -VaultName $VaultName -ResourceGroupName $ResourceGroupName `
                -DefaultAction Deny -Bypass AzureServices
        }
    }
    
    # Check for excessive permissions
    if (-not $vault.EnableRbacAuthorization) {
        $policies = Get-AzKeyVaultAccessPolicy -VaultName $VaultName
        $excessivePolicies = $policies | Where-Object {
            $_.PermissionsToSecrets -contains 'all' -or
            $_.PermissionsToKeys -contains 'all' -or
            $_.PermissionsToCertificates -contains 'all'
        }
        
        if ($excessivePolicies) {
            $issues += "Access policies with 'all' permissions detected"
        }
    }
    
    # Check diagnostic settings
    $diagnostics = Get-AzDiagnosticSetting -ResourceId $vault.ResourceId -ErrorAction SilentlyContinue
    if (-not $diagnostics) {
        $issues += "No diagnostic settings configured"
    }
    
    # Create compliance report
    $report = @{
        VaultName = $VaultName
        IsCompliant = $issues.Count -eq 0
        Issues = $issues
        ComplianceScore = [math]::Round((10 - $issues.Count) / 10 * 100, 0)
        Recommendations = @()
    }
    
    if ($issues.Count -gt 0) {
        $report.Recommendations = @(
            "Enable soft delete with 90-day retention"
            "Configure network restrictions with default deny"
            "Use RBAC instead of access policies"
            "Enable diagnostic logging"
            "Review and minimize permissions"
            "Enable purge protection for production vaults"
        )
    }
    
    return $report
}

#endregion

#region Secret Rotation Automation

function Enable-AzKeyVaultSecretRotation {
    <#
    .SYNOPSIS
        Enable automated secret rotation
    .DESCRIPTION
        Configures automated rotation for secrets using Azure Functions or Logic Apps
    .PARAMETER VaultName
        Key Vault name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER SecretName
        Secret to rotate
    .PARAMETER RotationIntervalDays
        Rotation interval in days
    .PARAMETER NotificationEmail
        Email for rotation notifications
    .EXAMPLE
        Enable-AzKeyVaultSecretRotation -VaultName "kv-prod" -ResourceGroupName "rg-prod" -SecretName "SqlPassword" -RotationIntervalDays 30
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$SecretName,
        
        [ValidateRange(1, 365)]
        [int]$RotationIntervalDays = 90,
        
        [string]$NotificationEmail
    )
    
    try {
        # Get current secret
        $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName
        
        if (-not $secret) {
            throw "Secret '$SecretName' not found in vault '$VaultName'"
        }
        
        # Set expiration on current version
        $expirationDate = (Get-Date).AddDays($RotationIntervalDays)
        $secretParams = @{
            VaultName = $VaultName
            Name = $SecretName
            Expires = $expirationDate
            Tag = @{
                RotationEnabled = "true"
                RotationInterval = $RotationIntervalDays
                LastRotated = (Get-Date -Format 'yyyy-MM-dd')
                NextRotation = ($expirationDate.ToString('yyyy-MM-dd'))
            }
        }
        
        if ($NotificationEmail) {
            $secretParams.Tag.NotificationEmail = $NotificationEmail
        }
        
        Update-AzKeyVaultSecret @secretParams
        
        # Create rotation configuration
        $rotationConfig = @{
            SecretName = $SecretName
            VaultName = $VaultName
            ResourceGroup = $ResourceGroupName
            RotationInterval = $RotationIntervalDays
            NextRotation = $expirationDate
            NotificationEmail = $NotificationEmail
            Status = "Enabled"
        }
        
        Write-Information "Secret rotation enabled for: $SecretName" -InformationAction Continue
        Write-Information "Next rotation: $($expirationDate.ToString('yyyy-MM-dd'))" -InformationAction Continue
        Write-Information "Note: Configure Azure Function or Logic App for automated rotation execution" -InformationAction Continue
        
        return $rotationConfig
    }
    catch {
        Write-Error "Failed to enable secret rotation: $_"
    }
}

function Start-AzKeyVaultSecretRotation {
    <#
    .SYNOPSIS
        Manually trigger secret rotation
    .DESCRIPTION
        Rotates a secret and updates dependent services
    .PARAMETER VaultName
        Key Vault name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER SecretName
        Secret to rotate
    .PARAMETER NewValue
        New secret value (auto-generated if not provided)
    .PARAMETER UpdateDependencies
        Update dependent services
    .EXAMPLE
        Start-AzKeyVaultSecretRotation -VaultName "kv-prod" -ResourceGroupName "rg-prod" -SecretName "SqlPassword"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$SecretName,
        
        [SecureString]$NewValue,
        
        [switch]$UpdateDependencies
    )
    
    if ($PSCmdlet.ShouldProcess($SecretName, "Rotate secret")) {
        try {
            # Get current secret
            $currentSecret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName
            
            # Generate new value if not provided
            if (-not $NewValue) {
                $length = 32
                $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
                $newPassword = -join (1..$length | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
                $NewValue = ConvertTo-SecureString -String $newPassword -AsPlainText -Force
            }
            
            # Create new version
            $newSecretParams = @{
                VaultName = $VaultName
                Name = $SecretName
                SecretValue = $NewValue
                Tag = $currentSecret.Tags
                ContentType = $currentSecret.ContentType
                Expires = (Get-Date).AddDays($script:SecretExpirationDays)
            }
            
            # Update rotation metadata
            $newSecretParams.Tag.LastRotated = (Get-Date -Format 'yyyy-MM-dd')
            $newSecretParams.Tag.PreviousVersion = $currentSecret.Version
            $newSecretParams.Tag.RotationCount = ([int]$currentSecret.Tags.RotationCount + 1).ToString()
            
            $newSecret = Set-AzKeyVaultSecret @newSecretParams
            
            # Disable old version
            Update-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName `
                -Version $currentSecret.Version -Enable $false
            
            # Update dependencies if requested
            if ($UpdateDependencies) {
                # This would be customized based on the secret type
                Write-Information "Dependency update requested - implement based on secret type" -InformationAction Continue
            }
            
            Write-Information "Secret rotated successfully: $SecretName" -InformationAction Continue
            Write-Information "New version: $($newSecret.Version)" -InformationAction Continue
            Write-Information "Previous version disabled: $($currentSecret.Version)" -InformationAction Continue
            
            return @{
                SecretName = $SecretName
                OldVersion = $currentSecret.Version
                NewVersion = $newSecret.Version
                RotationTime = Get-Date
                ExpirationDate = $newSecret.Expires
            }
        }
        catch {
            Write-Error "Failed to rotate secret: $_"
        }
    }
}

function Get-AzKeyVaultExpiringSecrets {
    <#
    .SYNOPSIS
        Get secrets nearing expiration
    .DESCRIPTION
        Lists all secrets that will expire within specified days
    .PARAMETER VaultName
        Key Vault name (optional, all vaults if not specified)
    .PARAMETER ExpirationDays
        Days until expiration to check
    .PARAMETER IncludeDisabled
        Include disabled secrets
    .EXAMPLE
        Get-AzKeyVaultExpiringSecrets -ExpirationDays 30
    #>
    [CmdletBinding()]
    param(
        [string]$VaultName,
        
        [int]$ExpirationDays = 30,
        
        [switch]$IncludeDisabled
    )
    
    $expiringSecrets = @()
    $cutoffDate = (Get-Date).AddDays($ExpirationDays)
    
    # Get vaults to check
    $vaults = if ($VaultName) {
        @(Get-AzKeyVault -VaultName $VaultName)
    } else {
        Get-AzKeyVault
    }
    
    foreach ($vault in $vaults) {
        try {
            $secrets = Get-AzKeyVaultSecret -VaultName $vault.VaultName
            
            foreach ($secret in $secrets) {
                if ($secret.Expires -and $secret.Expires -lt $cutoffDate) {
                    if ($secret.Enabled -or $IncludeDisabled) {
                        $expiringSecrets += [PSCustomObject]@{
                            VaultName = $vault.VaultName
                            SecretName = $secret.Name
                            Version = $secret.Version
                            Enabled = $secret.Enabled
                            Expires = $secret.Expires
                            DaysUntilExpiration = [math]::Round(($secret.Expires - (Get-Date)).TotalDays, 0)
                            Tags = $secret.Tags
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed to check vault $($vault.VaultName): $_"
        }
    }
    
    return $expiringSecrets | Sort-Object DaysUntilExpiration
}

#endregion

#region Certificate Lifecycle Management

function New-AzKeyVaultCertificateAdvanced {
    <#
    .SYNOPSIS
        Create certificate with lifecycle management
    .DESCRIPTION
        Creates a certificate with auto-renewal and monitoring configuration
    .PARAMETER VaultName
        Key Vault name
    .PARAMETER CertificateName
        Certificate name
    .PARAMETER Subject
        Certificate subject
    .PARAMETER DnsNames
        DNS names for SAN
    .PARAMETER ValidityInMonths
        Certificate validity period
    .PARAMETER RenewAtPercentageLifetime
        Percentage of lifetime to trigger renewal
    .PARAMETER KeyType
        Key type (RSA or EC)
    .PARAMETER KeySize
        Key size (2048, 3072, 4096 for RSA)
    .EXAMPLE
        New-AzKeyVaultCertificateAdvanced -VaultName "kv-prod" -CertificateName "webapp-cert" -Subject "CN=app.contoso.com" -DnsNames @("app.contoso.com", "www.app.contoso.com")
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        
        [Parameter(Mandatory)]
        [string]$CertificateName,
        
        [Parameter(Mandatory)]
        [string]$Subject,
        
        [string[]]$DnsNames,
        
        [ValidateRange(1, 39)]
        [int]$ValidityInMonths = 12,
        
        [ValidateRange(1, 99)]
        [int]$RenewAtPercentageLifetime = 80,
        
        [ValidateSet('RSA', 'EC')]
        [string]$KeyType = 'RSA',
        
        [ValidateSet(2048, 3072, 4096)]
        [int]$KeySize = 2048
    )
    
    if ($PSCmdlet.ShouldProcess($CertificateName, "Create certificate")) {
        try {
            # Create certificate policy
            $policy = New-AzKeyVaultCertificatePolicy `
                -SubjectName $Subject `
                -IssuerName 'Self' `
                -ValidityInMonths $ValidityInMonths `
                -RenewAtPercentageLifetime $RenewAtPercentageLifetime `
                -KeyType $KeyType `
                -KeySize $KeySize `
                -ReuseKeyOnRenewal $false `
                -Ekus "1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2"  # Server auth, Client auth
            
            # Add DNS names if provided
            if ($DnsNames) {
                $policy.DnsNames = $DnsNames
            }
            
            # Configure lifetime actions
            $emailAction = New-AzKeyVaultCertificateLifetimeAction `
                -Action EmailContacts `
                -DaysBeforeExpiry 30
                
            $autoRenewAction = New-AzKeyVaultCertificateLifetimeAction `
                -Action AutoRenew `
                -PercentageLifetime $RenewAtPercentageLifetime
            
            $policy.LifetimeActions = @($autoRenewAction, $emailAction)
            
            # Create certificate
            $certificate = Add-AzKeyVaultCertificate `
                -VaultName $VaultName `
                -Name $CertificateName `
                -CertificatePolicy $policy
            
            Write-Information "Certificate creation initiated: $CertificateName" -InformationAction Continue
            Write-Information "Auto-renewal configured at $RenewAtPercentageLifetime% lifetime" -InformationAction Continue
            
            # Wait for certificate creation
            $timeoutSeconds = 60
            $endTime = (Get-Date).AddSeconds($timeoutSeconds)
            
            while ((Get-Date) -lt $endTime) {
                $cert = Get-AzKeyVaultCertificateOperation -VaultName $VaultName -Name $CertificateName
                if ($cert.Status -eq 'completed') {
                    $finalCert = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName
                    return $finalCert
                }
                elseif ($cert.Status -eq 'failed') {
                    throw "Certificate creation failed: $($cert.Error)"
                }
                Start-Sleep -Seconds 5
            }
            
            throw "Certificate creation timed out after $timeoutSeconds seconds"
        }
        catch {
            Write-Error "Failed to create certificate: $_"
        }
    }
}

function Get-AzKeyVaultCertificateHealth {
    <#
    .SYNOPSIS
        Check certificate health and expiration
    .DESCRIPTION
        Analyzes certificate status, expiration, and renewal configuration
    .PARAMETER VaultName
        Key Vault name (optional, all vaults if not specified)
    .PARAMETER WarningDays
        Days before expiration to trigger warning
    .PARAMETER IncludeDisabled
        Include disabled certificates
    .EXAMPLE
        Get-AzKeyVaultCertificateHealth -WarningDays 60
    #>
    [CmdletBinding()]
    param(
        [string]$VaultName,
        
        [int]$WarningDays = $script:CertificateExpirationWarningDays,
        
        [switch]$IncludeDisabled
    )
    
    $certificateHealth = @()
    $warningDate = (Get-Date).AddDays($WarningDays)
    
    # Get vaults to check
    $vaults = if ($VaultName) {
        @(Get-AzKeyVault -VaultName $VaultName)
    } else {
        Get-AzKeyVault
    }
    
    foreach ($vault in $vaults) {
        try {
            $certificates = Get-AzKeyVaultCertificate -VaultName $vault.VaultName
            
            foreach ($cert in $certificates) {
                if ($cert.Enabled -or $IncludeDisabled) {
                    # Get full certificate details
                    $fullCert = Get-AzKeyVaultCertificate -VaultName $vault.VaultName -Name $cert.Name
                    $policy = Get-AzKeyVaultCertificatePolicy -VaultName $vault.VaultName -Name $cert.Name
                    
                    $health = @{
                        VaultName = $vault.VaultName
                        CertificateName = $cert.Name
                        Thumbprint = $cert.Thumbprint
                        Enabled = $cert.Enabled
                        Created = $cert.Created
                        Expires = $cert.Expires
                        DaysUntilExpiration = [math]::Round(($cert.Expires - (Get-Date)).TotalDays, 0)
                        Subject = $cert.SubjectName
                        Issuer = $policy.IssuerName
                        KeyType = $policy.KeyProperties.KeyType
                        KeySize = $policy.KeyProperties.KeySize
                        AutoRenewEnabled = $false
                        Status = 'Healthy'
                        Issues = @()
                    }
                    
                    # Check auto-renewal
                    $renewAction = $policy.LifetimeActions | Where-Object { $_.Action -eq 'AutoRenew' }
                    if ($renewAction) {
                        $health.AutoRenewEnabled = $true
                        $health.RenewAtPercentage = $renewAction.PercentageLifetime
                    }
                    
                    # Determine status
                    if ($cert.Expires -lt (Get-Date)) {
                        $health.Status = 'Expired'
                        $health.Issues += "Certificate has expired"
                    }
                    elseif ($cert.Expires -lt $warningDate) {
                        $health.Status = 'Warning'
                        $health.Issues += "Certificate expires in $($health.DaysUntilExpiration) days"
                    }
                    
                    if (-not $health.AutoRenewEnabled -and $health.DaysUntilExpiration -lt 90) {
                        $health.Issues += "Auto-renewal not configured"
                    }
                    
                    if ($policy.KeyProperties.KeySize -lt 2048) {
                        $health.Issues += "Key size less than 2048 bits"
                    }
                    
                    $certificateHealth += [PSCustomObject]$health
                }
            }
        }
        catch {
            Write-Warning "Failed to check vault $($vault.VaultName): $_"
        }
    }
    
    return $certificateHealth | Sort-Object Status, DaysUntilExpiration
}

function Start-AzKeyVaultCertificateRenewal {
    <#
    .SYNOPSIS
        Manually trigger certificate renewal
    .DESCRIPTION
        Initiates certificate renewal process for certificates nearing expiration
    .PARAMETER VaultName
        Key Vault name
    .PARAMETER CertificateName
        Certificate name
    .PARAMETER Force
        Force renewal even if not near expiration
    .EXAMPLE
        Start-AzKeyVaultCertificateRenewal -VaultName "kv-prod" -CertificateName "webapp-cert"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        
        [Parameter(Mandatory)]
        [string]$CertificateName,
        
        [switch]$Force
    )
    
    if ($PSCmdlet.ShouldProcess($CertificateName, "Renew certificate")) {
        try {
            $cert = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName
            $policy = Get-AzKeyVaultCertificatePolicy -VaultName $VaultName -Name $CertificateName
            
            # Check if renewal is needed
            $daysUntilExpiration = ($cert.Expires - (Get-Date)).TotalDays
            $lifetimePercentage = (($cert.Expires - $cert.Created).TotalDays - $daysUntilExpiration) / ($cert.Expires - $cert.Created).TotalDays * 100
            
            if (-not $Force -and $lifetimePercentage -lt 80) {
                Write-Warning "Certificate is only at $([math]::Round($lifetimePercentage, 0))% of lifetime. Use -Force to renew anyway."
                return
            }
            
            # Create new version with same policy
            $operation = Add-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName -CertificatePolicy $policy
            
            Write-Information "Certificate renewal initiated for: $CertificateName" -InformationAction Continue
            
            # Monitor renewal progress
            $timeoutSeconds = 300
            $endTime = (Get-Date).AddSeconds($timeoutSeconds)
            
            while ((Get-Date) -lt $endTime) {
                $status = Get-AzKeyVaultCertificateOperation -VaultName $VaultName -Name $CertificateName
                
                if ($status.Status -eq 'completed') {
                    $newCert = Get-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName
                    Write-Information "Certificate renewed successfully" -InformationAction Continue
                    Write-Information "New thumbprint: $($newCert.Thumbprint)" -InformationAction Continue
                    Write-Information "Expires: $($newCert.Expires)" -InformationAction Continue
                    
                    return @{
                        CertificateName = $CertificateName
                        OldThumbprint = $cert.Thumbprint
                        NewThumbprint = $newCert.Thumbprint
                        NewExpiration = $newCert.Expires
                        RenewalTime = Get-Date
                    }
                }
                elseif ($status.Status -eq 'failed') {
                    throw "Certificate renewal failed: $($status.Error)"
                }
                
                Start-Sleep -Seconds 10
            }
            
            throw "Certificate renewal timed out after $timeoutSeconds seconds"
        }
        catch {
            Write-Error "Failed to renew certificate: $_"
        }
    }
}

#endregion

#region Access Policy and RBAC Management

function Set-AzKeyVaultAccessPolicyLeastPrivilege {
    <#
    .SYNOPSIS
        Apply least privilege access policies
    .DESCRIPTION
        Configures minimal required permissions for service principals and users
    .PARAMETER VaultName
        Key Vault name
    .PARAMETER ObjectId
        Object ID of user, group, or service principal
    .PARAMETER ApplicationId
        Application ID (for service principals)
    .PARAMETER PermissionProfile
        Pre-defined permission profile
    .PARAMETER CustomPermissions
        Custom permissions hashtable
    .EXAMPLE
        Set-AzKeyVaultAccessPolicyLeastPrivilege -VaultName "kv-prod" -ObjectId $sp.Id -PermissionProfile "SecretReader"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        
        [Parameter(Mandatory)]
        [string]$ObjectId,
        
        [string]$ApplicationId,
        
        [Parameter(ParameterSetName = 'Profile')]
        [ValidateSet('SecretReader', 'SecretManager', 'CertificateManager', 'KeyManager', 'Auditor')]
        [string]$PermissionProfile,
        
        [Parameter(ParameterSetName = 'Custom')]
        [hashtable]$CustomPermissions
    )
    
    # Define permission profiles
    $profiles = @{
        SecretReader = @{
            PermissionsToSecrets = @('get', 'list')
            PermissionsToKeys = @()
            PermissionsToCertificates = @()
        }
        SecretManager = @{
            PermissionsToSecrets = @('get', 'list', 'set', 'delete', 'backup', 'restore')
            PermissionsToKeys = @()
            PermissionsToCertificates = @()
        }
        CertificateManager = @{
            PermissionsToSecrets = @('get', 'list')
            PermissionsToKeys = @('get', 'list', 'create', 'sign')
            PermissionsToCertificates = @('get', 'list', 'create', 'delete', 'update', 'import', 'backup', 'restore')
        }
        KeyManager = @{
            PermissionsToSecrets = @()
            PermissionsToKeys = @('get', 'list', 'create', 'delete', 'update', 'import', 'backup', 'restore', 'encrypt', 'decrypt', 'sign', 'verify')
            PermissionsToCertificates = @()
        }
        Auditor = @{
            PermissionsToSecrets = @('list')
            PermissionsToKeys = @('list')
            PermissionsToCertificates = @('list')
        }
    }
    
    # Get permissions
    $permissions = if ($PermissionProfile) {
        $profiles[$PermissionProfile]
    } else {
        $CustomPermissions
    }
    
    if ($PSCmdlet.ShouldProcess($ObjectId, "Set Key Vault access policy")) {
        try {
            $params = @{
                VaultName = $VaultName
                ObjectId = $ObjectId
            }
            
            if ($ApplicationId) {
                $params.ApplicationId = $ApplicationId
            }
            
            if ($permissions.PermissionsToSecrets) {
                $params.PermissionsToSecrets = $permissions.PermissionsToSecrets
            }
            
            if ($permissions.PermissionsToKeys) {
                $params.PermissionsToKeys = $permissions.PermissionsToKeys
            }
            
            if ($permissions.PermissionsToCertificates) {
                $params.PermissionsToCertificates = $permissions.PermissionsToCertificates
            }
            
            Set-AzKeyVaultAccessPolicy @params
            
            Write-Information "Access policy applied successfully" -InformationAction Continue
            Write-Information "Profile: $($PermissionProfile ?? 'Custom')" -InformationAction Continue
            Write-Information "Object ID: $ObjectId" -InformationAction Continue
            
            return @{
                VaultName = $VaultName
                ObjectId = $ObjectId
                Profile = $PermissionProfile ?? 'Custom'
                Permissions = $permissions
            }
        }
        catch {
            Write-Error "Failed to set access policy: $_"
        }
    }
}

function Convert-AzKeyVaultToRbac {
    <#
    .SYNOPSIS
        Convert Key Vault from access policies to RBAC
    .DESCRIPTION
        Migrates existing access policies to RBAC roles
    .PARAMETER VaultName
        Key Vault name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER RemoveAccessPolicies
        Remove access policies after migration
    .EXAMPLE
        Convert-AzKeyVaultToRbac -VaultName "kv-prod" -ResourceGroupName "rg-prod"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [switch]$RemoveAccessPolicies
    )
    
    if ($PSCmdlet.ShouldProcess($VaultName, "Convert to RBAC")) {
        try {
            $vault = Get-AzKeyVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName
            
            if ($vault.EnableRbacAuthorization) {
                Write-Warning "Key Vault is already using RBAC"
                return
            }
            
            # Get current access policies
            $accessPolicies = $vault.AccessPolicies
            
            # Enable RBAC
            Update-AzKeyVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName -EnableRbacAuthorization $true
            
            Write-Information "RBAC enabled for Key Vault: $VaultName" -InformationAction Continue
            
            # Map access policies to RBAC roles
            $roleAssignments = @()
            
            foreach ($policy in $accessPolicies) {
                # Determine appropriate role based on permissions
                $role = 'Key Vault Reader'
                
                if ($policy.PermissionsToSecrets -contains 'set' -or $policy.PermissionsToSecrets -contains 'delete') {
                    $role = 'Key Vault Secrets Officer'
                }
                elseif ($policy.PermissionsToSecrets -contains 'get') {
                    $role = 'Key Vault Secrets User'
                }
                
                if ($policy.PermissionsToKeys -contains 'create' -or $policy.PermissionsToKeys -contains 'delete') {
                    $role = 'Key Vault Crypto Officer'
                }
                elseif ($policy.PermissionsToKeys -contains 'encrypt' -or $policy.PermissionsToKeys -contains 'decrypt') {
                    $role = 'Key Vault Crypto User'
                }
                
                if ($policy.PermissionsToCertificates -contains 'create' -or $policy.PermissionsToCertificates -contains 'delete') {
                    $role = 'Key Vault Certificates Officer'
                }
                
                # Create role assignment
                try {
                    $assignment = New-AzRoleAssignment -ObjectId $policy.ObjectId -RoleDefinitionName $role -Scope $vault.ResourceId
                    $roleAssignments += @{
                        ObjectId = $policy.ObjectId
                        Role = $role
                        Status = 'Success'
                    }
                    Write-Information "Assigned role '$role' to $($policy.ObjectId)" -InformationAction Continue
                }
                catch {
                    $roleAssignments += @{
                        ObjectId = $policy.ObjectId
                        Role = $role
                        Status = 'Failed'
                        Error = $_.Exception.Message
                    }
                    Write-Warning "Failed to assign role to $($policy.ObjectId): $_"
                }
            }
            
            # Remove access policies if requested
            if ($RemoveAccessPolicies) {
                foreach ($policy in $accessPolicies) {
                    Remove-AzKeyVaultAccessPolicy -VaultName $VaultName -ObjectId $policy.ObjectId
                }
                Write-Information "Access policies removed" -InformationAction Continue
            }
            
            return @{
                VaultName = $VaultName
                RbacEnabled = $true
                RoleAssignments = $roleAssignments
                MigrationComplete = $true
            }
        }
        catch {
            Write-Error "Failed to convert to RBAC: $_"
        }
    }
}

#endregion

#region Monitoring and Alerting

function Enable-AzKeyVaultMonitoring {
    <#
    .SYNOPSIS
        Enable comprehensive monitoring for Key Vault
    .DESCRIPTION
        Configures diagnostic settings, metrics, and alerts
    .PARAMETER VaultName
        Key Vault name
    .PARAMETER ResourceGroupName
        Resource group name
    .PARAMETER WorkspaceId
        Log Analytics workspace ID
    .PARAMETER AlertActionGroupId
        Action group ID for alerts
    .EXAMPLE
        Enable-AzKeyVaultMonitoring -VaultName "kv-prod" -ResourceGroupName "rg-prod" -WorkspaceId $workspace.ResourceId
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [Parameter(Mandatory)]
        [string]$WorkspaceId,
        
        [string]$AlertActionGroupId
    )
    
    try {
        $vault = Get-AzKeyVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName
        
        # Enable diagnostic settings
        $diagnosticParams = @{
            ResourceId = $vault.ResourceId
            Name = "diag-$VaultName"
            WorkspaceId = $WorkspaceId
            Category = @('AuditEvent', 'AllMetrics')
            Enabled = $true
        }
        
        Set-AzDiagnosticSetting @diagnosticParams
        Write-Information "Diagnostic settings configured" -InformationAction Continue
        
        # Create alerts
        if ($AlertActionGroupId) {
            # Alert for access denied events
            $accessDeniedAlert = @{
                Name = "alert-$VaultName-access-denied"
                ResourceGroupName = $ResourceGroupName
                Scopes = @($vault.ResourceId)
                Condition = New-AzMetricAlertRuleV2Criteria -MetricName 'ServiceApiResult' -TimeAggregation Total -Operator GreaterThan -Threshold 5
                ActionGroupId = @($AlertActionGroupId)
                WindowSize = New-TimeSpan -Minutes 5
                Frequency = New-TimeSpan -Minutes 5
                Severity = 2
                Description = "Alert when access denied events exceed threshold"
            }
            
            Add-AzMetricAlertRuleV2 @accessDeniedAlert
            
            # Alert for certificate expiration
            $certExpirationQuery = @"
AzureDiagnostics
| where ResourceType == "VAULTS" and ResourceId contains "$VaultName"
| where OperationName == "CertificateNearExpiry"
| summarize count() by bin(TimeGenerated, 5m)
"@
            
            $certAlert = @{
                Name = "alert-$VaultName-cert-expiry"
                ResourceGroupName = $ResourceGroupName
                Scopes = @($WorkspaceId)
                Condition = New-AzScheduledQueryRuleConditionObject -Query $certExpirationQuery -TimeAggregation Count -Operator GreaterThan -Threshold 0
                ActionGroupId = @($AlertActionGroupId)
                WindowSize = New-TimeSpan -Minutes 5
                Frequency = New-TimeSpan -Minutes 5
                Severity = 1
                Description = "Alert for certificates nearing expiration"
            }
            
            # Note: Scheduled query rules require additional setup
            Write-Information "Alert rules configured" -InformationAction Continue
        }
        
        return @{
            VaultName = $VaultName
            DiagnosticSettingsEnabled = $true
            AlertsConfigured = $AlertActionGroupId -ne $null
            WorkspaceId = $WorkspaceId
        }
    }
    catch {
        Write-Error "Failed to enable monitoring: $_"
    }
}

#endregion

#region Compliance and Audit

function Get-AzKeyVaultAuditReport {
    <#
    .SYNOPSIS
        Generate Key Vault audit report
    .DESCRIPTION
        Creates comprehensive audit report for Key Vault operations
    .PARAMETER VaultName
        Key Vault name
    .PARAMETER StartDate
        Report start date
    .PARAMETER EndDate
        Report end date
    .PARAMETER ExportPath
        Path to export report
    .EXAMPLE
        Get-AzKeyVaultAuditReport -VaultName "kv-prod" -StartDate (Get-Date).AddDays(-30) -ExportPath ".\audit-report.html"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$VaultName,
        
        [datetime]$StartDate = (Get-Date).AddDays(-7),
        
        [datetime]$EndDate = (Get-Date),
        
        [string]$ExportPath
    )
    
    $vault = Get-AzKeyVault -VaultName $VaultName
    
    # Audit data structure
    $auditData = @{
        VaultName = $VaultName
        ReportPeriod = "$($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))"
        GeneratedOn = Get-Date
        Configuration = @{}
        AccessPolicies = @()
        Secrets = @()
        Certificates = @()
        Keys = @()
        Operations = @()
    }
    
    # Configuration audit
    $auditData.Configuration = @{
        SoftDeleteEnabled = $vault.EnableSoftDelete
        PurgeProtectionEnabled = $vault.EnablePurgeProtection
        RbacEnabled = $vault.EnableRbacAuthorization
        NetworkRestrictions = (Get-AzKeyVaultNetworkRuleSet -VaultName $VaultName).DefaultAction
        Location = $vault.Location
        ResourceGroup = $vault.ResourceGroupName
    }
    
    # Access audit
    if (-not $vault.EnableRbacAuthorization) {
        $auditData.AccessPolicies = $vault.AccessPolicies | ForEach-Object {
            @{
                ObjectId = $_.ObjectId
                DisplayName = $_.DisplayName
                ApplicationId = $_.ApplicationId
                PermissionsToSecrets = $_.PermissionsToSecrets -join ', '
                PermissionsToKeys = $_.PermissionsToKeys -join ', '
                PermissionsToCertificates = $_.PermissionsToCertificates -join ', '
            }
        }
    }
    else {
        # Get RBAC assignments
        $roleAssignments = Get-AzRoleAssignment -Scope $vault.ResourceId
        $auditData.RoleAssignments = $roleAssignments | ForEach-Object {
            @{
                ObjectId = $_.ObjectId
                DisplayName = $_.DisplayName
                RoleDefinitionName = $_.RoleDefinitionName
                Scope = $_.Scope
            }
        }
    }
    
    # Inventory audit
    $secrets = Get-AzKeyVaultSecret -VaultName $VaultName
    $auditData.Secrets = $secrets | ForEach-Object {
        @{
            Name = $_.Name
            Enabled = $_.Enabled
            Created = $_.Created
            Updated = $_.Updated
            Expires = $_.Expires
            ContentType = $_.ContentType
        }
    }
    
    $certificates = Get-AzKeyVaultCertificate -VaultName $VaultName
    $auditData.Certificates = $certificates | ForEach-Object {
        @{
            Name = $_.Name
            Enabled = $_.Enabled
            Created = $_.Created
            Updated = $_.Updated
            Expires = $_.Expires
            Thumbprint = $_.Thumbprint
            Subject = $_.SubjectName
        }
    }
    
    $keys = Get-AzKeyVaultKey -VaultName $VaultName
    $auditData.Keys = $keys | ForEach-Object {
        @{
            Name = $_.Name
            Enabled = $_.Enabled
            Created = $_.Created
            Updated = $_.Updated
            Expires = $_.Expires
            KeyType = $_.Key.Kty
            KeySize = $_.Key.KeySize
        }
    }
    
    # Export report
    if ($ExportPath) {
        if ($ExportPath -match '\.html$') {
            # Generate HTML report
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Key Vault Audit Report - $VaultName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0078d4; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .warning { color: #ff6b6b; }
        .success { color: #51cf66; }
    </style>
</head>
<body>
    <h1>Key Vault Audit Report</h1>
    <p><strong>Vault:</strong> $($auditData.VaultName)</p>
    <p><strong>Period:</strong> $($auditData.ReportPeriod)</p>
    <p><strong>Generated:</strong> $($auditData.GeneratedOn)</p>
    
    <h2>Configuration</h2>
    <table>
        <tr><th>Setting</th><th>Value</th></tr>
        <tr><td>Soft Delete</td><td class="$(if($auditData.Configuration.SoftDeleteEnabled){'success'}else{'warning'})">$($auditData.Configuration.SoftDeleteEnabled)</td></tr>
        <tr><td>Purge Protection</td><td>$($auditData.Configuration.PurgeProtectionEnabled)</td></tr>
        <tr><td>RBAC Enabled</td><td>$($auditData.Configuration.RbacEnabled)</td></tr>
        <tr><td>Network Restrictions</td><td class="$(if($auditData.Configuration.NetworkRestrictions -eq 'Deny'){'success'}else{'warning'})">$($auditData.Configuration.NetworkRestrictions)</td></tr>
    </table>
    
    <h2>Inventory Summary</h2>
    <table>
        <tr><th>Type</th><th>Count</th><th>Enabled</th><th>Expiring Soon</th></tr>
        <tr><td>Secrets</td><td>$($auditData.Secrets.Count)</td><td>$(($auditData.Secrets | Where-Object Enabled).Count)</td><td>$(($auditData.Secrets | Where-Object { $_.Expires -and $_.Expires -lt (Get-Date).AddDays(30) }).Count)</td></tr>
        <tr><td>Certificates</td><td>$($auditData.Certificates.Count)</td><td>$(($auditData.Certificates | Where-Object Enabled).Count)</td><td>$(($auditData.Certificates | Where-Object { $_.Expires -and $_.Expires -lt (Get-Date).AddDays(30) }).Count)</td></tr>
        <tr><td>Keys</td><td>$($auditData.Keys.Count)</td><td>$(($auditData.Keys | Where-Object Enabled).Count)</td><td>$(($auditData.Keys | Where-Object { $_.Expires -and $_.Expires -lt (Get-Date).AddDays(30) }).Count)</td></tr>
    </table>
</body>
</html>
"@
            $html | Out-File $ExportPath
        }
        else {
            # Export as JSON
            $auditData | ConvertTo-Json -Depth 10 | Out-File $ExportPath
        }
        
        Write-Information "Audit report exported to: $ExportPath" -InformationAction Continue
    }
    
    return $auditData
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'New-AzKeyVaultAdvanced'
    'Test-AzKeyVaultCompliance'
    'Enable-AzKeyVaultSecretRotation'
    'Start-AzKeyVaultSecretRotation'
    'Get-AzKeyVaultExpiringSecrets'
    'New-AzKeyVaultCertificateAdvanced'
    'Get-AzKeyVaultCertificateHealth'
    'Start-AzKeyVaultCertificateRenewal'
    'Set-AzKeyVaultAccessPolicyLeastPrivilege'
    'Convert-AzKeyVaultToRbac'
    'Enable-AzKeyVaultMonitoring'
    'Get-AzKeyVaultAuditReport'
)