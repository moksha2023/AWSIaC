# ============================================================================
# Terraform Qualitative Assessment
# Fill this out AFTER completing all trials
# ============================================================================

## Date: ___________
## Time Spent on Full Implementation: _____ hours total

---

## 1. CODE QUALITY

### Metrics
```powershell
# Run these in your terraform/ folder:
Get-ChildItem *.tf | ForEach-Object { Write-Host "$($_.Name): $((Get-Content $_.FullName | Measure-Object -Line).Lines) lines" }
Get-ChildItem *.tf | Measure-Object -Property Length -Sum | Select-Object Count, @{N='TotalKB';E={[math]::Round($_.Sum/1KB,2)}}
Select-String -Path *.tf -Pattern 'resource "aws_' | Measure-Object
```

- **Total Lines of Code:** _____
- **Total File Size (KB):** _____
- **Number of Files:** _____
- **Resources Defined:** _____
- **Data Sources Used:** _____

### Readability Rating (1-10): _____
Justification:

### Code Organization Rating (1-10): _____
Justification:

### Use of count/for_each (DRY code):

### Comparison to CloudFormation Code:

---

## 2. DOCUMENTATION & ECOSYSTEM

### Terraform/HashiCorp Docs Rating (1-10): _____
### Compared to AWS CloudFormation Docs:
### Terraform Registry Usefulness (1-10): _____
### Community Resources Quality (1-10): _____

---

## 3. ERROR HANDLING

### Error Messages Encountered:

| # | Error Message (summary) | Clarity (1-10) | Time to Resolve | Resolution |
|---|------------------------|----------------|-----------------|------------|
| 1 |                        |                |                 |            |
| 2 |                        |                |                 |            |
| 3 |                        |                |                 |            |

### Overall Error Clarity Rating (1-10): _____
### Compared to CloudFormation Errors:

---

## 4. STATE MANAGEMENT

### terraform.tfstate file size: _____ KB
### State Complexity Rating (1-10, 10=very complex): _____
### Compared to CloudFormation (AWS-managed):

---

## 5. TERRAFORM-SPECIFIC FEATURES

### terraform plan Usefulness (1-10): _____
### terraform fmt Usefulness (1-10): _____
### terraform validate Usefulness (1-10): _____
### HCL Syntax vs YAML:

---

## 6. IMPLEMENTATION CHALLENGES

### Challenge 1:
- **What:**
- **Resolution:**
- **Time Lost:**

### Challenge 2:
- **What:**
- **Resolution:**
- **Time Lost:**

---

## 7. OVERALL IMPRESSIONS

### What was EASY?
1.
2.
3.

### What was HARD?
1.
2.
3.

### What SURPRISED you?
1.
2.

### Compared to CloudFormation, Terraform was:
- Better at:
- Worse at:
- Similar in:

### Would you recommend Terraform? Why/why not?

### Key insight for thesis:

---

## 8. SCREENSHOTS TAKEN

| # | Description | For Main Body or Appendix? |
|---|-------------|---------------------------|
| 1 | terraform init output | |
| 2 | terraform plan output | |
| 3 | terraform apply output | |
| 4 | Project file structure | |
| 5 | VPC in console | |
| 6 | EC2 instances running | |
| 7 | ALB healthy targets | |
| 8 | RDS available | |
| 9 | Browser - Terraform Deployment page | |
| 10 | terraform.tfstate file | |
| 11 | terraform destroy output | |
| 12 | tf-trial-results.csv | |
