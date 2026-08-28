# Lab-004: Network Security Groups (NSGs)
## Training School Module - Week 1, Day 4

**Module Code:** AZ-104-004  
**Difficulty:** HARD (Where 70% of candidates fail)  
**Duration:** 120 minutes  
**Cost:** $0 (NSGs are free)  
**Prerequisite:** Lab-003 (Hub-Spoke Architecture)  
**Exam Relevance:** 15-20% of AZ-104 exam

---

## 📚 Module Overview

This lab teaches **Layer 4 port-level security** through hands-on NSG deployment and break-fix troubleshooting. Students will master concepts that 85% of candidates struggle with: **AND Logic**, **Rule Priority**, and **Effective Rules Analysis**.

### For Students
Learn to design networks that comply with real-world security requirements (HIPAA, patient data isolation, departmental segregation).

### For Instructors
Teach troubleshooting skills through intentional break-fix scenarios. Students learn to diagnose NSG failures using `show-effective-nsg`.

### For CIOs
Understand NSG strategy as the first line of defense. Combined with firewalls in Lab-005, NSGs form the foundation of enterprise security posture.

---

## 🎯 Learning Objectives

By completing this module, learners will be able to:

1. ✅ **Create NSGs and configure rules** (Priority, Direction, Access, Protocol, Port ranges)
2. ✅ **Understand AND Logic** (Subnet NSG + NIC NSG both evaluated)
3. ✅ **Grasp Rule Priority Order** (Lower number = evaluated first)
4. ✅ **Apply Deny by Default** (No matching rule = auto-deny)
5. ✅ **Analyze Effective Rules** (What actually applies vs configured)
6. ✅ **Troubleshoot connectivity failures** (Using `show-effective-nsg`)
7. ✅ **Design micro-segmented networks** (Specific subnet restrictions)
8. ✅ **Implement compliance security** (Isolate sensitive data)

---

## 🏗️ Lab Architecture

### BEFORE Lab-004 (Lab-003 state)
```
Hub-Spoke topology exists
NO NSGs attached
All traffic allowed (if routing works)
❌ COMPLIANCE FAILURE: Clinical can reach Admin
```

### AFTER Lab-004 (Complete)
```
5 NSGs deployed
5 subnets protected
✅ COMPLIANCE PASS: Clinical isolated from Admin
✅ Database tiers locked down (app tier only)
✅ Hub controls all North/South traffic
```

### Network Topology
```
                    ☁️ INTERNET (Public)
                         |
            [Allow 443 OUT / Deny ALL IN]
                         |
        ╔═══════════════════════════════════════╗
        ║        🔴 HUB (10.0.0.0/16)           ║
        ║      nsg-hub-central (PROTECTED)      ║
        ║   Central infrastructure layer         ║
        ╚═════════════════╤══════════════════════╝
                         |
        [VNet Peering - Both directions]
                    |         |
        [Hub↔Spoke1]    [Hub↔Spoke2]
                    |         |
        ┌───────────┘         └──────────┐
        |                                  |
   ╔════╩═══════════════════╗    ╔════════╩══════════════════╗
   ║  🟢 SPOKE1             ║    ║  🟢 SPOKE2                ║
   ║  Clinical Data         ║    ║  Admin Data               ║
   ║  (Isolated)            ║    ║  (Isolated)               ║
   ║                        ║    ║                           ║
   ║ ┌──────────────────┐   ║    ║ ┌──────────────────┐      ║
   ║ │ APP TIER 🌐      │   ║    ║ │ APP TIER 🌐      │      ║
   ║ │ nsg-spoke1-app   │   ║    ║ │ nsg-spoke2-app   │      ║
   ║ │ ✅ 443 IN ✅ 1433 OUT│ ║ ║ │ ✅ 443 IN ✅ 1433 OUT│  ║
   ║ └────────┬─────────┘   ║    ║ └────────┬─────────┘      ║
   ║          | [SQL]       ║    ║          | [SQL]          ║
   ║ ┌────────▼─────────┐   ║    ║ ┌────────▼─────────┐      ║
   ║ │ DB TIER 🔒       │   ║    ║ │ DB TIER 🔒       │      ║
   ║ │ nsg-spoke1-db    │   ║    ║ │ nsg-spoke2-db    │      ║
   ║ │ ✅ 1433 from app │   ║    ║ │ ✅ 1433 from app │      ║
   ║ │ ❌ Deny ALL else │   ║    ║ │ ❌ Deny ALL else │      ║
   ║ └──────────────────┘   ║    ║ └──────────────────┘      ║
   ╚════════════════════════╝    ╚═══════════════════════════╝
```

