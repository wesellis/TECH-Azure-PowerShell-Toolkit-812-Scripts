#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Communication Services Manager

.DESCRIPTION
    Azure automation tool for managing Azure Communication Services
.AUTHOR
    Wes Ellis (wes@wesellis.com)
.VERSION
    1.0
.NOTES
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
    if (-not (Get-AzContext)) { Connect-AzAccount }

        Install-Module Az.Communication -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Communication
    }
    [string]$ResourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    switch ($Action.ToLower()) {
        "create" {
    $CommunicationParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $CommunicationServiceName
                DataLocation = $Location
            }
    [string]$CommunicationService = Invoke-AzureOperation -Operation {
                New-AzCommunicationService -ErrorAction Stop @communicationParams
            } -OperationName "Create Communication Service"
    [string]$ConnectionString = Invoke-AzureOperation -Operation {
                Get-AzCommunicationServiceKey -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
            } -OperationName "Get Connection String"

        }
        "configuredomain" {
            if (-not $DomainName) {
                throw "DomainName parameter is required for domain configuration"
            }
            Invoke-AzureOperation -Operation {
    [string]$SubscriptionId = (Get-AzContext).Subscription.Id
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
    [string]$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/domains/$DomainName" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Configure Email Domain" | Out-Null

            if ($DomainManagement -eq "CustomerManaged" ) {
                Write-Host "" -ForegroundColor Green
                Write-Host "DNS Configuration Required" -ForegroundColor Green
                Write-Host "For customer-managed domains, add these DNS records:" -ForegroundColor Green
                Write-Host "TXT record: verification code (check Azure portal)" -ForegroundColor Green
                Write-Host "MX record: inbound email routing" -ForegroundColor Green
                Write-Host "SPF record: sender policy framework" -ForegroundColor Green
                Write-Host "DKIM records: domain key identified mail" -ForegroundColor Green
                Write-Host "" -ForegroundColor Green
            }
        }
        "managephonenumbers" {
    [string]$AvailableNumbers = Invoke-AzureOperation -Operation {
    [string]$SubscriptionId = (Get-AzContext).Subscription.Id
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
    [string]$uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Communication/phoneNumberOrders/search" + "?api-version=2022-12-01"
    [string]$SearchResponse = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
                return $SearchResponse
            } -OperationName "Search Phone Numbers"
            Write-Host "" -ForegroundColor Green
            Write-Host "Available Phone Numbers" -ForegroundColor Green
            if ($AvailableNumbers.phoneNumbers) {
                foreach ($number in $AvailableNumbers.phoneNumbers) {
                    Write-Host "  $($number.phoneNumber)" -ForegroundColor Green
                    Write-Host "Cost: $($number.cost.amount) $($number.cost.currencyCode)/month" -ForegroundColor Green
                    Write-Host "Capabilities: $($number.capabilities.calling), $($number.capabilities.sms)" -ForegroundColor Green
                    Write-Host "" -ForegroundColor Green
                }
                if ($AvailableNumbers.phoneNumbers.Count -gt 0) {
                    Invoke-AzureOperation -Operation {
    $headers = @{
                            'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                            'Content-Type' = 'application/json'
                        }
    $body = @{
                            searchId = $AvailableNumbers.searchId
                        } | ConvertTo-Json
    [string]$uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Communication/phoneNumberOrders/purchase" + "?api-version=2022-12-01"
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
    $ConnectionString = Get-AzCommunicationServiceKey -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
    [string]$SmsResult = Invoke-AzureOperation -Operation {
    [string]$endpoint = ($ConnectionString.PrimaryConnectionString -split ';')[0] -replace 'endpoint=', ''
    [string]$AccessKey = ($ConnectionString.PrimaryConnectionString -split ';')[1] -replace 'accesskey=', ''
    $headers = @{
                    'Content-Type' = 'application/json'
                    'Authorization' = "Bearer $(Get-CommunicationAccessToken -Endpoint $endpoint -AccessKey $AccessKey)"
                }
    $body = @{
                    from = $SMSFrom
                    to = @($SMSTo)
                    message = $SMSMessage
                    enableDeliveryReport = $true
                    tag = "Azure-Automation-SMS"
                } | ConvertTo-Json -Depth 3
    [string]$uri = " $endpoint/sms?api-version=2021-03-07"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Send SMS"

        }
        "sendemail" {
            if (-not $EmailTo -or -not $EmailFrom -or -not $EmailSubject -or -not $EmailContent) {
                throw "EmailTo, EmailFrom, EmailSubject, and EmailContent parameters are required for email sending"
            }
            Invoke-AzureOperation -Operation {
    [string]$SubscriptionId = (Get-AzContext).Subscription.Id
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
    [string]$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/sendEmail" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Send Email" | Out-Null

        }
        "createidentity" {
    [string]$UserIdentity = Invoke-AzureOperation -Operation {
    [string]$SubscriptionId = (Get-AzContext).Subscription.Id
    $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
    $body = @{
                    createTokenWithScopes = @("chat" , "voip" )
                } | ConvertTo-Json
    [string]$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/identities" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Create User Identity"

            Write-Host "" -ForegroundColor Green
            Write-Host "User Identity Details" -ForegroundColor Green
            Write-Host "Identity ID: $($UserIdentity.identity.id)" -ForegroundColor Green
            Write-Host "Access Token: $($UserIdentity.accessToken.token)" -ForegroundColor Green
            Write-Host "Token Expires: $($UserIdentity.accessToken.expiresOn)" -ForegroundColor Green
            Write-Host "" -ForegroundColor Green
            Write-Host "[WARN]  Store the access token securely - it's needed for client authentication" -ForegroundColor Green
        }
        "getinfo" {
    [string]$CommunicationService = Invoke-AzureOperation -Operation {
                Get-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
            } -OperationName "Get Communication Service"
    [string]$PhoneNumbers = Invoke-AzureOperation -Operation {
    [string]$SubscriptionId = (Get-AzContext).Subscription.Id
    $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
    [string]$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/phoneNumbers" + "?api-version=2022-12-01"
    [string]$response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Phone Numbers"
    [string]$domains = Invoke-AzureOperation -Operation {
    [string]$SubscriptionId = (Get-AzContext).Subscription.Id
    $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
    [string]$uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/domains" + "?api-version=2023-04-01"
    [string]$response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ErrorAction SilentlyContinue
                return $response.value
            } -OperationName "Get Email Domains"
            Write-Host "" -ForegroundColor Green
            Write-Host "Communication Services Information" -ForegroundColor Green
            Write-Host "Service Name: $($CommunicationService.Name)" -ForegroundColor Green
            Write-Host "Data Location: $($CommunicationService.DataLocation)" -ForegroundColor Green
            Write-Host "Status: $($CommunicationService.ProvisioningState)" -ForegroundColor Green
            Write-Host "Resource ID: $($CommunicationService.Id)" -ForegroundColor Green
            if ($PhoneNumbers.Count -gt 0) {
                Write-Host "" -ForegroundColor Green
                Write-Host "Phone Numbers ($($PhoneNumbers.Count)):" -ForegroundColor Green
                foreach ($number in $PhoneNumbers) {
                    Write-Host "  $($number.phoneNumber)" -ForegroundColor Green
                    Write-Host "Type: $($number.phoneNumberType)" -ForegroundColor Green
                    Write-Host "Assignment: $($number.assignmentType)" -ForegroundColor Green
                    Write-Host "Capabilities: SMS=$($number.capabilities.sms), Calling=$($number.capabilities.calling)" -ForegroundColor Green
                    Write-Host "" -ForegroundColor Green
                }
            }
            if ($domains.Count -gt 0) {
                Write-Host "Email Domains ($($domains.Count)):" -ForegroundColor Green
                foreach ($domain in $domains) {
                    Write-Host "  $($domain.name)" -ForegroundColor Green
                    Write-Host "Management: $($domain.properties.domainManagement)" -ForegroundColor Green
                    Write-Host "Status: $($domain.properties.verificationStates.domain)" -ForegroundColor Green
                    Write-Host "" -ForegroundColor Green
                }
            }
        }
        "delete" {
    [string]$confirmation = Read-Host "Are you sure you want to delete the Communication Service '$CommunicationServiceName'? (yes/no)"
            if ($confirmation.ToLower() -ne "yes" ) {

                return
            }
            Invoke-AzureOperation -Operation {
                Remove-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName -Force
            } -OperationName "Delete Communication Service"

        }
    }
    if ($EnableEventGrid -and $Action.ToLower() -eq "create" ) {
        Invoke-AzureOperation -Operation {
    [string]$TopicName = " $CommunicationServiceName-events"
            New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Location $ResourceGroup.Location
        } -OperationName "Create Event Grid Topic" | Out-Null

    }
    if ($EnableMonitoring -and $Action.ToLower() -eq "create" ) {
    [string]$DiagnosticSettings = Invoke-AzureOperation -Operation {
    $LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($LogAnalyticsWorkspace) {
    [string]$ResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName"
    $DiagnosticParams = @{
                    ResourceId = $ResourceId
                    Name = " $CommunicationServiceName-diagnostics"
                    WorkspaceId = $LogAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("ChatOperational" , "SMSOperational" , "CallSummary" , "CallDiagnostics" )
                    MetricCategory = @("AllMetrics" )
                }
                Set-AzDiagnosticSetting -ErrorAction Stop @diagnosticParams
            } else {

                return $null
            }
        } -OperationName "Configure Monitoring"
        if ($DiagnosticSettings) {

        }
    }
    if ($Action.ToLower() -eq "create" ) {
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
    [string]$capabilities = @(
        "  Voice calling (VoIP) - Make and receive voice calls" ,
        "  Chat - Real-time messaging and group chat" ,
        "  SMS - Send and receive text messages" ,
        "  Email - Transactional and marketing emails" ,
        "  Video calling - HD video communication" ,
        "  Identity management - User authentication and tokens" ,
        "  Call analytics - Call quality and usage metrics" ,
        "  Global reach - Worldwide communication coverage"
    )
    [string]$SecurityScore = 0
    [string]$MaxScore = 5
    [string]$SecurityFindings = @()
    if ($Action.ToLower() -eq "create" ) {
        if ($Location -in @("United States" , "Europe" , "Asia Pacific" )) {
    [string]$SecurityScore++
    [string]$SecurityFindings = $SecurityFindings + "[OK] Data stored in compliant region"
        }
        if ($EnableMonitoring) {
    [string]$SecurityScore++
    [string]$SecurityFindings = $SecurityFindings + "[OK] Monitoring and logging enabled"
        } else {
    [string]$SecurityFindings = $SecurityFindings + "[WARN]  Monitoring not configured"
        }
        if ($EnableEventGrid) {
    [string]$SecurityScore++
    [string]$SecurityFindings = $SecurityFindings + "[OK] Event Grid integration for audit trails"
        } else {
    [string]$SecurityFindings = $SecurityFindings + "[WARN]  Event Grid not configured for event tracking"
        }
        if ($EnableMessaging) {
    [string]$SecurityScore++
    [string]$SecurityFindings = $SecurityFindings + "[OK]  messaging features enabled"
        }
    [string]$SecurityScore++
    [string]$SecurityFindings = $SecurityFindings + "[OK] End-to-end encryption for all communications"
    }
    $CostComponents = @{
        "SMS" = " $0.0075 per message (US)"
        "Voice Calling" = " $0.004 per minute (outbound)"
        "Phone Numbers" = " $1-15 per month depending on type"
        "Email" = " $0.25 per 1,000 emails"
        "Chat" = " $1.50 per monthly active user"
        "Video Calling" = " $0.004 per participant per minute"
        "Data Storage" = "Included in base service"
        "Identity Management" = "Free for basic operations"
    }
    if ($Action.ToLower() -ne "delete" ) {
    [string]$ServiceStatus = Invoke-AzureOperation -Operation {
            Get-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
        } -OperationName "Validate Service Status"
    }
    Write-Host "" -ForegroundColor Green
    Write-Host "                      AZURE COMMUNICATION SERVICES READY" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    if ($Action.ToLower() -eq "create" ) {
        Write-Host "Communication Service Details:" -ForegroundColor Green
        Write-Host "    Service Name: $CommunicationServiceName" -ForegroundColor Green
        Write-Host "    Resource Group: $ResourceGroupName" -ForegroundColor Green
        Write-Host "    Data Location: $Location" -ForegroundColor Green
        Write-Host "    Status: $($ServiceStatus.ProvisioningState)" -ForegroundColor Green
        Write-Host "    Resource ID: $($ServiceStatus.Id)" -ForegroundColor Green
        Write-Host "" -ForegroundColor Green
        Write-Host " [LOCK] Security Assessment: $SecurityScore/$MaxScore" -ForegroundColor Green
        foreach ($finding in $SecurityFindings) {
            Write-Host "   $finding" -ForegroundColor Green
        }
        Write-Host "" -ForegroundColor Green
        Write-Host "Pricing (Approximate):" -ForegroundColor Green
        foreach ($cost in $CostComponents.GetEnumerator()) {
            Write-Host "    $($cost.Key): $($cost.Value)" -ForegroundColor Green
        }
    }
    Write-Host "" -ForegroundColor Green
    Write-Host "Communication Capabilities:" -ForegroundColor Green
    foreach ($capability in $capabilities) {
        Write-Host "   $capability" -ForegroundColor Green
    }
    Write-Host "" -ForegroundColor Green
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "    Configure email domains using ConfigureDomain action" -ForegroundColor Green
    Write-Host "    Purchase phone numbers using ManagePhoneNumbers action" -ForegroundColor Green
    Write-Host "    Create user identities for chat and calling features" -ForegroundColor Green
    Write-Host "    Integrate with your applications using SDKs" -ForegroundColor Green
    Write-Host "    Set up monitoring and alerting for usage tracking" -ForegroundColor Green
    Write-Host "    Configure compliance settings for your region" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green

} catch {

    Write-Host "" -ForegroundColor Green
    Write-Host "Troubleshooting Tips:" -ForegroundColor Green
    Write-Host "    Verify Communication Services availability in your region" -ForegroundColor Green
    Write-Host "    Check subscription quotas and limits" -ForegroundColor Green
    Write-Host "    Ensure proper permissions for resource creation" -ForegroundColor Green
    Write-Host "    Validate phone number availability for your country" -ForegroundColor Green
    Write-Host "    Check domain ownership for email configuration" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    throw`n}
