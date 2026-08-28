# Break-Fix Scenario 1: Conflicting Rules (Priority Wins)

## 🔴 The Problem

You've configured two rules for the same traffic pattern, but they CONFLICT:

| Rule | Priority | Direction | Access | Port | Source |
|------|----------|-----------|--------|------|--------|
| Rule-A | **50** | Inbound | **DENY** | 443 | Internet |
| Rule-B | **100** | Inbound | **ALLOW** | 443 | Internet |

You expected internet traffic on port 443 to be **ALLOWED** (because you configured Allow rule).

**But traffic is BLOCKED.** Why?

---

## 🎯 What's Actually Happening

### NSG Rule Evaluation Order
```
Priority 50 Rule
    ↓
Does traffic match?
    ↓
YES → Traffic DENIED (Rule-A matched)
    ↓
Priority 100 Rule (never evaluated!)
```

**Key Insight:** NSG evaluates rules **in priority order** (lower number first). 
Once a rule **matches**, evaluation **stops**.

### The Mistake
Student thought: "I have an Allow rule, so it should be allowed"
Reality: "Priority 50 is evaluated FIRST, matches first, blocks first"

---

## 🔧 How to Fix

### Option 1: Delete the Deny Rule (FASTEST)
```powershell
az network nsg rule delete \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-app \
  --name "Deny-HTTPS-Inbound"
```

**Result:** 
- Priority 50 rule gone
- Priority 100 Allow rule now evaluated first
- Traffic ALLOWED ✅

---

### Option 2: Change Allow Rule Priority to 40 (BETTER)
```powershell
# Delete the old Allow rule
az network nsg rule delete \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-app \
  --name "Allow-HTTPS-Inbound"

# Recreate with higher priority (lower number)
az network nsg rule create \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-app \
  --name "Allow-HTTPS-Inbound" \
  --priority 40 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --destination-port-ranges 443
```

**Result:**
- Priority 40 Allow rule now evaluated first
- Priority 50 Deny rule never matches (already allowed)
- Traffic ALLOWED ✅

---

### Option 3: Change Deny Rule to Lower Port (SURGICAL)
If the Deny rule is intentional for a DIFFERENT port:

```powershell
# Modify the Deny rule to target only port 8443 (not 443)
az network nsg rule update \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-app \
  --name "Deny-HTTPS-Inbound" \
  --destination-port-ranges 8443
```

**Result:**
- Deny rule blocks 8443
- Allow rule (Priority 100) handles 443
- Different traffic patterns = no conflict ✅

---

## ✅ Verification

### Before Fix
```powershell
az network nsg rule list \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-app \
  --query "[?destinationPortRange=='443'].{Name:name,Priority:priority,Access:access}" \
  -o table

# Output:
# Name                    Priority    Access
# Deny-HTTPS-Inbound      50          Deny
# Allow-HTTPS-Inbound     100         Allow
```

Result: **BLOCKED** (Priority 50 Deny wins)

### After Fix (Option 1)
```powershell
az network nsg rule list \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-app \
  --query "[?destinationPortRange=='443'].{Name:name,Priority:priority,Access:access}" \
  -o table

# Output:
# Name                    Priority    Access
# Allow-HTTPS-Inbound     100         Allow
```

Result: **ALLOWED** ✅

---

## 📚 Learning Outcome

**What you learned:**
1. NSG rules are evaluated in **priority order** (lower number = higher priority)
2. First matching rule **wins** - later rules never execute
3. "Deny" vs "Allow" is NOT the determining factor - **priority is**
4. To override a Deny rule, give Allow rule **lower priority number**

**Exam Question This Teaches:**
> "Priority 50 DENY, Priority 100 ALLOW (same traffic). Block or allow?"
> 
> **Answer:** Blocked (Priority 50 evaluated first)

---

## 🛡️ Real-World Context

### Why This Matters in Production
- **Scenario:** You want to allow YouTube (HTTPS/443) for employee research
- **But:** Someone already configured "Deny all Internet" at priority 50
- **Result:** Your Allow rule (priority 100) is ignored
- **Fix:** Either delete the Deny rule or give Allow rule priority 40

### Defense-in-Depth Implications
- Combine NSGs with Azure Firewall (Layer 7) for additional control
- Layer 4 NSGs are **first line** - must be correct before Layer 7
- Document your priority numbers to avoid conflicts later

---

## ⚡ Quick Troubleshooting Checklist

- [ ] Check effective rules: `az network nic show-effective-nsg`
- [ ] List all rules for NSG: `az network nsg rule list --nsg-name nsg-name`
- [ ] Sort by priority: `--query "[].{Name:name,Priority:priority}" --sort-by name`
- [ ] Verify port ranges match the traffic you're testing
- [ ] Check direction (Inbound vs Outbound)
- [ ] Check access (Allow vs Deny)

---

**Scenario Complete!** You now understand NSG rule priority. Next: Scenario 2 (AND Logic).
