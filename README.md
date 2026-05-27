# QVIS Technology Solutions — End-to-End Small Business Network Build

**Portfolio project by Olumide Akomolafe**
*Network Support Technician — Conestoga College (Cambridge, Ontario)*


## What this project is

A complete, realistic small-business network designed and built from scratch for a fictional IT consultancy called **QVIS Technology Solutions**. The project covers everything a junior-to-intermediate network technician is expected to handle in a real first job:

- Multi-VLAN LAN design in Cisco Packet Tracer (ten VLANs, two access switches, one Layer 3 core, one edge router)
- Inter-VLAN routing on a Layer 3 core switch using SVIs
- Edge router with NAT overload, DHCP relay (`ip helper-address`), and ACL-based segmentation
- Active Directory Domain Services on Windows Server 2022 — two domain controllers, AGDLP group nesting, DHCP failover, DNS forward and reverse zones
- Function-first Organisational Unit tree designed for delegation and GPO targeting
- A screencast portfolio with shooting scripts and a clean read-aloud narration

Every design choice has a visible reason — nothing is over-engineered for marketing, and nothing is under-built for a real ten-to-twenty-person office.

---

## Why QVIS

QVIS Technology Solutions is a Kitchener-Waterloo-based managed services and cloud consulting firm. They are launching with **10 employees** and have a 12-month plan to scale to **20**. The office is a single floor with twelve distinct rooms ranging from a public reception area to a locked server room. That mix — small headcount, high security expectations from clients, and rapid growth — is exactly the situation in which a thoughtful junior network technician is most useful: there are no enterprise vendors holding your hand, but the design still has to scale, segment, and survive an audit.

---

## Repository layout

```
qvis-network-portfolio/
├── README.md                                  ← you are here
│
├── portfolio/                                 ← the written design
│   ├── QVIS_Portfolio.docx                    ← polished single-file write-up
│   ├── 01_company_overview.md                 ← company profile, staffing, rooms
│   ├── 02_network_design.md                   ← VLANs, IP plan, topology rationale
│   ├── 03_active_directory.md                 ← AD, OU tree, DHCP, DNS, GPO baseline
│   ├── 04_packet_tracer_build_guide.md        ← step-by-step .pkt construction
│   └── 05_troubleshooting_case_studies.md     ← 6 realistic incidents and fixes
│
├── diagrams/
│   ├── qvis_topology.svg                      ← labelled network topology (vector)
│   └── qvis_topology.png                      ← labelled network topology (image)
│
├── configs/
│   ├── cisco/                                 ← paste-into-Packet-Tracer IOS configs
│   │   ├── R1_edge_router.txt                 ← Cisco 2911 edge router (NAT, ACLs, SSH)
│   │   ├── CORE_SW1_L3.txt                    ← Cisco 3650 L3 core (SVIs, helper, east-west ACLs)
│   │   ├── ACC_SW1_access.txt                 ← Cisco 2960 north-wing access
│   │   └── ACC_SW2_access.txt                 ← Cisco 2960 south-wing access
│   │
│   └── windows/                               ← Windows Server 2022 build scripts
│       ├── ad-setup.ps1                       ← AD DS install + forest promotion
│       ├── ou-and-groups.ps1                  ← OU tree + AGDLP groups (idempotent)
│       ├── users-bulk-import.ps1              ← starting 10 users + growth to 20
│       ├── dhcp-scopes.ps1                    ← DHCP scopes per VLAN + failover
│       └── dns-zones.ps1                      ← forward, reverse, forwarders, scavenging
│
└── video/                                     ← four-part screencast portfolio
    ├── README.md                              ← video series overview
    ├── START_HERE.md                          ← end-to-end recording walkthrough
    ├── 00_production_guide.md                 ← OBS, microphone, lighting setup
    ├── 01_episode_1_overview.md               ← shooting script for Ep. 1
    ├── 02_episode_2_network.md                ← shooting script for Ep. 2 (clean build)
    ├── 03_episode_3_identity.md               ← shooting script for Ep. 3
    ├── 04_episode_4_troubleshooting.md        ← shooting script for Ep. 4
    ├── 05_publishing_kit.md                   ← thumbnails, titles, descriptions
    ├── NARRATION_COMPILATION.md               ← full clean read-aloud script (~3,500 words)
    ├── QVIS_Video_Portfolio_Production_Pack.docx
    └── QVIS_Video_Portfolio_Deck_v2.pptx      ← slide deck used in Episodes 1, 3, 4
```

