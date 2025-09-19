#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    2 Get Azvmsize

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
    We Enhanced 2 Get Azvmsize

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop" ; 
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
.OUTPUTS
    Output (if any)

    Name                   NumberOfCores MemoryInMB MaxDataDiskCount OSDiskSizeInMB ResourceDiskSizeInMB
----                   ------------- ---------- ---------------- -------------- --------------------
Standard_B1ls                      1        512                2        1047552                 4096
Standard_B1ms                      1       2048                2        1047552                 4096
Standard_B1s                       1       1024                2        1047552                 4096
Standard_B2ms                      2       8192                4        1047552                16384
Standard_B2s                       2       4096                4        1047552                 8192
Standard_B4ms                      4      16384                8        1047552                32768
Standard_B8ms                      8      32768               16        1047552                65536
Standard_B12ms                    12      49152               16        1047552                98304
Standard_B16ms                    16      65536               32        1047552               131072
Standard_B20ms                    20      81920               32        1047552               163840
Standard_D1_v2                     1       3584                4        1047552                51200
Standard_D2_v2                     2       7168                8        1047552               102400
Standard_D3_v2                     4      14336               16        1047552               204800
Standard_D4_v2                     8      28672               32        1047552               409600
Standard_D5_v2                    16      57344               64        1047552               819200
Standard_D11_v2                    2      14336                8        1047552               102400
Standard_D12_v2                    4      28672               16        1047552               204800
Standard_D13_v2                    8      57344               32        1047552               409600
Standard_D14_v2                   16     114688               64        1047552               819200
Standard_D15_v2                   20     143360               64        1047552              1024000
Standard_D2_v2_Promo               2       7168                8        1047552               102400
Standard_D3_v2_Promo               4      14336               16        1047552               204800
Standard_D4_v2_Promo               8      28672               32        1047552               409600
Standard_D5_v2_Promo              16      57344               64        1047552               819200
Standard_D11_v2_Promo              2      14336                8        1047552               102400
Standard_D12_v2_Promo              4      28672               16        1047552               204800
Standard_D13_v2_Promo              8      57344               32        1047552               409600
Standard_D14_v2_Promo             16     114688               64        1047552               819200
Standard_F1                        1       2048                4        1047552                16384
Standard_F2                        2       4096                8        1047552                32768
Standard_F4                        4       8192               16        1047552                65536
Standard_F8                        8      16384               32        1047552               131072
Standard_F16                      16      32768               64        1047552               262144
Standard_DS1_v2                    1       3584                4        1047552                 7168
Standard_DS2_v2                    2       7168                8        1047552                14336
Standard_DS3_v2                    4      14336               16        1047552                28672
Standard_DS4_v2                    8      28672               32        1047552                57344
Standard_DS5_v2                   16      57344               64        1047552               114688
Standard_DS11-1_v2                 2      14336                8        1047552                28672
Standard_DS11_v2                   2      14336                8        1047552                28672
Standard_DS12-1_v2                 4      28672               16        1047552                57344
Standard_DS12-2_v2                 4      28672               16        1047552                57344
Standard_DS12_v2                   4      28672               16        1047552                57344
Standard_DS13-2_v2                 8      57344               32        1047552               114688
Standard_DS13-4_v2                 8      57344               32        1047552               114688
Standard_DS13_v2                   8      57344               32        1047552               114688
Standard_DS14-4_v2                16     114688               64        1047552               229376
Standard_DS14-8_v2                16     114688               64        1047552               229376
Standard_DS14_v2                  16     114688               64        1047552               229376
Standard_DS15_v2                  20     143360               64        1047552               286720
Standard_DS2_v2_Promo              2       7168                8        1047552                14336
Standard_DS3_v2_Promo              4      14336               16        1047552                28672
Standard_DS4_v2_Promo              8      28672               32        1047552                57344
Standard_DS5_v2_Promo             16      57344               64        1047552               114688
Standard_DS11_v2_Promo             2      14336                8        1047552                28672
Standard_DS12_v2_Promo             4      28672               16        1047552                57344
Standard_DS13_v2_Promo             8      57344               32        1047552               114688
Standard_DS14_v2_Promo            16     114688               64        1047552               229376
Standard_F1s                       1       2048                4        1047552                 4096
Standard_F2s                       2       4096                8        1047552                 8192
Standard_F4s                       4       8192               16        1047552                16384
Standard_F8s                       8      16384               32        1047552                32768
Standard_F16s                     16      32768               64        1047552                65536
Standard_A1_v2                     1       2048                2        1047552                10240
Standard_A2m_v2                    2      16384                4        1047552                20480
Standard_A2_v2                     2       4096                4        1047552                20480
Standard_A4m_v2                    4      32768                8        1047552                40960
Standard_A4_v2                     4       8192                8        1047552                40960
Standard_A8m_v2                    8      65536               16        1047552                81920
Standard_A8_v2                     8      16384               16        1047552                81920
Standard_D2_v3                     2       8192                4        1047552                51200
Standard_D4_v3                     4      16384                8        1047552               102400
Standard_D8_v3                     8      32768               16        1047552               204800
Standard_D16_v3                   16      65536               32        1047552               409600
Standard_D32_v3                   32     131072               32        1047552               819200
Standard_D48_v3                   48     196608               32        1047552              1228800
Standard_D64_v3                   64     262144               32        1047552              1638400
Standard_D2s_v3                    2       8192                4        1047552                16384
Standard_D4s_v3                    4      16384                8        1047552                32768
Standard_D8s_v3                    8      32768               16        1047552                65536
Standard_D16s_v3                  16      65536               32        1047552               131072
Standard_D32s_v3                  32     131072               32        1047552               262144
Standard_D48s_v3                  48     196608               32        1047552               393216
Standard_D64s_v3                  64     262144               32        1047552               524288
Standard_E2_v3                     2      16384                4        1047552                51200
Standard_E4_v3                     4      32768                8        1047552               102400
Standard_E8_v3                     8      65536               16        1047552               204800
Standard_E16_v3                   16     131072               32        1047552               409600
Standard_E20_v3                   20     163840               32        1047552               512000
Standard_E32_v3                   32     262144               32        1047552               819200
Standard_E48_v3                   48     393216               32        1047552              1228800
Standard_E64i_v3                  64     442368               32        1047552              1638400
Standard_E64_v3                   64     442368               32        1047552              1638400
Standard_E2s_v3                    2      16384                4        1047552                32768
Standard_E4-2s_v3                  4      32768                8        1047552                65536
Standard_E4s_v3                    4      32768                8        1047552                65536
Standard_E8-2s_v3                  8      65536               16        1047552               131072
Standard_E8-4s_v3                  8      65536               16        1047552               131072
Standard_E8s_v3                    8      65536               16        1047552               131072
Standard_E16-4s_v3                16     131072               32        1047552               262144
Standard_E16-8s_v3                16     131072               32        1047552               262144
Standard_E16s_v3                  16     131072               32        1047552               262144
Standard_E20s_v3                  20     163840               32        1047552               327680
Standard_E32-8s_v3                32     262144               32        1047552               524288
Standard_E32-16s_v3               32     262144               32        1047552               524288
Standard_E32s_v3                  32     262144               32        1047552               524288
Standard_E48s_v3                  48     393216               32        1047552               786432
Standard_E64-16s_v3               64     442368               32        1047552               884736
Standard_E64-32s_v3               64     442368               32        1047552               884736
Standard_E64is_v3                 64     442368               32        1047552               884736
Standard_E64s_v3                  64     442368               32        1047552               884736
Standard_E2_v4                     2      16384                4        1047552                    0
Standard_E4_v4                     4      32768                8        1047552                    0
Standard_E8_v4                     8      65536               16        1047552                    0
Standard_E16_v4                   16     131072               32        1047552                    0
Standard_E20_v4                   20     163840               32        1047552                    0
Standard_E32_v4                   32     262144               32        1047552                    0
Standard_E2d_v4                    2      16384                4        1047552                76800
Standard_E4d_v4                    4      32768                8        1047552               153600
Standard_E8d_v4                    8      65536               16        1047552               307200
Standard_E16d_v4                  16     131072               32        1047552               614400
Standard_E20d_v4                  20     163840               32        1047552               768000
Standard_E32d_v4                  32     262144               32        1047552              1228800
Standard_E2s_v4                    2      16384                4        1047552                    0
Standard_E4-2s_v4                  4      32768                8        1047552                    0
Standard_E4s_v4                    4      32768                8        1047552                    0
Standard_E8-2s_v4                  8      65536               16        1047552                    0
Standard_E8-4s_v4                  8      65536               16        1047552                    0
Standard_E8s_v4                    8      65536               16        1047552                    0
Standard_E16-4s_v4                16     131072               32        1047552                    0
Standard_E16-8s_v4                16     131072               32        1047552                    0
Standard_E16s_v4                  16     131072               32        1047552                    0
Standard_E20s_v4                  20     163840               32        1047552                    0
Standard_E32-8s_v4                32     262144               32        1047552                    0
Standard_E32-16s_v4               32     262144               32        1047552                    0
Standard_E32s_v4                  32     262144               32        1047552                    0
Standard_E2ds_v4                   2      16384                4        1047552                76800
Standard_E4-2ds_v4                 4      32768                8        1047552               153600
Standard_E4ds_v4                   4      32768                8        1047552               153600
Standard_E8-2ds_v4                 8      65536               16        1047552               307200
Standard_E8-4ds_v4                 8      65536               16        1047552               307200
Standard_E8ds_v4                   8      65536               16        1047552               307200
Standard_E16-4ds_v4               16     131072               32        1047552               614400
Standard_E16-8ds_v4               16     131072               32        1047552               614400
Standard_E16ds_v4                 16     131072               32        1047552               614400
Standard_E20ds_v4                 20     163840               32        1047552               768000
Standard_E32-8ds_v4               32     262144               32        1047552              1228800
Standard_E32-16ds_v4              32     262144               32        1047552              1228800
Standard_E32ds_v4                 32     262144               32        1047552              1228800
Standard_D2d_v4                    2       8192                4        1047552                76800
Standard_D4d_v4                    4      16384                8        1047552               153600
Standard_D8d_v4                    8      32768               16        1047552               307200
Standard_D16d_v4                  16      65536               32        1047552               614400
Standard_D32d_v4                  32     131072               32        1047552              1228800
Standard_D48d_v4                  48     196608               32        1047552              1843200
Standard_D64d_v4                  64     262144               32        1047552              2457600
Standard_D2_v4                     2       8192                4        1047552                    0
Standard_D4_v4                     4      16384                8        1047552                    0
Standard_D8_v4                     8      32768               16        1047552                    0
Standard_D16_v4                   16      65536               32        1047552                    0
Standard_D32_v4                   32     131072               32        1047552                    0
Standard_D48_v4                   48     196608               32        1047552                    0
Standard_D64_v4                   64     262144               32        1047552                    0
Standard_D2ds_v4                   2       8192                4        1047552                76800
Standard_D4ds_v4                   4      16384                8        1047552               153600
Standard_D8ds_v4                   8      32768               16        1047552               307200
Standard_D16ds_v4                 16      65536               32        1047552               614400
Standard_D32ds_v4                 32     131072               32        1047552              1228800
Standard_D48ds_v4                 48     196608               32        1047552              1843200
Standard_D64ds_v4                 64     262144               32        1047552              2457600
Standard_D2s_v4                    2       8192                4        1047552                    0
Standard_D4s_v4                    4      16384                8        1047552                    0
Standard_D8s_v4                    8      32768               16        1047552                    0
Standard_D16s_v4                  16      65536               32        1047552                    0
Standard_D32s_v4                  32     131072               32        1047552                    0
Standard_D48s_v4                  48     196608               32        1047552                    0
Standard_D64s_v4                  64     262144               32        1047552                    0
Standard_F2s_v2                    2       4096                4        1047552                16384
Standard_F4s_v2                    4       8192                8        1047552                32768
Standard_F8s_v2                    8      16384               16        1047552                65536
Standard_F16s_v2                  16      32768               32        1047552               131072
Standard_F32s_v2                  32      65536               32        1047552               262144
Standard_F48s_v2                  48      98304               32        1047552               393216
Standard_F64s_v2                  64     131072               32        1047552               524288
Standard_F72s_v2                  72     147456               32        1047552               589824
Standard_DC8_v2                    8      32768                8        1047552               409600
Standard_DC1s_v2                   1       4096                1        1047552                51200
Standard_DC2s_v2                   2       8192                2        1047552               102400
Standard_DC4s_v2                   4      16384                4        1047552               204800
Standard_A0                        1        768                1        1047552                20480
Standard_A1                        1       1792                2        1047552                71680
Standard_A2                        2       3584                4        1047552               138240
Standard_A3                        4       7168                8        1047552               291840
Standard_A5                        2      14336                4        1047552               138240
Standard_A4                        8      14336               16        1047552               619520
Standard_A6                        4      28672                8        1047552               291840
Standard_A7                        8      57344               16        1047552               619520
Basic_A0                           1        768                1        1047552                20480
Basic_A1                           1       1792                2        1047552                40960
Basic_A2                           2       3584                4        1047552                61440
Basic_A3                           4       7168                8        1047552               122880
Basic_A4                           8      14336               16        1047552               245760
Standard_E48_v4                   48     393216               32        1047552                    0
Standard_E64_v4                   64     516096               32        1047552                    0
Standard_E48d_v4                  48     393216               32        1047552              1843200
Standard_E64d_v4                  64     516096               32        1047552              2457600
Standard_E48s_v4                  48     393216               32        1047552                    0
Standard_E64-16s_v4               64     516096               32        1047552                    0
Standard_E64-32s_v4               64     516096               32        1047552                    0
Standard_E64s_v4                  64     516096               32        1047552                    0
Standard_E80is_v4                 80     516096               32        1047552                    0
Standard_E48ds_v4                 48     393216               32        1047552              1843200
Standard_E64-16ds_v4              64     516096               32        1047552              2457600
Standard_E64-32ds_v4              64     516096               32        1047552              2457600
Standard_E64ds_v4                 64     516096               32        1047552              2457600
Standard_E80ids_v4                80     516096               32        1047552              4362240
Standard_G1                        2      28672                8        1047552               393216
Standard_G2                        4      57344               16        1047552               786432
Standard_G3                        8     114688               32        1047552              1572864
Standard_G4                       16     229376               64        1047552              3145728
Standard_G5                       32     458752               64        1047552              6291456
Standard_GS1                       2      28672                8        1047552                57344
Standard_GS2                       4      57344               16        1047552               114688
Standard_GS3                       8     114688               32        1047552               229376
Standard_GS4                      16     229376               64        1047552               458752
Standard_GS4-4                    16     229376               64        1047552               458752
Standard_GS4-8                    16     229376               64        1047552               458752
Standard_GS5                      32     458752               64        1047552               917504
Standard_GS5-8                    32     458752               64        1047552               917504
Standard_GS5-16                   32     458752               64        1047552               917504
Standard_L4s                       4      32768               16        1047552               694272
Standard_L8s                       8      65536               32        1047552              1421312
Standard_L16s                     16     131072               64        1047552              2874368
Standard_L32s                     32     262144               64        1047552              5765120
Standard_NC6s_v3                   6     114688               12        1047552               344064
Standard_NC12s_v3                 12     229376               24        1047552               688128
Standard_NC24rs_v3                24     458752               32        1047552              1376256
Standard_NC24s_v3                 24     458752               32        1047552              1376256
Standard_M8-2ms                    8     224000                8        1047552               256000
Standard_M8-4ms                    8     224000                8        1047552               256000
Standard_M8ms                      8     224000                8        1047552               256000
Standard_M16-4ms                  16     448000               16        1047552               512000
Standard_M16-8ms                  16     448000               16        1047552               512000
Standard_M16ms                    16     448000               16        1047552               512000
Standard_M32-8ms                  32     896000               32        1047552              1024000
Standard_M32-16ms                 32     896000               32        1047552              1024000
Standard_M32ls                    32     262144               32        1047552              1024000
Standard_M32ms                    32     896000               32        1047552              1024000
Standard_M32ts                    32     196608               32        1047552              1024000
Standard_M64-16ms                 64    1792000               64        1047552              2048000
Standard_M64-32ms                 64    1792000               64        1047552              2048000
Standard_M64ls                    64     524288               64        1047552              2048000
Standard_M64ms                    64    1792000               64        1047552              2048000
Standard_M64s                     64    1024000               64        1047552              2048000
Standard_M128-32ms               128    3891200               64        1047552              4096000
Standard_M128-64ms               128    3891200               64        1047552              4096000
Standard_M128ms                  128    3891200               64        1047552              4096000
Standard_M128s                   128    2048000               64        1047552              4096000
Standard_M64                      64    1024000               64        1047552              8192000
Standard_M64m                     64    1792000               64        1047552              8192000
Standard_M128                    128    2048000               64        1047552             16384000
Standard_M128m                   128    3891200               64        1047552             16384000
Standard_NV4as_v4                  4      14336                8        1047552                90112
Standard_NV8as_v4                  8      28672               16        1047552               180224
Standard_NV16as_v4                16      57344               32        1047552               360448
Standard_NV32as_v4                32     114688               32        1047552               720896


.NOTES
    General notes


get-azvmsize -Location 'CanadaCentral'


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
