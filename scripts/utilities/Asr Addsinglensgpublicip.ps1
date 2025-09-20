#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Asr Addsinglensgpublicip

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    .DESCRIPTION
        This will create a Public IP address for the failed over VM - only in test failover.
        Pre-requisites
        1. when you create a new Automation Account, make sure you have chosen to create a run-as account with it.
        2. If you create a run as account on your own, give the Connection Name in the variable - $connectionName
        What all you need to change in this script?
        1. Give the name of the Automation account in the variable - $AutomationAccountName
        2. Give the Resource Group name of the Automation Account in $AutomationAccountRg
        Do you want to add a NSG to the failed over VM? If yes, follow the below steps - you can skip this step if you dont want to add an NSG.
        1. Create the NSG that you want to apply
        2. Create a new Azure automation string variable <RecoveryPlanName>-NSG (example testrp-NSG). Save it with the value of the NSG you want to use.
        3. Create a new  string variable <RecoveryPlanName>-NSGRG (example testrp-NSGRG). Save it with the value of the NSG's Resource group you want to use.
        How to add the script?
        Add this script as a post action in boot up group for which you need a public IP. All the VMs in the group will get a public IP assigned.
        If the NSG parameters are specified, all the VM's NICs will get the same NSG attached.
        Clean up test failover behavior
        Clean up test failover will not delete the IP address. You will need to delete the IP address manually
    .NOTES
        AUTHOR: RuturajD@microsoft.com
        LASTEDIT: 27 January, 2017
workflow ASR-AddSingleNSGPublicIp {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [parameter()]
        [Object]$RecoveryPlanContext
    )
    $connectionName = "AzureRunAsConnection"
    $AutomationAccountName = "" #Fill this up with you Azure Automation Account Name
    $AutomationAccountRg = ""    #Fill this up with you  Account Resource Group
    # This is special code only added for this test run to avoid creating public IPs in S2S VPN network
    if ($RecoveryPlanContext.FailoverType -ne "Test" ) {
        exit
    }
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName
        "Logging in to Azure..."
        $params = @{
            Or = "($VM.RoleName"
            AutomationAccountName = $AutomationAccountName
            ne = $Null)) { ;  $NSG = Get-AzureRmNetworkSecurityGroup
            ErrorAction = "Stop | Where-Object MemberType"
            Location = $azurevm.Location
            NetworkInterface = $VMNetworkInterfaceObject } } }
            EQ = $Null))) { #this is when some data is anot available and it will fail Write-output "Resource group name " , $VM.ResourceGroupName Write-output "Rolename " = $VM.RoleName  InlineScript {  $azurevm = Get-AzureRMVM
            ResourceId = $azurevm.NetworkInterfaceIDs[0] write-output "Nic Arm Object Id = " , $NicArmObject.Id $VMNetworkInterfaceObject = Get-AzureRmNetworkInterface
            ResourceGroupName = $Using:NSGRGname Write-output $NSG.Id $VMNetworkInterfaceObject.NetworkSecurityGroup = $NSG } #Update the properties now Set-AzureRmNetworkInterface
            TenantId = $servicePrincipalConnection.TenantId
            Name = $Using:NSGname
            ApplicationId = $servicePrincipalConnection.ApplicationId
            ExpandProperty = "Name  Write-output $RecoveryPlanContext.VmMap Write-output $RecoveryPlanContext  # Get the NSG based on the name # if he has not passed this value just create the public IP and go ahead   $NSGValue = $RecoveryPlanContext.RecoveryPlanName + "
            Message = $_.Exception throw $_.Exception } }  $VMinfo = $RecoveryPlanContext.VmMap | Get-Member
            AllocationMethod = "Dynamic"
            Output = $NSGValue Write-Output $NSGRGValue  $NSGnameVar = Get-AzureRMAutomationVariable
            CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint } catch { if (!$servicePrincipalConnection) { $ErrorMessage = "Connection $connectionName not found." throw $ErrorMessage } else{ Write-Error
            And = "($Using:NSGRGname"
        }
        #Add-AzureRmAccount @params
}


