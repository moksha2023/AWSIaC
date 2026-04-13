# ============================================================================
# destroy-terraform.ps1
# Destroys the Terraform infrastructure and records timing
# Usage: powershell -ExecutionPolicy Bypass -File .\destroy-terraform.ps1
# ============================================================================

Write-Host "============================================" -ForegroundColor Red
Write-Host "  Terraform DESTRUCTION" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Red
Write-Host ""

$StartTime = Get-Date
Write-Host "Start time: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host ""

terraform destroy -auto-approve -input=false

$EndTime = Get-Date
$Duration = $EndTime - $StartTime

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  DESTRUCTION COMPLETE" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Start:    $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "End:      $($EndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "Duration: $($Duration.Minutes)m $($Duration.Seconds)s ($([math]::Round($Duration.TotalSeconds, 2)) seconds)" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "DESTRUCTION MAY HAVE FAILED" -ForegroundColor Red
    Write-Host "Check AWS console for remaining resources."
}
