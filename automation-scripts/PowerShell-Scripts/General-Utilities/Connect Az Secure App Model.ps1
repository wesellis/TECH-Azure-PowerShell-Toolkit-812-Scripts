<#
.SYNOPSIS
    Connect Az Secure App Model

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
Import-Module 'PartnerCenter'
$TenantID_3001 = $null
$TenantID_3001 = " e09d9473-1a06-4717-98c1-528067eab3a4" #FGC Health Tenant ID
$RefreshToken_3001 = $null
$RefreshToken_3001 = " 0.ARcApCcy3LpT8Ui1S4mTbNXKU0biMg2kdDBJrz9JcmUtdbsXAB8.AgABAAAAAAB2UyzwtQEKR7-rWbgdcBZIAQDs_wIA9P9pUxrVuXTg2zH4nC-eDuKt76Y8r544qqPu0Jw1DRa6Szg_xUeEDmiDPA64kaWOq8yW4evU8al0GB0h877MvgrTPpMPJMmE5FnOEz2VQNmwMia9uxNmUVwZyAyziJOIiPYH0sji3IBN0T3jRVww39_sylhbomngbZVMlEI3SyjU82UYxte4IIGR8Xvy6E8V7HPkYiVrG92mbJaSwGOaoX3Mjda3IqF4ZtdZrEXV-EhCG3Og78CtaTBBNKAyxhBb_owYceDIFfcV4W3PEZtzFNPQBZOscZrd31ojm8Nbcje-s1pHEZIyDuqba_2rcfJ7P0tGZnb-BGskwoGjhrf8uZEY50EyWiBG4D-E4Bhy4msNL19SHzEqd_WhvyNcCRJbGaI6eFBB7q81F0JQO_TTPoXlgmSeszCyBUyBPp8-R_kpshlZLrgdSVo1aARYdT1tuds635TNZa6IVfeE0f9QssIpb-dSw_kp3TEv5ijzYTEqPIZVHQWKROfZd3sDRaIjRgYDLbS50LiUU-G7xAtx2ATleDzLahpnMTCscIInmLJcE9NyFPixF3yamvTWkcXTAx9Ghn6XhnKsEZA15kjoAzK4s6NDGoL8M8Uaf4mYM_vMB42z1roksREn6GAAJ_5wjOeDSdBAHRaDn1_4BJ_FYX_eoAl8eeoqDejBRLtEOM7HrmtxHV-9aZjmw2C5TjJOUdOKOuZApBQ_p6Do01bhbjSO57ZCo6737sn0fv7zjCFkEKth1yu-JBXKcWqfvAdAAHWHIl4AwIB2XOjjlck6j5Am9YuwC2W9nEyGIqYO-3bGDz0-PmADXzqsr2xguVPrd1jRMyTvWNcocN7XT0KhgQDOJtybwmm4vfZXZzk76aVBPCtDE2LCBl_-CGC097VbNus2EFtZlQTjXhFAHOsxo9JEKm2vgnHv8dd3gtvV5yRZ2iYfqjs0hRtiZX1sjkluqey4rmZNuCrCY-K2o7hkMP_cDuPTik0UuFPBgNN7SJAQYipUp-_KdknxgmeAkhu-iNkIgiDnZ_ZLUj2vFa6giKlxiPKEHhSI1UtflQWhPPn4BZjdKurkIGhkHto7aJ3-IRKq1X_G6fTvvCNNLMxY-9m8LzExrHo82keOXw" #PSAutomation_M365SecureApp1
$AccountId_3001 = $null
$AccountId_3001 = 'Abdullah@canadacomputing.ca'
$Appcredential_3001 = $null
$Appcredential_3001 = Get-Credential -ErrorAction Stop
$newPartnerAccessTokenSplat_azureToken_3001 = $null
$newPartnerAccessTokenSplat_azureToken_3001 = @{
    ApplicationId    = $Appcredential_3001.UserName
    Credential       = $Appcredential_3001
    RefreshToken     = $RefreshToken_3001 #comment out if you are usnig the UseAuthorizationCode parameter
    Scopes           = 'https://management.azure.com/user_impersonation'
    ServicePrincipal = $true
    Tenant           = $TenantID_3001
    # UseAuthorizationCode = $true #use only the first time to provide consent if you get a consent error
}
$azuretoken_3001 = $null
$azuretoken_3001 = New-PartnerAccessToken -ErrorAction Stop @newPartnerAccessTokenSplat_azureToken_3001
$newPartnerAccessTokenSplat_graphToken_3001 = $null
$newPartnerAccessTokenSplat_graphToken_3001 = @{
    ApplicationId    = $Appcredential_3001.UserName
    Credential       = $Appcredential_3001
    RefreshToken     = $RefreshToken_3001
    Scopes           = 'https://graph.windows.net/.default'
    ServicePrincipal = $true
    Tenant           = $TenantID_3001
    # UseAuthorizationCode = $true #use only the first time to provide consent if you get a consent error
}
$graphToken_3001 = $null
$graphToken_3001 = New-PartnerAccessToken -ErrorAction Stop @newPartnerAccessTokenSplat_graphToken_3001
$connectAzAccountSplat_3001 = $null;
$connectAzAccountSplat_3001 = @{
    AccessToken      = $azuretoken_3001.AccessToken
    AccountId        = $AccountId_3001
    GraphAccessToken = $graphToken_3001.AccessToken
    Tenant           = $TenantID_3001
}
Connect-AzAccount @connectAzAccountSplat_3001

