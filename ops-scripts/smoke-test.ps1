param(
    [string]$BaseUrl = "http://localhost:8081/sistemppa"
)

$ErrorActionPreference = "Stop"

$urls = @(
    "$BaseUrl/",
    "$BaseUrl/login",
    "$BaseUrl/register",
    "$BaseUrl/forgot-password",
    "$BaseUrl/products"
)

$failed = $false
foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -MaximumRedirection 5 -UseBasicParsing
        Write-Host "$url => $($response.StatusCode)"
        if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 400) {
            $failed = $true
        }
    }
    catch {
        Write-Host "$url => ERROR: $($_.Exception.Message)"
        $failed = $true
    }
}

if ($failed) {
    throw "Smoke test failed. Check endpoints above."
}

Write-Host "Smoke test passed."
