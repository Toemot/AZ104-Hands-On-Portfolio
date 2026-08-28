# Break-Fix Scenario 2: AND Logic Failure (Subnet + NIC NSG)

## 🔴 The Problem

Traffic is blocked even though you configured rules. Here's what you see:

| Level | NSG | Rule | Access |
|-------|-----|------|--------|
| Subnet | nsg-spoke1-db | Allow 1433 FROM 10.1.0.0/24 | ✅ |
| NIC | (none) | (no rules) | ❌ DEFAULT DENY |

You expected database traffic (SQL/1433) from the app tier to reach the database VM.

**But traffic is BLOCKED.** Why?

---

## 🎯 What's Actually Happening

### Dual-NSG Evaluation (AND Logic)
```
Source VM (App Tier)
    ↓
    └─→ Subnet NSG (nsg-spoke1-app) for SOURCE direction
           ├─ Outbound rule: Allow 1433 to 10.1.1.0/24 ✅
           ↓
Destination VM (DB Tier)
    ↓
    └─→ Subnet NSG (nsg-spoke1-db) for DESTINATION direction
           ├─ Inbound rule: Allow 1433 from 10.1.0.0/24 ✅
           ↓
    └─→ NIC NSG (if attached) for DESTINATION direction
           ├─ No matching rule ❌ DEFAULT DENY 65500
           ↓
Result: ✅ AND ✅ AND ❌ = BLOCKED
```

**Key Insight:** Traffic must pass **ALL** NSG checks:
1. Source Subnet NSG Outbound ✅
2. Destination Subnet NSG Inbound ✅
3. Destination NIC NSG Inbound ❌ ← **PROBLEM HERE**

### The Mistake
Student thought: "Subnet NSG allows it, so traffic flows"
Reality: "Subnet NSG + NIC NSG both must allow (AND Logic). Missing NIC rule = default deny"

---

## 🔧 How to Fix

### Option 1: Remove NIC NSG (SIMPLEST)
If the NIC doesn't need its own NSG, detach it:

```powershell
# Get the NIC ID
$vmName = "db-vm-01"
$resourceGroup = "rg-learning-spoke1"

$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName
$nicId = $vm.NetworkProfile.NetworkInterfaces[0].Id

# Remove NSG from NIC
az network nic update \
  --ids $nicId \
  --network-security-group ""
```

**Result:**
- NIC NSG evaluation skipped
- Only Subnet NSG checked
- AND Logic: ✅ AND ✅ = ALLOWED ✅

**Best for:** When subnet-level NSG is sufficient (most cases)

---

### Option 2: Add NIC NSG with Matching Rule (EXPLICIT)
If you need NIC-level control:

```powershell
# Create NIC-level NSG
az network nsg create \
  --resource-group rg-learning-spoke1 \
  --name nsg-spoke1-db-nic

# Add inbound rule for SQL traffic
az network nsg rule create \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db-nic \
  --name "Allow-SQL-From-App" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "10.1.0.0/24" \
  --destination-port-ranges "1433"

# Attach NIC NSG to the database VM's NIC
$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName
$nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id
$nic.NetworkSecurityGroup = @{id = "/subscriptions/<subscription-id>/resourceGroups/rg-learning-spoke1/providers/Microsoft.Network/networkSecurityGroups/nsg-spoke1-db-nic"}
Set-AzNetworkInterface -NetworkInterface $nic
```

**Result:**
- NIC NSG has matching rule
- AND Logic: ✅ AND ✅ AND ✅ = ALLOWED ✅

**Best for:** Defense-in-depth (layered security)

---

### Option 3: Fix Subnet NSG Rule (IF MISSING)
If the subnet NSG rule doesn't exist:

```powershell
# Add missing rule to subnet NSG
az network nsg rule create \
  --resource-group rg-learning-spoke1 \
  --nsg-name nsg-spoke1-db \
  --name "Allow-SQL-From-App-Subnet" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "10.1.0.0/24" \
  --destination-port-ranges "1433"
```

**Result:**
- Subnet NSG rule now exists
- AND Logic: ✅ AND ✅ = ALLOWED ✅

---

## ✅ Verification

### Before Fix (NSGs & Rules)
```powershell
# Check Subnet NSG
az network nsg show \
  --resource-group rg-learning-spoke1 \
  --name nsg-spoke1-db \
  --query "securityRules[?direction=='Inbound' && destinationPortRange=='1433']" \
  -o table

# Output: Allow-SQL-From-App-Subnet | Inbound | Allow | Tcp | 1433 | 10.1.0.0/24 ✅

# Check NIC NSG
$vm = Get-AzVM -ResourceGroupName rg-learning-spoke1 -Name db-vm-01
$nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id
$nic.NetworkSecurityGroup

# Output: (null or empty) ❌
```

Result: **BLOCKED** (NIC NSG missing = default deny)

