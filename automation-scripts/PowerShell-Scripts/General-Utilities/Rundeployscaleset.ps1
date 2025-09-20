<#
.SYNOPSIS
    Rundeployscaleset

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$args=@{
    'scalesetDNSPrefix'='s'+[System.Guid]::NewGuid().toString();
    'newStorageAccountName'=[System.Guid]::NewGuid().toString().Replace('-','').Substring(1,24);
    'resourceGroupName'='ssrg1';
    'location'='northeurope';
    'scaleSetName'='windowscustom';
    'scaleSetVMSize'='Standard_DS1';
    'newStorageAccountType'='Premium_LRS';
}
.\deployscaleset.ps1 @args\n