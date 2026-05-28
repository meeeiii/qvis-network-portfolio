# 03 — Active Directory, DHCP, DNS and Baseline GPOs

## 3.1 Identity strategy

| Decision | Choice | Why |
|---|---|---|
| Forest design | Single forest, single domain `qvis.local` | 20 users does not justify multi-domain or multi-forest |
| Domain controllers | 2 × DC (DC1 primary, DC2 secondary) | Redundancy; DC2 also runs NPS for Wi-Fi RADIUS |
| FSMO placement | All 5 roles on DC1; DC2 ready to seize | Documented runbook for seizure; not exercised at launch |
| Functional level | Windows Server 2016 forest + domain functional level (running on 2022 servers) | Future-proof, supports modern features without breaking older client tooling |
| Naming | UPN suffix `@qvis.local` internal; external email `@qvistech.ca` | UPN matches mail address pattern for user convenience |
| Time | DC1 PDC emulator points to `time.nist.gov`; everyone else syncs to PDCe | Domain time hygiene = working Kerberos |

## 3.2 OU design — function first, then sub-function

I follow the well-established **function-then-sub-function** pattern, not a per-department pattern. The reasons:

1. **GPO targeting is cleaner.** A "Lock screen after 10 minutes" GPO applies to all `Users`. A "USB storage blocked" GPO applies only to `Users/Finance-HR` and `Users/Executive`. Department-shaped OUs would force GPO duplication.
2. **Delegation is cleaner.** The Tier-1 helpdesk gets "reset password + unlock account" rights on `OU=Users`. The Senior Network Engineer gets "create/delete computer" rights on `OU=Computers`. Neither needs domain-admin.
3. **Computers can move with users.** When the CFO swaps laptops, the user object stays put; only the computer object moves to a different sub-OU under `Computers`.
4. **Disabled-account holding pen** lives at the top of the tree, not inside each department. Easier to find, easier to retain for compliance.

```
qvis.local
└── OU = QVIS
    ├── OU = _Disabled                       ← offboarded users and decommissioned computers
    ├── OU = ServiceAccounts                 ← gMSA + traditional service accounts
    ├── OU = Users
    │   ├── OU = Executive
    │   ├── OU = Finance-HR
    │   ├── OU = Sales-Marketing
    │   ├── OU = Technical
    │   │   ├── OU = Network
    │   │   └── OU = Cloud-Sysadmin
    │   └── OU = Support-Admin
    ├── OU = Computers
    │   ├── OU = Workstations
    │   │   ├── OU = Executive
    │   │   ├── OU = Finance-HR
    │   │   ├── OU = Sales-Marketing
    │   │   ├── OU = Technical
    │   │   └── OU = Support-Admin
    │   ├── OU = Laptops
    │   └── OU = Servers
    │       ├── OU = FileServers
    │       └── OU = Application
    └── OU = Groups
        ├── OU = Security
        │   ├── OU = Role-Based               ← per-department "G_Finance_Users" etc.
        │   ├── OU = Resource                 ← per-share "DL_Share_Finance_RW"
        │   └── OU = Privileged               ← "G_Helpdesk_T1", "G_NetAdmins"
        └── OU = Distribution
```

> The default `Domain Controllers` OU is kept where AD places it; **do not** move DCs.

### Group nesting — AGDLP

| Layer | Example | Purpose |
|---|---|---|
| **A**ccount | `tunde.olumide` | The user |
| **G**lobal | `G_Network_Engineers` | Role / job function |
| **D**omain **L**ocal | `DL_Share_NetworkDocs_RW` | Tied to a single resource |
| **P**ermission | NTFS ACL on `\\FS1\NetworkDocs` | The actual ACL entry |

So `tunde.olumide` → member of → `G_Network_Engineers` → member of → `DL_Share_NetworkDocs_RW` → granted Modify on the share. No user is ever ACL'd directly; no Global group is ever ACL'd directly.

## 3.3 DHCP

| Setting | Value |
|---|---|
| Primary DHCP | DC1 (10.10.20.10) |
| Failover partner | DC2 (10.10.20.11) — **hot standby** mode, 5% reserve, 1 hour MCLT |
| Relay | `ip helper-address` on each user SVI on CORE-SW1 (already in switch config) |
| Lease duration | 8 days for fixed VLANs, 4 hours for GUEST and LAB |
| Authoritative | Yes (in DHCP console) |

### Scopes

