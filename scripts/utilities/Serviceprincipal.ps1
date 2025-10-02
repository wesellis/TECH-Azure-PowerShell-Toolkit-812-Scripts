#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Serviceprincipal

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
cls
Set-Location -ErrorAction Stop ".\"
$SubscriptionName =     ""          # name of the Azure subscription
$CloudwiseAppServiceURL=""          # this is the Unique URL of the Cloudwise App Service deployed by the ARM script
$suffix =               $SubscriptionName
$TenantID=              ""
$PasswordADApp =        "Password@123"
$Web1SiteName =         (" cloudwise" + $suffix)
$DisplayName1 =         ("CloudWise Governance Advisory Portal (ver.$(suffix) )" )
$ServicePrincipalPath=  (" .\$(subscriptionName) .json" )
if (($SubscriptionName -eq "" ) -or ($CloudwiseAppServiceURL -eq "" ))
{
    Write-Output "Please ensure parameters SubscriptionName and cloudwiseAppServiceURL are not empty" -foreground Red
    return
}
Write-Information ("Step 1: Logging in to Azure Subscription" + $SubscriptionName)
if(![System.IO.File]::Exists($ServicePrincipalPath)){
    Login-AzureRmAccount -SubscriptionName $SubscriptionName
    Save-AzureRmProfile -Path $ServicePrincipalPath
}
Select-AzureRmProfile -Path $ServicePrincipalPath
$sub = Get-AzureRmSubscription -ErrorAction Stop SubscriptionName $SubscriptionName | Select-AzureRmSubscription
Write-Information ("Step 2: Create Azure Active Directory apps in default directory" )
    $u = (Get-AzureRmContext).Account
    $u1 = ($u -split '@')[0]
    $u2 = ($u -split '@')[1]
    $u3 = ($u2 -split '\.')[0]
    $DefaultPrincipal = ($u1 + $u3 + " .onmicrosoft.com" )
    $TenantID = (Get-AzureRmContext).Tenant.TenantId
    $HomePageURL = (" http://$(defaultPrincipal) azurewebsites.net" + "/" + $Web1SiteName)
    $ReplyURLs = @( $CloudwiseAppServiceURL, "http://*.azurewebsites.net" ," http://localhost:62080" )
    $AzureAdApplication1 = New-AzureRmADApplication -DisplayName $DisplayName1 -HomePage $CloudwiseAppServiceURL -IdentifierUris $CloudwiseAppServiceURL -Password $PasswordADApp -ReplyUrls $ReplyURLs
    Write-Information ("Step 2.1: Azure Active Directory apps creation successful. AppID is " + $AzureAdApplication1.ApplicationId)
    Write-Information ("Step 3: Attempting to create Service Principal" )
$principal = New-AzureRmADServicePrincipal -ApplicationId $AzureAdApplication1.ApplicationId
    Start-Sleep -s 30
    Write-Information ("Step 3.1: Service Principal creation successful - " + $principal.DisplayName)
$ScopedSubs = ("/subscriptions/" + $sub.Subscription)
    Write-Information ("Step 3.2: Attempting Reader Role assignment" )
    New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $AzureAdApplication1.ApplicationId.Guid -Scope $ScopedSubs
    Write-Information ("Step 3.2: Reader Role assignment successful" )
Write-Information ("AD Application Details:" ) -foreground Green
$AzureAdApplication1
Write-Information ("Parameters to be used in the registration / configuration." ) -foreground Green
Write-Output "SubscriptionID: " -foreground Green NoNewLine
Write-Output $sub.Subscription -foreground Red
Write-Output "Domain: " -foreground Green NoNewLine
Write-Information ($u3 + " .onmicrosoft.com" ) -foreground Red NoNewLine
Write-Output " - Please verify the domain with the management portal. For debugging purposes we have used the domain of the user signing in. You might have Custom / Organization domains" -foreground Yellow
Write-Output "Application Client ID: " -foreground Green NoNewLine
Write-Output $AzureAdApplication1.ApplicationId -foreground Red
Write-Output "Application Client Password: " -foreground Green NoNewLine
Write-Output $PasswordADApp -foreground Red
Write-Output "PostLogoutRedirectUri: " -foreground Green NoNewLine
Write-Output $CloudwiseAppServiceURL -foreground Red
Write-Output "TenantId: " -foreground Green NoNewLine
Write-Output $TenantID -foreground Red
Write-Information ("TODO - Update permissions for the AD Application  '" ) -foreground Yellow NoNewLine
Write-Output $DisplayName1 -foreground Red NoNewLine
Write-Information (" '. Cloudwise would atleast need 2 apps" ) -foreground Yellow
Write-Information (" `t 1) Windows Azure Active Directory" ) -foreground Yellow
Write-Information (" `t 2) Windows Azure Service Management API" ) -foreground Yellow
Write-Information (" see README.md for details" ) -foreground Yellow



