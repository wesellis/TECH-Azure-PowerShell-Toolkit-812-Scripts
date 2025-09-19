#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Serviceprincipal

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Serviceprincipal

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


cls
Set-Location -ErrorAction Stop ".\"










$subscriptionName =     ""          # name of the Azure subscription
$cloudwiseAppServiceURL=""          # this is the Unique URL of the Cloudwise App Service deployed by the ARM script


$suffix =               $subscriptionName     #-- Name of the company/deployment. This is used to create a unique website name in your organization
$tenantID=              ""

$passwordADApp =        " Password@123" 

$WEWeb1SiteName =         (" cloudwise" + $suffix)
$displayName1 =         (" CloudWise Governance Advisory Portal (ver." + $suffix + " )" )
$servicePrincipalPath=  (" .\" + $subscriptionName + " .json" )



if (($subscriptionName -eq "" ) -or ($cloudwiseAppServiceURL -eq "" ))
{
    Write-WELog " Please ensure parameters SubscriptionName and cloudwiseAppServiceURL are not empty" " INFO" -foreground Red
    return
}



Write-Information (" Step 1: Logging in to Azure Subscription" + $subscriptionName)


if(![System.IO.File]::Exists($servicePrincipalPath)){
    # file with path $path doesn't exist

    #Add-AzureRmAccount 
    Login-AzureRmAccount -SubscriptionName $subscriptionName
    
    Save-AzureRmProfile -Path $servicePrincipalPath
}

Select-AzureRmProfile -Path $servicePrincipalPath






$sub = Get-AzureRmSubscription -ErrorAction Stop –SubscriptionName $subscriptionName | Select-AzureRmSubscription 



Write-Information (" Step 2: Create Azure Active Directory apps in default directory" )

    $u = (Get-AzureRmContext).Account
    $u1 = ($u -split '@')[0]
    $u2 = ($u -split '@')[1]
    $u3 = ($u2 -split '\.')[0]
    $defaultPrincipal = ($u1 + $u3 + " .onmicrosoft.com" )
    
    # Get tenant ID
    $tenantID = (Get-AzureRmContext).Tenant.TenantId

    $homePageURL = (" http://" + $defaultPrincipal + " azurewebsites.net" + " /" + $WEWeb1SiteName)
   
    $replyURLs = @( $cloudwiseAppServiceURL, " http://*.azurewebsites.net" ," http://localhost:62080" )

    # Create Active Directory Application
    $azureAdApplication1 = New-AzureRmADApplication -DisplayName $displayName1 -HomePage $cloudwiseAppServiceURL -IdentifierUris $cloudwiseAppServiceURL -Password $passwordADApp -ReplyUrls $replyURLs

    Write-Information (" Step 2.1: Azure Active Directory apps creation successful. AppID is " + $azureAdApplication1.ApplicationId)


    Write-Information (" Step 3: Attempting to create Service Principal" )
   ;  $principal = New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication1.ApplicationId
    Start-Sleep -s 30 # Wait till the ServicePrincipal is completely created. Usually takes 20+secs. Needed as Role assignment needs a fully deployed servicePrincipal

    Write-Information (" Step 3.1: Service Principal creation successful - " + $principal.DisplayName)

   ;  $scopedSubs = (" /subscriptions/" + $sub.Subscription)

    Write-Information (" Step 3.2: Attempting Reader Role assignment" )

    New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $azureAdApplication1.ApplicationId.Guid -Scope $scopedSubs

    Write-Information (" Step 3.2: Reader Role assignment successful" )



Write-Information (" AD Application Details:" ) -foreground Green
$azureAdApplication1


Write-Information (" Parameters to be used in the registration / configuration." ) -foreground Green

Write-WELog " SubscriptionID: " " INFO" -foreground Green –NoNewLine
Write-Information $sub.Subscription -foreground Red 
Write-WELog " Domain: " " INFO" -foreground Green –NoNewLine
Write-Information ($u3 + " .onmicrosoft.com" ) -foreground Red –NoNewLine
Write-WELog " - Please verify the domain with the management portal. For debugging purposes we have used the domain of the user signing in. You might have Custom / Organization domains" " INFO" -foreground Yellow
Write-WELog " Application Client ID: " " INFO" -foreground Green –NoNewLine
Write-Information $azureAdApplication1.ApplicationId -foreground Red 
Write-WELog " Application Client Password: " " INFO" -foreground Green –NoNewLine
Write-Information $passwordADApp -foreground Red 
Write-WELog " PostLogoutRedirectUri: " " INFO" -foreground Green –NoNewLine
Write-Information $cloudwiseAppServiceURL -foreground Red 
Write-WELog " TenantId: " " INFO" -foreground Green –NoNewLine
Write-Information $tenantID -foreground Red 

Write-Information (" TODO - Update permissions for the AD Application  '" ) -foreground Yellow –NoNewLine
Write-Information $displayName1 -foreground Red –NoNewLine
Write-Information (" '. Cloudwise would atleast need 2 apps" ) -foreground Yellow
Write-Information (" `t 1) Windows Azure Active Directory " ) -foreground Yellow
Write-Information (" `t 2) Windows Azure Service Management API " ) -foreground Yellow
Write-Information (" see README.md for details" ) -foreground Yellow



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