---

## How to read this portfolio

If you have **5 minutes**, open [`portfolio/QVIS_Portfolio.docx`](./portfolio/QVIS_Portfolio.docx) and skim the executive summary, the topology diagram, and the troubleshooting case studies. That tells you whether the candidate can think.

If you have **30 minutes**, walk the markdown files in [`portfolio/`](./portfolio) in order (01 → 05) and open the configs in [`configs/`](./configs) alongside. That tells you whether the candidate can build.

If you have **a lab session**, follow [`portfolio/04_packet_tracer_build_guide.md`](./portfolio/04_packet_tracer_build_guide.md) and recreate the topology yourself. The configs in `configs/cisco/` paste in directly; every command has been written to work in Packet Tracer 8.x.

If you'd like to **hear it spoken**, the video portfolio under [`video/`](./video) has the four episode scripts and a clean, read-aloud narration compilation. The screencast itself is on YouTube — see the link in my CV.

---

## Skills demonstrated

**Networking** — VLSM subnetting, VLAN design, 802.1Q trunking with explicit native-VLAN hardening, inter-VLAN routing on a Layer 3 switch (SVIs), DHCP relay (`ip helper-address`), NAT overload, named extended ACLs for east-west traffic control, SSH and AAA hardening, port-security on access edge, BPDU Guard, spanning-tree root pinning.

**Windows Server** — AD DS forest install, OU design following the *function-then-location* pattern, AGDLP group nesting, DHCP failover in hot-standby mode, DNS forward and reverse zones, conditional forwarders with root hints disabled (fail closed), scavenging and aging, baseline GPOs (password policy, screen lock, BitLocker, USB block on Finance/HR, mapped drives, training-lab lockdown).

**Troubleshooting** — structured OSI-stack triage, `err-disabled` recovery, ACL sequence-number debugging, DHCP-option / ACL alignment for split-DNS scenarios, root-cause writeups with runbook prevention. Three of these cases are walked through in Episode 4 of the video portfolio.

**Documentation and communication** — every design decision in this repo has a written rationale; the video portfolio adds spoken narration at ~140 words per minute for ~25 minutes total.

---

## Lab vs. simulation note

Conestoga's curriculum exposes students to Cisco 2811 routers, Juniper EX4100 L3 switches, and Palo Alto next-generation firewalls. **Palo Alto is referenced here as part of my training background; I have not used it in this build because I do not currently have access to a Palo Alto lab environment.** This portfolio is delivered entirely in **Cisco Packet Tracer 8.x** with devices Packet Tracer supports (Cisco 2911 router, Cisco 3650 L3 switch, Cisco 2960 access switches), so anyone with a laptop can reproduce it. One Packet-Tracer-specific caveat — the `log` keyword on ACL deny lines — has been stripped from every config with a header note explaining how to restore it on real IOS.

---

## Companion project

For a separate AWS cloud architecture portfolio piece (Lagos State Motor Vehicle Administration Agency / QVIS Quick Vehicle Insurance System), see the [**qvis-aws-portfolio**](https://github.com/) repository.

---

## Contact

**Olumide Akomolafe**
Cambridge, Ontario · Network Support Technician
Open to Tier-1 and Tier-2 Network Support roles in Ontario.

(Contact details in the cover slide of the video portfolio and on my CV.)

