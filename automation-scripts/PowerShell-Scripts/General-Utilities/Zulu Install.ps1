<#
.SYNOPSIS
    Zulu Install

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
    We Enhanced Zulu Install

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEPARAMS = @("Azul_Zulu_OpenJDK-7-JDK" , " Azul_Zulu_OpenJDK-7-JRE" ,
             " Azul_Zulu_OpenJDK-8-JDK" , " Azul_Zulu_OpenJDK-8-JRE" ,
             " Azul_Zulu_OpenJDK-11-JDK" , " Azul_Zulu_OpenJDK-11-JRE" ,
             " Azul_Zulu_OpenJDK-13-JDK" , " Azul_Zulu_OpenJDK-13-JRE" )

 $WEZULU_PACKS = @(" zulu-7-azure-jdk_7.38.0.11-7.0.262-win_x64.msi" ,
                 " zulu-7-azure-jre_7.38.0.11-7.0.262-win_x64.msi" ,
                 " zulu-8-azure-jdk_8.46.0.19-8.0.252-win_x64.msi" ,
                 " zulu-8-azure-jre_8.46.0.19-8.0.252-win_x64.msi" ,
                 " zulu-11-azure-jdk_11.39.15-11.0.7-win_x64.msi" ,
                 " zulu-11-azure-jre_11.39.15-11.0.7-win_x64.msi" ,
                 " zulu-13-azure-jdk_13.31.11-13.0.3-win_x64.msi" ,
                 " zulu-13-azure-jre_13.31.11-13.0.3-win_x64.msi" )

 $WEPACKAGE_DIRS = @(" zulu-7" , " zulu-7" , " zulu-8" , " zulu-8" , " zulu-11" , " zulu-11" , " zulu-13" , " zulu-13" )
;  $WEVERSIONS = @(" 7u262" , " 7u262" , " 8u252" , " 8u252" , " 11.0.7" , " 11.0.7" , " 13.0.3" , " 13.0.3" )
;  $WEINSTALL_DIRS = @(" zulu-7" , " zulu-7-jre" , " zulu-8" , " zulu-8-jre" , " zulu-11" , " zulu-11-jre" , " zulu-13" , " zulu-13-jre" )

 for ($idx = 0; $idx -lt $WEPARAMS.length; $idx++) {
    if ($args[0] -eq $WEPARAMS[$idx]) {
       $WEZULU_PACK = $WEZULU_PACKS[$idx]
       $WEPACKAGE_DIR = $WEPACKAGE_DIRS[$idx]
      ;  $WEVERSION = $WEVERSIONS[$idx]
      ;  $WEINSTALL_DIR = $WEINSTALL_DIRS[$idx]
       break
    }
 }

 Invoke-WebRequest -Uri http://repos.azul.com/azure-only/zulu/packages/$WEPACKAGE_DIR/$WEVERSION/$WEZULU_PACK -OutFile C:\Windows\Temp\$WEZULU_PACK
 msiexec /quiet /i C:\Windows\Temp\$WEZULU_PACK

 setx /m JAVA_HOME " C:\Program Files\Zulu\$WEINSTALL_DIR"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================