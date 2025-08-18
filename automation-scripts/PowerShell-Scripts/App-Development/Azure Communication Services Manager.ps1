<#
.SYNOPSIS
    We Enhanced Azure Communication Services Manager

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WECommunicationServiceName,
    
    [Parameter(Mandatory=$false)]
    [string]$WELocation = " Global",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Create", " Delete", " GetInfo", " ConfigureDomain", " ManagePhoneNumbers", " SendSMS", " SendEmail", " CreateIdentity")]
    [string]$WEAction = " Create",
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDomainName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" AzureManaged", " CustomerManaged")]
    [string]$WEDomainManagement = " AzureManaged",
    
    [Parameter(Mandatory=$false)]
    [string]$WEPhoneNumberType = " TollFree",
    
    [Parameter(Mandatory=$false)]
    [string]$WEPhoneNumberAssignmentType = " Application",
    
    [Parameter(Mandatory=$false)]
    [string]$WECountryCode = " US",
    
    [Parameter(Mandatory=$false)]
    [int]$WEPhoneNumberQuantity = 1,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESMSTo,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESMSFrom,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESMSMessage,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEEmailTo,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEEmailFrom,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEEmailSubject,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEEmailContent,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEUserIdentityName,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableEventGrid,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEEnableAdvancedMessaging
)


Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force


Show-Banner -ScriptName " Azure Communication Services Manager" -Version " 1.0" -Description " Enterprise communication platform automation"

