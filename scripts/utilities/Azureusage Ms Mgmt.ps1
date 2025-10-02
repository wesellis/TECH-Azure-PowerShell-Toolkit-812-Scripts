#Requires -Version 7.4

<#`n.SYNOPSIS
    Azureusage Ms Mgmt

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
function Write-Log {
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
[Parameter()]$Currency   ,
[Parameter()]$Locale   ,
[Parameter()]$RegionInfo   ,
[Parameter()]$OfferDurableId ,
[Parameter()][bool]$propagatetags=$true ,
[Parameter()]$SyncInterval='Hourly'
)
    $Timestampfield = "Timestamp"
    $log=@()
    $ApiVersion = '2015-06-01-preview'
IF([String]::IsNullOrEmpty($Currency)){  $Currency = 'USD' }
IF([String]::IsNullOrEmpty($Locale)){ $Locale = 'en-US'}
    $regionlist=@{}
    $regionlist.Add("Australia" ,"AU" )
    $regionlist.Add("Afghanistan" ,"AF" )
    $regionlist.Add("Albania" ,"AL" )
    $regionlist.Add("Algeria" ,"DZ" )
    $regionlist.Add("Angola" ,"AO" )
    $regionlist.Add("Argentina" ,"AR" )
    $regionlist.Add("Armenia" ,"AM" )
    $regionlist.Add("Austria" ,"AT" )
    $regionlist.Add("Azerbaijan" ,"AZ" )
    $regionlist.Add("Bahamas" ,"BS" )
    $regionlist.Add("Bahrain" ,"BH" )
    $regionlist.Add("Bangladesh" ,"BD" )
    $regionlist.Add("Barbados" ,"BB" )
    $regionlist.Add("Belarus" ,"BY" )
    $regionlist.Add("Belgium" ,"BE" )
    $regionlist.Add("Belize" ,"BZ" )
    $regionlist.Add("Bermuda" ,"BM" )
    $regionlist.Add("Bolivia" ,"BO" )
    $regionlist.Add("Bosnia and Herzegovina" ,"BA" )
    $regionlist.Add("Botswana" ,"BW" )
    $regionlist.Add("Brazil" ,"BR" )
    $regionlist.Add("Brunei" ,"BN" )
    $regionlist.Add("Bulgaria" ,"BG" )
    $regionlist.Add("Cameroon" ,"CM" )
    $regionlist.Add("Canada" ,"CA" )
    $regionlist.Add("Cape Verde" ,"CV" )
    $regionlist.Add("Cayman Islands" ,"KY" )
    $regionlist.Add("Chile" ,"CL" )
    $regionlist.Add("Colombia" ,"CO" )
    $regionlist.Add("Costa Rica" ,"CR" )
    $regionlist.Add("C��te D'ivoire" ,"CI" )
    $regionlist.Add("Croatia" ,"HR" )
    $regionlist.Add("Cura��ao" ,"CW" )
    $regionlist.Add("Cyprus" ,"CY" )
    $regionlist.Add("Czech Republic" ,"CZ" )
    $regionlist.Add("Denmark" ,"DK" )
    $regionlist.Add("Dominican Republic" ,"DO" )
    $regionlist.Add("Ecuador" ,"EC" )
    $regionlist.Add("Egypt" ,"EG" )
    $regionlist.Add("El Salvador" ,"SV" )
    $regionlist.Add("Estonia" ,"EE" )
    $regionlist.Add("Ethiopia" ,"ET" )
    $regionlist.Add("Faroe Islands" ,"FO" )
    $regionlist.Add("Fiji" ,"FJ" )
    $regionlist.Add("Finland" ,"FI" )
    $regionlist.Add("France" ,"FR" )
    $regionlist.Add("Georgia" ,"GE" )
    $regionlist.Add("Germany" ,"DE" )
    $regionlist.Add("Ghana" ,"GH" )
    $regionlist.Add("Greece" ,"GR" )
    $regionlist.Add("Guatemala" ,"GT" )
    $regionlist.Add("Honduras" ,"HN" )
    $regionlist.Add("Hong Kong SAR" ,"HK" )
    $regionlist.Add("Hungary" ,"HU" )
    $regionlist.Add("Iceland" ,"IS" )
    $regionlist.Add("India" ,"IN" )
    $regionlist.Add("Indonesia" ,"ID" )
    $regionlist.Add("Iraq" ,"IQ" )
    $regionlist.Add("Ireland" ,"IE" )
    $regionlist.Add("Israel" ,"IL" )
    $regionlist.Add("Italy" ,"IT" )
    $regionlist.Add("Jamaica" ,"JM" )
    $regionlist.Add("Japan" ,"JP" )
    $regionlist.Add("Jordan" ,"JO" )
    $regionlist.Add("Kazakhstan" ,"KZ" )
    $regionlist.Add("Kenya" ,"KE" )
    $regionlist.Add("Korea" ,"KR" )
    $regionlist.Add("Kuwait" ,"KW" )
    $regionlist.Add("Kyrgyzstan" ,"KG" )
    $regionlist.Add("Latvia" ,"LV" )
    $regionlist.Add("Lebanon" ,"LB" )
    $regionlist.Add("Libya" ,"LY" )
    $regionlist.Add("Liechtenstein" ,"LI" )
    $regionlist.Add("Lithuania" ,"LT" )
    $regionlist.Add("Luxembourg" ,"LU" )
    $regionlist.Add("Macao SAR" ,"MO" )
    $regionlist.Add("Macedonia, FYRO" ,"MK" )
    $regionlist.Add("Malaysia" ,"MY" )
    $regionlist.Add("Malta" ,"MT" )
    $regionlist.Add("Mauritius" ,"MU" )
    $regionlist.Add("Mexico" ,"MX" )
    $regionlist.Add("Moldova" ,"MD" )
    $regionlist.Add("Monaco" ,"MC" )
    $regionlist.Add("Mongolia" ,"MN" )
    $regionlist.Add("Montenegro" ,"ME" )
    $regionlist.Add("Morocco" ,"MA" )
    $regionlist.Add("Namibia" ,"NA" )
    $regionlist.Add("Nepal" ,"NP" )
    $regionlist.Add("Netherlands" ,"NL" )
    $regionlist.Add("New Zealand" ,"NZ" )
    $regionlist.Add("Nicaragua" ,"NI" )
    $regionlist.Add("Nigeria" ,"NG" )
    $regionlist.Add("Norway" ,"NO" )
    $regionlist.Add("Oman" ,"OM" )
    $regionlist.Add("Pakistan" ,"PK" )
    $regionlist.Add("Palestinian Territory" ,"PS" )
    $regionlist.Add("Panama" ,"PA" )
    $regionlist.Add("Paraguay" ,"PY" )
    $regionlist.Add("Peru" ,"PE" )
    $regionlist.Add("Philippines" ,"PH" )
    $regionlist.Add("Poland" ,"PL" )
    $regionlist.Add("Portugal" ,"PT" )
    $regionlist.Add("Puerto Rico" ,"PR" )
    $regionlist.Add("Qatar" ,"QA" )
    $regionlist.Add("Romania" ,"RO" )
    $regionlist.Add("Russia" ,"RU" )
    $regionlist.Add("Rwanda" ,"RW" )
    $regionlist.Add("Saint Kitts and Nevis" ,"KN" )
    $regionlist.Add("Saudi Arabia" ,"SA" )
    $regionlist.Add("Senegal" ,"SN" )
    $regionlist.Add("Serbia" ,"RS" )
    $regionlist.Add("Singapore" ,"SG" )
    $regionlist.Add("Slovakia" ,"SK" )
    $regionlist.Add("Slovenia" ,"SI" )
    $regionlist.Add("South Africa" ,"ZA" )
    $regionlist.Add("Spain" ,"ES" )
    $regionlist.Add("Sri Lanka" ,"LK" )
    $regionlist.Add("Sweden" ,"SE" )
    $regionlist.Add("Switzerland" ,"CH" )
    $regionlist.Add("Taiwan" ,"TW" )
    $regionlist.Add("Tajikistan" ,"TJ" )
    $regionlist.Add("Tanzania" ,"TZ" )
    $regionlist.Add("Thailand" ,"TH" )
    $regionlist.Add("Trinidad and Tobago" ,"TT" )
    $regionlist.Add("Tunisia" ,"TN" )
    $regionlist.Add("Turkey" ,"TR" )
    $regionlist.Add("Turkmenistan" ,"TM" )
    $regionlist.Add("U.S. Virgin Islands" ,"VI" )
    $regionlist.Add("Uganda" ,"UG" )
    $regionlist.Add("Ukraine" ,"UA" )
    $regionlist.Add("United Arab Emirates" ,"AE" )
    $regionlist.Add("United Kingdom" ,"GB" )
    $regionlist.Add("United States" ,"US" )
    $regionlist.Add("Uruguay" ,"UY" )
    $regionlist.Add("Uzbekistan" ,"UZ" )
    $regionlist.Add("Venezuela" ,"VE" )
    $regionlist.Add("Vietnam" ,"VN" )
    $regionlist.Add("Yemen" ,"YE" )
    $regionlist.Add("Zambia" ,"ZM" )
    $regionlist.Add("Zimbabwe" ,"ZW" );
    $RegionIso=$regionlist.item($regioninfo)
    $DefaultCurrency=@("Afghanistan;USD" ,
"Albania;USD" ,
"Algeria;USD" ,
"Angola;USD" ,
"Argentina;ARS" ,
"Armenia;USD" ,
"Australia;AUD" ,
"Austria;EUR" ,
"Azerbaijan;USD" ,
"Bahamas;USD" ,
"Bahrain;USD" ,
"Bangladesh;USD" ,
"Barbados;USD" ,
"Belarus;USD" ,
"Belgium;EUR" ,
"Belize;USD" ,
"Bermuda;USD" ,
"Bolivia;USD" ,
"Bosnia and Herzegovina;USD" ,
"Botswana;USD" ,
"Brazil;BRL" ,
"Brazil;USD" ,
"Brunei Darussalam;USD" ,
"Bulgaria;EUR" ,
"Cameroon;USD" ,
"Canada;CAD" ,
"Cape Verde;USD" ,
"Cayman Islands;USD" ,
"Chile;USD" ,
"Colombia;USD" ,
"Congo;USD" ,
"Costa Rica;USD" ,
"C��te D'ivoire;USD" ,
"Croatia;EUR" ,
"Croatia;USD" ,
"Cura��ao;USD" ,
"Cyprus;EUR" ,
"Czech Republic;EUR" ,
"Denmark;DKK" ,
"Dominican Republic;USD" ,
"Ecuador;USD" ,
"Egypt;USD" ,
"El Salvador;USD" ,
"Estonia;EUR" ,
"Ethiopia;USD" ,
"Faroe Islands;EUR" ,
"Fiji;USD" ,
"Finland;EUR" ,
"France;EUR" ,
"Georgia;USD" ,
"Germany;EUR" ,
"Ghana;USD" ,
"Greece;EUR" ,
"Guatemala;USD" ,
"Honduras;USD" ,
"Hong Kong;HKD" ,
"Hong Kong SAR;USD" ,
"Hungary;EUR" ,
"Iceland;EUR" ,
"India;INR" ,
"India;USD" ,
"Indonesia;IDR" ,
"Iraq;USD" ,
"Ireland;EUR" ,
"Israel;USD" ,
"Italy;EUR" ,
"Jamaica;USD" ,
"Japan;JPY" ,
"Jordan;USD" ,
"Kazakhstan;USD" ,
"Kenya;USD" ,
"Korea;KRW" ,
"Kuwait;USD" ,
"Kyrgyzstan;USD" ,
"Latvia;EUR" ,
"Lebanon;USD" ,
"Libya;USD" ,
"Liechtenstein;CHF" ,
"Lithuania;EUR" ,
"Luxembourg;EUR" ,
"Macao;USD" ,
"Macedonia;USD" ,
"Malaysia;MYR" ,
"Malaysia;USD" ,
"Malta;EUR" ,
"Mauritius;USD" ,
"Mexico;MXN" ,
"Mexico;USD" ,
"Moldova;USD" ,
"Monaco;EUR" ,
"Mongolia;USD" ,
"Montenegro;USD" ,
"Morocco;USD" ,
"Namibia;USD" ,
"Nepal;USD" ,
"Netherlands;EUR" ,
"New Zealand;NZD" ,
"Nicaragua;USD" ,
"Nigeria;USD" ,
"Norway;NOK" ,
"Oman;USD" ,
"Pakistan;USD" ,
"Palestinian Territory, Occupied;USD" ,
"Panama;USD" ,
"Paraguay;USD" ,
"Peru;USD" ,
"Philippines;USD" ,
"Poland;EUR" ,
"Portugal;EUR" ,
"Puerto Rico;USD" ,
"Qatar;USD" ,
"Romania;EUR" ,
"Russia;RUB" ,
"Rwanda;USD" ,
"Saint Kitts and Nevis;USD" ,
"Saudi Arabia;SAR" ,
"Senegal;USD" ,
"Serbia;USD" ,
"Singapore;USD" ,
"Slovakia;EUR" ,
"Slovenia;EUR" ,
"South Africa;ZAR" ,
"Spain;EUR" ,
"Sri Lanka;USD" ,
"Sweden;SEK" ,
"Switzerland;CHF" ,
"Taiwan;TWD" ,
"Tajikistan;USD" ,
"Tanzania;USD" ,
"Thailand;USD" ,
"Trinidad and Tobago;USD" ,
"Tunisia;USD" ,
"Turkey;TRY" ,
"Turkmenistan;USD" ,
"UAE;USD" ,
"Uganda;USD" ,
"Ukraine;USD" ,
"United Kingdom;GBP" ,
"United States;USD" ,
"Uruguay;USD" ,
"Uzbekistan;USD" ,
"Venezuela;USD" ,
"Viet Nam;USD" ,
"Virgin Islands, US;USD" ,
"Yemen;USD" ,
"Zambia;USD" ,
"Zimbabwe;USD" )
IF(!($DefaultCurrency|where{$_ -match $RegionInfo -and $_ -match $Currency}))
{
    $Currency=@($DefaultCurrency|where{$_ -match $RegionInfo})[0].Split(';')[1]
}
IF([String]::IsNullOrEmpty($RegionIso)){ $RegionIso= 'US'}
IF([String]::IsNullOrEmpty($OfferDurableId)){ $OfferDurableId = 'MS-AZR-0003P' }Else
{
    $OfferDurableId=$OfferDurableId.Split(':')[0].trim()
}
    $CustomerID = Get-AutomationVariable -Name  "AzureUsage-OPSINSIGHTS_WS_ID"
    $SharedKey = Get-AutomationVariable -Name  "AzureUsage-OPSINSIGHTS_WS_KEY"
    $logname='AzureUsage'
