<#
.SYNOPSIS
  Offline checks: format, init (no backend), validate. Makes no AWS calls and changes nothing in AWS.
#>
[CmdletBinding()]
param(
    [string]$EnvDir
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $EnvDir) { $EnvDir = Join-Path $scriptDir '..\environments\dev' }

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    throw 'terraform was not found on PATH.'
}

$root = (Resolve-Path (Join-Path $scriptDir '..')).Path
$EnvDir = (Resolve-Path $EnvDir).Path

function Invoke-Step {
    param([string]$Title, [scriptblock]$Command)
    Write-Host "==> $Title" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "Step failed: $Title (exit code $LASTEXITCODE)" }
}

Invoke-Step 'terraform fmt -check -recursive' { terraform -chdir="$root" fmt -check -recursive }
Invoke-Step 'terraform init -backend=false'   { terraform -chdir="$EnvDir" init -backend=false -input=false }
Invoke-Step 'terraform validate'              { terraform -chdir="$EnvDir" validate }

Write-Host 'All offline checks passed.' -ForegroundColor Green
