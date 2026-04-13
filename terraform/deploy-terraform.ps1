# ============================================================================
# deploy-terraform.ps1
# Deploys the Terraform infrastructure and records timing
# Usage: powershell -ExecutionPolicy Bypass -File .\deploy-terraform.ps1
# ============================================================================

$Region = "eu-central-1"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Terraform Deployment" -ForegroundColor Cyan
Write-Host "  Region: $Region" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Init
Write-Host "[1/4] Initializing Terraform..." -ForegroundColor Yellow
terraform init -input=false
if ($LASTEXITCODE -ne 0) {
    Write-Host "terraform init FAILED." -ForegroundColor Red
    exit 1
}
Write-Host "Init complete." -ForegroundColor Green
Write-Host ""

# Validate
Write-Host "[2/4] Validating configuration..." -ForegroundColor Yellow
terraform validate
if ($LASTEXITCODE -ne 0) {
    Write-Host "Validation FAILED." -ForegroundColor Red
    exit 1
}
Write-Host "Validation passed." -ForegroundColor Green
Write-Host ""

# Plan
Write-Host "[3/4] Planning..." -ForegroundColor Yellow
$PlanStart = Get-Date
terraform plan -out=tfplan -input=false
$PlanEnd = Get-Date
$PlanDuration = $PlanEnd - $PlanStart
Write-Host "Plan time: $([math]::Round($PlanDuration.TotalSeconds, 2))s" -ForegroundColor Cyan
Write-Host ""

# Apply
Write-Host "[4/4] Applying..." -ForegroundColor Yellow
$StartTime = Get-Date
Write-Host "Start time: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "(This will take 10-20 minutes due to RDS Multi-AZ)" -ForegroundColor DarkGray
Write-Host ""

terraform apply -auto-approve -input=false tfplan

$EndTime = Get-Date
$Duration = $EndTime - $StartTime

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  DEPLOYMENT SUCCESSFUL" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Plan time:  $([math]::Round($PlanDuration.TotalSeconds, 2))s" -ForegroundColor Cyan
    Write-Host "Apply time: $($Duration.Minutes)m $($Duration.Seconds)s ($([math]::Round($Duration.TotalSeconds, 2)) seconds)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Outputs:" -ForegroundColor Yellow
    terraform output
} else {
    Write-Host ""
    Write-Host "DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "Duration before failure: $($Duration.Minutes)m $($Duration.Seconds)s"
}

# Cleanup plan file
Remove-Item tfplan -ErrorAction SilentlyContinue
