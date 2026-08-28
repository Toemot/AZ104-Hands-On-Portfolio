# Break-Fix Scenario 3: Wrong Port Number (Exact Match Required)

## 🔴 The Problem

Database connectivity fails, but you think you configured the rule. Here's what you set up:

| Field | Value | Issue |
|-------|-------|-------|
| **Configured Port** | **3306** (MySQL) | ❌ |
| **Actual Traffic Port** | **1433** (SQL Server) | ✅ |
| **Match?** | **NO** | ❌ |

You configured a rule allowing port 3306, but your app uses port 1433.

**Traffic is BLOCKED because ports don't match exactly.** Why?

---

## 🎯 What's Actually Happening

### NSG Rule Matching Process
```
Incoming traffic on port 1433 from app subnet
    ↓
NSG evaluates all rules in priority order
    ↓
Rule 1: Priority 100
  ├─ Source: 10.1.0.0/24? ✅ YES
  ├─ Protocol: TCP? ✅ YES
  ├─ Port: 3306? ❌ NO (traffic uses 1433)
  ↓
Rule matching: FAILED (port 3306 ≠ 1433)
    ↓
No more allow rules → Default rule 65500 DENY
    ↓
Result: BLOCKED ❌
```

**Key Insight:** NSG rules require **EXACT MATCH** on ALL fields:
- Source IP/CIDR ✅
- Protocol (TCP/UDP) ✅
- **Port number ✅ ← MUST MATCH EXACTLY**

### The Mistake
Student thought: "Close enough, 3306 and 1433 are both database ports"
Reality: "NSG doesn't care about semantics. 3306 ≠ 1433. Rule doesn't match."

---

## 🔧 How to Fix

### Fix: Correct the Port Number in the Rule

```powershell
# Option A: Delete and recreate the rule with correct port
az network nsg rule delete \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db \
  --name "Allow-SQL-From-App"

az network nsg rule create \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db \
  --name "Allow-SQL-From-App" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "10.1.0.0/24" \
  --destination-port-ranges "1433"
```

**Result:**
- Rule now matches port 1433
- Traffic on port 1433 is ALLOWED ✅

---

### Alternative: Support MULTIPLE Database Ports

If your app needs to support both MySQL (3306) AND SQL Server (1433):

```powershell
# Create a single rule with multiple ports
az network nsg rule delete \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db \
  --name "Allow-SQL-From-App"

az network nsg rule create \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db \
  --name "Allow-Multiple-DB-From-App" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "10.1.0.0/24" \
  --destination-port-ranges "3306" "1433"
```

**Result:**
- Rule allows BOTH 1433 (SQL Server) and 3306 (MySQL)
- Traffic on either port is ALLOWED ✅

**Best for:** Microservices using different databases

---

## ✅ Verification

### Before Fix
```powershell
# List the rule
az network nsg rule show \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db \
  --name "Allow-SQL-From-App" \
  --query "{Name:name, Port:destinationPortRange, Protocol:protocol}" \
  -o table

# Output:
# Name                    Port     Protocol
# Allow-SQL-From-App      3306     Tcp
```

**Result:** Rule exists but WRONG PORT (3306, not 1433)

### After Fix
```powershell
az network nsg rule show \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db \
  --name "Allow-SQL-From-App" \
  --query "{Name:name, Port:destinationPortRange, Protocol:protocol}" \
  -o table

# Output:
# Name                    Port     Protocol
# Allow-SQL-From-App      1433     Tcp
```

**Result:** Rule now CORRECT PORT (1433) ✅

---

## 📊 Common Port Mismatches

Trainee developers often mix up database ports:

| Database | Port | Protocol | Common Mistake |
|----------|------|----------|-----------------|
| SQL Server | **1433** | TCP | Config 3306 (MySQL port) |
| MySQL | **3306** | TCP | Config 1433 (SQL Server port) |
| PostgreSQL | **5432** | TCP | Config 3306 or 1433 |
| Oracle | **1521** | TCP | Config 3306 |
| Redis | **6379** | TCP | Config 3306 (databases mix-up) |
| MongoDB | **27017** | TCP | Config 3306 |
| HTTP | **80** | TCP | Config 443 (SSL) |
| HTTPS | **443** | TCP | Config 80 (non-SSL) |
| SSH/RDP | **22** vs **3389** | TCP | Flip 22 ↔ 3389 |

---

## 📚 Learning Outcome

