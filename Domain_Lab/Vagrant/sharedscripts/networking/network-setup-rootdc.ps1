#DNS Setup on ROOT DC

$ip = (Get-NetAdapter | Get-NetIPAddress | ? addressfamily -eq 'IPv4').ipaddress
$firstOctet = $ip.split(".")[0]
$secondOctet = $ip.split(".")[1]
$thirdOctet = $ip.split(".")[2]
$fourthOctet = $ip.split(".")[3]

#Import our file with DNS entries for the DC
Import-CSV -Path C:\root_dns_entries.csv | ForEach-Object {
    Remove-DnsServerResourceRecord -ZoneName "smarter.loc" -RRType "A" -Name $_.Hostname -force
    $hostfullIP = "$firstOctet.$secondOctet.$thirdOctet." + $_.IPEnd
    Add-DnsServerResourceRecordA -Name $_.Hostname -ZoneName "nebulatech.local" -IPv4Address $hostfullIP
}

#Add the DNS forwarder for outbound DNS
$forward = Get-DnsServerForwarder
Remove-DnsServerForwarder $forward.IPAddress -force
Add-DnsServerForwarder -IPAddress 8.8.8.8

#All done, now we can set the DNS of our actual DC as well
$dnsip = "$firstOctet.$secondOctet.$thirdOctet.$fourthOctet"

Remove-DnsServerResourceRecord -ZoneName "nebulatech.local" -RRType "A" -Name "nebulatech.local" -force
Add-DNSServerResourceRecordA -Name "nebulatech.local" -ZoneName "nebulatech.local" -IPv4Address $dnsip

$index = Get-NetAdapter -Name 'Ethernet 2' | Select-Object -ExpandProperty 'ifIndex'
Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $dnsip

