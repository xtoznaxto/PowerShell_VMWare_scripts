if (!$session.IsConnected) { 
 $creds = Get-Credential -Message "Authenticate to  Cloud Service"
 $session = Connect-CIServer -Server server.com -Org org_name -Credential $creds  
 }

$item_numbers = 1 .. 10

function Set_memory
{
 $vm_names = (Read-Host -Prompt 'Enter vm names you whant to work with (ex. web-vm)').Split(",")
 [ValidateRange(1024,65536)] [int]$memory_size = Read-Host -Prompt 'Enter needed memory size, between 1024 and 65536 Mb. (ex.2048/4096/8192, min step 128 Mb)'
 if (($memory_size / 128) -is [int]) 
 {
 foreach ($vm_name in $vm_names)
  {
  $civm = Get-CIVM -Name $vm_name
  foreach ($item in $item_numbers)
    {
    if ($civm.ExtensionData.Section[0].Item[$item].Description -like "Memory Size") 
     {
     $current_value = $civm.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value
     $civm.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value = $memory_size
     "!!!Changing memory size for $vm_name in item[$item] from $current_value to $memory_size!!!"
     #$civm | stop-CIVM -confirm:$false
     $civm.ExtensionData.Section[0].UpdateServerData()
     #$civm | start-CIVM -confirm:$false
     } 
    }
   }
  } Else {"Enter memory size in valid format. Value should be 128Mb multiple."}
}

function Set_CPU
{
 $vm_names = (Read-Host -Prompt 'Enter vm names you whant to work with (ex. web-vm)').Split(",")
 [ValidateRange(1,16)][int]$cpu_quantity = Read-Host -Prompt 'Enter needed CPU quantity numbers (ex. 2)'
 foreach ($vm_name in $vm_names)
  {
  $civm = Get-CIVM -Name $vm_name
  foreach ($item in $item_numbers)
    {
    if ($civm.ExtensionData.Section[0].Item[$item].Description -like "Number of Virtual CPUs") 
     {
     $current_value = $civm.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value
     $civm.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value = $cpu_quantity
     "!!!Changing number of CPUs for $vm_name in item[$item] from $current_value to $cpu_quantity!!!"
     #$civm | stop-CIVM -confirm:$false
     $civm.ExtensionData.Section[0].UpdateServerData()
     #$civm | start-CIVM -confirm:$false
     } 
    }
   }
}

function Set_memory_cpu
{
 $vm_names = (Read-Host -Prompt 'Enter vm names you whant to work with (ex. web-vm)').Split(",")
 [ValidateRange(1,16)]$cpu_quantity = Read-Host -Prompt 'Enter needed CPU quantity numbers (ex. 2)'
 [ValidateRange(1024,65536)] [int]$memory_size = Read-Host -Prompt 'Enter needed memory size, between 1024 and 65536 Mb. (ex.2048/4096/8192, min step 128 Mb)'
 if (($memory_size / 128) -is [int]) 
 {
 foreach ($vm_name in $vm_names)
  {
  $civm = Get-CIVM -Name $vm_name
  foreach ($item in $item_numbers)
    {
    if ($civm.ExtensionData.Section[0].Item[$item].Description -like "Memory Size") 
     {
     $current_value = $civm.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value
     $civm.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value = $memory_size
     "!!!Changing memory size for $vm_name in item[$item] from $current_value to $memory_size!!! -ForegroundColor Red"
     } 
    if ($civm.ExtensionData.Section[0].Item[$item].Description -like "Number of Virtual CPUs") 
     {
     $current_value = $civm.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value
     $civm.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value = $cpu_quantity
     "!!!Changing number of CPUs for $vm_name in item[$item] from $current_value to $cpu_quantity!!! -ForegroundColor Red"
     }
    }
     #$civm | stop-CIVM -confirm:$false
     $civm.ExtensionData.Section[0].UpdateServerData()
     #$civm | start-CIVM -confirm:$false
    }
   } Else {"Enter memory size in valid format. Value should be 128Mb multiple."}
}


function Stop_vms
{
 $vm_names = (Read-Host -Prompt 'Enter vm names you whant to work with (ex. web_vm,test_vm)').Split(",")
 $vm_info = Get-CIVM -Name *dev #$vm_names
  if ($vm_info.Status -like "PoweredOn") 
   {   $vm_info | stop-CIVM -confirm:$false} 
   Else {Write-Host "$vm_names already Powered Off" -Foregroundcolor "Green"}
}

