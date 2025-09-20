<#
.SYNOPSIS
    Asr Wordpress Changemysqlconfig

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
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
        [parameter()]
        [Object]$RecoveryPlanContext
    )
	$connectionName = "AzureRunAsConnection"
    $recoveryLocation = " southeastasia"
    # This is special code only added for this test run to avoid creating public IPs in S2S VPN network
    #if ($RecoveryPlanContext.FailoverType -ne "Test" ) {
    #    exit
    #}
	try
	{
		# Get the connection "AzureRunAsConnection "
		$servicePrincipalConnection=Get-AutomationConnection -Name $connectionName
		"Logging in to Azure..."
		$params = @{
		    Message = $_.Exception throw $_.Exception } }  ;  $VMinfo = $RecoveryPlanContext.VmMap | Get-Member
		    ExpandProperty = "Name  Write-output $RecoveryPlanContext.VmMap Write-output $RecoveryPlanContext"
		    TenantId = $servicePrincipalConnection.TenantId
		    ApplicationId = $servicePrincipalConnection.ApplicationId
		    EQ = "NoteProperty | select"
		    ErrorAction = "Stop | Where-Object MemberType"
		    CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint } catch { if (!$servicePrincipalConnection) { $ErrorMessage = "Connection $connectionName not found." throw $ErrorMessage } else{ Write-Error
		}
		#Add-AzureRmAccount @params
$VMs = $RecoveryPlanContext.VmMap;
    $vmMap = $RecoveryPlanContext.VmMap
    foreach($VMID in $VMinfo)
    {
$VM = $vmMap.$VMID
        if( !(($VM -eq $Null) -Or ($VM.ResourceGroupName -eq $Null) -Or ($VM.RoleName -eq $Null))) {
            #this is when some data is anot available and it will fail
            Write-output "Resource group name " , $VM.ResourceGroupName
            Write-output "Rolename " = $VM.RoleName
            InlineScript {
                $params = @{
                    ResourceGroupName = $Using:VM.ResourceGroupName
                    Name = " myCustomScript"
                    FileUri = "https://raw.githubusercontent.com/ruturaj/RecoveryPlanScripts/master/ChangeWPDBHostIP.ps1"
                    Location = $recoveryLocation } } }
                    Run = "ChangeWPDBHostIP.ps1"
                    VMName = $Using:VM.RoleName
                }
                Set-AzureRmVMCustomScriptExtension @params
}\n