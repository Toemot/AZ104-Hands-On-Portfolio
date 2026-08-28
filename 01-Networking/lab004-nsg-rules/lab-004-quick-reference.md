# Lab 004: NSG Rules - Quick Reference

## Commands Typed (Manual Entry - No Copy/Paste)

### Hub NSG Creation
```powershell
az network nsg create --resource-group rg-learning-hub --name nsg-hub-central --location canadacentral --tags Environment="Dev" ServiceOwner="admin@example.com" SolutionName="AZ104-NSG-Lab" BCHOCostCenter="CC-0001" OwnerBCHO="Platform-Team" Classification="Internal"

az network nsg rule create --resource-group rg-learning-hub --nsg-name nsg-hub-central --name "Allow-HTTPS-Outbound" --priority 100 --direction Outbound --access Allow --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*" --destination-address-prefixes "Internet" --destination-port-ranges "443"

az network nsg rule create --resource-group rg-learning-hub --nsg-name nsg-hub-central --name "Deny-All-Inbound-Internet" --priority 100 --direction Inbound --access Deny --protocol "*" --source-address-prefixes "Internet" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "*"
```

### Spoke1 App NSG Creation
```powershell
az network nsg create --resource-group rg-learning-spoke1 --name nsg-spoke1-app --location canadacentral --tags Environment="Dev" ServiceOwner="admin@example.com" SolutionName="AZ104-NSG-Lab" BCHOCostCenter="CC-0001" OwnerBCHO="Platform-Team" Classification="Internal"

az network nsg rule create --resource-group rg-learning-spoke1 --nsg-name nsg-spoke1-app --name "Allow-HTTPS-Inbound" --priority 100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "Internet" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "443"

az network nsg rule create --resource-group rg-learning-spoke1 --nsg-name nsg-spoke1-app --name "Allow-SSH-From-Hub" --priority 110 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "10.0.0.0/24" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "22"

az network nsg rule create --resource-group rg-learning-spoke1 --nsg-name nsg-spoke1-app --name "Allow-SQL-To-DB-Subnet" --priority 100 --direction Outbound --access Allow --protocol Tcp --source-address-prefixes "*" --source-port-ranges "*" --destination-address-prefixes "10.1.1.0/24" --destination-port-ranges "1433"
```

### Spoke1 DB NSG Creation
```powershell
az network nsg create --resource-group rg-learning-spoke1 --name nsg-spoke1-db --location canadacentral --tags Environment="Dev" ServiceOwner="admin@example.com" SolutionName="AZ104-NSG-Lab" BCHOCostCenter="CC-0001" OwnerBCHO="Platform-Team" Classification="Internal"

az network nsg rule create --resource-group rg-learning-spoke1 --nsg-name nsg-spoke1-db --name "Allow-SQL-From-App-Subnet" --priority 100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "10.1.0.0/24" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "1433"

az network nsg rule create --resource-group rg-learning-spoke1 --nsg-name nsg-spoke1-db --name "Allow-SSH-From-Hub" --priority 110 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "10.0.0.0/24" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "22"

az network nsg rule create --resource-group rg-learning-spoke1 --nsg-name nsg-spoke1-db --name "Deny-All-Other-Inbound" --priority 4000 --direction Inbound --access Deny --protocol "*" --source-address-prefixes "*" --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "*"
```

### Spoke2 App & DB NSG Creation (Same pattern as Spoke1)
```powershell
# Spoke2 App NSG
az network nsg create --resource-group rg-learning-spoke2 --name nsg-spoke2-app --location canadacentral --tags Environment="Dev" ServiceOwner="admin@example.com" SolutionName="AZ104-NSG-Lab" BCHOCostCenter="CC-0001" OwnerBCHO="Platform-Team" Classification="Internal"

az network nsg rule create --resource-group rg-learning-spoke2 --nsg-name nsg-spoke2-app --name "Allow-HTTPS-Inbound" --priority 100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "Internet" --destination-port-ranges "443"

# Spoke2 DB NSG  
az network nsg create --resource-group rg-learning-spoke2 --name nsg-spoke2-db --location canadacentral --tags Environment="Dev" ServiceOwner="admin@example.com" SolutionName="AZ104-NSG-Lab" BCHOCostCenter="CC-0001" OwnerBCHO="Platform-Team" Classification="Internal"

az network nsg rule create --resource-group rg-learning-spoke2 --nsg-name nsg-spoke2-db --name "Allow-SQL-From-App-Subnet" --priority 100 --direction Inbound --access Allow --protocol Tcp --source-address-prefixes "10.2.0.0/24" --destination-port-ranges "1433"
```

### Attach NSGs to Subnets
```powershell
# Hub
az network vnet subnet update --resource-group rg-learning-hub --vnet-name vnet-hub --name subnet-hub-central --network-security-group nsg-hub-central

# Spoke1
az network vnet subnet update --resource-group rg-learning-spoke1 --vnet-name vnet-spoke1 --name subnet-spoke1-app --network-security-group nsg-spoke1-app

az network vnet subnet update --resource-group rg-learning-spoke1 --vnet-name vnet-spoke1 --name subnet-spoke1-db --network-security-group nsg-spoke1-db

# Spoke2
az network vnet subnet update --resource-group rg-learning-spoke2 --vnet-name vnet-spoke2 --name subnet-spoke2-app --network-security-group nsg-spoke2-app

az network vnet subnet update --resource-group rg-learning-spoke2 --vnet-name vnet-spoke2 --name subnet-spoke2-db --network-security-group nsg-spoke2-db
```

