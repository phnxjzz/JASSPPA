param(
    [string]$ProjectRoot = "p:\ProjectLI",
    [string]$MavenCmd = "tools\apache-maven-3.9.14\bin\mvn.cmd",
    [string]$TomcatWebapps = "runtime\apache-tomcat-11.0.18\webapps",
    [string]$WarName = "sistemppa.war"
)

$ErrorActionPreference = "Stop"

Push-Location $ProjectRoot
try {
    Write-Host "[1/3] Build project (clean package)..."
    & $MavenCmd -q clean package

    $warPath = Join-Path -Path "target" -ChildPath $WarName
    if (-not (Test-Path $warPath)) {
        throw "WAR not found at $warPath"
    }

    $deployPath = Join-Path -Path $TomcatWebapps -ChildPath $WarName
    Write-Host "[2/3] Copy WAR to Tomcat webapps..."
    Copy-Item $warPath $deployPath -Force

    Write-Host "[3/3] Done. Deployed to $deployPath"
}
finally {
    Pop-Location
}