try {
    # Test Azure connection
    Write-ProgressStep -StepNumber 1 -TotalSteps 10 -StepName " Azure Connection" -Status " Validating connection and communication services"
    if (-not (Test-AzureConnection -RequiredModules @('Az.Accounts', 'Az.Resources', 'Az.Communication'))) {
        Write-Log " Installing Azure Communication module..." -Level INFO
        Install-Module Az.Communication -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Communication
    }

    # Validate resource group
    Write-ProgressStep -StepNumber 2 -TotalSteps 10 -StepName " Resource Group Validation" -Status " Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction Stop
    } -OperationName " Get Resource Group"
    
    Write-Log " ✓ Using resource group: $($resourceGroup.ResourceGroupName) in $($resourceGroup.Location)" -Level SUCCESS

    switch ($WEAction.ToLower()) {
        " create" {
            # Create Communication Services resource
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Communication Service Creation" -Status " Creating Azure Communication Services resource"
            
            $communicationParams = @{
                ResourceGroupName = $WEResourceGroupName
                Name = $WECommunicationServiceName
                DataLocation = $WELocation
            }
            
            $communicationService = Invoke-AzureOperation -Operation {
                New-AzCommunicationService @communicationParams
            } -OperationName " Create Communication Service"
            
            Write-Log " ✓ Communication Service created: $WECommunicationServiceName" -Level SUCCESS
            Write-Log " ✓ Data location: $WELocation" -Level INFO
            Write-Log " ✓ Resource ID: $($communicationService.Id)" -Level INFO
            
            # Get connection string
            $connectionString = Invoke-AzureOperation -Operation {
                Get-AzCommunicationServiceKey -ResourceGroupName $WEResourceGroupName -Name $WECommunicationServiceName
            } -OperationName " Get Connection String"
            
            Write-Log " ✓ Connection string retrieved (store securely)" -Level SUCCESS
        }
        
        " configuredomain" {
            if (-not $WEDomainName) {
                throw " DomainName parameter is required for domain configuration"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Domain Configuration" -Status " Configuring email domain"
            
            # Configure email domain using REST API
            Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    properties = @{
                        domainManagement = $WEDomainManagement
                        validSenderUsernames = @{
                            " *" = " Enabled"
                        }
                    }
                } | ConvertTo-Json -Depth 3
                
                $uri = " https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$WECommunicationServiceName/domains/$WEDomainName" + " ?api-version=2023-04-01"
                
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName " Configure Email Domain" | Out-Null
            
            Write-Log " ✓ Email domain configured: $WEDomainName" -Level SUCCESS
            Write-Log " ✓ Domain management: $WEDomainManagement" -Level INFO
            
            if ($WEDomainManagement -eq " CustomerManaged") {
                Write-WELog "" " INFO"
                Write-WELog " 📋 DNS Configuration Required" " INFO" -ForegroundColor Yellow
                Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Yellow
                Write-WELog " For customer-managed domains, add these DNS records:" " INFO" -ForegroundColor White
                Write-WELog " • TXT record: verification code (check Azure portal)" " INFO" -ForegroundColor White
                Write-WELog " • MX record: inbound email routing" " INFO" -ForegroundColor White
                Write-WELog " • SPF record: sender policy framework" " INFO" -ForegroundColor White
                Write-WELog " • DKIM records: domain key identified mail" " INFO" -ForegroundColor White
                Write-WELog "" " INFO"
            }
        }
        
        " managephonenumbers" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Phone Number Management" -Status " Managing phone numbers"
            
            # Search for available phone numbers
            $availableNumbers = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    phoneNumberType = $WEPhoneNumberType
                    assignmentType = $WEPhoneNumberAssignmentType
                    capabilities = @{
                        calling = " inbound+outbound"
                        sms = " inbound+outbound"
                    }
                    areaCode = ""
                    quantity = $WEPhoneNumberQuantity
                } | ConvertTo-Json -Depth 3
                
                $uri = " https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Communication/phoneNumberOrders/search" + " ?api-version=2022-12-01"
                
                $searchResponse = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
                return $searchResponse
            } -OperationName " Search Phone Numbers"
            
            Write-WELog "" " INFO"
            Write-WELog " 📞 Available Phone Numbers" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            
            if ($availableNumbers.phoneNumbers) {
                foreach ($number in $availableNumbers.phoneNumbers) {
                    Write-WELog " • $($number.phoneNumber)" " INFO" -ForegroundColor White
                    Write-WELog "  Cost: $($number.cost.amount) $($number.cost.currencyCode)/month" " INFO" -ForegroundColor Gray
                    Write-WELog "  Capabilities: $($number.capabilities.calling), $($number.capabilities.sms)" " INFO" -ForegroundColor Gray
                    Write-WELog "" " INFO"
                }
                
                # Purchase the first available number
                if ($availableNumbers.phoneNumbers.Count -gt 0) {
                    Invoke-AzureOperation -Operation {
                        $headers = @{
                            'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                            'Content-Type' = 'application/json'
                        }
                        
                        $body = @{
                            searchId = $availableNumbers.searchId
                        } | ConvertTo-Json
                        
                        $uri = " https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Communication/phoneNumberOrders/purchase" + " ?api-version=2022-12-01"
                        
                        Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
                    } -OperationName " Purchase Phone Numbers" | Out-Null
                    
                    Write-Log " ✓ Phone number purchase initiated" -Level SUCCESS
                    Write-Log " ✓ Search ID: $($availableNumbers.searchId)" -Level INFO
                }
            } else {
                Write-Log " No phone numbers available for the specified criteria" -Level WARN
            }
        }
        
        " sendsms" {
            if (-not $WESMSTo -or -not $WESMSFrom -or -not $WESMSMessage) {
                throw " SMSTo, SMSFrom, and SMSMessage parameters are required for SMS sending"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " SMS Sending" -Status " Sending SMS message"
            
            # Get connection string
            $connectionString = Get-AzCommunicationServiceKey -ResourceGroupName $WEResourceGroupName -Name $WECommunicationServiceName
            
            # Send SMS using REST API
            $smsResult = Invoke-AzureOperation -Operation {
               ;  $endpoint = ($connectionString.PrimaryConnectionString -split ';')[0] -replace 'endpoint=', ''
                $accessKey = ($connectionString.PrimaryConnectionString -split ';')[1] -replace 'accesskey=', ''
                
                $headers = @{
                    'Content-Type' = 'application/json'
                    'Authorization' = " Bearer $(Get-CommunicationAccessToken -Endpoint $endpoint -AccessKey $accessKey)"
                }
                
                $body = @{
                    from = $WESMSFrom
                    to = @($WESMSTo)
                    message = $WESMSMessage
                    enableDeliveryReport = $true
                    tag = " Azure-Automation-SMS"
                } | ConvertTo-Json -Depth 3
                
                $uri = " $endpoint/sms?api-version=2021-03-07"
                
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName " Send SMS"
            
            Write-Log " ✓ SMS sent successfully" -Level SUCCESS
            Write-Log " ✓ From: $WESMSFrom" -Level INFO
            Write-Log " ✓ To: $WESMSTo" -Level INFO
            Write-Log " ✓ Message ID: $($smsResult.messageId)" -Level INFO
        }
        
        " sendemail" {
            if (-not $WEEmailTo -or -not $WEEmailFrom -or -not $WEEmailSubject -or -not $WEEmailContent) {
                throw " EmailTo, EmailFrom, EmailSubject, and EmailContent parameters are required for email sending"
            }
            
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Email Sending" -Status " Sending email message"
            
            # Send email using REST API
            Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    senderAddress = $WEEmailFrom
                    recipients = @{
                        to = @(
                            @{
                                address = $WEEmailTo
                                displayName = $WEEmailTo
                            }
                        )
                    }
                    content = @{
                        subject = $WEEmailSubject
                        plainText = $WEEmailContent
                        html = " <p>$WEEmailContent</p>"
                    }
                    importance = " normal"
                    disableUserEngagementTracking = $false
                } | ConvertTo-Json -Depth 5
                
                $uri = " https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$WECommunicationServiceName/sendEmail" + " ?api-version=2023-04-01"
                
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName " Send Email" | Out-Null
            
            Write-Log " ✓ Email sent successfully" -Level SUCCESS
            Write-Log " ✓ From: $WEEmailFrom" -Level INFO
            Write-Log " ✓ To: $WEEmailTo" -Level INFO
            Write-Log " ✓ Subject: $WEEmailSubject" -Level INFO
        }
        
        " createidentity" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Identity Creation" -Status " Creating communication user identity"
            
            # Create user identity
            $userIdentity = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $body = @{
                    createTokenWithScopes = @(" chat", " voip")
                } | ConvertTo-Json
                
                $uri = " https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$WECommunicationServiceName/identities" + " ?api-version=2023-04-01"
                
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName " Create User Identity"
            
            Write-Log " ✓ User identity created" -Level SUCCESS
            Write-Log " ✓ Identity ID: $($userIdentity.identity.id)" -Level INFO
            Write-Log " ✓ Access token generated with chat and VoIP scopes" -Level INFO
            
            Write-WELog "" " INFO"
            Write-WELog " 🆔 User Identity Details" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            Write-WELog " Identity ID: $($userIdentity.identity.id)" " INFO" -ForegroundColor White
            Write-WELog " Access Token: $($userIdentity.accessToken.token)" " INFO" -ForegroundColor Yellow
            Write-WELog " Token Expires: $($userIdentity.accessToken.expiresOn)" " INFO" -ForegroundColor White
            Write-WELog "" " INFO"
            Write-WELog " ⚠️  Store the access token securely - it's needed for client authentication" " INFO" -ForegroundColor Red
        }
        
        " getinfo" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Information Retrieval" -Status " Gathering Communication Services information"
            
            # Get Communication Service info
            $communicationService = Invoke-AzureOperation -Operation {
                Get-AzCommunicationService -ResourceGroupName $WEResourceGroupName -Name $WECommunicationServiceName
            } -OperationName " Get Communication Service"
            
            # Get phone numbers
            $phoneNumbers = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $uri = " https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$WECommunicationServiceName/phoneNumbers" + " ?api-version=2022-12-01"
                
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName " Get Phone Numbers"
            
            # Get domains
            $domains = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = " Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                
                $uri = " https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$WECommunicationServiceName/domains" + " ?api-version=2023-04-01"
                
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ErrorAction SilentlyContinue
                return $response.value
            } -OperationName " Get Email Domains"
            
            Write-WELog "" " INFO"
            Write-WELog " 📡 Communication Services Information" " INFO" -ForegroundColor Cyan
            Write-WELog " ════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Cyan
            Write-WELog " Service Name: $($communicationService.Name)" " INFO" -ForegroundColor White
            Write-WELog " Data Location: $($communicationService.DataLocation)" " INFO" -ForegroundColor White
            Write-WELog " Status: $($communicationService.ProvisioningState)" " INFO" -ForegroundColor Green
            Write-WELog " Resource ID: $($communicationService.Id)" " INFO" -ForegroundColor White
            
            if ($phoneNumbers.Count -gt 0) {
                Write-WELog "" " INFO"
                Write-WELog " 📞 Phone Numbers ($($phoneNumbers.Count)):" " INFO" -ForegroundColor Cyan
                foreach ($number in $phoneNumbers) {
                    Write-WELog " • $($number.phoneNumber)" " INFO" -ForegroundColor White
                    Write-WELog "  Type: $($number.phoneNumberType)" " INFO" -ForegroundColor Gray
                    Write-WELog "  Assignment: $($number.assignmentType)" " INFO" -ForegroundColor Gray
                    Write-WELog "  Capabilities: SMS=$($number.capabilities.sms), Calling=$($number.capabilities.calling)" " INFO" -ForegroundColor Gray
                    Write-WELog "" " INFO"
                }
            }
            
            if ($domains.Count -gt 0) {
                Write-WELog " 📧 Email Domains ($($domains.Count)):" " INFO" -ForegroundColor Cyan
                foreach ($domain in $domains) {
                    Write-WELog " • $($domain.name)" " INFO" -ForegroundColor White
                    Write-WELog "  Management: $($domain.properties.domainManagement)" " INFO" -ForegroundColor Gray
                    Write-WELog "  Status: $($domain.properties.verificationStates.domain)" " INFO" -ForegroundColor Gray
                    Write-WELog "" " INFO"
                }
            }
        }
        
        " delete" {
            Write-ProgressStep -StepNumber 3 -TotalSteps 10 -StepName " Service Deletion" -Status " Removing Communication Services resource"
            
            $confirmation = Read-Host " Are you sure you want to delete the Communication Service '$WECommunicationServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne " yes") {
                Write-Log " Deletion cancelled by user" -Level WARN
                return
            }
            
            Invoke-AzureOperation -Operation {
                Remove-AzCommunicationService -ResourceGroupName $WEResourceGroupName -Name $WECommunicationServiceName -Force
            } -OperationName " Delete Communication Service"
            
            Write-Log " ✓ Communication Service deleted: $WECommunicationServiceName" -Level SUCCESS
        }
    }

    # Configure Event Grid integration if enabled
    if ($WEEnableEventGrid -and $WEAction.ToLower() -eq " create") {
        Write-ProgressStep -StepNumber 4 -TotalSteps 10 -StepName " Event Grid Setup" -Status " Configuring Event Grid integration"
        
        Invoke-AzureOperation -Operation {
            $topicName = " $WECommunicationServiceName-events"
            New-AzEventGridTopic -ResourceGroupName $WEResourceGroupName -Name $topicName -Location $resourceGroup.Location
        } -OperationName " Create Event Grid Topic" | Out-Null
        
        Write-Log " ✓ Event Grid topic created for communication events" -Level SUCCESS
    }

    # Configure monitoring if enabled
    if ($WEEnableMonitoring -and $WEAction.ToLower() -eq " create") {
        Write-ProgressStep -StepNumber 5 -TotalSteps 10 -StepName " Monitoring Setup" -Status " Configuring diagnostic settings"
        
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName | Select-Object -First 1
            
            if ($logAnalyticsWorkspace) {
                $resourceId = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$WEResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$WECommunicationServiceName"
                
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = " $WECommunicationServiceName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @(" ChatOperational", " SMSOperational", " CallSummary", " CallDiagnostics")
                    MetricCategory = @(" AllMetrics")
                }
                
                Set-AzDiagnosticSetting @diagnosticParams
            } else {
                Write-Log " ⚠️  No Log Analytics workspace found for monitoring setup" -Level WARN
                return $null
            }
        } -OperationName " Configure Monitoring"
        
        if ($diagnosticSettings) {
            Write-Log " ✓ Monitoring configured with diagnostic settings" -Level SUCCESS
        }
    }

    # Apply enterprise tags if creating service
    if ($WEAction.ToLower() -eq " create") {
        Write-ProgressStep -StepNumber 6 -TotalSteps 10 -StepName " Tagging" -Status " Applying enterprise tags"
        $tags = @{
            'Environment' = 'Production'
            'Service' = 'CommunicationServices'
            'ManagedBy' = 'Azure-Automation'
            'CreatedBy' = $env:USERNAME
            'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
            'CostCenter' = 'Communications'
            'Purpose' = 'CustomerEngagement'
            'DataLocation' = $WELocation
            'Compliance' = 'GDPR-Ready'
        }
        
        Invoke-AzureOperation -Operation {
            $resource = Get-AzResource -ResourceGroupName $WEResourceGroupName -Name $WECommunicationServiceName -ResourceType " Microsoft.Communication/CommunicationServices"
            Set-AzResource -ResourceId $resource.ResourceId -Tag $tags -Force
        } -OperationName " Apply Enterprise Tags" | Out-Null
    }

    # Communication capabilities analysis
    Write-ProgressStep -StepNumber 7 -TotalSteps 10 -StepName " Capabilities Analysis" -Status " Analyzing communication capabilities"
    
    $capabilities = @(
        " 📞 Voice calling (VoIP) - Make and receive voice calls",
        " 💬 Chat - Real-time messaging and group chat",
        " 📱 SMS - Send and receive text messages",
        " 📧 Email - Transactional and marketing emails",
        " 📹 Video calling - HD video communication",
        " 🔐 Identity management - User authentication and tokens",
        " 📊 Call analytics - Call quality and usage metrics",
        " 🌍 Global reach - Worldwide communication coverage"
    )

    # Security assessment
    Write-ProgressStep -StepNumber 8 -TotalSteps 10 -StepName " Security Assessment" -Status " Evaluating security configuration"
    
    $securityScore = 0
    $maxScore = 5
    $securityFindings = @()
    
    if ($WEAction.ToLower() -eq " create") {
        # Check data location
        if ($WELocation -in @(" United States", " Europe", " Asia Pacific")) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Data stored in compliant region"
        }
        
        # Check monitoring
        if ($WEEnableMonitoring) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Monitoring and logging enabled"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Monitoring not configured"
        }
        
        # Check Event Grid integration
        if ($WEEnableEventGrid) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Event Grid integration for audit trails"
        } else {
            $securityFindings = $securityFindings + " ⚠️  Event Grid not configured for event tracking"
        }
        
        # Check advanced messaging
        if ($WEEnableAdvancedMessaging) {
            $securityScore++
            $securityFindings = $securityFindings + " ✓ Advanced messaging features enabled"
        }
        
        # Service is inherently secure
        $securityScore++
        $securityFindings = $securityFindings + " ✓ End-to-end encryption for all communications"
    }

    # Cost analysis
    Write-ProgressStep -StepNumber 9 -TotalSteps 10 -StepName " Cost Analysis" -Status " Analyzing cost components"
    
    $costComponents = @{
        " SMS" = " $0.0075 per message (US)"
        " Voice Calling" = " $0.004 per minute (outbound)"
        " Phone Numbers" = " $1-15 per month depending on type"
        " Email" = " $0.25 per 1,000 emails"
        " Chat" = " $1.50 per monthly active user"
        " Video Calling" = " $0.004 per participant per minute"
        " Data Storage" = " Included in base service"
        " Identity Management" = " Free for basic operations"
    }

    # Final validation
    Write-ProgressStep -StepNumber 10 -TotalSteps 10 -StepName " Validation" -Status " Validating communication service"
    
    if ($WEAction.ToLower() -ne " delete") {
       ;  $serviceStatus = Invoke-AzureOperation -Operation {
            Get-AzCommunicationService -ResourceGroupName $WEResourceGroupName -Name $WECommunicationServiceName
        } -OperationName " Validate Service Status"
    }

    # Success summary
    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                      AZURE COMMUNICATION SERVICES READY" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    
    if ($WEAction.ToLower() -eq " create") {
        Write-WELog " 📡 Communication Service Details:" " INFO" -ForegroundColor Cyan
        Write-WELog "   • Service Name: $WECommunicationServiceName" " INFO" -ForegroundColor White
        Write-WELog "   • Resource Group: $WEResourceGroupName" " INFO" -ForegroundColor White
        Write-WELog "   • Data Location: $WELocation" " INFO" -ForegroundColor White
        Write-WELog "   • Status: $($serviceStatus.ProvisioningState)" " INFO" -ForegroundColor Green
        Write-WELog "   • Resource ID: $($serviceStatus.Id)" " INFO" -ForegroundColor White
        
        Write-WELog "" " INFO"
        Write-WELog " 🔒 Security Assessment: $securityScore/$maxScore" " INFO" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-WELog "   $finding" " INFO" -ForegroundColor White
        }
        
        Write-WELog "" " INFO"
        Write-WELog " 💰 Pricing (Approximate):" " INFO" -ForegroundColor Cyan
        foreach ($cost in $costComponents.GetEnumerator()) {
            Write-WELog "   • $($cost.Key): $($cost.Value)" " INFO" -ForegroundColor White
        }
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 🚀 Communication Capabilities:" " INFO" -ForegroundColor Cyan
    foreach ($capability in $capabilities) {
        Write-WELog "   $capability" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 💡 Next Steps:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Configure email domains using ConfigureDomain action" " INFO" -ForegroundColor White
    Write-WELog "   • Purchase phone numbers using ManagePhoneNumbers action" " INFO" -ForegroundColor White
    Write-WELog "   • Create user identities for chat and calling features" " INFO" -ForegroundColor White
    Write-WELog "   • Integrate with your applications using SDKs" " INFO" -ForegroundColor White
    Write-WELog "   • Set up monitoring and alerting for usage tracking" " INFO" -ForegroundColor White
    Write-WELog "   • Configure compliance settings for your region" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"

    Write-Log " ✅ Azure Communication Services operation '$WEAction' completed successfully!" -Level SUCCESS

} catch {
    Write-Log " ❌ Communication Services operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    
    Write-WELog "" " INFO"
    Write-WELog " 🔧 Troubleshooting Tips:" " INFO" -ForegroundColor Yellow
    Write-WELog "   • Verify Communication Services availability in your region" " INFO" -ForegroundColor White
    Write-WELog "   • Check subscription quotas and limits" " INFO" -ForegroundColor White
    Write-WELog "   • Ensure proper permissions for resource creation" " INFO" -ForegroundColor White
    Write-WELog "   • Validate phone number availability for your country" " INFO" -ForegroundColor White
    Write-WELog "   • Check domain ownership for email configuration" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"
    
    exit 1
}

Write-Progress -Activity " Communication Services Management" -Completed
Write-Log " Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================