### Verification Commands
```powershell
# List all NSGs
az network nsg list --query "[?starts_with(name, 'nsg-')].{Name:name, ResourceGroup:resourceGroup}" -o table

# View NSG rules
az network nsg rule list --resource-group rg-learning-spoke1 --nsg-name nsg-spoke1-db -o table

# Verify subnet NSG attachment
az network vnet subnet show --resource-group rg-learning-spoke1 --vnet-name vnet-spoke1 --name subnet-spoke1-db --query networkSecurityGroup.id
```

---

## NSG Strategy Summary

| Subnet | NSG Name | Key Rules | Purpose |
|--------|----------|-----------|---------|
| subnet-hub-central | nsg-hub-central | Allow 443 OUT, Deny all IN | Hub is protected, can fetch updates |
| subnet-spoke1-app | nsg-spoke1-app | Allow 443 IN, Allow 1433 OUT to 10.1.1.0/24 | Web tier accepts traffic, talks to local DB |
| subnet-spoke1-db | nsg-spoke1-db | Allow 1433 from 10.1.0.0/24, Deny all else | Database locked down, app tier ONLY |
| subnet-spoke2-app | nsg-spoke2-app | Allow 443 IN, Allow 1433 OUT to 10.2.1.0/24 | Web tier, isolated from Spoke1 |
| subnet-spoke2-db | nsg-spoke2-db | Allow 1433 from 10.2.0.0/24, Deny all else | Database locked down, app tier ONLY |

---

## Key Metrics

- **Total NSGs:** 5 (1 hub + 2 per spoke)
- **Total Custom Rules:** 15+
- **Subnets Protected:** 5 (all Lab-003 subnets)
- **Cost:** $0 (NSGs are free)
- **Time to Execute:** 120 minutes
- **Concepts Mastered:**
  - ✅ NSG AND Logic (subnet + NIC both evaluated)
  - ✅ Rule Priority Order (lower number = higher priority)
  - ✅ Effective Security Rules (what actually applies)
  - ✅ Deny by Default (rule 65500 blocks unmatched traffic)
  - ✅ Stateful Filtering (return traffic auto-allowed)
  - ✅ Service Tags (Internet, VirtualNetwork)
  - ✅ Micro-segmentation (specific subnet restrictions)

---

## NSG Rule Evaluation Quick Facts

1. **Priority Order:** Lower number = evaluated first (100 beats 200)
2. **First Match Wins:** Once a rule matches, stop evaluating
3. **AND Logic:** Subnet NSG AND NIC NSG (both must allow)
4. **Deny by Default:** No matching rule = Priority 65500 DENY
5. **Stateful:** Outbound allowed = return traffic auto-allowed
6. **Port Specificity:** Port numbers must match exactly (1433 ≠ 3306)

---

## Lab-003 Infrastructure Preserved

This lab **attaches NSGs** to existing Lab-003 infrastructure:
- ✅ VNets unchanged (vnet-hub, vnet-spoke1, vnet-spoke2)
- ✅ Subnets unchanged (all 5 subnets still exist)
- ✅ Peerings unchanged (hub↔spoke1, hub↔spoke2)
- ✅ NSGs added as security layer (new resources)

**Result:** Lab-003 now has Layer 4 security (NSGs) + Layer 3 routing (peerings)

---

## Break-Fix Scenarios Completed

1. ✅ **Conflicting Rules:** Priority 50 DENY vs Priority 100 ALLOW
   - Learning: Lower priority number wins
   - Fix: Delete conflicting rule or change priority

2. ✅ **AND Logic Failure:** Subnet NSG allows, NIC NSG empty
   - Learning: Both must allow for traffic to flow
   - Fix: Add rule to NIC NSG or remove NIC NSG

3. ✅ **Wrong Port Number:** Rule for 3306, traffic uses 1433
   - Learning: Port must match exactly
   - Fix: Correct port number in rule

---

## Exam Preparation Checklist

After Lab-004, you should be able to answer:

- ✅ "Which NSG rule takes precedence: Priority 50 or 100?" → 50
- ✅ "Subnet NSG allows traffic, NIC NSG blocks. Traffic is...?" → Blocked (AND logic)
- ✅ "No matching rule found. Traffic is...?" → Denied (default deny 65500)
- ✅ "How do you see combined NSG rules?" → `az network nic show-effective-nsg`
- ✅ "How do you troubleshoot blocked traffic?" → Check effective rules, verify AND logic
- ✅ "Database should only accept from app tier. Which NSG?" → DB subnet NSG with source restriction
- ✅ "How do responses reach back if inbound is blocked?" → Stateful filtering auto-allows
- ✅ "Why can't Spoke1 reach Spoke2 database?" → No allow rule for 10.2.1.0/24 in Spoke1 NSG

---

## Next Lab (Lab-005)

**Lab-005: User-Defined Routes (UDRs) + Azure Firewall**

After NSGs lock things down, Lab-005 will:
- Force spoke-to-spoke traffic through hub
- Deploy Azure Firewall in hub
- Create routing policies for transitive routing
- Test Spoke1 → Hub Firewall → Spoke2 connectivity

Time: 150 minutes | Cost: $10-15 | Difficulty: HARD

---

**Lab-004 Complete!**

Date: Aug 27, 2026 | Duration: 120 minutes | Cost: $0
