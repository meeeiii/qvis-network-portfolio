<#
================================================================
  QVIS Technology Solutions
  Build the OU tree and the AGDLP security groups.
  Run on DC1 after ad-setup.ps1, as Domain Admin.
================================================================
#>

Import-Module ActiveDirectory

$Root   = 'OU=QVIS,DC=qvis,DC=local'
$Domain = 'DC=qvis,DC=local'

# --- helper -----------------------------------------------------
function New-OUSafe {
    param([string]$Name,[string]$Path)
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -SearchScope OneLevel -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
        Write-Host "  + OU $Name created under $Path"
    } else {
        Write-Host "  = OU $Name already exists under $Path"
    }
}

# ---------- 1. Top-level QVIS ----------------------------------
New-OUSafe -Name 'QVIS' -Path $Domain

# ---------- 2. Branches under OU=QVIS --------------------------
'_Disabled','ServiceAccounts','Users','Computers','Groups' |
    ForEach-Object { New-OUSafe -Name $_ -Path $Root }

# ---------- 3. Users sub-OUs -----------------------------------
$UsersOU = "OU=Users,$Root"
'Executive','Finance-HR','Sales-Marketing','Technical','Support-Admin' |
    ForEach-Object { New-OUSafe -Name $_ -Path $UsersOU }

$TechOU = "OU=Technical,$UsersOU"
'Network','Cloud-Sysadmin' |
    ForEach-Object { New-OUSafe -Name $_ -Path $TechOU }

# ---------- 4. Computers sub-OUs -------------------------------
$CompOU = "OU=Computers,$Root"
'Workstations','Laptops','Servers' |
    ForEach-Object { New-OUSafe -Name $_ -Path $CompOU }

$WksOU = "OU=Workstations,$CompOU"
'Executive','Finance-HR','Sales-Marketing','Technical','Support-Admin' |
    ForEach-Object { New-OUSafe -Name $_ -Path $WksOU }

$SrvOU = "OU=Servers,$CompOU"
'FileServers','Application' |
    ForEach-Object { New-OUSafe -Name $_ -Path $SrvOU }

# ---------- 5. Groups sub-OUs ----------------------------------
$GroupsOU = "OU=Groups,$Root"
'Security','Distribution' |
    ForEach-Object { New-OUSafe -Name $_ -Path $GroupsOU }

$SecOU = "OU=Security,$GroupsOU"
'Role-Based','Resource','Privileged' |
    ForEach-Object { New-OUSafe -Name $_ -Path $SecOU }

Write-Host "`n[OK]  OU tree built.`n" -ForegroundColor Green

# ================================================================
# AGDLP groups
# Role-Based (Global) groups follow the pattern G_<Function>
# Resource    (Domain Local) groups follow DL_<Resource>_<Permission>
# Privileged  (Global)   groups: G_Helpdesk_T1, G_NetAdmins, G_CloudAdmins
# ================================================================

function New-GroupSafe {
    param(
        [string]$Name,
        [ValidateSet('Global','DomainLocal','Universal')]$Scope,
        [string]$Path,
        [string]$Description
    )
    if (-not (Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $Name -GroupScope $Scope -GroupCategory Security `
                    -Path $Path -Description $Description
        Write-Host "  + Group $Name ($Scope) created"
    } else {
        Write-Host "  = Group $Name already exists"
    }
}

$RolePath = "OU=Role-Based,$SecOU"
$ResPath  = "OU=Resource,$SecOU"
$PrivPath = "OU=Privileged,$SecOU"

# Role-based (Global) — by job function
$RoleGroups = @(
    @{N='G_Exec_Users';            D='Executive office staff'},
    @{N='G_FinanceHR_Users';       D='Finance and HR staff'},
    @{N='G_Sales_Users';           D='Sales and Marketing staff'},
    @{N='G_Network_Engineers';     D='Network engineering team'},
    @{N='G_Cloud_Admins';          D='Cloud and sysadmin team'},
    @{N='G_Helpdesk_T1';           D='Tier-1 helpdesk'},
    @{N='G_Helpdesk_T2';           D='Tier-2 helpdesk'},
    @{N='G_Office_Admin';          D='Front-office admin staff'},
    @{N='G_AllStaff';              D='All employees (umbrella)'}
)
$RoleGroups | ForEach-Object { New-GroupSafe -Name $_.N -Scope Global -Path $RolePath -Description $_.D }

# Resource (Domain Local) — by share and permission
$ResourceGroups = @(
    @{N='DL_Share_Finance_RW';     D='Modify on \\FS1\Finance'},
    @{N='DL_Share_Finance_R';      D='Read on   \\FS1\Finance'},
    @{N='DL_Share_HR_RW';          D='Modify on \\FS1\HR'},
    @{N='DL_Share_Sales_RW';       D='Modify on \\FS1\Sales'},
    @{N='DL_Share_Network_RW';     D='Modify on \\FS1\Network'},
    @{N='DL_Share_Public_RW';      D='Modify on \\FS1\Public'},
    @{N='DL_Share_Public_R';       D='Read on   \\FS1\Public'},
    @{N='DL_Print_AllPrinters';    D='Print to any QVIS printer'},
    @{N='DL_VPN_Allowed';          D='Permitted to dial VPN'}
)
$ResourceGroups | ForEach-Object { New-GroupSafe -Name $_.N -Scope DomainLocal -Path $ResPath -Description $_.D }

# Privileged (Global)
$PrivGroups = @(
    @{N='G_NetAdmins';   D='Full network device admin'},
    @{N='G_ServerAdmins';D='Local admin on member servers (via LAPS/restricted groups)'},
    @{N='G_WksAdmins';   D='Local admin on workstations'}
)
$PrivGroups | ForEach-Object { New-GroupSafe -Name $_.N -Scope Global -Path $PrivPath -Description $_.D }

# ---------- AGDLP nesting ---------------------------------------
Add-ADGroupMember -Identity DL_Share_Finance_RW  -Members G_FinanceHR_Users
Add-ADGroupMember -Identity DL_Share_HR_RW       -Members G_FinanceHR_Users
Add-ADGroupMember -Identity DL_Share_Sales_RW    -Members G_Sales_Users
Add-ADGroupMember -Identity DL_Share_Network_RW  -Members G_Network_Engineers, G_Cloud_Admins
Add-ADGroupMember -Identity DL_Share_Public_RW   -Members G_AllStaff
Add-ADGroupMember -Identity DL_Print_AllPrinters -Members G_AllStaff
Add-ADGroupMember -Identity DL_VPN_Allowed       -Members G_Network_Engineers, G_Cloud_Admins, G_Helpdesk_T2

# All role groups inherit "AllStaff"
'G_Exec_Users','G_FinanceHR_Users','G_Sales_Users','G_Network_Engineers',
'G_Cloud_Admins','G_Helpdesk_T1','G_Helpdesk_T2','G_Office_Admin' |
ForEach-Object { Add-ADGroupMember -Identity G_AllStaff -Members $_ }

Write-Host "`n[OK]  Groups and AGDLP nesting complete.`n" -ForegroundColor Green
