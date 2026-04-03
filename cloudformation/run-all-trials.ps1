# ============================================================================
# run-all-trials.ps1
# Automated trial runner for CloudFormation performance testing
# Runs 5 deployment trials, 3 update trials, 5 destruction trials
# Logs all timing data to CSV
# ============================================================================
# USAGE:
#   .\run-all-trials.ps1                    # Run everything
#   .\run-all-trials.ps1 -SkipDeploy        # Skip deploy trials
#   .\run-all-trials.ps1 -OnlyUpdate        # Only update trials (stack must exist)
# ============================================================================

param(
    [switch]$SkipDeploy,
    [switch]$OnlyUpdate
)

$StackName = "thesis-cf-stack"
$TemplateFile = "three-tier-webapp.yaml"
$Region = "eu-central-1"
$CsvFile = "cf-trial-results.csv"

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

function Wait-StackDeleted {
    Write-Host "  Waiting for DELETE_COMPLETE..." -ForegroundColor DarkGray
    aws cloudformation wait stack-delete-complete --stack-name $StackName --region $Region 2>$null
    # Extra safety wait
    Start-Sleep -Seconds 10
}

function Empty-S3Buckets {
    $AccountId = aws sts get-caller-identity --query Account --output text
    $AppBucket = "thesis-cf-app-assets-$AccountId"
    $LogsBucket = "thesis-cf-logs-$AccountId"
    
    aws s3 rm s3://$AppBucket --recursive 2>$null
    aws s3 rm s3://$LogsBucket --recursive 2>$null
    
    # Handle versioned objects
    $Versions = aws s3api list-object-versions --bucket $AppBucket --query "Versions[].{Key:Key,VersionId:VersionId}" --output json 2>$null | ConvertFrom-Json
    if ($Versions) {
        foreach ($v in $Versions) {
            aws s3api delete-object --bucket $AppBucket --key $v.Key --version-id $v.VersionId 2>$null
        }
    }
    $Markers = aws s3api list-object-versions --bucket $AppBucket --query "DeleteMarkers[].{Key:Key,VersionId:VersionId}" --output json 2>$null | ConvertFrom-Json
    if ($Markers) {
        foreach ($m in $Markers) {
            aws s3api delete-object --bucket $AppBucket --key $m.Key --version-id $m.VersionId 2>$null
        }
    }
}

