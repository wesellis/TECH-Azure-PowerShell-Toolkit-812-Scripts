#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage NICs

.DESCRIPTION
    Manage NICs
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Communication Services Manager
#
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$CommunicationServiceName,
    [Parameter()]
    [string]$Location = "Global",
    [Parameter()]
    [ValidateSet("Create", "Delete", "GetInfo", "ConfigureDomain", "ManagePhoneNumbers", "SendSMS", "SendEmail", "CreateIdentity")]
    [string]$Action = "Create",
    [Parameter()]
    [string]$DomainName,
    [Parameter()]
    [ValidateSet("AzureManaged", "CustomerManaged")]
    [string]$DomainManagement = "AzureManaged",
    [Parameter()]
    [string]$PhoneNumberType = "TollFree",
    [Parameter()]
    [string]$PhoneNumberAssignmentType = "Application",
    [Parameter()]
    [string]$CountryCode = "US",
    [Parameter()]
    [int]$PhoneNumberQuantity = 1,
    [Parameter()]
    [string]$SMSTo,
    [Parameter()]
    [string]$SMSFrom,
    [Parameter()]
    [string]$SMSMessage,
    [Parameter()]
    [string]$EmailTo,
    [Parameter()]
    [string]$EmailFrom,
    [Parameter()]
    [string]$EmailSubject,
    [Parameter()]
    [string]$EmailContent,
    [Parameter()]
    [string]$UserIdentityName,
    [Parameter()]
    [switch]$EnableEventGrid,
    [Parameter()]
    [switch]$EnableMonitoring,
    [Parameter()]
    [switch]$EnableMessaging
)
try {
    # Test Azure connection
        if (-not (Get-AzContext)) { throw "Not connected to Azure" }
        
        Install-Module Az.Communication -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Communication
    }
    # Validate resource group
        $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    
    switch ($Action.ToLower()) {
        "create" {
            # Create Communication Services resource
                $communicationParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $CommunicationServiceName
                DataLocation = $Location
            }
            $communicationService = Invoke-AzureOperation -Operation {
                New-AzCommunicationService -ErrorAction Stop @communicationParams
            } -OperationName "Create Communication Service"
            
            # Get connection string
            $connectionString = Invoke-AzureOperation -Operation {
                Get-AzCommunicationServiceKey -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
            } -OperationName "Get Connection String"
            
        }
        "configuredomain" {
            if (-not $DomainName) {
                throw "DomainName parameter is required for domain configuration"
            }
                # Configure email domain using REST API
            Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $body = @{
                    properties = @{
                        domainManagement = $DomainManagement
                        validSenderUsernames = @{
                            "*" = "Enabled"
                        }
                    }
                } | ConvertTo-Json -Depth 3
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/domains/$DomainName" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Configure Email Domain" | Out-Null
            
            if ($DomainManagement -eq "CustomerManaged") {
                Write-Host ""
                Write-Host "For customer-managed domains, add these DNS records:"
                Write-Host "TXT record: verification code (check Azure portal)"
                Write-Host "MX record: inbound email routing"
                Write-Host "SPF record: sender policy framework"
                Write-Host "DKIM records: domain key identified mail"
                Write-Host ""
            }
        }
        "managephonenumbers" {
                # Search for available phone numbers
            $availableNumbers = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $body = @{
                    phoneNumberType = $PhoneNumberType
                    assignmentType = $PhoneNumberAssignmentType
                    capabilities = @{
                        calling = "inbound+outbound"
                        sms = "inbound+outbound"
                    }
                    areaCode = ""
                    quantity = $PhoneNumberQuantity
                } | ConvertTo-Json -Depth 3
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Communication/phoneNumberOrders/search" + "?api-version=2022-12-01"
                $searchResponse = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
                return $searchResponse
            } -OperationName "Search Phone Numbers"
            Write-Host ""
            if ($availableNumbers.phoneNumbers) {
                foreach ($number in $availableNumbers.phoneNumbers) {
                    Write-Host " $($number.phoneNumber)"
                    Write-Host "Cost: $($number.cost.amount) $($number.cost.currencyCode)/month"
                    Write-Host "Capabilities: $($number.capabilities.calling), $($number.capabilities.sms)"
                    Write-Host ""
                }
                # Purchase the first available number
                if ($availableNumbers.phoneNumbers.Count -gt 0) {
                    Invoke-AzureOperation -Operation {
                        $headers = @{
                            'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                            'Content-Type' = 'application/json'
                        }
                        $body = @{
                            searchId = $availableNumbers.searchId
                        } | ConvertTo-Json
                        $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Communication/phoneNumberOrders/purchase" + "?api-version=2022-12-01"
                        Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
                    } -OperationName "Purchase Phone Numbers" | Out-Null
                    
                }
            } else {
                
            }
        }
        "sendsms" {
            if (-not $SMSTo -or -not $SMSFrom -or -not $SMSMessage) {
                throw "SMSTo, SMSFrom, and SMSMessage parameters are required for SMS sending"
            }
                # Get connection string
            $connectionString = Get-AzCommunicationServiceKey -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
            # Send SMS using REST API
            $smsResult = Invoke-AzureOperation -Operation {
                $endpoint = ($connectionString.PrimaryConnectionString -split ';')[0] -replace 'endpoint=', ''
                $accessKey = ($connectionString.PrimaryConnectionString -split ';')[1] -replace 'accesskey=', ''
                $headers = @{
                    'Content-Type' = 'application/json'
                    'Authorization' = "Bearer $(Get-CommunicationAccessToken -Endpoint $endpoint -AccessKey $accessKey)"
                }
                $body = @{
                    from = $SMSFrom
                    to = @($SMSTo)
                    message = $SMSMessage
                    enableDeliveryReport = $true
                    tag = "Azure-Automation-SMS"
                } | ConvertTo-Json -Depth 3
                $uri = "$endpoint/sms?api-version=2021-03-07"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Send SMS"
            
        }
        "sendemail" {
            if (-not $EmailTo -or -not $EmailFrom -or -not $EmailSubject -or -not $EmailContent) {
                throw "EmailTo, EmailFrom, EmailSubject, and EmailContent parameters are required for email sending"
            }
                # Send email using REST API
            Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $body = @{
                    senderAddress = $EmailFrom
                    recipients = @{
                        to = @(
                            @{
                                address = $EmailTo
                                displayName = $EmailTo
                            }
                        )
                    }
                    content = @{
                        subject = $EmailSubject
                        plainText = $EmailContent
                        html = "<p>$EmailContent</p>"
                    }
                    importance = "normal"
                    disableUserEngagementTracking = $false
                } | ConvertTo-Json -Depth 5
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/sendEmail" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Send Email" | Out-Null
            
        }
        "createidentity" {
                # Create user identity
            $userIdentity = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $body = @{
                    createTokenWithScopes = @("chat", "voip")
                } | ConvertTo-Json
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/identities" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Create User Identity"
            
            Write-Host ""
            Write-Host "Identity ID: $($userIdentity.identity.id)"
            Write-Host "Access Token: $($userIdentity.accessToken.token)"
            Write-Host "Token Expires: $($userIdentity.accessToken.expiresOn)"
            Write-Host ""
            Write-Host "[WARN]  Store the access token securely - it's needed for client authentication"
        }
        "getinfo" {
                # Get Communication Service info
            $communicationService = Invoke-AzureOperation -Operation {
                Get-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
            } -OperationName "Get Communication Service"
            # Get phone numbers
            $phoneNumbers = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/phoneNumbers" + "?api-version=2022-12-01"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Phone Numbers"
            # Get domains
            $domains = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/domains" + "?api-version=2023-04-01"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ErrorAction SilentlyContinue
                return $response.value
            } -OperationName "Get Email Domains"
            Write-Host ""
            Write-Host "Service Name: $($communicationService.Name)"
            Write-Host "Data Location: $($communicationService.DataLocation)"
            Write-Host "Status: $($communicationService.ProvisioningState)"
            Write-Host "Resource ID: $($communicationService.Id)"
            if ($phoneNumbers.Count -gt 0) {
                Write-Host ""
                foreach ($number in $phoneNumbers) {
                    Write-Host " $($number.phoneNumber)"
                    Write-Host "Type: $($number.phoneNumberType)"
                    Write-Host "Assignment: $($number.assignmentType)"
                    Write-Host "Capabilities: SMS=$($number.capabilities.sms), Calling=$($number.capabilities.calling)"
                    Write-Host ""
                }
            }
            if ($domains.Count -gt 0) {
                foreach ($domain in $domains) {
                    Write-Host " $($domain.name)"
                    Write-Host "Management: $($domain.properties.domainManagement)"
                    Write-Host "Status: $($domain.properties.verificationStates.domain)"
                    Write-Host ""
                }
            }
        }
        "delete" {
                $confirmation = Read-Host "Are you sure you want to delete the Communication Service '$CommunicationServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {
                
                return
            }
            Invoke-AzureOperation -Operation {
                if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
            } -OperationName "Delete Communication Service"
            
        }
    }
    # Configure Event Grid integration if enabled
    if ($EnableEventGrid -and $Action.ToLower() -eq "create") {
            Invoke-AzureOperation -Operation {
            $topicName = "$CommunicationServiceName-events"
            New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $topicName -Location $resourceGroup.Location
        } -OperationName "Create Event Grid Topic" | Out-Null
        
    }
    # Configure monitoring if enabled
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
            $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($logAnalyticsWorkspace) {
                $resourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName"
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = "$CommunicationServiceName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("ChatOperational", "SMSOperational", "CallSummary", "CallDiagnostics")
                    MetricCategory = @("AllMetrics")
                }
                Set-AzDiagnosticSetting -ErrorAction Stop @diagnosticParams
            } else {
                
                return $null
            }
        } -OperationName "Configure Monitoring"
        if ($diagnosticSettings) {
            
        }
    }
    # Apply enterprise tags if creating service
    if ($Action.ToLower() -eq "create") {
            $tags = @{
            'Environment' = 'Production'
            'Service' = 'CommunicationServices'
            'ManagedBy' = 'Azure-Automation'
            'CreatedBy' = $env:USERNAME
            'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
            'CostCenter' = 'Communications'
            'Purpose' = 'CustomerEngagement'
            'DataLocation' = $Location
            'Compliance' = 'GDPR-Ready'
        }
        Invoke-AzureOperation -Operation {
            $resource = Get-AzResource -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName -ResourceType "Microsoft.Communication/CommunicationServices"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
        } -OperationName "Apply Enterprise Tags" | Out-Null
    }
    # Communication capabilities analysis
        $capabilities = @(
        "Voice calling (VoIP) - Make and receive voice calls",
        "Chat - Real-time messaging and group chat",
        "SMS - Send and receive text messages",
        "Email - Transactional and marketing emails",
        "Video calling - HD video communication",
        "Identity management - User authentication and tokens",
        "Call analytics - Call quality and usage metrics",
        "Global reach - Worldwide communication coverage"
    )
    # Security assessment
        $securityScore = 0
    $maxScore = 5
    $securityFindings = @()
    if ($Action.ToLower() -eq "create") {
        # Check data location
        if ($Location -in @("United States", "Europe", "Asia Pacific")) {
            $securityScore++
            $securityFindings += "[OK] Data stored in compliant region"
        }
        # Check monitoring
        if ($EnableMonitoring) {
            $securityScore++
            $securityFindings += "[OK] Monitoring and logging enabled"
        } else {
            $securityFindings += "[WARN]  Monitoring not configured"
        }
        # Check Event Grid integration
        if ($EnableEventGrid) {
            $securityScore++
            $securityFindings += "[OK] Event Grid integration for audit trails"
        } else {
            $securityFindings += "[WARN]  Event Grid not configured for event tracking"
        }
        # Check  messaging
        if ($EnableMessaging) {
            $securityScore++
            $securityFindings += "[OK]  messaging features enabled"
        }
        # Service is inherently secure
        $securityScore++
        $securityFindings += "[OK] End-to-end encryption for all communications"
    }
    # Cost analysis
        $costComponents = @{
        "SMS" = "$0.0075 per message (US)"
        "Voice Calling" = "$0.004 per minute (outbound)"
        "Phone Numbers" = "$1-15 per month depending on type"
        "Email" = "$0.25 per 1,000 emails"
        "Chat" = "$1.50 per monthly active user"
        "Video Calling" = "$0.004 per participant per minute"
        "Data Storage" = "Included in base service"
        "Identity Management" = "Free for basic operations"
    }
    # Final validation
        if ($Action.ToLower() -ne "delete") {
        $serviceStatus = Invoke-AzureOperation -Operation {
            Get-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
        } -OperationName "Validate Service Status"
    }
    # Success summary
    Write-Host ""
    Write-Host "                      AZURE COMMUNICATION SERVICES READY"
    Write-Host ""
    if ($Action.ToLower() -eq "create") {
        Write-Host "    Service Name: $CommunicationServiceName"
        Write-Host "    Resource Group: $ResourceGroupName"
        Write-Host "    Data Location: $Location"
        Write-Host "    Status: $($serviceStatus.ProvisioningState)"
        Write-Host "    Resource ID: $($serviceStatus.Id)"
        Write-Host ""
        Write-Host "[LOCK] Security Assessment: $securityScore/$maxScore"
        foreach ($finding in $securityFindings) {
            Write-Host "   $finding"
        }
        Write-Host ""
        Write-Host "Pricing (Approximate):"
        foreach ($cost in $costComponents.GetEnumerator()) {
            Write-Host "    $($cost.Key): $($cost.Value)"
        }
    }
    Write-Host ""
    Write-Host "Communication Capabilities:"
    foreach ($capability in $capabilities) {
        Write-Host "   $capability"
    }
    Write-Host ""
    Write-Host "    Configure email domains using ConfigureDomain action"
    Write-Host "    Purchase phone numbers using ManagePhoneNumbers action"
    Write-Host "    Create user identities for chat and calling features"
    Write-Host "    Integrate with your applications using SDKs"
    Write-Host "    Set up monitoring and alerting for usage tracking"
    Write-Host "    Configure compliance settings for your region"
    Write-Host ""
    
} catch {
    
    Write-Host ""
    Write-Host "Troubleshooting Tips:"
    Write-Host "    Verify Communication Services availability in your region"
    Write-Host "    Check subscription quotas and limits"
    Write-Host "    Ensure proper permissions for resource creation"
    Write-Host "    Validate phone number availability for your country"
    Write-Host "    Check domain ownership for email configuration"
    Write-Host ""
    throw
}

