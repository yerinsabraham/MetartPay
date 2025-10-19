param(
  [Parameter(Mandatory=$false)]
  [long]$JobId = 0
)

if (-not $env:GITHUB_TOKEN -or $env:GITHUB_TOKEN.Trim().Length -eq 0) {
  Write-Host "GITHUB_TOKEN is not set in this session. Cannot query GitHub API."
  exit 2
}

if ($JobId -eq 0) {
  Write-Host "No JobId provided. Please call: .\get_job_details.ps1 -JobId 12345"
  exit 2
}

$hdr = @{ Authorization = "Bearer $($env:GITHUB_TOKEN)"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'get-job-details-script' }
$url = "https://api.github.com/repos/yerinsabraham/MetartPay/actions/jobs/$JobId"

try {
  $r = Invoke-RestMethod -Uri $url -Headers $hdr -Method Get -ErrorAction Stop
  Write-Host "Job: $($r.id) - $($r.name)"
  Write-Host "Status: $($r.status)  Conclusion: $($r.conclusion)"
  Write-Host "Started at: $($r.started_at)  Completed at: $($r.completed_at)"
  if ($r.steps) {
    Write-Host "Steps:"
    $r.steps | ForEach-Object {
      Write-Host " - $($_.number): $($_.name) => $($_.status) ($($_.conclusion))"
    }
  } else {
    Write-Host "No step details available yet."
  }
} catch {
  Write-Host "Failed to fetch job details for job ${JobId}: $($($_.Exception).Message)"
  exit 1
}
