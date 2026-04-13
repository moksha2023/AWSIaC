# ============================================================================
# run-all-trials.ps1 (Terraform version)
# Automated trial runner for Terraform performance testing
# Runs 5 deployment trials, 3 update trials, 5 destruction trials
# Logs all timing data to CSV
# ============================================================================
# USAGE:
#   powershell -ExecutionPolicy Bypass -File .\run-all-trials.ps1
# ============================================================================

$CsvFile = "tf-trial-results.csv"

# Initialize CSV
if (-not (Test-Path $CsvFile)) {
    "Tool,Trial,Operation,StartTime,EndTime,DurationSeconds,Status,Notes" | Out-File $CsvFile -Encoding utf8
}

function Log-Trial {
    param($Tool, $Trial, $Operation, $Start, $End, $Status, $Notes)
    $Duration = ($End - $Start).TotalSeconds
    $Line = "$Tool,$Trial,$Operation,$($Start.ToString('yyyy-MM-dd HH:mm:ss')),$($End.ToString('yyyy-MM-dd HH:mm:ss')),$([math]::Round($Duration,2)),$Status,$Notes"
    $Line | Out-File $CsvFile -Append -Encoding utf8
    Write-Host "  => $Operation Trial $Trial : $([math]::Round($Duration,2))s [$Status]" -ForegroundColor $(if ($Status -eq "SUCCESS") {"Green"} else {"Red"})
}

function Ensure-Init {
    if (-not (Test-Path ".terraform")) {
        Write-Host "  Running terraform init..." -ForegroundColor DarkGray
        terraform init -input=false | Out-Null
    }
}

function Clean-State {
    # Remove local state and plan files for a clean slate
    Remove-Item -Path "terraform.tfstate" -ErrorAction SilentlyContinue
    Remove-Item -Path "terraform.tfstate.backup" -ErrorAction SilentlyContinue
    Remove-Item -Path "tfplan" -ErrorAction SilentlyContinue
}

# ============================================================================
# DEPLOYMENT TRIALS (5x)
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  TERRAFORM DEPLOYMENT TRIALS (5 trials)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

Ensure-Init

for ($i = 1; $i -le 5; $i++) {
    Write-Host ""
    Write-Host "--- Deploy Trial $i/5 ---" -ForegroundColor Yellow

    # Ensure clean slate — destroy if anything exists
    $StateCheck = terraform state list 2>$null
    if ($StateCheck) {
        Write-Host "  Resources exist, destroying first..." -ForegroundColor DarkGray
        terraform destroy -auto-approve -input=false | Out-Null
        Start-Sleep -Seconds 10
    }
    Clean-State
    Ensure-Init

    # Plan
    $PlanStart = Get-Date
    terraform plan -out=tfplan -input=false | Out-Null
    $PlanEnd = Get-Date
    $PlanDuration = ($PlanEnd - $PlanStart).TotalSeconds
    Log-Trial "Terraform" $i "Plan" $PlanStart $PlanEnd "SUCCESS" ""

    # Apply
    $Start = Get-Date
    Write-Host "  Deploying... (started $($Start.ToString('HH:mm:ss')))" -ForegroundColor DarkGray

    terraform apply -auto-approve -input=false tfplan 2>$null

    $End = Get-Date
    $Status = if ($LASTEXITCODE -eq 0) {"SUCCESS"} else {"FAILED"}
    Log-Trial "Terraform" $i "Deploy" $Start $End $Status ""

    Remove-Item tfplan -ErrorAction SilentlyContinue

    # If last deploy trial, keep infra alive for update trials
    if ($i -lt 5) {
        Write-Host "  Destroying for next trial..." -ForegroundColor DarkGray
        terraform destroy -auto-approve -input=false | Out-Null
        Start-Sleep -Seconds 10
        Clean-State
        Ensure-Init
    }
}

# ============================================================================
# UPDATE TRIALS (3x)
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host "  TERRAFORM UPDATE TRIALS (3 trials)" -ForegroundColor Magenta
Write-Host "  Change: asg_max_size 4 -> 6 -> 4 -> 6 -> 4 -> 6" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta

# Ensure infra exists
$StateCheck = terraform state list 2>$null
if (-not $StateCheck) {
    Write-Host "  No infrastructure found. Deploying first..." -ForegroundColor Yellow
    terraform plan -out=tfplan -input=false | Out-Null
    terraform apply -auto-approve -input=false tfplan | Out-Null
    Remove-Item tfplan -ErrorAction SilentlyContinue
}

for ($i = 1; $i -le 3; $i++) {
    Write-Host ""
    Write-Host "--- Update Trial $i/3 ---" -ForegroundColor Yellow

    # Update: max_size -> 6
    $Start = Get-Date
    Write-Host "  Updating asg_max_size to 6... (started $($Start.ToString('HH:mm:ss')))" -ForegroundColor DarkGray

    terraform apply -auto-approve -input=false -var="asg_max_size=6" 2>$null

    $End = Get-Date
    $Status = if ($LASTEXITCODE -eq 0) {"SUCCESS"} else {"FAILED"}
    Log-Trial "Terraform" $i "Update" $Start $End $Status "asg_max_size 4->6"

    # Revert: max_size -> 4
    Write-Host "  Reverting asg_max_size to 4..." -ForegroundColor DarkGray
    terraform apply -auto-approve -input=false -var="asg_max_size=4" 2>$null
    Write-Host "  Reverted. Ready for next trial." -ForegroundColor DarkGray
}

# ============================================================================
# DESTRUCTION TRIALS (5x)
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Red
Write-Host "  TERRAFORM DESTRUCTION TRIALS (5 trials)" -ForegroundColor Red
Write-Host "================================================================" -ForegroundColor Red

for ($i = 1; $i -le 5; $i++) {
    Write-Host ""
    Write-Host "--- Destroy Trial $i/5 ---" -ForegroundColor Yellow

    # Ensure infra exists
    $StateCheck = terraform state list 2>$null
    if (-not $StateCheck) {
        Write-Host "  No infrastructure. Deploying first..." -ForegroundColor DarkGray
        Ensure-Init
        terraform plan -out=tfplan -input=false | Out-Null
        terraform apply -auto-approve -input=false tfplan | Out-Null
        Remove-Item tfplan -ErrorAction SilentlyContinue
    }

    # Destroy
    $Start = Get-Date
    Write-Host "  Destroying... (started $($Start.ToString('HH:mm:ss')))" -ForegroundColor DarkGray

    terraform destroy -auto-approve -input=false 2>$null

    $End = Get-Date
    $Status = if ($LASTEXITCODE -eq 0) {"SUCCESS"} else {"FAILED"}
    Log-Trial "Terraform" $i "Destroy" $Start $End $Status ""

    Start-Sleep -Seconds 10
    Clean-State
    Ensure-Init
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  ALL TERRAFORM TRIALS COMPLETE" -ForegroundColor Cyan
Write-Host "  Results saved to: $CsvFile" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Import-Csv $CsvFile | Format-Table -AutoSize
