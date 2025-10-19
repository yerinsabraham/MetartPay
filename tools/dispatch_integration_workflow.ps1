<#
Dispatch the 'integration-simulate.yml' GitHub Actions workflow for this repo.
Usage:
  - Ensure a GitHub token is available in environment variable GITHUB_TOKEN or GH_TOKEN.
  - Run: .\dispatch_integration_workflow.ps1 [-Ref <branch-or-ref>]

The script auto-detects the repo owner and name from 'git remote origin' and uses the current branch if -Ref isn't provided.
#>
param(
    [string]$Ref
)

Set-StrictMode -Version Latest

Push-Location (Split-Path -Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent)
try {
    # Determine ref (branch) if not provided
    if (-not $Ref) {
        $Ref = (git rev-parse --abbrev-ref HEAD) -replace "\r|\n", ''
    }

    # Get remote origin URL
    $remote = (git config --get remote.origin.url) -replace "\r|\n", ''
    if (-not $remote) {
        Write-Error "Could not read git remote origin URL. Are you in a git repo?"
        exit 2
    }

    # Parse owner/repo from remote URL
    $ownerRepo = $null
    if ($remote -match 'github.com[:/](?<owner>[^/]+)\/(?<repo>[^.]+)') {
        $owner = $matches['owner']
        $repo = $matches['repo']
        $ownerRepo = "$owner/$repo"
    }

    if (-not $ownerRepo) {
        Write-Error "Could not parse owner/repo from remote URL: $remote"
        exit 3
    }

    # Resolve token
    $token = $env:GITHUB_TOKEN
    if (-not $token) { $token = $env:GH_TOKEN }
    if (-not $token) {
        Write-Host "GITHUB_TOKEN or GH_TOKEN not found in environment. Please paste a personal access token with 'repo' and 'workflow' scope (input will be hidden):"
        $secure = Read-Host -AsSecureString
        $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
    }

    $workflowFile = 'integration-simulate.yml'
    $url = "https://api.github.com/repos/$ownerRepo/actions/workflows/$workflowFile/dispatches"

    $body = @{ ref = $Ref } | ConvertTo-Json

    Write-Host "Dispatching workflow '$workflowFile' for $ownerRepo@$Ref ..."

    $headers = @{
        Authorization = "token $token"
        Accept = 'application/vnd.github.v3+json'
        'User-Agent' = 'dispatch-script'
    }

    Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body -ErrorAction Stop | Out-Null
    Write-Host "Dispatch sent. Monitor the Actions tab for progress."
}
catch {
    Write-Error "Failed to dispatch workflow: $_"
    exit 4
}
finally {
    Pop-Location
}
