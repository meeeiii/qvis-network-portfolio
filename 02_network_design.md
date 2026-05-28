# 02 — Network Design

## 2.1 Design goals

| Goal | How it is met |
|---|---|
| Segment by sensitivity, not by department label | EXEC-FIN VLAN groups everyone with restricted data; STAFF and TECH separated; LAB fully isolated |
| Survive doubling of headcount without re-IP | Every user VLAN sized as /24 (254 usable hosts) — fits 20 employees with 10× headroom |
| Inter-VLAN routing performed in hardware | Cisco 3650 L3 core switch with SVIs, not on a router-on-a-stick |
| One single point to enforce east-west policy | Named extended ACLs applied **inbound** on each L3 SVI |
| Internet edge isolated and replaceable | Cisco 2911 edge router only handles default route, NAT overload, and a single inbound management ACL |
| No flat Wi-Fi | Three SSIDs (Corp, Guest, Lab) map to three different VLANs via 802.1Q-tagged trunk to the AP |

## 2.2 Device inventory

| Role | Model (Packet Tracer) | Production substitute (Conestoga lab) | Hostname |
|---|---|---|---|
| Edge router | Cisco 2911 ISR | Cisco 2811 ISR | R1 |
| Core L3 switch | Cisco 3650-24PS | Juniper EX4100 | CORE-SW1 |
| Access switch — north wing | Cisco 2960-24TT | Juniper EX4100 | ACC-SW1 |
| Access switch — south wing | Cisco 2960-24TT | Juniper EX4100 | ACC-SW2 |
| Wireless AP × 3 (lobby, bullpen, lab) | Cisco AP-PT | Real AP w/ controller | AP1/AP2/AP3 |
| Domain Controller 1 | Server-PT running Win Server 2022 | Real Win Server | DC1 |
| Domain Controller 2 | Server-PT running Win Server 2022 | Real Win Server | DC2 |
| File server | Server-PT | Real Win Server | FS1 |
| Print server / printers | Printer-PT × 3 | HP LaserJet MFP | PRN1/2/3 |

> The Juniper EX4100 column reflects gear I have hands-on time with in the Conestoga lab and would substitute the Cisco 3650/2960 line for in a production-equivalent build; translating these IOS configs to Junos is a planned next-iteration appendix. **Palo Alto firewalls are part of the Conestoga curriculum and remain a known-skill on my resume, but I do not have access to a Palo Alto lab outside the school environment, so they are not used in this implementation** — the firewall function in this build lives on the Cisco 2911 edge router and the ACLs on the L3 core.

## 2.3 VLAN plan

| VLAN ID | Name | Subnet | Gateway (SVI on CORE-SW1) | Purpose | Hosts at launch | Hosts at 20-employee target |
|---|---|---|---|---|---|---|
| 10 | MGMT | 10.10.10.0/24 | 10.10.10.1 | In-band management of switches, AP, iDRAC, UPS | ~8 | ~12 |
| 20 | SERVERS | 10.10.20.0/24 | 10.10.20.1 | DC1, DC2, FS1, future app servers | 4 | ~8 |
| 30 | EXEC-FIN | 10.10.30.0/24 | 10.10.30.1 | Executive + Finance + HR workstations | 3 | 6 |
| 40 | STAFF | 10.10.40.0/24 | 10.10.40.1 | Sales, Marketing, Admin | 3 | 6 |
| 50 | TECH | 10.10.50.0/24 | 10.10.50.1 | IT / Network / Cloud / Support | 4 | 8 |
| 60 | LAB | 10.10.60.0/24 | 10.10.60.1 | Training Lab — isolated from corp | up to 8 | up to 8 |
| 70 | VOICE | 10.10.70.0/24 | 10.10.70.1 | IP phones (auxiliary VLAN on access ports) | ~10 | ~20 |
| 80 | PRINT | 10.10.80.0/24 | 10.10.80.1 | Printers, MFPs, badge scanners | 3 | 5 |
| 90 | GUEST | 10.10.90.0/24 | 10.10.90.1 | Guest Wi-Fi — internet only, no LAN reachability | dynamic | dynamic |
| 99 | BLACKHOLE / NATIVE | n/a | n/a | Unused VLAN set as the trunk native, all access ports default to here when wiped | — | — |

