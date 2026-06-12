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
    $appDirName = [System.IO.Path]::GetFileNameWithoutExtension($WarName)
    $explodedPath = Join-Path -Path $TomcatWebapps -ChildPath $appDirName

    if (Test-Path $explodedPath) {
        Write-Host "[2/4] Remove stale exploded app folder..."
        Remove-Item $explodedPath -Recurse -Force
    }

    if (Test-Path $deployPath) {
        Write-Host "[3/4] Remove old WAR..."
        Remove-Item $deployPath -Force
    }

    Write-Host "[4/4] Copy WAR to Tomcat webapps..."
    Copy-Item $warPath $deployPath -Force

    Write-Host "Done. Deployed to $deployPath"
}
finally {
    Pop-Location
}
