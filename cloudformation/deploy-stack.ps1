# ============================================================================
# deploy-stack.ps1
# Deploys the CloudFormation stack and records timing
# Usage: .\deploy-stack.ps1
# ============================================================================

$StackName = "thesis-cf-stack"
$TemplateFile = "three-tier-webapp.yaml"
$Region = "eu-central-1"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  CloudFormation Deployment" -ForegroundColor Cyan
Write-Host "  Stack: $StackName" -ForegroundColor Cyan
Write-Host "  Region: $Region" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Validate template first
Write-Host "[1/3] Validating template..." -ForegroundColor Yellow
aws cloudformation validate-template `
    --template-body file://$TemplateFile `
    --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "Template validation FAILED. Fix errors before deploying." -ForegroundColor Red
    exit 1
}
Write-Host "Template valid." -ForegroundColor Green
Write-Host ""

# Deploy with timing
Write-Host "[2/3] Deploying stack..." -ForegroundColor Yellow
$StartTime = Get-Date
Write-Host "Start time: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host ""

aws cloudformation create-stack `
    --stack-name $StackName `
    --template-body file://$TemplateFile `
    --capabilities CAPABILITY_NAMED_IAM `
    --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "Stack creation command FAILED." -ForegroundColor Red
    exit 1
}

# Wait for completion
Write-Host ""
Write-Host "[3/3] Waiting for stack creation to complete..." -ForegroundColor Yellow
Write-Host "(This will take 10-20 minutes due to RDS Multi-AZ)" -ForegroundColor DarkGray
Write-Host ""

aws cloudformation wait stack-create-complete `
    --stack-name $StackName `
    --region $Region

$EndTime = Get-Date
$Duration = $EndTime - $StartTime

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  DEPLOYMENT SUCCESSFUL" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Start:    $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "End:      $($EndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "Duration: $($Duration.Minutes)m $($Duration.Seconds)s ($([math]::Round($Duration.TotalSeconds, 2)) seconds)" -ForegroundColor Cyan
    Write-Host ""

    # Show outputs
    Write-Host "Stack Outputs:" -ForegroundColor Yellow
    aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" `
        --output table
} else {
    Write-Host ""
    Write-Host "DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "Duration before failure: $($Duration.Minutes)m $($Duration.Seconds)s"
    Write-Host ""
    Write-Host "Check events:" -ForegroundColor Yellow
    aws cloudformation describe-stack-events `
        --stack-name $StackName `
        --region $Region `
        --query "StackEvents[?ResourceStatus=='CREATE_FAILED'].[LogicalResourceId,ResourceStatusReason]" `
        --output table
}
