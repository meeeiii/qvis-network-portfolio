# QVIS Technology Solutions — End-to-End Small Business Network Build

**A portfolio project by Olumide Akomolafe**
*Network Support Technician — Conestoga College (Cambridge, Ontario)*

---

## What I'm demonstrating here

I designed and built a complete, realistic small-business network from scratch for a fictional IT consultancy I call **QVIS Technology Solutions**. In this repository I'll be showing you everything a junior-to-intermediate network technician is expected to handle in a real first job:

- I designed a multi-VLAN LAN in Cisco Packet Tracer — ten VLANs, two access switches, one Layer 3 core, one edge router.
- I configured inter-VLAN routing on the Layer 3 core using SVIs.
- I set up the edge router with NAT overload, DHCP relay (`ip helper-address`), and ACL-based segmentation.
- I deployed Active Directory Domain Services on Windows Server 2022 — two domain controllers, AGDLP group nesting, DHCP failover, DNS forward and reverse zones.
- I built the Organisational Unit tree function-first, so it's designed for delegation and clean GPO targeting.
- I produced a four-part screencast portfolio with shooting scripts and a clean read-aloud narration.

Every design choice I made has a visible reason — I didn't over-engineer anything for marketing, and I didn't under-build anything that a real ten-to-twenty-person office would actually need.

---

## Why I chose QVIS as the scenario

QVIS Technology Solutions is a Kitchener-Waterloo-based managed services and cloud consulting firm. I picked the scenario carefully — they're launching with **10 employees** and have a 12-month plan to scale to **20**. The office is a single floor with twelve distinct rooms ranging from a public reception area to a locked server room. That mix — small headcount, high security expectations from clients, and rapid growth — is exactly the situation in which I think a thoughtful junior network technician is most useful. There are no enterprise vendors holding my hand, but my design still has to scale, segment, and survive an audit. That's the bar I held myself to.

---


## Repository layout

```
qvis-network-portfolio/
├── README.md                                  ← you are here
│
├── portfolio/                                 ← my written design
│   ├── QVIS_Portfolio.docx                    ← my polished single-file write-up
│   ├── 01_company_overview.md                 ← company profile, staffing, rooms
│   ├── 02_network_design.md                   ← VLANs, IP plan, topology rationale
│   ├── 03_active_directory.md                 ← AD, OU tree, DHCP, DNS, GPO baseline
│   ├── 04_packet_tracer_build_guide.md        ← my step-by-step .pkt construction
│   └── 05_troubleshooting_case_studies.md     ← 6 realistic incidents I worked through
│
├── diagrams/
│   ├── qvis_topology.svg                      ← my labelled network topology (vector)
│   └── qvis_topology.png                      ← my labelled network topology (image)
│
├── configs/
│   ├── cisco/                                 ← my paste-into-Packet-Tracer IOS configs
│   │   ├── R1_edge_router.txt                 ← Cisco 2911 edge router (NAT, ACLs, SSH)
│   │   ├── CORE_SW1_L3.txt                    ← Cisco 3650 L3 core (SVIs, helper, east-west ACLs)
│   │   ├── ACC_SW1_access.txt                 ← Cisco 2960 north-wing access
│   │   └── ACC_SW2_access.txt                 ← Cisco 2960 south-wing access
│   │
│   └── windows/                               ← my Windows Server 2022 build scripts
│       ├── ad-setup.ps1                       ← AD DS install + forest promotion
│       ├── ou-and-groups.ps1                  ← OU tree + AGDLP groups (idempotent)
│       ├── users-bulk-import.ps1              ← starting 10 users + growth to 20
│       ├── dhcp-scopes.ps1                    ← DHCP scopes per VLAN + failover
│       └── dns-zones.ps1                      ← forward, reverse, forwarders, scavenging
│
└── video/                                     ← my four-part screencast portfolio
    ├── README.md                              ← video series overview
    ├── START_HERE.md                          ← end-to-end recording walkthrough
     ├── QVIS_Video
    └── QVIS_Video_Portfolio_Deck_v2.pptx      ← the slide deck I used 
```
## Skills demonstrated

**Networking** — I'm showing VLSM subnetting, VLAN design, 802.1Q trunking with explicit native-VLAN hardening, inter-VLAN routing on a Layer 3 switch (SVIs), DHCP relay (`ip helper-address`), NAT overload, named extended ACLs for east-west traffic control, SSH and AAA hardening, port-security on the access edge, BPDU Guard, and spanning-tree root pinning.

**Windows Server** — I'm demonstrating AD DS forest install, OU design following the *function-then-location* pattern, AGDLP group nesting, DHCP failover in hot-standby mode, DNS forward and reverse zones, conditional forwarders with root hints disabled (fail closed), scavenging and aging, and a baseline GPO set (password policy, screen lock, BitLocker, USB block on Finance/HR, mapped drives, training-lab lockdown).

**Troubleshooting** — I walk through structured OSI-stack triage, `err-disabled` recovery, ACL sequence-number debugging, and DHCP-option / ACL alignment for split-DNS scenarios. Each case study includes my root-cause writeup and the runbook change I'd make to prevent it recurring. I narrate three of these cases in Episode 4 of my video portfolio.

**Documentation and communication** — Every design decision I made in this repo has a written rationale. My video portfolio adds spoken narration at ~140 words per minute for ~25 minutes total.

---