---

## 📊 AZ-104 Exam Concepts

This module directly prepares learners for these exam topics:

### Topic 1: NSG AND Logic (85% fail this)
**Exam Weight:** 15-20%

**Concept:** Traffic must pass MULTIPLE NSG evaluations:
- Subnet NSG outbound (source)
- Subnet NSG inbound (destination)
- NIC NSG outbound (source VM)
- NIC NSG inbound (destination VM)

**Exam Question Pattern:**
> "Subnet NSG allows traffic. NIC NSG has no rules. Traffic is blocked. Why?"

**Expected Answer:** "AND Logic requires both NSGs to allow. NIC NSG defaults to Deny (65500)."

---

### Topic 2: Rule Priority (70% get wrong)
**Exam Weight:** 10-15%

**Concept:** Lower priority number = evaluated first = wins if matches

**Exam Question Pattern:**
> "Priority 50 DENY, Priority 100 ALLOW (same traffic). Blocked or allowed?"

**Expected Answer:** "Blocked. Priority 50 matches first (lower number), DENY wins."

---

### Topic 3: Effective Rules (90% don't know)
**Exam Weight:** 5-10%

**Concept:** Configured rules + Default rules = Effective rules

**Exam Command:** `az network nic show-effective-nsg --resource-group rg --name nic-name`

**Exam Question Pattern:**
> "How do you see combined NSG rules on a NIC?"

**Expected Answer:** "`az network nic show-effective-nsg`"

---

### Topic 4: Deny by Default (60% forget)
**Exam Weight:** 10-15%

**Concept:** Priority 65500 (DenyAllInBound) blocks unmatched traffic

**Exam Question Pattern:**
> "No rule matches incoming traffic. Allowed or blocked?"

**Expected Answer:** "Blocked. Default rule 65500 DENIES all unmatched."

---

## 🧪 Break-Fix Scenarios (Hands-On Learning)

### Scenario 1: Conflicting Rules (Priority Matters)

**Problem:** 
- Priority 50: DENY port 443
- Priority 100: ALLOW port 443

**What Happens:**
- Internet tries to reach app on port 443
- Priority 50 evaluated first (lower number)
- DENY matches → Traffic blocked
- Priority 100 never evaluated

**Why It Fails:**
Student thinks: "I configured Allow rule, so traffic should flow"
Reality: "Priority order matters more than Allow vs Deny"

**Fix:**
- Delete Priority 50 DENY rule, OR
- Change Priority 100 ALLOW to Priority 40 ALLOW

**Exam Relevance:** Teaches rule evaluation order

---

### Scenario 2: AND Logic Failure (Subnet + NIC)

**Problem:**
- Subnet NSG: Allow 1433 from app subnet ✅
- NIC NSG: No rules (empty) ❌

**What Happens:**
- App tries to reach database on 1433
- Subnet NSG check: ALLOW ✅
- NIC NSG check: No matching rule → Default DENY 65500 ❌
- AND Logic: ✅ AND ❌ = FAIL

**Why It Fails:**
Student thinks: "Subnet NSG allows it, so traffic flows"
Reality: "Both NSGs must allow. Missing rule = default deny"

**Fix:**
- Add allow rule to NIC NSG, OR
- Remove NIC NSG entirely

**How to Diagnose:**
```powershell
az network nic show-effective-nsg --resource-group rg-learning-spoke1 --name nic-db-01
# Shows combined rules (subnet + NIC)
# Look for: Which NSG is blocking?
```

**Exam Relevance:** Teaches AND Logic concept (most failed)

---

### Scenario 3: Wrong Port Number (Specificity)

**Problem:**
- Rule: Allow port 3306 (MySQL)
- Traffic: Uses port 1433 (SQL Server)

**What Happens:**
- App tries database on 1433
- Rule says: Allow 3306
- Does 1433 match 3306? NO ❌
- No matching rule → Default DENY ❌

**Why It Fails:**
Student thinks: "Close enough, maybe it works?"
Reality: "Port numbers must match EXACTLY"

**Fix:**
- Correct port number to 1433

**Common Mistakes:**
| Wrong | Correct | Service |
|-------|---------|---------|
| 80 | 443 | HTTPS |
| 22 | 3389 | RDP |
| 3306 | 1433 | SQL Server |

**Exam Relevance:** Teaches NSG specificity (all fields must match)

---

## 📋 Compliance Use Case (BC Health Example)

### Scenario: Clinical + Admin networks, must isolate patient data

