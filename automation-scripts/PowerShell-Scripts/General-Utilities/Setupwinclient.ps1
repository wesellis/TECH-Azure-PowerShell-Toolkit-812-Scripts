<#
.SYNOPSIS
    Setupwinclient

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
    We Enhanced Setupwinclient

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


mkdir c:\temp -Force
Get-Date -ErrorAction Stop > c:\temp\hello.txt


REG add "HKLM\SOFTWARE\Policies\Microsoft\System\DNSClient" /v " PrimaryDnsSuffix" /t REG_SZ /d $args[0] /f           # for now
REG add " HKLM\SOFTWARE\Policies\Microsoft\System\DNSClient" /v " NV PrimaryDnsSuffix" /t REG_SZ /d $args[0] /f        # for next reboot



REG add " HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v RegisterReverseLookup       /t REG_DWORD /d 1        /f
REG add " HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v RegistrationEnabled         /t REG_DWORD /d 1        /f
REG add " HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v RegisterAdapterName         /t REG_DWORD /d 1        /f
REG add " HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v UpdateSecurityLevel         /t REG_DWORD /d 16       /f
REG add " HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v AdapterDomainName           /t REG_SZ    /d $args[0] /f



shutdown /r /t 120



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================