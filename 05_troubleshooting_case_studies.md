# 05 — Troubleshooting Case Studies

Six real-shaped incidents I have either built into a lab and resolved, or that arrive in this exact form on a Tier-1 / Tier-2 ticket queue. Every case follows the same structure:

1. **Symptom** — what the user reports
2. **Triage questions** — what I ask before I touch anything
3. **Diagnostic plan** — OSI-shaped, cheapest checks first
4. **Root cause**
5. **Fix** — exact commands or clicks
6. **Prevention** — what stops this recurring

---

## Case 1 — "The new sales rep's PC has no network"

### Symptom
Liam, a newly hired Sales Rep, is plugged into a desk in R4 (Sales bullpen). His PC has a "No Internet" tray icon. The phone on the same cable is also dead.

### Triage questions
- Which physical port on the wall plate?
- Has the cable been re-routed recently? (Did anyone unplug something this morning?)
- Same desk previously working for someone else?

### Diagnostic plan
| Layer | Check | Tool |
|---|---|---|
| L1 | Link light on switch port and on NIC | Eyes / `show interfaces status` |
| L2 | Is the port up/up? VLAN as expected? | `show interfaces Fa0/N status` |
| L2 | Is the port in err-disable? | `show interfaces status err-disabled` |
| L3 | DHCP lease? Default gateway reachable? | `ipconfig /all`, `ping 10.10.40.1` |

### Root cause
`show interfaces status err-disabled` returns `Fa0/11 err-disabled psecure-violation`. The new rep brought his own Wi-Fi dongle on a USB hub yesterday and the extra MAC tripped port-security `maximum 2` rule. The phone counts as MAC #1, the PC NIC as #2, the dongle as #3 → port shut.

### Fix
```
ACC-SW1#
configure terminal
interface FastEthernet0/11
 shutdown
 no shutdown
end
write memory
```
Talk to the user: corporate Wi-Fi only, no rogue dongles. Wipe the offending sticky MAC if you want a clean slate:
```
ACC-SW1# clear port-security sticky interface Fa0/11
```

### Prevention
- This is *exactly* what port-security is for — the policy did its job.
- Send a one-paragraph reminder to the new-hire onboarding pack: don't plug random USB-NICs into corporate ports.
- Consider lowering violation action from `shutdown` to `restrict` if the helpdesk gets tickets like this weekly.

---

## Case 2 — "All of Sales lost the internet at 11 a.m."

### Symptom
Sofia (Sales Lead) calls: every PC in the bullpen has internet, but cannot reach `\\fs1\sales` or `\\fs1\public`. EXEC-FIN and TECH report no problem.

### Triage questions
- Did anyone change a switch port in the last hour?
- Did anyone add a new VLAN this morning?
- Is the problem one PC or all of STAFF?

### Diagnostic plan
| Layer | Check |
|---|---|
| L3 | From a Sales PC: `ping 10.10.40.1` (gateway) → OK. `ping 10.10.20.12` (FS1) → fails. |
| L3 | From CORE-SW1: `ping 10.10.40.20` (Sales PC) → OK. `ping 10.10.20.12` → OK. |
| L3 | Means inter-VLAN forwarding is working from CORE, but something is blocking STAFF→SERVERS east-west. |
| ACL | `show access-lists ACL-STAFF-IN` and look for hit counts on a `deny` line. |

### Root cause
This morning the Sr. Network Engineer was hardening `ACL-STAFF-IN` and accidentally pasted the deny-RFC1918 catch-all *before* the SMB permit lines. ACLs are top-down: the first match wins. Sales → SERVERS now matches the deny first.

### Fix
```
CORE-SW1(config)# ip access-list extended ACL-STAFF-IN
CORE-SW1(config-ext-nacl)# no 60                   ! remove the misordered deny line
CORE-SW1(config-ext-nacl)# 200 deny ip 10.10.40.0 0.0.0.255 10.10.30.0 0.0.0.255 log
```
Re-verify order with `show access-lists ACL-STAFF-IN`, then `write memory`.

### Prevention
- ACL changes go through a peer review and are pasted into a test environment first.
- Use sequence numbers explicitly (`10`, `20`, `30`…), not implicit append.
- Keep a printed copy of the intended ACL hit-pattern; if hit counts on `deny … log` start climbing, an alert fires.

