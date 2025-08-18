<#
.SYNOPSIS
    Azuresaingestionlogs Ms Mgmt Sa

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

<#
.SYNOPSIS
    We Enhanced Azuresaingestionlogs Ms Mgmt Sa

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionidFilter,
    [Parameter(Mandatory = $false)] [bool] $collectionFromAllSubscriptions = $false,
    [Parameter(Mandatory = $false)] [bool] $getAsmHeader = $true)



$WEErrorActionPreference = " Stop"

Write-Output " RB Initial Memory  : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB" 



$WEStartTime = [dateTime]::Now
$WETimestampfield = " Timestamp"


$timestamp = $WEStartTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:45:00.000Z" )



$customerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'


$sharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'



$WEApiVerSaAsm = '2016-04-01'
$WEApiVerSaArm = '2016-01-01'
$WEApiStorage = '2016-05-31'




$WEAAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'

$WEAAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'



$logname = 'AzureStorage'



$childrunbook = " AzureSAIngestionChild-MS-Mgmt-SA"
$schedulename = " AzureStorageIngestionChild-Schedule-MS-Mgmt-SA"




$hash = [hashtable]::New(@{})

$WEStarttimer = get-date -ErrorAction Stop






function New-tableSignature ($customerId, $sharedKey, $date, $method, $resource, $uri) {
    $stringToHash = $method + " `n" + " `n" + " `n" + $date + " `n" + " /" + $resource + $uri.AbsolutePath
    Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)  
    $querystr = ''
    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
   ;  $authorization = 'SharedKey {0}:{1}' -f $resource, $encodedHash
    return $authorization
	
}

function New-StorageSignature ($sharedKey, $date, $method, $bodylength, $resource, $uri , $service) {
    Add-Type -AssemblyName System.Web
   ;  $str = New-Object -TypeName " System.Text.StringBuilder" ;
    $builder = [System.Text.StringBuilder]::new(" /" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
   ;  $values2 = @{}
    IF ($service -eq 'Table') {
       ;  $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)  
        #    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
        foreach ($str2 in $values.Keys) {
            [System.Collections.ArrayList]$list = $values.GetValues($str2)
            $list.sort()
           ;  $builder2 = [System.Text.StringBuilder]::new()
			
            foreach ($obj2 in $list) {
                if ($builder2.Length -gt 0) {
                    $builder2.Append(" ," );
                }
                $builder2.Append($obj2.ToString()) |Out-Null
            }
            IF ($null -ne $str2) {
                $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
            } 
        }
		
        $list2 = [System.Collections.ArrayList]::new($values2.Keys)
        $list2.sort()
        foreach ($str3 in $list2) {
            IF ($str3 -eq 'comp') {
               ;  $builder3 = [System.Text.StringBuilder]::new()
                $builder3.Append($str3) |out-null
                $builder3.Append(" =" ) |out-null
                $builder3.Append($values2[$str3]) |out-null
                $str.Append(" ?" ) |out-null
                $str.Append($builder3.ToString())|out-null
            }
        }
    }
    Else {
       ;  $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)  
        #    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
        foreach ($str2 in $values.Keys) {
            [System.Collections.ArrayList]$list = $values.GetValues($str2)
            $list.sort()
           ;  $builder2 = [System.Text.StringBuilder]::new()
			
            foreach ($obj2 in $list) {
                if ($builder2.Length -gt 0) {
                    $builder2.Append(" ," );
                }
                $builder2.Append($obj2.ToString()) |Out-Null
            }
            IF ($null -ne $str2) {
                $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
            } 
        }
		
        $list2 = [System.Collections.ArrayList]::new($values2.Keys)
        $list2.sort()
        foreach ($str3 in $list2) {
			
           ;  $builder3 = [System.Text.StringBuilder]::new()
            $builder3.Append($str3) |out-null
            $builder3.Append(" :" ) |out-null
            $builder3.Append($values2[$str3]) |out-null
            $str.Append(" `n" ) |out-null
            $str.Append($builder3.ToString())|out-null
        }
    } 
    #   ;  $stringToHash = $stringToHash + $str.ToString();
    #$str.ToString()
    ############
    $xHeaders = " x-ms-date:" + $date + " `n" + " x-ms-version:$WEApiStorage"
    if ($service -eq 'Table') {
        $stringToHash = $method + " `n" + " `n" + " `n" + $date + " `n" + $str.ToString()
    }
    Else {
        IF ($method -eq 'GET' -or $method -eq 'HEAD') {
            $stringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + $xHeaders + " `n" + $str.ToString()
        }
        Else {
            $stringToHash = $method + " `n" + " `n" + " `n" + $bodylength + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + $xHeaders + " `n" + $str.ToString()
        }     
    }
    ##############
	

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $encodedHash
    return $authorization
	
}