| Scope name | Network | Start | End | Exclusions | Options |
|---|---|---|---|---|---|
| QVIS-MGMT | 10.10.10.0/24 | .20 | .199 | .1–.19, .200–.254 | 003 router=.1, 006 DNS=DC1/DC2, 015 domain=qvis.local |
| QVIS-EXEC-FIN | 10.10.30.0/24 | .20 | .199 | .1–.19, .200–.254 | same shape, router=10.10.30.1 |
| QVIS-STAFF | 10.10.40.0/24 | .20 | .199 | .1–.19 | router=10.10.40.1 |
| QVIS-TECH | 10.10.50.0/24 | .20 | .199 | .1–.19 | router=10.10.50.1 |
| QVIS-LAB | 10.10.60.0/24 | .50 | .150 | .1–.49 | router=10.10.60.1, 4-hour lease |
| QVIS-VOICE | 10.10.70.0/24 | .20 | .199 | .1–.19 | router=10.10.70.1, 150 TFTP for phones |
| QVIS-PRINT | 10.10.80.0/24 | .20 | .49 | .1–.19, .50–.254 | reservations only for production; small dynamic pool for new printers |
| QVIS-GUEST | 10.10.90.0/24 | .20 | .254 | .1–.19 | router=10.10.90.1, DNS=1.1.1.1/1.0.0.1, 4-hour lease |

### Reservations

DHCP reservations rather than pure-static IPs for any device that should not move address but should still be central to manage:
- All three printers
- The two MFPs at reception and Finance/HR
- The conference room AV controller
- The wireless APs

The `dhcp-scopes.ps1` script in `/configs` creates every scope and reservation in one pass.

## 3.4 DNS

### Zones

| Zone | Type | Notes |
|---|---|---|
| qvis.local | AD-integrated primary, secure dynamic update only | Domain DNS |
| 10.10.in-addr.arpa | AD-integrated reverse | One reverse zone covers all internal /24s |
| qvistech.ca | NOT hosted on DC | External DNS at registrar — split-DNS not used at this stage |

### Forwarders
- 1.1.1.1 (Cloudflare)
- 9.9.9.9 (Quad9 — filters known-malicious)

Root hints disabled — forwarders only, fail closed.

### Hygiene
- Scavenging enabled on the qvis.local zone (no-refresh 7 days, refresh 7 days)
- Aging applied to existing records on first run

## 3.5 Baseline GPOs

| GPO name | Linked to | Effect |
|---|---|---|
| GPO_Baseline_AllUsers | OU=Users | Password policy (12 char, complexity, 90-day max), screen lock 10 min, account lockout 5/15 min |
| GPO_Baseline_AllComputers | OU=Computers | Windows Update WSUS pointer (or Windows Update for Business), Firewall on for all profiles, BitLocker required, SmartScreen on |
| GPO_FinanceHR_USB_Block | OU=Users/Finance-HR + OU=Users/Executive | Removable storage write denied, read denied for USBSTOR |
| GPO_Mapped_Drives | OU=Users | M: → `\\FS1\Shared`, U: → `\\FS1\Users\%username%`, plus per-department drives via item-level targeting |
| GPO_Helpdesk_LocalAdmin | OU=Computers/Workstations | LAPS deployed; `G_Helpdesk_T1` added to local Administrators via restricted groups |
| GPO_Lab_Lockdown | OU=Computers (lab machines targeted via WMI filter) | No corporate mapped drives, lab-specific wallpaper, auto-logoff at 6pm |

## 3.6 Starting user list (phase 1)

| Display name | sAMAccountName | UPN | OU | Primary group |
|---|---|---|---|---|
| Adaeze Okafor | adaeze.okafor | adaeze.okafor@qvis.local | Users/Executive | G_Exec_Users |
| Marcus Lee | marcus.lee | marcus.lee@qvis.local | Users/Executive | G_Exec_Users |
| Priya Sharma | priya.sharma | priya.sharma@qvis.local | Users/Finance-HR | G_FinanceHR_Users |
| Daniel Chen | daniel.chen | daniel.chen@qvis.local | Users/Technical/Network | G_Network_Engineers |
| Olumide Tunde | olumide.tunde | olumide.tunde@qvis.local | Users/Technical/Network | G_Network_Engineers |
| Aisha Mohamed | aisha.mohamed | aisha.mohamed@qvis.local | Users/Technical/Cloud-Sysadmin | G_Cloud_Admins |
| Jordan Reyes | jordan.reyes | jordan.reyes@qvis.local | Users/Support-Admin | G_Helpdesk_T1 |
| Sofia Almeida | sofia.almeida | sofia.almeida@qvis.local | Users/Sales-Marketing | G_Sales_Users |
| Liam O'Connor | liam.oconnor | liam.oconnor@qvis.local | Users/Sales-Marketing | G_Sales_Users |
| Emma Taylor | emma.taylor | emma.taylor@qvis.local | Users/Support-Admin | G_Office_Admin |

The `users-bulk-import.ps1` script provisions all ten and also has commented-out blocks for the next ten hires.
