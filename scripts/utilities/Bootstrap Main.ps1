#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Bootstrap Main

.DESCRIPTION
    Bootstrap master script for pre-configuring Automation Account
    Author: Wes Ellis (wes@wesellis.com)
.EXAMPLE
    .\Bootstrap_Main.ps1
$ErrorActionPreference = 'Stop'

function ValidateKeyVaultAndCreate([string] $KeyVaultName, [string] $ResourceGroup, [string] $KeyVaultLocation)
{
   $GetKeyVault=Get-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
   if (!$GetKeyVault)
   {
     Write-Warning -Message "Key Vault $KeyVaultName not found. Creating the Key Vault $KeyVaultName"
     $KeyValut=New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroup -Location $KeyVaultLocation
     if (!$KeyValut) {
       Write-Error -Message "Key Vault $KeyVaultName creation failed. Please fix and continue"
       return
     }
     $uri = New-Object -ErrorAction Stop System.Uri($KeyValut.VaultUri, $true)
     $HostName = $uri.Host
     Start-Sleep -s 15
   }
 }
 function CreateSelfSignedCertificate([string] $KeyVaultName, [string] $CertificateName, [string] $SelfSignedCertPlainPassword,[string] $CertPath, [string] $CertPathCer, [string] $NoOfMonthsUntilExpired )
{
   $CertSubjectName=" cn=" +$CertificateName
   $Policy = New-AzureKeyVaultCertificatePolicy -SecretContentType " application/x-pkcs12" -SubjectName $CertSubjectName  -IssuerName "Self" -ValidityInMonths $NoOfMonthsUntilExpired -ReuseKeyOnRenewal
   $AddAzureKeyVaultCertificateStatus = Add-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $CertificateName -CertificatePolicy $Policy
   While($AddAzureKeyVaultCertificateStatus.Status -eq " inProgress" )
   {
     Start-Sleep -s 10
     $AddAzureKeyVaultCertificateStatus = Get-AzureKeyVaultCertificateOperation -VaultName $KeyVaultName -Name $CertificateName
   }
   if($AddAzureKeyVaultCertificateStatus.Status -ne " completed" )
   {
     Write-Error -Message "Key vault cert creation is not sucessfull and its status is: $status.Status"
   }
   $SecretRetrieved = Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $CertificateName
   $PfxBytes = [System.Convert]::FromBase64String($SecretRetrieved.SecretValueText)
   $CertCollection = New-Object -ErrorAction Stop System.Security.Cryptography.X509Certificates.X509Certificate2Collection
   $CertCollection.Import($PfxBytes,$null,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
   $ProtectedCertificateBytes = $CertCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $SelfSignedCertPlainPassword)
   [System.IO.File]::WriteAllBytes($CertPath, $ProtectedCertificateBytes)
   $cert = Get-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $CertificateName
   $CertBytes = $cert.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
   [System.IO.File]::WriteAllBytes($CertPathCer, $CertBytes)
   $RemoveAzureKeyVaultCertificateStatus = Remove-AzureKeyVaultCertificate -VaultName $KeyVaultName -Name $CertificateName -PassThru -Force -ErrorAction SilentlyContinue -Confirm:$false
 }
 function CreateServicePrincipal([System.Security.Cryptography.X509Certificates.X509Certificate2] $PfxCert, [string] $ApplicationDisplayName) {
   $CurrentDate = Get-Date -ErrorAction Stop
   $KeyValue = [System.Convert]::ToBase64String($PfxCert.GetRawCertData())
   $KeyId = [Guid]::NewGuid()
   $KeyCredential = New-Object -ErrorAction Stop  Microsoft.Azure.Commands.Resources.Models.ActiveDirectory.PSADKeyCredential
   $KeyCredential.StartDate = $CurrentDate
   $KeyCredential.EndDate= [DateTime]$PfxCert.GetExpirationDateString()
   $KeyCredential.KeyId = $KeyId
   $KeyCredential.CertValue  = $KeyValue
   $Application = New-AzureRmADApplication -DisplayName $ApplicationDisplayName -HomePage (" http://" + $ApplicationDisplayName) -IdentifierUris (" http://" + $KeyId) -KeyCredentials $KeyCredential
   $ServicePrincipal = New-AzureRMADServicePrincipal -ApplicationId $Application.ApplicationId
   $GetServicePrincipal = Get-AzureRmADServicePrincipal -ObjectId $ServicePrincipal.Id
   Start-Sleep -s 15
$NewRole = $null
$Retries = 0;
   While ($null -eq $NewRole -and $Retries -le 6)
   {
      New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $Application.ApplicationId | Write-Verbose -ErrorAction SilentlyContinue
      Start-Sleep -s 10
      $NewRole = Get-AzureRMRoleAssignment -ServicePrincipalName $Application.ApplicationId -ErrorAction SilentlyContinue
      $Retries++;
   }
   return $Application.ApplicationId.ToString();
 }
 function CreateAutomationCertificateAsset ([string] $ResourceGroup, [string] $AutomationAccountName, [string] $CertifcateAssetName,[string] $CertPath, [string] $CertPlainPassword, [Boolean] $Exportable) {
   $CertPassword = Read-Host -Prompt "Enter secure value" -AsSecureString
   Remove-AzureRmAutomationCertificate -ResourceGroupName $ResourceGroup -automationAccountName $AutomationAccountName -Name $CertifcateAssetName -ErrorAction SilentlyContinue
   New-AzureRmAutomationCertificate -ResourceGroupName $ResourceGroup -automationAccountName $AutomationAccountName -Path $CertPath -Name $CertifcateAssetName -Password $CertPassword -Exportable:$Exportable  | write-verbose
 }
 function CreateAutomationConnectionAsset ([string] $ResourceGroup, [string] $AutomationAccountName, [string] $ConnectionAssetName, [string] $ConnectionTypeName, [System.Collections.Hashtable] $ConnectionFieldValues ) {
   Remove-AzureRmAutomationConnection -ResourceGroupName $ResourceGroup -automationAccountName $AutomationAccountName -Name $ConnectionAssetName -Force -ErrorAction SilentlyContinue
   New-AzureRmAutomationConnection -ResourceGroupName $ResourceGroup -automationAccountName $AutomationAccountName -Name $ConnectionAssetName -ConnectionTypeName $ConnectionTypeName -ConnectionFieldValues $ConnectionFieldValues
 }
