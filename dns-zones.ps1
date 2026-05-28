<#
================================================================
  QVIS Technology Solutions
  DNS zones, reverse lookup, forwarders, scavenging.
  Run on DC1 as Domain Admin.
  AD DS install already brought up the qvis.local zone.
================================================================
#>

# ---------- 1. Forward zone already exists; tighten it ---------
# Secure dynamic update only (anonymous joins cannot poison records)
Set-DnsServerPrimaryZone -Name 'qvis.local' -DynamicUpdate Secure

# ---------- 2. Reverse lookup zone (covers all 10.10.x.x) ------
Add-DnsServerPrimaryZone `
    -NetworkID 10.10.0.0/16 `
    -ReplicationScope Domain `
    -DynamicUpdate Secure

# ---------- 3. Forwarders ---------------------------------------
Set-DnsServerForwarder -IPAddress 1.1.1.1, 9.9.9.9 -UseRootHint $false -Timeout 5

# ---------- 4. Conditional forwarder example (legal partner) ---
# Add-DnsServerConditionalForwarderZone -Name partner.example.com -MasterServers 198.51.100.10 -ReplicationScope Forest

# ---------- 5. Scavenging (clean stale records) ----------------
Set-DnsServerScavenging `
    -ScavengingState $true `
    -ScavengingInterval 7.00:00:00 `
    -ApplyOnAllZones

Set-DnsServerZoneAging `
    -Name 'qvis.local' `
    -Aging $true `
    -RefreshInterval 7.00:00:00 `
    -NoRefreshInterval 7.00:00:00

# ---------- 6. Static records that should never come from DHCP --
# Use DHCP reservations rather than static A records where possible.
# Below are records for things that aren't DHCP clients at all.
Add-DnsServerResourceRecordA -ZoneName qvis.local -Name 'fs1'   -IPv4Address 10.10.20.12
Add-DnsServerResourceRecordA -ZoneName qvis.local -Name 'core'  -IPv4Address 10.10.10.1
Add-DnsServerResourceRecordA -ZoneName qvis.local -Name 'r1'    -IPv4Address 10.10.0.1
Add-DnsServerResourceRecordA -ZoneName qvis.local -Name 'acc1'  -IPv4Address 10.10.10.2
Add-DnsServerResourceRecordA -ZoneName qvis.local -Name 'acc2'  -IPv4Address 10.10.10.3

# CNAMEs that staff actually type
Add-DnsServerResourceRecordCName -ZoneName qvis.local -Name 'files'   -HostNameAlias 'fs1.qvis.local'
Add-DnsServerResourceRecordCName -ZoneName qvis.local -Name 'intranet' -HostNameAlias 'fs1.qvis.local'

# ---------- 7. Verify ------------------------------------------
# Get-DnsServerZone
# Get-DnsServerForwarder
# Get-DnsServerScavenging
# Resolve-DnsName files.qvis.local

Write-Host "`n[OK]  DNS zones, forwarders and scavenging configured.`n" -ForegroundColor Green