Function invoke-StorageREST($sharedKey, $method, $msgbody, $resource, $uri, $svc, $download) {

    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )

	
    If ($method -eq 'PUT') {
        $signature = Build-StorageSignature `
            -sharedKey $sharedKey `
            -date  $rfc1123date `
            -method $method -resource $resource -uri $uri -bodylength $msgbody.length -service $svc
    }
    Else {

       ;  $signature = Build-StorageSignature `
            -sharedKey $sharedKey `
            -date  $rfc1123date `
            -method $method -resource $resource -uri $uri -body $body -service $svc
    } 

    If ($svc -eq 'Table') {
       ;  $headersforsa = @{
            'Authorization'         = " $signature"
            'x-ms-version'          = " $apistorage"
            'x-ms-date'             = " $rfc1123date"
            'Accept-Charset'        = 'UTF-8'
            'MaxDataServiceVersion' = '3.0;NetFx'
            #      'Accept'='application/atom+xml,application/json;odata=nometadata'
            'Accept'                = 'application/json;odata=nometadata'
        }
    }
    Else { 
        $headersforSA = @{
            'x-ms-date'     = " $rfc1123date"
            'Content-Type'  = 'application\xml'
            'Authorization' = " $signature"
            'x-ms-version'  = " $WEApiStorage"
        }
    }
	




    IF ($download) {
        $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"

		
        #$xresp=Get-Content -ErrorAction Stop " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
        return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"


    }
    Else {
        If ($svc -eq 'Table') {
            IF ($method -eq 'PUT') {  
                $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody  
                return $resp1
            }
            Else {
                $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody 

                $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" )) 
            } 
            return $xresp

        }
        Else {
            IF ($method -eq 'PUT') {  
                $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody 
                return $resp1
            }
            Elseif ($method -eq 'GET') {
                $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0

                $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" )) 
                return $xresp
            }
            Elseif ($method -eq 'HEAD') {
                $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody 

				
                return $resp1
            }
        }
    }
}


function WE-Get-BlobSize -ErrorAction Stop ($bloburi, $storageaccount, $rg, $type) {

    If ($type -eq 'ARM') {
        $WEUri = " https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $WEApiVerSaArm, $storageaccount, $rg, $WESubscriptionId 
        $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
        $keys = ConvertFrom-Json -InputObject $keyresp.Content
        $prikey = $keys.keys[0].value
    }
    Elseif ($type -eq 'Classic') {
        $WEUri = " https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $WEApiVerSaAsm, $storageaccount, $rg, $WESubscriptionId 
        $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
        $keys = ConvertFrom-Json -InputObject $keyresp.Content
        $prikey = $keys.primaryKey
    }
    Else {
        " Could not detect storage account type, $storageaccount will not be processed"
        Continue
    }





    $vhdblob = invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
	
    Return [math]::round($vhdblob.Headers.'Content-Length' / 1024 / 1024 / 1024, 0)



}		

function New-OMSSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
    $xHeaders = " x-ms-date:" + $date
    $stringToHash = $method + " `n" + $contentLength + " `n" + $contentType + " `n" + $xHeaders + " `n" + $resource
    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
    return $authorization
}

