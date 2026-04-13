# ============================================================================
# CloudFormation Qualitative Assessment
# Fill this out AFTER completing all trials (Day 23)
# ============================================================================

## Date: ___________
## Time Spent on Full Implementation: _____ hours total

---

## 1. CODE QUALITY

### Line Count
```powershell
# Run this in your cloudformation/ folder:
Get-Content three-tier-webapp.yaml | Measure-Object -Line
# Also get file size:
Get-Item three-tier-webapp.yaml | Select-Object Name, Length
```

- **Total Lines of Code:** _____
- **Total File Size (KB):** _____
- **Number of Files:** 1 (single template)
- **Resources Defined:** _____ (count from Resources section)
- **Parameters Defined:** _____
- **Outputs Defined:** _____

### Readability Rating (1-10): _____
Justification:


### Code Organization Rating (1-10): _____
Justification:


### Repeated/Boilerplate Code:
Examples:


---

## 2. DOCUMENTATION & ECOSYSTEM

### AWS CloudFormation Docs Rating (1-10): _____
Notes:


### Useful Examples Found (count): _____
### Community Resources Quality (1-10): _____
### Documentation Gaps Noticed:


---

## 3. ERROR HANDLING

### Error Messages Encountered During Implementation:

| # | Error Message (summary) | Clarity (1-10) | Time to Resolve | Resolution |
|---|------------------------|----------------|-----------------|------------|
| 1 |                        |                |                 |            |
| 2 |                        |                |                 |            |
| 3 |                        |                |                 |            |
| 4 |                        |                |                 |            |
| 5 |                        |                |                 |            |

### Overall Error Clarity Rating (1-10): _____
### Debugging Experience Rating (1-10): _____
Notes:


---

## 4. STATE MANAGEMENT

### How is state managed?
AWS-managed (no local state file)

### State Visibility Rating (1-10): _____
### Drift Detection Test:
- Made manual change to: _____
- Drift detected? Yes / No
- Detection time: _____
- Detection accuracy: _____

### Rollback Test:
- Triggered rollback by: _____
- Rollback successful? Yes / No
- Rollback time: _____
- Rollback completeness: _____

---

## 5. OPERATIONAL EXPERIENCE

### Change Set Usefulness (1-10): _____
Notes:


### Stack Events Clarity (1-10): _____
Notes:


### Overall Workflow Rating (1-10): _____

---

## 6. IMPLEMENTATION CHALLENGES

### Challenge 1:
- **What:** 
- **Impact:** 
- **Resolution:** 
- **Time Lost:** 

### Challenge 2:
- **What:** 
- **Impact:** 
- **Resolution:** 
- **Time Lost:** 

### Challenge 3:
- **What:** 
- **Impact:** 
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

### Would you recommend CloudFormation for a new AWS project? Why/why not?


### Key insight for thesis:


---

## 8. SCREENSHOTS TAKEN

| # | Description | Filename | For Main Body or Appendix? |
|---|-------------|----------|---------------------------|
| 1 | VPC Console | | |
| 2 | Subnets | | |
| 3 | Route Tables | | |
| 4 | NAT Gateway | | |
| 5 | Security Groups | | |
| 6 | IAM Role | | |
| 7 | RDS Instance | | |
| 8 | S3 Buckets | | |
| 9 | ALB Console | | |
| 10 | ALB Healthy Targets | | |
| 11 | EC2 Instances Running | | |
| 12 | Stack Events | | |
| 13 | Stack Outputs | | |
| 14 | Deployment Timing | | |
| 15 | Destruction Timing | | |
| 16 | Change Set Preview | | |
| 17 | Update Timing | | |
| 18 | Cost Explorer | | |
| 19 | Error Example (if any) | | |
| 20 | Working App in Browser | | |

**Main body screenshots (6-8 max):** Pick the most impactful ones
**Everything else -> Appendix C**
