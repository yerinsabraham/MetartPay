# Safe polling script — will not terminate the VS Code terminal on errors.
# Usage: run it after you've set $env:GITHUB_TOKEN appropriately.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage='Run ID to poll (int64)')]
    [long]$RunId = 0,
    [Parameter(Mandatory=$false, HelpMessage='If set, fetch the latest run id automatically')]
    [switch]$Latest
)

# Read token from environment
$token = $env:GITHUB_TOKEN

if (-not $token -or $token.Trim().Length -eq 0) {
    Write-Host "GITHUB_TOKEN is not set or is empty. Please set it before running this script."
    Write-Host ""
    Write-Host "To set for this session (PowerShell):"
    Write-Host "  $env:GITHUB_TOKEN = 'ghp_...'"
    Write-Host ""
    Write-Host "Or to set permanently for your user (PowerShell - run as your user):"
    Write-Host "  setx GITHUB_TOKEN \"ghp_...\""
    Write-Host "  # you will need to restart the terminal for setx changes to apply"
    return
}

$owner = 'yerinsabraham'
$repo = 'MetartPay'

# If -Latest provided, query GitHub API for most recent workflow runs and pick the newest run id
if ($Latest) {
    try {
        $hdrTmp = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'local-script' }
        $url = "https://api.github.com/repos/$owner/$repo/actions/runs?per_page=1"
        $resp = Invoke-RestMethod -Uri $url -Headers $hdrTmp -Method Get -ErrorAction Stop
        if ($resp.workflow_runs -and $resp.workflow_runs.Count -gt 0) {
            $RunId = [int]$resp.workflow_runs[0].id
            Write-Host "Discovered latest run id: $RunId"
        } else {
            Write-Host "No workflow runs found to use for -Latest"
            return
        }
    } catch {
        Write-Host ("Failed to fetch latest run id: {0}" -f $_.Exception.Message)
        return
    }
}

if (-not $RunId -or $RunId -eq 0) {
    Write-Host "No RunId provided. Use -RunId <int> or -Latest to auto-detect the latest run.";
    return
}

$hdr = @{
    Authorization = "Bearer $token"
    Accept = 'application/vnd.github+json'
    'User-Agent' = 'local-script'
}

# Poll the run status until completed (or until we reach max polls)
$maxPolls = 60
$pollInterval = 6  # seconds
$r = $null

try {
    for ($i = 0; $i -lt $maxPolls; $i++) {
        try {
            $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/actions/runs/$runId" -Headers $hdr -Method Get -ErrorAction Stop
            Write-Host ("Status: {0}  Conclusion: {1}  (poll #{2})" -f $r.status, $r.conclusion, $i)
        } catch {
            Write-Host ("Warning: API request failed on poll #{0}: {1}" -f $i, $_.Exception.Message)
            # don't abort; wait and continue polling
        }

        if ($r -and $r.status -eq 'completed') {
            break
        }

        Start-Sleep -Seconds $pollInterval
    }
} catch {
    Write-Host ("Unexpected error while polling: {0}" -f $_.Exception.Message)
    return
}

if (-not $r -or $r.status -ne 'completed') {
    Write-Host "Run did not complete within the polling window. Last known status: $($r.status)"
    return
}

# Download logs (safe try/catch)
$out = "job_${runId}_logs.zip"
try {
    $logsUrl = "https://api.github.com/repos/$owner/$repo/actions/runs/$runId/logs"
    Write-Host "Downloading logs from $logsUrl to $out ..."
    Invoke-RestMethod -Uri $logsUrl -Headers $hdr -Method Get -OutFile $out -ErrorAction Stop
    Write-Host "Downloaded $out"
} catch {
    Write-Host ("Failed to download logs: {0}" -f $_.Exception.Message)
    return
}

# Extract and inspect
$d = "tools/job-logs/run_$runId"
try {
    mkdir -Force $d | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    [System.IO.Compression.ZipFile]::ExtractToDirectory((Resolve-Path $out).Path, $d)
    Write-Host "Extracted logs to $d"
} catch {
    Write-Host ("Failed to extract logs: {0}" -f $_.Exception.Message)
    return
}

# List largest files
Get-ChildItem -Recurse $d | Sort-Object Length -Descending | Select-Object -First 20 | Format-Table FullName,Length -AutoSize

Write-Host "---- Search for debug outputs (limited results) ----"
$patterns = @(
    'firebase-functions',
    'functions.yaml',
    'backend/dist/index.js loaded OK',
    'Failed to parse build specification',
    'Failed to load function definition',
    'Function us-central1-api does not exist'
)

try {
    foreach ($p in $patterns) {
        Write-Host "---- Pattern: $p ----"
        Select-String -Path "$d\**\*" -Pattern $p -SimpleMatch -ErrorAction SilentlyContinue |
            Select-Object -First 200 |
            ForEach-Object { Write-Host ($_.Path + ':' + $_.LineNumber + ' => ' + $_.Line) }
    }
} catch {
    Write-Host ("Search error: {0}" -f $_.Exception.Message)
}

Write-Host "Done."