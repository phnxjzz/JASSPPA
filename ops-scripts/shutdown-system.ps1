# shutdown-system.ps1

param(
    [string]$TomcatHome = "p:\ProjectLI\runtime\apache-tomcat-11.0.18",
    [int]$WaitSeconds = 5
)

# Fungsi untuk log mesej
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Type) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $color
}

# Periksa jika running as Administrator
$admin = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "Error: Script ini mesti dijalankan sebagai Administrator" "ERROR"
    exit 1
}

Write-Log "========================================" "INFO"
Write-Log "Sistem SPPA Shutdown Script" "INFO"
Write-Log "========================================" "INFO"

# 1. Tutup Tomcat
$shutdownScript = "$TomcatHome\bin\shutdown.bat"
if (Test-Path $shutdownScript) {
    Write-Log "Menutup Tomcat..." "INFO"
    & $shutdownScript
    Write-Log "Tomcat sedang ditutup. Menunggu $WaitSeconds saat..." "INFO"
    Start-Sleep -Seconds $WaitSeconds
    Write-Log "Tomcat ditutup" "SUCCESS"
} else {
    Write-Log "Warning: Tomcat shutdown script tidak ditemui" "WARN"
}

# 2. Periksa jika sudah tutup
$javaProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue
if ($javaProcess) {
    Write-Log "Java masih berjalan. Force killing processes..." "WARN"
    Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue
    Write-Log "Java processes ditutup" "SUCCESS"
} else {
    Write-Log " Tomcat sudah berjalan" "SUCCESS"
}

# 3. Optional: Tutup MySQL
$response = Read-Host "Tutup MySQL juga? (y/n)"
if ($response -eq "y") {
    Write-Log "Menutup MySQL 8.0..." "INFO"
    Stop-Service MySQL80 -ErrorAction SilentlyContinue
    Write-Log "MySQL 8.0 ditutup" "SUCCESS"
}

Write-Log "" "INFO"
Write-Log " Sistem sudah ditutup!" "SUCCESS"
