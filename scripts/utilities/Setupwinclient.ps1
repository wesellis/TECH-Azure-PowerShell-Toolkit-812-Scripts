#Requires -Version 7.0

<#`n.SYNOPSIS
    Setupwinclient

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
mkdir c:\temp -Force
Get-Date -ErrorAction Stop > c:\temp\hello.txt
REG add "HKLM\SOFTWARE\Policies\Microsoft\System\DNSClient" /v "PrimaryDnsSuffix" /t REG_SZ /d $args[0] /f           # for now
REG add "HKLM\SOFTWARE\Policies\Microsoft\System\DNSClient" /v "NV PrimaryDnsSuffix" /t REG_SZ /d $args[0] /f        # for next reboot
REG add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v RegisterReverseLookup       /t REG_DWORD /d 1        /f
REG add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v RegistrationEnabled         /t REG_DWORD /d 1        /f
REG add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v RegisterAdapterName         /t REG_DWORD /d 1        /f
REG add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v UpdateSecurityLevel         /t REG_DWORD /d 16       /f
REG add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v AdapterDomainName           /t REG_SZ    /d $args[0] /f
shutdown /r /t 120
