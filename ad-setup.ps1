<#
================================================================
  QVIS Technology Solutions
  AD DS install + forest promotion
  Target: DC1 (10.10.20.10), Windows Server 2022 Standard
  Run as local Administrator on the box BEFORE it is joined to anything.
================================================================
#>

# --- 1. Rename and re-IP the server before any AD work --------
Rename-Computer -NewName 'DC1' -Force
New-NetIPAddress  -InterfaceAlias 'Ethernet0' `
                  -IPAddress 10.10.20.10 `
                  -PrefixLength 24 `
                  -DefaultGateway 10.10.20.1
Set-DnsClientServerAddress -InterfaceAlias 'Ethernet0' `
                           -ServerAddresses 127.0.0.1, 10.10.20.11

Restart-Computer -Force          # comes back as DC1
# ----------------------------------------------------------------

# --- 2. Install AD DS role -------------------------------------
Install-WindowsFeature -Name AD-Domain-Services `
                       -IncludeManagementTools

# --- 3. Promote to first DC in a brand-new forest --------------
$SafeMode = Read-Host -AsSecureString 'DSRM password (write it down!)'

Install-ADDSForest `
    -DomainName 'qvis.local' `
    -DomainNetbiosName 'QVIS' `
    -ForestMode 'WinThreshold' `
    -DomainMode 'WinThreshold' `
    -InstallDns:$true `
    -CreateDnsDelegation:$false `
    -DatabasePath 'C:\Windows\NTDS' `
    -LogPath 'C:\Windows\NTDS' `
    -SysvolPath 'C:\Windows\SYSVOL' `
    -SafeModeAdministratorPassword $SafeMode `
    -Force:$true

# Server reboots automatically. After reboot, log in as QVIS\Administrator.

<#
================================================================
  POST-PROMOTION TASKS (run on DC1 once it's back up)
================================================================
#>

# --- 4. Domain & forest functional levels ----------------------
Set-ADForestMode  -Identity 'qvis.local' -ForestMode  Windows2016Forest -Confirm:$false
Set-ADDomainMode  -Identity 'qvis.local' -DomainMode  Windows2016Domain -Confirm:$false

# --- 5. Set the PDC emulator to use external NTP --------------
w32tm /config /manualpeerlist:'time.nist.gov,0x8 time.windows.com,0x8' /syncfromflags:manual /reliable:yes /update
Restart-Service w32time
w32tm /resync

# --- 6. Recycle Bin (enable so deletions are recoverable) -----
Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' `
    -Scope ForestOrConfigurationSet `
    -Target 'qvis.local' `
    -Confirm:$false

<#
================================================================
  ADDING DC2 (10.10.20.11) AS A SECONDARY DC
  Run these on the DC2 server AFTER joining it to qvis.local.
================================================================
#>

# On DC2:
#   Rename-Computer -NewName 'DC2' -Force
#   Set static IP 10.10.20.11/24, GW 10.10.20.1, DNS = 10.10.20.10
#   Add-Computer -DomainName qvis.local -Credential (Get-Credential)
#   Restart-Computer
#   Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
#   Install-ADDSDomainController -DomainName qvis.local `
#       -InstallDns:$true -Credential (Get-Credential) `
#       -SafeModeAdministratorPassword (Read-Host -AsSecureString 'DSRM pw')

Write-Host '`n[OK]  Forest qvis.local created. Next: ou-and-groups.ps1' -ForegroundColor Green