[Collections.Arraylist]$InstanceResults = @()
    $colltime=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddThh:00:00.000Z" )
function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource)
{
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n" + $ContentLength + " `n" + $ContentType + " `n" + $XHeaders + " `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$EncodedHash
	return $authorization
}
Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType)
{
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
	    date = $rfc1123date
	    contentLength = $ContentLength
	    resource = $resource
	    sharedKey = $SharedKey
	    customerId = $CustomerId
	    contentType = $ContentType
	    fileName = $FileName
	    method = $method
	}
    $signature @params
    $uri = "https://" + $CustomerId + " .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
    $OMSheaders = @{
		"Authorization" = $signature;
		"Log-Type" = $LogType;
		" x-ms-date" = $rfc1123date;
		" time-generated-field" = $TimeStampField;
	}
    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
	return $response.StatusCode
    $log = $log + " $(get-date)   -  OMS Data Upload ststus code $($response.StatusCod) "
}
function Calculate-rate ($meter,[double]$quantity)
{
	$i=0
    $CalcCost=$CalcSaving=$CalcLowestCost=0
    $MeterArr=@()
    $MeterArr=[array]$meter.MeterRates.psobject.Properties
	If($MeterArr.Count -eq 1)
	{
    $CalcCost=[double]$MeterArr[0].Value*$quantity
	}
	Else
	{
		$i=0
    $remaining=$quantity
    $CalcCost=0
    $meter.MeterRates.psobject.Properties|Foreach-object{
			[long]$curname=$_.name
			[double]$curval=$_.value
			" $curname  $curval  -$i"
			IF ($i -gt 0 -and $quantity -gt 0 )
			{
				IF($quantity -le $curname )
				{
    $CalcCost = $CalcCost + $lastval*$quantity
					" cost =  $lastval * $quantity  =$CalcCost"
    $quantity=$quantity-$curname
				}
				Else
				{
    $CalcCost = $CalcCost + ($curname-$lastname)*$lastval
    $quantity=$quantity-$curname
					" cost =  ($curname - $lastname) * $lastval  , total cost: $CalcCost"
					"Reamining $quantity"
				}
			}
    $i++
    $lastname=$curname
    $lastval=$curval
		}
	}
    $CalcBillItem = New-Object -ErrorAction Stop PSObject -Property @{
		calcCost=[double]$CalcCost
	}
	Return $CalcBillItem
}
Function find-lowestcost ($meter)
{
    $FilteredMEters=$meters|where{$_.MeterCategory -eq $meter.MeterCategory -and $_.MeterName -eq $Meter.MeterName -and $_.MeterSubCategory -eq $meter.MeterSubCategory -and ![string]::IsNullOrEmpty($_.MeterREgion)}
    $SortedMEter=@()
	Foreach($BillRegion in $FilteredMEters)
	{
    $SortedMeter = $SortedMeter + new-object -ErrorAction Stop PSobject -Property @{
			MeterRegion=$BillRegion.MeterRegion
			Meterrates=$BillRegion.MeterRates.0
			Rates=$BillRegion.MeterRates
			MeterID=$BillRegion.MeterId
		}
	}
    $resultarr=@()
    $SortedMEter|where {$_.Meterrates -eq $($SortedMEter|Sort-Object -Property Meterrates |select -First 1).Meterrates}|?{
    $lowestregion = $lowestregion + " $($_.MEterregion),"
    $resultarr = $resultarr + New-Object -ErrorAction Stop PSObject -Property @{
			Lowcostregion=$_.MEterregion
			LowcostregionCost=[double]$_.MeterRates
			Meterid=$_.MeterId
		}
	}
	return $resultarr
}
    $ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
Write-Output  "Logging in to Azure..."
    $retry = 6
    $SyncOk = $false
do
{
	try
	{
		Add-AzureRMAccount -ServicePrincipal -Tenant $ArmConn.TenantID -ApplicationId $ArmConn.ApplicationID -CertificateThumbprint $ArmConn.CertificateThumbprint
    $SyncOk = $true
	}
	catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. Retry attempts left: $retry"
    $retry = $retry - 1
		Start-Sleep -s 60
	}
} while (-not $SyncOk -and $retry -ge 0)
"Selecting Azure subscription..."
    $SelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $ArmConn.SubscriptionId -TenantId $ArmConn.tenantid
    $subscriptionid=$ArmConn.SubscriptionId
"Azure rm profile path  $((get-module -Name AzureRM.Profile).path) "
    $path=(get-module -Name AzureRM.Profile).path
    $path=Split-Path $path
    $dlllist=Get-ChildItem -Path $path  -Filter Microsoft.IdentityModel.Clients.ActiveDirectory.dll  -Recurse
    $adal =  $dlllist[0].VersionInfo.FileName
try
{
	Add-type -Path $adal
	[reflection.assembly]::LoadWithPartialName( "Microsoft.IdentityModel.Clients.ActiveDirectory" )
}
catch
{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
	Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. "
}
    $certs= Get-ChildItem -Path Cert:\Currentuser\my -Recurse | Where{$_.Thumbprint -eq $ArmConn.CertificateThumbprint}
[System.Security.Cryptography.X509Certificates.X509Certificate2]$mycert=$certs[0]
    $CliCert=new-object -ErrorAction Stop  Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($ArmConn.ApplicationId,$mycert)
    $AuthContext = new-object -ErrorAction Stop Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($ArmConn.tenantid)" )
    $result = $AuthContext.AcquireToken(" https://management.core.windows.net/" ,$CliCert);
    $header = "Bearer " + $result.AccessToken;
    $headers = @{"Authorization" =$header;"Accept" =" application/json" }
    $body=$null
    $HTTPVerb="GET"
    $SubscriptionInfoUri = "https://management.azure.com/subscriptions/" +$subscriptionid+"?api-version=2016-02-01"
    $SubscriptionInfo = Invoke-RestMethod -Uri $SubscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($SubscriptionInfo)
{
	Write-Output   "Successfully connected to Azure ARM REST"
}
    $ScriptBlock = {
	Param ($hash,$meters,$metrics)
    $start=get-date -ErrorAction Stop
	function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource)
	{
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n" + $ContentLength + " `n" + $ContentType + " `n" + $XHeaders + " `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$EncodedHash
		return $authorization
	}
	Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType)
	{
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
		    Uri = $uri
		    customerId = $CustomerId
		    contentLength = $ContentLength
		    fileName = $FileName
		    Headers = $OMSheaders
		    contentType = $ContentType
		    rate = "($meter,[double]$quantity) {"
		    sharedKey = $SharedKey
		    resource = $resource ; 	$uri = "https://" + $CustomerId + " .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ; 	$OMSheaders = @{ "Authorization" = $signature; "Log-Type" = $LogType; " x-ms-date" = $rfc1123date; " time-generated-field" = $TimeStampField; } $response = Invoke-WebRequest
		    UseBasicParsing = "return $response.StatusCode $log = $log + " $(get-date)"
		    Body = $body
		    date = $rfc1123date
		    method = $method
		}
    $signature @params
		$i=0
    $CalcCost=$CalcSaving=$CalcLowestCost=0
    $MeterArr=@()
    $MeterArr=[array]$meter.MeterRates.psobject.Properties
		If($MeterArr.Count -eq 1)
		{
    $CalcCost=[double]$MeterArr[0].Value*$quantity
		}
		Else
		{
			$i=0
    $remaining=$quantity
    $CalcCost=0
    $meter.MeterRates.psobject.Properties|Foreach-object{
				[long]$curname=$_.name
				[double]$curval=$_.value
				" $curname  $curval  -$i"
				IF ($i -gt 0 -and $quantity -gt 0 )
				{
					IF($quantity -le $curname )
					{
    $CalcCost = $CalcCost + $lastval*$quantity
						" cost =  $lastval * $quantity  =$CalcCost"
    $quantity=$quantity-$curname
					}
					Else
					{
    $CalcCost = $CalcCost + ($curname-$lastname)*$lastval
    $quantity=$quantity-$curname
						" cost =  ($curname - $lastname) * $lastval  , total cost: $CalcCost"
						"Reamining $quantity"
					}
				}
    $i++
    $lastname=$curname
    $lastval=$curval
			}
		}
    $FilteredMEters=$meters|where{$_.MeterCategory -eq $meter.MeterCategory -and $_.MeterName -eq $Meter.MeterName -and $_.MeterSubCategory -eq $meter.MeterSubCategory -and ![string]::IsNullOrEmpty($_.MeterREgion)}
    $SortedMEter=@()
		Foreach($BillRegion in $FilteredMEters)
		{
    $SortedMeter = $SortedMeter + new-object -ErrorAction Stop PSobject -Property @{
				MeterRegion=$BillRegion.MeterRegion
				Meterrates=$BillRegion.MeterRates.0
				Rates=$BillRegion.MeterRates
			}
		}
    $SortedMEter|where {$_.Meterrates -eq $($SortedMEter|Sort-Object -Property Meterrates |select -First 1).Meterrates}|?{$lowestregion = $lowestregion + " $($_.MEterregion)," }
		If ($lowestregion -match $meter.MeterRegion)
		{
    $CalcLowestCost=$CalcCost
    $CalcSaving=0
		}
		Else
		{
    $CalcLowestCost=0
    $LowestRate=($SortedMEter|Sort-Object -Property Meterrates |select -First 1).Rates
    $MeterArr=[array]$LowestRate.psobject.Properties
			If($MeterArr.Count -eq 1)
			{
    $CalcLowestCost=[double]$MeterArr[0].Value*$quantity
			}
			Else
			{
				$i=0
    $remaining=$quantity
    $CalcLowestCost=0
    $LowestRate.psobject.Properties|Foreach-object{
					[long]$curname=$_.name
					[double]$curval=$_.value
					" $curname  $curval  -$i"
					IF ($i -gt 0 -and $quantity -gt 0 )
					{
						IF($quantity -le $curname )
						{
    $CalcLowestCost = $CalcLowestCost + $lastval*$quantity
							" cost =  $lastval * $quantity  =$CalcLowestCost"
    $quantity=$quantity-$curname
						}
						Else
						{
    $CalcLowestCost = $CalcLowestCost + ($curname-$lastname)*$lastval
    $quantity=$quantity-$curname
							" cost =  ($curname - $lastname) * $lastval  , total cost: $CalcLowestCost"
							"Remaining $quantity"
						}
					}
    $i++
    $lastname=$curname
    $lastval=$curval
				}
			}
    $CalcSaving=$CalcCost-$CalcLowestCost
		}
    $CalcBillItem = New-Object -ErrorAction Stop PSObject -Property @{
			calcCost=[double]$CalcCost
		}
		Return $CalcBillItem
	}
	Function find-lowestcost ($meter)
	{
    $FilteredMEters=$meters|where{$_.MeterCategory -eq $meter.MeterCategory -and $_.MeterName -eq $Meter.MeterName -and $_.MeterSubCategory -eq $meter.MeterSubCategory -and ![string]::IsNullOrEmpty($_.MeterREgion)}
    $SortedMEter=@()
		Foreach($BillRegion in $FilteredMEters)
		{
    $SortedMeter = $SortedMeter + new-object -ErrorAction Stop PSobject -Property @{
				MeterRegion=$BillRegion.MeterRegion
				Meterrates=$BillRegion.MeterRates.0
				Rates=$BillRegion.MeterRates
				MeterID=$BillRegion.MeterId
			}
		}
    $resultarr=@()
    $SortedMEter|where {$_.Meterrates -eq $($SortedMEter|Sort-Object -Property Meterrates |select -First 1).Meterrates}|?{
    $lowestregion = $lowestregion + " $($_.MEterregion),"
    $resultarr = $resultarr + New-Object -ErrorAction Stop PSObject -Property @{
				Lowcostregion=$_.MEterregion
				LowcostregionCost=[double]$_.MeterRates
				Meterid=$_.MeterId
			}
		}
		return $resultarr
	}
    $SubscriptionInfo=$hash.subscriptionInfo
    $ArmConn=$hash.ArmConn
    $headers=$hash.headers
    $Timestampfield = $hash.Timestampfield
    $ApiVersion = $hash.ApiVersion
    $Currency=$hash.Currency
    $Locale=$hash.Locale
    $RegionInfo=$hash.RegionInfo
    $OfferDurableId=$hash.OfferDurableId
    $SyncInterval=$Hash.syncInterval
    $allrg=$hash.allrg
    $resmap=$hash.resmap
    $CustomerID =$hash.customerID
    $SharedKey = $hash.sharedKey
    $logname=$hash.Logname
    $colbilldata=@()
    $ColTaggedbilldata=@()
    $ratescache=@{}
    $count=1
    $metrics|Foreach{
    $metricitem=$null
    $metricitem=$_
    $obj=$resid=$location=$resource=$null
		IF($metricitem.instanceData)
		{
    $insdata=$cu=$null
    $insdata=(convertfrom-json $metricitem.instanceData).'Microsoft.Resources'
    $resid=$insdata.resourceUri
    $rg=$allrg|where {$_.Name -eq $resid.Split('/')[4]}
    $tag=$null
    $tags=$null
    $tags=@{}
    $restag=$null
    $restag=(convertfrom-json $metricitem.instanceData).'Microsoft.Resources'.tags
			If ($restag)
			{
    $restag.PSObject.Properties | foreach-object {
    $tags.add($_.Name,$_.value)
				}
			}
    $UsageType=$insdata.additionalInfo.UsageType
    $Meter=($meters|where {$_.meterid -eq $metricitem.meterId})
    $price=Calculate-rate -meter $meter -quantity $metricitem.quantity
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
				Timestamp = $metricitem.usageStartTime
				Collectiontime=$colltime
				meterCategory= $Meter.meterCategory
				meterSubCategory= $Meter.meterSubCategory
				meterName= $Meter.meterName
				unit=$metricitem.unit
				quantity=$metricitem.quantity
				Location=$insdata.location
				ResourceGroup=$insdata.resourceUri.Split('/')[4]
				Cost=$price.calcCost
				SubscriptionId = $ArmConn.SubscriptionID;
				AzureSubscription = $SubscriptionInfo.displayname;
				usageEndTime=$metricitem.usageEndTime
				UsageType=$insdata.additionalInfo.UsageType
				Resource=$insdata.resourceUri.Split('/')[$insdata.resourceUri.Split('/').count-1]
				Aggregation=$SyncInterval
				CostTag='Overall'
				OfferDurableId=$OfferDurableId
				Currency=$Currency
				Locale=$Locale
				RegionInfo=$RegionInfo
			}
    $colbilldata = $colbilldata + $cu
			IF($propagatetags -eq $true -and ![string]::IsNullOrEmpty($rg.tags) )
			{
    $rg.tags.PSObject.Properties | foreach-object {
    $tags.add($_.Name,$_.value)
				}
			}
			If($tags)
			{
				foreach ($tag in $tags.Keys)
				{
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
						Timestamp = $metricitem.usageStartTime
						Collectiontime=$colltime
						meterCategory= $meter.meterCategory
						meterSubCategory= $meter.meterSubCategory
						meterName= $meter.meterName
						unit=$metricitem.unit
						quantity=$metricitem.quantity
						Location=$insdata.location
						ResourceGroup=$insdata.resourceUri.Split('/')[4]
						TaggedCost=$price.calcCost
						SubscriptionId = $ArmConn.SubscriptionID;
						AzureSubscription = $SubscriptionInfo.displayname;
						usageEndTime=$metricitem.usageEndTime
						UsageType=$insdata.additionalInfo.UsageType
						Resource=$insdata.resourceUri.Split('/')[$insdata.resourceUri.Split('/').count-1]
						Aggregation=$SyncInterval
						Tag=" $tag : $($tags.item($tag))"
						OfferDurableId=$OfferDurableId
						Currency=$Currency
						Locale=$Locale
						RegionInfo=$RegionInfo
					}
    $cu|add-member -MemberType NoteProperty -Name $tag  -Value $tags.item($tag) -ea 0
    $ColTaggedbilldata = $ColTaggedbilldata + $cu
				}
			}
		}
		Else{
    $obj=$resid=$MeteredRegion=$MeteredService=$project=$cu1=$null
    $MeteredRegion=$metricitem.infoFields.meteredRegion
    $MeteredServiceType=$metricitem.infoFields.meteredServiceType
    $rgcls=$null
    $rg=$null
			IF ($metricitem.infoFields.meteredservice -eq 'Compute')
			{
    $rgcls=$metricitem.infoFields.project.Split('(')[0]
    $rg=$allrg|where {$_.Name -eq $rgcls}
			}Else
			{
    $rgcls=($resmap|where{$_.Resource -eq " $($metricitem.infoFields.project)" }).Resourcegroup
    $rg=$allrg|where {$_.Name -eq $rgcls}
			}
    $project=$metricitem.infoFields.project
    $price=$null
    $Meter=($meters|where {$_.meterid -eq $metricitem.meterId})
    $price=Calculate-rate -meter $meter -quantity $metricitem.quantity
    $cu1 = New-Object -ErrorAction Stop PSObject -Property @{
				Timestamp = $metricitem.usageStartTime
				Collectiontime=$colltime
				meterCategory= $meter.meterCategory
				meterSubCategory= $meter.meterSubCategory
				meterName= $meter.meterName
				unit=$metricitem.unit
				quantity=$metricitem.quantity
				Location=$metricitem.infoFields.meteredRegion
				ResourceGroup=$Rgcls
				Cost=$price.calcCost
				SubscriptionId = $ArmConn.SubscriptionID;
				AzureSubscription = $SubscriptionInfo.displayname;
				usageEndTime=$metricitem.usageEndTime
				Resource= $metricitem.infoFields.project
				Aggregation=$SyncInterval
				CostTag="Overall"
				OfferDurableId=$OfferDurableId
				Currency=$Currency
				Locale=$Locale
				RegionInfo=$RegionInfo
			}
    $colbilldata = $colbilldata + $cu1
			IF($propagatetags -eq $true -and ![string]::IsNullOrEmpty($rg.Tags) )
			{
				" tags $($rg.Tags) added to classic res"
    $rg.tags.PSObject.Properties | foreach-object {
    $tags.add($_.Name,$_.value)
				}
				foreach ($tag in $tags.Keys)
				{
    $cu1=$null
    $cu1 = New-Object -ErrorAction Stop PSObject -Property @{
						Timestamp = $metricitem.usageStartTime
						Collectiontime=$colltime
						meterCategory= $meter.meterCategory
						meterSubCategory= $meter.meterSubCategory
						meterName= $meter.meterName
						unit=$metricitem.unit
						quantity=$metricitem.quantity
						Location=$metricitem.infoFields.meteredRegion
						ResourceGroup=$Rgcls
						TaggedCost=$price.calcCost
						SubscriptionId = $ArmConn.SubscriptionID;
						AzureSubscription = $SubscriptionInfo.displayname;
						usageEndTime=$metricitem.usageEndTime
						Resource= $metricitem.infoFields.project
						Aggregation=$SyncInterval
						Tag=" $tag : $($tags.item($tag))"
						OfferDurableId=$OfferDurableId
						Currency=$Currency
						Locale=$Locale
						RegionInfo=$RegionInfo
					}
    $cu1|add-member -MemberType NoteProperty -Name $tag  -Value $tags.item($tag) -ea 0
    $ColTaggedbilldata = $ColTaggedbilldata + $cu1
				}
			}
		}
    $count++
	}
    $jsoncolbill = ConvertTo-Json -InputObject $colbilldata
	If($jsoncolbill){$postres=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoncolbill)) -logType $logname}
	If ($postres -ge 200 -and $postres -lt 300)
	{
	}
	Else
	{
		Write-Warning "Failed to upload  $($colbilldata.count)  metrics to OMS"
	}
	IF($ColTaggedbilldata)
	{
    $jsoncolbill = ConvertTo-Json -InputObject $ColTaggedbilldata
		If($jsoncolbill){$postres=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoncolbill)) -logType $logname}
		If ($postres -ge 200 -and $postres -lt 300)
		{
		}
		Else
		{
			Write-Warning "Failed to upload  $($ColTaggedbilldata.count) tagged usage metrics to OMS"
		}
	}
    $end=get-date -ErrorAction Stop
    $timetaken = ($end-$start).Totalseconds
	Write-Output " $timetaken   seconds ..." -Verbose
}
Write-Output "Getting all available rates... "
    $uri= "https://management.azure.com/subscriptions/{5}/providers/Microsoft.Commerce/RateCard?api-version={0}&`$filter=OfferDurableId eq '{1}' and Currency eq '{2}' and Locale eq '{3}' and RegionInfo eq '{4}'" -f $ApiVersion, $OfferDurableId, $Currency, $Locale, $RegionIso, $SubscriptionId
    $resp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing -Timeout 180
    $res=ConvertFrom-Json -InputObject $resp.Content
    $Meters=$res.meters
