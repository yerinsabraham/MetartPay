<#
Deploy Firestore rules using the Firebase CLI.

Prerequisites:
- Install Firebase CLI: npm install -g firebase-tools
- Login: firebase login
- Select project or provide --project when running the script

Usage:
.
    .\deploy-firestore-rules.ps1 -ProjectId "your-firebase-project-id"

If you want to preview the rules without applying use --dryRun switch.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,

    [switch]$DryRun
)

$rulesPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath 'firestore.rules'
if (-not (Test-Path $rulesPath)) {
    Write-Error "Rules file not found at $rulesPath"
    exit 1
}

if ($DryRun) {
    Write-Host "Previewing rules for project $ProjectId"
    firebase --project $ProjectId deploy --only firestore:rules --test
    exit $LASTEXITCODE
}

Write-Host "Deploying Firestore rules to project: $ProjectId"
firebase --project $ProjectId deploy --only firestore:rules --force
exit $LASTEXITCODE