### Native VLAN security

VLAN 99 is configured as the **native VLAN on every 802.1Q trunk**, has no SVI, and no access port is assigned to it. This neutralises the classic double-tag VLAN-hopping attack and ensures that any unconfigured/wiped port becomes inert rather than landing on VLAN 1.

### Voice VLAN

Phones use VLAN 70 as their **auxiliary** VLAN. Workstations connect *through* the phone, so a single cable to the desk carries:
- the workstation traffic untagged on the access VLAN of the port (STAFF/EXEC-FIN/TECH),
- the phone traffic tagged on VLAN 70.

Configured per access port with `switchport voice vlan 70`.

## 2.4 IP plan

### WAN edge
- ISP-supplied public IP (placeholder `203.0.113.2/30`) on `R1 Gi0/0`
- Default route: `ip route 0.0.0.0 0.0.0.0 203.0.113.1`
- NAT overload (PAT) on Gi0/0 outbound for all inside subnets

### Inside transit
- R1 ↔ CORE-SW1 over a routed `/30` point-to-point — `10.10.0.0/30`
  - `R1 Gi0/1`: 10.10.0.1
  - `CORE-SW1` routed port (Gi1/0/24): 10.10.0.2

### Reserved within each VLAN
For every user VLAN (10/20/30/40/50/60/70/80):

| Range | Use |
|---|---|
| `.1` | Gateway (SVI on CORE-SW1) |
| `.2 – .9` | Static infrastructure (DHCP relay targets, AP, secondary GW if any) |
| `.10 – .19` | Servers and printers in that VLAN (reservations) |
| `.20 – .199` | DHCP pool |
| `.200 – .254` | Reserved for future static or growth |

### Critical static assignments

| Host | VLAN | Address |
|---|---|---|
| DC1 (AD + DNS + DHCP primary) | 20 SERVERS | 10.10.20.10 |
| DC2 (AD + DNS + DHCP failover) | 20 SERVERS | 10.10.20.11 |
| FS1 (file server) | 20 SERVERS | 10.10.20.12 |
| PRN1 (north wing MFP) | 80 PRINT | 10.10.80.10 |
| PRN2 (south wing MFP) | 80 PRINT | 10.10.80.11 |
| PRN3 (Finance/HR MFP) | 80 PRINT | 10.10.80.12 |
| CORE-SW1 management | 10 MGMT | 10.10.10.1 (loopback SVI) |
| ACC-SW1 | 10 MGMT | 10.10.10.2 |
| ACC-SW2 | 10 MGMT | 10.10.10.3 |
| AP1/AP2/AP3 | 10 MGMT | 10.10.10.4–6 |

## 2.5 Logical topology

```
                          INTERNET
                              |
                       [ R1  Cisco 2911 ]
                       Gi0/0  203.0.113.2/30
                       Gi0/1  10.10.0.1/30   (routed)
                              |
                       trunk + routed P2P
                              |
                      [ CORE-SW1  Cisco 3650 L3 ]
                       Gi1/0/24 routed: 10.10.0.2/30
                       SVIs: 10/20/30/40/50/60/70/80/90 = .1 each
                       /                    \
                      /                      \
                trunk Gi1/0/1            trunk Gi1/0/2
                802.1Q                    802.1Q
               /                              \
   [ ACC-SW1  Cisco 2960 ]            [ ACC-SW2  Cisco 2960 ]
   North wing edge                     South wing edge
   R1, R2, R3, R4, R8, R9, R11         R5, R6, R10, R12
   AP1 (lobby), AP2 (bullpen)          AP3 (lab)

   [ SERVER ROOM R7 — connected directly to CORE-SW1 on access ports in VLAN 20 ]
   DC1   10.10.20.10
   DC2   10.10.20.11
   FS1   10.10.20.12
```

