```markdown
# Lab 001: Resource Group Management & Tagging

**Domain:** Infrastructure Management (Foundation)  
**Exam Weight:** Foundational (applies to all domains)  
**Difficulty:** Beginner  
**Time Required:** 1 hour  
**Cost:** $0 (Resource groups are FREE)  
**Date Completed:** [Today's date]  
**Environment:** BCH (canadacentral, 6 mandatory tags)

---

## 🎯 Objective

Master resource group creation, tagging strategies, and understand why tags are critical for cost management and governance in Azure.

Real-world relevance: Every Azure deployment starts with resource groups. Proper tagging is essential for cost tracking, compliance, and resource organization.

---

## 🏗️ What I Built

- 3 resource groups in canadacentral (BCH policy compliant)
- Tagged with all 6 mandatory BCH tags (Environment=Dev, ServiceOwner, SolutionName, BCHOCostCenter, OwnerBCHO, Classification)
- Learned to query and filter resource groups using JMESPath
- Documented configuration in exported JSON

---



---

## 💥 What I Broke

Removed the `BCHOCostCenter` tag to simulate a compliance violation.

```powershell
az group update --name rg-learning-hub --set tags.BCHOCostCenter=null
```

**Result:** Resource group no longer meets BCH tagging requirements. This would violate organizational policy.

---

## 🔍 How I Diagnosed It

```powershell
# Check tags on resource group
az group show --name rg-learning-hub --query tags
```

**Result:** Confirmed `CostCenter` tag was missing.

---

## ✅ How I Fixed It

```powershell
# Restore all required tags (match BCH policy - all 6 tags mandatory)
az group update --name rg-learning-hub --tags Environment=Dev ServiceOwner="organizational.owner" SolutionName="AZ104-Learning-Hub" BCHOCostCenter="CC-0000" OwnerBCHO="Platform-Team" Classification="Internal"

# Verify
az group show --name rg-learning-hub --query tags
```

---

## 📄 ARM Template Analysis

**Key JSON Properties:**

```json
{
  "id": "/subscriptions/<sub-id>/resourceGroups/rg-learning-hub",
  "name": "rg-learning-hub",
  "location": "canadacentral",
  "tags": {
    "Environment": "Dev",
    "ServiceOwner": "organizational.owner",
    "SolutionName": "AZ104-Learning-Hub",
    "BCHOCostCenter": "CC-0000",
    "OwnerBCHO": "Platform-Team",
    "Classification": "Internal"
  },
  "properties": {
    "provisioningState": "Succeeded"
  }
}
```

**Insights:**
- `id`: Full Azure Resource Manager path - used in scripts and policies
- `tags`: Key-value pairs - case-sensitive, used for cost allocation
- `provisioningState`: "Succeeded" means RG is ready for resource deployment

---

## 🧠 Key Takeaways

1. **Resource groups are logical containers** - Not physical locations. Resources can span multiple regions but RG has one location for metadata.

2. **Tags are metadata only** - They don't affect functionality but are CRITICAL for cost management and governance.

3. **Tags aren't inherited** - Resource group tags don't automatically apply to resources inside. Must tag resources separately or use Azure Policy to enforce.

4. **JMESPath queries are powerful** - The `--query` parameter filters JSON output. Essential skill for CLI automation.

5. **Compliance requires automation** - Without Azure Policy, there's nothing stopping someone from removing tags. Manual processes don't scale.

---

## 📝 Exam Connection

**AZ-104 tests this indirectly:**
- Resource organization (20-25% of exam - Identity & Governance domain)
- Cost management (appears across all domains)
- Azure Policy for tag enforcement (tested in governance section)

---

## 💰 Cost Impact

- Resource groups: **FREE**
- Tags: **FREE**
- Azure Policy (used to enforce tags): **FREE**

**Total lab cost:** $0

---

## 🚨 Common Gotchas

- ⚠️ **Deleting a resource group deletes ALL resources inside** - No undo button. Always verify contents first.
- ⚠️ **Tags don't inherit** - Many assume RG tags apply to child resources. They don't.
- ⚠️ **Tag limits** - 50 tags per resource/RG, names up to 512 chars, values up to 256 chars
- ⚠️ **Case-sensitive** - "Environment" ≠ "environment"

---

## 📚 Related Labs

- **Next:** Lab 002 - Virtual Network Basics
- **Advanced:** Lab 010 - Azure Policy for Tag Enforcement (Week 4)

---

## � Artifacts Created

**Exported JSON:**
- `resource-groups-exported.json` - Output from `az group list --query "[?tags.Environment=='Dev']"` showing all 3 RGs with their properties

**Screenshots (LOCAL USE ONLY - CONFIDENTIAL):**
- Screenshot 1: All 3 resource groups listed in portal (with BCH tags)
- Screenshot 2: rg-learning-hub details showing all 6 BCH tags
- Screenshot 3: rg-learning-hub after removing BCHOCostCenter (break scenario)
- Screenshot 4: rg-learning-hub after restoring tags (fix scenario)

**For Social Media (if creating content):**
- Create anonymized versions with generic naming (rg-demo-hub instead of BCH-specific names)
- Blur or redact cost centers, team names, and classification levels
- Focus on demonstrating the technical process, not the organizational details

**Documentation:**
- `commands.sh` - All commands typed in this lab (for reference)
- `README.md` - This detailed analysis
- `../exports/resource-groups.json` - Original JSON export from Step 3

**Portfolio Use:**
- All files kept in private GitHub repo for hiring managers and interviewers (who understand confidentiality)

---

## ✍️ Reflection

**What I learned:**
[Write your personal notes - what surprised you? what clicked?]

**How this helps consulting:**
[How would you explain this to a client?]

**Next steps:**
[What are you curious about? What do you want to explore next?]

---

**Lab completed:** [Today's date]  
**Commands typed:** [Count how many you typed]  
**Time spent:** [Actual time]

