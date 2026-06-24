param(
    [string]$BaseUrl = "http://localhost:8081/sistemppa",
    [string]$JobKey = $env:KPP_REMINDER_JOB_KEY,
    [switch]$DryRun,
    [int]$Limit = 100
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($JobKey)) {
    Write-Error "KPP reminder job key tidak diisi. Set env KPP_REMINDER_JOB_KEY atau beri -JobKey."
    exit 1
}

$query = "key=$([System.Uri]::EscapeDataString($JobKey))&limit=$Limit"
if ($DryRun) {
    $query = "$query&dry_run=1"
}

$endpoint = "$BaseUrl/internal/kpp-reminder-run?$query"
Write-Host "Calling: $endpoint"

$response = Invoke-RestMethod -Method Get -Uri $endpoint -Headers @{
    "X-Internal-Key" = $JobKey
}

$response | ConvertTo-Json -Depth 5

if (-not $response.success) {
    Write-Error "KPP reminder job gagal: $($response.message)"
    exit 1
}

Write-Host "KPP reminder job selesai. due=$($response.dueCount), processed=$($response.processedCount), sent=$($response.sentCount), failed=$($response.failedCount), rescheduled=$($response.rescheduledCount)"
