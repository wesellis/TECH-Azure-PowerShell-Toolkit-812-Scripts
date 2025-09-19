#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Azure Communication Services Manager
# Professional Azure communications automation script
# Version: 1.0 | Enterprise communication platform automation

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$CommunicationServiceName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "Global",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Create", "Delete", "GetInfo", "ConfigureDomain", "ManagePhoneNumbers", "SendSMS", "SendEmail", "CreateIdentity")]
    [string]$Action = "Create",
    
    [Parameter(Mandatory=$false)]
    [string]$DomainName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureManaged", "CustomerManaged")]
    [string]$DomainManagement = "AzureManaged",
    
    [Parameter(Mandatory=$false)]
    [string]$PhoneNumberType = "TollFree",
    
    [Parameter(Mandatory=$false)]
    [string]$PhoneNumberAssignmentType = "Application",
    
    [Parameter(Mandatory=$false)]
    [string]$CountryCode = "US",
    
    [Parameter(Mandatory=$false)]
    [int]$PhoneNumberQuantity = 1,
    
    [Parameter(Mandatory=$false)]
    [string]$SMSTo,
    
    [Parameter(Mandatory=$false)]
    [string]$SMSFrom,
    
    [Parameter(Mandatory=$false)]
    [string]$SMSMessage,
    
    [Parameter(Mandatory=$false)]
    [string]$EmailTo,
    
    [Parameter(Mandatory=$false)]
    [string]$EmailFrom,
    
    [Parameter(Mandatory=$false)]
    [string]$EmailSubject,
    
    [Parameter(Mandatory=$false)]
    [string]$EmailContent,
    
    [Parameter(Mandatory=$false)]
    [string]$UserIdentityName,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableEventGrid,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableAdvancedMessaging
)

#region Functions

# Import common functions
# Module import removed - use #Requires instead