Function Post-OMSData($customerId, $sharedKey, $body, $logType) {


    #usage     Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
    $method = " POST"
    $contentType = " application/json"
    $resource = " /api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $contentLength = $body.Length
    $signature = Build-OMSSignature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -fileName $fileName `
        -method $method `
        -contentType $contentType `
        -resource $resource
   ;  $uri = " https://" + $customerId + " .ods.opinsights.azure.com" + $resource + " ?api-version=2016-04-01"
   ;  $WEOMSheaders = @{
        " Authorization"        = $signature;
        " Log-Type"             = $logType;
        " x-ms-date"            = $rfc1123date;
        " time-generated-field" = $WETimeStampField;
    }

    Try {
        $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $contentType -Headers $WEOMSheaders -Body $body -UseBasicParsing
    }catch [Net.WebException] {
       ;  $ex = $_.Exception
        If ($_.Exception.Response.StatusCode.value__) {
           ;  $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
            #Write-Output $crap;
        }
        If ($_.Exception.Message) {
            $exMessage = ($_.Exception.Message).ToString().Trim();
            #Write-Output $crapMessage;
        }
        $errmsg = " $exrespcode : $exMessage"
    }

    if ($errmsg) {return $errmsg }
    Else {	return $response.StatusCode }
    #write-output $response.StatusCode
    Write-error $error[0]
}



[CmdletBinding()]
function WE-Cleanup-Variables {

    Get-Variable -ErrorAction Stop |

    Where-Object { $startupVariables -notcontains $_.Name } |

    % { Remove-Variable -Name “$($_.Name)” -Force -Scope “global” }

}







" Logging in to Azure..."
$WEArmConn = Get-AutomationConnection -Name AzureRunAsConnection 

if ($null -eq $WEArmConn)
{
	throw " Could not retrieve connection asset AzureRunAsConnection,  Ensure that runas account  exists in the Automation account."
}


$retry = 6
$syncOk = $false
do
{ 
	try
	{  
		Add-AzureRMAccount -ServicePrincipal -Tenant $WEArmConn.TenantID -ApplicationId $WEArmConn.ApplicationID -CertificateThumbprint $WEArmConn.CertificateThumbprint
		$syncOk = $true
	}
	catch
	{
		$WEErrorMessage = $_.Exception.Message
		$WEStackTrace = $_.Exception.StackTrace
		Write-Warning " Error during sync: $WEErrorMessage, stack: $WEStackTrace. Retry attempts left: $retry"
		$retry = $retry - 1       
		Start-Sleep -s 60        
	}
} while (-not $syncOk -and $retry -ge 0)
" Selecting Azure subscription..."
$WESelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $WEArmConn.SubscriptionId -TenantId $WEArmConn.tenantid 

$subscriptionid=$WEArmConn.SubscriptionId
" Azure rm profile path  $((get-module -Name AzureRM.Profile).path) "
$path=(get-module -Name AzureRM.Profile).path
$path=Split-Path $path
$dlllist=Get-ChildItem -Path $path  -Filter Microsoft.IdentityModel.Clients.ActiveDirectory.dll  -Recurse
$adal =  $dlllist[0].VersionInfo.FileName
try
{
	Add-type -Path $adal
	[reflection.assembly]::LoadWithPartialName( " Microsoft.IdentityModel.Clients.ActiveDirectory" )
}
catch
{
	$WEErrorMessage = $_.Exception.Message
	$WEStackTrace = $_.Exception.StackTrace
	Write-Warning " Error during sync: $WEErrorMessage, stack: $WEStackTrace. "
}

$certs= Get-ChildItem -Path Cert:\Currentuser\my -Recurse | Where{$_.Thumbprint -eq $WEArmConn.CertificateThumbprint}

[System.Security.Cryptography.X509Certificates.X509Certificate2]$mycert=$certs[0]

$WECliCert=new-object -ErrorAction Stop   Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($WEArmConn.ApplicationId,$mycert)
$WEAuthContext = new-object -ErrorAction Stop Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($WEArmConn.tenantid)" )
$result = $WEAuthContext.AcquireToken(" https://management.core.windows.net/" ,$WECliCert); 
$header = " Bearer " + $result.AccessToken; 
$headers = @{" Authorization" =$header;" Accept" =" application/json" }
$body=$null
$WEHTTPVerb=" GET"
$subscriptionInfoUri = " https://management.azure.com/subscriptions/" +$subscriptionid+" ?api-version=2016-02-01"
$subscriptionInfo = Invoke-RestMethod -Uri $subscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($subscriptionInfo)
{
	" Successfully connected to Azure ARM REST"
}



if ($getAsmHeader) {
    
	try
    {
        $WEAsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection -ea 0
       
    }
    Catch
    {
        if ($null -eq $WEAsmConn) {
            Write-Warning " Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account."
            $getAsmHeader=$false
        }
    }
     if ($null -eq $WEAsmConn) {
        Write-Warning " Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account. Quota usage infomration for classic accounts will no tbe collected"
        $getAsmHeader=$false
    }Else{

        $WECertificateAssetName = $WEAsmConn.CertificateAssetName
        $WEAzureCert = Get-AutomationCertificate -Name $WECertificateAssetName
        if ($null -eq $WEAzureCert)
        {
            Write-Warning  " Could not retrieve certificate asset: $WECertificateAssetName. Ensure that this asset exists and valid  in the Automation account."
            $getAsmHeader=$false
        }
        Else{

        " Logging into Azure Service Manager"
        Write-Verbose " Authenticating to Azure with certificate." -Verbose
        Set-AzureSubscription -SubscriptionName $WEAsmConn.SubscriptionName -SubscriptionId $WEAsmConn.SubscriptionId -Certificate $WEAzureCert
        Select-AzureSubscription -SubscriptionId $WEAsmConn.SubscriptionId
        #finally create the headers for ASM REST 
        $headerasm = @{" x-ms-version" =" 2013-08-01" }
        }
    }

}






$WESubscriptionsURI = " https://management.azure.com/subscriptions?api-version=2016-06-01" 
$WESubscriptions = Invoke-RestMethod -Uri  $WESubscriptionsURI -Method GET  -Headers $headers -UseBasicParsing 
$WESubscriptions = @($WESubscriptions.value)


IF ($collectionFromAllSubscriptions -and $WESubscriptions.count -gt 1 ) {
    Write-Output " $($WESubscriptions.count) Subscription found , additonal runbook jobs will be created to collect data "
    $WEAAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $WEAAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $WELogsRunbookName = " AzureSAIngestionLogs-MS-Mgmt-SA"

    #we will process first subscription with this runbook and  pass the rest to additional jobs

    #$n=$WESubscriptions.count-1
    #$subslist=$WESubscriptions[-$n..-1]
	
   ;  $subslist = $subscriptions|where {$_.subscriptionId -ne $subscriptionId}
    Foreach ($item in $subslist) {

       ;  $params1 = @{" SubscriptionidFilter" = $item.subscriptionId; " collectionFromAllSubscriptions" = $false; " getAsmHeader" = $false}
        Start-AzureRmAutomationRunbook -AutomationAccountName $WEAAAccount -Name $WELogsRunbookName -ResourceGroupName $WEAAResourceGroup -Parameters $params1 | out-null
    }
}









" $(GEt-date) - Get ARM storage Accounts "

$WEUri = " https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}" -f $WEApiVerSaArm, $WESubscriptionId 
$armresp = Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
$saArmList = $armresp.Value
" $(GEt-date)  $($saArmList.count) classic storage accounts found"


" $(GEt-date)  Get Classic storage Accounts "

$WEUri = " https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}" -f $WEApiVerSaAsm, $WESubscriptionId 

$asmresp = Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
$saAsmList = $asmresp.value

" $(GEt-date)  $($saAsmList.count) storage accounts found"




$colParamsforChild = @()

foreach ($sa in $saArmList|where {$_.Sku.tier -ne 'Premium'}) {

    $rg =;  $sku = $null

   ;  $rg = $sa.id.Split('/')[4]

   ;  $colParamsforChild = $colParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier);$($sa.Kind)"
	
}


$sa = $rg = $null

foreach ($sa in $saAsmList|where {$_.properties.accounttype -notmatch 'Premium'}) {

    $rg = $sa.id.Split('/')[4]
   ;  $tier = $null

    # array  wth SAName,ReouceGroup,Prikey,Tier 

    If ( $sa.properties.accountType -notmatch 'premium') {
       ;  $tier = 'Standard'
       ;  $colParamsforChild = $colParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier;$($sa.Kind)"
    }

	

}


Write-Output " Core Count  $([System.Environment]::ProcessorCount)"



if ($colParamsforChild.count -eq 0) {
    Write-Output " No Storage account found under subscription $subscriptionid , please note that Premium storage does not support metrics and excluded from the collection!"
    exit
}


$sa = $null
$logTracker = @()
$blobdate = (Get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy/MM/dd/HH00" )




$hash['Host'] = $host
$hash['subscriptionInfo'] = $subscriptionInfo
$hash['ArmConn'] = $WEArmConn
$hash['AsmConn'] = $WEAsmConn
$hash['headers'] = $headers
$hash['headerasm'] = $headers
$hash['AzureCert'] = $WEAzureCert
$hash['Timestampfield'] = $WETimestampfield

$hash['customerID'] = $customerID
$hash['syncInterval'] = $syncInterval
$hash['sharedKey'] = $sharedKey 
$hash['Logname'] = $logname

$hash['ApiVerSaAsm'] = $WEApiVerSaAsm
$hash['ApiVerSaArm'] = $WEApiVerSaArm
$hash['ApiStorage'] = $WEApiStorage
$hash['AAAccount'] = $WEAAAccount
$hash['AAResourceGroup'] = $WEAAResourceGroup

$hash['debuglog'] = $true

$hash['logTracker'] = @()



$WESAInfo = @()
$hash.'SAInfo' = $sainfo



$WEThrottle = [int][System.Environment]::ProcessorCount + 1  #threads

$sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
$runspacepool = [runspacefactory]::CreateRunspacePool(1, $WEThrottle, $sessionstate, $WEHost)
$runspacepool.Open() 
[System.Collections.ArrayList]$WEJobs = @()


$scriptBlock = {

    Param ($hash, [array]$WESa, $rsid)

    $subscriptionInfo = $hash.subscriptionInfo
    $WEArmConn = $hash.ArmConn
    $headers = $hash.headers
    $WEAsmConn = $hash.AsmConn
    $headerasm = $hash.headerasm
    $WEAzureCert = $hash.AzureCert

    $WETimestampfield = $hash.Timestampfield

    $WECurrency = $hash.Currency
    $WELocale = $hash.Locale
    $WERegionInfo = $hash.RegionInfo
    $WEOfferDurableId = $hash.OfferDurableId
    $syncInterval = $WEHash.syncInterval
    $customerID = $hash.customerID 
    $sharedKey = $hash.sharedKey
    $logname = $hash.Logname
    $WEStartTime = [dateTime]::Now
    $WEApiVerSaAsm = $hash.ApiVerSaAsm
    $WEApiVerSaArm = $hash.ApiVerSaArm
    $WEApiStorage = $hash.ApiStorage
    $WEAAAccount = $hash.AAAccount
    $WEAAResourceGroup = $hash.AAResourceGroup
    $debuglog = $hash.deguglog



    #Inventory variables
    $varQueueList = " AzureSAIngestion-List-Queues"
    $varFilesList = " AzureSAIngestion-List-Files"

    $subscriptionId = $subscriptionInfo.subscriptionId


    #region Define Required Functions

    function New-tableSignature ($customerId, $sharedKey, $date, $method, $resource, $uri) {
        $stringToHash = $method + " `n" + " `n" + " `n" + $date + " `n" + " /" + $resource + $uri.AbsolutePath
        Add-Type -AssemblyName System.Web
        $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)  
        $querystr = ''
        $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
        $keyBytes = [Convert]::FromBase64String($sharedKey)
        $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
        $sha256.Key = $keyBytes
        $calculatedHash = $sha256.ComputeHash($bytesToHash)
        $encodedHash = [Convert]::ToBase64String($calculatedHash)
       ;  $authorization = 'SharedKey {0}:{1}' -f $resource, $encodedHash
        return $authorization
		
    }
    # Create the function to create the authorization signature
    function New-StorageSignature ($sharedKey, $date, $method, $bodylength, $resource, $uri , $service) {
        Add-Type -AssemblyName System.Web
       ;  $str = New-Object -TypeName " System.Text.StringBuilder" ;
        $builder = [System.Text.StringBuilder]::new(" /" )
        $builder.Append($resource) |out-null
        $builder.Append($uri.AbsolutePath) | out-null
        $str.Append($builder.ToString()) | out-null
       ;  $values2 = @{}
        IF ($service -eq 'Table') {
           ;  $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)  
            #    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
            foreach ($str2 in $values.Keys) {
                [System.Collections.ArrayList]$list = $values.GetValues($str2)
                $list.sort()
               ;  $builder2 = [System.Text.StringBuilder]::new()
				
                foreach ($obj2 in $list) {
                    if ($builder2.Length -gt 0) {
                        $builder2.Append(" ," );
                    }
                    $builder2.Append($obj2.ToString()) |Out-Null
                }
                IF ($null -ne $str2) {
                    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
                } 
            }
			
            $list2 = [System.Collections.ArrayList]::new($values2.Keys)
            $list2.sort()
            foreach ($str3 in $list2) {
                IF ($str3 -eq 'comp') {
                   ;  $builder3 = [System.Text.StringBuilder]::new()
                    $builder3.Append($str3) |out-null
                    $builder3.Append(" =" ) |out-null
                    $builder3.Append($values2[$str3]) |out-null
                    $str.Append(" ?" ) |out-null
                    $str.Append($builder3.ToString())|out-null
                }
            }
        }
        Else {
           ;  $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)  
            #    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
            foreach ($str2 in $values.Keys) {
                [System.Collections.ArrayList]$list = $values.GetValues($str2)
                $list.sort()
               ;  $builder2 = [System.Text.StringBuilder]::new()
				
                foreach ($obj2 in $list) {
                    if ($builder2.Length -gt 0) {
                        $builder2.Append(" ," );
                    }
                    $builder2.Append($obj2.ToString()) |Out-Null
                }
                IF ($null -ne $str2) {
                    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
                } 
            }
			
            $list2 = [System.Collections.ArrayList]::new($values2.Keys)
            $list2.sort()
            foreach ($str3 in $list2) {
				
               ;  $builder3 = [System.Text.StringBuilder]::new()
                $builder3.Append($str3) |out-null
                $builder3.Append(" :" ) |out-null
                $builder3.Append($values2[$str3]) |out-null
                $str.Append(" `n" ) |out-null
                $str.Append($builder3.ToString())|out-null
            }
        } 
        #   ;  $stringToHash = $stringToHash + $str.ToString();
        #$str.ToString()
        ############
        $xHeaders = " x-ms-date:" + $date + " `n" + " x-ms-version:$WEApiStorage"
        if ($service -eq 'Table') {
            $stringToHash = $method + " `n" + " `n" + " `n" + $date + " `n" + $str.ToString()
        }
        Else {
            IF ($method -eq 'GET' -or $method -eq 'HEAD') {
                $stringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + $xHeaders + " `n" + $str.ToString()
            }
            Else {
                $stringToHash = $method + " `n" + " `n" + " `n" + $bodylength + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + $xHeaders + " `n" + $str.ToString()
            }     
        }
        ##############
		

        $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
        $keyBytes = [Convert]::FromBase64String($sharedKey)
        $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
        $sha256.Key = $keyBytes
        $calculatedHash = $sha256.ComputeHash($bytesToHash)
        $encodedHash = [Convert]::ToBase64String($calculatedHash)
        $authorization = 'SharedKey {0}:{1}' -f $resource, $encodedHash
        return $authorization
		
    }
    # Create the function to create and post the request
    Function invoke-StorageREST($sharedKey, $method, $msgbody, $resource, $uri, $svc, $download) {

        $rfc1123date = [DateTime]::UtcNow.ToString(" r" )

		
        If ($method -eq 'PUT') {
            $signature = Build-StorageSignature `
                -sharedKey $sharedKey `
                -date  $rfc1123date `
                -method $method -resource $resource -uri $uri -bodylength $msgbody.length -service $svc
        }
        Else {

           ;  $signature = Build-StorageSignature `
                -sharedKey $sharedKey `
                -date  $rfc1123date `
                -method $method -resource $resource -uri $uri -body $body -service $svc
        } 

        If ($svc -eq 'Table') {
           ;  $headersforsa = @{
                'Authorization'         = " $signature"
                'x-ms-version'          = " $apistorage"
                'x-ms-date'             = " $rfc1123date"
                'Accept-Charset'        = 'UTF-8'
                'MaxDataServiceVersion' = '3.0;NetFx'
                #      'Accept'='application/atom+xml,application/json;odata=nometadata'
                'Accept'                = 'application/json;odata=nometadata'
            }
        }
        Else { 
            $headersforSA = @{
                'x-ms-date'     = " $rfc1123date"
                'Content-Type'  = 'application\xml'
                'Authorization' = " $signature"
                'x-ms-version'  = " $WEApiStorage"
            }
        }
		




        IF ($download) {
            $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"

			
            #$xresp=Get-Content -ErrorAction Stop " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
            return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"


        }
        Else {
            If ($svc -eq 'Table') {
                IF ($method -eq 'PUT') {  
                    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody  
                    return $resp1
                }
                Else {
                    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody 

                    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" )) 
                } 
                return $xresp

            }
            Else {
                IF ($method -eq 'PUT') {  
                    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody 
                    return $resp1
                }
                Elseif ($method -eq 'GET') {
                    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0

                    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" )) 
                    return $xresp
                }
                Elseif ($method -eq 'HEAD') {
                    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody 

					
                    return $resp1
                }
            }
        }
    }
    #get blob file size in gb 

    function WE-Get-BlobSize -ErrorAction Stop ($bloburi, $storageaccount, $rg, $type) {

        If ($type -eq 'ARM') {
            $WEUri = " https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $WEApiVerSaArm, $storageaccount, $rg, $WESubscriptionId 
            $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
            $keys = ConvertFrom-Json -InputObject $keyresp.Content
            $prikey = $keys.keys[0].value
        }
        Elseif ($type -eq 'Classic') {
            $WEUri = " https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $WEApiVerSaAsm, $storageaccount, $rg, $WESubscriptionId 
            $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
            $keys = ConvertFrom-Json -InputObject $keyresp.Content
            $prikey = $keys.primaryKey
        }
        Else {
            " Could not detect storage account type, $storageaccount will not be processed"
            Continue
        }





        $vhdblob = invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
		
        Return [math]::round($vhdblob.Headers.'Content-Length' / 1024 / 1024 / 1024, 0)



    }		
    # Create the function to create the authorization signature
    function New-OMSSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
        $xHeaders = " x-ms-date:" + $date
        $stringToHash = $method + " `n" + $contentLength + " `n" + $contentType + " `n" + $xHeaders + " `n" + $resource
        $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
        $keyBytes = [Convert]::FromBase64String($sharedKey)
        $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
        $sha256.Key = $keyBytes
        $calculatedHash = $sha256.ComputeHash($bytesToHash)
        $encodedHash = [Convert]::ToBase64String($calculatedHash)
        $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
        return $authorization
    }
    # Create the function to create and post the request
    Function Post-OMSData($customerId, $sharedKey, $body, $logType) {


        #usage     Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
        $method = " POST"
        $contentType = " application/json"
        $resource = " /api/logs"
        $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
        $contentLength = $body.Length
        $signature = Build-OMSSignature `
            -customerId $customerId `
            -sharedKey $sharedKey `
            -date $rfc1123date `
            -contentLength $contentLength `
            -fileName $fileName `
            -method $method `
            -contentType $contentType `
            -resource $resource
       ;  $uri = " https://" + $customerId + " .ods.opinsights.azure.com" + $resource + " ?api-version=2016-04-01"
       ;  $WEOMSheaders = @{
            " Authorization"        = $signature;
            " Log-Type"             = $logType;
            " x-ms-date"            = $rfc1123date;
            " time-generated-field" = $WETimeStampField;
        }

        Try {
            $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $contentType -Headers $WEOMSheaders -Body $body -UseBasicParsing
        }catch [Net.WebException] {
           ;  $ex = $_.Exception
            If ($_.Exception.Response.StatusCode.value__) {
               ;  $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
                #Write-Output $crap;
            }
            If ($_.Exception.Message) {
                $exMessage = ($_.Exception.Message).ToString().Trim();
                #Write-Output $crapMessage;
            }
            $errmsg = " $exrespcode : $exMessage"
        }

        if ($errmsg) {return $errmsg }
        Else {	return $response.StatusCode }
        #write-output $response.StatusCode
        Write-error $error[0]
    }



    #endregion



    $prikey = $storageaccount = $rg =;  $type = $null
   ;  $storageaccount = $sa.Split(';')[0]
    $rg = $sa.Split(';')[1]
    $type = $sa.Split(';')[2]
    $tier = $sa.Split(';')[3]
    $kind = $sa.Split(';')[4]


    If ($type -eq 'ARM') {
        $WEUri = " https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $WEApiVerSaArm, $storageaccount, $rg, $WESubscriptionId 
        $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
        $keys = ConvertFrom-Json -InputObject $keyresp.Content
        $prikey = $keys.keys[0].value


    }
    Elseif ($type -eq 'Classic') {
        $WEUri = " https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $WEApiVerSaAsm, $storageaccount, $rg, $WESubscriptionId 
        $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
        $keys = ConvertFrom-Json -InputObject $keyresp.Content
        $prikey = $keys.primaryKey


    }
    Else {
		
        " Could not detect storage account type, $storageaccount will not be processed"
        Continue
		

    }

    #check if metrics are enabled
    IF ($kind -eq 'BlobStorage') {
        $svclist = @('blob', 'table')
    }
    Else {
        $svclist = @('blob', 'table', 'queue')
    }


    $logging = $false

    Foreach ($svc in $svclist) {


		
        [uri]$uriSvcProp = " https://{0}.{1}.core.windows.net/?restype=service&comp=properties	" -f $storageaccount, $svc

        IF ($svc -eq 'table') {
            [xml]$WESvcPropResp = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriSvcProp -svc Table
			
        }
        else {
            [xml]$WESvcPropResp = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriSvcProp 
			
        }

        IF ($WESvcPropResp.StorageServiceProperties.Logging.Read -eq 'true' -or $WESvcPropResp.StorageServiceProperties.Logging.Write -eq 'true' -or $WESvcPropResp.StorageServiceProperties.Logging.Delete -eq 'true') {
            $msg = " Logging is enabled for {0} in {1}" -f $svc, $storageaccount
            #Write-output $msg

            $logging = $true

			

			
        }
        Else {
            $msg = " Logging is not  enabled for {0} in {1}" -f $svc, $storageaccount

        }


    }


    $hash.SAInfo += New-Object -ErrorAction Stop PSObject -Property @{
        StorageAccount = $storageaccount
        Key            = $prikey
        Logging        = $logging
        Rg             = $rg
        Type           = $type
        Tier           = $tier
        Kind           = $kind

    }


}