try
{
    Write-Output "Bootstrap main script execution started..."
    Write-Output "Checking for the RunAs account..."
    $ServicePrincipalConnection=Get-AutomationConnection -Name 'AzureRunAsConnection' -ErrorAction SilentlyContinue
    $AutomationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $SubscriptionId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'
    $AroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'
    if ($null -eq $ServicePrincipalConnection)
    {
        $MyCredential = Get-AutomationPSCredential -Name 'AzureCredentials'
        $AzureLoginUserName = $MyCredential.UserName
        $SecurePassword = $MyCredential.Password
        $AzureLoginPassword = $MyCredential.GetNetworkCredential().Password
        Write-Output "Executing Step-1 : Create the keyvault certificate and connection asset..."
        Write-Output "RunAsAccount Creation Started..."
        try
         {
            Write-Output "Logging into Azure Subscription..."
            $SecPassword = Read-Host -Prompt "Enter secure value" -AsSecureString
            $AzureOrgIdCredential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential($AzureLoginUserName, $SecPassword)
            Login-AzureRmAccount -Credential $AzureOrgIdCredential
            Get-AzureRmSubscription -SubscriptionId $SubscriptionId | Select-AzureRmSubscription
            Write-Output "Successfully logged into Azure Subscription..."
            $AzureRMProfileVersion= (Get-Module -ErrorAction Stop AzureRM.Profile).Version
            if (!(($AzureRMProfileVersion.Major -ge 2 -and $AzureRMProfileVersion.Minor -ge 1) -or ($AzureRMProfileVersion.Major -gt 2)))
            {
                Write-Error -Message "Please install the latest Azure PowerShell and retry. Relevant doc url : https://docs.microsoft.com/en-us/powershell/azureps-cmdlets-docs/ "
                return
            }
            [String] $ApplicationDisplayName=" $($AutomationAccountName)App1"
            [Boolean] $CreateClassicRunAsAccount=$false
            [String] $SelfSignedCertPlainPassword = [Guid]::NewGuid().ToString().Substring(0,8)+" !"
            [String] $KeyVaultName="KeyVault" + [Guid]::NewGuid().ToString().Substring(0,5)
            [int] $NoOfMonthsUntilExpired = 36
            $RG = Get-AzureRmResourceGroup -Name $AroResourceGroupName
            $KeyVaultLocation = $RG[0].Location
            $CertifcateAssetName = "AzureRunAsCertificate"
            $ConnectionAssetName = "AzureRunAsConnection"
            $ConnectionTypeName = "AzureServicePrincipal"
            Write-Output "Creating Keyvault for generating cert..."
            ValidateKeyVaultAndCreate $KeyVaultName $AroResourceGroupName $KeyVaultLocation
            $CertificateName = $AutomationAccountName+$CertifcateAssetName
            $PfxCertPathForRunAsAccount = Join-Path $env:TEMP ($CertificateName + " .pfx" )
            $PfxCertPlainPasswordForRunAsAccount = $SelfSignedCertPlainPassword
            $CerCertPathForRunAsAccount = Join-Path $env:TEMP ($CertificateName + " .cer" )
            Write-Output "Generating the cert using Keyvault..."
            CreateSelfSignedCertificate $KeyVaultName $CertificateName $PfxCertPlainPasswordForRunAsAccount $PfxCertPathForRunAsAccount $CerCertPathForRunAsAccount $NoOfMonthsUntilExpired
            Write-Output "Creating service principal..."
            $PfxCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($PfxCertPathForRunAsAccount, $PfxCertPlainPasswordForRunAsAccount)
            $ApplicationId=CreateServicePrincipal $PfxCert $ApplicationDisplayName
            Write-Output "Creating Certificate in the Asset..."
            CreateAutomationCertificateAsset $AroResourceGroupName $AutomationAccountName $CertifcateAssetName $PfxCertPathForRunAsAccount $PfxCertPlainPasswordForRunAsAccount $true
            $SubscriptionInfo = Get-AzureRmSubscription -SubscriptionId $SubscriptionId
            $TenantID = $SubscriptionInfo | Select-Object TenantId -First 1
$Thumbprint = $PfxCert.Thumbprint
$ConnectionFieldValues = @{"ApplicationId" = $ApplicationId; "TenantId" = $TenantID.TenantId; "CertificateThumbprint" = $Thumbprint; "SubscriptionId" = $SubscriptionId}
            Write-Output "Creating Connection in the Asset..."
            CreateAutomationConnectionAsset $AroResourceGroupName $AutomationAccountName $ConnectionAssetName $ConnectionTypeName $ConnectionFieldValues
            Write-Output "RunAsAccount Creation Completed..."
            Write-Output "Completed Step-1 ..."
         }
         catch
         {
            Write-Output "Error Occurred on Step-1..."
            Write-Output $_.Exception
            Write-Error $_.Exception
            exit
         }
    }
    else
    {
        Write-Output "RunAs account already available..."
        $ConnectionName = "AzureRunAsConnection"
        try
        {
            $ServicePrincipalConnection=Get-AutomationConnection -Name $ConnectionName
            "Logging in to Azure..."
            $params = @{
                ApplicationId = $ServicePrincipalConnection.ApplicationId
                TenantId = $ServicePrincipalConnection.TenantId
                CertificateThumbprint = $ServicePrincipalConnection.CertificateThumbprint } catch { if (!$ServicePrincipalConnection) { $ErrorMessage = "Connection $ConnectionName not found." throw $ErrorMessage } else{ Write-Error
                Message = $_.Exception throw $_.Exception exit } } }
            }
            Add-AzureRmAccount @params
    try
    {
        $RunbookNameforStopVM = "AutoSnooze_StopVM_Child"
        $WebhookNameforStopVM = "AutoSnooze_StopVM_ChildWebhook"
        [String] $WebhookUriVariableName ="Internal_AutoSnooze_WebhookUri"
        $CheckWebhook = Get-AzureRmAutomationWebhook -Name $WebhookNameforStopVM -automationAccountName $AutomationAccountName -ResourceGroupName $AroResourceGroupName -ErrorAction SilentlyContinue
        if($null -eq $CheckWebhook)
        {
            Write-Output "Executing Step-2 : Create the webhook for $($RunbookNameforStopVM)..."
            $ExpiryTime = (Get-Date).AddDays(730)
            Write-Output "Creating the Webhook ($($WebhookNameforStopVM)) for the Runbook ($($RunbookNameforStopVM))..."
            $Webhookdata = New-AzureRmAutomationWebhook -Name $WebhookNameforStopVM -automationAccountName $AutomationAccountName -ResourceGroupName $AroResourceGroupName -RunbookName $RunbookNameforStopVM -IsEnabled $true -ExpiryTime $ExpiryTime -Force
            Write-Output "Successfully created the Webhook ($($WebhookNameforStopVM)) for the Runbook ($($RunbookNameforStopVM))..."
            $ServiceUri = $Webhookdata.WebhookURI
            Write-Output "Webhook Uri [$($ServiceUri)]"
            Write-Output "Creating the Assest Variable ($($WebhookUriVariableName)) in the Automation Account ($($AutomationAccountName)) to store the Webhook URI..."
            New-AzureRmAutomationVariable -automationAccountName $AutomationAccountName -Name $WebhookUriVariableName -Encrypted $False -Value $ServiceUri -ResourceGroupName $AroResourceGroupName
            Write-Output "Successfully created the Assest Variable ($($WebhookUriVariableName)) in the Automation Account ($($AutomationAccountName)) and Webhook URI value updated..."
            Write-Output "Webhook Creation completed..."
            Write-Output "Completed Step-2..."
        }
        else
        {
            Write-Output "Webhook already available. Ignoring Step-2..."

} catch
    {
        Write-Output "Error Occurred in Step-2..."
        Write-Output $_.Exception
        Write-Error $_.Exception
        exit
    }
    try
    {
        $RunbookNameforCreateAlert = "AutoSnooze_CreateAlert_Parent"
        $ScheduleNameforCreateAlert = "Schedule_AutoSnooze_CreateAlert_Parent"
        $CheckMegaSchedule = Get-AzureRmAutomationSchedule -Name $ScheduleNameforCreateAlert -automationAccountName $AutomationAccountName -ResourceGroupName $AroResourceGroupName -ErrorAction SilentlyContinue
        if($null -eq $CheckMegaSchedule)
        {
            Write-Output "Executing Step-3 : Create schedule for AutoSnooze_CreateAlert_Parent runbook ..."
            $StartTime = (Get-Date).AddMinutes(10)
            $EndTime = $StartTime.AddYears(3)
            $Hours = 8
            Write-Output "Creating the Schedule ($($ScheduleNameforCreateAlert)) in Automation Account ($($AutomationAccountName))..."
            New-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleNameforCreateAlert -ResourceGroupName $AroResourceGroupName -StartTime $StartTime -ExpiryTime $EndTime -HourInterval $Hours
            Set-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleNameforCreateAlert -ResourceGroupName $AroResourceGroupName -IsEnabled $false
            Write-Output "Successfully created the Schedule ($($ScheduleNameforCreateAlert)) in Automation Account ($($AutomationAccountName))..."
            $ParamsAutoSnooze = @{"WhatIf" =$false}
            Write-Output "Registering the Schedule ($($ScheduleNameforCreateAlert)) in the Runbook ($($RunbookNameforCreateAlert))..."
            Register-AzureRmAutomationScheduledRunbook -automationAccountName $AutomationAccountName -Name $RunbookNameforCreateAlert -ScheduleName $ScheduleNameforCreateAlert -ResourceGroupName $AroResourceGroupName -Parameters $ParamsAutoSnooze
            Write-Output "Successfully Registered the Schedule ($($ScheduleNameforCreateAlert)) in the Runbook ($($RunbookNameforCreateAlert))..."
            Write-Output "Completed Step-3 ..."
        }
        else
        {
            Write-Output "Schedule $($ScheduleNameforCreateAlert) already available. Ignoring Step-3..."

} catch
    {
        Write-Output "Error Occurred in Step-3..."
        Write-Output $_.Exception
        Write-Error $_.Exception
        exit
    }
    try
    {
        $RunbookNameforARMVMOptimization = "ScheduledSnooze_Parent"
        $ScheduleStart = "ScheduledSnooze-StartVM"
        $ScheduleStop = "ScheduledSnooze-StopVM"
        $CheckSchSnoozeStart = Get-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleStart -ResourceGroupName $AroResourceGroupName -ErrorAction SilentlyContinue
        $CheckSchSnoozeStop = Get-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleStop -ResourceGroupName $AroResourceGroupName -ErrorAction SilentlyContinue
        $StartVmUTCTime = (Get-Date -ErrorAction Stop " 13:00:00" ).AddDays(1).ToUniversalTime()
$StopVmUTCTime = (Get-Date -ErrorAction Stop " 01:00:00" ).AddDays(1).ToUniversalTime()
        if($null -eq $CheckSchSnoozeStart)
        {
            Write-Output "Executing Step-4 : Create schedule for ScheduledSnooze_Parent runbook ..."
            Write-Output "Creating the Schedule in Automation Account ($($AutomationAccountName))..."
            New-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleStart -ResourceGroupName $AroResourceGroupName -StartTime $StartVmUTCTime -ExpiryTime $StartVmUTCTime.AddYears(1) -DayInterval 1
            Write-Output "Successfully created the Schedule in Automation Account ($($AutomationAccountName))..."
            Set-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleStart -ResourceGroupName $AroResourceGroupName -IsEnabled $false
$ParamsStartVM = @{"Action" ="Start" ;"WhatIf" =$false}
            Register-AzureRmAutomationScheduledRunbook -automationAccountName $AutomationAccountName -Name $RunbookNameforARMVMOptimization -ScheduleName $ScheduleStart -ResourceGroupName $AroResourceGroupName -Parameters $ParamsStartVM
            Write-Output "Successfully Registered the Schedule in the Runbook ($($RunbookNameforARMVMOptimization))..."
        }
        if($null -eq $CheckSchSnoozeStop)
        {
            New-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleStop -ResourceGroupName $AroResourceGroupName -StartTime $StopVmUTCTime -ExpiryTime $StopVmUTCTime.AddYears(1) -DayInterval 1
            Write-Output "Successfully created the Schedule in Automation Account ($($AutomationAccountName))..."
            Set-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleStop -ResourceGroupName $AroResourceGroupName -IsEnabled $false
            Write-Output "Registering the Schedule in the Runbook ($($RunbookNameforARMVMOptimization))..."
            $ParamsStopVM = @{"Action" ="Stop" ;"WhatIf" =$false}
            Register-AzureRmAutomationScheduledRunbook -automationAccountName $AutomationAccountName -Name $RunbookNameforARMVMOptimization -ScheduleName $ScheduleStop -ResourceGroupName $AroResourceGroupName -Parameters $ParamsStopVM
            Write-Output "Successfully Registered the Schedule in the Runbook ($($RunbookNameforARMVMOptimization))..."
         }
         if($null -ne $CheckSchSnoozeStart -and $null -ne $CheckSchSnoozeStop)
         {
            Write-Output "Schedule already available. Ignoring Step-4..."
         }
        Write-Output "Completed Step-4 ..."
    }
    catch
    {
        Write-Output "Error Occurred in Step-4..."
        Write-Output $_.Exception
        Write-Error $_.Exception
        exit
    }
    try
    {
        $RunbookNameforAutoupdate = "AROToolkit_AutoUpdate"
        $ScheduleNameforAutoupdate = "Schedule_AROToolkit_AutoUpdate"
        $StartUTCTime = (Get-Date -ErrorAction Stop " 13:00:00" ).AddDays(1).ToUniversalTime()
        $CheckScheduleAU = Get-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleNameforAutoupdate -ResourceGroupName $AroResourceGroupName -ErrorAction SilentlyContinue
        if($null -eq $CheckScheduleAU)
        {
            Write-Output "Executing Step-5 : Create schedule for AROToolkit_AutoUpdate runbook ..."
            Write-Output "Creating the Schedule ($($ScheduleNameforAutoupdate)) in Automation Account ($($AutomationAccountName))..."
            New-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleNameforAutoupdate -ResourceGroupName $AroResourceGroupName -StartTime $StartUTCTime -WeekInterval 2
            Set-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $ScheduleNameforAutoupdate -ResourceGroupName $AroResourceGroupName -IsEnabled $false
            Write-Output "Successfully created the Schedule ($($ScheduleNameforAutoupdate)) in Automation Account ($($AutomationAccountName))..."
            Write-Output "Registering the Schedule ($($ScheduleNameforAutoupdate)) in the Runbook ($($RunbookNameforAutoupdate))..."
            Register-AzureRmAutomationScheduledRunbook -automationAccountName $AutomationAccountName -Name $RunbookNameforAutoupdate -ScheduleName $ScheduleNameforAutoupdate -ResourceGroupName $AroResourceGroupName
            Write-Output "Successfully Registered the Schedule ($($ScheduleNameforAutoupdate)) in the Runbook ($($RunbookNameforAutoupdate))..."
        }
        else
        {
            Write-Output "Schedule already available. Ignoring Step-5"
        }
        Write-Output "Completed Step-5 ..."
    }
    catch
    {
        Write-Output "Error Occurred in Step-5..."
        Write-Output $_.Exception
        Write-Error $_.Exception
        exit
    }
    try
    {
        $RunbookNameforARMVMOptimization = "SequencedSnooze_Parent"
        $SequenceStart = "SequencedSnooze-StartVM"
        $SequenceStop = "SequencedSnooze-StopVM"
        $CheckSeqSnoozeStart = Get-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $SequenceStart -ResourceGroupName $AroResourceGroupName -ErrorAction SilentlyContinue
        $CheckSeqSnoozeStop = Get-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $SequenceStop -ResourceGroupName $AroResourceGroupName -ErrorAction SilentlyContinue
        $StartVmUTCTime = (Get-Date -ErrorAction Stop " 13:00:00" ).AddDays(1).ToUniversalTime()
$StopVmUTCTime = (Get-Date -ErrorAction Stop " 01:00:00" ).AddDays(1).ToUniversalTime()
        if($null -eq $CheckSeqSnoozeStart)
        {
            Write-Output "Executing Step-6 : Create schedule for SequencedSnooze_Parent runbook ..."
            Write-Output "Creating the Schedule in Automation Account ($($AutomationAccountName))..."
            New-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $SequenceStart -ResourceGroupName $AroResourceGroupName -StartTime $StartVmUTCTime -DaysOfWeek Monday -WeekInterval 1
            Write-Output "Successfully created the Schedule in Automation Account ($($AutomationAccountName))..."
            Set-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $SequenceStart -ResourceGroupName $AroResourceGroupName -IsEnabled $false
$ParamsStartVM = @{"Action" =" start" ;"WhatIf" =$false;"ContinueOnError" =$false}
            Register-AzureRmAutomationScheduledRunbook -automationAccountName $AutomationAccountName -Name $RunbookNameforARMVMOptimization -ScheduleName $SequenceStart -ResourceGroupName $AroResourceGroupName -Parameters $ParamsStartVM
            Write-Output "Successfully Registered the Schedule in the Runbook ($($RunbookNameforARMVMOptimization))..."
        }
        if($null -eq $CheckSeqSnoozeStop)
        {
            Write-Output "Executing Step-6 : Create schedule for SequencedSnooze_Parent runbook ..."
            Write-Output "Creating the Schedule in Automation Account ($($AutomationAccountName))..."
            New-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $SequenceStop -ResourceGroupName $AroResourceGroupName -StartTime $StopVmUTCTime -DaysOfWeek Friday -WeekInterval 1
            Write-Output "Successfully created the Schedule in Automation Account ($($AutomationAccountName))..."
            Set-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name $SequenceStop -ResourceGroupName $AroResourceGroupName -IsEnabled $false
            $ParamsStartVM = @{"Action" =" stop" ;"WhatIf" =$false;"ContinueOnError" =$false}
            Register-AzureRmAutomationScheduledRunbook -automationAccountName $AutomationAccountName -Name $RunbookNameforARMVMOptimization -ScheduleName $SequenceStop -ResourceGroupName $AroResourceGroupName -Parameters $ParamsStartVM
            Write-Output "Successfully Registered the Schedule in the Runbook ($($RunbookNameforARMVMOptimization))..."
        }
        if($null -ne $CheckSeqSnoozeStart -and $null -ne $CheckSeqSnoozeStop)
         {
            Write-Output "Schedule already available. Ignoring Step-6..."
         }
        Write-Output "Completed Step-6 ..."
    }
    catch
    {
        Write-Output "Error Occurred in Step-6..."
        Write-Output $_.Exception
        Write-Error $_.Exception
        exit
    }
    try{
        $AutomationAccountId=(Find-AzureRmResource -ResourceType "Microsoft.Automation/automationAccounts" -ResourceNameContains $AutomationAccountName).ResourceId
        $Status = (Get-AzureRmDiagnosticSetting -ResourceID $AutomationAccountId | Select-Object -ExpandProperty Logs | Where-Object {$_.Enabled -eq $false}).Count
        if ($Status -gt 0)
        {
            Write-Output "Executing Step-7 : Linking Automation Workspace to OMS Log Analytics..."
            Write-Output "Checking if omsWorkspaceId Variable is defined..."
            $OmsWorkspaceId = Get-AzureRmAutomationVariable -Name 'Internal_omsWorkspaceId' -ResourceGroupName $AroResourceGroupName -automationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($OmsWorkspaceId.Value)) {
                Write-Output " omsWorkspaceId Variable is null, skipping OMS Log Analytics link step..."
            } else {
                Write-Output " omsWorkspaceId Variable Found!  Linking to OMS Log Analytics..."
                Set-AzureRmDiagnosticSetting -ResourceId $AutomationAccountId -WorkspaceId $OmsWorkspaceId.Value -Enabled $true
                Start-Sleep -s 15
                $Status = (Get-AzureRmDiagnosticSetting -ResourceID $AutomationAccountId | Select-Object -ExpandProperty Logs | Where-Object {$_.Enabled -eq $false}).Count
                    if ($Status -eq 0) {
                        Write-Output "Successfully linked Automation account to OMS Log Analytics"
                    } else {
                        Write-Output "Failed to link Automation Account with OMS Log Analytics"
                    }
            }
        } else {
            Write-Output "OMS Logging is already enabled...."
        }
        Write-Output "Completed Step-7 ..."
    }
    catch
    {
        Write-Output "Error Occurred in Step-7..."
        Write-Output $_.Exception
        Write-Error $_.Exception
    }
    try
    {
        Write-Output "Executing Step-8 : Performing clean up tasks (Bootstrap script, Bootstrap Schedule, Credential asset variable, and Keyvault) ..."
        if($null -ne $KeyVaultName)
        {
            Write-Output "Removing the Keyvault : ($($KeyVaultName))..."
            Remove-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $AroResourceGroupName -Confirm:$False -Force
        }
$CheckCredentials = Get-AzureRmAutomationCredential -Name "AzureCredentials" -automationAccountName $AutomationAccountName -ResourceGroupName $AroResourceGroupName -ErrorAction SilentlyContinue
        if($null -ne $CheckCredentials)
        {
            Write-Output "Removing the Azure Credentials..."
            Remove-AzureRmAutomationCredential -Name "AzureCredentials" -automationAccountName $AutomationAccountName -ResourceGroupName $AroResourceGroupName
        }
$CheckScheduleBootstrap = Get-AzureRmAutomationSchedule -automationAccountName $AutomationAccountName -Name " startBootstrap" -ResourceGroupName $AroResourceGroupName -ErrorAction SilentlyContinue
        if($null -ne $CheckScheduleBootstrap)
        {
            Write-Output "Removing Bootstrap Schedule..."
            Remove-AzureRmAutomationSchedule -Name " startBootstrap" -automationAccountName $AutomationAccountName -ResourceGroupName $AroResourceGroupName -Force
        }
        Write-Output "Removing omsWorkspaceId Variable..."
        Remove-AzureRmAutomationVariable -Name 'Internal_omsWorkspaceId' -ResourceGroupName $AroResourceGroupName -automationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
        Write-Output "Removing the Bootstrap_Main Runbook..."
        Remove-AzureRmAutomationRunbook -Name "Bootstrap_Main" -ResourceGroupName $AroResourceGroupName -automationAccountName $AutomationAccountName -Force
        Write-Output "Completed Step-8 ..."
    }
    catch
    {
        Write-Output "Error Occurred in Step-8..."
        Write-Output $_.Exception
        Write-Error $_.Exception
    }
    Write-Output "Bootstrap wrapper script execution completed..."
}
catch
{
    Write-Output "Error Occurred in Bootstrap Wrapper..."
    Write-Output $_.Exception
    Write-Error $_.Exception`n}
