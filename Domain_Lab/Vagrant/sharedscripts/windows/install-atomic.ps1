#Install Atomic under C://AtomicRedTeam
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
Install-AtomicRedTeam -getAtomics -Force;