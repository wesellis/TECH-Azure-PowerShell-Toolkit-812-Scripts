#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Multi Nic Vm Iaasv2

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Switch-AzureMode AzureResourceManager
$rgname = 'samplerg'
$VnetName = $rgname + 'vnet'
$VnetAddressPrefix = '10.0.0.0/16'
$SubnetName = $rgname + 'subnet'
$SubnetAddressPrefix = '10.0.1.0/24'
$PublicIpName = $rgname + 'pubip'
$LbName = $rgname + 'lb'
$FrontendName = $rgname + 'frontend'
$BackendAddressPoolName = $rgname + 'backend'
$InboundNatRuleName1 = $rgname + 'nat1'
$nicname1 = $rgname + 'nic1'
$nicname2 = $rgname + 'nic2'
$ResourceTypeParent = "Microsoft.Network/loadBalancers" ;
$location = 'westus';
$vmsize = 'Standard_D2';  # must be A2 or D2 or above for two nics
$vmname = $rgname + 'vm';
$stoname = $rgname.ToLower() + 'sto';
$stotype = 'Standard_LRS';
$OsDiskName = 'osDisk';
$OsDiskVhdUri = "https://$stoname.blob.core.windows.net/vhds/os.vhd" ;
$user = " ops" ;
$credential = Get-Credential -Message 'Enter VM credentials'
$password = $credential.GetNetworkCredential().Password
New-AzureResourceGroup -Name $rgname -Location $location
$subnet = New-AzureVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$vnet = New-AzurevirtualNetwork -Name $VnetName -ResourceGroupName $rgname -Location $location -AddressPrefix $VnetAddressPrefix -Subnet $subnet
$publicip = New-AzurePublicIpAddress -ResourceGroupName $rgname -name $PublicIpName -location $location -AllocationMethod Dynamic
$frontend = New-AzureLoadBalancerFrontendIpConfig -Name $FrontendName -PublicIpAddress $publicip
$BackendAddressPool = New-AzureLoadBalancerBackendAddressPoolConfig -Name $BackendAddressPoolName
$InboundNatRule1 = New-AzureLoadBalancerInboundNatRuleConfig -Name $InboundNatRuleName1 -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 50001 -BackendPort 3389 -IdleTimeoutInMinutes 15
$lb = New-AzureLoadBalancer -Name $LbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $BackendAddressPool -InboundNatRule $InboundNatRule1
$nic1 = New-AzureNetworkInterface -Name $nicname1 -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[0] ;
$nic2 = New-AzureNetworkInterface -Name $nicname2 -ResourceGroupName $rgname -Location $location -SubnetId $vnet.Subnets[0].Id
$nic1.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($lb.BackendAddressPools[0]);
$nic1.IpConfigurations[0].LoadBalancerInboundNatRules.Add($lb.InboundNatRules[0]);
$vm = New-AzureVMConfig -VMName $vmname -VMSize $vmsize;
$vm = Add-AzureVMNetworkInterface -VM $vm -Id $nic1.Id -Primary;
$vm = Add-AzureVMNetworkInterface -VM $vm -Id $nic2.Id;
New-AzureStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $location -Type $stotype;
$stoaccount = Get-AzureStorageAccount -ResourceGroupName $rgname -Name $stoname;
$vm = Set-AzureVMOSDisk -VM $vm -Name $OsDiskName -VhdUri $OsDiskVhdUri -Caching 'ReadWrite' -CreateOption fromImage;
$SecurePassword = Read-Host -Prompt "Enter secure value" -AsSecureString;
$cred = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ($user, $SecurePassword);
$vm = Set-AzureVMOperatingSystem -VM $vm -Windows -ComputerName $vmname -Credential $cred;
$vm = Set-AzureVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version " latest"
New-AzureVM -ResourceGroupName $rgname -Location $location -Name $vmname -VM $vm;



