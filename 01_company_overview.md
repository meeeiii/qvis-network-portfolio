# 01 — Company, Staffing and Office Layout

## 1.1 Company profile

| Field | Value |
|---|---|
| Legal name | QVIS Technology Solutions Inc. |
| Public-facing domain | qvistech.ca |
| Internal AD domain | qvis.local |
| Location | Kitchener-Waterloo, ON, Canada |
| Industry | Managed IT services, cloud migration, small-business cybersecurity |
| Clients | ~40 SMB clients across legal, dental, accounting, and manufacturing |
| Stage | Launch + 12 months. Headcount 10 today, target 20 within a year. |
| Compliance pressure | PIPEDA, client SOC 2 expectations (handles client data), some PHIPA-adjacent dental work |

The compliance pressure is what justifies things that would otherwise look heavy for a 10-person office — separate VLANs for Finance/HR, ACL-based east-west restriction, USB lockdown on the restricted VLAN, DHCP and DNS logging.

---

## 1.2 Staffing — phase 1 (10 employees at launch)

| # | Role | Department | VLAN | OU |
|---|---|---|---|---|
| 1 | Managing Director / CEO | Executive | EXEC-FIN (30) | Users/Executive |
| 2 | Operations Manager | Executive | EXEC-FIN (30) | Users/Executive |
| 3 | Finance & HR Manager | Finance-HR | EXEC-FIN (30) | Users/Finance-HR |
| 4 | Senior Network Engineer | Technical | TECH (50) | Users/Technical/Network |
| 5 | **Network Technician** (you) | Technical | TECH (50) | Users/Technical/Network |
| 6 | Senior Cloud / Sysadmin | Technical | TECH (50) | Users/Technical/Cloud-Sysadmin |
| 7 | Helpdesk / Tier-1 Support | Support | TECH (50) | Users/Support-Admin |
| 8 | Sales Lead | Sales-Marketing | STAFF (40) | Users/Sales-Marketing |
| 9 | Sales Representative | Sales-Marketing | STAFF (40) | Users/Sales-Marketing |
| 10 | Office Administrator / Receptionist | Support-Admin | STAFF (40) | Users/Support-Admin |

## 1.3 Staffing — phase 2 (scaling to 20)

The next ten hires are scheduled across the 12-month growth plan. Adding them does not require a re-IP or re-VLAN — each user VLAN was sized for at least 40 hosts so doubling headcount is absorbed without scope edits.

| # | Role | Department | VLAN | OU |
|---|---|---|---|---|
| 11 | CFO | Executive | EXEC-FIN (30) | Users/Executive |
| 12 | HR Coordinator | Finance-HR | EXEC-FIN (30) | Users/Finance-HR |
| 13 | Marketing Specialist | Sales-Marketing | STAFF (40) | Users/Sales-Marketing |
| 14 | Sales Representative | Sales-Marketing | STAFF (40) | Users/Sales-Marketing |
| 15 | Sales Representative | Sales-Marketing | STAFF (40) | Users/Sales-Marketing |
| 16 | Project Manager | Technical | TECH (50) | Users/Technical |
| 17 | Cybersecurity Analyst | Technical | TECH (50) | Users/Technical/Network |
| 18 | Junior Cloud Engineer | Technical | TECH (50) | Users/Technical/Cloud-Sysadmin |
| 19 | Helpdesk / Tier-2 Support | Support | TECH (50) | Users/Support-Admin |
| 20 | Helpdesk / Tier-1 Support | Support | TECH (50) | Users/Support-Admin |

---

## 1.4 Office floor plan — twelve rooms

The office is a single floor, roughly rectangular. The server room sits at the geographic centre of the floor so that horizontal copper runs to the furthest desk stay under the 90-metre TIA-568 limit. The plan is divided into a **north wing** (front-of-house / staff) and a **south wing** (back-of-house / technical) — each wing is served by its own access switch.

| Room | Wing | Purpose | Occupants | Network drops | Wireless coverage |
|---|---|---|---|---|---|
| R1 Reception / Lobby | North | Public-facing entrance, visitor seating | Receptionist, 0–4 visitors | 2× data, 1× VoIP | Guest SSID only |
| R2 Executive Office | North | Closed-door office for CEO + Ops Mgr | 2 people | 4× data, 2× VoIP | Corp + Guest |
| R3 Finance / HR Office | North | Closed-door office, restricted entry | Finance/HR Mgr, CFO, HR Coord | 4× data, 2× VoIP, locked rack-mounted shredder bin | Corp only |
| R4 Open Workspace (Sales bullpen) | North | Sales and admin bullpen | Sales Lead, 3× Sales Reps, Marketing, Office Admin | 12× data, 6× VoIP | Corp + Guest |
| R5 Engineering / Tech Workstations | South | Permanent desks for tech team | Sr. Net Eng, Sr. Cloud, Net Tech, Jr. Cloud, Cyber Analyst, PM | 10× data, 4× VoIP | Corp |
| R6 NOC (Network Ops Centre) | South | Wall of monitors, on-call station | Tech team shares; 2 dedicated stations | 4× data, 2× VoIP, KVM | Corp |
| R7 Server Room / MDF | Centre | Locked, climate-controlled, badge entry | None (visited only) | Fibre + copper trunks to both wings | None |
| R8 Large Conference Room | North | Client meetings, all-hands | Up to 14 | 4× data, 1× VoIP, AV controller | Corp + Guest |
| R9 Small Huddle Room | North | 1:1s, interviews | Up to 4 | 2× data, 1× VoIP | Corp + Guest |
| R10 Training Lab | South | Client training, internal Packet Tracer / lab benches | Up to 8 trainees | 10× data, isolated VLAN | LAB SSID only |
| R11 Break Room / Kitchen | North | Kitchen, eating area | Anyone | 2× data (smart fridge / TV) | Guest |
| R12 Storage / Receiving | South | Spare hardware, shipping | None | 1× data (asset scanner) | None |

### Why this matters for the network design

- **R3 Finance/HR** is the only set of users that lives in the EXEC-FIN VLAN alongside the Executive office. Putting them physically adjacent (both in the north wing) keeps cabling clean *and* lets us run a single restrictive ACL covering both.
- **R7 Server Room** sits in the middle of the floor — fibre uplinks from each wing's access switch terminate at the core switch here, and the same room houses the two domain controllers, the file server, and the UPS. Badge access is restricted to the Technical OU's "Server Room Access" security group.
- **R10 Training Lab** has its own VLAN (LAB) and its own SSID. Anything that happens in the lab — including a misbehaving demo router or a client trainee plugging in their laptop — cannot touch production. This is non-negotiable for any company that runs client-facing training.
- **R6 NOC** sits next to **R7 Server Room** so that an on-call engineer can walk into the rack within seconds during an incident.