### After Fix (Effective Rules)
```powershell
# View EFFECTIVE rules (Subnet + NIC combined)
az network nic show-effective-nsg \
  --resource-group rg-learning-spoke1 \
  --name nic-db-01 \
  --query "effectiveSecurityRules[?destinationPortRange=='1433']" \
  -o table

# Output:
# Name                        Direction    Priority    Access    Protocol    Port
# Allow-SQL-From-App-Subnet   Inbound      100         Allow     Tcp         1433
```

Result: **ALLOWED** ✅

---

## 📚 Learning Outcome

**What you learned:**
1. NSGs are **dual-evaluated** at source and destination
2. **AND Logic:** Outbound rules at source + Inbound rules at destination
3. **NIC NSG adds a third check** (optional but powerful)
4. **Subnet NSG alone is usually sufficient** (unless defense-in-depth needed)
5. **Default rule 65500 blocks** unmatched traffic at EVERY level

**Mental Model:**
```
Traffic Path:
Source Subnet NSG Outbound ──┐
                              ├─ BOTH must allow
                              ↓
Destination Subnet NSG Inbound ──┐
                                  ├─ BOTH must allow
                                  ↓
Destination NIC NSG Inbound ──────┘
```

**Exam Question This Teaches:**
> "Subnet NSG allows traffic. NIC NSG has no rules. Traffic is?"
> 
> **Answer:** Blocked (NIC NSG defaults to Deny 65500. AND Logic requires both)

---

## 🛡️ Real-World Context

### Why This Matters in Production

**Scenario 1: Healthcare (Clinical vs Admin Data)**
```
Clinical App (Spoke1) tries to reach Admin DB (Spoke2):
- Source: App Subnet NSG (nsg-spoke1-app) ✅ Allow outbound 1433
- Dest:   App Subnet NSG (nsg-spoke2-app) ✅ No rule for destination
- Dest:   DB Subnet NSG (nsg-spoke2-db) ❌ Rule allows ONLY nsg-spoke2-app source
  
Result: BLOCKED (correct - isolates sensitive data)
```

**Scenario 2: Troubleshooting Production Issue**
```
Customer says: "Database unreachable from app"
You check:
- Subnet NSG at source: ✅ Outbound rule exists
- Subnet NSG at destination: ✅ Inbound rule exists
- NIC NSG at destination: ❌ No rule (didn't check this!)
- Result: You add rule to NIC NSG, fixed!
```

### Defense-in-Depth Strategy
- **Subnet NSG:** Broad policies (all VMs in subnet)
- **NIC NSG:** Specific policies (single VM extra protection)
- **Example:** Database VM gets both subnet NSG (database tier rules) + NIC NSG (extra hardening)

---

## ⚡ Troubleshooting NSG Blocking Issues

### Step 1: Gather Facts
```powershell
$sourceName = "app-vm-01"
$destName = "db-vm-01"
$port = 1433

$sourceVM = Get-AzVM -Name $sourceName
$destVM = Get-AzVM -Name $destName

$sourceNIC = Get-AzNetworkInterface -ResourceId $sourceVM.NetworkProfile.NetworkInterfaces[0].Id
$destNIC = Get-AzNetworkInterface -ResourceId $destVM.NetworkProfile.NetworkInterfaces[0].Id

Write-Host "Source NSG:" $sourceNIC.NetworkSecurityGroup.Id
Write-Host "Dest NSG:" $destNIC.NetworkSecurityGroup.Id
```

### Step 2: Check Source Outbound
```powershell
az network nic show-effective-nsg \
  --resource-group rg-learning-spoke1 \
  --name nic-app-01 \
  --query "effectiveSecurityRules[?direction=='Outbound']"
```

### Step 3: Check Dest Inbound (Subnet + NIC)
```powershell
az network nic show-effective-nsg \
  --resource-group rg-learning-spoke1 \
  --name nic-db-01 \
  --query "effectiveSecurityRules[?direction=='Inbound']"
```

### Step 4: Identify Blocking Rule
Look for:
- Rule with Access='Deny'
- Or if no Allow rule matches, the default rule 65500 (DenyAllInBound)

### Step 5: Fix
- Delete conflicting Deny rule, OR
- Add missing Allow rule, OR
- Verify port/protocol/source match exactly

---

## 🎓 Teaching Point

**For Instructors:** This is THE most commonly misunderstood NSG concept.

**Teachable Moments:**
1. "Why doesn't the subnet NSG rule alone work?"
2. "What does 'effective rules' mean?"
3. "When do you need NIC NSG vs Subnet NSG?"
4. "How do you troubleshoot blocking issues in production?"

**Student Misconception:** "NSG filters traffic" (True, but incomplete)
**Corrected Understanding:** "NSGs filter at MULTIPLE levels and ALL must allow (AND Logic)"

---

**Scenario Complete!** You now understand NSG AND Logic. Next: Scenario 3 (Port Specificity).
