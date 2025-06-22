#Requires -Version 7.0
#Requires -Modules Az.Accounts

<#
.SYNOPSIS
    Enterprise Azure Accounts Management Module
.DESCRIPTION
    Advanced authentication and subscription management for enterprise Azure environments
.VERSION
    2.0.0
.AUTHOR
    Azure Enterprise Toolkit
#>

# Module configuration
$script:ModuleVersion = '2.0.0'
$script:MinAzAccountsVersion = '2.12.1'

# Initialize module
function Initialize-AzAccountsEnterprise {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Initializing Az.Accounts Enterprise Module v$script:ModuleVersion"
    
    # Check Az.Accounts version
    $azAccounts = Get-Module -Name Az.Accounts -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $azAccounts -or $azAccounts.Version -lt $script:MinAzAccountsVersion) {
        throw "Az.Accounts module version $script:MinAzAccountsVersion or higher is required. Current version: $($azAccounts.Version)"
    }
}

#region Multi-Tenant Authentication

function Connect-AzMultiTenant {
    <#
    .SYNOPSIS
        Connect to multiple Azure tenants simultaneously
    .DESCRIPTION
        Establishes connections to multiple Azure AD tenants for cross-tenant management
    .PARAMETER TenantIds
        Array of tenant IDs to connect to
    .PARAMETER UseServicePrincipal
        Use service principal authentication
    .PARAMETER ServicePrincipalId
        Service principal application ID
    .PARAMETER ServicePrincipalSecret
        Service principal secret (SecureString)
    .PARAMETER UseManagedIdentity
        Use managed identity authentication
    .PARAMETER CertificateThumbprint
        Certificate thumbprint for certificate-based authentication
    .EXAMPLE
        Connect-AzMultiTenant -TenantIds @('tenant1-id', 'tenant2-id')
    #>
    [CmdletBinding(DefaultParameterSetName = 'Interactive')]
    param(
        [Parameter(Mandatory)]
        [string[]]$TenantIds,
        
        [Parameter(ParameterSetName = 'ServicePrincipal')]
        [switch]$UseServicePrincipal,
        
        [Parameter(ParameterSetName = 'ServicePrincipal', Mandatory)]
        [string]$ServicePrincipalId,
        
        [Parameter(ParameterSetName = 'ServicePrincipal', Mandatory)]
        [SecureString]$ServicePrincipalSecret,
        
        [Parameter(ParameterSetName = 'ManagedIdentity')]
        [switch]$UseManagedIdentity,
        
        [Parameter(ParameterSetName = 'Certificate')]
        [string]$CertificateThumbprint
    )
    
    $connections = @{}
    
    foreach ($tenantId in $TenantIds) {
        Write-Information "Connecting to tenant: $tenantId" -InformationAction Continue
        
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'ServicePrincipal' {
                    $credential = New-Object System.Management.Automation.PSCredential($ServicePrincipalId, $ServicePrincipalSecret)
                    $context = Connect-AzAccount -ServicePrincipal -Tenant $tenantId -Credential $credential -ErrorAction Stop
                }
                'ManagedIdentity' {
                    $context = Connect-AzAccount -Identity -TenantId $tenantId -ErrorAction Stop
                }
                'Certificate' {
                    $context = Connect-AzAccount -CertificateThumbprint $CertificateThumbprint -ApplicationId $ServicePrincipalId -Tenant $tenantId -ErrorAction Stop
                }
                default {
                    $context = Connect-AzAccount -TenantId $tenantId -ErrorAction Stop
                }
            }
            
            $connections[$tenantId] = $context
            Write-Information "Successfully connected to tenant: $tenantId" -InformationAction Continue
        }
        catch {
            Write-Error "Failed to connect to tenant $tenantId: $_"
        }
    }
    
    return $connections
}

