param(
  [Parameter(Mandatory=$false)]
  [long]$RunId = 0
)

if (-not $env:GITHUB_TOKEN -or $env:GITHUB_TOKEN.Trim().Length -eq 0) {
  Write-Host "GITHUB_TOKEN is not set in this session. Cannot query GitHub API."
  exit 2
}

if ($RunId -eq 0) {
  Write-Host "No RunId provided. Please call: .\get_run_jobs.ps1 -RunId 12345"
  exit 2
}

$hdr = @{ Authorization = "Bearer $($env:GITHUB_TOKEN)"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'get-run-jobs-script' }
$url = "https://api.github.com/repos/yerinsabraham/MetartPay/actions/runs/$RunId/jobs"

try {
  $r = Invoke-RestMethod -Uri $url -Headers $hdr -Method Get -ErrorAction Stop
  $r.jobs | Select-Object id,name,status,conclusion,started_at,completed_at | Format-Table -AutoSize
} catch {
  Write-Host "Failed to fetch jobs for run ${RunId}: $($($_.Exception).Message)"
  exit 1
}