**NSG Strategy:**
```
Clinical Spoke (Spoke1):
  App NSG: Allow 443 IN (web), Allow 1433 OUT to clinical DB
  DB NSG:  Allow 1433 FROM clinical app ONLY

Admin Spoke (Spoke2):
  App NSG: Allow 443 IN (web), Allow 1433 OUT to admin DB
  DB NSG:  Allow 1433 FROM admin app ONLY
```

**Result:**
- ✅ Clinical app → Clinical DB (works)
- ✅ Admin app → Admin DB (works)
- ❌ Clinical app → Admin DB (blocked by Spoke2 App NSG, then Spoke2 DB NSG)
- ❌ Admin app → Clinical DB (blocked by Spoke1 App NSG, then Spoke1 DB NSG)

**Compliance:** Patient data (Spoke1) cannot leak to Finance (Spoke2) ✅

---

## 🎓 Teaching Delivery Suggestions

### For 60-Minute Bootcamp Session
1. **Lecture (10 min):** NSG fundamentals, AND logic, priority
2. **Live Demo (15 min):** Create 1 NSG, add rules, attach to subnet
3. **Hands-On (20 min):** Students create remaining NSGs
4. **Troubleshooting (15 min):** Demo break-fix scenario, show `show-effective-nsg`

### For Self-Paced Learning (120 min)
1. Read Lab-004-NSG-Rules.md theory (15 min)
2. Complete Phases 1-2 (create + attach NSGs) (50 min)
3. Complete Phase 3 (analyze effective rules) (15 min)
4. Review break-fix scenarios theoretically (30 min)
5. Document findings (10 min)

### For Interview Prep (30 min)
1. Memorize: AND Logic rule
2. Memorize: Priority order (lower wins)
3. Practice: "How do you troubleshoot blocked NSG traffic?"
4. Practice: "Design NSGs for clinical + admin isolation"

---

## ❓ Common Student Questions

**Q: "Why do we need NSGs if we have Azure Firewall?"**  
A: NSGs are **Layer 4** (port filtering), free, no extra config. Firewalls are **Layer 7** (application inspection), $$$. NSGs are foundational.

**Q: "What's the difference between subnet NSG and NIC NSG?"**  
A: Subnet NSG applies to **all resources** in subnet. NIC NSG applies to **single VM**. AND Logic means **both evaluate**.

**Q: "Why does priority matter if Allow beats Deny?"**  
A: Priority determines **evaluation order**, not preference. Lower priority = evaluated first = wins if match.

**Q: "How do I troubleshoot 'Connection refused' errors?"**  
A: Check **effective rules** (`az network nic show-effective-nsg`). Look for which NSG is blocking. Verify AND logic alignment.

**Q: "Can I attach multiple NSGs to one subnet?"**  
A: No, only one NSG per subnet. But one NSG can have 1000+ rules.

**Q: "What if I misconfigure NSG and lock myself out?"**  
A: You can't lock yourself out—Azure prevents that. If issues, delete NSG or create new one.

---

## 📊 Success Metrics

After Lab-004, learners should:

- ✅ Understand NSG AND Logic (not 85% anymore)
- ✅ Know rule priority order (not 70% failure rate)
- ✅ Use `show-effective-nsg` for troubleshooting (not 90% ignorance)
- ✅ Recognize deny-by-default behavior
- ✅ Design micro-segmented networks
- ✅ Answer AZ-104 NSG questions correctly

---

## 🔗 Progression to Next Lab

**Lab-005: User-Defined Routes (UDRs) + Azure Firewall**

Lab-004 answers: "HOW DO I FILTER TRAFFIC?"  
Lab-005 answers: "HOW DO I ROUTE TRAFFIC?"

Lab-005 will force spoke-to-spoke traffic through hub firewall, adding Layer 7 inspection on top of Lab-004's Layer 4 NSGs.

---

## 📚 Resources

- Microsoft Learn: NSG Overview
- Microsoft Learn: NSG Rules
- Azure CLI Reference: `az network nsg`
- Azure Portal: Network Security Groups

---

## 📝 Lab Completion Checklist

- ✅ 5 NSGs created (hub, spoke1-app, spoke1-db, spoke2-app, spoke2-db)
- ✅ 15+ rules configured
- ✅ All NSGs attached to Lab-003 subnets
- ✅ Effective rules analyzed
- ✅ Break-fix scenarios understood
- ✅ Exports saved to JSON
- ✅ Documentation created
- ✅ Ready to commit to GitHub

---

**Lab-004 Complete** ✅

*Created: Aug 27, 2026 | Duration: 120 minutes | Cost: $0*

*Next: Lab-005 (UDRs + Azure Firewall) - Central routing + Layer 7 inspection*