function Switch-AzTenant {
    <#
    .SYNOPSIS
        Switch between connected Azure tenants
    .DESCRIPTION
        Quickly switch context between connected Azure AD tenants
    .PARAMETER TenantId
        Target tenant ID to switch to
    .EXAMPLE
        Switch-AzTenant -TenantId 'tenant-id'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )
    
    try {
        $contexts = Get-AzContext -ListAvailable | Where-Object { $_.Tenant.Id -eq $TenantId }
        
        if ($contexts) {
            $context = $contexts | Select-Object -First 1
            Set-AzContext -Context $context | Out-Null
            Write-Information "Switched to tenant: $($context.Tenant.Id) - $($context.Tenant.Name)" -InformationAction Continue
            return $context
        }
        else {
            throw "No available context found for tenant: $TenantId"
        }
    }
    catch {
        Write-Error "Failed to switch tenant: $_"
    }
}

#endregion

#region Service Principal Automation

function New-AzServicePrincipalAdvanced {
    <#
    .SYNOPSIS
        Create a service principal with advanced options
    .DESCRIPTION
        Creates a service principal with certificate or secret authentication and custom permissions
    .PARAMETER DisplayName
        Display name for the service principal
    .PARAMETER UseCertificate
        Use certificate-based authentication
    .PARAMETER ValidYears
        Certificate/secret validity in years (default: 1)
    .PARAMETER Role
        Azure RBAC role to assign
    .PARAMETER Scope
        Scope for role assignment
    .EXAMPLE
        New-AzServicePrincipalAdvanced -DisplayName "MyApp" -UseCertificate -Role "Contributor" -Scope "/subscriptions/sub-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DisplayName,
        
        [switch]$UseCertificate,
        
        [int]$ValidYears = 1,
        
        [string]$Role,
        
        [string]$Scope
    )
    
    try {
        $endDate = (Get-Date).AddYears($ValidYears)
        
        if ($UseCertificate) {
            # Generate self-signed certificate
            $cert = New-SelfSignedCertificate -Subject "CN=$DisplayName" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -KeyLength 2048 -KeyUsage DigitalSignature -NotAfter $endDate
            
            $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
            
            # Create service principal with certificate
            $sp = New-AzADServicePrincipal -DisplayName $DisplayName -CertValue $keyValue -EndDate $endDate
            
            Write-Information "Certificate thumbprint: $($cert.Thumbprint)" -InformationAction Continue
        }
        else {
            # Create service principal with secret
            $sp = New-AzADServicePrincipal -DisplayName $DisplayName -EndDate $endDate
        }
        
        # Assign role if specified
        if ($Role -and $Scope) {
            Start-Sleep -Seconds 10 # Wait for SP propagation
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $Role -Scope $Scope
        }
        
        $result = @{
            ApplicationId = $sp.AppId
            ObjectId = $sp.Id
            DisplayName = $sp.DisplayName
            TenantId = (Get-AzContext).Tenant.Id
        }
        
        if ($UseCertificate) {
            $result.CertificateThumbprint = $cert.Thumbprint
        }
        else {
            $result.Secret = $sp.PasswordCredentials[0].SecretText
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to create service principal: $_"
    }
}

function Remove-ExpiredServicePrincipals {
    <#
    .SYNOPSIS
        Remove expired service principals
    .DESCRIPTION
        Identifies and removes service principals with expired credentials
    .PARAMETER WhatIf
        Preview changes without making them
    .EXAMPLE
        Remove-ExpiredServicePrincipals -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $currentDate = Get-Date
    $expiredSPs = @()
    
    Get-AzADServicePrincipal -All | ForEach-Object {
        $sp = $_
        $expired = $false
        
        # Check password credentials
        $sp.PasswordCredentials | ForEach-Object {
            if ($_.EndDateTime -lt $currentDate) {
                $expired = $true
            }
        }
        
        # Check key credentials (certificates)
        $sp.KeyCredentials | ForEach-Object {
            if ($_.EndDateTime -lt $currentDate) {
                $expired = $true
            }
        }
        
        if ($expired) {
            $expiredSPs += $sp
        }
    }
    
    foreach ($sp in $expiredSPs) {
        if ($PSCmdlet.ShouldProcess($sp.DisplayName, "Remove expired service principal")) {
            Remove-AzADServicePrincipal -ObjectId $sp.Id -Force
            Write-Information "Removed expired service principal: $($sp.DisplayName)" -InformationAction Continue
        }
    }
    
    return $expiredSPs
}