**What you learned:**
1. NSG rules **MUST MATCH exactly** on all fields (source, protocol, port)
2. **Port numbers are specific** - 3306 ≠ 1433
3. NSG doesn't understand "this is a database" - it only sees "port X"
4. **Multiple ports in one rule** saves space (use comma-separated values)
5. **Always verify port numbers** match your application's configuration

**Mental Model:**
```
NSG Rule Matching Checklist:
□ Source IP/CIDR matches? ✓
□ Protocol (TCP/UDP) matches? ✓
□ Port number matches? ✓ ← MUST match EXACTLY
│
If ALL checked: ALLOWED ✅
If ANY unchecked: Continues to next rule (likely BLOCKED by rule 65500)
```

**Exam Question This Teaches:**
> "NSG rule allows port 3306. Traffic uses port 1433. Blocked or allowed?"
> 
> **Answer:** Blocked (Ports must match exactly. 3306 ≠ 1433)

---

## 🛡️ Real-World Context

### Why This Matters in Production

**Scenario 1: Database Migration**
```
Old setup: MySQL on port 3306
New setup: SQL Server on port 1433

You update NSG rules to allow 1433
But you forget to delete the old 3306 rule
Result: Old rule still there, doesn't cause issues (extra rule is harmless)
Lesson: Clean up old rules to avoid confusion later
```

**Scenario 2: Microservices Architecture**
```
App Tier has multiple services:
- API Service: Uses MySQL on 3306
- Cache Service: Uses Redis on 6379
- Message Queue: Uses RabbitMQ on 5672

NSG DB rule must allow MULTIPLE ports (not just 3306)
Result: One rule with ports "3306, 5672, 6379" instead of three rules
Cleaner + maintainable
```

**Scenario 3: Firewall Rule vs NSG Rule**
```
Azure Firewall rule: Allow port 1433
NSG rule: Allow port 3306

Which blocks traffic? NSG (evaluated at VM NIC level, which is before firewall)
Debugging: Start at NSG, then check firewall
Lesson: Debug from bottom-up (NIC → Subnet → Firewall)
```

### Compliance Implications
- **Database Encryption:** TLS often uses different ports (1434 for encrypted SQL Server)
- **PCI DSS:** Must allow database port AND verify it's encrypted
- **HIPAA:** Patient data (Spoke1) should use separate port than admin data (Spoke2)

---

## ⚡ Port Troubleshooting Checklist

When your application can't reach a service:

```powershell
# Step 1: What port is your app ACTUALLY using?
# (Check app config, documentation, netstat on running app)
$actualPort = 1433  # Example: SQL Server

# Step 2: What port does NSG rule allow?
az network nsg rule show \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db \
  --name "Allow-SQL-From-App" \
  --query "destinationPortRange" \
  -o tsv

# Step 3: Do they match?
if ($actualPort -eq $configuredPort) {
    Write-Host "✅ Ports match - check other fields (source IP, protocol)"
} else {
    Write-Host "❌ Ports DON'T match - FIX THE NSG RULE"
}

# Step 4: Update rule with correct port
az network nsg rule update \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db \
  --name "Allow-SQL-From-App" \
  --destination-port-ranges $actualPort
```

---

## 🎓 Teaching Point

**For Instructors:** This is the EASIEST NSG concept to understand but HARDEST to debug.

**Why?** Because students often assume "close enough" or "roughly correct"
- "3306 is a database port, 1433 is a database port, should work"
- "They're both on TCP, should work"
- "The rule exists, so it should work"

**Reality:** NSG matching is **literal and exact**. No fuzzy logic.

**Teaching Strategy:**
1. Show working rule (port 1433 allows traffic on 1433)
2. Change port to 3306 (now blocks)
3. Explain: "NSG sees 3306 in rule, traffic on 1433, no match = blocked"
4. Let students predict what happens
5. Fix the rule together
6. Verify traffic works

**Aha Moment:** "So NSG doesn't understand what a database is—it just looks for literal matches"

---

## 📝 Key Takeaway

**NSG rules are LITERAL FILTERS:**
- Source IP must match EXACTLY
- Protocol (TCP/UDP) must match EXACTLY
- Port must match EXACTLY

**There's no fuzzy logic, no "close enough", no assumptions.**

This is why troubleshooting NSGs requires:
1. Exact specification of what traffic you're testing (source IP, port, protocol)
2. Comparing with NSG rules
3. Finding the mismatch
4. Fixing the rule

---

**Scenario Complete!** You now understand NSG port specificity. All three scenarios done! ✅

Next: Export all NSG configs to JSON, then copy to GitHub folder.
