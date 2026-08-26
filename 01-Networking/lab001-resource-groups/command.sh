## 🔨 Commands Used

```powershell
# Create resource groups with tags (BCH COMPLIANT - canadacentral + all 6 tags mandatory)
az group create --name rg-learning-hub --location canadacentral --tags Environment=Dev ServiceOwner="organizational.owner@company.com" SolutionName="AZ104-Learning-Hub" BCHOCostCenter="CC-0001" OwnerBCHO="Platform-Team" Classification="Internal"

az group create --name rg-learning-spoke1 --location canadacentral --tags Environment=Dev ServiceOwner="organizational.owner@company.com" SolutionName="AZ104-Learning-Spoke1" BCHOCostCenter="CC-0001" OwnerBCHO="Platform-Team" Classification="Internal"

az group create --name rg-learning-spoke2 --location canadacentral --tags Environment=Dev ServiceOwner="organizational.owner@company.com" SolutionName="AZ104-Learning-Spoke2" BCHOCostCenter="CC-0001" OwnerBCHO="Platform-Team" Classification="Internal"

# List all resource groups
az group list -o table

# Query with JMESPath filter (by Environment tag - must match 'Dev' from Step 1)
az group list --query "[?tags.Environment=='Dev'].{Name:name, Location:location, Environment:tags.Environment, ServiceOwner:tags.ServiceOwner}" -o table

# Show specific resource group with all tags
az group show --name rg-learning-hub --query "{Name:name, Location:location, Tags:tags}"

# Export to JSON for analysis (matching Environment=Dev from Step 1)
az group list --query "[?tags.Environment=='Dev']" > resource-groups.json

# Update tags (removing one - BREAKING SCENARIO - this violates BCH policy by removing required tag)
az group update --name rg-learning-hub --set tags.BCHOCostCenter=null

# Fix tags (restore all required tags)
az group update --name rg-learning-hub --tags Environment=Dev ServiceOwner="organizational.owner@company.com" SolutionName="AZ104-Learning-Hub" BCHOCostCenter="CC-0001" OwnerBCHO="Platform-Team" Classification="Internal"
```