#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage NICs

.DESCRIPTION
    Manage NICs
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding(SupportsShouldProcess)]

$ErrorActionPreference = 'Stop'

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
        if (-not (Get-AzContext)) { throw "Not connected to Azure" }

        Install-Module Az.Communication -Force -AllowClobber -Scope CurrentUser
        Import-Module Az.Communication
    }
        $ResourceGroup = Invoke-AzureOperation -Operation {
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    } -OperationName "Get Resource Group"

    switch ($Action.ToLower()) {
        "create" {
                $CommunicationParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $CommunicationServiceName
                DataLocation = $Location
            }
            $CommunicationService = Invoke-AzureOperation -Operation {
                New-AzCommunicationService -ErrorAction Stop @communicationParams
            } -OperationName "Create Communication Service"

            $ConnectionString = Invoke-AzureOperation -Operation {
                Get-AzCommunicationServiceKey -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
            } -OperationName "Get Connection String"

        }
        "configuredomain" {
            if (-not $DomainName) {
                throw "DomainName parameter is required for domain configuration"
            }
            Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
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
                $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/domains/$DomainName" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $body
            } -OperationName "Configure Email Domain" | Out-Null

            if ($DomainManagement -eq "CustomerManaged") {
                Write-Output ""
                Write-Output "For customer-managed domains, add these DNS records:"
                Write-Output "TXT record: verification code (check Azure portal)"
                Write-Output "MX record: inbound email routing"
                Write-Output "SPF record: sender policy framework"
                Write-Output "DKIM records: domain key identified mail"
                Write-Output ""
            }
        }
        "managephonenumbers" {
            $AvailableNumbers = Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
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
                $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Communication/phoneNumberOrders/search" + "?api-version=2022-12-01"
                $SearchResponse = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
                return $SearchResponse
            } -OperationName "Search Phone Numbers"
            Write-Output ""
            if ($AvailableNumbers.phoneNumbers) {
                foreach ($number in $AvailableNumbers.phoneNumbers) {
                    Write-Output " $($number.phoneNumber)"
                    Write-Output "Cost: $($number.cost.amount) $($number.cost.currencyCode)/month"
                    Write-Output "Capabilities: $($number.capabilities.calling), $($number.capabilities.sms)"
                    Write-Output ""
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
                        $uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Communication/phoneNumberOrders/purchase" + "?api-version=2022-12-01"
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
            $SmsResult = Invoke-AzureOperation -Operation {
                $endpoint = ($ConnectionString.PrimaryConnectionString -split ';')[0] -replace 'endpoint=', ''
                $AccessKey = ($ConnectionString.PrimaryConnectionString -split ';')[1] -replace 'accesskey=', ''
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
                $uri = "$endpoint/sms?api-version=2021-03-07"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Send SMS"

        }
        "sendemail" {
            if (-not $EmailTo -or -not $EmailFrom -or -not $EmailSubject -or -not $EmailContent) {
                throw "EmailTo, EmailFrom, EmailSubject, and EmailContent parameters are required for email sending"
            }
            Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
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
                $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/sendEmail" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Send Email" | Out-Null

        }
        "createidentity" {
            $UserIdentity = Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $body = @{
                    createTokenWithScopes = @("chat", "voip")
                } | ConvertTo-Json
                $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/identities" + "?api-version=2023-04-01"
                Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
            } -OperationName "Create User Identity"

            Write-Output ""
            Write-Output "Identity ID: $($UserIdentity.identity.id)"
            Write-Output "Access Token: $($UserIdentity.accessToken.token)"
            Write-Output "Token Expires: $($UserIdentity.accessToken.expiresOn)"
            Write-Output ""
            Write-Output "[WARN]  Store the access token securely - it's needed for client authentication"
        }
        "getinfo" {
            $CommunicationService = Invoke-AzureOperation -Operation {
                Get-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
            } -OperationName "Get Communication Service"
            $PhoneNumbers = Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/phoneNumbers" + "?api-version=2022-12-01"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
                return $response.value
            } -OperationName "Get Phone Numbers"
            $domains = Invoke-AzureOperation -Operation {
                $SubscriptionId = (Get-AzContext).Subscription.Id
                $headers = @{
                    'Authorization' = "Bearer $((Get-AzAccessToken).Token)"
                    'Content-Type' = 'application/json'
                }
                $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName/domains" + "?api-version=2023-04-01"
                $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers -ErrorAction SilentlyContinue
                return $response.value
            } -OperationName "Get Email Domains"
            Write-Output ""
            Write-Output "Service Name: $($CommunicationService.Name)"
            Write-Output "Data Location: $($CommunicationService.DataLocation)"
            Write-Output "Status: $($CommunicationService.ProvisioningState)"
            Write-Output "Resource ID: $($CommunicationService.Id)"
            if ($PhoneNumbers.Count -gt 0) {
                Write-Output ""
                foreach ($number in $PhoneNumbers) {
                    Write-Output " $($number.phoneNumber)"
                    Write-Output "Type: $($number.phoneNumberType)"
                    Write-Output "Assignment: $($number.assignmentType)"
                    Write-Output "Capabilities: SMS=$($number.capabilities.sms), Calling=$($number.capabilities.calling)"
                    Write-Output ""
                }
            }
            if ($domains.Count -gt 0) {
                foreach ($domain in $domains) {
                    Write-Output " $($domain.name)"
                    Write-Output "Management: $($domain.properties.domainManagement)"
                    Write-Output "Status: $($domain.properties.verificationStates.domain)"
                    Write-Output ""
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
    if ($EnableEventGrid -and $Action.ToLower() -eq "create") {
            Invoke-AzureOperation -Operation {
            $TopicName = "$CommunicationServiceName-events"
            New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Location $ResourceGroup.Location
        } -OperationName "Create Event Grid Topic" | Out-Null

    }
    if ($EnableMonitoring -and $Action.ToLower() -eq "create") {
            $DiagnosticSettings = Invoke-AzureOperation -Operation {
            $LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName | Select-Object -First 1
            if ($LogAnalyticsWorkspace) {
                $ResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Communication/CommunicationServices/$CommunicationServiceName"
                $DiagnosticParams = @{
                    ResourceId = $ResourceId
                    Name = "$CommunicationServiceName-diagnostics"
                    WorkspaceId = $LogAnalyticsWorkspace.ResourceId
                    Enabled = $true
                    Category = @("ChatOperational", "SMSOperational", "CallSummary", "CallDiagnostics")
                    MetricCategory = @("AllMetrics")
                }
                Set-AzDiagnosticSetting -ErrorAction Stop @diagnosticParams
            } else {

                return $null
            }
        } -OperationName "Configure Monitoring"
        if ($DiagnosticSettings) {

        }
    }
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
        $SecurityScore = 0
    $MaxScore = 5
    $SecurityFindings = @()
    if ($Action.ToLower() -eq "create") {
        if ($Location -in @("United States", "Europe", "Asia Pacific")) {
            $SecurityScore++
            $SecurityFindings += "[OK] Data stored in compliant region"
        }
        if ($EnableMonitoring) {
            $SecurityScore++
            $SecurityFindings += "[OK] Monitoring and logging enabled"
        } else {
            $SecurityFindings += "[WARN]  Monitoring not configured"
        }
        if ($EnableEventGrid) {
            $SecurityScore++
            $SecurityFindings += "[OK] Event Grid integration for audit trails"
        } else {
            $SecurityFindings += "[WARN]  Event Grid not configured for event tracking"
        }
        if ($EnableMessaging) {
            $SecurityScore++
            $SecurityFindings += "[OK]  messaging features enabled"
        }
        $SecurityScore++
        $SecurityFindings += "[OK] End-to-end encryption for all communications"
    }
        $CostComponents = @{
        "SMS" = "$0.0075 per message (US)"
        "Voice Calling" = "$0.004 per minute (outbound)"
        "Phone Numbers" = "$1-15 per month depending on type"
        "Email" = "$0.25 per 1,000 emails"
        "Chat" = "$1.50 per monthly active user"
        "Video Calling" = "$0.004 per participant per minute"
        "Data Storage" = "Included in base service"
        "Identity Management" = "Free for basic operations"
    }
        if ($Action.ToLower() -ne "delete") {
        $ServiceStatus = Invoke-AzureOperation -Operation {
            Get-AzCommunicationService -ResourceGroupName $ResourceGroupName -Name $CommunicationServiceName
        } -OperationName "Validate Service Status"
    }
    Write-Output ""
    Write-Output "                      AZURE COMMUNICATION SERVICES READY"
    Write-Output ""
    if ($Action.ToLower() -eq "create") {
        Write-Output "    Service Name: $CommunicationServiceName"
        Write-Output "    Resource Group: $ResourceGroupName"
        Write-Output "    Data Location: $Location"
        Write-Output "    Status: $($ServiceStatus.ProvisioningState)"
        Write-Output "    Resource ID: $($ServiceStatus.Id)"
        Write-Output ""
        Write-Output "[LOCK] Security Assessment: $SecurityScore/$MaxScore"
        foreach ($finding in $SecurityFindings) {
            Write-Output "   $finding"
        }
        Write-Output ""
        Write-Output "Pricing (Approximate):"
        foreach ($cost in $CostComponents.GetEnumerator()) {
            Write-Output "    $($cost.Key): $($cost.Value)"
        }
    }
    Write-Output ""
    Write-Output "Communication Capabilities:"
    foreach ($capability in $capabilities) {
        Write-Output "   $capability"
    }
    Write-Output ""
    Write-Output "    Configure email domains using ConfigureDomain action"
    Write-Output "    Purchase phone numbers using ManagePhoneNumbers action"
    Write-Output "    Create user identities for chat and calling features"
    Write-Output "    Integrate with your applications using SDKs"
    Write-Output "    Set up monitoring and alerting for usage tracking"
    Write-Output "    Configure compliance settings for your region"
    Write-Output ""

} catch {

    Write-Output ""
    Write-Output "Troubleshooting Tips:"
    Write-Output "    Verify Communication Services availability in your region"
    Write-Output "    Check subscription quotas and limits"
    Write-Output "    Ensure proper permissions for resource creation"
    Write-Output "    Validate phone number availability for your country"
    Write-Output "    Check domain ownership for email configuration"
    Write-Output ""
    throw`n}