If([string]::IsNullOrEmpty($Meters))
{
	Write-warning "Rates are not available ,  runbook will try again after 15 minutes"
    $RescheduleRB=$true
	exit
}
    $Uri=" https://management.azure.com/subscriptions/$subscriptionid/resourcegroups?api-version=2016-09-01"
    $resp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing -TimeoutSec 180
    $res=@()
    $content=ConvertFrom-Json -InputObject $resp.Content
    $res = $res + $content
IF(![string]::IsNullOrEmpty($res.nextLink))
{
	do
	{
    $uri2=$content.nextLink
    $content=$null
    $resultarm = Invoke-WebRequest -Method $HTTPVerb -Uri $uri2 -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $res = $res + $content
    $uri2=$null
	}While (![string]::IsNullOrEmpty($content.nextLink))
}
    $AllRg=$res.value
    $Uriresources=" https://management.azure.com/subscriptions/$subscriptionid/resources?api-version=2016-09-01"
    $respresources=Invoke-WebRequest -Uri $uriresources -Method GET  -Headers $headers -UseBasicParsing -TimeoutSec 180
    $resresources=@()
    $resresources = $resresources + ConvertFrom-Json -InputObject $respresources.Content
IF(![string]::IsNullOrEmpty($resresources.nextLink))
{
	do
	{
    $uri2=$resresources.nextLink
    $content=$null
    $resultarm = Invoke-WebRequest -Method $HTTPVerb -Uri $uri2 -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $resresources = $resresources + $content
    $uri2=$null
	}While (![string]::IsNullOrEmpty($content.nextLink))
}
write-output " $($resresources.value.count) resources found"
    $resmap=@()