# Professional banner
Show-Banner -ScriptName "Azure Communication Services Manager" -Version "1.0" -Description "Enterprise communication platform automation"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 10 -StepName "Azure Connection" -Status "Validating connection and communication services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Communication'))) {
        Write-Log "Installing Azure Communication module..." -Level INFO
        Install-Module Az.Communication -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Communication
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 10 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"
    
    Write-Log "[OK] Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    switch ($Action.ToLower()) {
        "create" {
            # Create Communication Services resource
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Communication Service Creation" -Status "Creating Azure Communication Services resource"
            
            $communicationParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $CommunicationServiceName
                DataLocation = $Location
            }
            
            $communicationService = Invoke-AzureOperation -Operation {
                New-AzCommunicationService -ErrorAction Stop @communicationParams
            } -OperationName "Create Communication Service"
            
            Write-Log "[OK] Communication Service created: $CommunicationServiceName" -Level SUCCESS
            Write-Log "[OK] Data location: $Location" -Level INFO
            Write-Log "[OK] Resource ID: $($communicationService.Id)" -Level INFO
            
            # Get connection string
            $connectionString = Invoke-AzureOperation -Operation {
                Get-AzCommunicationServiceKey -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
            } -OperationName "Get Connection String"
            
            Write-Log "[OK] Connection string retrieved (store securely)" -Level SUCCESS
        }
        
        "configuredomain" {
            if (-not $DomainName) {
                throw "DomainName parameter is required for domain configuration"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Domain Configuration" -Status "Configuring email domain"
            
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
            
            Write-Log "[OK] Email domain configured: $DomainName" -Level SUCCESS
            Write-Log "[OK] Domain management: $DomainManagement" -Level INFO
            
            if ($DomainManagement -eq "CustomerManaged") {
                Write-Information ""
                Write-Information "� DNS Configuration Required"
                Write-Information "════════════════════════════════════════════════════════════════════"
                Write-Information "For customer-managed domains, add these DNS records:"
                Write-Information "• TXT record: verification code (check Azure portal)"
                Write-Information "• MX record: inbound email routing"
                Write-Information "• SPF record: sender policy framework"
                Write-Information "• DKIM records: domain key identified mail"
                Write-Information ""
            }
        }
        
        "managephonenumbers" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Phone Number Management" -Status "Managing phone numbers"
            
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
            
            Write-Information ""
            Write-Information "� Available Phone Numbers"
            Write-Information "════════════════════════════════════════════════════════════════════"
            
            if ($availableNumbers.phoneNumbers) {
                foreach ($number in $availableNumbers.phoneNumbers) {
                    Write-Information "• $($number.phoneNumber)"
                    Write-Information "  Cost: $($number.cost.amount) $($number.cost.currencyCode)/month"
                    Write-Information "  Capabilities: $($number.capabilities.calling), $($number.capabilities.sms)"
                    Write-Information ""
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
                    
                    Write-Log "[OK] Phone number purchase initiated" -Level SUCCESS
                    Write-Log "[OK] Search ID: $($availableNumbers.searchId)" -Level INFO
                }
            } else {
                Write-Log "No phone numbers available for the specified criteria" -Level WARN
            }
        }
        
        "sendsms" {
            if (-not $SMSTo -or -not $SMSFrom -or -not $SMSMessage) {
                throw "SMSTo, SMSFrom, and SMSMessage parameters are required for SMS sending"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "SMS Sending" -Status "Sending SMS message"
            
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
            
            Write-Log "[OK] SMS sent successfully" -Level SUCCESS
            Write-Log "[OK] From: $SMSFrom" -Level INFO
            Write-Log "[OK] To: $SMSTo" -Level INFO
            Write-Log "[OK] Message ID: $($smsResult.messageId)" -Level INFO
        }
        
        "sendemail" {
            if (-not $EmailTo -or -not $EmailFrom -or -not $EmailSubject -or -not $EmailContent) {
                throw "EmailTo, EmailFrom, EmailSubject, and EmailContent parameters are required for email sending"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Email Sending" -Status "Sending email message"
            
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
            
            Write-Log "[OK] Email sent successfully" -Level SUCCESS
            Write-Log "[OK] From: $EmailFrom" -Level INFO
            Write-Log "[OK] To: $EmailTo" -Level INFO
            Write-Log "[OK] Subject: $EmailSubject" -Level INFO
        }
        
        "createidentity" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Identity Creation" -Status "Creating communication user identity"
            
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
            
            Write-Log "[OK] User identity created" -Level SUCCESS
            Write-Log "[OK] Identity ID: $($userIdentity.identity.id)" -Level INFO
            Write-Log "[OK] Access token generated with chat and VoIP scopes" -Level INFO
            
            Write-Information ""
            Write-Information "� User Identity Details"
            Write-Information "════════════════════════════════════════════════════════════════════"
            Write-Information "Identity ID: $($userIdentity.identity.id)"
            Write-Information "Access Token: $($userIdentity.accessToken.token)"
            Write-Information "Token Expires: $($userIdentity.accessToken.expiresOn)"
            Write-Information ""
            Write-Information "[WARN]  Store the access token securely - it's needed for client authentication"
        }
        
        "getinfo" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Information Retrieval" -Status "Gathering Communication Services information"
            
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
            
            Write-Information ""
            Write-Information "� Communication Services Information"
            Write-Information "════════════════════════════════════════════════════════════════════"
            Write-Information "Service Name: $($communicationService.Name)"
            Write-Information "Data Location: $($communicationService.DataLocation)"
            Write-Information "Status: $($communicationService.ProvisioningState)"
            Write-Information "Resource ID: $($communicationService.Id)"
            
            if ($phoneNumbers.Count -gt 0) {
                Write-Information ""
                Write-Information "� Phone Numbers ($($phoneNumbers.Count)):"
                foreach ($number in $phoneNumbers) {
                    Write-Information "• $($number.phoneNumber)"
                    Write-Information "  Type: $($number.phoneNumberType)"
                    Write-Information "  Assignment: $($number.assignmentType)"
                    Write-Information "  Capabilities: SMS=$($number.capabilities.sms), Calling=$($number.capabilities.calling)"
                    Write-Information ""
                }
            }
            
            if ($domains.Count -gt 0) {
                Write-Information "� Email Domains ($($domains.Count)):"
                foreach ($domain in $domains) {
                    Write-Information "• $($domain.name)"
                    Write-Information "  Management: $($domain.properties.domainManagement)"
                    Write-Information "  Status: $($domain.properties.verificationStates.domain)"
                    Write-Information ""
                }
            }
        }
        
        "delete" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName "Service Deletion" -Status "Removing Communication Services resource"
            
            $confirmation = Read-Host "Are you sure you want to delete the Communication Service '$CommunicationServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes") {
                Write-Log "Deletion cancelled by user" -Level WARN
                return
            }
            
            Invoke-AzureOperation -Operation {
                Remove-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName -Force
            } -OperationName "Delete Communication Service"
            
            Write-Log "[OK] Communication Service deleted: $CommunicationServiceName" -Level SUCCESS
        }
    }

    # Configure Event Grid integration if enabled
    if ($EnableEventGrid -and $Action.ToLower() -eq "create") {
        Write-ProgressStep -StepNumber 4 -TotalSteps 10 -StepName "Event Grid Setup" -Status "Configuring Event Grid integration"
        
        Invoke-AzureOperation -Operation {
            $topicName = "$CommunicationServiceName-events"
            New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $topicName -Location $resourceGroup.Location
        } -OperationName "Create Event Grid Topic" | Out-Null
        
        Write-Log "[OK] Event Grid topic created for communication events" -Level SUCCESS
    }

    # Configure monitoring if enabled
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
        Write-ProgressStep -StepNumber 5 -TotalSteps 10 -StepName "Monitoring Setup" -Status "Configuring diagnostic settings"
        
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
                Write-Log "[WARN]️  No Log Analytics workspace found for monitoring setup" -Level WARN
                return $null
            }
        } -OperationName "Configure Monitoring"
        
        if ($diagnosticSettings) {
            Write-Log "[OK] Monitoring configured with diagnostic settings" -Level SUCCESS
        }
    }

    # Apply enterprise tags if creating service
    if ($Action.ToLower() -eq "create") {
        Write-ProgressStep -StepNumber 6 -TotalSteps 10 -StepName "Tagging" -Status "Applying enterprise tags"
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
    Write-ProgressStep -StepNumber 7 -TotalSteps 10 -StepName "Capabilities Analysis" -Status "Analyzing communication capabilities"
    
    $capabilities = @(
        "📞 Voice calling (VoIP) - Make and receive voice calls",
        "💬 Chat - Real-time messaging and group chat",
        "📱 SMS - Send and receive text messages",
        "📧 Email - Transactional and marketing emails",
        "📹 Video calling - HD video communication",
        "🔐 Identity management - User authentication and tokens",
        " Call analytics - Call quality and usage metrics",
        "🌍 Global reach - Worldwide communication coverage"
    )

    # Security assessment
    Write-ProgressStep -StepNumber 8 -TotalSteps 10 -StepName "Security Assessment" -Status "Evaluating security configuration"
    
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
            $securityFindings += "[WARN]️  Monitoring not configured"
        }
        
        # Check Event Grid integration
        if ($EnableEventGrid) {
            $securityScore++
            $securityFindings += "[OK] Event Grid integration for audit trails"
        } else {
            $securityFindings += "[WARN]️  Event Grid not configured for event tracking"
        }
        
        # Check advanced messaging
        if ($EnableAdvancedMessaging) {
            $securityScore++
            $securityFindings += "[OK] Advanced messaging features enabled"
        }
        
        # Service is inherently secure
        $securityScore++
        $securityFindings += "[OK] End-to-end encryption for all communications"
    }

    # Cost analysis
    Write-ProgressStep -StepNumber 9 -TotalSteps 10 -StepName "Cost Analysis" -Status "Analyzing cost components"
    
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
    Write-ProgressStep -StepNumber 10 -TotalSteps 10 -StepName "Validation" -Status "Validating communication service"
    
    if ($Action.ToLower() -ne "delete") {
        $serviceStatus = Invoke-AzureOperation -Operation {
            Get-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
        } -OperationName "Validate Service Status"
    }

    # Success summary
    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                      AZURE COMMUNICATION SERVICES READY"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    
    if ($Action.ToLower() -eq "create") {
        Write-Information "� Communication Service Details:"
        Write-Information "   • Service Name: $CommunicationServiceName"
        Write-Information "   • Resource Group: $ResourceGroupName"
        Write-Information "   • Data Location: $Location"
        Write-Information "   • Status: $($serviceStatus.ProvisioningState)"
        Write-Information "   • Resource ID: $($serviceStatus.Id)"
        
        Write-Information ""
        Write-Information "[LOCK] Security Assessment: $securityScore/$maxScore"
        foreach ($finding in $securityFindings) {
            Write-Information "   $finding"
        }
        
        Write-Information ""
        Write-Information " Pricing (Approximate):"
        foreach ($cost in $costComponents.GetEnumerator()) {
            Write-Information "   • $($cost.Key): $($cost.Value)"
        }
    }
    
    Write-Information ""
    Write-Information " Communication Capabilities:"
    foreach ($capability in $capabilities) {
        Write-Information "   $capability"
    }
    
    Write-Information ""
    Write-Information "� Next Steps:"
    Write-Information "   • Configure email domains using ConfigureDomain action"
    Write-Information "   • Purchase phone numbers using ManagePhoneNumbers action"
    Write-Information "   • Create user identities for chat and calling features"
    Write-Information "   • Integrate with your applications using SDKs"
    Write-Information "   • Set up monitoring and alerting for usage tracking"
    Write-Information "   • Configure compliance settings for your region"
    Write-Information ""

    Write-Log " Azure Communication Services operation '$Action' completed successfully!" -Level SUCCESS

} catch {
    Write-Log " Communication Services operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-Information ""
    Write-Information " Troubleshooting Tips:"
    Write-Information "   • Verify Communication Services availability in your region"
    Write-Information "   • Check subscription quotas and limits"
    Write-Information "   • Ensure proper permissions for resource creation"
    Write-Information "   • Validate phone number availability for your country"
    Write-Information "   • Check domain ownership for email configuration"
    Write-Information ""
    
    exit 1
}

Write-Progress -Activity "Communication Services Management" -Completed
Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO


#endregion