---

## Case 3 — "Conference room Wi-Fi is unusable during client meetings"

### Symptom
Marcus (Ops Mgr) reports that during big meetings in R8, laptops drop off Wi-Fi every 30–60 seconds. Same laptops work fine at their desks.

### Triage questions
- Does it happen with 5 people in the room, 10, 15?
- Which AP is the room actually associating to — AP2 (Bullpen) or something else?
- Is the corporate AP in the room itself, or are users hitting AP2 through a wall?

### Diagnostic plan
| Layer | Check |
|---|---|
| L1 / RF | Walk in with WiFi Analyzer app; check signal level and 2.4 GHz channel overlap | 
| L2 | Confirm laptops are on `QVIS-Corp` SSID and on the expected VLAN |
| AP | Check AP2's client count and channel utilisation |

### Root cause
The Bullpen AP (AP2) is the only corporate AP in range of R8. With 12 client laptops plus 6 phones in the room, AP2's 2.4 GHz radio is at ~85% airtime utilisation. Worse: a neighbouring tenant's AP overlaps on channel 6 and AP2 is on channel 11 — but the BIG conference TV is also broadcasting an SSID for screen casting, hammering the same channel.

### Fix
Short-term:
- Disable the conference TV's broadcast SSID and use HDMI casting.
- Force AP2 to 5 GHz only on the corp SSID, with band-steering on.

Long-term:
- Add a dedicated AP4 in R8 with the same SSID, anchored to channel 36 (DFS-free) on 5 GHz, channel 1 on 2.4 GHz.
- 1× AP serving 12 simultaneous video-conferencing clients is undersized; the rule of thumb is 1 AP per 20 active devices *or* 1 per 1,500 sq ft, whichever is smaller.

### Prevention
- Wireless survey before every office layout change.
- Disable 2.4 GHz on the corp SSID where 5 GHz coverage is good.
- Cap any non-essential SSID broadcast in the building (smart TVs, projectors).

---

## Case 4 — "I created the user in AD but she can't log in"

### Symptom
Jordan (Helpdesk T1) created `nadia.hassan` for the new Marketing Specialist. The account shows up in ADUC. Nadia gets "The trust relationship between this workstation and the primary domain failed" at the login screen of her new laptop.

### Triage questions
- Did the laptop ever successfully join the domain?
- Was the laptop wiped and re-imaged recently, keeping the same name?
- What does `Get-ADComputer` show for the laptop?

### Diagnostic plan
| Check | Result |
|---|---|
| `Test-ComputerSecureChannel` on the laptop (booted in safe mode w/ networking, signed in with local admin) | Returns `False` |
| `Get-ADComputer NADIA-LT01` in ADUC | Object exists, password mismatched |

### Root cause
The laptop was re-imaged using the same hostname but **not removed** from AD first. The local machine account no longer matches the AD computer object's password — the secure channel is broken.

### Fix
On the laptop (local admin):
```powershell
Test-ComputerSecureChannel -Repair -Credential (Get-Credential)
```
Provide a Domain Admin credential (or use LAPS to elevate). Reboot. Nadia logs in.

If that fails, the bigger hammer: remove computer from domain, restart, rejoin from a clean computer object.

### Prevention
- **Process change.** Imaging template must include the line `Remove-ADComputer` against the old name as part of the destroy step, or generate a new hostname every reimage (better: `QVIS-LT-####` random).
- Use **LAPS** so the helpdesk doesn't need to keep typing Domain Admin creds.
- Document the reimage runbook in OneNote / Confluence and require T1 sign-off.

---

## Case 5 — "DNS works for everyone except the Training Lab"

### Symptom
Daniel (Sr. Net Engineer) tries to run a client training class in R10 using six lab PCs on VLAN 60. PCs get DHCP, can ping 8.8.8.8, but `nslookup google.com` returns "DNS request timed out."

### Triage questions
- Lab PCs DNS server set to what?
- Is it consistent — *all* lab PCs or just some?
- Was the lab ACL changed recently?