function Start_vms
{
 $vm_names = (Read-Host -Prompt 'Enter vm names you whant to work with (ex. web_vm,test_vm)').Split(",")
  $vm_info = Get-CIVM -Name $vm_names
      if ($vm_info.Status -like "PoweredOff") 
     {
     $vm_info | start-CIVM -confirm:$false
     } Else {"$vm_names already Powered On"}
}


function Change_pass
{
$vm_names = (Read-Host -Prompt 'Enter vm names you whant to work with (ex. web_vm,test_vm)').Split(",")
$vm_info = Get-CIVM -Name $vm_names
if ($vm_info.Status -like "PoweredOn") 
  {$vm_info | stop-CIVM -confirm:$rue} 
  Else 
  {"$vm_names already Powered Off"}
$vm_info.ExtensionData.Section[3].Enabled = $true
$vm_info.ExtensionData.Section[3].AdminPasswordAuto = $false
$vm_info.ExtensionData.Section[3].AdminPassword = 'some_password'
$vm_info.ExtensionData.Section[3].UpdateServerData()
$vm_info.ExtensionData.Deploy(1,1,0)
}


function Make_new_vm 
{
$vdc = Get-OrgVdc | Out-GridView -PassThru -Title "Choose  vDC"
$vapp = Get-CIVApp -OrgVdc $vdc | Out-GridView -PassThru -Title "Choose vapp"
$etalon = Get-CIVAppTemplate | Out-GridView -PassThru -Title "Choose etalon"
$new_vm_names = @((Read-Host -Prompt 'Enter vm names you whant to create').Split(","))
$new_vms_count = $new_vm_names.count

"You are going to create $new_vms_count new vms in $vapp"
$confirmation = Read-Host "Are you shure? [y/n]"
while($confirmation -ne "y")
{
    if ($confirmation -eq 'n') {exit}
    $confirmation = Read-Host "Please, give exact answer? [y/n]"
}

[ValidateRange(1,16)]$cpu_quantity = Read-Host -Prompt 'Enter needed CPU quantity numbers (ex. 2)'
[ValidateRange(1024,65536)] [int]$memory_size = Read-Host -Prompt 'Enter needed memory size, between 1024 and 65536 Mb. (ex.2048/4096/8192, min step 128 Mb)'
$myVappNetwork = Get-CIVAppNetwork -VApp $vapp | Out-GridView -PassThru -Title "Choose  Network"

foreach ($new_vm_name in $new_vm_names) {
New-CIVM -VApp $vapp.Name -VMTemplate $etalon.Name -Name $new_vm_name -ComputerName $new_vm_name
}

foreach ($new_vm_name in $new_vm_names) {
$vm_info = Get-CIVM -Name $new_vm_name
$ip_addres = Read-Host -Prompt "Enter ip address for $new_vm_name in $myVappNetwork"
$vm_info | Get-CINetworkAdapter | Set-CINetworkAdapter -VAppNetwork $myVappNetwork[0] -Connected $true -IPAddressAllocationMode Manual -IPAddress $ip_addres
foreach ($item in $item_numbers)
 {
 if ($vm_info.ExtensionData.Section[0].Item[$item].Description -like "Memory Size") 
  {
     $current_value = $vm_info.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value
     $vm_info.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value = $memory_size
     "!!!Changing memory size for $new_vm_name in item[$item] from $current_value to $memory_size!!!"
     } 
 if ($vm_info.ExtensionData.Section[0].Item[$item].Description -like "Number of Virtual CPUs") 
  {
     $current_value = $vm_info.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value
     $vm_info.ExtensionData.Section[0].Item[$item].VirtualQuantity.Value = $cpu_quantity
     "!!!Changing number of CPUs for $new_vm_name in item[$item] from $current_value to $cpu_quantity!!!"
     }
  }
$vm_info.ExtensionData.Section[3].Enabled = $true
$vm_info.ExtensionData.Section[3].AdminPasswordAuto = $false
$vm_info.ExtensionData.Section[3].AdminPassword = 'some_password'
$vm_info.ExtensionData.Section[0].UpdateServerData()
$vm_info.ExtensionData.Section[3].UpdateServerData()
$vm_info | start-CIVM -confirm:$false
 }
}


function export_VMs_info
{ 
Get-CIVM | Export-Csv "C:\Users\DeNovoVMs$(get-date -f dd-MM-yyyy--HH-mm).csv"
Get-CINetworkAdapter | Export-Csv "C:\Users\DeNovoVMs_IPs$(get-date -f dd-MM-yyyy--HH-mm).csv"
}
