<#
================================================================
  QVIS Technology Solutions
  DHCP role install, scope creation, options and failover.
  Run on DC1 as Domain Admin. Re-run on DC2 only for failover step.
================================================================
#>

# ---------- 1. Install DHCP role -------------------------------
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# ---------- 2. Authorize the DHCP server in AD -----------------
Add-DhcpServerInDC -DnsName 'DC1.qvis.local' -IPAddress 10.10.20.10

# ---------- 3. Tell Server Manager that post-deploy is done ----
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12' `
                 -Name 'ConfigurationState' -Value 2

# ---------- 4. Service binding ---------------------------------
Set-DhcpServerv4Binding -InterfaceAlias 'Ethernet0' -BindingState $true

# ---------- 5. Scopes ------------------------------------------
function New-QvisScope {
    param(
        [string]$Name, [string]$Net, [string]$Start, [string]$End,
        [string]$Mask, [string]$Router, [int]$Lease = 691200      # 8 days default
    )
    Add-DhcpServerv4Scope -Name $Name -StartRange $Start -EndRange $End `
                          -SubnetMask $Mask -State Active -LeaseDuration ([TimeSpan]::FromSeconds($Lease))
    Set-DhcpServerv4OptionValue -ScopeId $Net `
        -Router $Router `
        -DnsServer 10.10.20.10,10.10.20.11 `
        -DnsDomain 'qvis.local'
}

New-QvisScope -Name 'QVIS-MGMT'      -Net 10.10.10.0 -Start 10.10.10.20 -End 10.10.10.199 -Mask 255.255.255.0 -Router 10.10.10.1
New-QvisScope -Name 'QVIS-EXEC-FIN'  -Net 10.10.30.0 -Start 10.10.30.20 -End 10.10.30.199 -Mask 255.255.255.0 -Router 10.10.30.1
New-QvisScope -Name 'QVIS-STAFF'     -Net 10.10.40.0 -Start 10.10.40.20 -End 10.10.40.199 -Mask 255.255.255.0 -Router 10.10.40.1
New-QvisScope -Name 'QVIS-TECH'      -Net 10.10.50.0 -Start 10.10.50.20 -End 10.10.50.199 -Mask 255.255.255.0 -Router 10.10.50.1
New-QvisScope -Name 'QVIS-LAB'       -Net 10.10.60.0 -Start 10.10.60.50 -End 10.10.60.150 -Mask 255.255.255.0 -Router 10.10.60.1 -Lease 14400      # 4 hours
New-QvisScope -Name 'QVIS-VOICE'     -Net 10.10.70.0 -Start 10.10.70.20 -End 10.10.70.199 -Mask 255.255.255.0 -Router 10.10.70.1
New-QvisScope -Name 'QVIS-PRINT'     -Net 10.10.80.0 -Start 10.10.80.20 -End 10.10.80.49  -Mask 255.255.255.0 -Router 10.10.80.1
New-QvisScope -Name 'QVIS-GUEST'     -Net 10.10.90.0 -Start 10.10.90.20 -End 10.10.90.254 -Mask 255.255.255.0 -Router 10.10.90.1 -Lease 14400

# Guest: public DNS only, override the default
Set-DhcpServerv4OptionValue -ScopeId 10.10.90.0 -DnsServer 1.1.1.1,9.9.9.9 -DnsDomain 'guest.qvistech.ca'

# Voice scope: TFTP option 150 for phone firmware
Set-DhcpServerv4OptionValue -ScopeId 10.10.70.0 -OptionId 150 -Value 10.10.20.12

# ---------- 6. Reservations -----------------------------------
# Printers
Add-DhcpServerv4Reservation -ScopeId 10.10.80.0 -IPAddress 10.10.80.10 -ClientId 'AA-BB-CC-11-22-01' -Name 'PRN1-NorthMFP' -Description 'HP M428 - North wing MFP'
Add-DhcpServerv4Reservation -ScopeId 10.10.80.0 -IPAddress 10.10.80.11 -ClientId 'AA-BB-CC-11-22-02' -Name 'PRN2-SouthMFP' -Description 'HP M428 - South wing MFP'
Add-DhcpServerv4Reservation -ScopeId 10.10.80.0 -IPAddress 10.10.80.12 -ClientId 'AA-BB-CC-11-22-03' -Name 'PRN3-FinanceMFP' -Description 'HP M428 - Finance MFP'

# APs
Add-DhcpServerv4Reservation -ScopeId 10.10.10.0 -IPAddress 10.10.10.4 -ClientId 'AA-BB-CC-22-33-01' -Name 'AP1-Lobby'
Add-DhcpServerv4Reservation -ScopeId 10.10.10.0 -IPAddress 10.10.10.5 -ClientId 'AA-BB-CC-22-33-02' -Name 'AP2-Bullpen'
Add-DhcpServerv4Reservation -ScopeId 10.10.10.0 -IPAddress 10.10.10.6 -ClientId 'AA-BB-CC-22-33-03' -Name 'AP3-Lab'

# Conference room AV controller
Add-DhcpServerv4Reservation -ScopeId 10.10.40.0 -IPAddress 10.10.40.15 -ClientId 'AA-BB-CC-33-44-01' -Name 'R8-AV-Controller'

# ---------- 7. Audit log + DNS update credentials -------------
Set-DhcpServerAuditLog -Enable $true -Path 'C:\Windows\System32\dhcp'
Set-DhcpServerDnsCredential -Credential (Get-Credential -Message 'Service account allowed to update DNS')

# ---------- 8. Failover: pair DC1 with DC2 --------------------
# DC2 must already have DHCP role installed and be authorised.
Add-DhcpServerv4Failover `
    -Name 'QVIS-DHCP-Failover' `
    -PartnerServer 'DC2.qvis.local' `
    -ScopeId 10.10.10.0,10.10.30.0,10.10.40.0,10.10.50.0,10.10.60.0,10.10.70.0,10.10.80.0,10.10.90.0 `
    -SharedSecret 'replace-with-strong-shared-secret' `
    -ServerRole Active `
    -LoadBalancePercent 50 `
    -MaxClientLeadTime ([TimeSpan]::FromHours(1))

Write-Host "`n[OK]  DHCP scopes, reservations and failover configured.`n" -ForegroundColor Green

# ---------- 9. Verify -----------------------------------------
# Get-DhcpServerv4Scope
# Get-DhcpServerv4Reservation -ScopeId 10.10.80.0
# Get-DhcpServerv4Failover
# Get-DhcpServerv4Statistics -ScopeId 10.10.40.0
