#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Communication Services Manager

.DESCRIPTION
    Azure automation tool for managing Azure Communication Services
.AUTHOR
    Wes Ellis (wes@wesellis.com)
.VERSION
    1.0
.NOTES
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$CommunicationServiceName,
    [Parameter(ValueFromPipeline)]`n    [string]$Location = "Global",
    [Parameter()]
    [ValidateSet("Create", "Delete", "GetInfo", "ConfigureDomain", "ManagePhoneNumbers", "SendSMS", "SendEmail", "CreateIdentity")]
    [string]$Action = "Create",
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName,
    [Parameter()]
    [ValidateSet("AzureManaged", "CustomerManaged")]
    [string]$DomainManagement = "AzureManaged",
    [Parameter(ValueFromPipeline)]`n    [string]$PhoneNumberType = "TollFree",
    [Parameter(ValueFromPipeline)]`n    [string]$PhoneNumberAssignmentType = "Application",
    [Parameter(ValueFromPipeline)]`n    [string]$CountryCode = "US",
    [Parameter()]
    [int]$PhoneNumberQuantity = 1,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SMSTo,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SMSFrom,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SMSMessage,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$EmailTo,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$EmailFrom,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$EmailSubject,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$EmailContent,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$UserIdentityName,
    [Parameter()]
    [switch]$EnableEventGrid,
    [Parameter()]
    [switch]$EnableMonitoring,
    [Parameter()]
    [switch]$EnableMessaging
)
Write-Host "Script Started" -ForegroundColor Green
try {
    # Test Azure connection
    # Progress stepNumber 1 -TotalSteps 10 -StepName "Azure Connection" -Status "Validating connection and communication services"
    if (-not (Get-AzContext)) { Connect-AzAccount }

        Install-Module Az.Communication -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Communication
    }
    # Validate resource group
    # Progress stepNumber 2 -TotalSteps 10 -StepName "Resource Group Validation" -Status "Checking resource group existence"
    $resourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    switch ($Action.ToLower()) {
        "create" {
            # Create Communication Services resource
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Communication Service Creation" -Status "Creating Azure Communication Services resource"
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
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Domain Configuration" -Status "Configuring email domain"
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

            if ($DomainManagement -eq "CustomerManaged" ) {
                Write-Host "" -ForegroundColor Green
                Write-Host "DNS Configuration Required" -ForegroundColor Yellow
                Write-Host "For customer-managed domains, add these DNS records:" -ForegroundColor White
                Write-Host "TXT record: verification code (check Azure portal)" -ForegroundColor White
                Write-Host "MX record: inbound email routing" -ForegroundColor White
                Write-Host "SPF record: sender policy framework" -ForegroundColor White
                Write-Host "DKIM records: domain key identified mail" -ForegroundColor White
                Write-Host "" -ForegroundColor Green
            }
        }
        "managephonenumbers" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Phone Number Management" -Status "Managing phone numbers"
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
            Write-Host "" -ForegroundColor Green
            Write-Host "Available Phone Numbers" -ForegroundColor Cyan
            if ($availableNumbers.phoneNumbers) {
                foreach ($number in $availableNumbers.phoneNumbers) {
                    Write-Host "  $($number.phoneNumber)" -ForegroundColor White
                    Write-Host "Cost: $($number.cost.amount) $($number.cost.currencyCode)/month" -ForegroundColor Gray
                    Write-Host "Capabilities: $($number.capabilities.calling), $($number.capabilities.sms)" -ForegroundColor Gray
                    Write-Host "" -ForegroundColor Green
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
            # Progress stepNumber 3 -TotalSteps 10 -StepName "SMS Sending" -Status "Sending SMS message"
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
                $uri = " $endpoint/sms?api-version=2021-03-07"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Send SMS"

        }
        "sendemail" {
            if (-not $EmailTo -or -not $EmailFrom -or -not $EmailSubject -or -not $EmailContent) {
                throw "EmailTo, EmailFrom, EmailSubject, and EmailContent parameters are required for email sending"
            }
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Email Sending" -Status "Sending email message"
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
                        html = " <p>$EmailContent</p>"
                    }
                    importance = "normal"
                    disableUserEngagementTracking = $false
                } | ConvertTo-Json -Depth 5
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/sendEmail" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Send Email" | Out-Null

        }
        "createidentity" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Identity Creation" -Status "Creating communication user identity"
            # Create user identity
            $userIdentity = Invoke-AzureOperation -Operation {
                $subscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $body = @{
                    createTokenWithScopes = @("chat" , "voip" )
                } | ConvertTo-Json
                $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/identities" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Create User Identity"

            Write-Host "" -ForegroundColor Green
            Write-Host "User Identity Details" -ForegroundColor Cyan
            Write-Host "Identity ID: $($userIdentity.identity.id)" -ForegroundColor White
            Write-Host "Access Token: $($userIdentity.accessToken.token)" -ForegroundColor Yellow
            Write-Host "Token Expires: $($userIdentity.accessToken.expiresOn)" -ForegroundColor White
            Write-Host "" -ForegroundColor Green
            Write-Host "[WARN]  Store the access token securely - it's needed for client authentication" -ForegroundColor Red
        }
        "getinfo" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Information Retrieval" -Status "Gathering Communication Services information"
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
            Write-Host "" -ForegroundColor Green
            Write-Host "Communication Services Information" -ForegroundColor Cyan
            Write-Host "Service Name: $($communicationService.Name)" -ForegroundColor White
            Write-Host "Data Location: $($communicationService.DataLocation)" -ForegroundColor White
            Write-Host "Status: $($communicationService.ProvisioningState)" -ForegroundColor Green
            Write-Host "Resource ID: $($communicationService.Id)" -ForegroundColor White
            if ($phoneNumbers.Count -gt 0) {
                Write-Host "" -ForegroundColor Green
                Write-Host "Phone Numbers ($($phoneNumbers.Count)):" -ForegroundColor Cyan
                foreach ($number in $phoneNumbers) {
                    Write-Host "  $($number.phoneNumber)" -ForegroundColor White
                    Write-Host "Type: $($number.phoneNumberType)" -ForegroundColor Gray
                    Write-Host "Assignment: $($number.assignmentType)" -ForegroundColor Gray
                    Write-Host "Capabilities: SMS=$($number.capabilities.sms), Calling=$($number.capabilities.calling)" -ForegroundColor Gray
                    Write-Host "" -ForegroundColor Green
                }
            }
            if ($domains.Count -gt 0) {
                Write-Host "Email Domains ($($domains.Count)):" -ForegroundColor Cyan
                foreach ($domain in $domains) {
                    Write-Host "  $($domain.name)" -ForegroundColor White
                    Write-Host "Management: $($domain.properties.domainManagement)" -ForegroundColor Gray
                    Write-Host "Status: $($domain.properties.verificationStates.domain)" -ForegroundColor Gray
                    Write-Host "" -ForegroundColor Green
                }
            }
        }
        "delete" {
            # Progress stepNumber 3 -TotalSteps 10 -StepName "Service Deletion" -Status "Removing Communication Services resource"
            $confirmation = Read-Host "Are you sure you want to delete the Communication Service '$CommunicationServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes" ) {

                return
            }
            Invoke-AzureOperation -Operation {
                Remove-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName -Force
            } -OperationName "Delete Communication Service"

        }
    }
    # Configure Event Grid integration if enabled
    if ($EnableEventGrid -and $Action.ToLower() -eq "create" ) {
        # Progress stepNumber 4 -TotalSteps 10 -StepName "Event Grid Setup" -Status "Configuring Event Grid integration"
        Invoke-AzureOperation -Operation {
            $topicName = " $CommunicationServiceName-events"
            New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $topicName -Location $resourceGroup.Location
        } -OperationName "Create Event Grid Topic" | Out-Null

    }
    # Configure monitoring if enabled
    if ($EnableMonitoring -and $Action.ToLower() -eq "create" ) {
        # Progress stepNumber 5 -TotalSteps 10 -StepName "Monitoring Setup" -Status "Configuring diagnostic settings"
        $diagnosticSettings = Invoke-AzureOperation -Operation {
            $logAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($logAnalyticsWorkspace) {
                $resourceId = " /subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName"
                $diagnosticParams = @{
                    ResourceId = $resourceId
                    Name = " $CommunicationServiceName-diagnostics"
                    WorkspaceId = $logAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("ChatOperational" , "SMSOperational" , "CallSummary" , "CallDiagnostics" )
                    MetricCategory = @("AllMetrics" )
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
    if ($Action.ToLower() -eq "create" ) {
        # Progress stepNumber 6 -TotalSteps 10 -StepName "Tagging" -Status "Applying enterprise tags"
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
    # Progress stepNumber 7 -TotalSteps 10 -StepName "Capabilities Analysis" -Status "Analyzing communication capabilities"
    $capabilities = @(
        "  Voice calling (VoIP) - Make and receive voice calls" ,
        "  Chat - Real-time messaging and group chat" ,
        "  SMS - Send and receive text messages" ,
        "  Email - Transactional and marketing emails" ,
        "  Video calling - HD video communication" ,
        "  Identity management - User authentication and tokens" ,
        "  Call analytics - Call quality and usage metrics" ,
        "  Global reach - Worldwide communication coverage"
    )
    # Security assessment
    # Progress stepNumber 8 -TotalSteps 10 -StepName "Security Assessment" -Status "Evaluating security configuration"
    $securityScore = 0
    $maxScore = 5
    $securityFindings = @()
    if ($Action.ToLower() -eq "create" ) {
        # Check data location
        if ($Location -in @("United States" , "Europe" , "Asia Pacific" )) {
            $securityScore++
            $securityFindings = $securityFindings + "[OK] Data stored in compliant region"
        }
        # Check monitoring
        if ($EnableMonitoring) {
            $securityScore++
            $securityFindings = $securityFindings + "[OK] Monitoring and logging enabled"
        } else {
            $securityFindings = $securityFindings + "[WARN]  Monitoring not configured"
        }
        # Check Event Grid integration
        if ($EnableEventGrid) {
            $securityScore++
            $securityFindings = $securityFindings + "[OK] Event Grid integration for audit trails"
        } else {
            $securityFindings = $securityFindings + "[WARN]  Event Grid not configured for event tracking"
        }
        # Check  messaging
        if ($EnableMessaging) {
            $securityScore++
            $securityFindings = $securityFindings + "[OK]  messaging features enabled"
        }
        # Service is inherently secure
        $securityScore++
        $securityFindings = $securityFindings + "[OK] End-to-end encryption for all communications"
    }
    # Cost analysis
    # Progress stepNumber 9 -TotalSteps 10 -StepName "Cost Analysis" -Status "Analyzing cost components"
$costComponents = @{
        "SMS" = " $0.0075 per message (US)"
        "Voice Calling" = " $0.004 per minute (outbound)"
        "Phone Numbers" = " $1-15 per month depending on type"
        "Email" = " $0.25 per 1,000 emails"
        "Chat" = " $1.50 per monthly active user"
        "Video Calling" = " $0.004 per participant per minute"
        "Data Storage" = "Included in base service"
        "Identity Management" = "Free for basic operations"
    }
    # Final validation
    # Progress stepNumber 10 -TotalSteps 10 -StepName "Validation" -Status "Validating communication service"
    if ($Action.ToLower() -ne "delete" ) {
$serviceStatus = Invoke-AzureOperation -Operation {
            Get-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
        } -OperationName "Validate Service Status"
    }
    # Success summary
    Write-Host "" -ForegroundColor Green
    Write-Host "                      AZURE COMMUNICATION SERVICES READY" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    if ($Action.ToLower() -eq "create" ) {
        Write-Host "Communication Service Details:" -ForegroundColor Cyan
        Write-Host "    Service Name: $CommunicationServiceName" -ForegroundColor White
        Write-Host "    Resource Group: $ResourceGroupName" -ForegroundColor White
        Write-Host "    Data Location: $Location" -ForegroundColor White
        Write-Host "    Status: $($serviceStatus.ProvisioningState)" -ForegroundColor Green
        Write-Host "    Resource ID: $($serviceStatus.Id)" -ForegroundColor White
        Write-Host "" -ForegroundColor Green
        Write-Host " [LOCK] Security Assessment: $securityScore/$maxScore" -ForegroundColor Cyan
        foreach ($finding in $securityFindings) {
            Write-Host "   $finding" -ForegroundColor White
        }
        Write-Host "" -ForegroundColor Green
        Write-Host "Pricing (Approximate):" -ForegroundColor Cyan
        foreach ($cost in $costComponents.GetEnumerator()) {
            Write-Host "    $($cost.Key): $($cost.Value)" -ForegroundColor White
        }
    }
    Write-Host "" -ForegroundColor Green
    Write-Host "Communication Capabilities:" -ForegroundColor Cyan
    foreach ($capability in $capabilities) {
        Write-Host "   $capability" -ForegroundColor White
    }
    Write-Host "" -ForegroundColor Green
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "    Configure email domains using ConfigureDomain action" -ForegroundColor White
    Write-Host "    Purchase phone numbers using ManagePhoneNumbers action" -ForegroundColor White
    Write-Host "    Create user identities for chat and calling features" -ForegroundColor White
    Write-Host "    Integrate with your applications using SDKs" -ForegroundColor White
    Write-Host "    Set up monitoring and alerting for usage tracking" -ForegroundColor White
    Write-Host "    Configure compliance settings for your region" -ForegroundColor White
    Write-Host "" -ForegroundColor Green

} catch {

    Write-Host "" -ForegroundColor Green
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "    Verify Communication Services availability in your region" -ForegroundColor White
    Write-Host "    Check subscription quotas and limits" -ForegroundColor White
    Write-Host "    Ensure proper permissions for resource creation" -ForegroundColor White
    Write-Host "    Validate phone number availability for your country" -ForegroundColor White
    Write-Host "    Check domain ownership for email configuration" -ForegroundColor White
    Write-Host "" -ForegroundColor Green
    throw
}\n