### Diagnostic plan
| Layer | Check |
|---|---|
| L7 (DNS) | `nslookup google.com 10.10.20.10` from Lab-PC → timeout |
| L7 (DNS) | `nslookup google.com 1.1.1.1`     from Lab-PC → answers fine |
| L3 | `ping 10.10.20.10` from Lab-PC → timeout (TCP 53 / UDP 53 also dropped) |
| Policy | `show access-lists ACL-LAB-IN` |

### Root cause
`ACL-LAB-IN` only permits DNS to `host 10.10.20.10` on the explicit subnet (10.10.60.0/24). The deny-RFC1918 lines below it should *not* drop UDP/53 to DC1 — but the helper-address is sending DHCP relay to DC1, *and* the lab DHCP scope was handing out **both** DCs as DNS servers. When a client tries DC2 (10.10.20.11) for DNS, the ACL drops it.

### Fix
Two options:
- **Option A (preferred):** make the lab DHCP scope hand out *only* DC1 as DNS, since the ACL only opens DC1.
  ```powershell
  Set-DhcpServerv4OptionValue -ScopeId 10.10.60.0 -DnsServer 10.10.20.10
  ```
- **Option B:** widen the ACL to permit DNS to both DCs:
  ```
  CORE-SW1(config)# ip access-list extended ACL-LAB-IN
  CORE-SW1(config-ext-nacl)# 5 permit udp 10.10.60.0 0.0.0.255 host 10.10.20.11 eq 53
  ```

Pick A: the lab should not become more reachable into the corporate VLAN than strictly required.

### Prevention
- ACL and DHCP scope live in the same change document. If you change one, you must touch the other.
- Add a synthetic monitor on the lab VLAN that hourly does `nslookup` to both DC1 and DC2; alerts on either failing.

---

## Case 6 — "Finance can't print to the Finance MFP — but they can print to the bullpen one"

### Symptom
Priya (Finance) and Adaeze (CEO) try to print payroll to PRN3 (the printer physically in their corridor). Job spools, never prints. They print fine to PRN1 in the bullpen — which is wrong on its own (payroll going past Sales).

### Triage questions
- When did PRN3 last work?
- Did PRN3's IP change?
- Did the print queue on FS1 (print server) restart?

### Diagnostic plan
| Layer | Check |
|---|---|
| L3 | `ping 10.10.80.12` from Finance PC | fails |
| L3 | `ping 10.10.80.12` from CORE-SW1 | succeeds |
| L3 | `ping 10.10.80.12` from FS1        | succeeds |
| ACL | `show access-lists ACL-EXEC-FIN-IN` — hit counter on print permit line? | 0 hits |

### Root cause
PRN3 was replaced two days ago. The new MFP arrived configured with IP `10.10.80.112` instead of the reserved `10.10.80.12`. The DHCP reservation for PRN3 still hands out `.12`, but the device is locally set to static `.112`. The print queue on FS1 was updated to point at the new device's static IP `.112` — but the ACL `ACL-EXEC-FIN-IN` permits `tcp … 10.10.80.0/24 eq 9100` so layer 3 to `.112` should work. *And it does* from FS1 → PRN3. The problem is that Finance PCs send the print job directly via a peer-to-peer queue installed by an old GPO that still points to `.12`. `.12` doesn't answer, jobs time out.

### Fix
Two layers:
- Re-IP the new PRN3 to honour the reservation: factory-reset the printer's NIC and let DHCP give it `.12`. Update FS1's print queue back to `.12`.
- Remove the old per-PC TCP/IP printer port from Finance laptops and re-deploy printers through GPO Preferences → Printers, so users get the *shared queue* `\\FS1\PRN3-Finance` rather than a hard-coded IP.

### Prevention
- **Don't print direct-IP; print via the print server.** That way, the IP can change and only one place needs updating.
- DHCP reservations should be set on the printer *before* it's racked, by the technician installing it. Add a step to the install checklist.
- Quarterly: walk the print queue list against `Get-DhcpServerv4Reservation` and flag any IP mismatch.

---

## Closing note — what these six have in common

In every case, the actual fix was small (one config line, one GPO removal, one DHCP option). The value the technician brings is **structured triage** — moving up the OSI stack methodically, not guessing. The portfolio version of this file is the version a hiring manager wants to see: *not* "I rebooted the switch and it worked," but *"here is the layered reasoning, here is the exact command, here is what I changed in the runbook so it does not recur."*
