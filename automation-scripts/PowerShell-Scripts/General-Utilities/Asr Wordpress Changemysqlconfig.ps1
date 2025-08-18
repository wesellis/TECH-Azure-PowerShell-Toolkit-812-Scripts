<#
.SYNOPSIS
    Asr Wordpress Changemysqlconfig

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
    We Enhanced Asr Wordpress Changemysqlconfig

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
    .DESCRIPTION
        This Runbook changes the WordPress configuration by replacing the wp-config.php and replace it with wp-config.php.Azure. 
        The old file will get renamed as wp-config.php.onprem
        This is an example script used in blog https://azure.microsoft.com/en-us/blog/one-click-failover-of-application-to-microsoft-azure-using-site-recovery

        This runbook uses an external powershellscript located at https://raw.githubusercontent.com/ruturaj/RecoveryPlanScripts/master/ChangeWPDBHostIP.ps1
        and runs it inside all of the VMs of the group this script is added to.

        Parameter to change -
            $recoveryLocation - change this to the location to which the VM is recovering to
            
    .NOTES
        AUTHOR: RuturajD@microsoft.com
        LASTEDIT: 27 March, 2017



workflow ASR-Wordpress-ChangeMysqlConfig
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [parameter(Mandatory=$false)]
        [Object]$WERecoveryPlanContext
    )

	$connectionName = " AzureRunAsConnection"
    $recoveryLocation = " southeastasia"

    # This is special code only added for this test run to avoid creating public IPs in S2S VPN network
    #if ($WERecoveryPlanContext.FailoverType -ne " Test" ) {
    #    exit
    #}

	try
	{
		# Get the connection " AzureRunAsConnection "
		$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

        

		" Logging in to Azure..."
		#Add-AzureRmAccount `
        Login-AzureRmAccount `
			-ServicePrincipal `
			-TenantId $servicePrincipalConnection.TenantId `
			-ApplicationId $servicePrincipalConnection.ApplicationId `
			-CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
	}
	catch {
		if (!$servicePrincipalConnection)
		{
			$WEErrorMessage = " Connection $connectionName not found."
			throw $WEErrorMessage
		} else{
			Write-Error -Message $_.Exception
			throw $_.Exception
		}
	} 
    
   ;  $WEVMinfo = $WERecoveryPlanContext.VmMap | Get-Member -ErrorAction Stop | Where-Object MemberType -EQ NoteProperty | select -ExpandProperty Name
	
    Write-output $WERecoveryPlanContext.VmMap
    Write-output $WERecoveryPlanContext
    

   ;  $WEVMs = $WERecoveryPlanContext.VmMap;
	
    $vmMap = $WERecoveryPlanContext.VmMap
    
    foreach($WEVMID in $WEVMinfo)
    {
       ;  $WEVM = $vmMap.$WEVMID                

        if( !(($WEVM -eq $WENull) -Or ($WEVM.ResourceGroupName -eq $WENull) -Or ($WEVM.RoleName -eq $WENull))) {
            #this is when some data is anot available and it will fail
            Write-output " Resource group name " , $WEVM.ResourceGroupName
            Write-output " Rolename " = $WEVM.RoleName

            InlineScript { 

                Set-AzureRmVMCustomScriptExtension -ResourceGroupName $WEUsing:VM.ResourceGroupName `
                     -VMName $WEUsing:VM.RoleName `
                     -Name " myCustomScript" `
                     -FileUri " https://raw.githubusercontent.com/ruturaj/RecoveryPlanScripts/master/ChangeWPDBHostIP.ps1" `
                     -Run " ChangeWPDBHostIP.ps1" -Location $recoveryLocation
            }
        } 
    }	
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================