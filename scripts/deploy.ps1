<#
.SYNOPSIS
  Initializes the S3 backend and creates a reviewable plan. Applies ONLY when -Apply is given
  and you type the confirmation phrase; it applies the exact saved plan that was reviewed.
.NOTES
  Needs valid AWS credentials and the existing state bucket (see README).
  The database password must come from $env:TF_VAR_db_password (or db_manage_master_user_password = true).
#>
[CmdletBinding()]
param(
    [string]$EnvDir,
    [string]$PlanFile = 'dev.tfplan',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $EnvDir) { $EnvDir = Join-Path $scriptDir '..\environments\dev' }

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    throw 'terraform was not found on PATH.'
}

$EnvDir = (Resolve-Path $EnvDir).Path

function Invoke-Step {
    param([string]$Title, [scriptblock]$Command)
    Write-Host "==> $Title" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "Step failed: $Title (exit code $LASTEXITCODE)" }
}

Invoke-Step 'terraform init'     { terraform -chdir="$EnvDir" init -input=false }
Invoke-Step 'terraform validate' { terraform -chdir="$EnvDir" validate }
Invoke-Step 'terraform plan'     { terraform -chdir="$EnvDir" plan -input=false -out="$PlanFile" }

Write-Host ''
Write-Host "Plan saved to $EnvDir\$PlanFile (treat it as sensitive; it is git-ignored)." -ForegroundColor Yellow
Write-Host 'Review it before approving:  terraform -chdir=environments\dev show dev.tfplan'

if (-not $Apply) {
    Write-Host 'Plan only. Re-run with -Apply after a human has reviewed the plan.'
    return
}

$answer = Read-Host "Type 'apply' to create the billable resources in this plan"
if ($answer -ne 'apply') {
    Write-Host 'Aborted. Nothing was applied.'
    return
}

Invoke-Step 'terraform apply (reviewed plan)' { terraform -chdir="$EnvDir" apply -input=false "$PlanFile" }