write-output " $($colParamsforChild.count) objects will be processed "

$i = 1 

$WEStarttimer = get-date -ErrorAction Stop



$colParamsforChild|foreach {

    $splitmetrics = $null
    $splitmetrics = $_
    $WEJob = [powershell]::Create().AddScript($WEScriptBlock).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $WEJob.RunspacePool = $WERunspacePool
    $WEJobs = $WEJobs + New-Object -ErrorAction Stop PSObject -Property @{
        RunNum = $i
        Pipe   = $WEJob
        Result = $WEJob.BeginInvoke()

    }
	
    $i++
}

write-output  " $(get-date)  , started $i Runspaces "
Write-Output " After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
$jobsClone = $jobs.clone()
Write-Output " Waiting.."



$s = 1
Do {

    Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"

    foreach ($jobobj in $WEJobsClone) {

        if ($WEJobobj.result.IsCompleted -eq $true) {
            $jobobj.Pipe.Endinvoke($jobobj.Result)
            $jobobj.pipe.dispose()
            $jobs.Remove($jobobj)
        }
    }


    IF ($([System.gc]::gettotalmemory('forcefullcollection') / 1MB) -gt 200) {
        [gc]::Collect()
    }


    IF ($s % 10 -eq 0) {
        Write-Output " Job $s - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    }  
    $s++
	
    Start-Sleep -Seconds 15


} While ( @($jobs.result.iscompleted|where {$_ -match 'False'}).count -gt 0)
Write-output " All jobs completed!"



$jobs|foreach {$_.Pipe.Dispose()}
Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global
Remove-Variable -ErrorAction Stop Job -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global

$runspacepool.Close()

[gc]::Collect()



$startupVariables = ””

new-variable -force -name startupVariables -value ( Get-Variable -ErrorAction Stop |

    % { $_.Name } )

Write-Output " Memory After Initial pool for keys : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB" 




$sa = $null
$logTracker = @()
$blobdate = (Get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy/MM/dd/HH00" )

$s = 1


write-output $hash.SAInfo|select Logging , storageaccount


foreach ($sa in @($hash.SAInfo|Where {$_.Logging -eq 'True' -and $_.key -ne $null})) {

    $prikey = $sa.key
    $storageaccount = $sa.StorageAccount
    $rg = $sa.rg
    $type = $sa.Type
    $tier = $sa.Tier
    $kind = $sa.Kind





    $logArray = @()
    $WELogcount = 0
    $WELogSize = 0

    Foreach ($svc in @('blob', 'table', 'queue')) {

        $blobs = @()
        $prefix = $svc + " /" + $blobdate
		
        [uri]$uriLBlobs = " https://{0}.blob.core.windows.net/`$logs`?restype=container&comp=list&prefix={1}&maxresults=1000" -f $storageaccount, $prefix
        [xml]$fresponse = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriLBlobs
		
        $content = $null
        $content = $fresponse.EnumerationResults
        $blobs = $blobs + $content.Blobs.blob

        REmove-Variable -Name fresponse
		
        IF (![string]::IsNullOrEmpty($content.NextMarker)) {
            do {
                [uri]$uriLogs2 = " https://{0}.blob.core.windows.net/`$logs`?restype=container&comp=list&maxresults=1000&marker={1}" -f $storageaccount, $content.NextMarker

                $content = $null
                [xml]$WELogresp2 = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriLogs2 

                $content = $WELogresp2.EnumerationResults

                $blobs = $blobs + $content.Blobs.Blob
                # $blobsall = $blobsall + $blobs

                $uriLogs2 = $null

            }While (![string]::IsNullOrEmpty($content.NextMarker))
        }

		
        $fresponse = $logresp2 = $null


        IF ($blobs) {
            Foreach ($blob in $blobs) {

                [uri]$uriLogs3 = " https://{0}.blob.core.windows.net/`$logs/{1}" -f $storageaccount, $blob.Name

                $content = $null
                $auditlog = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriLogs3 -download $true 

                if (Test-Path $auditlog) {
                   ;  $file = New-Object -ErrorAction Stop System.IO.StreamReader -Arg $auditlog
					
                    while ($line = $file.ReadLine()) {
						

                       ;  $splitline = [regex]::Split( $line , ';(?=(?:[^" ]|" [^" ]*" )*$)' )

                        $logArray = $logArray + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp          = $splitline[1]
                            MetricName         = 'AuditLogs'
                            StorageAccount     = $storageaccount
                            StorageService     = $splitline[10]
                            Operation          = $splitline[2]
                            Status             = $splitline[3]
                            StatusCode         = $splitline[4]
                            E2ELatency         = [int]$splitline[5]
                            ServerLatency      = [int]$splitline[6]
                            AuthenticationType = $splitline[7]	 
                            Requesteraccount   = $splitline[8]
                            Resource           = $splitline[12].Replace('" ', '')
                            RequesterIP        = $splitline[15].Split(':')[0]
                            UserAgent          = $splitline[27].Replace('" ', '')
                            SubscriptionId     = $WEArmConn.SubscriptionId;
                            AzureSubscription  = $subscriptionInfo.displayName;
                        }
						
                    }
                    $file.close()

                    $file = get-item -ErrorAction Stop $auditlog 
                    $WELogcount++
                    $WELogSize = $WELogSize + [Math]::Round($file.Length / 1024, 0)
                    Remove-Item -ErrorAction Stop $auditl -Forceo -Forceg -Force


                    #push data into oms if specific thresholds are reached 
                    IF ($logArray.count -gt 5000 -or $([System.gc]::gettotalmemory('forcefullcollection') / 1MB) -gt 150) {
                        write-output " $($logArray.count)  logs consumed $([System.gc]::gettotalmemory('forcefullcollection') /1MB) , uploading data  to OMS"

                        $jsonlogs = ConvertTo-Json -InputObject $logArray
                        $logarray = @()

                        Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

                        remove-variable -ErrorAction Stop jsonlogs -force 
                        [gc]::Collect()
						
                    }



                }
				
            }
            $auditlog = $file = $null
        }
        write-output " $($blobs.count)  log file processed for $storageaccount. $($logarray.count) records wil be uploaded"
    }
    Remove-Variable -Name Blobs
    $logTracker = $logTracker + New-Object -ErrorAction Stop PSObject -Property @{
        StorageAccount = $storageaccount
        Logcount       = $WELogcount
        LogSizeinKB    = $WELogSize            
    }
	
}




If ($logArray) {
   ;  $splitSize = 5000
    If ($logArray.count -gt $splitSize) {
       ;  $spltlist = @()
       ;  $spltlist = $spltlist + for ($WEIndex = 0; $WEIndex -lt $logArray.count; $WEIndex = $WEIndex + $splitSize) {
            , ($logArray[$index..($index + $splitSize - 1)])
        }
		
		
        $spltlist|foreach {
            $splitLogs = $null
            $splitLogs = $_
           ;  $jsonlogs = ConvertTo-Json -InputObject $splitLogs
            Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

        }



    }
    Else {

       ;  $jsonlogs = ConvertTo-Json -InputObject $logArray

        Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

    }
}


IF ($s % 10 -eq 0) {
    Write-Output " Job $s - SA $storageaccount -Logsize : $logsize - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
}  
$s++


Remove-Variable -Name  logArray -ea 0
Remove-Variable -Name  fresponse -ea 0
Remove-Variable -Name  auditlog -ea 0
Remove-Variable -Name  jsonlogs  -ea 0
[gc]::Collect()







# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================