# ============================================================================
# DEPLOYMENT TRIALS (5x)
# ============================================================================
if (-not $SkipDeploy -and -not $OnlyUpdate) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  DEPLOYMENT TRIALS (5 trials)" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan

    for ($i = 1; $i -le 5; $i++) {
        Write-Host ""
        Write-Host "--- Deploy Trial $i/5 ---" -ForegroundColor Yellow

        # Ensure clean slate
        $Exists = aws cloudformation describe-stacks --stack-name $StackName --region $Region 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Stack exists, destroying first..." -ForegroundColor DarkGray
            Empty-S3Buckets
            aws cloudformation delete-stack --stack-name $StackName --region $Region
            Wait-StackDeleted
        }

        # Deploy
        $Start = Get-Date
        Write-Host "  Deploying... (started $($Start.ToString('HH:mm:ss')))" -ForegroundColor DarkGray

        aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body file://$TemplateFile `
            --capabilities CAPABILITY_NAMED_IAM `
            --region $Region 2>$null

        aws cloudformation wait stack-create-complete `
            --stack-name $StackName `
            --region $Region

        $End = Get-Date
        $Status = if ($LASTEXITCODE -eq 0) {"SUCCESS"} else {"FAILED"}
        Log-Trial "CloudFormation" $i "Deploy" $Start $End $Status ""

        # If last deploy trial, keep stack alive for update trials
        if ($i -lt 5) {
            Write-Host "  Cleaning up for next trial..." -ForegroundColor DarkGray
            Empty-S3Buckets
            aws cloudformation delete-stack --stack-name $StackName --region $Region
            Wait-StackDeleted
        }
    }
}

# ============================================================================
# UPDATE TRIALS (3x)
# ============================================================================
if (-not $SkipDeploy -or $OnlyUpdate) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Magenta
    Write-Host "  UPDATE TRIALS (3 trials)" -ForegroundColor Magenta
    Write-Host "  Change: ASGMaxSize 4 -> 6 -> 4 -> 6 -> 4 -> 6" -ForegroundColor Magenta
    Write-Host "================================================================" -ForegroundColor Magenta

    # Ensure stack exists
    $Exists = aws cloudformation describe-stacks --stack-name $StackName --region $Region 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Stack does not exist. Deploying first..." -ForegroundColor Yellow
        aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body file://$TemplateFile `
            --capabilities CAPABILITY_NAMED_IAM `
            --region $Region
        aws cloudformation wait stack-create-complete --stack-name $StackName --region $Region
    }

    for ($i = 1; $i -le 3; $i++) {
        Write-Host ""
        Write-Host "--- Update Trial $i/3 ---" -ForegroundColor Yellow

        # Update: MaxSize -> 6
        $Start = Get-Date
        Write-Host "  Updating ASGMaxSize to 6... (started $($Start.ToString('HH:mm:ss')))" -ForegroundColor DarkGray

        aws cloudformation update-stack `
            --stack-name $StackName `
            --template-body file://$TemplateFile `
            --capabilities CAPABILITY_NAMED_IAM `
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
            --region $Region 2>$null

        aws cloudformation wait stack-update-complete --stack-name $StackName --region $Region
        $End = Get-Date
        $Status = if ($LASTEXITCODE -eq 0) {"SUCCESS"} else {"FAILED"}
        Log-Trial "CloudFormation" $i "Update" $Start $End $Status "ASGMax 4->6"

        # Revert: MaxSize -> 4
        Write-Host "  Reverting ASGMaxSize to 4..." -ForegroundColor DarkGray
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
            --region $Region 2>$null

        aws cloudformation wait stack-update-complete --stack-name $StackName --region $Region
        Write-Host "  Reverted. Ready for next trial." -ForegroundColor DarkGray
    }
}

# ============================================================================
# DESTRUCTION TRIALS (5x)
# ============================================================================
if (-not $OnlyUpdate) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "  DESTRUCTION TRIALS (5 trials)" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red

    for ($i = 1; $i -le 5; $i++) {
        Write-Host ""
        Write-Host "--- Destroy Trial $i/5 ---" -ForegroundColor Yellow

        # Ensure stack exists
        $Exists = aws cloudformation describe-stacks --stack-name $StackName --region $Region 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Stack does not exist. Deploying first..." -ForegroundColor DarkGray
            aws cloudformation create-stack `
                --stack-name $StackName `
                --template-body file://$TemplateFile `
                --capabilities CAPABILITY_NAMED_IAM `
                --region $Region 2>$null
            aws cloudformation wait stack-create-complete --stack-name $StackName --region $Region
        }

        # Empty S3 before destroy
        Empty-S3Buckets

        # Destroy
        $Start = Get-Date
        Write-Host "  Destroying... (started $($Start.ToString('HH:mm:ss')))" -ForegroundColor DarkGray

        aws cloudformation delete-stack `
            --stack-name $StackName `
            --region $Region

        aws cloudformation wait stack-delete-complete `
            --stack-name $StackName `
            --region $Region

        $End = Get-Date
        $Status = if ($LASTEXITCODE -eq 0) {"SUCCESS"} else {"FAILED"}
        Log-Trial "CloudFormation" $i "Destroy" $Start $End $Status ""

        # Wait before next trial
        Start-Sleep -Seconds 10
    }
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  ALL TRIALS COMPLETE" -ForegroundColor Cyan
Write-Host "  Results saved to: $CsvFile" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Import-Csv $CsvFile | Format-Table -AutoSize