#endregion

#region Managed Identity Integration

function Test-AzManagedIdentity {
    <#
    .SYNOPSIS
        Test managed identity configuration
    .DESCRIPTION
        Validates managed identity setup and permissions
    .PARAMETER ResourceId
        Resource ID of the managed identity
    .EXAMPLE
        Test-AzManagedIdentity -ResourceId "/subscriptions/sub-id/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-name"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceId
    )
    
    try {
        # Parse resource ID
        $parts = $ResourceId -split '/'
        $subscriptionId = $parts[2]
        $resourceGroup = $parts[4]
        $identityName = $parts[-1]
        
        # Get managed identity
        $identity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroup -Name $identityName
        
        if (-not $identity) {
            throw "Managed identity not found"
        }
        
        # Get role assignments
        $roleAssignments = Get-AzRoleAssignment -ObjectId $identity.PrincipalId
        
        $result = @{
            IdentityName = $identity.Name
            PrincipalId = $identity.PrincipalId
            ClientId = $identity.ClientId
            TenantId = $identity.TenantId
            RoleAssignments = $roleAssignments | Select-Object RoleDefinitionName, Scope
            IsValid = $true
        }
        
        # Test authentication
        try {
            $context = Connect-AzAccount -Identity -AccountId $identity.ClientId -ErrorAction Stop
            $result.AuthenticationTest = "Passed"
            Disconnect-AzAccount -ContextName $context.Name | Out-Null
        }
        catch {
            $result.AuthenticationTest = "Failed: $_"
            $result.IsValid = $false
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to test managed identity: $_"
    }
}

#endregion

#region Cross-Subscription Management

function Get-AzAllSubscriptions {
    <#
    .SYNOPSIS
        Get all subscriptions across connected tenants
    .DESCRIPTION
        Retrieves all Azure subscriptions accessible across all connected tenants
    .PARAMETER IncludeDisabled
        Include disabled subscriptions
    .EXAMPLE
        Get-AzAllSubscriptions | Format-Table Name, State, TenantId
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeDisabled
    )
    
    $allSubscriptions = @()
    $contexts = Get-AzContext -ListAvailable | Select-Object -Unique -Property Tenant
    
    foreach ($context in $contexts) {
        try {
            Set-AzContext -TenantId $context.Tenant.Id | Out-Null
            $subscriptions = Get-AzSubscription -TenantId $context.Tenant.Id
            
            if (-not $IncludeDisabled) {
                $subscriptions = $subscriptions | Where-Object { $_.State -eq 'Enabled' }
            }
            
            $allSubscriptions += $subscriptions
        }
        catch {
            Write-Warning "Failed to get subscriptions for tenant $($context.Tenant.Id): $_"
        }
    }
    
    return $allSubscriptions
}

