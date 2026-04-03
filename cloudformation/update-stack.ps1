# ============================================================================
# update-stack.ps1
# Updates the CloudFormation stack (ASG MaxSize 4 -> 6) and records timing
# Usage: .\update-stack.ps1
# ============================================================================

$StackName = "thesis-cf-stack"
$TemplateFile = "three-tier-webapp.yaml"
$Region = "eu-central-1"

Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  CloudFormation UPDATE" -ForegroundColor Magenta
Write-Host "  Change: ASGMaxSize 4 -> 6" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""

# Create change set first (for thesis documentation)
Write-Host "[1/4] Creating change set for review..." -ForegroundColor Yellow

$ChangeSetName = "update-asg-max-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

aws cloudformation create-change-set `
    --stack-name $StackName `
    --template-body file://$TemplateFile `
    --capabilities CAPABILITY_NAMED_IAM `
    --change-set-name $ChangeSetName `
    --parameters ParameterKey=ASGMaxSize,ParameterValue=6 `
                 ParameterKey=EnvironmentName,UsePreviousValue=true `
                 ParameterKey=VpcCidr,UsePreviousValue=true `
                 ParameterKey=PublicSubnet1Cidr,UsePreviousValue=true `
                 ParameterKey=PublicSubnet2Cidr,UsePreviousValue=true `
                 ParameterKey=PrivateSubnet1Cidr,UsePreviousValue=true `
                 ParameterKey=PrivateSubnet2Cidr,UsePreviousValue=true `
                 ParameterKey=InstanceType,UsePreviousValue=true `
                 ParameterKey=DBInstanceClass,UsePreviousValue=true `
                 ParameterKey=DBName,UsePreviousValue=true `
                 ParameterKey=DBMasterUsername,UsePreviousValue=true `
                 ParameterKey=DBMasterPassword,UsePreviousValue=true `
                 ParameterKey=ASGDesiredCapacity,UsePreviousValue=true `
                 ParameterKey=ASGMinSize,UsePreviousValue=true `
                 ParameterKey=LatestAmiId,UsePreviousValue=true `
    --region $Region

Write-Host "Waiting for change set to be created..." -ForegroundColor DarkGray

aws cloudformation wait change-set-create-complete `
    --stack-name $StackName `
    --change-set-name $ChangeSetName `
    --region $Region

Write-Host ""
Write-Host "[2/4] Change set preview:" -ForegroundColor Yellow
aws cloudformation describe-change-set `
    --stack-name $StackName `
    --change-set-name $ChangeSetName `
    --region $Region `
    --query "Changes[*].ResourceChange.{Action:Action,Resource:LogicalResourceId,Type:ResourceType}" `
    --output table

Write-Host ""
Write-Host ">>> SCREENSHOT THIS CHANGE SET OUTPUT FOR THESIS <<<" -ForegroundColor Cyan
Write-Host ""

# Execute the change set with timing
Write-Host "[3/4] Executing change set..." -ForegroundColor Yellow
$StartTime = Get-Date
Write-Host "Start time: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"

aws cloudformation execute-change-set `
    --stack-name $StackName `
    --change-set-name $ChangeSetName `
    --region $Region

# Wait for update
Write-Host ""
Write-Host "[4/4] Waiting for update to complete..." -ForegroundColor Yellow

aws cloudformation wait stack-update-complete `
    --stack-name $StackName `
    --region $Region

$EndTime = Get-Date
$Duration = $EndTime - $StartTime

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  UPDATE SUCCESSFUL" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Start:    $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "End:      $($EndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "Duration: $($Duration.Minutes)m $($Duration.Seconds)s ($([math]::Round($Duration.TotalSeconds, 2)) seconds)" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "UPDATE FAILED" -ForegroundColor Red
    Write-Host "Duration: $($Duration.Minutes)m $($Duration.Seconds)s"
    aws cloudformation describe-stack-events `
        --stack-name $StackName `
        --region $Region `
        --query "StackEvents[?ResourceStatus=='UPDATE_FAILED'].[LogicalResourceId,ResourceStatusReason]" `
        --output table
}
