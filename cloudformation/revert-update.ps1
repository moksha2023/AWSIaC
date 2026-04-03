# ============================================================================
# revert-update.ps1
# Reverts ASGMaxSize back to 4 (for repeated update trials)
# Usage: .\revert-update.ps1
# ============================================================================

$StackName = "thesis-cf-stack"
$TemplateFile = "three-tier-webapp.yaml"
$Region = "eu-central-1"

Write-Host "Reverting ASGMaxSize back to 4..." -ForegroundColor Yellow

aws cloudformation update-stack `
    --stack-name $StackName `
    --template-body file://$TemplateFile `
    --capabilities CAPABILITY_NAMED_IAM `
    --parameters ParameterKey=ASGMaxSize,ParameterValue=4 `
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

aws cloudformation wait stack-update-complete `
    --stack-name $StackName `
    --region $Region

if ($LASTEXITCODE -eq 0) {
    Write-Host "Reverted successfully. Ready for next update trial." -ForegroundColor Green
} else {
    Write-Host "Revert failed. Check console." -ForegroundColor Red
}