function Invoke-AzCrossSubscriptionCommand {
    <#
    .SYNOPSIS
        Execute commands across multiple subscriptions
    .DESCRIPTION
        Runs a script block across multiple Azure subscriptions in parallel
    .PARAMETER SubscriptionIds
        Array of subscription IDs to run command in
    .PARAMETER ScriptBlock
        Script block to execute in each subscription
    .PARAMETER ThrottleLimit
        Maximum number of parallel executions
    .EXAMPLE
        Invoke-AzCrossSubscriptionCommand -SubscriptionIds @('sub1', 'sub2') -ScriptBlock { Get-AzVM }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SubscriptionIds,
        
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [int]$ThrottleLimit = 5
    )
    
    $jobs = @()
    
    foreach ($subscriptionId in $SubscriptionIds) {
        $jobs += Start-ThreadJob -ScriptBlock {
            param($subId, $script)
            
            try {
                Set-AzContext -SubscriptionId $subId | Out-Null
                $result = & $script
                
                return @{
                    SubscriptionId = $subId
                    Success = $true
                    Result = $result
                }
            }
            catch {
                return @{
                    SubscriptionId = $subId
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
        } -ArgumentList $subscriptionId, $ScriptBlock -ThrottleLimit $ThrottleLimit
    }
    
    $results = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    return $results
}

#endregion

#region Certificate-Based Authentication

function New-AzAuthenticationCertificate {
    <#
    .SYNOPSIS
        Create a certificate for Azure authentication
    .DESCRIPTION
        Generates a self-signed certificate for Azure service principal authentication
    .PARAMETER Subject
        Certificate subject name
    .PARAMETER ExportPath
        Path to export certificate files
    .PARAMETER ValidYears
        Certificate validity in years
    .EXAMPLE
        New-AzAuthenticationCertificate -Subject "CN=AzureAuth" -ExportPath "C:\Certs" -ValidYears 2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Subject,
        
        [Parameter(Mandatory)]
        [string]$ExportPath,
        
        [int]$ValidYears = 1
    )
    
    try {
        # Create directory if it doesn't exist
        if (-not (Test-Path $ExportPath)) {
            New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null
        }
        
        # Generate certificate
        $cert = New-SelfSignedCertificate `
            -Subject $Subject `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -KeyExportPolicy Exportable `
            -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
            -KeyLength 2048 `
            -KeyUsage DigitalSignature `
            -NotAfter (Get-Date).AddYears($ValidYears)
        
        # Export certificate
        $certPath = Join-Path $ExportPath "$($Subject -replace 'CN=', '').cer"
        $pfxPath = Join-Path $ExportPath "$($Subject -replace 'CN=', '').pfx"
        
        # Export public certificate
        Export-Certificate -Cert $cert -FilePath $certPath | Out-Null
        
        # Export PFX with password
        $password = Read-Host -AsSecureString "Enter password for PFX file"
        Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $password | Out-Null
        
        return @{
            Thumbprint = $cert.Thumbprint
            Subject = $cert.Subject
            NotAfter = $cert.NotAfter
            PublicKeyPath = $certPath
            PfxPath = $pfxPath
            StoreLocation = "Cert:\CurrentUser\My\$($cert.Thumbprint)"
        }
    }
    catch {
        Write-Error "Failed to create authentication certificate: $_"
    }
}

#endregion

#region Module Utilities

function Get-AzAccountsEnterpriseInfo {
    <#
    .SYNOPSIS
        Get information about the enterprise accounts module
    .DESCRIPTION
        Returns version and configuration information
    .EXAMPLE
        Get-AzAccountsEnterpriseInfo
    #>
    [CmdletBinding()]
    param()
    
    return @{
        ModuleVersion = $script:ModuleVersion
        RequiredAzAccountsVersion = $script:MinAzAccountsVersion
        CurrentAzAccountsVersion = (Get-Module Az.Accounts).Version
        Features = @(
            'Multi-tenant authentication'
            'Service principal automation'
            'Managed identity integration'
            'Certificate-based authentication'
            'Cross-subscription management'
        )
    }
}

#endregion

# Initialize module on import
Initialize-AzAccountsEnterprise

# Export module members
Export-ModuleMember -Function @(
    'Connect-AzMultiTenant'
    'Switch-AzTenant'
    'New-AzServicePrincipalAdvanced'
    'Remove-ExpiredServicePrincipals'
    'Test-AzManagedIdentity'
    'Get-AzAllSubscriptions'
    'Invoke-AzCrossSubscriptionCommand'
    'New-AzAuthenticationCertificate'
    'Get-AzAccountsEnterpriseInfo'
)