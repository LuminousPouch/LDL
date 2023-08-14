# Ensure necessary modules are installed and imported
Import-Module ActiveDirectory
Import-Module GroupPolicy

# Configure the DC to be a collector
wecutil qc /q

# Specify event IDs and create a subscription
$eventIds = @(4624, 4625, 4634, 4662, 4720, 4722, 4723, 4724, 4725, 4726, 4738, 4740, 4771, 4776, 4781)
$selectQueries = $eventIds -join " or " | ForEach-Object { "EventID=$_" }

$subscriptionXml = @"
<Subscription xmlns="http://schemas.microsoft.com/2006/03/windows/events/subscription">
  <SubscriptionId>SecurityEventSubscription</SubscriptionId>
  <SubscriptionType>SourceInitiated</SubscriptionType>
  <Description>Subscription for specific security events.</Description>
  <Enabled>true</Enabled>
  <Uri>http://schemas.microsoft.com/wbem/wsman/1/windows/EventLog</Uri>
  <ConfigurationMode>Normal</ConfigurationMode>
  <Delivery Mode="Push">
    <Batching>
      <MaxItems>1</MaxItems>
      <MaxLatencyTime>2000</MaxLatencyTime>
    </Batching>
    <PushSettings>
      <Heartbeat Interval="60000"/>
    </PushSettings>
  </Delivery>
  <Query><![CDATA[
    <QueryList>
      <Query Path="Security">
        <Select>*[System[($selectQueries)]]</Select>
      </Query>
    </QueryList>
  ]]></Query>
  <ReadExistingEvents>true</ReadExistingEvents>
  <TransportName>http</TransportName>
  <ContentFormat>RenderedText</ContentFormat>
  <Locale Language="en-US"/>
  <LogFile>ForwardedEvents</LogFile>
  <AllowedSourceNonDomainComputers></AllowedSourceNonDomainComputers>
</Subscription>
"@

$subscriptionPath = "$env:TEMP\Subscription.xml"
$subscriptionXml | Out-File $subscriptionPath -Encoding utf8
wecutil cs $subscriptionPath
Remove-Item -Path $subscriptionPath -Force

# Create a new GPO for event forwarding
$gpoName = "EventForwardingGPO"
New-GPO -Name $gpoName

# Set the GPO setting to configure target Subscription Manager
$gpoPath = "HKLM\SOFTWARE\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager"
$collectorFQDN = "$env:COMPUTERNAME.$env:USERDNSDOMAIN" # Assumes the script runs on the collector
$subscriptionManagerValue = "Server=http://$collectorFQDN:5985/wsman/SubscriptionManager/WEC,Refresh=10"
Set-GPRegistryValue -Name $gpoName -Key $gpoPath -ValueName 0 -Type String -Value $subscriptionManagerValue

# Link the GPO to the root of the domain
$linkToDomain = "DC=$($env:USERDNSDOMAIN.Replace('.',',DC='))"
New-GPLink -Name $gpoName -Target $linkToDomain -LinkEnabled Yes

Write-Output "DC configured as collector, subscription for specific event IDs created, and GPO set up and linked to the domain."
