# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #
# SNMP Install
# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #

Add-WindowsFeature -Name "SNMP-Service"

New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities -Name 'prtg' -PropertyType DWord -Value 4
Remove-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers -Name 1

New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers -Name 1 -PropertyType String -Value 'prtg.domain.local'
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers -Name 2 -PropertyType String -Value 'test.domain.local'

if((Get-WmiObject win32_operatingsystem).Version -like '6.1.7601') {
  netsh advfirewall firewall set rule name="SNMP Service (UDP In)" profile=domain new remoteip="172.16.1.1,172.16.1.2"
  netsh advfirewall firewall set rule name="SNMP Service (UDP In)" profile="private,public" new enable=no
} else {
  Set-NetFirewallRule -Name 'SNMP-In-UDP' -Enabled False
  Set-NetFirewallRule -Name 'SNMP-In-UDP-NoScope' -RemoteAddress @("172.16.1.1", "172.16.1.2")
}
if (Get-Service -Name snmp) {
  Write-Host " SNMP installed - OK"
}