foreach($azres in $resresources.value)
{
    $resgrp=$null
    $resgrp=$azres.id.split('/')[4]
    $resmap = $resmap + New-Object -ErrorAction Stop PSObject -Property @{
		Resource=$azres.name
		REsourceGroup=$resgrp
		Type=$azres.type
	}
}
IF($SyncInterval -eq 'Hourly')
{
    $end=(get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy-MM-dd'T'HH:00:00" )
    $start=(get-date).AddHours(-2).ToUniversalTime().ToString(" yyyy-MM-dd'T'HH:00:00" )
    $Uri=" https://management.azure.com/subscriptions/$subscriptionid/providers/Microsoft.Commerce/UsageAggregates?api-version=2015-06-01-preview&reportedStartTime=$start&reportedEndTime=$end&aggregationGranularity=$SyncInterval&showDetails=true"
}
Else
{
    $end=(get-date).ToUniversalTime().ToString(" yyyy-MM-dd'T'00:00:00" )
    $start=(get-date).Adddays(-1).ToUniversalTime().ToString(" yyyy-MM-dd'T'00:00:00" )
    $Uri=" https://management.azure.com/subscriptions/$subscriptionid/providers/Microsoft.Commerce/UsageAggregates?api-version=2015-06-01-preview&reportedStartTime=$start&reportedEndTime=$end&aggregationGranularity=$SyncInterval&showDetails=true"
}
Write-Output "Fetching Usage data for  $start (UTC) and $end (UTC) , Currency :$Currency Locate : $Locale ,Region: $RegionIso , Azure Subs Type : $OfferDurableId "
    $resp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing  -TimeoutSec 180
    $res=@()
    $content=ConvertFrom-Json -InputObject $resp.Content
    $res = $res + $content
IF(![string]::IsNullOrEmpty($res.nextLink))
{
	do
	{
    $uri2=$content.nextLink
    $content=$null
    $resultarm = Invoke-WebRequest -Method $HTTPVerb -Uri $uri2 -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $res = $res + $content
    $uri2=$null
	}While (![string]::IsNullOrEmpty($content.nextLink))
}
    $metrics=$res.value.Properties
    $metrics=$metrics|Sort-Object -Property metercategory -Descending
Write-output " $($metrics.count) usage metrics  found ";
    $spltlist=@()
If($metrics.count -gt 200)
{
    $SplitSize=200
    $spltlist = $spltlist + for ($Index = 0; $Index -lt  $metrics.Count; $Index = $Index + $SplitSize)
	{
		,($metrics[$index..($index+$SplitSize-1)])
	}
}Elseif($metrics.count -gt 100)
{
    $SplitSize=100
    $spltlist = $spltlist + for ($Index = 0; $Index -lt  $metrics.Count; $Index = $Index + $SplitSize)
	{
		,($metrics[$index..($index+$SplitSize-1)])
	}
}Else{
    $spltlist = $spltlist + ,($metrics)
}
    $hash = [hashtable]::New(@{})
    $hash['Host']=$host
    $hash['subscriptionInfo']=$SubscriptionInfo
    $hash['ArmConn']=$ArmConn
    $hash['headers']=$headers
    $hash['Timestampfield']=$Timestampfield
    $hash['ApiVersion'] =$ApiVersion
    $hash['Currency']=$Currency
    $hash['Locale']=$Locale
    $hash['RegionInfo']=$RegionInfo
    $hash['OfferDurableId']=$OfferDurableId
    $hash['allrg']=$allrg
    $hash['resmap']=$resmap
    $hash['customerID'] =$CustomerID
    $hash['syncInterval']=$SyncInterval
    $hash['sharedKey']=$SharedKey
    $hash['Logname']=$logname
    $Throttle = 6
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
    $Jobs = @()
write-output " $($metrics.count) objects will be processed "
$i=1
    $spltlist|foreach{
    $splitmetrics=$null
    $splitmetrics=$_
    $Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($hash).AddArgument($meters).AddArgument($splitmetrics)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
		RunNum = $_
		Pipe = $Job
		Result = $Job.BeginInvoke()
	}
	write-output  " $(get-date)  , started Runsapce $i "
    $i++
}
Write-Output "Waiting.."
Do {
	Start-Sleep -Seconds 60
} While ( $Jobs.Result.IsCompleted -contains $false)
Write-Output "All jobs completed!" ;
    $Results = @()
ForEach ($Job in $Jobs)
{
    $Results = $Results + $Job.Pipe.EndInvoke($Job.Result)
	if($jobs[0].Pipe.HadErrors)
	{
		write-warning " $($jobs.Pipe.Streams.Error.exception)"
	}
}
    $jobs|foreach{$_.Pipe.Dispose()}
    $runspacepool.Close()
[gc]::Collect()



