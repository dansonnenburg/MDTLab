New-VMSwitch –SwitchName "NAT” –SwitchType Internal 
New-NetIPAddress –IPAddress 192.168.1.1 -PrefixLength 24 -InterfaceAlias "vEthernet (NAT)" 
New-NetNat –Name NATNetwork –InternalIPInterfaceAddressPrefix 192.168.1.0/24