A labeled SVG version of the topology lives at `diagrams/qvis_topology.svg` and is embedded in the Word doc.

## 2.6 East-west policy (named extended ACLs)

Applied **inbound on each VLAN's SVI** at CORE-SW1. The principle: deny by exception, permit the rest, end with explicit log to capture surprises.

| From → To | EXEC-FIN | STAFF | TECH | LAB | SERVERS | PRINT | GUEST | INTERNET |
|---|---|---|---|---|---|---|---|---|
| **EXEC-FIN** | ✓ | ✗ | ✗ | ✗ | ✓ AD/SMB/print | ✓ | ✗ | ✓ |
| **STAFF** | ✗ | ✓ | ✗ | ✗ | ✓ AD/SMB/print | ✓ | ✗ | ✓ |
| **TECH** | ✓ mgmt | ✓ mgmt | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| **LAB** | ✗ | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✓ |
| **GUEST** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |

Key design points:

- **TECH can reach everywhere** because the IT team has to support every other VLAN. That power is balanced by tight admin logging and the requirement that domain admin accounts be separate from daily-driver accounts.
- **LAB is one-way isolated**: it can reach the internet for software downloads during training but nothing on the corporate LAN can reach in, and nothing in the lab can reach corp.
- **GUEST** drops onto a single ACL line — `permit ip any 203.0.113.0 0.0.0.255` after a `deny ip any 10.10.0.0 0.0.255.255`. Anything that is not the public ISP next-hop is dropped.

The actual ACL syntax lives in `configs/CORE_SW1_L3.txt` under the heading **East-West Policy ACLs**.

## 2.7 Wireless

| SSID | VLAN | Auth | Notes |
|---|---|---|---|
| QVIS-Corp | 50 TECH (depending on AP location, AP4/5 push 40/30 via WPA2-Enterprise dynamic VLAN; in Packet Tracer simulated as static-per-AP) | WPA3-Enterprise via RADIUS on DC2 (NPS) | Domain-joined laptops only |
| QVIS-Guest | 90 GUEST | WPA2 with rotating PSK held at reception | Captive portal not implemented in Packet Tracer; documented in production-next-iteration appendix |
| QVIS-Lab | 60 LAB | WPA2-PSK, rotated per training cohort | Only broadcast inside R10 |

In a real deployment WPA3-Enterprise with dynamic VLAN assignment is the right answer; in Packet Tracer we pin each AP to one VLAN to keep the simulation tractable.

## 2.8 Resilience choices that fit a 10-person office

I deliberately did **not** add features that look professional on a slide deck but cost money the business will not spend at this stage. For each, the reason and the trigger that would flip the decision:

| Feature | Decision | Why | Trigger to add later |
|---|---|---|---|
| Stacking on access switches | Not at launch | Two 2960s = two cables, not worth the stack module | When access switch count exceeds 4 |
| HSRP / VRRP on the core | Not at launch | Single L3 switch is acceptable for a 10-person office; the real SPOF is the router | Adding a second 3650 |
| Redundant ISP | Not at launch | Cost-prohibitive; QVIS uses cellular failover stick on R1 as cheap backup | Reaching ~30 employees or any 24/7 service obligation |
| Spanning Tree tuning | Yes — Rapid PVST+ with CORE-SW1 explicitly set as root for all VLANs | Default STP root election by lowest MAC is a footgun; you should always pin the root | n/a |
| BPDU Guard / Root Guard on access ports | Yes | Every access port has `spanning-tree portfast` + `spanning-tree bpduguard enable`, edge → core trunks have `spanning-tree guard root` | n/a |
| Port-security on access ports | Yes — sticky MAC, max 2 (phone + PC), violation shutdown | Stops random devices being plugged in | n/a |
