<#
.SYNOPSIS
    We Enhanced 2 New Azstorageaccount

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


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)

    -Kind

Specifies the kind of Storage account that this cmdlet creates. The acceptable values for this parameter are:

    Storage. General purpose Storage account that supports storage of Blobs, Tables, Queues, Files and Disks.
    StorageV2. General Purpose Version 2 (GPv2) Storage account that supports Blobs, Tables, Queues, Files, and Disks, with advanced features like data tiering.
    BlobStorage. Blob Storage account which supports storage of Blobs only.
    BlockBlobStorage. Block Blob Storage account which supports storage of Block Blobs only.
    FileStorage. File Storage account which supports storage of Files only. The default value is StorageV2.



    -MinimumTlsVersion

The minimum TLS version to be permitted on requests to storage. The default interpretation is TLS 1.0 for this property.




-SkuName

Specifies the SKU name of the Storage account that this cmdlet creates. The acceptable values for this parameter are:

    Standard_LRS. Locally-redundant storage.
    Standard_ZRS. Zone-redundant storage.
    Standard_GRS. Geo-redundant storage.
    Standard_RAGRS. Read access geo-redundant storage.
    Premium_LRS. Premium locally-redundant storage.
    Premium_ZRS. Premium zone-redundant storage.
    Standard_GZRS - Geo-redundant zone-redundant storage.
    Standard_RAGZRS - Read access geo-redundant zone-redundant storage.


.OUTPUTS
    Output (if any)
.NOTES
    General notes

    New-AzStorageAccount : FGC_Prod_FileStrage_SA1 is not a valid storage account name. Storage account name must be between 3 and 24 characters in   
length and use numbers and lower-case letters only.
Parameter name: Name
At C:\Users\Abdullah.Ollivierre\AzureRepos2\Azure\Storage\Storage Accounts\2-New-AzStorageAccount.ps1:64 char:1
+ New-AzStorageAccount @newAzStorageAccountSplat
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [New-AzStorageAccount], ArgumentException
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.Management.Storage.NewAzureStorageAccountCommand


$WEResourceGroupName = " FGC_Prod_FileStorage_RG"
$WEStorageAccountName = 'fgcprodfilestoragesa1'

$WELocationName = 'CanadaCentral'
$WECustomerName = 'FGCHealth'


$WESkuName = 'Standard_LRS'
$WEKind = " Storagev2" 
$WEAccessTier = " Hot"
$WEMinimumTlsVersion = 'TLS1_0'

$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss")
[hashtable]$WETags = @{

    " Createdby"         = 'Abdullah Ollivierre'
    " CustomerName"      = " $WECustomerName"
    " DateTimeCreated"   = " $datetime"
    " Environment"       = 'Production'
    " Application"       = 'Storage Account'  
    " Purpose"           = 'EDW Prod'
    " Location"          = " $WELocationName"
    " Approved By"       = " Hamza Musaphir"
    " Approved On"       = " Friday Dec 11 2020"
    " Ticket ID"         = " 1515933"
    " CSP"               = " Canada Computing Inc."
    " Subscription Name" = " Microsoft Azure - FGC Production"
    " Subscription ID"   = " 3532a85c-c00a-4465-9b09-388248166360"
    " Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"
    " AccessTier"        = $WEAccessTier
    " Kind"              = $WEKind
    " SkuName"           = $WESkuName
    " MinimumVersion"    = $WEMinimumTlsVersion
    " Storage Services"  = " General Purpose Version 2 (GPv2) Storage account that supports Blobs, Tables, Queues, Files, and Disks, with advanced features like data tiering."

}
; 
$newAzStorageAccountSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Name              = $WEStorageAccountName
    Location          = $WELocationName
    SkuName           = $WESkuName
    Kind              = $WEKind
    AccessTier        = $WEAccessTier
    MinimumTlsVersion = $WEMinimumTlsVersion
    Tag               = $WETags
}

New-AzStorageAccount @newAzStorageAccountSplat


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================