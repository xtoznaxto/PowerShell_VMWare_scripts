if (!$session.IsConnected) { 
 $creds = Get-Credential -Message "Authenticate to  Cloud Service"
 $session = Connect-VIServer -Server server.com -Credential $creds  
 }



function Make_new_vm 
{
$os_cust = Get-OSCustomizationSpec -Name hostname_cust
$res_pull = Get-ResourcePool -Name Swift

$csv = @()
$csv = Import-CSV -Path 'C:\Users\Documents\HPI-vms_swift_1.csv' -Delimiter ";"  | Where {$_.vm_name}
$csv | % {
    $_.vm_name = $_.vm_name.Trim()
    $_.cpu = $_.cpu.Trim()
    $_.ram = $_.ram.Trim()
    $_.ip = $_.ip.Trim()
    $_.mask = $_.mask.Trim()
    $_.gateway = $_.gateway.Trim()
    $_.etalon = $_.etalon.Trim()
    $_.network = $_.network.Trim()
    }

foreach ($new_vm_name in $csv) {
New-VM -Name $new_vm_name.vm_name -Template $new_vm_name.etalon -OSCustomizationSpec $os_cust  -ResourcePool $res_pull -Datastore vsanDatastore -Location CustomerVM| Set-VM -NumCpu $new_vm_name.cpu -MemoryGB $new_vm_name.ram -Confirm:$false
write-host "...  wait 10 s..."
Start-Sleep -s 10
Get-vm -Name $new_vm_name.vm_name | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $new_vm_name.network -StartConnected:$true -Confirm:$false
} 

foreach ($new_vm_name in $csv) {
 $vm_info = Get-VM -Name $new_vm_name.vm_name
 $vm_info | Start-VM | Wait-Tools 
 $vm_info.ExtensionData.Guest.ToolsStatus
 $vm_info.ExtensionData.Guest.ToolsRunningStatus
 write-host "...wait 60 s..."
 Start-Sleep -s 60
 $vm_info.ExtensionData.Guest.ToolsStatus
 $vm_info.ExtensionData.Guest.ToolsRunningStatus
 }
 
 
foreach ($new_vm_name in $csv) {
 $vm_info = Get-VM -Name $new_vm_name.vm_name
 $name = $new_vm_name.vm_name
 $ip = $new_vm_name.ip
 $mask = $new_vm_name.mask
 $gateway = $new_vm_name.gateway
 $net_set0 = "ifconfig ens160 down; ifconfig ens160 $ip netmask $mask broadcast $gateway; ifconfig ens1 up; ifconfig ens1"
 $net_set1 = "hostname && nmcli con mod ens1 ipv6.method 'ignore'"
 $net_set2 = "hostname && nmcli con delete ens1 && nmcli con add type ethernet con-name ens1 ifname ens1 ip4 $ip/16 gw4 10.0.0.1 && nmcli con mod ens1 ipv4.dns '8.8.8.8 1.1.1.1' ipv4.dns-search 'dc.domain.com' && nmcli con up ens1 && ip a && ping 10.0.0.1 -c 3"
 $net_set3 = "hostname && sysctl -w net.ipv6.conf.ens1.disable_ipv6=1"
 $net_set = "hostname && sysctl -w net.ipv6.conf.ens1.disable_ipv6=1 && ping 192.168.1.1 -c 2"
 $net_set5 = "ipa-client-install --enable-dns-updates --mkhome --domain=dc.domain.com --server=ipa.com -p username --password=secret_pass --unattended"
 Invoke-VMScript -ScriptText $net_set4 -VM $vm_info -GuestUser root -GuestPassword Qwerty -ScriptType Bash
 }
}

