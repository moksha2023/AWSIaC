# ============================================================================
# destroy-stack.ps1
# Destroys the CloudFormation stack and records timing
# Usage: .\destroy-stack.ps1
# ============================================================================

$StackName = "thesis-cf-stack"
$Region = "eu-central-1"

Write-Host "============================================" -ForegroundColor Red
Write-Host "  CloudFormation DESTRUCTION" -ForegroundColor Red
Write-Host "  Stack: $StackName" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Red
Write-Host ""

# Check stack exists
$StackStatus = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query "Stacks[0].StackStatus" `
    --output text 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Stack '$StackName' does not exist or is already deleted." -ForegroundColor Yellow
    exit 0
}

Write-Host "Current stack status: $StackStatus"
Write-Host ""

# Empty S3 buckets first (required before deletion)
Write-Host "[1/3] Emptying S3 buckets..." -ForegroundColor Yellow

$AccountId = aws sts get-caller-identity --query Account --output text
$AppBucket = "thesis-cf-app-assets-$AccountId"
$LogsBucket = "thesis-cf-logs-$AccountId"

# Suppress errors if buckets don't exist or are already empty
aws s3 rm s3://$AppBucket --recursive 2>$null
aws s3 rm s3://$LogsBucket --recursive 2>$null

# Also remove versioned objects from app bucket
aws s3api list-object-versions --bucket $AppBucket --query "Versions[].{Key:Key,VersionId:VersionId}" --output json 2>$null | ConvertFrom-Json | ForEach-Object {
    if ($_) {
        aws s3api delete-object --bucket $AppBucket --key $_.Key --version-id $_.VersionId 2>$null
    }
}
aws s3api list-object-versions --bucket $AppBucket --query "DeleteMarkers[].{Key:Key,VersionId:VersionId}" --output json 2>$null | ConvertFrom-Json | ForEach-Object {
    if ($_) {
        aws s3api delete-object --bucket $AppBucket --key $_.Key --version-id $_.VersionId 2>$null
    }
}

Write-Host "S3 buckets emptied." -ForegroundColor Green
Write-Host ""

# Delete stack with timing
Write-Host "[2/3] Deleting stack..." -ForegroundColor Yellow
$StartTime = Get-Date
Write-Host "Start time: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

aws cloudformation delete-stack `
    --stack-name $StackName `
    --region $Region

# Wait for completion
Write-Host ""
Write-Host "[3/3] Waiting for deletion to complete..." -ForegroundColor Yellow

aws cloudformation wait stack-delete-complete `
    --stack-name $StackName `
    --region $Region

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
