#Requires -Version 7.0
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    New Azstorageaccount

.DESCRIPTION
    New Azstorageaccount operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
    -Kind
Specifies the kind of Storage account that this cmdlet creates. The acceptable values for this parameter are:
    Storage. General purpose Storage account that supports storage of Blobs, Tables, Queues, Files and Disks.
    StorageV2. General Purpose Version 2 (GPv2) Storage account that supports Blobs, Tables, Queues, Files, and Disks, with  features like data tiering.
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
    General notes
    New-AzStorageAccount -ErrorAction Stop : FGC_Prod_FileStrage_SA1 is not a valid storage account name. Storage account name must be between 3 and 24 characters in
length and use numbers and lower-case letters only.
Parameter name: Name
At C:\Users\Abdullah.Ollivierre\AzureRepos2\Azure\Storage\Storage Accounts\2-New-AzStorageAccount.ps1:64 char:1
+ New-AzStorageAccount -ErrorAction Stop @newAzStorageAccountSplat
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [New-AzStorageAccount], ArgumentException
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.Management.Storage.NewAzureStorageAccountCommand
$ResourceGroupName = "FGC_Prod_FileStorage_RG"
$StorageAccountName = 'fgcprodfilestoragesa1'
$LocationName = 'CanadaCentral'
$CustomerName = 'FGCHealth'
$SkuName = 'Standard_LRS'
$Kind = "Storagev2"
$AccessTier = "Hot"
$MinimumTlsVersion = 'TLS1_0'

$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Createdby"         = 'Abdullah Ollivierre'
    "CustomerName"      = " $CustomerName"
    "DateTimeCreated"   = " $datetime"
    "Environment"       = 'Production'
    "Application"       = 'Storage Account'
    "Purpose"           = 'EDW Prod'
    "Location"          = " $LocationName"
    "Approved By"       = "Hamza Musaphir"
    "Approved On"       = "Friday Dec 11 2020"
    "Ticket ID"         = " 1515933"
    "CSP"               = "Canada Computing Inc."
    "Subscription Name" = "Microsoft Azure - FGC Production"
    "Subscription ID"   = " 3532a85c-c00a-4465-9b09-388248166360"
    "Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"
    "AccessTier"        = $AccessTier
    "Kind"              = $Kind
    "SkuName"           = $SkuName
    "MinimumVersion"    = $MinimumTlsVersion
    "Storage Services"  = "General Purpose Version 2 (GPv2) Storage account that supports Blobs, Tables, Queues, Files, and Disks, with  features like data tiering."
}

$newAzStorageAccountSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name              = $StorageAccountName
    Location          = $LocationName
    SkuName           = $SkuName
    Kind              = $Kind
    AccessTier        = $AccessTier
    MinimumTlsVersion = $MinimumTlsVersion
    Tag               = $Tags
}
New-AzStorageAccount -ErrorAction Stop @newAzStorageAccountSplat

